from __future__ import annotations

import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = PROJECT_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from llvm_pass.certification import (  # noqa: E402
    ActionResult,
    CertificationPolicy,
    Decision,
    GateResult,
    GateSpec,
    OutputClass,
)
from llvm_pass.certifying_transaction import TransactionalPipeline  # noqa: E402


def _pipeline(tmp_path: Path, *, reference: bool = False) -> TransactionalPipeline:
    source = tmp_path / "input.ll"
    source.write_text("input", encoding="utf-8")
    reference_path = None
    if reference:
        reference_path = tmp_path / "reference.bin"
        reference_path.write_bytes(b"reference")
    return TransactionalPipeline(
        input_artifact=source,
        reference_artifact=reference_path,
        workdir=tmp_path / "work",
        report_path=tmp_path / "report.json",
    )


def _pass_gate(gate_id: str) -> GateSpec:
    return GateSpec(
        gate_id,
        lambda _candidate, _stage: GateResult(
            gate_id, Decision.PASS, "pass"
        ),
    )


def _write_action(payload: bytes = b"candidate"):
    def action(_input: Path, output: Path, _stage: Path) -> ActionResult:
        output.write_bytes(payload)
        return ActionResult(Decision.PASS, "produced")

    return action


def test_input_and_reference_are_frozen_inside_run(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path, reference=True)
    assert pipeline.last_accepted != Path(pipeline.report.input_artifact)
    assert pipeline.last_accepted.read_text(encoding="utf-8") == "input"
    assert pipeline.reference_snapshot is not None
    assert pipeline.reference_snapshot.read_bytes() == b"reference"


def test_action_mutating_its_input_is_rejected_and_candidate_deleted(
    tmp_path: Path,
) -> None:
    pipeline = _pipeline(tmp_path)
    checkpoint = pipeline.last_accepted

    def action(action_input: Path, output: Path, _stage: Path) -> ActionResult:
        action_input.write_text("mutated", encoding="utf-8")
        output.write_bytes(b"candidate")
        return ActionResult(Decision.PASS, "claimed pass")

    result = pipeline.run_stage(
        stage_id="mutating-action",
        candidate_artifact=pipeline.workdir / "candidate.ll",
        action=action,
        gates=[_pass_gate("llvm_verify")],
    )
    assert not result.accepted
    assert result.action.decision == Decision.ERROR
    assert pipeline.report.output_class == OutputClass.REJECTED
    assert checkpoint.read_text(encoding="utf-8") == "input"
    assert not Path(result.candidate_artifact).exists()


def test_action_mutating_checkpoint_is_detected_and_restored(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    checkpoint = pipeline.last_accepted

    def action(_input: Path, output: Path, _stage: Path) -> ActionResult:
        checkpoint.write_text("corrupt", encoding="utf-8")
        output.write_bytes(b"candidate")
        return ActionResult(Decision.PASS, "claimed pass")

    result = pipeline.run_stage(
        stage_id="checkpoint-attack",
        candidate_artifact=pipeline.workdir / "candidate.ll",
        action=action,
        gates=[_pass_gate("llvm_verify")],
    )
    assert result.action.decision == Decision.ERROR
    assert checkpoint.read_text(encoding="utf-8") == "input"
    assert not Path(result.candidate_artifact).exists()


def test_nonblocking_gate_mutation_cannot_downgrade_to_publishable_evidence(
    tmp_path: Path,
) -> None:
    pipeline = _pipeline(tmp_path)

    def mutate(candidate: Path, _stage: Path) -> GateResult:
        candidate.write_bytes(b"tainted")
        return GateResult("behavior", Decision.PASS, "claimed pass")

    result = pipeline.run_stage(
        stage_id="gate-attack",
        candidate_artifact=pipeline.workdir / "candidate.ll",
        action=_write_action(),
        gates=[
            _pass_gate("llvm_verify"),
            GateSpec("behavior", mutate, required=True, blocking=False),
        ],
    )
    assert not result.accepted
    assert result.gates[-1].decision == Decision.ERROR
    assert pipeline.report.output_class == OutputClass.REJECTED
    assert not Path(result.candidate_artifact).exists()


def test_stage_evidence_directory_cannot_be_reused(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    pipeline.run_stage(
        stage_id="once",
        candidate_artifact=pipeline.workdir / "first.ll",
        action=_write_action(),
        gates=[_pass_gate("llvm_verify")],
    )
    with pytest.raises(FileExistsError):
        pipeline.run_stage(
            stage_id="once",
            candidate_artifact=pipeline.workdir / "second.ll",
            action=_write_action(),
            gates=[_pass_gate("llvm_verify")],
        )


def test_certified_candidate_is_hash_bound_at_publication(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    candidate = pipeline.workdir / "candidate.ll"
    pipeline.run_stage(
        stage_id="certified",
        candidate_artifact=candidate,
        action=_write_action(),
        gates=[_pass_gate(g) for g in CertificationPolicy().certification_gates],
    )
    assert pipeline.report.output_class == OutputClass.CERTIFIED
    candidate.write_bytes(b"changed")
    with pytest.raises(PermissionError, match="changed after"):
        pipeline.publish(artifact_destination=tmp_path / "published.ll")
