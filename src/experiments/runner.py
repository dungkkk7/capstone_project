from __future__ import annotations

import datetime as dt
import os
import platform
import re
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import traceback
from pathlib import Path
from types import SimpleNamespace
from typing import Any, Dict

from llm_recovery.llm_recovery import (
    LLMEmptyResponseError,
    RecoveryError,
)

from .audit import (
    ARTIFACT_MANIFEST_PATH,
    AuditError,
    AuditLogger,
    create_artifact_manifest,
    verify_artifact_manifest,
    verify_event_log,
)
from .config import method_list
from .enums import MethodId, Stage, TerminalStatus
from .evaluation import (
    EvaluationError,
    build_candidate,
    build_union_corpus,
    discover_inputs,
    execute_reference,
    prepare_base_corpus,
    replay_candidate,
)
from .generation import (
    CandidateError,
    ContextOverflow,
    EmptyResponseError,
    LeakageError,
    generate_one_shot,
)
from .identity import read_dataset
from .models import RepresentationArtifact, SampleIdentity, VariantResult
from .p0_legacy import P0LegacyAdapter, P0PrecheckFailed
from .quota import QuotaWaitExceeded
from .representations import (
    A0Builder,
    B0Builder,
    RawLiftService,
    RepresentationError,
)
from .storage import (
    atomic_write_json,
    load_json,
    sha256_file,
    stable_json_sha256,
)
from .storage import sha256_text
from .prompts import (
    B0_PROMPT_POLICY_VERSION,
    B0_USER_TEMPLATE,
    ONE_SHOT_SYSTEM_PROMPT,
)
from llvm_pass.britening_ir import PASS_PIPELINE, PLUGINS


class RunIntegrityError(RuntimeError):
    pass


RUN_ID_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}")


def _git_state(project_root: str) -> Dict[str, Any]:
    commit = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=project_root,
        capture_output=True,
        text=True,
        check=False,
    )
    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=project_root,
        capture_output=True,
        text=True,
        check=False,
    )
    status_text = status.stdout
    return {
        "git_commit": commit.stdout.strip() if commit.returncode == 0 else None,
        "git_dirty": bool(status_text.strip()),
        "git_status_sha256": sha256_text(status_text),
        "git_status": status_text.splitlines(),
    }


def _command_version(command: list[str]) -> str:
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        lines = (result.stdout or result.stderr or "").strip().splitlines()
        return lines[0][:500] if lines else f"exit={result.returncode}"
    except Exception as exc:
        return f"unavailable: {exc}"


def _source_snapshot(project_root: Path) -> Dict[str, Any]:
    entries = []
    source_root = project_root / "src"
    allowed_suffixes = {".py", ".java"}
    for path in sorted(source_root.rglob("*")):
        if not path.is_file():
            continue
        relative_parts = path.relative_to(source_root).parts
        if "build" in relative_parts or "__pycache__" in relative_parts:
            continue
        if path.suffix.lower() not in allowed_suffixes:
            continue
        entries.append(
            {
                "path": path.relative_to(project_root).as_posix(),
                "size_bytes": path.stat().st_size,
                "sha256": sha256_file(path),
            }
        )
    return {
        "file_count": len(entries),
        "sha256": stable_json_sha256(entries),
    }


