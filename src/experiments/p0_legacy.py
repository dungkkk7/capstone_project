from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Optional

from fuzzing_equi_check.fuzzing import SemanticFuzzer, compile_to_binary
from fuzzing_equi_check.input_contracts import resolve_input_contract
from llm_recovery.llm_recovery import (
    P0_PROMPT_POLICY_VERSION,
    RecoveryConfig,
    RecoveryResult,
    VertexGemini,
    export_ghidra_pseudocode,
    run_recovery_loop,
)
from llvm_pass.britening_ir import (
    brighten_ir,
    read_native_contract_report,
    verify_native_contract,
)
from main import (
    _resolve_seed_paths,
    _run_experimental_delift_bundle,
    _run_fuzzer_sync,
    _select_generator,
)

from .enums import MethodId
from .models import GenerationResult, RepresentationArtifact, SampleIdentity
from .quota import QuotaController
from .representations import RawLiftService, RepresentationError
from .storage import atomic_write_json, sha256_file, stable_json_sha256


def build_p0_recovery_config(config: Dict[str, Any]) -> RecoveryConfig:
    """Freeze non-algorithmic P0 runtime knobs to the experiment contract."""

    llm_config = config["llm"]
    return RecoveryConfig(
        model=str(llm_config["model_id"]),
        location=str(llm_config["location"]),
        max_iterations=5,
        fuzz_iterations=int(config["p0"]["fuzz_iterations"]),
        fuzz_timeout=0.5,
        max_ir_chars=None,
        temperature=float(llm_config["temperature"]),
        top_p=float(llm_config["top_p"]),
        candidate_count=int(llm_config.get("candidate_count", 1)),
        thinking_level=llm_config.get("thinking_level") or "LOW",
        llm_timeout=float(llm_config["request_timeout_sec"]),
        # Supply both frozen evidence sources through the readable File API:
        # focused Ghidra pseudocode and final cleaned LLVM IR.
        use_file_api=True,
        file_api_inline_max_bytes=None,
        request_timeout=float(llm_config["request_timeout_sec"]),
        max_output_tokens=int(llm_config["max_output_tokens"]),
        context_window_tokens=int(llm_config["context_window_tokens"]),
        context_safety_margin_tokens=int(
            llm_config["context_safety_margin_tokens"]
        ),
        pseudo_backend="ghidra",
        ghidra_binary_path=str(config["paths"]["ghidra_headless"]),
        ghidra_timeout=float(
            config["representation"]["b0"]["ghidra_timeout_sec"]
        ),
        two_stage_recovery=True,
        attach_clean_ir=True,
        require_json=False,
    )


class _FakeLegacyClient:
    def __init__(self, source_path: str):
        source = Path(source_path).read_text(encoding="utf-8")
        self.response = source
        self.last_response_meta = {
            "finish_reason": "STOP",
            "model_version": "fake",
            "usage_metadata": {},
        }

    def generate(self, prompt: str, **_: Any) -> str:
        return self.response


@dataclass
class P0LegacyRun:
    representation: RepresentationArtifact
    generation: GenerationResult
    internal_precheck: Dict[str, Any]
    internal_precheck_passed: bool
    internal_recovery_report: Optional[Dict[str, Any]]
    recovery_oracle_path: str
    candidate_path: str


