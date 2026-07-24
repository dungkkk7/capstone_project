from __future__ import annotations

import json
import os
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, Optional

from fuzzing_equi_check.fuzzing import SemanticFuzzer, compile_to_binary
from fuzzing_equi_check.input_contracts import resolve_input_contract
from llm_recovery.llm_recovery import (
    RecoveryConfig,
    RecoveryResult,
    VertexGemini,
    run_recovery_loop,
)
from llvm_pass.britening_ir import brighten_ir, read_native_contract_report
from main import _resolve_seed_paths, _run_fuzzer_sync, _select_generator

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

    VERSION = "p0-legacy-adapter-v1"

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
        variant = Path(variant_dir)
        representation_dir = variant / "representation"
        generation_dir = variant / "generation"
        representation_dir.mkdir(parents=True, exist_ok=True)
        generation_dir.mkdir(parents=True, exist_ok=True)

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
        native_report = read_native_contract_report(str(brightened_bc))
        if native_report:
            atomic_write_json(
                representation_dir / "native_contract_report.json", native_report
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

        # Freeze provider/decoding knobs from the experiment config for every
        # method.  This preserves P0's current representation, prompt,
        # compiler/fuzz-feedback loop and five-iteration bound while preventing
        # ambient LLM_RECOVERY_* variables from silently giving P0 a different
        # model or sampling policy than A0/B0.
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

        precheck = run_legacy_fuzz(
            str(brightened_bc),
            sample.original_elf_path,
            iterations=int(self.config["p0"]["fuzz_iterations"]),
            timeout=float(self.config["p0"]["fuzz_timeout_sec"]),
        )
        atomic_write_json(variant / "p0_internal_precheck.json", precheck)
        if not precheck.get("is_fully_equivalent", False):
            raise P0PrecheckFailed(precheck)

        brightened_reference = (
            representation_dir / "brightened_ref.bin"
        )
        compile_to_binary(str(brightened_bc), str(brightened_reference))
        recovery_reference = (
            str(brightened_reference)
            if brightened_reference.is_file()
            else sample.original_elf_path
        )

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
                    if recovery_reference == str(brightened_reference)
                    else "original"
                ),
                "input_ir": str(brightened_ll),
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
        p0_pseudocode = generation_dir / "ghidra_pseudocode.c"
        if not p0_pseudocode.is_file() or not p0_pseudocode.stat().st_size:
            raise RepresentationError(
                "P0_PSEUDOCODE_MISSING",
                "P0 strict representation requires its Ghidra pseudocode",
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
            "pseudocode_sha256": sha256_file(p0_pseudocode),
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
        representation = RepresentationArtifact(
            method=MethodId.P0,
            primary_path=str(brightened_ll),
            primary_sha256=sha256_file(brightened_ll),
            byte_count=brightened_ll.stat().st_size,
            token_count=max(
                1,
                (
                    len(brightened_ll.read_bytes())
                    + 2
                )
                // 3,
            ),
            builder_version=self.VERSION,
            attachment_paths=[
                str(brightened_ll),
                str(p0_pseudocode),
            ],
            attachment_sha256=[
                sha256_file(brightened_ll),
                sha256_file(p0_pseudocode),
            ],
            provenance={
                "source_sha256": sample.original_elf_sha256,
                "raw_lift_cache_key": lift["cache_key"],
                "brightened_bc_sha256": sha256_file(brightened_bc),
                "internal_reference": recovery_reference,
                "internal_reference_sha256": sha256_file(recovery_reference),
                "native_contract": native_report,
                "protocol": "legacy_iterative_repair",
                "max_iterations": 5,
                "representation_contract": (
                    "brightened LLVM IR plus P0 Ghidra pseudocode"
                ),
                "model_freeze": model_freeze,
            },
            evidence_byte_count=(
                brightened_ll.stat().st_size
                + p0_pseudocode.stat().st_size
            ),
            evidence_token_count=max(
                1,
                (
                    brightened_ll.stat().st_size
                    + p0_pseudocode.stat().st_size
                    + 2
                )
                // 3,
            ),
        )
        atomic_write_json(
            representation_dir / "representation_manifest.json",
            representation.to_dict(),
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
