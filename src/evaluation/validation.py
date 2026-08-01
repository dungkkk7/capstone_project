"""Strict pre-aggregation validation.  Invalid data is reported, never edited."""

from __future__ import annotations

import json
from typing import Any

from evaluation.schema import FLOW_SPECS


def _error(
    run: dict[str, Any],
    rule: str,
    values: dict[str, Any],
    message: str,
    severity: str = "ERROR",
) -> dict[str, Any]:
    return {
        "experiment_id": run.get("experiment_id"),
        "sample_id": run.get("sample_id"),
        "flow_id": run.get("flow_id"),
        "repeat_id": run.get("repeat_id"),
        "violated_rule": rule,
        "field_values": json.dumps(values, sort_keys=True, default=str),
        "severity": severity,
        "message": message,
    }


def validate_run(run: dict[str, Any]) -> list[dict[str, Any]]:
    errors: list[dict[str, Any]] = []
    flow = run.get("flow_id")
    status = run.get("status")

    iterative = run.get("error_context_enabled", run.get("iterative"))
    if iterative is None and flow in FLOW_SPECS:
        iterative = FLOW_SPECS[flow].iterative
    if iterative is False:
        values = {
            "llm_calls": run.get("llm_calls"),
            "compile_repair_rounds": run.get("compile_repair_rounds"),
            "behavioral_repair_rounds": run.get("behavioral_repair_rounds"),
        }
        if values != {
            "llm_calls": 1,
            "compile_repair_rounds": 0,
            "behavioral_repair_rounds": 0,
        }:
            errors.append(
                _error(
                    run,
                    "RULE_1_ONESHOT_CONTRACT",
                    values,
                    f"{flow} disables error context and must have exactly one "
                    "LLM call with zero repair rounds.",
                )
            )

    if not run.get("any_compile_success_within_budget"):
        values = {
            "fuzz_valid": run.get("fuzz_valid"),
            "input_match_rate": run.get("input_match_rate"),
            "status": status,
        }
        if (run.get("fuzz_valid") not in (None, 0)) or run.get("input_match_rate") is not None or status == "PASS":
            errors.append(_error(run, "RULE_2_NO_EXECUTABLE", values, "A run without an executable cannot have behavioral evidence or PASS."))

    if status == "PASS":
        values = {
            "any_compile_success_within_budget": run.get("any_compile_success_within_budget"),
            "fuzzing_completed": run.get("fuzzing_completed"),
            "final_counterexample_found": run.get("final_counterexample_found"),
        }
        if values != {
            "any_compile_success_within_budget": True,
            "fuzzing_completed": True,
            "final_counterexample_found": False,
        }:
            errors.append(_error(run, "RULE_3_PASS_REQUIREMENTS", values, "PASS requires executable, completed fuzzing, and no final counterexample."))

    if status == "FAIL_BEHAVIORAL":
        values = {
            "any_compile_success_within_budget": run.get("any_compile_success_within_budget"),
            "reproducible_final_counterexample": run.get("reproducible_final_counterexample"),
        }
        if not all(values.values()):
            errors.append(_error(run, "RULE_4_FAIL_BEHAVIORAL", values, "FAIL_BEHAVIORAL requires an executable and reproducible final counterexample."))

    if run.get("compile_success_first") and run.get("compiler_attempts", 0) < 1:
        errors.append(_error(run, "RULE_5_FIRST_COMPILE", {"compile_success_first": True, "compiler_attempts": run.get("compiler_attempts")}, "First-pass success requires a compile attempt."))

    if run.get("final_counterexample_found") and status == "PASS":
        errors.append(_error(run, "RULE_6_COUNTEREXAMPLE_STATE", {"final_counterexample_found": True, "status": status}, "A final counterexample cannot coexist with PASS."))

    counts = {
        "fuzz_matches": run.get("fuzz_matches"),
        "fuzz_valid": run.get("fuzz_valid"),
        "fuzz_executed_on_both": run.get("fuzz_executed_on_both"),
        "fuzz_generated": run.get("fuzz_generated"),
    }
    if all(value is not None for value in counts.values()):
        if not (
            counts["fuzz_matches"]
            <= counts["fuzz_valid"]
            <= counts["fuzz_executed_on_both"]
            <= counts["fuzz_generated"]
        ):
            errors.append(_error(run, "RULE_7_FUZZ_COUNTS", counts, "Fuzz counts violate matches <= valid <= executed_on_both <= generated."))

    undefined_metrics = run.get("undefined_metric_violations") or []
    if undefined_metrics:
        errors.append(_error(run, "RULE_8_UNDEFINED_DENOMINATOR", {"fields": undefined_metrics}, "Metrics without a denominator must be null/N/A."))

    if run.get("repair_case_round_confusion"):
        errors.append(_error(run, "RULE_9_REPAIR_CASE_VS_ROUND", {"repair_case_round_confusion": True}, "Repair cases and repair rounds are distinct quantities."))

    for warning in run.get("provenance_warnings") or []:
        errors.append(_error(run, "RULE_10_SOURCE_DATA_GAP", {"warning": warning}, warning, severity="WARNING"))
    return errors


def validate_runs(runs: list[dict[str, Any]]) -> list[dict[str, Any]]:
    errors = [error for run in runs for error in validate_run(run)]
    seen: set[tuple[str, str, str, int]] = set()
    for run in runs:
        key = (
            str(run.get("experiment_id")),
            str(run.get("sample_id")),
            str(run.get("flow_id")),
            int(run.get("repeat_id", 0)),
        )
        if key in seen:
            errors.append(_error(run, "PAIRED_KEY_DUPLICATE", {"key": key}, "Paired evaluation key is duplicated."))
        seen.add(key)
    return errors
