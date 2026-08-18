"""Fail-closed transaction engine used by the certifying brightening runner.

It snapshots caller-owned inputs, gives actions an isolated copy, treats gates
as read-only, restores an altered checkpoint, and publishes only bytes whose
hashes are identical to the hashes recorded by the authority gates.
"""

from __future__ import annotations

import re
import time
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

from llvm_pass.certification import (
    Action,
    ActionResult,
    CertificationPolicy,
    Decision,
    GateResult,
    GateSpec,
    OutputClass,
    StageResult,
    TransactionalPipeline as _ReportPipeline,
    atomic_copy,
    sha256_file,
    utc_now,
)

_TOKEN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def _remove(path: Path) -> None:
    try:
        path.unlink()
    except FileNotFoundError:
        pass


def _regular(path: Path) -> bool:
    try:
        return not path.is_symlink() and path.is_file() and path.stat().st_size > 0
    except OSError:
        return False


class TransactionalPipeline(_ReportPipeline):
    """Hardened authority boundary; the base class supplies report dataclasses."""

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
        selected = policy or CertificationPolicy()
        cert = tuple(selected.certification_gates)
        structural = tuple(selected.structural_gates)
        invalid = (
            not cert
            or any(not isinstance(x, str) or not _TOKEN.fullmatch(x) for x in cert)
            or any(not isinstance(x, str) or not _TOKEN.fullmatch(x) for x in structural)
            or len(cert) != len(set(cert))
            or len(structural) != len(set(structural))
            or not set(structural).issubset(cert)
            or selected.behavior_gate not in cert
            or selected.native_gate not in cert
        )
        if invalid:
            raise ValueError("invalid certification policy")
        super().__init__(
            input_artifact=input_artifact,
            workdir=workdir,
            report_path=report_path,
            reference_artifact=reference_artifact,
            policy=selected,
            metadata=metadata,
        )

        self._source_input = Path(self.report.input_artifact).resolve()
        self._input_hash = self.report.input_sha256
        if self._input_hash is None:
            raise FileNotFoundError(self._source_input)
        frozen = self.workdir / "frozen"
        frozen.mkdir(parents=True, exist_ok=False)
        self._input_snapshot = frozen / f"input{self._source_input.suffix or '.artifact'}"
        atomic_copy(self._source_input, self._input_snapshot)
        if {sha256_file(self._source_input), sha256_file(self._input_snapshot)} != {
            self._input_hash
        }:
            raise PermissionError("input changed while its snapshot was created")

        self._source_reference = (
            Path(self.report.reference_artifact).resolve()
            if self.report.reference_artifact
            else None
        )
        self._reference_hash = self.report.reference_sha256
        self._reference_backup: Path | None = None
        self._reference_snapshot: Path | None = None
        if self._source_reference is not None:
            if self._reference_hash is None:
                raise FileNotFoundError(self._source_reference)
            suffix = self._source_reference.suffix or ".artifact"
            self._reference_backup = frozen / f"reference-backup{suffix}"
            self._reference_snapshot = frozen / f"reference-runtime{suffix}"
            atomic_copy(self._source_reference, self._reference_backup)
            atomic_copy(self._reference_backup, self._reference_snapshot)
            observed = {
                sha256_file(self._source_reference),
                sha256_file(self._reference_backup),
                sha256_file(self._reference_snapshot),
            }
            if observed != {self._reference_hash}:
                raise PermissionError("reference changed while its snapshot was created")

        self.report.last_accepted_artifact = str(self._input_snapshot)
        self.report.last_accepted_sha256 = self._input_hash
        self.report.metadata["transaction_core"] = {
            "engine": "hardened-certifying-transaction-v1",
            "input_snapshot": str(self._input_snapshot),
            "input_snapshot_sha256": self._input_hash,
            "reference_snapshot": (
                str(self._reference_snapshot) if self._reference_snapshot else None
            ),
            "reference_snapshot_sha256": self._reference_hash,
        }
        self._persist()

    @property
    def reference_snapshot(self) -> Path | None:
        return self._reference_snapshot

    def _observed(self, accepted: Path) -> dict[str, str | None]:
        return {
            "source_input": sha256_file(self._source_input),
            "accepted": sha256_file(accepted),
            "source_reference": (
                sha256_file(self._source_reference) if self._source_reference else None
            ),
            "reference_backup": (
                sha256_file(self._reference_backup) if self._reference_backup else None
            ),
            "reference_snapshot": (
                sha256_file(self._reference_snapshot) if self._reference_snapshot else None
            ),
        }

    def _expected(self, accepted_hash: str) -> dict[str, str | None]:
        return {
            "source_input": self._input_hash,
            "accepted": accepted_hash,
            "source_reference": self._reference_hash,
            "reference_backup": self._reference_hash,
            "reference_snapshot": self._reference_hash,
        }

    @staticmethod
    def _changed(
        observed: Mapping[str, str | None], expected: Mapping[str, str | None]
    ) -> list[str]:
        return [name for name, value in expected.items() if observed.get(name) != value]

    def _restore(
        self,
        accepted: Path,
        backup: Path,
        observed: Mapping[str, str | None],
        expected: Mapping[str, str | None],
    ) -> None:
        if observed.get("accepted") != expected.get("accepted"):
            atomic_copy(backup, accepted)
        if (
            self._reference_snapshot
            and self._reference_backup
            and observed.get("reference_snapshot") != expected.get("reference_snapshot")
            and observed.get("reference_backup") == expected.get("reference_backup")
        ):
            atomic_copy(self._reference_backup, self._reference_snapshot)

    @staticmethod
    def _gate_result(spec: GateSpec, result: GateResult) -> GateResult:
        if not isinstance(result, GateResult):
            raise TypeError("gate must return GateResult")
        if not isinstance(result.decision, Decision):
            raise TypeError("gate decision must be Decision")
        if result.gate_id != spec.gate_id:
            raise ValueError(f"gate returned {result.gate_id!r}, expected {spec.gate_id!r}")
        return GateResult(
            result.gate_id,
            result.decision,
            result.summary,
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
        if not isinstance(stage_id, str) or not _TOKEN.fullmatch(stage_id):
            raise ValueError("stage_id must be a non-path token")
        gate_ids = [spec.gate_id for spec in gates]
        if any(not isinstance(x, str) or not _TOKEN.fullmatch(x) for x in gate_ids):
            raise ValueError("gate ids must be non-path tokens")
        if len(gate_ids) != len(set(gate_ids)):
            raise ValueError("gate ids must be unique")

        accepted = self.last_accepted.resolve()
        accepted_hash = self.report.last_accepted_sha256
        if accepted_hash is None:
            raise RuntimeError("accepted checkpoint has no hash")
        candidate = Path(candidate_artifact).resolve()
        if candidate == accepted:
            raise ValueError("candidate may not overwrite the checkpoint")
        try:
            candidate.relative_to(self.workdir)
        except ValueError as exc:
            raise ValueError("candidate must stay inside the run directory") from exc

        stage_dir = self.workdir / "authority-stages" / stage_id
        stage_dir.mkdir(parents=True, exist_ok=False)
        candidate.parent.mkdir(parents=True, exist_ok=True)
        _remove(candidate)
        suffix = accepted.suffix or ".artifact"
        action_input = stage_dir / f"action-input{suffix}"
        backup = stage_dir / f"accepted-backup{suffix}"
        atomic_copy(accepted, backup)
        atomic_copy(backup, action_input)
        if any(sha256_file(path) != accepted_hash for path in (accepted, backup, action_input)):
            raise PermissionError("could not create stable stage snapshots")

        started_at = utc_now()
        started = time.monotonic()
        expected = self._expected(accepted_hash)
        changed_before = self._changed(self._observed(accepted), expected)
        if changed_before:
            action_result = ActionResult(
                Decision.ERROR,
                "protected bytes changed before the stage",
                metrics={"changed_fields": changed_before},
            )
        else:
            try:
                action_result = action(action_input, candidate, stage_dir)
                if not isinstance(action_result, ActionResult):
                    raise TypeError("action must return ActionResult")
                if not isinstance(action_result.decision, Decision):
                    raise TypeError("action decision must be Decision")
            except Exception as exc:
                action_result = ActionResult(
                    Decision.ERROR, f"action raised {type(exc).__name__}: {exc}"
                )

        after_action = self._observed(accepted)
        changed_action = self._changed(after_action, expected)
        if sha256_file(action_input) != accepted_hash:
            changed_action.append("action_input")
        if changed_action:
            self._restore(accepted, backup, after_action, expected)
            action_result = ActionResult(
                Decision.ERROR,
                "action mutated protected input/reference bytes",
                command=list(action_result.command),
                returncode=action_result.returncode,
                stdout_path=action_result.stdout_path,
                stderr_path=action_result.stderr_path,
                metrics={
                    **dict(action_result.metrics),
                    "changed_fields": sorted(set(changed_action)),
                },
            )
            _remove(candidate)

        candidate_exists = _regular(candidate)
        if action_result.decision != Decision.PASS:
            _remove(candidate)
            candidate_exists = False
        elif not candidate_exists:
            action_result = ActionResult(
                Decision.ERROR,
                "action reported success but produced no regular non-empty candidate",
                command=list(action_result.command),
                returncode=action_result.returncode,
                stdout_path=action_result.stdout_path,
                stderr_path=action_result.stderr_path,
                metrics=dict(action_result.metrics),
            )

        results: list[GateResult] = []
        blocked = action_result.decision != Decision.PASS or not candidate_exists
        for spec in gates:
            if blocked:
                results.append(
                    GateResult(
                        spec.gate_id,
                        Decision.SKIPPED,
                        "skipped after an earlier required failure",
                        required=spec.required,
                        blocking=spec.blocking,
                    )
                )
                continue
            gate_started = time.monotonic()
            candidate_before = sha256_file(candidate)
            protected_before = self._observed(accepted)
            try:
                result = self._gate_result(spec, spec.evaluate(candidate, stage_dir))
            except Exception as exc:
                result = GateResult(
                    spec.gate_id,
                    Decision.ERROR,
                    f"gate raised {type(exc).__name__}: {exc}",
                    required=spec.required,
                    blocking=spec.blocking,
                )
            candidate_after = sha256_file(candidate)
            protected_after = self._observed(accepted)
            changed = sorted(
                set(self._changed(protected_before, expected))
                | set(self._changed(protected_after, expected))
            )
            if candidate_after != candidate_before or changed:
                self._restore(accepted, backup, protected_after, expected)
                result = GateResult(
                    spec.gate_id,
                    Decision.ERROR,
                    "gate mutated candidate/input/reference bytes",
                    required=spec.required,
                    blocking=spec.blocking,
                    command=list(result.command),
                    returncode=result.returncode,
                    evidence_paths=list(result.evidence_paths),
                    metrics={
                        **dict(result.metrics),
                        "candidate_before": candidate_before,
                        "candidate_after": candidate_after,
                        "changed_fields": changed,
                    },
                )
                _remove(candidate)
                blocked = True
            if result.duration_ms == 0:
                result = GateResult(
                    result.gate_id,
                    result.decision,
                    result.summary,
                    required=result.required,
                    blocking=result.blocking,
                    command=list(result.command),
                    returncode=result.returncode,
                    evidence_paths=list(result.evidence_paths),
                    metrics=dict(result.metrics),
                    duration_ms=int((time.monotonic() - gate_started) * 1000),
                )
            results.append(result)
            if spec.required and spec.blocking and result.decision != Decision.PASS:
                blocked = True

        final_observed = self._observed(accepted)
        final_changed = self._changed(final_observed, expected)
        if final_changed:
            self._restore(accepted, backup, final_observed, expected)
            _remove(candidate)
            results.append(
                GateResult(
                    "transaction_integrity",
                    Decision.ERROR,
                    "protected bytes changed after the final gate",
                    metrics={"changed_fields": final_changed},
                )
            )

        candidate_exists = _regular(candidate)
        accepted_stage = (
            action_result.decision == Decision.PASS
            and candidate_exists
            and all(r.decision == Decision.PASS for r in results if r.required)
        )
        candidate_hash = sha256_file(candidate) if candidate_exists else None
        stage = StageResult(
            stage_id,
            str(accepted),
            str(candidate),
            sha256_file(accepted),
            candidate_hash,
            action_result,
            results,
            accepted_stage,
            started_at,
            utc_now(),
            int((time.monotonic() - started) * 1000),
        )
        self.report.stages.append(stage)
        self.report.final_candidate = str(candidate) if candidate_exists else None
        self.report.final_candidate_sha256 = candidate_hash
        if accepted_stage:
            self.report.last_accepted_artifact = str(candidate)
            self.report.last_accepted_sha256 = candidate_hash
        self.report.output_class = self.classify(stage)
        self._persist()
        return stage

    def classify(self, stage: StageResult | None = None) -> OutputClass:
        stage = stage or (self.report.stages[-1] if self.report.stages else None)
        if stage is None or not _regular(Path(stage.candidate_artifact)):
            return OutputClass.REJECTED
        gates = {gate.gate_id: gate for gate in stage.gates}

        def passed(gate_id: str) -> bool:
            gate = gates.get(gate_id)
            return bool(gate and gate.required and gate.decision == Decision.PASS)

        if stage.accepted and all(passed(x) for x in self.policy.certification_gates):
            return OutputClass.CERTIFIED
        if (
            stage.action.decision == Decision.PASS
            and all(passed(x) for x in self.policy.structural_gates)
            and passed(self.policy.behavior_gate)
        ):
            return OutputClass.VALIDATED_COMPAT
        if stage.action.decision == Decision.PASS and passed("llvm_verify"):
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
        if self.report.output_class not in set(allowed_classes):
            raise PermissionError(f"refusing to publish {self.report.output_class.value}")
        if self.report.final_candidate is None:
            raise FileNotFoundError("no final candidate")
        candidate = Path(self.report.final_candidate)
        candidate_hash = sha256_file(candidate)
        if (
            not _regular(candidate)
            or candidate_hash != self.report.final_candidate_sha256
        ):
            raise PermissionError("final candidate changed after its gates")

        published_binary: Path | None = None
        published_artifact: Path | None = None
        binary_hash: str | None = None
        try:
            if binary_source is not None or binary_destination is not None:
                if binary_source is None or binary_destination is None:
                    raise ValueError("binary source/destination must be paired")
                binary = Path(binary_source)
                if binary.is_symlink():
                    raise PermissionError("binary source must be regular")
                binary_hash = sha256_file(binary)
                if binary_hash is None:
                    raise FileNotFoundError(binary)
                if expected_binary_sha256 and binary_hash != expected_binary_sha256:
                    raise PermissionError("binary changed after bundle-link gate")
                published_binary = atomic_copy(binary, binary_destination)
                if sha256_file(binary) != binary_hash or sha256_file(published_binary) != binary_hash:
                    raise PermissionError("binary changed during publication")

            published_artifact = atomic_copy(candidate, artifact_destination)
            if (
                sha256_file(candidate) != candidate_hash
                or sha256_file(published_artifact) != candidate_hash
            ):
                raise PermissionError("candidate changed during publication")
            self.report.published_artifact = str(published_artifact)
            self.report.published_artifact_sha256 = candidate_hash
            self.report.published_binary = (
                str(published_binary) if published_binary else None
            )
            self.report.published_binary_sha256 = binary_hash
            self._persist()
        except Exception:
            for path in (published_artifact, published_binary):
                if path:
                    _remove(path)
            raise
        assert published_artifact is not None
        return published_artifact, published_binary
