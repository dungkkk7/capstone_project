from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Optional

from fuzzing_equi_check.fuzzing import SemanticFuzzer, compile_to_binary
from fuzzing_equi_check.input_contracts import resolve_input_contract
from llm_recovery.llm_recovery import (
    RecoveryConfig,
    RecoveryResult,
    VertexGemini,
    confirmed_equivalence_pass,
    export_ghidra_pseudocode,
    run_recovery_loop,
)
from llvm_pass.britening_ir import brighten_ir, read_native_contract_report
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


class P0PrecheckFailed(RuntimeError):
    def __init__(self, report: Dict[str, Any]):
        super().__init__("P0 legacy semantic precheck did not pass")
        self.report = report


def build_p0_recovery_config(config: Dict[str, Any]) -> RecoveryConfig:
    """Freeze non-algorithmic P0 runtime knobs to the experiment contract."""

    llm_config = config["llm"]
    return RecoveryConfig(
        model=str(llm_config["model_id"]),
        location=str(llm_config["location"]),
        max_iterations=5,
        fuzz_iterations=int(config["p0"]["fuzz_iterations"]),
        fuzz_timeout=float(config["p0"]["fuzz_timeout_sec"]),
        max_ir_chars=None,
        temperature=float(llm_config["temperature"]),
        top_p=float(llm_config["top_p"]),
        candidate_count=int(llm_config.get("candidate_count", 1)),
        thinking_level=llm_config.get("thinking_level"),
        llm_timeout=float(llm_config["request_timeout_sec"]),
        use_file_api=True,
        file_api_inline_max_bytes=None,
        request_timeout=float(llm_config["request_timeout_sec"]),
        max_output_tokens=int(llm_config["max_output_tokens"]),
        pseudo_backend="ghidra",
        ghidra_binary_path=str(config["paths"]["ghidra_headless"]),
        ghidra_timeout=float(
            config["representation"]["b0"]["ghidra_timeout_sec"]
        ),
        two_stage_recovery=True,
        attach_clean_ir=bool(config["p0"].get("attach_clean_ir", False)),
        require_json=True,
    )


class _FakeLegacyClient:
    def __init__(self, source_path: str):
        source = Path(source_path).read_text(encoding="utf-8")
        self.response = json.dumps({"source": source})
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
    internal_recovery_report: Optional[Dict[str, Any]]
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
        delifted_ll_text, delift_status, delift_log = _run_experimental_delift_bundle(
            str(brightened_ll), str(representation_dir), "delifted"
        )
        delifted_ll = Path(delifted_ll_text)
        if delift_status == "applied":
            primary_ll = delifted_ll
        else:
            primary_ll = brightened_ll
        native_report = read_native_contract_report(str(brightened_bc))
        if native_report:
            atomic_write_json(
                representation_dir / "native_contract_report.json", native_report
            )

        # Freeze provider/decoding knobs from the experiment config for every
        # method.  This preserves P0's current representation, prompt,
        # compiler/fuzz-feedback loop and five-iteration bound while preventing
        # ambient LLM_RECOVERY_* variables from silently giving P0 a different
        # model or sampling policy than A0/B0.
        legacy_config = build_p0_recovery_config(self.config)

        brightened_reference = representation_dir / "brightened_ref.bin"
        compile_to_binary(str(primary_ll), str(brightened_reference))
        recovery_reference = (
            str(brightened_reference)
            if brightened_reference.is_file()
            else sample.original_elf_path
        )

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
            attachment_paths.insert(0, str(primary_ll))
            attachment_hashes.insert(0, sha256_file(primary_ll))
        representation = RepresentationArtifact(
            method=MethodId.P0,
            primary_path=str(primary_ll),
            primary_sha256=sha256_file(primary_ll),
            byte_count=primary_ll.stat().st_size,
            token_count=max(1, (primary_ll.stat().st_size + 2) // 3),
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
                "delifted_ll_path": str(primary_ll),
                "delifted_ll_sha256": sha256_file(primary_ll),
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
                "max_iterations": 5,
                "representation_contract": (
                    "delifted LLVM IR plus P0 Ghidra pseudocode"
                    if attach_clean_ir
                    else "P0 Ghidra pseudocode only; delifted LLVM IR retained locally"
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
                    + 2
                )
                // 3,
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
        brightened_ll = Path(representation.primary_path)
        if (
            not brightened_ll.is_file()
            or sha256_file(brightened_ll) != representation.primary_sha256
        ):
            raise RepresentationError(
                "P0_REPRESENTATION_HASH_MISMATCH",
                "Frozen P0 brightened LLVM IR is missing or changed",
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
            return _run_fuzzer_sync(
                fuzzer,
                iterations=iterations,
                generator=generator,
                timeout=timeout,
            )

        brightened_bc = Path(
            str(provenance.get("brightened_bc_path") or "")
        )
        if (
            not brightened_bc.is_file()
            or sha256_file(brightened_bc)
            != provenance.get("brightened_bc_sha256")
        ):
            raise RepresentationError(
                "P0_BRIGHTENED_BC_HASH_MISMATCH",
                "Frozen P0 brightened bitcode is missing or changed",
            )
        precheck = run_legacy_fuzz(
            recovery_reference,
            sample.original_elf_path,
            iterations=int(self.config["p0"]["fuzz_iterations"]),
            timeout=float(self.config["p0"]["fuzz_timeout_sec"]),
        )
        precheck_path = variant / "p0_internal_precheck.json"
        atomic_write_json(precheck_path, precheck)
        if not confirmed_equivalence_pass(precheck):
            raise P0PrecheckFailed(precheck)

        def recovery_fuzz(candidate_path: str) -> Dict[str, Any]:
            return run_legacy_fuzz(
                candidate_path,
                recovery_reference,
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
            ir_text=brightened_ll.read_text(
                encoding="utf-8", errors="replace"
            ),
            output_recovered_c_path=str(output_candidate),
            case_output_dir=str(generation_dir),
            metadata={
                "original_binary": sample.original_elf_path,
                "recovery_reference_binary": recovery_reference,
                "recovery_reference_label": (
                    "brightened.bc compiled"
                    if recovery_reference != sample.original_elf_path
                    else "original"
                ),
                "input_ir": str(brightened_ll),
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
            "max_iterations": 5,
            **model_freeze,
            "representation_sha256": sha256_file(brightened_ll),
            "pseudocode_sha256": sha256_file(prepared_pseudocode),
            "recovery_reference_sha256": sha256_file(recovery_reference),
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
                "success": result.success,
                "max_iterations": legacy_config.max_iterations,
                "generator_reason": generator_reason,
                "model_freeze": model_freeze,
                "quota": quota_metrics,
            },
        )
        atomic_write_json(
            generation_dir / "generation_manifest.json",
            generation.to_dict(),
        )
        return P0LegacyRun(
            representation=representation,
            generation=generation,
            internal_precheck=precheck,
            internal_recovery_report=result.fuzz_report,
            candidate_path=str(output_candidate),
        )
