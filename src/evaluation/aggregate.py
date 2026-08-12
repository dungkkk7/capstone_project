"""Flow-level, stage-level, failure, repair, reliability, and cost aggregates."""

from __future__ import annotations

import collections
import math
from typing import Any

from evaluation.metrics import (
    bootstrap_ci,
    canonical_e2e_rate,
    compilation_repair_success_rate,
    counterexample_detection_rate,
    descriptive,
    executable_pair_execution_rate,
    final_rsr,
    first_pass_rsr,
    flow_specific_recovery_rate,
    gain,
    inconclusive_rate,
    input_match_rate,
    program_behavioral_pass_rate,
    rate,
    re_executability_rate,
    reproducibility_rate,
    semantic_repair_success_rate,
    valid_input_rate,
)
from evaluation.schema import FLOW_ORDER, FLOW_SPECS


def _is_error(error: dict[str, Any]) -> bool:
    return error.get("severity") == "ERROR"


def invalid_keys(errors: list[dict[str, Any]]) -> set[tuple[str, str, int]]:
    return {
        (
            str(error["sample_id"]),
            str(error["flow_id"]),
            int(error["repeat_id"]),
        )
        for error in errors
        if _is_error(error)
    }


def _ci_rate(values: list[bool]) -> tuple[float | None, float | None]:
    if not values:
        return None, None
    percentages = [100.0 if value else 0.0 for value in values]
    return bootstrap_ci(percentages)


def _desc_fields(prefix: str, values: list[float | int | None]) -> dict[str, Any]:
    desc = descriptive(values)
    low, high = bootstrap_ci(values)
    return {
        f"{prefix}_{key}": value for key, value in desc.items()
    } | {
        f"{prefix}_bootstrap_ci_low": low,
        f"{prefix}_bootstrap_ci_high": high,
    }