class ExperimentRunner:
    def __init__(
        self,
        dataset_path: str,
        config: Dict[str, Any],
        run_id: str,
        *,
        pilot: int | None = None,
        sample_ids: list[str] | None = None,
    ):
        self.dataset_path = str(Path(dataset_path).resolve())
        self.config = config
        if not RUN_ID_PATTERN.fullmatch(run_id):
            raise RunIntegrityError(
                "run_id must match [A-Za-z0-9][A-Za-z0-9._-]{0,127}"
            )
        self.run_id = run_id
        self.project_root = Path(config["_project_root"])
        self.run_root = Path(config["paths"]["result_root"]) / run_id
        self.audit = AuditLogger(self.run_root, run_id)
        self.samples = read_dataset(
            self.dataset_path,
            self.project_root,
            pilot=pilot,
            sample_ids=sample_ids,
        )
        self.methods = method_list(config)
        self.execution_order = [
            MethodId(value)
            for value in config["experiment"].get(
                "variant_order",
                [method.value for method in self.methods],
            )
        ]
        self.lift_service = RawLiftService(config)
        self.a0_builder = A0Builder(config, self.lift_service)
        self.b0_builder = B0Builder(config)
        self.p0_adapter = P0LegacyAdapter(config, self.lift_service)

    def initialize(self) -> None:
        self.run_root.mkdir(parents=True, exist_ok=True)
        manifest_path = self.run_root / "experiment_manifest.json"
        resumed = manifest_path.is_file()
        sample_manifest = [sample.to_dict() for sample in self.samples]
        git_state = _git_state(str(self.project_root))
        if self.config["experiment"].get("require_clean_git", False):
            if not git_state.get("git_commit"):
                raise RunIntegrityError(
                    "Primary reproducibility mode requires a Git commit"
                )
            if git_state.get("git_dirty"):
                changed = git_state.get("git_status") or []
                preview = "; ".join(changed[:12])
                suffix = " ..." if len(changed) > 12 else ""
                raise RunIntegrityError(
                    "Primary reproducibility mode requires a clean Git worktree. "
                    "Commit or stash the intended changes, or use "
                    "configs/experiment_three_case.yaml for development. "
                    f"Changed paths: {preview}{suffix}"
                )
        manifest = {
            "schema_version": "3.0",
            "run_id": self.run_id,
            "created_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "dataset_path": self.dataset_path,
            "dataset_sha256": sha256_file(self.dataset_path),
            "sample_ids": [sample.sample_id for sample in self.samples],
            "study_scope": self.config["experiment"]["study_scope"],
            "sample_manifest_sha256": stable_json_sha256(sample_manifest),
            "source_snapshot": _source_snapshot(self.project_root),
            "methods": [method.value for method in self.methods],
            "variant_order": [
                method.value for method in self.execution_order
            ],
            "protocols": {
                "P0": "legacy_iterative_repair_max_5",
                "A0": "strict_one_shot",
                "B0": "strict_one_shot",
            },
            "phase_contract": {
                "preparation": (
                    "freeze corpus and P0/A0/B0 model evidence; zero LLM calls"
                ),
                "processing": (
                    "LLM generation, build, fuzz discovery, union replay, "
                    "and raw differential results"
                ),
                "evaluation": (
                    "metrics, statistics, analysis, reports, and visualization; "
                    "zero LLM/fuzz calls"
                ),
            },
            "config_sha256": self.config["_config_sha256"],
            "model": {
                "provider": self.config["llm"]["provider"],
                "model_id": self.config["llm"]["model_id"],
                "location": self.config["llm"]["location"],
                "temperature": self.config["llm"]["temperature"],
                "top_p": self.config["llm"]["top_p"],
                "candidate_count": self.config["llm"].get(
                    "candidate_count", 1
                ),
                "max_output_tokens": self.config["llm"][
                    "max_output_tokens"
                ],
                "context_window_tokens": self.config["llm"][
                    "context_window_tokens"
                ],
                "model_spec_source": self.config["llm"].get(
                    "model_spec_source"
                ),
                "model_spec_verified_date": self.config["llm"].get(
                    "model_spec_verified_date"
                ),
                "thinking_level": self.config["llm"].get(
                    "thinking_level"
                ),
            },
            "pricing": {
                "plan": self.config["llm"].get("pricing_plan"),
                "usd_per_million_input_tokens": self.config["llm"].get(
                    "pricing_usd_per_million_input_tokens"
                ),
                "usd_per_million_output_tokens": self.config["llm"].get(
                    "pricing_usd_per_million_output_tokens"
                ),
                "long_context_threshold_tokens": self.config["llm"].get(
                    "pricing_long_context_threshold_tokens"
                ),
                "usd_per_million_input_tokens_long_context": self.config[
                    "llm"
                ].get("pricing_usd_per_million_input_tokens_long_context"),
                "usd_per_million_output_tokens_long_context": self.config[
                    "llm"
                ].get("pricing_usd_per_million_output_tokens_long_context"),
                "source": self.config["llm"].get("pricing_source"),
                "verified_date": self.config["llm"].get(
                    "pricing_verified_date"
                ),
                "estimate_scope": (
                    "provider-reported input plus response-and-reasoning "
                    "output tokens only; "
                    "not a provider invoice"
                ),
            },
            "environment": {
                "python": platform.python_version(),
                "platform": platform.platform(),
                **git_state,
            },
            "tool_versions": {
                "clang": _command_version(
                    [self.config["build"]["compiler"], "--version"]
                ),
                "llvm_dis": _command_version(
                    [self.config["paths"]["llvm_dis"], "--version"]
                ),
                "ghidra": _command_version(
                    [self.config["paths"]["ghidra_headless"], "-version"]
                ),
                "ida_path": self.config["paths"]["ida_disassembler"],
                "p0_pass_pipeline_sha256": sha256_text(PASS_PIPELINE),
                "p0_pass_plugin_sha256": {
                    plugin: (
                        sha256_file(
                            self.project_root
                            / "src"
                            / "llvm_pass"
                            / plugin
                        )
                        if (
                            self.project_root
                            / "src"
                            / "llvm_pass"
                            / plugin
                        ).is_file()
                        else "missing"
                    )
                    for plugin in PLUGINS
                },
                "b0_ghidra_script_sha256": sha256_file(
                    self.b0_builder.script
                ),
            },
        }
        if manifest_path.is_file():
            existing = load_json(manifest_path)
            if existing.get("config_sha256") != self.config["_config_sha256"]:
                raise RunIntegrityError(
                    "Refusing resume: experiment config hash changed"
                )
            if existing.get("dataset_sha256") != manifest["dataset_sha256"]:
                raise RunIntegrityError(
                    "Refusing resume: experiment dataset hash changed"
                )
            if existing.get("run_id") != self.run_id:
                raise RunIntegrityError("Refusing resume: run_id changed")
            if (
                existing.get("sample_manifest_sha256")
                != manifest["sample_manifest_sha256"]
            ):
                raise RunIntegrityError(
                    "Refusing resume: enrolled sample set or identity changed; "
                    "use a new run_id"
                )
            if existing.get("methods") != manifest["methods"]:
                raise RunIntegrityError(
                    "Refusing resume: enrolled method order/set changed"
                )
            if existing.get("variant_order") != manifest["variant_order"]:
                raise RunIntegrityError(
                    "Refusing resume: variant execution order changed"
                )
            for frozen_field in (
                "protocols",
                "phase_contract",
                "model",
                "tool_versions",
            ):
                if existing.get(frozen_field) != manifest[frozen_field]:
                    raise RunIntegrityError(
                        "Refusing resume: frozen "
                        f"{frozen_field} fingerprint changed"
                    )
            if existing.get("source_snapshot") != manifest["source_snapshot"]:
                if not self.config.get("_p0_backfill", False):
                    raise RunIntegrityError(
                        "Refusing resume: frozen source_snapshot changed"
                    )
            if existing.get("environment") != manifest["environment"]:
                if not self.config.get("_p0_backfill", False):
                    raise RunIntegrityError(
                        "Refusing resume: frozen environment changed"
                    )
                self.audit.log(
                    "p0_backfill_environment_changed",
                    stage=Stage.GENERATION.value,
                    status="RUNNING",
                    payload={
                        "previous_environment": existing.get("environment"),
                        "current_environment": manifest["environment"],
                    },
                )
                self.audit.log(
                    "p0_backfill_source_snapshot_changed",
                    stage=Stage.GENERATION.value,
                    status="RUNNING",
                    payload={
                        "previous_source_snapshot": existing.get(
                            "source_snapshot"
                        ),
                        "current_source_snapshot": manifest[
                            "source_snapshot"
                        ],
                    },
                )
        else:
            atomic_write_json(manifest_path, manifest)
        atomic_write_json(
            self.run_root / "config_resolved.json",
            {
                key: value
                for key, value in self.config.items()
                if not key.startswith("_")
            },
        )
        for sample in self.samples:
            sample_dir = self._sample_dir(sample)
            sample_dir.mkdir(parents=True, exist_ok=True)
            atomic_write_json(sample_dir / "identity.json", sample.to_dict())
            for method in self.methods:
                variant_dir = sample_dir / method.value
                variant_dir.mkdir(parents=True, exist_ok=True)
                result_path = variant_dir / "result.json"
                if not result_path.exists():
                    enrolled = VariantResult.enrolled(
                        self.run_id, sample, method
                    )
                    atomic_write_json(result_path, enrolled.to_dict())
        self.audit.log(
            (
                "experiment_resumed"
                if resumed
                else "experiment_initialized"
            ),
            stage=Stage.ENROLLED.value,
            status="READY",
            payload={
                "dataset_sha256": manifest["dataset_sha256"],
                "config_sha256": self.config["_config_sha256"],
                "sample_count": len(self.samples),
                "study_scope": manifest["study_scope"],
                "methods": [method.value for method in self.methods],
                "variant_order": [
                    method.value for method in self.execution_order
                ],
            },
        )

    def _sample_dir(self, sample: SampleIdentity) -> Path:
        return self.run_root / "samples" / sample.sample_id

    def _result_path(self, sample: SampleIdentity, method: MethodId) -> Path:
        return self._sample_dir(sample) / method.value / "result.json"

    def _persist(self, sample: SampleIdentity, result: VariantResult) -> None:
        path = self._result_path(sample, result.method)
        atomic_write_json(path, result.to_dict())
        self.audit.log(
            "variant_checkpoint",
            sample_id=sample.sample_id,
            method=result.method.value,
            stage=result.final_stage.value,
            status=result.terminal_status.value,
            payload={
                "result_path": path.relative_to(self.run_root).as_posix(),
                "result_sha256": sha256_file(path),
                "e2e_pass": result.e2e_pass,
                "failure_code": result.failure_code,
                "representation_sha256": (
                    (result.representation or {}).get("primary_sha256")
                ),
                "candidate_sha256": (
                    (result.generation or {}).get("candidate_sha256")
                ),
                "model_call_count": (
                    (result.generation or {}).get("model_call_count")
                ),
                "iterations": (result.generation or {}).get("iterations"),
                "api_attempt_count": (
                    (result.generation or {}).get("api_attempt_count")
                ),
                "quota_throttle_count": (
                    (result.generation or {}).get("quota_throttle_count")
                ),
                "quota_wait_duration_ms": (
                    (result.generation or {}).get(
                        "quota_wait_duration_ms"
                    )
                ),
                "timing_ms": dict(result.timing),
            },
        )

    def _quota_event_callback(
        self,
        sample: SampleIdentity,
        result: VariantResult,
    ):
        def handle(event_type: str, payload: Dict[str, Any]) -> None:
            result.final_stage = Stage.GENERATION
            result.provenance["quota"] = dict(payload)
            result.timing["quota_wait_duration_ms"] = int(
                payload.get("quota_wait_duration_ms", 0)
            )
            if event_type in {
                "quota_throttled",
                "quota_wait_started",
                "quota_deferred",
            }:
                result.terminal_status = TerminalStatus.WAITING_FOR_QUOTA
            elif event_type == "quota_resumed":
                result.terminal_status = TerminalStatus.CANCELLED
            self.audit.log(
                event_type,
                sample_id=sample.sample_id,
                method=result.method.value,
                stage=Stage.GENERATION.value,
                status=result.terminal_status.value,
                payload=payload,
            )
            self._persist(sample, result)

        return handle

    def _seal_audit(self, command: str) -> None:
        self.audit.log(
            "artifacts_sealed",
            stage=Stage.FINALIZED.value,
            status="SEALED",
            payload={"command": command},
        )
        create_artifact_manifest(self.run_root, run_id=self.run_id)

    def prepare(self) -> None:
        self.initialize()
        self.audit.log(
            "command_started",
            status="RUNNING",
            payload={"command": "prepare", "phase": "preparation"},
        )
        self._run_samples(
            "preparation",
            self._prepare_input_sample,
            lambda sample: self._sample_input_prepared(sample),
        )
        self.audit.log(
            "command_work_completed",
            status="COMPLETED",
            payload={"command": "prepare", "phase": "preparation"},
        )
        self._seal_audit("prepare")

    def _base_corpus_manifest_path(self, sample: SampleIdentity) -> Path:
        return (
            self._sample_dir(sample)
            / "common"
            / "base_corpus"
            / "corpus_manifest.json"
        )

    def _representation_manifest_path(
        self, sample: SampleIdentity, method: MethodId
    ) -> Path:
        return (
            self._sample_dir(sample)
            / method.value
            / "representation"
            / "representation_manifest.json"
        )

    def _load_prepared_representation(
        self, sample: SampleIdentity, method: MethodId
    ) -> RepresentationArtifact:
        manifest_path = self._representation_manifest_path(sample, method)
        if not manifest_path.is_file():
            raise RepresentationError(
                f"{method.value}_REPRESENTATION_MISSING",
                f"Missing frozen representation: {manifest_path}",
            )
        payload = load_json(manifest_path)
        if payload.get("method") != method.value:
            raise RepresentationError(
                f"{method.value}_REPRESENTATION_METHOD_MISMATCH",
                f"Unexpected method in {manifest_path}",
            )
        primary_path = Path(str(payload.get("primary_path") or ""))
        if (
            not primary_path.is_file()
            or sha256_file(primary_path) != payload.get("primary_sha256")
        ):
            raise RepresentationError(
                f"{method.value}_REPRESENTATION_HASH_MISMATCH",
                f"Frozen primary artifact is missing or changed: {primary_path}",
            )
        attachment_paths = payload.get("attachment_paths") or []
        attachment_hashes = payload.get("attachment_sha256") or []
        if len(attachment_paths) != len(attachment_hashes):
            raise RepresentationError(
                f"{method.value}_ATTACHMENT_MANIFEST_INVALID",
                "Frozen evidence paths and hashes have different lengths",
            )
        for path_value, expected_hash in zip(
            attachment_paths, attachment_hashes
        ):
            path = Path(str(path_value))
            if not path.is_file() or sha256_file(path) != expected_hash:
                raise RepresentationError(
                    f"{method.value}_ATTACHMENT_HASH_MISMATCH",
                    f"Frozen evidence is missing or changed: {path}",
                )
        data = dict(payload)
        data["method"] = method
        return RepresentationArtifact(**data)

    def _load_prepared_base_inputs(
        self, sample: SampleIdentity
    ) -> list[Dict[str, Any]]:
        """Load and validate the deterministic input corpus for one sample."""

        manifest_path = self._base_corpus_manifest_path(sample)
        if not manifest_path.is_file():
            raise EvaluationError(
                f"MISSING_BASE_CORPUS_MANIFEST: {manifest_path}"
            )
        payload = load_json(manifest_path)
        if payload.get("sample_id") != sample.sample_id:
            raise EvaluationError("BASE_CORPUS_SAMPLE_ID_MISMATCH")
        inputs = payload.get("inputs")
        if not isinstance(inputs, list) or not inputs:
            raise EvaluationError("BASE_CORPUS_EMPTY")
        for item in inputs:
            if not isinstance(item, dict):
                raise EvaluationError("BASE_CORPUS_ENTRY_INVALID")
            path = Path(str(item.get("path") or ""))
            if not path.is_file():
                raise EvaluationError(
                    f"BASE_CORPUS_INPUT_MISSING: {path}"
                )
            if sha256_file(path) != item.get("sha256"):
                raise EvaluationError(
                    f"BASE_CORPUS_INPUT_HASH_MISMATCH: {path}"
                )
            if path.stat().st_size != int(item.get("size", -1)):
                raise EvaluationError(
                    f"BASE_CORPUS_INPUT_SIZE_MISMATCH: {path}"
                )
        if stable_json_sha256(inputs) != payload.get("corpus_sha256"):
            raise EvaluationError("BASE_CORPUS_MANIFEST_HASH_MISMATCH")
        return inputs

    def _prepared_input_available(self, sample: SampleIdentity) -> bool:
        try:
            self._load_prepared_base_inputs(sample)
        except (EvaluationError, OSError, TypeError, ValueError):
            return False
        return True

    def _sample_input_prepared(self, sample: SampleIdentity) -> bool:
        return bool(
            self.config["experiment"].get("resume", True)
            and self._sample_preparation_ready(sample)
        )

    def _sample_preparation_ready(self, sample: SampleIdentity) -> bool:
        if self._p0_backfill_eligible(sample):
            return False
        if not self._prepared_input_available(sample):
            return False
        manifest_path = self._sample_dir(sample) / "preparation_manifest.json"
        if not manifest_path.is_file():
            return False
        try:
            manifest = load_json(manifest_path)
        except (OSError, ValueError):
            return False
        if (
            manifest.get("sample_id") != sample.sample_id
            or manifest.get("llm_calls") != 0
            or manifest.get("fuzz_calls") != 0
            or not manifest.get("ready_for_processing")
        ):
            return False
        for method in self.execution_order:
            result_path = self._result_path(sample, method)
            if not result_path.is_file():
                return False
            data = load_json(result_path)
            if (
                data.get("final_stage") == Stage.FINALIZED.value
                and not self._is_retryable_llm_failure(data)
            ):
                continue
            try:
                representation = self._load_prepared_representation(
                    sample, method
                )
            except RepresentationError:
                return False
            if not (representation.provenance or {}).get(
                "prepared_without_llm", method is not MethodId.P0
            ):
                return False
        return True

    def _prepare_input_sample(self, sample: SampleIdentity) -> None:
        print(
            f"[experiment] prepare sample={sample.sample_id}",
            flush=True,
        )
        self.audit.log(
            "sample_preparation_started",
            sample_id=sample.sample_id,
            stage=Stage.ENROLLED.value,
            status="RUNNING",
            payload={"llm_calls": 0, "fuzz_calls": 0},
        )
        started = time.perf_counter()
        try:
            output_dir = (
                self._sample_dir(sample) / "common" / "base_corpus"
            )
            inputs = prepare_base_corpus(sample, output_dir, self.config)
            # Read back the persisted files so preparation cannot be marked
            # complete when its manifest or payloads are inconsistent.
            self._load_prepared_base_inputs(sample)
        except Exception as exc:
            self.audit.log(
                "sample_preparation_failed",
                sample_id=sample.sample_id,
                stage=Stage.ENROLLED.value,
                status="FAILED",
                payload={
                    "llm_calls": 0,
                    "fuzz_calls": 0,
                    "error": str(exc),
                },
            )
            raise

        representation_summary: Dict[str, Any] = {}
        for method in self.execution_order:
            result_path = self._result_path(sample, method)
            if method is MethodId.P0 and self._p0_backfill_eligible(sample):
                self._archive_p0_backfill(sample)
            if (
                self.config["experiment"].get("resume", True)
                and result_path.is_file()
            ):
                existing = load_json(result_path)
                if (
                    existing.get("final_stage") == Stage.FINALIZED.value
                    and not self._is_retryable_llm_failure(existing)
                ):
                    representation_summary[method.value] = {
                        "status": "terminal",
                        "failure_code": existing.get("failure_code"),
                    }
                    continue
                try:
                    frozen = self._load_prepared_representation(
                        sample, method
                    )
                except RepresentationError:
                    frozen = None
                if frozen is not None:
                    representation_summary[method.value] = {
                        "status": "ready_for_llm",
                        "representation_sha256": frozen.primary_sha256,
                    }
                    continue

            result = VariantResult.enrolled(self.run_id, sample, method)
            variant_dir = self._sample_dir(sample) / method.value
            method_started = time.perf_counter()
            self.audit.log(
                "variant_preparation_started",
                sample_id=sample.sample_id,
                method=method.value,
                stage=Stage.REPRESENTATION.value,
                status="RUNNING",
                payload={"llm_calls": 0, "fuzz_calls": 0},
            )
            try:
                if method is MethodId.P0:
                    representation = self.p0_adapter.prepare(
                        sample,
                        self._sample_dir(sample) / "common",
                        variant_dir,
                    )
                elif method is MethodId.A0:
                    representation = self.a0_builder.build(
                        sample,
                        self._sample_dir(sample) / "common",
                        variant_dir / "representation",
                    )
                else:
                    representation = self.b0_builder.build(
                        sample, variant_dir / "representation"
                    )
                result.representation = representation.to_dict()
                result.final_stage = Stage.GENERATION
                result.provenance["prepared_without_llm"] = True
                result.timing["preparation_duration_ms"] = int(
                    (time.perf_counter() - method_started) * 1000
                )
                self._persist(sample, result)
                representation_summary[method.value] = {
                    "status": "ready_for_llm",
                    "representation_sha256": representation.primary_sha256,
                    "evidence_sha256": representation.attachment_sha256,
                }
                self.audit.log(
                    "variant_preparation_completed",
                    sample_id=sample.sample_id,
                    method=method.value,
                    stage=Stage.REPRESENTATION.value,
                    status="READY_FOR_LLM",
                    payload={
                        "llm_calls": 0,
                        "fuzz_calls": 0,
                        "representation_sha256": (
                            representation.primary_sha256
                        ),
                    },
                )
            except Exception as exc:
                self._finalize_exception(
                    sample, result, exc, method_started
                )
                representation_summary[method.value] = {
                    "status": "terminal",
                    "failure_code": result.failure_code,
                }
                if self.config["experiment"].get("fail_fast"):
                    raise

        preparation_manifest = {
            "schema_version": "1.0",
            "sample_id": sample.sample_id,
            "llm_calls": 0,
            "fuzz_calls": 0,
            "base_corpus_manifest": str(
                self._base_corpus_manifest_path(sample)
            ),
            "representations": representation_summary,
            "ready_for_processing": True,
            "duration_ms": int((time.perf_counter() - started) * 1000),
        }
        atomic_write_json(
            self._sample_dir(sample) / "preparation_manifest.json",
            preparation_manifest,
        )
        self.audit.log(
            "sample_preparation_completed",
            sample_id=sample.sample_id,
            stage=Stage.REPRESENTATION.value,
            status="READY_FOR_PROCESSING",
            payload={
                "llm_calls": 0,
                "fuzz_calls": 0,
                "input_count": len(inputs),
                "representations": representation_summary,
                "duration_ms": int(
                    (time.perf_counter() - started) * 1000
                ),
            },
        )

    def precompute(self) -> None:
        """Backward-compatible alias for the full preparation phase."""

        self.prepare()

    def _sample_complete(self, sample: SampleIdentity) -> bool:
        if not self.config["experiment"].get("resume", True):
            return False
        return self._sample_processing_output_ready(sample)

    def _sample_processing_output_ready(
        self, sample: SampleIdentity
    ) -> bool:
        return bool(
            self._sample_processing_ready(sample)
            and self._processing_manifest_ready(sample)
        )

    def _processing_manifest_ready(self, sample: SampleIdentity) -> bool:
        path = self._sample_dir(sample) / "processing_manifest.json"
        if not path.is_file():
            return False
        try:
            payload = load_json(path)
        except (OSError, ValueError):
            return False
        observed_methods = {
            item.get("method")
            for item in payload.get("raw_results") or []
            if isinstance(item, dict)
        }
        return bool(
            payload.get("sample_id") == sample.sample_id
            and payload.get("ready_for_evaluation")
            and observed_methods
            == {method.value for method in self.methods}
        )

    def _sample_processing_ready(self, sample: SampleIdentity) -> bool:
        """Return whether raw per-variant comparison data is finalized."""

        if self._p0_backfill_eligible(sample):
            return False
        for method in self.execution_order:
            path = self._result_path(sample, method)
            if not path.is_file():
                return False
            data = load_json(path)
            if data.get("final_stage") != Stage.FINALIZED.value:
                return False
            # A provider cancellation may have finalized the variant before
            # the process can be resumed. Keep that sample eligible for a
            # later run so a transient LLM failure is not treated as a final
            # scientific outcome forever.
            if self._is_retryable_llm_failure(data):
                return False
        return True

    @staticmethod
    def _is_retryable_llm_failure(data: Dict[str, Any]) -> bool:
        return (
            data.get("terminal_status")
            == TerminalStatus.LLM_REQUEST_FAILED.value
            and str(data.get("failure_code") or "").endswith(
                "_LLM_REQUEST_FAILED"
            )
        )

    def _sample_generation_complete(self, sample: SampleIdentity) -> bool:
        """Return whether generation may be skipped during a resumed run."""
        if not self.config["experiment"].get("resume", True):
            return False
        return self._sample_generation_ready(sample)

    def _sample_generation_ready(self, sample: SampleIdentity) -> bool:
        """Return whether every method is terminal or ready for evaluation."""

        if self._p0_backfill_eligible(sample):
            return False
        for method in self.execution_order:
            path = self._result_path(sample, method)
            if not path.is_file():
                return False
            data = load_json(path)
            if data.get("final_stage") == Stage.FINALIZED.value:
                if self._is_retryable_llm_failure(data):
                    return False
                continue
            if data.get("terminal_status") == (
                TerminalStatus.WAITING_FOR_QUOTA.value
            ):
                return False
            generation = data.get("generation") or {}
            build = data.get("build") or {}
            candidate_path = generation.get("candidate_path")
            executable_path = build.get("executable_path")
            if (
                not candidate_path
                or not Path(candidate_path).is_file()
                or not build.get("ok")
                or not executable_path
                or not Path(executable_path).is_file()
            ):
                return False
        return True

    def _p0_backfill_eligible(self, sample: SampleIdentity) -> bool:
        """Return whether an existing finalized P0 result should be retried."""

        if not self.config.get("_p0_backfill", False):
            return False
        result_path = self._result_path(sample, MethodId.P0)
        if not result_path.is_file():
            return False
        data = load_json(result_path)
        if data.get("final_stage") != Stage.FINALIZED.value:
            return False
        return str(data.get("failure_code") or "").startswith("P0_")

    def _archive_p0_backfill(self, sample: SampleIdentity) -> None:
        """Archive one skipped P0 attempt before rebuilding it in-place."""

        p0_dir = self._sample_dir(sample) / MethodId.P0.value
        stamp = dt.datetime.now(dt.timezone.utc).strftime(
            "%Y%m%dT%H%M%S%fZ"
        )
        history_dir = p0_dir / "backfill_history" / stamp
        history_dir.mkdir(parents=True, exist_ok=True)
        moved: list[str] = []
        for name in (
            "result.json",
            "representation",
            "generation",
            "processing",
            "evaluation",
        ):
            source = p0_dir / name
            if not source.exists():
                continue
            shutil.move(str(source), str(history_dir / name))
            moved.append(name)
        self.audit.log(
            "p0_backfill_reset",
            sample_id=sample.sample_id,
            method=MethodId.P0.value,
            stage=Stage.GENERATION.value,
            status="RUNNING",
            payload={"archived_path": str(history_dir), "moved": moved},
        )
        print(
            f"[experiment] P0 backfill sample={sample.sample_id} "
            f"archived={history_dir}",
            flush=True,
        )

    def _sample_processing_blockers(
        self, sample: SampleIdentity
    ) -> list[str]:
        """Return variants that could still contribute discovery inputs.

        A union corpus may only be frozen after every nonterminal variant has
        completed generation and build. In particular, evaluating the other
        methods while one method is WAITING_FOR_QUOTA would permanently omit
        that method's later discovery inputs from the shared corpus.
        """
        blockers: list[str] = []
        for method in self.methods:
            result_path = self._result_path(sample, method)
            if not result_path.is_file():
                blockers.append(f"{method.value}:missing_result")
                continue
            data = load_json(result_path)
            if data.get("final_stage") == Stage.FINALIZED.value:
                continue
            if data.get("terminal_status") == (
                TerminalStatus.WAITING_FOR_QUOTA.value
            ):
                blockers.append(f"{method.value}:waiting_for_quota")
                continue
            generation = data.get("generation") or {}
            build = data.get("build") or {}
            candidate_path = generation.get("candidate_path")
            executable_path = build.get("executable_path")
            if (
                not generation
                or not candidate_path
                or not build.get("ok")
                or not executable_path
            ):
                blockers.append(f"{method.value}:generation_not_ready")
        return blockers

    def _sample_evaluation_blockers(
        self, sample: SampleIdentity
    ) -> list[str]:
        """Compatibility alias for the former phase terminology."""

        return self._sample_processing_blockers(sample)

    def run(self) -> bool:
        self.initialize()
        workflow = [
            "preparation",
            "processing",
            "evaluation",
        ]
        self.audit.log(
            "command_started",
            status="RUNNING",
            payload={"command": "run", "workflow": workflow},
        )
        print(
            "[experiment] E2E phase 1/3 PREPARATION: corpus + frozen LLM evidence",
            flush=True,
        )
        self._run_samples(
            "preparation",
            self._prepare_input_sample,
            lambda sample: self._sample_input_prepared(sample),
        )
        print(
            "[experiment] E2E phase 2/3 PROCESSING: LLM + build + fuzz/compare",
            flush=True,
        )
        self._run_samples(
            "llm-build",
            self._generate_sample,
            lambda sample: self._sample_generation_complete(sample),
        )
        pending_generation = [
            sample.sample_id
            for sample in self.samples
            if not self._sample_generation_ready(sample)
        ]
        if pending_generation:
            self.audit.log(
                "generation_deferred",
                stage=Stage.GENERATION.value,
                status="WAITING_FOR_QUOTA",
                payload={"pending_sample_ids": pending_generation},
            )
            print(
                "[experiment] generation deferred; pending sample(s) saved "
                "for backfill: "
                + ", ".join(pending_generation),
                flush=True,
            )
            self._seal_audit("run-deferred-generation")
            return False
        self._run_samples(
            "fuzz-compare",
            self._process_comparison_sample,
            lambda sample: self._sample_complete(sample),
        )
        pending_processing = [
            sample.sample_id
            for sample in self.samples
            if not self._sample_processing_output_ready(sample)
        ]
        if pending_processing:
            self.audit.log(
                "processing_incomplete",
                stage=Stage.UNION_REPLAY.value,
                status="INCOMPLETE",
                payload={"pending_sample_ids": pending_processing},
            )
            self._seal_audit("run-incomplete-processing")
            return False
        print(
            "[experiment] E2E phase 3/3 EVALUATION: metrics + analysis + visualization",
            flush=True,
        )
        self._aggregate_outputs()
        self.audit.log(
            "command_work_completed",
            status="COMPLETED",
            payload={"command": "run", "workflow": workflow},
        )
        print(
            "[experiment] sealing artifacts and verifying integrity",
            flush=True,
        )
        self._seal_audit("run")
        verify_run_integrity(
            self.run_root,
            self.samples,
            self.methods,
            attach_clean_ir=bool(self.config["p0"].get("attach_clean_ir", False)),
        )
        print(
            f"[experiment] E2E complete: {self.run_root}",
            flush=True,
        )
        return True

    def process(self) -> bool:
        self.initialize()
        self.audit.log(
            "command_started", status="RUNNING", payload={"command": "process"}
        )
        unprepared = [
            sample.sample_id
            for sample in self.samples
            if not self._sample_preparation_ready(sample)
        ]
        if unprepared:
            raise RunIntegrityError(
                "Processing requires frozen preparation artifacts for: "
                + ", ".join(unprepared)
            )
        self._run_samples(
            "llm-build",
            self._generate_sample,
            lambda sample: self._sample_generation_complete(sample),
        )
        if not all(
            self._sample_generation_ready(sample) for sample in self.samples
        ):
            self._seal_audit("process-deferred-generation")
            return False
        self._run_samples(
            "fuzz-compare",
            self._process_comparison_sample,
            lambda sample: self._sample_complete(sample),
        )
        completed = all(
            self._sample_processing_output_ready(sample)
            for sample in self.samples
        )
        self.audit.log(
            "command_work_completed",
            status="COMPLETED" if completed else "INCOMPLETE",
            payload={"command": "process"},
        )
        self._seal_audit("process")
        return completed

    def generate(self) -> bool:
        """Backward-compatible alias for the standardized processing phase."""

        return self.process()

    def evaluate(self) -> Dict[str, Any]:
        self.initialize()
        self.audit.log(
            "command_started", status="RUNNING", payload={"command": "evaluate"}
        )
        incomplete = [
            sample.sample_id
            for sample in self.samples
            if not self._sample_processing_output_ready(sample)
        ]
        if incomplete:
            raise RunIntegrityError(
                "Evaluation requires finalized raw comparison data for: "
                + ", ".join(incomplete)
            )
        aggregate = self._aggregate_outputs()
        self.audit.log(
            "command_work_completed",
            status="COMPLETED",
            payload={"command": "evaluate"},
        )
        self._seal_audit("evaluate")
        verify_run_integrity(
            self.run_root,
            self.samples,
            self.methods,
            attach_clean_ir=bool(
                self.config["p0"].get("attach_clean_ir", False)
            ),
        )
        return aggregate

    def _aggregate_outputs(self) -> Dict[str, Any]:
        from .reporting import aggregate_run

        started = time.perf_counter()
        aggregate = aggregate_run(self.run_root, self.config)
        output_paths = [
            self.run_root / "aggregate" / name
            for name in (
                "metrics.json",
                "metrics_long.csv",
                "statistics.json",
                "report.md",
                "dashboard.html",
                "figures_manifest.json",
            )
        ]
        atomic_write_json(
            self.run_root / "evaluation_manifest.json",
            {
                "schema_version": "1.0",
                "phase": "evaluation",
                "input_scope": "frozen processing result.json files",
                "llm_calls": 0,
                "fuzz_calls": 0,
                "duration_ms": int(
                    (time.perf_counter() - started) * 1000
                ),
                "outputs": [
                    {
                        "path": str(path),
                        "sha256": sha256_file(path),
                        "size_bytes": path.stat().st_size,
                    }
                    for path in output_paths
                    if path.is_file()
                ],
            },
        )
        self.audit.log(
            "aggregate_generated",
            stage=Stage.FINALIZED.value,
            status="COMPLETED",
            payload={
                "variant_count": aggregate["variant_count"],
                "metric_count": aggregate.get("metric_count"),
                "figure_count": aggregate.get("figure_count"),
            },
        )
        return aggregate

    def aggregate(self) -> Dict[str, Any]:
        self.initialize()
        self.audit.log(
            "command_started", status="RUNNING", payload={"command": "aggregate"}
        )
        aggregate = self._aggregate_outputs()
        self.audit.log(
            "command_work_completed",
            status="COMPLETED",
            payload={"command": "aggregate"},
        )
        self._seal_audit("aggregate")
        return aggregate

    def verify(self) -> Dict[str, Any]:
        return verify_run_integrity(
            self.run_root,
            self.samples,
            self.methods,
            attach_clean_ir=bool(self.config["p0"].get("attach_clean_ir", False)),
        )

    def _run_samples(self, phase: str, operation, is_complete) -> None:
        """Run independent samples concurrently while preserving per-sample order.

        ``operation`` is deliberately called once per sample. The operation
        itself still executes the configured method order, so a sample cannot
        observe a partially generated sibling method. Each sample owns its
        artifact directories and quota checkpoints; AuditLogger serializes
        append operations with its file lock.
        """
        pending = []
        for sample in self.samples:
            if is_complete(sample):
                if phase == "generate":
                    print(f"[experiment] resume: skip completed {sample.sample_id}")
                continue
            pending.append(sample)

        workers = max(
            1, int(self.config["experiment"].get("sample_workers", 1))
        )
        workers = min(workers, max(1, len(pending)))
        print(
            f"[experiment] {phase}: {len(pending)} pending sample(s), "
            f"workers={workers}",
            flush=True,
        )
        if not pending:
            return
        if workers == 1:
            for sample in pending:
                operation(sample)
            return

        with ThreadPoolExecutor(
            max_workers=workers,
            thread_name_prefix=f"experiment-{phase}",
        ) as executor:
            futures = {
                executor.submit(operation, sample): sample
                for sample in pending
            }
            for future in as_completed(futures):
                sample = futures[future]
                try:
                    future.result()
                    print(
                        f"[experiment] {phase} complete sample={sample.sample_id}",
                        flush=True,
                    )
                except Exception:
                    # Keep the existing fail-fast behavior: an uncaught
                    # sample-level failure aborts the command, while the
                    # operation's own per-method failure handling remains
                    # unchanged.
                    for other in futures:
                        if other is not future:
                            other.cancel()
                    raise

    def _generate_sample(self, sample: SampleIdentity) -> None:
        print(
            f"[experiment] process sample={sample.sample_id} stage=llm start",
            flush=True,
        )
        self.audit.log(
            "sample_processing_started",
            sample_id=sample.sample_id,
            stage=Stage.GENERATION.value,
            status="RUNNING",
        )
        sample_dir = self._sample_dir(sample)
        if not self._sample_preparation_ready(sample):
            raise RunIntegrityError(
                f"Sample {sample.sample_id} is not prepared; run prepare first"
            )

        for method in self.execution_order:
            existing_path = self._result_path(sample, method)
            if self.config["experiment"].get("resume", True) and existing_path.is_file():
                existing = load_json(existing_path)
                retryable_llm_failure = self._is_retryable_llm_failure(
                    existing
                )
                if (
                    existing.get("final_stage") == Stage.FINALIZED.value
                    and not retryable_llm_failure
                ):
                    continue
                if existing.get("generation") and (existing.get("build") or {}).get("ok"):
                    continue
            existing = (
                load_json(existing_path)
                if existing_path.is_file()
                else None
            )
            result = VariantResult.enrolled(self.run_id, sample, method)
            if existing and existing.get("representation"):
                result.representation = existing["representation"]
                result.timing.update(existing.get("timing") or {})
                result.provenance.update(existing.get("provenance") or {})
            variant_dir = sample_dir / method.value
            started = time.perf_counter()
            print(
                f"[experiment] sample={sample.sample_id} method={method.value} "
                "stage=llm start",
                flush=True,
            )
            self.audit.log(
                "variant_generation_started",
                sample_id=sample.sample_id,
                method=method.value,
                stage=Stage.GENERATION.value,
                status="RUNNING",
            )
            try:
                representation = self._load_prepared_representation(
                    sample, method
                )
                if method is MethodId.P0:
                    p0_started = time.perf_counter()
                    p0 = self.p0_adapter.process(
                        sample,
                        variant_dir,
                        representation=representation,
                        quota_event_callback=self._quota_event_callback(
                            sample, result
                        ),
                    )
                    result.timing["p0_legacy_pipeline_duration_ms"] = int(
                        (time.perf_counter() - p0_started) * 1000
                    )
                    representation = p0.representation
                    generation = p0.generation
                    candidate_path = p0.candidate_path
                    result.provenance.update(
                        {
                            "protocol": "legacy_iterative_repair",
                            "max_iterations": 5,
                            "internal_precheck_passed": True,
                        }
                    )
                    print(
                        f"[experiment] sample={sample.sample_id} method=P0 "
                        "stage=llm+repair done "
                        f"duration_ms={result.timing['p0_legacy_pipeline_duration_ms']}",
                        flush=True,
                    )
                elif method is MethodId.A0:
                    generation_started = time.perf_counter()
                    generation = generate_one_shot(
                        method,
                        representation,
                        variant_dir / "generation",
                        self.config,
                        log_context=sample.sample_id,
                        quota_event_callback=self._quota_event_callback(
                            sample, result
                        ),
                    )
                    result.timing["generation_duration_ms"] = int(
                        (time.perf_counter() - generation_started) * 1000
                    )
                    print(
                        f"[experiment] sample={sample.sample_id} method=A0 "
                        "stage=llm done "
                        f"duration_ms={result.timing['generation_duration_ms']}",
                        flush=True,
                    )
                    candidate_path = generation.candidate_path
                    result.provenance["protocol"] = "strict_one_shot"
                else:
                    generation_started = time.perf_counter()
                    generation = generate_one_shot(
                        method,
                        representation,
                        variant_dir / "generation",
                        self.config,
                        log_context=sample.sample_id,
                        quota_event_callback=self._quota_event_callback(
                            sample, result
                        ),
                    )
                    result.timing["generation_duration_ms"] = int(
                        (time.perf_counter() - generation_started) * 1000
                    )
                    print(
                        f"[experiment] sample={sample.sample_id} method=B0 "
                        "stage=llm done "
                        f"duration_ms={result.timing['generation_duration_ms']}",
                        flush=True,
                    )
                    candidate_path = generation.candidate_path
                    result.provenance["protocol"] = "strict_one_shot"

                result.representation = representation.to_dict()
                result.generation = generation.to_dict()
                result.final_stage = Stage.BUILD
                print(
                    f"[experiment] sample={sample.sample_id} method={method.value} "
                    "stage=build start",
                    flush=True,
                )
                build = build_candidate(
                    candidate_path,
                    variant_dir / "build",
                    self.config,
                )
                result.build = build.to_dict()
                print(
                    f"[experiment] sample={sample.sample_id} method={method.value} "
                    f"stage=build done ok={build.ok} duration_ms={build.duration_ms}",
                    flush=True,
                )
                result.timing["generation_pipeline_duration_ms"] = int(
                    (time.perf_counter() - started) * 1000
                )
                if not build.ok:
                    result.terminal_status = TerminalStatus.BUILD_FAILED
                    result.failure_code = "CANDIDATE_BUILD_FAILED"
                    result.failure_message = (
                        f"Compiler returned {build.return_code}; "
                        f"see {build.stderr_path}"
                    )
                    result.final_stage = Stage.FINALIZED
                    result.timing["total_duration_ms"] = result.timing[
                        "generation_pipeline_duration_ms"
                    ]
                    self._persist(sample, result)
                    continue
                result.integrity.update(
                    {
                        "candidate_immutable": True,
                        "reference_is_original_elf": True,
                        "leakage_scan_passed": True,
                    }
                )
                result.final_stage = Stage.FUZZ_DISCOVERY
                self._persist(sample, result)
            except QuotaWaitExceeded as exc:
                result.terminal_status = TerminalStatus.WAITING_FOR_QUOTA
                result.failure_code = (
                    f"{method.value}_QUOTA_WAIT_EXCEEDED"
                )
                result.failure_message = str(exc)
                result.final_stage = Stage.GENERATION
                result.timing["generation_pipeline_duration_ms"] = int(
                    (time.perf_counter() - started) * 1000
                )
                self._persist(sample, result)
                if self.config["experiment"].get("fail_fast"):
                    raise
            except Exception as exc:
                self._finalize_exception(sample, result, exc, started)
                if self.config["experiment"].get("fail_fast"):
                    raise

    def _process_comparison_sample(self, sample: SampleIdentity) -> None:
        """Produce frozen raw differential data; do not aggregate metrics."""

        blockers = self._sample_processing_blockers(sample)
        if blockers:
            self.audit.log(
                "sample_processing_comparison_deferred",
                sample_id=sample.sample_id,
                stage=Stage.FUZZ_DISCOVERY.value,
                status="WAITING_FOR_GENERATION",
                payload={"blockers": blockers},
            )
            print(
                f"[experiment] defer processing sample={sample.sample_id}: "
                + ", ".join(blockers)
            )
            return
        print(f"[experiment] fuzz/compare sample={sample.sample_id}")
        self.audit.log(
            "sample_processing_comparison_started",
            sample_id=sample.sample_id,
            stage=Stage.FUZZ_DISCOVERY.value,
            status="RUNNING",
        )
        sample_dir = self._sample_dir(sample)
        common_dir = sample_dir / "common"
        base_inputs = self._load_prepared_base_inputs(sample)
        print(
            f"[experiment] sample={sample.sample_id} stage=base-corpus "
            f"ready inputs={len(base_inputs)}",
            flush=True,
        )
        active: Dict[MethodId, Dict[str, Any]] = {}
        for method in self.methods:
            result_path = self._result_path(sample, method)
            if not result_path.is_file():
                continue
            data = load_json(result_path)
            if data.get("terminal_status") == (
                TerminalStatus.WAITING_FOR_QUOTA.value
            ):
                continue
            if data.get("final_stage") == Stage.FINALIZED.value:
                continue
            build_data = data.get("build") or {}
            generation_data = data.get("generation") or {}
            executable_path = build_data.get("executable_path")
            if (
                not build_data.get("ok")
                or not executable_path
                or not Path(executable_path).is_file()
            ):
                result = VariantResult.from_dict(data)
                self._finalize_exception(
                    sample,
                    result,
                    EvaluationError("MISSING_FROZEN_EXECUTABLE"),
                    time.perf_counter(),
                )
                continue
            candidate_path = generation_data.get("candidate_path")
            if not candidate_path or not Path(candidate_path).is_file():
                result = VariantResult.from_dict(data)
                self._finalize_exception(
                    sample,
                    result,
                    EvaluationError("MISSING_FROZEN_CANDIDATE"),
                    time.perf_counter(),
                )
                continue
            if sha256_file(candidate_path) != generation_data.get(
                "candidate_sha256"
            ):
                result = VariantResult.from_dict(data)
                self._finalize_exception(
                    sample,
                    result,
                    EvaluationError("CANDIDATE_MUTATED"),
                    time.perf_counter(),
                )
                continue
            active[method] = {
                "result": VariantResult.from_dict(data),
                "build": SimpleNamespace(**build_data),
                "candidate_path": candidate_path,
                "started": time.perf_counter(),
            }

        discoveries = []
        for method, state in active.items():
            variant_dir = sample_dir / method.value
            try:
                print(
                    f"[experiment] sample={sample.sample_id} method={method.value} "
                    "stage=fuzz-discovery start",
                    flush=True,
                )
                discovered = discover_inputs(
                    sample,
                    state["candidate_path"],
                    base_inputs,
                    method.value,
                    variant_dir / "processing" / "discovery",
                    self.config,
                )
                discoveries.append(discovered)
                print(
                    f"[experiment] sample={sample.sample_id} method={method.value} "
                    f"stage=fuzz-discovery done discovered={len(discovered)}",
                    flush=True,
                )
            except Exception as exc:
                result = state["result"]
                self._finalize_exception(
                    sample, result, exc, state["started"]
                )

                state["comparison_failed"] = True

        union, corpus_hash = build_union_corpus(
            base_inputs, discoveries, common_dir
        )
        self.audit.log(
            "union_corpus_built",
            sample_id=sample.sample_id,
            stage=Stage.UNION_REPLAY.value,
            status="COMPLETED",
            payload={
                "input_count": len(union),
                "union_corpus_sha256": corpus_hash,
            },
        )
        print(
            f"[experiment] sample={sample.sample_id} stage=union-corpus "
            f"done inputs={len(union)}",
            flush=True,
        )
        print(
            f"[experiment] sample={sample.sample_id} stage=reference-execution start",
            flush=True,
        )
        reference = execute_reference(
            sample,
            union,
            common_dir / "reference_outputs",
            self.config,
        )
        print(
            f"[experiment] sample={sample.sample_id} stage=reference-execution "
            f"done inputs={len(reference)}",
            flush=True,
        )
        for method, state in active.items():
            if state.get("comparison_failed"):
                continue
            result: VariantResult = state["result"]
            build = state["build"]
            try:
                print(
                    f"[experiment] sample={sample.sample_id} method={method.value} "
                    "stage=union-replay start",
                    flush=True,
                )
                replay = replay_candidate(
                    build.executable_path,
                    build.executable_sha256,
                    union,
                    corpus_hash,
                    reference,
                    sample_dir / method.value / "processing",
                    self.config,
                )
                print(
                    f"[experiment] sample={sample.sample_id} method={method.value} "
                    f"stage=union-replay done matches={replay['matches']} "
                    f"mismatches={replay['mismatches']} "
                    f"inconclusive={replay['inconclusive']}",
                    flush=True,
                )
                result.evaluation = replay
                result.integrity.update(
                    {
                        "reference_sha256": sample.original_elf_sha256,
                        "union_corpus_sha256": corpus_hash,
                        "candidate_immutable": True,
                    }
                )
                if not replay.get("smoke_runnable", True):
                    status = TerminalStatus.NOT_RUNNABLE
                elif replay["behavior_pass"]:
                    status = TerminalStatus.PASS
                elif replay["mismatches"] > 0:
                    status = TerminalStatus.BEHAVIOR_MISMATCH
                else:
                    status = TerminalStatus.EVAL_INCONCLUSIVE
                result.terminal_status = status
                result.e2e_pass = status is TerminalStatus.PASS
                result.final_stage = Stage.FINALIZED
                evaluation_duration = int(
                    (time.perf_counter() - state["started"]) * 1000
                )
                result.timing["evaluation_duration_ms"] = evaluation_duration
                result.timing[
                    "processing_comparison_duration_ms"
                ] = evaluation_duration
                result.timing["total_duration_ms"] = (
                    result.timing.get("generation_pipeline_duration_ms", 0)
                    + evaluation_duration
                )
                self._persist(sample, result)
            except Exception as exc:
                self._finalize_exception(
                    sample, result, exc, state["started"]
                )

        raw_results = []
        for method in self.methods:
            result_path = self._result_path(sample, method)
            data = load_json(result_path)
            raw_results.append(
                {
                    "method": method.value,
                    "result_path": str(result_path),
                    "result_sha256": sha256_file(result_path),
                    "terminal_status": data.get("terminal_status"),
                    "failure_code": data.get("failure_code"),
                    "has_differential_data": bool(data.get("evaluation")),
                }
            )
        atomic_write_json(
            sample_dir / "processing_manifest.json",
            {
                "schema_version": "1.0",
                "sample_id": sample.sample_id,
                "phase": "processing",
                "union_corpus_sha256": corpus_hash,
                "reference_sha256": sample.original_elf_sha256,
                "raw_results": raw_results,
                "ready_for_evaluation": True,
            },
        )
        self.audit.log(
            "sample_processing_completed",
            sample_id=sample.sample_id,
            stage=Stage.FINALIZED.value,
            status="READY_FOR_EVALUATION",
            payload={
                "union_corpus_sha256": corpus_hash,
                "raw_result_count": len(raw_results),
            },
        )

    def _evaluate_sample(self, sample: SampleIdentity) -> None:
        """Compatibility alias for callers using the former phase name."""

        self._process_comparison_sample(sample)

    def _finalize_exception(
        self,
        sample: SampleIdentity,
        result: VariantResult,
        exc: Exception,
        started: float,
    ) -> None:
        if result.method is MethodId.P0:
            self._recover_partial_p0_artifacts(sample, result)
        if isinstance(exc, ContextOverflow):
            status = TerminalStatus.CONTEXT_OVERFLOW
            code = f"{result.method.value}_CONTEXT_OVERFLOW"
        elif isinstance(exc, RepresentationError):
            status = (
                TerminalStatus.INFRA_ERROR
                if "HASH_MISMATCH" in exc.code
                or "WRONG_DECOMPILE_TARGET" in exc.code
                or "FORBIDDEN" in exc.code
                else TerminalStatus.REPRESENTATION_FAILED
            )
            code = exc.code
        elif isinstance(exc, P0PrecheckFailed):
            status = TerminalStatus.REPRESENTATION_FAILED
            code = "P0_SEMANTIC_PRECHECK_FAILED"
            result.provenance["p0_internal_precheck"] = exc.report
        elif isinstance(exc, LeakageError):
            status = TerminalStatus.INFRA_ERROR
            code = f"{result.method.value}_FORBIDDEN_ARTIFACT_IN_REQUEST"
        elif isinstance(exc, EmptyResponseError):
            status = TerminalStatus.LLM_EMPTY_RESPONSE
            code = f"{result.method.value}_LLM_EMPTY_RESPONSE"
            result.generation = exc.generation
        elif isinstance(exc, CandidateError):
            status = TerminalStatus.INVALID_CANDIDATE
            code = f"{result.method.value}_INVALID_CANDIDATE"
        elif isinstance(exc, LLMEmptyResponseError):
            status = TerminalStatus.LLM_EMPTY_RESPONSE
            code = f"{result.method.value}_LLM_EMPTY_RESPONSE"
        elif isinstance(exc, RecoveryError):
            status = TerminalStatus.LLM_REQUEST_FAILED
            code = f"{result.method.value}_LLM_REQUEST_FAILED"
        elif isinstance(exc, EvaluationError):
            status = TerminalStatus.INFRA_ERROR
            code = str(exc)
        else:
            status = TerminalStatus.INFRA_ERROR
            code = f"{result.method.value}_UNHANDLED_ERROR"
        result.terminal_status = status
        result.failure_code = code
        result.failure_message = str(exc)
        result.provenance["traceback"] = traceback.format_exc()
        result.final_stage = Stage.FINALIZED
        elapsed = int(
            (time.perf_counter() - started) * 1000
        )
        if result.timing.get("generation_pipeline_duration_ms") is not None:
            result.timing["evaluation_duration_ms"] = elapsed
            result.timing["total_duration_ms"] = (
                result.timing["generation_pipeline_duration_ms"] + elapsed
            )
        else:
            result.timing["generation_pipeline_duration_ms"] = elapsed
            result.timing["total_duration_ms"] = elapsed
        self._persist(sample, result)
        print(
            f"[experiment] {sample.sample_id}/{result.method.value}: "
            f"{status.value} ({code}): {exc}"
        )

    def _recover_partial_p0_artifacts(
        self, sample: SampleIdentity, result: VariantResult
    ) -> None:
        """Preserve P0 work/counters when its legacy loop exits mid-protocol."""

        variant_dir = self._sample_dir(sample) / MethodId.P0.value
        representation_dir = variant_dir / "representation"
        generation_dir = variant_dir / "generation"
        brightened_ll = representation_dir / "brightened.ll"
        pseudocode = generation_dir / "ghidra_pseudocode.c"
        if (
            result.representation is None
            and brightened_ll.is_file()
            and pseudocode.is_file()
        ):
            attachment_paths = [str(pseudocode)]
            attachment_hashes = [sha256_file(pseudocode)]
            if self.config["p0"].get("attach_clean_ir", False):
                attachment_paths.insert(0, str(brightened_ll))
                attachment_hashes.insert(0, sha256_file(brightened_ll))
            evidence_bytes = sum(
                Path(path).stat().st_size for path in attachment_paths
            )
            result.representation = {
                "method": MethodId.P0.value,
                "primary_path": str(brightened_ll),
                "primary_sha256": sha256_file(brightened_ll),
                "byte_count": brightened_ll.stat().st_size,
                "token_count": max(
                    1, (brightened_ll.stat().st_size + 2) // 3
                ),
                "builder_version": self.p0_adapter.VERSION,
                "attachment_paths": attachment_paths,
                "attachment_sha256": attachment_hashes,
                "tool_versions": {},
                "provenance": {
                    "source_sha256": sample.original_elf_sha256,
                    "protocol": "legacy_iterative_repair",
                    "max_iterations": 5,
                    "partial_recovery": True,
                },
                "evidence_byte_count": evidence_bytes,
                "evidence_token_count": max(
                    1, (evidence_bytes + 2) // 3
                ),
            }
        if result.generation is not None:
            return
        quota_state_path = generation_dir / "quota_state.json"
        recovery_state_path = generation_dir / "recovery_state.json"
        quota_state = (
            load_json(quota_state_path)
            if quota_state_path.is_file()
            else {}
        )
        recovery_state = (
            load_json(recovery_state_path)
            if recovery_state_path.is_file()
            else {}
        )
        responses = sorted(
            generation_dir.glob("recovery_iter*.response.txt")
        )
        metas = sorted(generation_dir.glob("recovery_iter*.meta.json"))
        accepted_calls = int(
            quota_state.get("accepted_model_call_count", len(responses))
        )
        if not accepted_calls and not recovery_state:
            return
        usage_input = usage_output = usage_thinking = usage_total = 0
        last_meta: Dict[str, Any] = {}
        for meta_path in metas:
            try:
                last_meta = load_json(meta_path)
            except (OSError, ValueError):
                continue
            usage = last_meta.get("usage_metadata") or {}
            usage_input += int(
                usage.get(
                    "prompt_token_count",
                    usage.get("promptTokenCount", 0),
                )
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
                usage.get(
                    "total_token_count",
                    usage.get("totalTokenCount", 0),
                )
                or 0
            )
        candidates = sorted(generation_dir.glob("recovered_iter*.c"))
        candidate_path = candidates[-1] if candidates else None
        llm = self.config["llm"]
        result.generation = {
            "request_sha256": recovery_state.get("request_sha256"),
            "candidate_path": str(candidate_path) if candidate_path else None,
            "candidate_sha256": (
                sha256_file(candidate_path) if candidate_path else None
            ),
            "logical_generation_count": accepted_calls,
            "model_call_count": accepted_calls,
            "response_path": str(responses[-1]) if responses else (
                quota_state.get("response_cache_path") or ""
            ),
            "input_tokens": usage_input or None,
            "output_tokens": usage_output or None,
            "thinking_tokens": usage_thinking or None,
            "billable_output_tokens": (
                usage_output + usage_thinking
                if usage_output or usage_thinking
                else None
            ),
            "total_tokens": usage_total or (
                usage_input + usage_output + usage_thinking
                if usage_input or usage_output or usage_thinking
                else None
            ),
            "latency_ms": None,
            "iterations": int(
                recovery_state.get("iteration", accepted_calls or 1)
            ),
            "api_attempt_count": int(
                quota_state.get("api_attempt_count", len(responses))
            ),
            "quota_throttle_count": int(
                quota_state.get("quota_throttle_count", 0)
            ),
            "quota_wait_duration_ms": int(
                quota_state.get("quota_wait_duration_ms", 0)
            ),
            "response_metadata": {
                **last_meta,
                "protocol": "legacy_iterative_repair",
                "partial_recovery": True,
                "model_freeze": {
                    "model_id": llm["model_id"],
                    "location": llm["location"],
                    "temperature": llm["temperature"],
                    "top_p": llm["top_p"],
                    "candidate_count": llm.get("candidate_count", 1),
                    "max_output_tokens": llm["max_output_tokens"],
                    "thinking_level": llm.get("thinking_level"),
                },
                "quota": quota_state,
            },
        }


