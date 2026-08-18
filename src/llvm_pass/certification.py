"""Fail-closed transactional certification primitives for LLVM IR pipelines.

The module deliberately separates three concerns:

* an action produces a candidate artifact;
* gates collect evidence about that candidate;
* a policy decides whether the candidate may replace the last accepted
  checkpoint and whether it may be published as ``certified``.

A failed, missing, stale, or inconclusive candidate never replaces the last
accepted artifact.  This is a certification contract, not a claim of universal
program equivalence: the report records exactly which proof and empirical gates
were executed.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import tempfile
import time
import uuid
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping, Sequence


PROTOCOL_VERSION = "certifying-brightening-v1"
_STAGE_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


class Decision(str, Enum):
    """Canonical decision emitted by actions and evidence gates."""

    PASS = "pass"
    FAIL = "fail"
    INCONCLUSIVE = "inconclusive"
    ERROR = "error"
    SKIPPED = "skipped"


class OutputClass(str, Enum):
    """Authority attached to the final candidate.

    ``CERTIFIED`` means every gate named by the frozen certification policy
    passed.  It does not mean a mathematical proof for every possible input.
    """

    CERTIFIED = "certified"
    VALIDATED_COMPAT = "validated_compat"
    EVIDENCE_ONLY = "evidence_only"
    REJECTED = "rejected"


@dataclass(frozen=True)
class ActionResult:
    decision: Decision
    summary: str
    command: list[str] = field(default_factory=list)
    returncode: int | None = None
    stdout_path: str | None = None
    stderr_path: str | None = None
    metrics: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class GateResult:
    gate_id: str
    decision: Decision
    summary: str
    required: bool = True
    blocking: bool = True
    command: list[str] = field(default_factory=list)
    returncode: int | None = None
    evidence_paths: list[str] = field(default_factory=list)
    metrics: dict[str, Any] = field(default_factory=dict)
    duration_ms: int = 0


@dataclass(frozen=True)
class GateSpec:
    gate_id: str
    evaluate: Callable[[Path, Path], GateResult]
    required: bool = True
    blocking: bool = True


@dataclass
class StageResult:
    stage_id: str
    input_artifact: str
    candidate_artifact: str
    input_sha256: str | None
    candidate_sha256: str | None
    action: ActionResult
    gates: list[GateResult]
    accepted: bool
    started_at: str
    finished_at: str
    duration_ms: int


@dataclass(frozen=True)
class CertificationPolicy:
    """Frozen names of the gates required for final certification."""

    certification_gates: tuple[str, ...] = (
        "llvm_verify",
        "entrypoint",
        "bundle_link",
        "behavior",
        "native_contract",
        "native_compile",
    )
    structural_gates: tuple[str, ...] = (
        "llvm_verify",
        "entrypoint",
        "bundle_link",
    )
    behavior_gate: str = "behavior"
    native_gate: str = "native_contract"

    def validate(self) -> None:
        certification = tuple(self.certification_gates)
        structural = tuple(self.structural_gates)
        if not certification:
            raise ValueError("certification_gates must not be empty")
        if len(certification) != len(set(certification)):
            raise ValueError("certification_gates must be unique")
        if len(structural) != len(set(structural)):
            raise ValueError("structural_gates must be unique")
        missing = set(structural) - set(certification)
        if missing:
            raise ValueError(
                "structural_gates must be a subset of certification_gates: "
                + ", ".join(sorted(missing))
            )
        for gate_id in (self.behavior_gate, self.native_gate):
            if gate_id not in certification:
                raise ValueError(
                    f"policy gate {gate_id!r} must be in certification_gates"
                )

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "CertificationPolicy":
        policy = cls(
            certification_gates=tuple(payload["certification_gates"]),
            structural_gates=tuple(payload["structural_gates"]),
            behavior_gate=str(payload["behavior_gate"]),
            native_gate=str(payload["native_gate"]),
        )
        policy.validate()
        return policy


@dataclass
class CertificationReport:
    protocol_version: str
    run_id: str
    created_at: str
    input_artifact: str
    input_sha256: str | None
    reference_artifact: str | None
    reference_sha256: str | None
    policy: dict[str, Any]
    metadata: dict[str, Any]
    stages: list[StageResult] = field(default_factory=list)
    last_accepted_artifact: str | None = None
    last_accepted_sha256: str | None = None
    final_candidate: str | None = None
    final_candidate_sha256: str | None = None
    output_class: OutputClass = OutputClass.REJECTED
    evidence_directory: str | None = None
    published_artifact: str | None = None
    published_artifact_sha256: str | None = None
    published_binary: str | None = None
    published_binary_sha256: str | None = None

    def as_dict(self) -> dict[str, Any]:
        payload = asdict(self)
        payload["output_class"] = self.output_class.value
        for stage in payload["stages"]:
            stage["action"]["decision"] = stage["action"]["decision"].value
            for gate in stage["gates"]:
                gate["decision"] = gate["decision"].value
        return payload


Action = Callable[[Path, Path, Path], ActionResult]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path | str) -> str | None:
    candidate = Path(path)
    if not candidate.is_file():
        return None
    digest = hashlib.sha256()
    with candidate.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_write_json(path: Path | str, payload: Mapping[str, Any]) -> None:
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.", suffix=".tmp", dir=destination.parent
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, destination)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def atomic_copy(source: Path | str, destination: Path | str) -> Path:
    source_path = Path(source)
    destination_path = Path(destination)
    if not source_path.is_file():
        raise FileNotFoundError(source_path)
    destination_path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(
        prefix=f".{destination_path.name}.",
        suffix=".tmp",
        dir=destination_path.parent,
    )
    os.close(fd)
    try:
        shutil.copy2(source_path, temporary_name)
        os.replace(temporary_name, destination_path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise
    return destination_path


class TransactionalPipeline:
    """Execute candidate-producing stages without ever accepting bad output."""

    def __init__(
        self,
        *,
        input_artifact: Path | str,
        workdir: Path | str,
        report_path: Path | str,
        reference_artifact: Path | str | None = None,
        policy: CertificationPolicy | None = None,
        metadata: Mapping[str, Any] | None = None,
    ) -> None:
        input_path = Path(input_artifact).resolve()
        if not input_path.is_file():
            raise FileNotFoundError(input_path)
        workdir_root = Path(workdir).resolve()
        workdir_root.mkdir(parents=True, exist_ok=True)
        run_id = str(uuid.uuid4())
        self.workdir = workdir_root / "runs" / run_id
        self.workdir.mkdir(parents=True, exist_ok=False)
        self.report_path = Path(report_path).resolve()
        self.policy = policy or CertificationPolicy()
        self.policy.validate()
        reference_path = (
            Path(reference_artifact).resolve() if reference_artifact else None
        )
        self.report = CertificationReport(
            protocol_version=PROTOCOL_VERSION,
            run_id=run_id,
            created_at=utc_now(),
            input_artifact=str(input_path),
            input_sha256=sha256_file(input_path),
            reference_artifact=str(reference_path) if reference_path else None,
            reference_sha256=sha256_file(reference_path) if reference_path else None,
            policy=asdict(self.policy),
            metadata=dict(metadata or {}),
            last_accepted_artifact=str(input_path),
            last_accepted_sha256=sha256_file(input_path),
            evidence_directory=str(self.workdir),
        )
        self._persist()

    @property
    def last_accepted(self) -> Path:
        artifact = self.report.last_accepted_artifact
        if artifact is None:
            raise RuntimeError("pipeline has no accepted artifact")
        return Path(artifact)

    def _persist(self) -> None:
        atomic_write_json(self.report_path, self.report.as_dict())

    @staticmethod
    def _normalized_gate_result(spec: GateSpec, result: GateResult) -> GateResult:
        if result.gate_id != spec.gate_id:
            raise ValueError(
                f"gate returned id {result.gate_id!r}; expected {spec.gate_id!r}"
            )
        return GateResult(
            gate_id=result.gate_id,
            decision=result.decision,
            summary=result.summary,
            required=spec.required,
            blocking=spec.blocking,
            command=list(result.command),
            returncode=result.returncode,
            evidence_paths=list(result.evidence_paths),
            metrics=dict(result.metrics),
            duration_ms=result.duration_ms,
        )

    def run_stage(
        self,
        *,
        stage_id: str,
        candidate_artifact: Path | str,
        action: Action,
        gates: Sequence[GateSpec],
    ) -> StageResult:
        if not _STAGE_ID_RE.fullmatch(stage_id) or stage_id in {".", ".."}:
            raise ValueError(
                "stage_id must match [A-Za-z0-9][A-Za-z0-9._-]* and may not "
                "be '.' or '..'"
            )
        gate_ids = [spec.gate_id for spec in gates]
        if len(gate_ids) != len(set(gate_ids)):
            raise ValueError("gate ids must be unique within a stage")
        input_path = self.last_accepted.resolve()
        candidate_path = Path(candidate_artifact).resolve()
        if candidate_path == input_path:
            raise ValueError("candidate artifact must not overwrite the accepted input")
        try:
            candidate_path.relative_to(self.workdir)
        except ValueError as exc:
            raise ValueError(
                "candidate artifact must stay inside the pipeline workdir"
            ) from exc
        candidate_path.parent.mkdir(parents=True, exist_ok=True)
        stage_dir = self.workdir / "stages" / stage_id
        stage_dir.mkdir(parents=True, exist_ok=True)

        # A repeated run may leave a valid-looking candidate behind.  Remove it
        # before invoking the action so a failed action cannot reuse stale data.
        try:
            candidate_path.unlink()
        except FileNotFoundError:
            pass

        started_wall = utc_now()
        started = time.monotonic()
        try:
            action_result = action(input_path, candidate_path, stage_dir)
            if not isinstance(action_result, ActionResult):
                raise TypeError("stage action must return ActionResult")
            if not isinstance(action_result.decision, Decision):
                raise TypeError("stage action decision must be Decision")
        except Exception as exc:  # fail closed and preserve the exception in the report
            action_result = ActionResult(
                decision=Decision.ERROR,
                summary=f"stage action raised {type(exc).__name__}: {exc}",
            )

        candidate_exists = candidate_path.is_file() and candidate_path.stat().st_size > 0
        if action_result.decision == Decision.PASS and not candidate_exists:
            action_result = ActionResult(
                decision=Decision.ERROR,
                summary="stage reported success but produced no non-empty candidate",
                command=list(action_result.command),
                returncode=action_result.returncode,
                stdout_path=action_result.stdout_path,
                stderr_path=action_result.stderr_path,
                metrics=dict(action_result.metrics),
            )

        gate_results: list[GateResult] = []
        blocked = action_result.decision != Decision.PASS or not candidate_exists
        for spec in gates:
            if blocked:
                gate_results.append(
                    GateResult(
                        gate_id=spec.gate_id,
                        decision=Decision.SKIPPED,
                        summary="not executed because an earlier required step failed",
                        required=spec.required,
                        blocking=spec.blocking,
                    )
                )
                continue
            gate_started = time.monotonic()
            candidate_hash_before_gate = sha256_file(candidate_path)
            try:
                evaluated = spec.evaluate(candidate_path, stage_dir)
                result = self._normalized_gate_result(spec, evaluated)
            except Exception as exc:
                result = GateResult(
                    gate_id=spec.gate_id,
                    decision=Decision.ERROR,
                    summary=f"gate raised {type(exc).__name__}: {exc}",
                    required=spec.required,
                    blocking=spec.blocking,
                )
            candidate_hash_after_gate = sha256_file(candidate_path)
            if candidate_hash_after_gate != candidate_hash_before_gate:
                result = GateResult(
                    gate_id=spec.gate_id,
                    decision=Decision.ERROR,
                    summary="gate mutated the candidate artifact; evidence gates must be read-only",
                    required=spec.required,
                    blocking=spec.blocking,
                    command=list(result.command),
                    returncode=result.returncode,
                    evidence_paths=list(result.evidence_paths),
                    metrics={
                        **dict(result.metrics),
                        "candidate_sha256_before": candidate_hash_before_gate,
                        "candidate_sha256_after": candidate_hash_after_gate,
                    },
                )
            elapsed_ms = int((time.monotonic() - gate_started) * 1000)
            if result.duration_ms == 0:
                result = GateResult(
                    gate_id=result.gate_id,
                    decision=result.decision,
                    summary=result.summary,
                    required=result.required,
                    blocking=result.blocking,
                    command=list(result.command),
                    returncode=result.returncode,
                    evidence_paths=list(result.evidence_paths),
                    metrics=dict(result.metrics),
                    duration_ms=elapsed_ms,
                )
            gate_results.append(result)
            if spec.blocking and spec.required and result.decision != Decision.PASS:
                blocked = True

        accepted = (
            action_result.decision == Decision.PASS
            and candidate_exists
            and all(
                result.decision == Decision.PASS
                for result in gate_results
                if result.required
            )
        )
        candidate_hash = sha256_file(candidate_path) if candidate_exists else None
        finished = utc_now()
        result = StageResult(
            stage_id=stage_id,
            input_artifact=str(input_path),
            candidate_artifact=str(candidate_path),
            input_sha256=sha256_file(input_path),
            candidate_sha256=candidate_hash,
            action=action_result,
            gates=gate_results,
            accepted=accepted,
            started_at=started_wall,
            finished_at=finished,
            duration_ms=int((time.monotonic() - started) * 1000),
        )
        self.report.stages.append(result)
        self.report.final_candidate=str(candidate_path) if candidate_exists else None
        self.report.final_candidate_sha256=candidate_hash
        if accepted:
            self.report.last_accepted_artifact = str(candidate_path)
            self.report.last_accepted_sha256 = candidate_hash
        self.report.output_class = self.classify(result)
        self._persist()
        return result

    def classify(self, stage: StageResult | None = None) -> OutputClass:
        if stage is None:
            if not self.report.stages:
                return OutputClass.REJECTED
            stage = self.report.stages[-1]
        if not Path(stage.candidate_artifact).is_file():
            return OutputClass.REJECTED
        gates = {gate.gate_id: gate for gate in stage.gates}

        def required_pass(gate_id: str) -> bool:
            gate = gates.get(gate_id)
            return bool(
                gate is not None
                and gate.required
                and gate.decision == Decision.PASS
            )

        if stage.accepted and all(
            required_pass(gate_id)
            for gate_id in self.policy.certification_gates
        ):
            return OutputClass.CERTIFIED
        structural_ok = all(
            required_pass(gate_id)
            for gate_id in self.policy.structural_gates
        )
        behavior_ok = required_pass(self.policy.behavior_gate)
        if stage.action.decision == Decision.PASS and structural_ok and behavior_ok:
            return OutputClass.VALIDATED_COMPAT
        if stage.action.decision == Decision.PASS and required_pass("llvm_verify"):
            return OutputClass.EVIDENCE_ONLY
        return OutputClass.REJECTED

    def publish(
        self,
        *,
        artifact_destination: Path | str,
        binary_source: Path | str | None = None,
        binary_destination: Path | str | None = None,
        expected_binary_sha256: str | None = None,
        allowed_classes: Iterable[OutputClass] = (OutputClass.CERTIFIED,),
    ) -> tuple[Path, Path | None]:
        allowed = set(allowed_classes)
        output_class = self.report.output_class
        if output_class not in allowed:
            raise PermissionError(
                f"refusing to publish {output_class.value}; allowed: "
                + ", ".join(sorted(item.value for item in allowed))
            )
        candidate = self.report.final_candidate
        if candidate is None:
            raise FileNotFoundError("no final candidate available")
        candidate_hash = sha256_file(candidate)
        if candidate_hash is None or candidate_hash != self.report.final_candidate_sha256:
            raise PermissionError("final candidate changed after certification gates")

        published_binary: Path | None = None
        if binary_source is not None or binary_destination is not None:
            if binary_source is None or binary_destination is None:
                raise ValueError("binary_source and binary_destination must be paired")
            binary_hash = sha256_file(binary_source)
            if binary_hash is None:
                raise FileNotFoundError(binary_source)
            if expected_binary_sha256 is not None and binary_hash != expected_binary_sha256:
                raise PermissionError("binary changed after the bundle-link gate")
            # Publish the executable before the IR authority marker.  A failed
            # binary copy therefore cannot leave a newly certified IR behind.
            published_binary = atomic_copy(binary_source, binary_destination)

        published_artifact = atomic_copy(candidate, artifact_destination)
        self.report.published_artifact = str(published_artifact)
        self.report.published_artifact_sha256 = sha256_file(published_artifact)
        self.report.published_binary = (
            str(published_binary) if published_binary is not None else None
        )
        self.report.published_binary_sha256 = (
            sha256_file(published_binary) if published_binary is not None else None
        )
        self._persist()
        return published_artifact, published_binary
