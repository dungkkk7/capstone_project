"""Canonical schema and flow definitions for evaluation framework v2.

The schema is intentionally represented as plain dictionaries at the storage
boundary.  Dataclasses below cover the two places where exact typing matters:
flow contracts and observable process behavior.  Historical campaigns are
migrated without rewriting their original artifacts.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional


SCHEMA_VERSION = "2.0"
FLOW_LAYOUT_VERSION = "five-flow-b1-b2-f1-f2-f3-v3"
LEGACY_FLOW_LAYOUT_VERSION = "legacy-full-at-f2-v1"
FLOW_ORDER = ("B1", "B2", "F1", "F2", "F3")
ARTIFACT_FLOW_ORDER = FLOW_ORDER
FINAL_STATUSES = (
    "PASS",
    "FAIL_PREPROCESSING",
    "FAIL_GENERATION",
    "FAIL_COMPILE",
    "FAIL_BEHAVIORAL",
    "INCONCLUSIVE",
    "CANCELLED",
)


@dataclass(frozen=True)
class FlowSpec:
    flow_id: str
    name: str
    requires_raw_ir: bool
    requires_clean_ir: bool
    requires_pseudocode: bool
    iterative: bool
    requires_assembly: bool = False
    optimization_level: Optional[str] = None
    llm_enabled: bool = True


FLOW_SPECS = {
    "B1": FlowSpec(
        "B1",
        "GHIDRA_PSEUDOCODE_ONESHOT",
        False,
        False,
        True,
        False,
    ),
    "B2": FlowSpec(
        "B2",
        "OBJDUMP_ASSEMBLY_ONESHOT",
        False,
        False,
        False,
        False,
        requires_assembly=True,
    ),
    "F1": FlowSpec(
        "F1",
        "CLEAN_IR_ITERATIVE",
        False,
        True,
        False,
        True,
    ),
    "F2": FlowSpec(
        "F2",
        "RAW_IR_ITERATIVE",
        True,
        False,
        False,
        True,
    ),
    "F3": FlowSpec(
        "F3",
        "CLEAN_IR_ONESHOT",
        False,
        True,
        False,
        False,
    ),
}

# Campaigns created before ``FLOW_LAYOUT_VERSION`` used the same IDs for a
# different ordering. Offline report regeneration must never reinterpret those
# immutable artifacts under the new names.
LEGACY_FLOW_SPECS = {
    "F1": FlowSpec(
        "F1", "CLEAN_PSEUDOCODE_ITERATIVE", False, False, True, True
    ),
    "F2": FlowSpec(
        "F2", "CLEAN_IR_AND_PSEUDOCODE_ITERATIVE", False, True, True, True
    ),
    "F3": FlowSpec("F3", "RAW_IR_ITERATIVE", True, False, False, True),
    "F4": FlowSpec("F4", "CLEAN_IR_ITERATIVE", False, True, False, True),
    "F5": FlowSpec(
        "F5",
        "CLEAN_IR_AND_PSEUDOCODE_ONESHOT",
        False,
        True,
        True,
        False,
    ),
}

# Exact configuration-preserving permutation used when regenerating reports
# from campaigns created before flow contracts were persisted.
LEGACY_TO_CURRENT_FLOW_ID = {
    "F2": "F1",  # full
    "F5": "F2",  # no error context / one-shot
    "F4": "F3",  # no pseudocode
    "F1": "F4",  # no direct Clean IR
    "F3": "F5",  # Raw IR baseline
}


def flow_contract(spec: FlowSpec) -> dict[str, Any]:
    return {
        "flow_layout_version": FLOW_LAYOUT_VERSION,
        "flow_id": spec.flow_id,
        "flow_name": spec.name,
        "requires_raw_ir": spec.requires_raw_ir,
        "requires_clean_ir": spec.requires_clean_ir,
        "requires_pseudocode": spec.requires_pseudocode,
        "requires_assembly": spec.requires_assembly,
        "optimization_level": spec.optimization_level,
        "llm_enabled": spec.llm_enabled,
        "error_context_enabled": spec.iterative,
        "iterative": spec.iterative,
    }


@dataclass(frozen=True)
class BehaviorObservation:
    stdout_bytes: bytes
    stderr_bytes: bytes
    exit_code: Optional[int]
    terminating_signal: Optional[int]
    timeout_status: bool

    def as_json(self) -> dict[str, Any]:
        import base64

        return {
            "stdout_base64": base64.b64encode(self.stdout_bytes).decode("ascii"),
            "stderr_base64": base64.b64encode(self.stderr_bytes).decode("ascii"),
            "exit_code": self.exit_code,
            "terminating_signal": self.terminating_signal,
            "timeout_status": self.timeout_status,
        }


def paired_key(record: dict[str, Any]) -> tuple[str, str, str, int]:
    """Return the canonical paired-evaluation key."""

    return (
        str(record["experiment_id"]),
        str(record["sample_id"]),
        str(record["flow_id"]),
        int(record["repeat_id"]),
    )