def verify_run_integrity(
    run_root: str | Path,
    samples: list[SampleIdentity],
    methods: list[MethodId],
    *,
    attach_clean_ir: bool = False,
) -> Dict[str, Any]:
    root = Path(run_root)
    errors = []
    audit_report: Dict[str, Any] = {"required": False}
    experiment_manifest_path = root / "experiment_manifest.json"
    experiment_manifest = (
        load_json(experiment_manifest_path)
        if experiment_manifest_path.is_file()
        else {}
    )
    resolved_config_path = root / "config_resolved.json"
    resolved_config = (
        load_json(resolved_config_path)
        if resolved_config_path.is_file()
        else {}
    )
    llm_config = resolved_config.get("llm") or {}
    expected_model_freeze = (
        {
            "model_id": llm_config.get("model_id"),
            "location": llm_config.get("location"),
            "temperature": llm_config.get("temperature"),
            "top_p": llm_config.get("top_p"),
            "candidate_count": llm_config.get("candidate_count", 1),
            "max_output_tokens": llm_config.get("max_output_tokens"),
            "thinking_level": llm_config.get("thinking_level"),
        }
        if llm_config
        else None
    )
    audit_required = (
        experiment_manifest.get("schema_version") == "2.1"
        or (root / "audit" / "events.jsonl").is_file()
    )
    audit_report["required"] = audit_required
    if audit_required:
        try:
            audit_report["event_chain"] = verify_event_log(
                root / "audit" / "events.jsonl"
            )
        except AuditError as exc:
            errors.append(f"audit event chain failed: {exc}")
        try:
            audit_report["artifact_manifest"] = verify_artifact_manifest(root)
        except AuditError as exc:
            errors.append(f"artifact manifest failed: {exc}")
    elif (root / ARTIFACT_MANIFEST_PATH).is_file():
        errors.append("artifact manifest exists without an audit event log")
    for sample in samples:
        preparation_path = (
            root / "samples" / sample.sample_id / "preparation_manifest.json"
        )
        if not preparation_path.is_file():
            errors.append(
                f"missing preparation manifest: {sample.sample_id}"
            )
        else:
            preparation = load_json(preparation_path)
            if preparation.get("llm_calls") != 0:
                errors.append(
                    f"preparation invoked LLM: {sample.sample_id}"
                )
            if preparation.get("fuzz_calls") != 0:
                errors.append(
                    f"preparation invoked fuzzer: {sample.sample_id}"
                )
            prepared_methods = set(
                (preparation.get("representations") or {}).keys()
            )
            if prepared_methods != {method.value for method in methods}:
                errors.append(
                    f"preparation method set mismatch: {sample.sample_id}"
                )
        processing_path = (
            root / "samples" / sample.sample_id / "processing_manifest.json"
        )
        if not processing_path.is_file():
            errors.append(
                f"missing processing manifest: {sample.sample_id}"
            )
        else:
            processing = load_json(processing_path)
            if not processing.get("ready_for_evaluation"):
                errors.append(
                    f"processing not ready for evaluation: {sample.sample_id}"
                )
            raw_methods = {
                item.get("method")
                for item in processing.get("raw_results") or []
                if isinstance(item, dict)
            }
            if raw_methods != {method.value for method in methods}:
                errors.append(
                    f"processing method set mismatch: {sample.sample_id}"
                )
        results = []
        for method in methods:
            path = root / "samples" / sample.sample_id / method.value / "result.json"
            if not path.is_file():
                errors.append(f"missing result: {sample.sample_id}/{method.value}")
                continue
            result = load_json(path)
            results.append(result)
            identity = result.get("identity") or {}
            if identity.get("original_elf_sha256") != (
                sample.original_elf_sha256
            ):
                errors.append(
                    f"enrolled ELF identity mismatch: {sample.sample_id}/{method.value}"
                )
            if identity.get("input_contract_sha256") != (
                sample.input_contract_sha256
            ):
                errors.append(
                    "input-contract identity mismatch: "
                    f"{sample.sample_id}/{method.value}"
                )
            if identity.get("seed_manifest_sha256") != (
                sample.seed_manifest_sha256
            ):
                errors.append(
                    f"seed identity mismatch: {sample.sample_id}/{method.value}"
                )
            if result.get("final_stage") != Stage.FINALIZED.value:
                errors.append(
                    f"nonterminal result: {sample.sample_id}/{method.value}"
                )
            generation = result.get("generation") or {}
            representation = result.get("representation") or {}
            primary_path = representation.get("primary_path")
            if primary_path:
                if not Path(primary_path).is_file():
                    errors.append(
                        f"missing representation: {sample.sample_id}/{method.value}"
                    )
                elif sha256_file(primary_path) != representation.get(
                    "primary_sha256"
                ):
                    errors.append(
                        "representation hash mismatch: "
                        f"{sample.sample_id}/{method.value}"
                    )
            attachment_paths = representation.get("attachment_paths") or []
            attachment_hashes = representation.get("attachment_sha256") or []
            if len(attachment_paths) != len(attachment_hashes):
                errors.append(
                    "representation attachment manifest mismatch: "
                    f"{sample.sample_id}/{method.value}"
                )
            for attachment_path, attachment_hash in zip(
                attachment_paths, attachment_hashes
            ):
                if not Path(attachment_path).is_file():
                    errors.append(
                        "missing representation attachment: "
                        f"{sample.sample_id}/{method.value}/{attachment_path}"
                    )
                elif sha256_file(attachment_path) != attachment_hash:
                    errors.append(
                        "representation attachment hash mismatch: "
                        f"{sample.sample_id}/{method.value}/{attachment_path}"
                    )
            if attachment_paths and all(
                Path(path).is_file() for path in attachment_paths
            ):
                evidence_bytes = sum(
                    Path(path).stat().st_size for path in attachment_paths
                )
                if representation.get("evidence_byte_count") != evidence_bytes:
                    errors.append(
                        "representation evidence size mismatch: "
                        f"{sample.sample_id}/{method.value}"
                    )
            candidate_path = generation.get("candidate_path")
            if candidate_path and Path(candidate_path).is_file():
                if sha256_file(candidate_path) != generation.get(
                    "candidate_sha256"
                ):
                    errors.append(
                        f"candidate hash mismatch: {sample.sample_id}/{method.value}"
                    )
            if method in {MethodId.A0, MethodId.B0} and generation:
                if generation.get("logical_generation_count") != 1:
                    errors.append(
                        f"one-shot violation: {sample.sample_id}/{method.value}"
                    )
                if generation.get("model_call_count") != 1:
                    errors.append(
                        "accepted-call violation: "
                        f"{sample.sample_id}/{method.value}"
                    )
                request_path = (
                    root
                    / "samples"
                    / sample.sample_id
                    / method.value
                    / "generation"
                    / "request.json"
                )
                if not request_path.is_file():
                    errors.append(
                        f"missing one-shot request: {sample.sample_id}/{method.value}"
                    )
                else:
                    request = load_json(request_path)
                    request_without_hash = dict(request)
                    recorded_request_sha256 = request_without_hash.pop(
                        "request_sha256", None
                    )
                    if stable_json_sha256(request_without_hash) != (
                        recorded_request_sha256
                    ):
                        errors.append(
                            "one-shot request hash mismatch: "
                            f"{sample.sample_id}/{method.value}"
                        )
                    if recorded_request_sha256 != generation.get(
                        "request_sha256"
                    ):
                        errors.append(
                            "generation/request identity mismatch: "
                            f"{sample.sample_id}/{method.value}"
                        )
                    if request.get("representation_sha256") != (
                        representation.get("primary_sha256")
                    ):
                        errors.append(
                            "request/representation mismatch: "
                            f"{sample.sample_id}/{method.value}"
                        )
                    if expected_model_freeze is not None:
                        observed_freeze = {
                            "model_id": request.get("model_id"),
                            "location": request.get("location"),
                            **(request.get("decoding") or {}),
                        }
                        if observed_freeze != expected_model_freeze:
                            errors.append(
                                "model freeze mismatch: "
                                f"{sample.sample_id}/{method.value}"
                            )
            if method is MethodId.B0 and generation:
                request_path = (
                    root
                    / "samples"
                    / sample.sample_id
                    / "B0"
                    / "generation"
                    / "request.json"
                )
                if not request_path.is_file():
                    errors.append(f"missing B0 request: {sample.sample_id}")
                else:
                    request = load_json(request_path)
                    policy = request.get("prompt_policy") or {}
                    if request.get("system_prompt") != ONE_SHOT_SYSTEM_PROMPT:
                        errors.append(
                            f"B0 system prompt drift: {sample.sample_id}"
                        )
                    if policy.get("policy_version") != B0_PROMPT_POLICY_VERSION:
                        errors.append(
                            f"B0 prompt policy drift: {sample.sample_id}"
                        )
                    if not request.get("user_prompt", "").startswith(
                        B0_USER_TEMPLATE.split("{GHIDRA_PSEUDOCODE}", 1)[0]
                    ):
                        errors.append(
                            f"B0 user prompt drift: {sample.sample_id}"
                        )
                    if not (request.get("forbidden_scan") or {}).get("passed"):
                        errors.append(
                            f"B0 leakage scan failed: {sample.sample_id}"
                        )
                provenance = representation.get("provenance") or {}
                if provenance.get("source_sha256") != sample.original_elf_sha256:
                    errors.append(f"B0 target mismatch: {sample.sample_id}")
            if method is MethodId.A0 and representation:
                provenance = representation.get("provenance") or {}
                if provenance.get("pass_pipeline") != []:
                    errors.append(f"A0 pass contamination: {sample.sample_id}")
                request_path = (
                    root
                    / "samples"
                    / sample.sample_id
                    / "A0"
                    / "generation"
                    / "request.json"
                )
                if request_path.is_file() and not (
                    load_json(request_path).get("forbidden_scan") or {}
                ).get("passed"):
                    errors.append(f"A0 leakage scan failed: {sample.sample_id}")
            if method is MethodId.P0 and generation:
                if generation.get("iterations", 0) > 5:
                    errors.append(
                        f"P0 exceeded five iterations: {sample.sample_id}"
                    )
                if generation.get("model_call_count", 0) > 5:
                    errors.append(
                        f"P0 exceeded five accepted calls: {sample.sample_id}"
                    )
                expected_p0_attachments = 2 if attach_clean_ir else 1
                if len(attachment_paths) != expected_p0_attachments:
                    errors.append(
                        f"P0 strict representation incomplete: {sample.sample_id}"
                    )
                elif not attachment_paths[-1].endswith(".c") or (
                    expected_p0_attachments == 2
                    and not attachment_paths[0].endswith(".ll")
                ):
                    errors.append(
                        f"P0 strict attachment roles invalid: {sample.sample_id}"
                    )
                observed_model_freeze = (
                    generation.get("response_metadata") or {}
                ).get("model_freeze")
                if expected_model_freeze is not None and (
                    observed_model_freeze != expected_model_freeze
                ):
                    errors.append(
                        f"P0 model freeze mismatch: {sample.sample_id}"
                    )
            if generation:
                api_attempts = generation.get("api_attempt_count")
                accepted_calls = generation.get("model_call_count", 0)
                if (
                    api_attempts is not None
                    and int(api_attempts) < int(accepted_calls)
                ):
                    errors.append(
                        "API attempts below accepted calls: "
                        f"{sample.sample_id}/{method.value}"
                    )
                if int(generation.get("quota_wait_duration_ms", 0)) < 0:
                    errors.append(
                        "negative quota wait: "
                        f"{sample.sample_id}/{method.value}"
                    )
                response_tokens = generation.get("output_tokens")
                thinking_tokens = generation.get("thinking_tokens")
                billable_tokens = generation.get(
                    "billable_output_tokens"
                )
                if (
                    response_tokens is not None
                    or thinking_tokens is not None
                ):
                    expected_billable = int(response_tokens or 0) + int(
                        thinking_tokens or 0
                    )
                    if billable_tokens is None or int(
                        billable_tokens
                    ) != expected_billable:
                        errors.append(
                            "billable output token mismatch: "
                            f"{sample.sample_id}/{method.value}"
                        )
                    total_tokens = generation.get("total_tokens")
                    input_tokens = generation.get("input_tokens")
                    if (
                        total_tokens is not None
                        and input_tokens is not None
                        and int(total_tokens)
                        < int(input_tokens) + expected_billable
                    ):
                        errors.append(
                            "provider total token count below components: "
                            f"{sample.sample_id}/{method.value}"
                        )
        corpus_hashes = {
            (result.get("integrity") or {}).get("union_corpus_sha256")
            for result in results
            if result.get("evaluation")
        }
        corpus_hashes.discard(None)
        if len(corpus_hashes) > 1:
            errors.append(f"union corpus mismatch: {sample.sample_id}")
        reference_hashes = {
            (result.get("integrity") or {}).get("reference_sha256")
            for result in results
            if result.get("evaluation")
        }
        reference_hashes.discard(None)
        if reference_hashes and reference_hashes != {
            sample.original_elf_sha256
        }:
            errors.append(f"reference mismatch: {sample.sample_id}")
    evaluation_manifest_path = root / "evaluation_manifest.json"
    if not evaluation_manifest_path.is_file():
        errors.append("missing evaluation manifest")
    else:
        evaluation_manifest = load_json(evaluation_manifest_path)
        if evaluation_manifest.get("phase") != "evaluation":
            errors.append("evaluation manifest phase mismatch")
        if evaluation_manifest.get("llm_calls") != 0:
            errors.append("evaluation manifest reports LLM calls")
        if evaluation_manifest.get("fuzz_calls") != 0:
            errors.append("evaluation manifest reports fuzz calls")
    report = {
        "passed": not errors,
        "errors": errors,
        "audit": audit_report,
    }
    atomic_write_json(root / "integrity_report.json", report)
    if errors:
        raise RunIntegrityError("; ".join(errors))
    return report
