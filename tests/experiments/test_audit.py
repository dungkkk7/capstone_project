import json
import sys
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from experiments.audit import (  # noqa: E402
    AuditError,
    AuditLogger,
    create_artifact_manifest,
    verify_artifact_manifest,
    verify_event_log,
)


def test_audit_event_log_is_hash_chained(tmp_path):
    logger = AuditLogger(tmp_path, "audit-test")
    first = logger.log("experiment_initialized", status="READY")
    second = logger.log(
        "variant_checkpoint",
        sample_id="p00001",
        method="B0",
        stage="build",
        status="RUNNING",
        payload={"candidate_sha256": "abc"},
    )

    assert first["sequence"] == 1
    assert second["sequence"] == 2
    assert second["previous_event_sha256"] == first["event_sha256"]
    report = verify_event_log(tmp_path / "audit" / "events.jsonl")
    assert report["passed"] is True
    assert report["event_count"] == 2

    lines = (tmp_path / "audit" / "events.jsonl").read_text().splitlines()
    tampered = json.loads(lines[0])
    tampered["status"] = "ALTERED"
    lines[0] = json.dumps(tampered, sort_keys=True)
    (tmp_path / "audit" / "events.jsonl").write_text(
        "\n".join(lines) + "\n"
    )
    with pytest.raises(AuditError, match="hash mismatch"):
        verify_event_log(tmp_path / "audit" / "events.jsonl")


def test_artifact_manifest_detects_post_seal_mutation(tmp_path):
    logger = AuditLogger(tmp_path, "artifact-test")
    logger.log("experiment_initialized", status="READY")
    artifact = tmp_path / "samples" / "p00001" / "B0" / "candidate.c"
    artifact.parent.mkdir(parents=True)
    artifact.write_text("int main(void) { return 0; }\n")
    logger.log("artifacts_sealed", status="SEALED")

    manifest = create_artifact_manifest(tmp_path, run_id="artifact-test")
    assert manifest["artifact_count"] >= 2
    assert verify_artifact_manifest(tmp_path)["passed"] is True

    artifact.write_text("int main(void) { return 1; }\n")
    with pytest.raises(AuditError, match="artifact hash mismatch"):
        verify_artifact_manifest(tmp_path)
