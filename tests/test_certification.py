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
    TransactionalPipeline,
)


def _pipeline(tmp_path: Path) -> TransactionalPipeline:
    source = tmp_path / "input.ll"
    source.write_text("input", encoding="utf-8")
    return TransactionalPipeline(
        input_artifact=source,
        workdir=tmp_path / "work",
        report_path=tmp_path / "report.json",
    )


def _write_action(payload: bytes = b"candidate"):
    def action(_input: Path, output: Path, _stage_dir: Path) -> ActionResult:
        output.write_bytes(payload)
        return ActionResult(Decision.PASS, "candidate produced")

    return action


def _gate(gate_id: str, decision: Decision = Decision.PASS, *, mutate: bool = False) -> GateSpec:
    def evaluate(candidate: Path, _stage_dir: Path) -> GateResult:
        if mutate:
            candidate.write_bytes(b"mutated by gate")
        return GateResult(gate_id, decision, f"{gate_id}: {decision.value}")

    return GateSpec(gate_id, evaluate, required=True, blocking=True)


def test_failed_action_cannot_reuse_stale_candidate(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    candidate = pipeline.workdir / "candidate.ll"
    candidate.write_bytes(b"stale")

    def fail(_input: Path, _output: Path, _stage_dir: Path) -> ActionResult:
        return ActionResult(Decision.FAIL, "transform failed")

    result = pipeline.run_stage(
        stage_id="fail",
        candidate_artifact=candidate,
        action=fail,
        gates=[_gate("llvm_verify")],
    )

    assert not result.accepted
    assert not candidate.exists()
    assert Path(pipeline.report.last_accepted_artifact or "") == Path(
        pipeline.report.input_artifact
    )


def test_required_inconclusive_gate_blocks_acceptance(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    result = pipeline.run_stage(
        stage_id="unknown",
        candidate_artifact=pipeline.workdir / "candidate.ll",
        action=_write_action(),
        gates=[_gate("llvm_verify", Decision.INCONCLUSIVE)],
    )
    assert not result.accepted
    assert pipeline.report.output_class == OutputClass.REJECTED


def test_evidence_gate_is_read_only(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    result = pipeline.run_stage(
        stage_id="mutating-gate",
        candidate_artifact=pipeline.workdir / "candidate.ll",
        action=_write_action(),
        gates=[_gate("llvm_verify", mutate=True)],
    )
    assert not result.accepted
    assert result.gates[0].decision == Decision.ERROR
    assert "read-only" in result.gates[0].summary


def test_candidate_must_stay_inside_unique_run_directory(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    with pytest.raises(ValueError, match="inside the pipeline workdir"):
        pipeline.run_stage(
            stage_id="escape",
            candidate_artifact=tmp_path / "outside.ll",
            action=_write_action(),
            gates=[],
        )


def test_all_frozen_required_gates_create_certified_authority(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    result = pipeline.run_stage(
        stage_id="certified",
        candidate_artifact=pipeline.workdir / "candidate.ll",
        action=_write_action(),
        gates=[_gate(gate_id) for gate_id in CertificationPolicy().certification_gates],
    )
    assert result.accepted
    assert pipeline.report.output_class == OutputClass.CERTIFIED


def test_changed_candidate_cannot_be_published(tmp_path: Path) -> None:
    pipeline = _pipeline(tmp_path)
    candidate = pipeline.workdir / "candidate.ll"
    pipeline.run_stage(
        stage_id="certified",
        candidate_artifact=candidate,
        action=_write_action(),
        gates=[_gate(gate_id) for gate_id in CertificationPolicy().certification_gates],
    )
    candidate.write_bytes(b"changed after gates")
    with pytest.raises(PermissionError, match="changed after certification"):
        pipeline.publish(artifact_destination=tmp_path / "published.ll")
