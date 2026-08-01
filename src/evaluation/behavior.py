"""Exact behavioral-oracle tuple comparison and divergence classification."""

from __future__ import annotations

import base64
from typing import Any

from evaluation.schema import BehaviorObservation


def observation_from_record(side: dict[str, Any]) -> BehaviorObservation:
    """Convert a historical fuzzer side record to the canonical observation."""

    stdout = side.get("stdout_base64")
    stderr = side.get("stderr_base64")
    stdout_bytes = (
        base64.b64decode(stdout)
        if isinstance(stdout, str)
        else str(side.get("stdout", "")).encode("utf-8", errors="replace")
    )
    stderr_bytes = (
        base64.b64decode(stderr)
        if isinstance(stderr, str)
        else str(side.get("stderr", "")).encode("utf-8", errors="replace")
    )
    status = str(side.get("status", ""))
    signal = side.get("signal")
    return BehaviorObservation(
        stdout_bytes=stdout_bytes,
        stderr_bytes=stderr_bytes,
        exit_code=side.get("returncode"),
        terminating_signal=int(signal) if signal is not None else None,
        timeout_status=status == "timeout",
    )


def behavior_matches(
    reference: BehaviorObservation, candidate: BehaviorObservation
) -> bool:
    """Match only when every component of the observable tuple is identical."""

    return reference == candidate


def classify_divergence(
    reference: BehaviorObservation, candidate: BehaviorObservation
) -> str | None:
    """Return the canonical divergence type, or ``None`` for an exact match."""

    stream_differences: list[str] = []
    if reference.stdout_bytes != candidate.stdout_bytes:
        stream_differences.append("OUTPUT_MISMATCH")
    if reference.stderr_bytes != candidate.stderr_bytes:
        stream_differences.append("STDERR_MISMATCH")
    ref_crash = reference.terminating_signal is not None
    cand_crash = candidate.terminating_signal is not None
    structural: str | None = None
    if reference.timeout_status != candidate.timeout_status:
        structural = "TIMEOUT_MISMATCH"
    elif ref_crash != cand_crash:
        # The associated negative return code is a consequence of the crash,
        # not an independent exit-status divergence.
        structural = "CRASH_MISMATCH"
    elif ref_crash and (
        reference.terminating_signal != candidate.terminating_signal
    ):
        structural = "SIGNAL_MISMATCH"
    elif reference.exit_code != candidate.exit_code:
        structural = "EXIT_STATUS_MISMATCH"

    differences = stream_differences + ([structural] if structural else [])
    if not differences:
        return None
    if len(differences) == 1:
        return differences[0]
    return "MIXED_DIVERGENCE"