class P0LegacyAdapter:
    """Run the current five-iteration P0 protocol without redefining it."""

    VERSION = "p0-legacy-adapter-v2-split-phases"

    def __init__(self, config: Dict[str, Any], lift_service: RawLiftService):
        self.config = config
        self.lift_service = lift_service
        if int(config["p0"]["max_iterations"]) != 5:
            raise ValueError("P0 legacy adapter requires max_iterations=5")

    def run(
        self,
        sample: SampleIdentity,
        common_dir: str | Path,
        variant_dir: str | Path,
        *,
        quota_event_callback: (
            Callable[[str, Dict[str, Any]], None] | None
        ) = None,
    ) -> P0LegacyRun:
        representation = self.prepare(sample, common_dir, variant_dir)
        return self.process(
            sample,
            variant_dir,
            representation=representation,
            quota_event_callback=quota_event_callback,
        )

    def prepare(
        self,
        sample: SampleIdentity,
        common_dir: str | Path,
        variant_dir: str | Path,
    ) -> RepresentationArtifact:
        """Freeze all P0 evidence required by the later LLM phase."""

        variant = Path(variant_dir)
        representation_dir = variant / "representation"
        representation_dir.mkdir(parents=True, exist_ok=True)

        lift = self.lift_service.build(sample, Path(common_dir) / "raw_lift")
        raw_bc = Path(lift["raw_bc_path"])
        brightened_bc = representation_dir / "brightened.bc"
        if not brighten_ir(
            str(raw_bc), str(brightened_bc), binary_path=sample.original_elf_path
        ):
            raise RepresentationError(
                "P0_BRIGHTEN_FAILED", "P0 brighten_ir returned false"
            )
        brightened_ll = brightened_bc.with_suffix(".ll")
        if not brightened_ll.is_file():
            raise RepresentationError(
                "P0_BRIGHTENED_LL_MISSING", "P0 did not produce brightened.ll"
            )
        final_ll_text, delift_status, delift_log = _run_experimental_delift_bundle(
            str(brightened_ll), str(representation_dir), "p0"
        )
        final_ll = Path(final_ll_text) if final_ll_text else None
        if delift_status != "applied" or final_ll is None or not final_ll.is_file():
            raise RepresentationError(
                "P0_FINALIZATION_FAILED",
                "P0 delift bundle did not produce final LLVM IR",
            )
        if not verify_native_contract(str(final_ll)):
            raise RepresentationError(
                "P0_FINAL_VERIFY_FAILED",
                "P0 final LLVM IR did not pass the verifier-only native gate",
            )
        native_report = read_native_contract_report(str(final_ll))

        # Freeze provider/decoding knobs from the experiment config for every
        # method.  This preserves P0's current representation, prompt,
        # compiler/fuzz-feedback loop and five-iteration bound while preventing
        # ambient LLM_RECOVERY_* variables from silently giving P0 a different
        # model or sampling policy than A0/B0.
        legacy_config = build_p0_recovery_config(self.config)
        final_reference = representation_dir / "final_ref.bin"
        compile_to_binary(str(final_ll), str(final_reference))
        if not final_reference.is_file():
            raise RepresentationError(
                "P0_FINAL_REFERENCE_FAILED",
                "P0 final LLVM IR did not produce the compiled reference",
            )
        recovery_reference = str(final_reference)

        p0_pseudocode = representation_dir / "ghidra_pseudocode.c"
        export_ghidra_pseudocode(
            recovery_reference,
            str(p0_pseudocode),
            ghidra_binary_path=legacy_config.ghidra_binary_path,
            timeout=legacy_config.ghidra_timeout,
        )
        if not p0_pseudocode.is_file() or not p0_pseudocode.stat().st_size:
            raise RepresentationError(
                "P0_PSEUDOCODE_MISSING",
                "P0 preparation produced no Ghidra pseudocode",
            )

        model_freeze = {
            "model_id": legacy_config.model,
            "location": legacy_config.location,
            "temperature": legacy_config.temperature,
            "top_p": legacy_config.top_p,
            "candidate_count": legacy_config.candidate_count,
            "max_output_tokens": legacy_config.max_output_tokens,
            "thinking_level": legacy_config.thinking_level,
        }
        attach_clean_ir = legacy_config.attach_clean_ir
        attachment_paths = [str(p0_pseudocode)]
        attachment_hashes = [sha256_file(p0_pseudocode)]
        if attach_clean_ir:
            attachment_paths.insert(0, str(final_ll))
            attachment_hashes.insert(0, sha256_file(final_ll))
        representation = RepresentationArtifact(
            method=MethodId.P0,
            primary_path=str(final_ll),
            primary_sha256=sha256_file(final_ll),
            byte_count=final_ll.stat().st_size,
            token_count=max(1, (final_ll.stat().st_size + 1) // 2),
            builder_version=self.VERSION,
            attachment_paths=attachment_paths,
            attachment_sha256=attachment_hashes,
            provenance={
                "source_sha256": sample.original_elf_sha256,
                "raw_lift_cache_key": lift["cache_key"],
                "brightened_bc_path": str(brightened_bc),
                "brightened_bc_sha256": sha256_file(brightened_bc),
                "delift_bundle": delift_status,
                "delift_bundle_log": delift_log,
                "final_ir_path": str(final_ll),
                "final_ir_sha256": sha256_file(final_ll),
                "finalization": "verified",
                "pseudocode_path": str(p0_pseudocode),
                "pseudocode_sha256": sha256_file(p0_pseudocode),
                "internal_precheck_path": str(
                    variant / "p0_internal_precheck.json"
                ),
                "internal_reference": recovery_reference,
                "internal_reference_sha256": sha256_file(
                    recovery_reference
                ),
                "native_contract": native_report,
                "protocol": "legacy_iterative_repair",
                "prompt_policy_version": P0_PROMPT_POLICY_VERSION,
                "max_iterations": 5,
                "representation_contract": (
                    "verified final LLVM IR plus P0 Ghidra pseudocode"
                    if attach_clean_ir
                    else "P0 Ghidra pseudocode only; final LLVM IR retained locally"
                ),
                "model_freeze": model_freeze,
                "prepared_without_llm": True,
            },
            evidence_byte_count=sum(
                Path(path).stat().st_size for path in attachment_paths
            ),
            evidence_token_count=max(
                1,
                (
                    sum(
                        Path(path).stat().st_size
                        for path in attachment_paths
                    )
                    + 1
                )
                // 2,
            ),
        )
        atomic_write_json(
            representation_dir / "representation_manifest.json",
            representation.to_dict(),
        )
        return representation

    def process(
        self,
        sample: SampleIdentity,
        variant_dir: str | Path,
        *,
        representation: RepresentationArtifact,
        quota_event_callback: (
            Callable[[str, Dict[str, Any]], None] | None
        ) = None,
    ) -> P0LegacyRun:
        """Consume frozen P0 evidence and run LLM recovery/repair."""

        variant = Path(variant_dir)
        generation_dir = variant / "generation"
        generation_dir.mkdir(parents=True, exist_ok=True)
        if representation.method is not MethodId.P0:
            raise RepresentationError(
                "P0_REPRESENTATION_METHOD_MISMATCH",
                "P0 processing received another method's representation",
            )
        final_ll = Path(representation.primary_path)
        if (
            not final_ll.is_file()
            or sha256_file(final_ll) != representation.primary_sha256
        ):
            raise RepresentationError(
                "P0_REPRESENTATION_HASH_MISMATCH",
                "Frozen P0 final LLVM IR is missing or changed",
            )
        provenance = representation.provenance or {}
        p0_pseudocode = Path(str(provenance.get("pseudocode_path") or ""))
        if (
            not p0_pseudocode.is_file()
            or sha256_file(p0_pseudocode)
            != provenance.get("pseudocode_sha256")
        ):
            raise RepresentationError(
                "P0_PSEUDOCODE_HASH_MISMATCH",
                "Frozen P0 Ghidra pseudocode is missing or changed",
            )
        prepared_pseudocode = p0_pseudocode
        recovery_reference = str(provenance.get("internal_reference") or "")
        if (
            not Path(recovery_reference).is_file()
            or sha256_file(recovery_reference)
            != provenance.get("internal_reference_sha256")
        ):
            raise RepresentationError(
                "P0_REFERENCE_HASH_MISMATCH",
                "Frozen P0 recovery reference is missing or changed",
            )

        root = self.config["_project_root"]
        generator, generator_reason = _select_generator(
            root, sample.original_elf_path
        )
        seed_paths, seed_dir = _resolve_seed_paths(
            root, sample.original_elf_path
        )
        contract = resolve_input_contract(
            root, sample.original_elf_path, only_custom=True
        )
        legacy_config = build_p0_recovery_config(self.config)
        internal_input_dir = variant / "processing" / "p0_internal_discovery"
        internal_input_dir.mkdir(parents=True, exist_ok=True)
        internal_inputs: list[Dict[str, Any]] = []
        fuzz_call_index = 0

        def run_legacy_fuzz(
            file1: str,
            file2: str,
            *,
            iterations: int,
            timeout: float,
        ) -> Dict[str, Any]:
            fuzzer = SemanticFuzzer(
                file1,
                file2,
                seed_paths=seed_paths,
                seed_dir=seed_dir,
                input_contract=contract,
            )
            nonlocal fuzz_call_index
            report = _run_fuzzer_sync(
                fuzzer,
                iterations=iterations,
                generator=generator,
                timeout=timeout,
            )
            fuzz_call_index += 1
            for payload_index, encoded in enumerate(report.get("tested_payloads") or []):
                try:
                    payload = base64.b64decode(str(encoded), validate=True)
                except (ValueError, TypeError):
                    continue
                path = internal_input_dir / f"fuzz_{fuzz_call_index:03d}_{payload_index:05d}.bin"
                path.write_bytes(payload)
                internal_inputs.append({
                    "path": str(path),
                    "sha256": sha256_file(path),
                    "size": path.stat().st_size,
                    "category": "p0_internal_fuzz",
                    "origin_method": "P0",
                })
            return report

        precheck = run_legacy_fuzz(
            str(final_ll),
            sample.original_elf_path,
            iterations=int(self.config["p0"]["fuzz_iterations"]),
            timeout=float(self.config["p0"]["fuzz_timeout_sec"]),
        )
        precheck_path = variant / "p0_internal_precheck.json"
        atomic_write_json(precheck_path, precheck)
        precheck_passed = bool(precheck.get("is_fully_equivalent", False))
        if not precheck_passed:
            raise RepresentationError(
                "P0_FINAL_SEMANTIC_REGRESSION",
                "P0 final LLVM IR failed semantic precheck",
            )
        recovery_oracle = recovery_reference
        recovery_oracle_label = "semantic-gated final IR reference"
        print(
            "[experiment] "
            f"sample={sample.sample_id} method=P0 stage=semantic-precheck "
            f"passed={precheck_passed} recovery_oracle={recovery_oracle_label}",
            flush=True,
        )

        def recovery_fuzz(candidate_path: str) -> Dict[str, Any]:
            return run_legacy_fuzz(
                candidate_path,
                recovery_oracle,
                iterations=legacy_config.fuzz_iterations,
                timeout=legacy_config.fuzz_timeout,
            )
        fake_path = self.config["llm"].get("fake_response_path")
        model_client = (
            _FakeLegacyClient(fake_path)
            if fake_path
            else VertexGemini(legacy_config)
        )
        quota = (
            None
            if fake_path
            else QuotaController(
                self.config["llm"],
                generation_dir,
                method=MethodId.P0.value,
                log_context=f"{sample.sample_id}/{MethodId.P0.value}",
                event_callback=quota_event_callback,
                response_metadata_getter=(
                    lambda: dict(model_client.last_response_meta or {})
                ),
                response_metadata_setter=lambda metadata: setattr(
                    model_client, "last_response_meta", dict(metadata)
                ),
            )
        )
        output_candidate = generation_dir / "p0_recovered.c"
        result: RecoveryResult = run_recovery_loop(
            ir_text=final_ll.read_text(
                encoding="utf-8", errors="replace"
            ),
            output_recovered_c_path=str(output_candidate),
            case_output_dir=str(generation_dir),
            metadata={
                "original_binary": sample.original_elf_path,
                # Ghidra evidence remains frozen from the prepared internal
                # reference.  The fuzzer callback above may use the original
                # ELF as oracle when that internal reference failed its
                # diagnostic baseline.
                "recovery_reference_binary": recovery_reference,
                "recovery_reference_label": recovery_oracle_label,
                "input_ir": str(final_ll),
                "precomputed_ghidra_pseudocode_path": str(
                    prepared_pseudocode
                ),
                "precomputed_ghidra_pseudocode_sha256": sha256_file(
                    prepared_pseudocode
                ),
                "case": sample.sample_id,
            },
            fuzzer_callback=recovery_fuzz,
            config=legacy_config,
            model_client=model_client,
            request_executor=(quota.execute if quota is not None else None),
            resume_state_path=str(generation_dir / "recovery_state.json"),
        )
        if not result.source_path or not Path(result.source_path).is_file():
            raise RuntimeError("P0 legacy recovery produced no candidate")
        persisted_pseudocode = generation_dir / "ghidra_pseudocode.c"
        if (
            not persisted_pseudocode.is_file()
            or sha256_file(persisted_pseudocode)
            != sha256_file(prepared_pseudocode)
        ):
            raise RepresentationError(
                "P0_PSEUDOCODE_PROCESSING_DRIFT",
                "P0 processing did not consume the frozen Ghidra pseudocode",
            )

        responses = sorted(generation_dir.glob("recovery_iter*.response.txt"))
        metas = sorted(generation_dir.glob("recovery_iter*.meta.json"))
        context_records = []
        for context_path in sorted(
            generation_dir.glob("recovery_iter*.context.json")
        ):
            try:
                context_records.append(
                    json.loads(context_path.read_text(encoding="utf-8"))
                )
            except (OSError, ValueError):
                continue
        usage_input = usage_output = usage_thinking = usage_total = 0
        for meta_path in metas:
            try:
                meta = json.loads(meta_path.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                continue
            usage = meta.get("usage_metadata") or {}
            usage_input += int(
                usage.get("prompt_token_count", usage.get("promptTokenCount", 0))
                or 0
            )
            usage_output += int(
                usage.get(
                    "candidates_token_count",
                    usage.get("candidatesTokenCount", 0),
                )
                or 0
            )
            usage_thinking += int(
                usage.get(
                    "thoughts_token_count",
                    usage.get("thoughtsTokenCount", 0),
                )
                or 0
            )
            usage_total += int(
                usage.get("total_token_count", usage.get("totalTokenCount", 0))
                or 0
            )
        model_freeze = {
            "model_id": legacy_config.model,
            "location": legacy_config.location,
            "temperature": legacy_config.temperature,
            "top_p": legacy_config.top_p,
            "candidate_count": legacy_config.candidate_count,
            "max_output_tokens": legacy_config.max_output_tokens,
            "thinking_level": legacy_config.thinking_level,
        }
        request_identity = {
            "protocol": "legacy_iterative_repair",
            "prompt_policy_version": P0_PROMPT_POLICY_VERSION,
            "max_iterations": 5,
            **model_freeze,
            "representation_sha256": sha256_file(final_ll),
            "pseudocode_sha256": sha256_file(prepared_pseudocode),
            "recovery_reference_sha256": sha256_file(recovery_reference),
            "recovery_oracle_sha256": sha256_file(recovery_oracle),
            "internal_precheck_passed": precheck_passed,
        }
        quota_metrics = (
            quota.metrics()
            if quota is not None
            else {
                "api_attempt_count": len(responses),
                "accepted_model_call_count": len(responses),
                "quota_throttle_count": 0,
                "quota_wait_duration_ms": 0,
            }
        )
        generation = GenerationResult(
            request_sha256=stable_json_sha256(request_identity),
            candidate_path=str(output_candidate),
            candidate_sha256=sha256_file(output_candidate),
            logical_generation_count=len(responses),
            model_call_count=len(responses),
            response_path=str(responses[-1]) if responses else "",
            input_tokens=usage_input or None,
            output_tokens=usage_output or None,
            thinking_tokens=usage_thinking or None,
            billable_output_tokens=(
                usage_output + usage_thinking
                if usage_output or usage_thinking
                else None
            ),
            total_tokens=usage_total or (
                usage_input + usage_output + usage_thinking
                if usage_input or usage_output or usage_thinking
                else None
            ),
            iterations=result.iterations,
            api_attempt_count=quota_metrics["api_attempt_count"],
            quota_throttle_count=quota_metrics["quota_throttle_count"],
            quota_wait_duration_ms=quota_metrics[
                "quota_wait_duration_ms"
            ],
            response_metadata={
                "protocol": "legacy_iterative_repair",
                "prompt_policy_version": P0_PROMPT_POLICY_VERSION,
                "success": result.success,
                "max_iterations": legacy_config.max_iterations,
                "evidence_schedule": [
                    record.get("evidence_mode")
                    for record in context_records
                ],
                "context_safe_split_active": any(
                    bool(record.get("context_safe_split_active"))
                    for record in context_records
                ),
                "generator_reason": generator_reason,
                "model_freeze": model_freeze,
                "internal_precheck_passed": precheck_passed,
                "internal_precheck_path": str(precheck_path),
                "recovery_oracle_path": recovery_oracle,
                "recovery_oracle_sha256": sha256_file(recovery_oracle),
                "recovery_oracle_label": recovery_oracle_label,
                "quota": quota_metrics,
                "internal_discovery_manifest": str(
                    internal_input_dir / "manifest.json"
                ),
            },
        )
        atomic_write_json(
            internal_input_dir / "manifest.json",
            {"inputs": internal_inputs},
        )
        atomic_write_json(
            generation_dir / "generation_manifest.json",
            generation.to_dict(),
        )
        return P0LegacyRun(
            representation=representation,
            generation=generation,
            internal_precheck=precheck,
            internal_precheck_passed=precheck_passed,
            internal_recovery_report=result.fuzz_report,
            recovery_oracle_path=recovery_oracle,
            candidate_path=str(output_candidate),
        )
