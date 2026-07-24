from __future__ import annotations

import datetime as dt
import fcntl
import json
import os
from pathlib import Path
from typing import Any, Dict

from .storage import (
    atomic_write_json,
    load_json,
    sha256_file,
    stable_json_sha256,
)


AUDIT_SCHEMA_VERSION = "1.0"
ARTIFACT_MANIFEST_SCHEMA_VERSION = "1.0"
GENESIS_HASH = "0" * 64
ARTIFACT_MANIFEST_PATH = "audit/artifact_manifest.json"

# These files are verification outputs or the ledger itself. Re-running an
# integrity check must not invalidate an otherwise sealed experiment.
LEDGER_EXCLUDED_PATHS = {
    ARTIFACT_MANIFEST_PATH,
    "integrity_report.json",
    "audit/verification_report.json",
}


class AuditError(RuntimeError):
    pass


def _utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def _canonical_event_hash(event: Dict[str, Any]) -> str:
    payload = dict(event)
    payload.pop("event_sha256", None)
    return stable_json_sha256(payload)


def _load_and_verify_events(path: Path) -> tuple[list[Dict[str, Any]], list[str]]:
    if not path.is_file():
        return [], [f"missing audit event log: {path}"]
    events: list[Dict[str, Any]] = []
    errors: list[str] = []
    expected_previous = GENESIS_HASH
    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not raw_line.strip():
            errors.append(f"blank audit line: {line_number}")
            continue
        try:
            event = json.loads(raw_line)
        except json.JSONDecodeError as exc:
            errors.append(f"invalid audit JSON line {line_number}: {exc}")
            continue
        expected_sequence = len(events) + 1
        if event.get("sequence") != expected_sequence:
            errors.append(
                f"audit sequence mismatch at line {line_number}: "
                f"expected {expected_sequence}, got {event.get('sequence')}"
            )
        if event.get("previous_event_sha256") != expected_previous:
            errors.append(f"audit chain mismatch at line {line_number}")
        expected_hash = _canonical_event_hash(event)
        if event.get("event_sha256") != expected_hash:
            errors.append(f"audit event hash mismatch at line {line_number}")
        expected_previous = event.get("event_sha256") or expected_previous
        events.append(event)
    return events, errors


class AuditLogger:
    """Append-only, hash-chained JSONL log for experiment lifecycle events."""

    def __init__(self, run_root: str | Path, run_id: str):
        self.run_root = Path(run_root)
        self.run_id = run_id
        self.path = self.run_root / "audit" / "events.jsonl"

    def log(
        self,
        event_type: str,
        *,
        sample_id: str | None = None,
        method: str | None = None,
        stage: str | None = None,
        status: str | None = None,
        payload: Dict[str, Any] | None = None,
    ) -> Dict[str, Any]:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        # Lock the log file itself so staged commands cannot interleave events.
        with self.path.open("a+", encoding="utf-8") as handle:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
            handle.seek(0)
            content = handle.read()
            if content:
                events, errors = _load_and_verify_events(self.path)
                if errors:
                    raise AuditError(
                        "Refusing to append to corrupt audit log: "
                        + "; ".join(errors)
                    )
            else:
                events = []
            previous_hash = (
                events[-1]["event_sha256"] if events else GENESIS_HASH
            )
            event: Dict[str, Any] = {
                "schema_version": AUDIT_SCHEMA_VERSION,
                "sequence": len(events) + 1,
                "timestamp_utc": _utc_now(),
                "run_id": self.run_id,
                "event_type": event_type,
                "sample_id": sample_id,
                "method": method,
                "stage": stage,
                "status": status,
                "payload": payload or {},
                "previous_event_sha256": previous_hash,
            }
            event["event_sha256"] = _canonical_event_hash(event)
            handle.seek(0, os.SEEK_END)
            handle.write(
                json.dumps(
                    event,
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                    default=str,
                )
                + "\n"
            )
            handle.flush()
            os.fsync(handle.fileno())
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        return event


def verify_event_log(path: str | Path) -> Dict[str, Any]:
    event_path = Path(path)
    events, errors = _load_and_verify_events(event_path)
    report = {
        "passed": not errors,
        "schema_version": AUDIT_SCHEMA_VERSION,
        "event_count": len(events),
        "first_event_sha256": (
            events[0].get("event_sha256") if events else None
        ),
        "last_event_sha256": (
            events[-1].get("event_sha256") if events else None
        ),
        "event_log_sha256": (
            sha256_file(event_path) if event_path.is_file() else None
        ),
        "errors": errors,
    }
    if errors:
        raise AuditError("; ".join(errors))
    return report


def _ledger_files(run_root: Path) -> list[Path]:
    paths = []
    for path in sorted(run_root.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(run_root).as_posix()
        if relative in LEDGER_EXCLUDED_PATHS or relative.endswith(".tmp"):
            continue
        paths.append(path)
    return paths


def create_artifact_manifest(
    run_root: str | Path, *, run_id: str
) -> Dict[str, Any]:
    root = Path(run_root)
    artifacts = []
    for path in _ledger_files(root):
        artifacts.append(
            {
                "path": path.relative_to(root).as_posix(),
                "size_bytes": path.stat().st_size,
                "sha256": sha256_file(path),
            }
        )
    event_report = verify_event_log(root / "audit" / "events.jsonl")
    manifest = {
        "schema_version": ARTIFACT_MANIFEST_SCHEMA_VERSION,
        "created_at_utc": _utc_now(),
        "run_id": run_id,
        "hash_algorithm": "SHA-256",
        "excluded_paths": sorted(LEDGER_EXCLUDED_PATHS),
        "event_chain": event_report,
        "artifact_count": len(artifacts),
        "artifacts": artifacts,
    }
    atomic_write_json(root / ARTIFACT_MANIFEST_PATH, manifest)
    return manifest


def verify_artifact_manifest(run_root: str | Path) -> Dict[str, Any]:
    root = Path(run_root)
    manifest_path = root / ARTIFACT_MANIFEST_PATH
    errors: list[str] = []
    if not manifest_path.is_file():
        raise AuditError(f"missing artifact manifest: {manifest_path}")
    manifest = load_json(manifest_path)
    expected = {
        item["path"]: item for item in manifest.get("artifacts", [])
    }
    current_paths = {
        path.relative_to(root).as_posix(): path for path in _ledger_files(root)
    }
    for relative, item in expected.items():
        path = current_paths.get(relative)
        if path is None:
            errors.append(f"missing sealed artifact: {relative}")
            continue
        if path.stat().st_size != item.get("size_bytes"):
            errors.append(f"artifact size mismatch: {relative}")
        if sha256_file(path) != item.get("sha256"):
            errors.append(f"artifact hash mismatch: {relative}")
    for relative in sorted(set(current_paths) - set(expected)):
        errors.append(f"unsealed artifact present: {relative}")
    if manifest.get("artifact_count") != len(expected):
        errors.append("artifact_count does not match manifest entries")
    event_report = verify_event_log(root / "audit" / "events.jsonl")
    sealed_event = manifest.get("event_chain") or {}
    if event_report.get("event_log_sha256") != sealed_event.get(
        "event_log_sha256"
    ):
        errors.append("sealed audit event log hash mismatch")
    report = {
        "passed": not errors,
        "artifact_count": len(expected),
        "manifest_sha256": sha256_file(manifest_path),
        "event_chain": event_report,
        "errors": errors,
    }
    if errors:
        raise AuditError("; ".join(errors))
    return report