def aggregate_flows(
    runs: list[dict[str, Any]],
    errors: list[dict[str, Any]],
    counterexamples: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    invalid = invalid_keys(errors)
    rows: list[dict[str, Any]] = []
    for flow_id in FLOW_ORDER:
        all_flow = [run for run in runs if run["flow_id"] == flow_id]
        flow = [
            run
            for run in all_flow
            if (run["sample_id"], run["flow_id"], run["repeat_id"]) not in invalid
        ]
        repair_flag = (
            flow[0].get("error_context_enabled", flow[0].get("iterative"))
            if flow
            else None
        )
        repair_enabled = (
            bool(repair_flag)
            if repair_flag is not None
            else FLOW_SPECS[flow_id].iterative
        )
        candidates = [run for run in flow if run["compiler_attempts"] > 0]
        nc = len(candidates)
        nc0 = sum(run["compile_success_first"] for run in candidates)
        ncr = sum(run["any_compile_success_within_budget"] for run in candidates)
        first_pct = first_pass_rsr(nc0, nc)
        final_pct = final_rsr(ncr, nc)

        compile_cases = [run for run in flow if run["compile_repair_case"]]
        compile_successes = sum(
            run["compile_repair_success"] is True for run in compile_cases
        )
        concluded = [
            run for run in flow if run["behavioral_validation_completed"]
        ]
        behavioral_passes = sum(run["final_behavioral_pass"] is True for run in concluded)
        initial_concluded = [
            run for run in flow if run["first_behavioral_pass"] is not None
        ]
        initial_passes = sum(
            run["first_behavioral_pass"] is True for run in initial_concluded
        )
        initial_pct = program_behavioral_pass_rate(
            initial_passes, len(initial_concluded)
        )
        final_behavior_pct = program_behavioral_pass_rate(
            behavioral_passes, len(concluded)
        )
        match_values = [
            run["input_match_rate"]
            for run in concluded
            if run["input_match_rate"] is not None
        ]
        total_matches = sum(int(run["fuzz_matches"] or 0) for run in concluded)
        total_valid = sum(int(run["fuzz_valid"] or 0) for run in concluded)
        final_cex = sum(run["reproducible_final_counterexample"] for run in concluded)
        ever_cex = sum(
            run["reproducible_counterexample_ever_found"] for run in concluded
        )
        behavior_cases = [run for run in flow if run["behavioral_repair_case"]]
        behavior_successes = sum(
            run["behavioral_repair_success"] is True for run in behavior_cases
        )
        canonical_successes = sum(run["canonical_e2e_success"] for run in flow)
        reexec_successes = sum(
            bool(
                run.get(
                    "re_executability_success",
                    run.get("any_compile_success_within_budget"),
                )
            )
            for run in flow
        )
        flow_successes = sum(run["flow_specific_recovery_success"] for run in flow)
        total_recorded_tokens = sum(
            int(run["total_tokens"])
            for run in flow
            if run.get("total_tokens") is not None
        )
        generated = sum(int(run["fuzz_generated"] or 0) for run in flow)
        executed = sum(int(run["fuzz_executed_on_both"] or 0) for run in flow)
        valid = sum(int(run["fuzz_valid"] or 0) for run in flow)
        flow_cex = [
            item
            for item in counterexamples
            if item["flow_id"] == flow_id
            and (item["sample_id"], item["flow_id"], item["repeat_id"]) not in invalid
        ]
        replayed = sum(int(item["replay_count"] or 0) for item in flow_cex)
        replay_ok = sum(int(item["replay_success_count"] or 0) for item in flow_cex)
        first_ci = _ci_rate([bool(run["compile_success_first"]) for run in candidates])
        final_ci = _ci_rate(
            [bool(run["any_compile_success_within_budget"]) for run in candidates]
        )
        behavior_ci = _ci_rate(
            [bool(run["final_behavioral_pass"]) for run in concluded]
        )
        canonical_ci = _ci_rate(
            [bool(run["canonical_e2e_success"]) for run in flow]
        )
        reexec_ci = _ci_rate(
            [
                bool(
                    run.get(
                        "re_executability_success",
                        run.get("any_compile_success_within_budget"),
                    )
                )
                for run in flow
            ]
        )
        row: dict[str, Any] = {
            "flow_id": flow_id,
            "artifact_flow_id": (
                all_flow[0].get("artifact_flow_id", flow_id)
                if all_flow
                else flow_id
            ),
            "flow_name": (
                all_flow[0].get("flow_name")
                if all_flow
                else FLOW_SPECS[flow_id].name
            ),
            "derived_from_flow_id": (
                all_flow[0].get("derived_from_flow_id") if all_flow else None
            ),
            "independent_run": (
                all_flow[0].get("independent_run", True) if all_flow else True
            ),
            "error_context_enabled": repair_enabled,
            "sample_count": len(all_flow),
            "eligible_sample_count": len(flow),
            "excluded_invalid_sample_count": len(all_flow) - len(flow),
            "initial_candidate_count": nc,
            "first_compile_success_count": nc0,
            "first_pass_rsr_percent": first_pct,
            "first_pass_rsr_ci_low": first_ci[0],
            "first_pass_rsr_ci_high": first_ci[1],
            "compile_success_within_budget_count": ncr,
            "final_rsr_percent": final_pct,
            "final_rsr_ci_low": final_ci[0],
            "final_rsr_ci_high": final_ci[1],
            "compilation_repair_gain_pp": (
                gain(final_pct, first_pct) if repair_enabled else None
            ),
            "compile_repair_case_count": len(compile_cases),
            "compile_repair_success_count": compile_successes,
            "compilation_repair_success_rate_percent": (
                None
                if not repair_enabled
                else compilation_repair_success_rate(
                    compile_successes, len(compile_cases)
                )
            ),
            "compile_repair_budget_exhausted_count": sum(
                run["compile_repair_case"]
                and not run["any_compile_success_within_budget"]
                for run in flow
            ),
            "completed_behavioral_validation_count": len(concluded),
            "behavioral_pass_count": behavioral_passes,
            "program_behavioral_pass_rate_percent": final_behavior_pct,
            "program_behavioral_pass_rate_ci_low": behavior_ci[0],
            "program_behavioral_pass_rate_ci_high": behavior_ci[1],
            "initial_behavioral_validation_count": len(initial_concluded),
            "initial_behavioral_pass_count": initial_passes,
            "initial_behavioral_pass_rate_percent": initial_pct,
            "final_behavioral_pass_rate_percent": final_behavior_pct,
            "input_match_macro_percent": (
                sum(match_values) / len(match_values) if match_values else None
            ),
            "input_match_micro_percent": input_match_rate(total_matches, total_valid),
            "input_match_median_percent": (
                descriptive(match_values)["median"] if match_values else None
            ),
            "counterexample_sample_count": final_cex,
            "counterexample_detection_rate_percent": counterexample_detection_rate(
                final_cex, len(concluded)
            ),
            "counterexample_ever_detected_count": ever_cex,
            "counterexample_ever_detected_rate_percent": rate(
                ever_cex, len(concluded)
            ),
            "final_counterexample_rate_percent": rate(final_cex, len(concluded)),
            "behavioral_repair_case_count": len(behavior_cases),
            "behavioral_repair_success_count": behavior_successes,
            "semantic_repair_success_rate_percent": (
                None
                if not repair_enabled
                else semantic_repair_success_rate(
                    behavior_successes, len(behavior_cases)
                )
            ),
            "behavioral_repair_gain_pp": (
                None
                if not repair_enabled
                else gain(final_behavior_pct, initial_pct)
            ),
            "behavioral_repair_budget_exhausted_count": sum(
                run["behavioral_repair_case"]
                and run["behavioral_repair_success"] is False
                for run in flow
            ),
            "canonical_e2e_success_count": canonical_successes,
            "canonical_e2e_rate_percent": canonical_e2e_rate(
                canonical_successes, len(flow)
            ),
            "canonical_e2e_ci_low": canonical_ci[0],
            "canonical_e2e_ci_high": canonical_ci[1],
            "re_executability_success_count": reexec_successes,
            "re_executability_rate_percent": re_executability_rate(
                reexec_successes, len(flow)
            ),
            "re_executability_ci_low": reexec_ci[0],
            "re_executability_ci_high": reexec_ci[1],
            "flow_specific_recovery_success_count": flow_successes,
            "flow_specific_recovery_rate_percent": flow_specific_recovery_rate(
                flow_successes, len(flow)
            ),
            "fuzz_generated_count": generated,
            "fuzz_executed_on_both_count": executed,
            "fuzz_valid_count": valid,
            "valid_input_rate_percent": valid_input_rate(valid, generated),
            "executable_pair_execution_rate_percent": executable_pair_execution_rate(
                executed, generated
            ),
            "counterexample_replay_count": replayed,
            "counterexample_replay_success_count": replay_ok,
            "counterexample_reproducibility_rate_percent": reproducibility_rate(
                replay_ok, replayed
            ),
            "inconclusive_count": sum(
                run["status"] == "INCONCLUSIVE" for run in flow
            ),
            "inconclusive_rate_percent": inconclusive_rate(
                sum(run["status"] == "INCONCLUSIVE" for run in flow), len(flow)
            ),
            "mean_llm_calls": descriptive(
                [run["llm_calls"] for run in flow]
            )["mean"],
            "mean_tokens": descriptive(
                [run["total_tokens"] for run in flow]
            )["mean"],
            "mean_runtime_seconds": descriptive(
                [run["total_runtime"] for run in flow]
            )["mean"],
            "mean_estimated_api_cost": descriptive(
                [run["estimated_api_cost"] for run in flow]
            )["mean"],
            "tokens_per_behavioral_pass": (
                total_recorded_tokens / behavioral_passes
                if behavioral_passes
                else None
            ),
            "tokens_per_e2e_success": (
                total_recorded_tokens / canonical_successes
                if canonical_successes
                else None
            ),
            "runtime_per_behavioral_pass_seconds": (
                sum(float(run["total_runtime"] or 0) for run in flow)
                / behavioral_passes
                if behavioral_passes
                else None
            ),
            "runtime_per_e2e_success_seconds": (
                sum(float(run["total_runtime"] or 0) for run in flow)
                / canonical_successes
                if canonical_successes
                else None
            ),
            "llm_calls_per_successful_recovery": (
                sum(run["llm_calls"] for run in flow) / canonical_successes
                if canonical_successes
                else None
            ),
        }
        row.update(
            _desc_fields(
                "compile_repair_rounds",
                [
                    run["compile_repair_rounds"]
                    for run in compile_cases
                ]
                if repair_enabled
                else [],
            )
        )
        row.update(
            _desc_fields(
                "behavioral_repair_rounds",
                [
                    run["behavioral_repair_rounds"]
                    for run in behavior_cases
                ]
                if repair_enabled
                else [],
            )
        )
        row.update(
            _desc_fields(
                "compiler_attempts", [run["compiler_attempts"] for run in flow]
            )
        )
        row.update(
            _desc_fields("total_tokens", [run["total_tokens"] for run in flow])
        )
        row.update(
            _desc_fields(
                "total_runtime_seconds", [run["total_runtime"] for run in flow]
            )
        )
        row.update(
            _desc_fields(
                "input_match_percent",
                [run["input_match_rate"] for run in flow],
            )
        )
        rows.append(row)
    return rows


STAGES = (
    ("binary_lifting", "binary_lifting_completed"),
    ("raw_ir_generation", "raw_ir_generated"),
    ("llvm_deobfuscation", "llvm_deobfuscation_completed"),
    ("llvm_ir_verification", "llvm_ir_verification_completed"),
    ("pseudocode_generation", "pseudocode_generated"),
    ("llm_generation", "llm_generation_completed"),
    ("compilation", "compilation_completed"),
    ("fuzzing", "fuzzing_completed"),
    ("behavioral_validation", "behavioral_validation_completed"),
    ("candidate_acceptance", "candidate_accepted"),
)


def stage_completion_rows(
    runs: list[dict[str, Any]], errors: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    invalid = invalid_keys(errors)
    rows: list[dict[str, Any]] = []
    for flow_id in FLOW_ORDER:
        flow = [
            run
            for run in runs
            if run["flow_id"] == flow_id
            and (run["sample_id"], run["flow_id"], run["repeat_id"]) not in invalid
        ]
        for stage, field in STAGES:
            numerator = sum(bool(run[field]) for run in flow)
            rows.append(
                {
                    "flow_id": flow_id,
                    "stage": stage,
                    "numerator": numerator,
                    "denominator": len(flow),
                    "percentage": rate(numerator, len(flow)),
                }
            )
    return rows


def failure_rows(
    runs: list[dict[str, Any]],
    compile_attempts: list[dict[str, Any]],
    counterexamples: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for flow_id in FLOW_ORDER:
        for category, count in sorted(
            collections.Counter(
                run["status"] for run in runs if run["flow_id"] == flow_id
            ).items()
        ):
            rows.append(
                {
                    "flow_id": flow_id,
                    "taxonomy": "FINAL_STATUS",
                    "category": category,
                    "count": count,
                }
            )
        for category, count in sorted(
            collections.Counter(
                attempt["failure_category"]
                for attempt in compile_attempts
                if attempt["flow_id"] == flow_id and attempt["failure_category"]
            ).items()
        ):
            rows.append(
                {
                    "flow_id": flow_id,
                    "taxonomy": "COMPILE_FAILURE",
                    "category": category,
                    "count": count,
                }
            )
        # Count each sample once from its latest persisted campaign. Multiple
        # divergence mechanisms within that campaign are a mixed divergence.
        by_sample: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
        for item in counterexamples:
            if item["flow_id"] == flow_id:
                by_sample[item["sample_id"]].append(item)
        categorized: collections.Counter[str] = collections.Counter()
        for sample_items in by_sample.values():
            latest = max(item["campaign_index"] for item in sample_items)
            types = {
                item["divergence_type"]
                for item in sample_items
                if item["campaign_index"] == latest
            }
            category = next(iter(types)) if len(types) == 1 else "MIXED_DIVERGENCE"
            categorized[category] += 1
        for category, count in sorted(categorized.items()):
            rows.append(
                {
                    "flow_id": flow_id,
                    "taxonomy": "BEHAVIORAL_DIVERGENCE",
                    "category": category,
                    "count": count,
                }
            )
        reasons = collections.Counter(
            run["inconclusive_reason"]
            for run in runs
            if run["flow_id"] == flow_id
            and run["status"] == "INCONCLUSIVE"
        )
        for category, count in sorted(reasons.items()):
            rows.append(
                {
                    "flow_id": flow_id,
                    "taxonomy": "INCONCLUSIVE",
                    "category": category or "OTHER",
                    "count": count,
                }
            )
    return rows
