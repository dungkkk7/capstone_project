#!/usr/bin/env python3
"""Run the existing experiment with metric tracking fixed to the thesis definitions.

Use this entry point instead of ``run_experiment.py``. It reuses the existing
pipeline but patches metric collection so that:

* rate columns are numeric percentages and end in ``_pct``;
* gain columns are numeric percentage points and end in ``_pp``;
* counts end in ``_count``;
* durations end in ``_seconds``;
* undefined ratios are exported as an empty CSV cell, not as 0% or 100%;
* Final RSR@R records whether any candidate built within the compiler-repair
  budget, independently of later behavioral-repair regressions.
"""

from __future__ import annotations

import csv
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

# Allow execution as ``python src/evaluation/run_experiment_metrics_fixed.py``.
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from evaluation import run_experiment as base
from evaluation.metric_definitions import (
    compilation_repair_success_rate,
    counterexample_detection_rate,
    counterexample_reproducibility_rate,
    end_to_end_recovery_rate,
    final_rsr_at_r,
    first_pass_rsr,
    inconclusive_rate,
    input_behavioral_match_rate,
    percentage_point_gain,
    program_behavioral_pass_rate,
    semantic_repair_success_rate,
    valid_input_rate,
)


EXTRA_DEFAULTS: Dict[str, Any] = {
    # Compilation stage
    "compile_success_ever_within_r": False,
    "final_retained_executable": False,
    # Behavioral stage
    "fuzz_campaign_completed": False,
    "first_behavioral_pass": False,
    "final_behavioral_pass": False,
    "entered_behavioral_repair": False,
    # Differential-run accounting
    "fuzz_confirmed": 0,
    "generated_input_count": 0,
    "valid_generated_input_count": 0,
    "reported_counterexample_count": 0,
    "reproduced_counterexample_count": 0,
}


def _ensure_fields(tracker: Any) -> None:
    for name, default in EXTRA_DEFAULTS.items():
        if not hasattr(tracker, name):
            setattr(tracker, name, default)


def _nullable(value: Optional[float]) -> str | float:
    """Return an empty cell for an undefined metric."""

    return "" if value is None else round(float(value), 4)


def _fuzz_generated_counts(report: Dict[str, Any]) -> tuple[int, int]:
    """Extract N_G and N_V from one fuzzing report.

    For AFL++, N_G is the number of candidate payloads presented to the input
    contract and N_V is the number accepted by that contract. For fallback
    contract generation, the accepted/rejected contract counts are used.
    The executed differential corpus is deliberately not used as N_G because
    it may include seeds and contract supplements.
    """

    cfg = report.get("fuzz_config") or {}
    if "afl_candidates" in cfg:
        generated = int(cfg.get("afl_candidates", 0) or 0)
        valid = int(cfg.get("afl_accepted", 0) or 0)
        return generated, valid

    accepted = int(cfg.get("contract_inputs_accepted", 0) or 0)
    rejected = int(cfg.get("contract_inputs_rejected", 0) or 0)
    if accepted or rejected:
        return accepted + rejected, accepted

    # No raw-generation denominator was recorded. Returning zero makes the
    # Valid Input Rate undefined rather than incorrectly reporting 100%.
    return 0, 0


# ---------------------------------------------------------------------------
# Patch tracker persistence
# ---------------------------------------------------------------------------

_original_to_dict = base.CaseTracker.to_dict
_original_from_dict = base.CaseTracker.from_dict.__func__


def _to_dict_fixed(self: Any) -> Dict[str, Any]:
    _ensure_fields(self)
    data = _original_to_dict(self)
    data.update({name: getattr(self, name) for name in EXTRA_DEFAULTS})
    return data


@classmethod
def _from_dict_fixed(cls: type, data: Dict[str, Any]) -> Any:
    tracker = _original_from_dict(cls, data)
    _ensure_fields(tracker)
    for name, default in EXTRA_DEFAULTS.items():
        setattr(tracker, name, data.get(name, default))
    return tracker


base.CaseTracker.to_dict = _to_dict_fixed
base.CaseTracker.from_dict = _from_dict_fixed


# ---------------------------------------------------------------------------
# Patch stage tracking
# ---------------------------------------------------------------------------

_original_compile_check = base._run_compile_check_tracked
_original_fuzzing = base.run_fuzzing_tracked


def _compile_check_fixed(
    candidate_path: str,
    output_dir: str,
    tracker: Any,
):
    _ensure_fields(tracker)
    ok, diagnostics = _original_compile_check(candidate_path, output_dir, tracker)
    attempt_number = int(tracker.compiler_attempts)
    if attempt_number == 1:
        tracker.compile_success_first = bool(ok)
    if ok:
        # This value is monotonic. A later semantic-repair candidate that does
        # not build must not erase an earlier build success within R.
        tracker.compile_success_ever_within_r = True
    return ok, diagnostics


def _fuzzing_fixed(
    candidate_path: str,
    ref_binary: str,
    contract: Any,
    generator: Any,
    seeds: list,
    tracker: Any,
    iterations: int,
) -> Dict[str, Any]:
    _ensure_fields(tracker)
    is_first_campaign = not tracker.fuzz_campaign_completed
    report = _original_fuzzing(
        candidate_path,
        ref_binary,
        contract,
        generator,
        seeds,
        tracker,
        iterations,
    )

    total = int(report.get("total_runs", 0) or 0)
    matches = int(report.get("matches", 0) or 0)
    mismatches = int(report.get("mismatches", 0) or 0)
    inconclusive = int(report.get("inconclusive", 0) or 0)
    confirmed = int(report.get("confirmed_runs", 0) or 0)
    if confirmed <= 0:
        confirmed = matches + mismatches

    completed = total > 0 and not report.get("error")
    fully_equivalent = bool(
        report.get("is_fully_equivalent", False)
        and mismatches == 0
        and inconclusive == 0
    )

    if completed:
        tracker.fuzz_campaign_completed = True
    tracker.fuzz_confirmed += confirmed

    generated, valid = _fuzz_generated_counts(report)
    tracker.generated_input_count += generated
    tracker.valid_generated_input_count += valid

    # Mismatches have already passed the fuzzer's stability checks; unstable
    # observations are placed in the inconclusive bucket instead.
    tracker.reported_counterexample_count += mismatches
    tracker.reproduced_counterexample_count += mismatches

    if is_first_campaign:
        tracker.first_behavioral_pass = fully_equivalent
    tracker.final_behavioral_pass = fully_equivalent
    if mismatches > 0:
        tracker.entered_behavioral_repair = True

    return report


base._run_compile_check_tracked = _compile_check_fixed
base.run_fuzzing_tracked = _fuzzing_fixed


# ---------------------------------------------------------------------------
# Canonical CSV export
# ---------------------------------------------------------------------------

PER_SAMPLE_COLUMNS = [
    "sample_id",
    "flow_id",
    "llm_calls_count",
    "compiler_attempts_count",
    "behavioral_repairs_count",
    "compile_success_first",
    "compile_success_ever_within_r",
    "final_retained_executable",
    "compile_repair_rounds_count",
    "behavioral_repair_rounds_count",
    "fuzz_campaign_completed",
    "first_behavioral_pass",
    "final_behavioral_pass",
    "entered_behavioral_repair",
    "fuzz_total_runs_count",
    "fuzz_confirmed_runs_count",
    "fuzz_matches_count",
    "generated_inputs_count",
    "valid_generated_inputs_count",
    "reported_counterexamples_count",
    "reproduced_counterexamples_count",
    "status",
    "input_tokens_count",
    "output_tokens_count",
    "llm_latency_seconds",
    "compilation_time_seconds",
    "fuzzing_time_seconds",
    "total_runtime_seconds",
]


def _sample_row(t: Any) -> Dict[str, Any]:
    _ensure_fields(t)
    # Preserve the existing final candidate state under an explicit name.
    t.final_retained_executable = bool(t.compile_success_final)
    return {
        "sample_id": t.sample_id,
        "flow_id": t.flow_id,
        "llm_calls_count": t.llm_calls,
        "compiler_attempts_count": t.compiler_attempts,
        "behavioral_repairs_count": t.behavioral_repairs,
        "compile_success_first": bool(t.compile_success_first),
        "compile_success_ever_within_r": bool(t.compile_success_ever_within_r),
        "final_retained_executable": bool(t.final_retained_executable),
        "compile_repair_rounds_count": t.compile_repair_rounds,
        "behavioral_repair_rounds_count": t.behavioral_repair_rounds,
        "fuzz_campaign_completed": bool(t.fuzz_campaign_completed),
        "first_behavioral_pass": bool(t.first_behavioral_pass),
        "final_behavioral_pass": bool(t.final_behavioral_pass),
        "entered_behavioral_repair": bool(t.entered_behavioral_repair),
        "fuzz_total_runs_count": t.fuzz_total,
        "fuzz_confirmed_runs_count": t.fuzz_confirmed,
        "fuzz_matches_count": t.fuzz_matches,
        "generated_inputs_count": t.generated_input_count,
        "valid_generated_inputs_count": t.valid_generated_input_count,
        "reported_counterexamples_count": t.reported_counterexample_count,
        "reproduced_counterexamples_count": t.reproduced_counterexample_count,
        "status": t.status,
        "input_tokens_count": t.input_tokens,
        "output_tokens_count": t.output_tokens,
        "llm_latency_seconds": round(float(t.llm_latency), 6),
        "compilation_time_seconds": round(float(t.compile_time), 6),
        "fuzzing_time_seconds": round(float(t.fuzzing_time), 6),
        "total_runtime_seconds": round(float(t.total_runtime), 6),
    }


def _write_dict_csv(path: str, rows: Iterable[Dict[str, Any]], columns: List[str]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)


def _flow_metrics(flow_ts: List[Any]) -> Dict[str, Any]:
    for tracker in flow_ts:
        _ensure_fields(tracker)
        tracker.final_retained_executable = bool(tracker.compile_success_final)

    n = len(flow_ts)
    initial_success = sum(bool(t.compile_success_first) for t in flow_ts)
    ever_success = sum(bool(t.compile_success_ever_within_r) for t in flow_ts)
    initial_failures = n - initial_success
    repaired_failures = sum(
        (not bool(t.compile_success_first))
        and bool(t.compile_success_ever_within_r)
        for t in flow_ts
    )

    fuzzed = [t for t in flow_ts if t.fuzz_campaign_completed]
    nf = len(fuzzed)
    behavioral_passes = sum(bool(t.final_behavioral_pass) for t in fuzzed)
    confirmed_runs = sum(int(t.fuzz_confirmed) for t in fuzzed)
    matches = sum(int(t.fuzz_matches) for t in fuzzed)
    cex_samples = sum(int(t.reported_counterexample_count) > 0 for t in fuzzed)

    repaired_behavior = [t for t in flow_ts if t.entered_behavioral_repair]
    nbr = len(repaired_behavior)
    nbrs = sum(bool(t.final_behavioral_pass) for t in repaired_behavior)

    before_behavior_rate = program_behavioral_pass_rate(
        sum(bool(t.first_behavioral_pass) for t in fuzzed),
        nf,
    )
    after_behavior_rate = program_behavioral_pass_rate(behavioral_passes, nf)

    generated = sum(int(t.generated_input_count) for t in flow_ts)
    valid_generated = sum(int(t.valid_generated_input_count) for t in flow_ts)
    reported_cex = sum(int(t.reported_counterexample_count) for t in flow_ts)
    reproduced_cex = sum(int(t.reproduced_counterexample_count) for t in flow_ts)
    inconclusive = sum(t.status == "INCONCLUSIVE" for t in flow_ts)
    e2e = sum(t.status == "PASS" for t in flow_ts)

    first_pct = first_pass_rsr(initial_success, n)
    final_pct = final_rsr_at_r(ever_success, n)

    return {
        "sample_count": n,
        "initial_compile_success_count": initial_success,
        "build_success_within_r_count": ever_success,
        "initial_compile_failure_count": initial_failures,
        "repaired_initial_compile_failure_count": repaired_failures,
        "first_pass_rsr_pct": _nullable(first_pct),
        "final_rsr_at_r_pct": _nullable(final_pct),
        "compilation_repair_gain_pp": _nullable(
            percentage_point_gain(final_pct, first_pct)
        ),
        "compilation_repair_success_rate_pct": _nullable(
            compilation_repair_success_rate(repaired_failures, initial_failures)
        ),
        "final_retained_executable_rate_pct": _nullable(
            first_pass_rsr(
                sum(bool(t.final_retained_executable) for t in flow_ts),
                n,
            )
        ),
        "completed_fuzz_campaign_count": nf,
        "behavioral_pass_count": behavioral_passes,
        "program_behavioral_pass_rate_pct": _nullable(after_behavior_rate),
        "input_behavioral_match_rate_micro_pct": _nullable(
            input_behavioral_match_rate(matches, confirmed_runs)
        ),
        "counterexample_sample_count": cex_samples,
        "counterexample_detection_rate_pct": _nullable(
            counterexample_detection_rate(cex_samples, nf)
        ),
        "behavioral_repair_candidate_count": nbr,
        "successful_behavioral_repair_count": nbrs,
        "semantic_repair_success_rate_pct": _nullable(
            semantic_repair_success_rate(nbrs, nbr)
        ),
        "behavioral_pass_rate_before_repair_pct": _nullable(before_behavior_rate),
        "behavioral_pass_rate_after_repair_pct": _nullable(after_behavior_rate),
        "behavioral_repair_gain_pp": _nullable(
            percentage_point_gain(after_behavior_rate, before_behavior_rate)
        ),
        "generated_inputs_count": generated,
        "valid_generated_inputs_count": valid_generated,
        "valid_input_rate_pct": _nullable(valid_input_rate(valid_generated, generated)),
        "reported_counterexamples_count": reported_cex,
        "reproduced_counterexamples_count": reproduced_cex,
        "counterexample_reproducibility_rate_pct": _nullable(
            counterexample_reproducibility_rate(reproduced_cex, reported_cex)
        ),
        "inconclusive_sample_count": inconclusive,
        "inconclusive_rate_pct": _nullable(inconclusive_rate(inconclusive, n)),
        "e2e_recovery_count": e2e,
        "e2e_recovery_rate_pct": _nullable(end_to_end_recovery_rate(e2e, n)),
        "mean_llm_calls_count": round(sum(t.llm_calls for t in flow_ts) / n, 4),
        "mean_tokens_count": round(
            sum(t.input_tokens + t.output_tokens for t in flow_ts) / n,
            4,
        ),
        "mean_runtime_seconds": round(sum(t.total_runtime for t in flow_ts) / n, 4),
    }


def export_metrics_csvs_fixed(
    trackers: List[Any],
    output_dir: str,
    experiment_id: str,
) -> None:
    os.makedirs(output_dir, exist_ok=True)

    sample_rows = [_sample_row(t) for t in trackers]
    _write_dict_csv(
        os.path.join(output_dir, "per_sample_results.csv"),
        sample_rows,
        PER_SAMPLE_COLUMNS,
    )

    flow_rows: List[Dict[str, Any]] = []
    for flow in ["F1", "F2", "F3", "F4", "F5"]:
        flow_ts = [t for t in trackers if t.flow_id == flow]
        if not flow_ts:
            continue
        row = {"flow_id": flow}
        row.update(_flow_metrics(flow_ts))
        flow_rows.append(row)

    if flow_rows:
        _write_dict_csv(
            os.path.join(output_dir, "per_flow_metrics.csv"),
            flow_rows,
            list(flow_rows[0].keys()),
        )

        repair_columns = [
            "flow_id",
            "initial_compile_failure_count",
            "repaired_initial_compile_failure_count",
            "compilation_repair_success_rate_pct",
            "compilation_repair_gain_pp",
            "behavioral_repair_candidate_count",
            "successful_behavioral_repair_count",
            "semantic_repair_success_rate_pct",
            "behavioral_repair_gain_pp",
        ]
        _write_dict_csv(
            os.path.join(output_dir, "repair_metrics.csv"),
            ({key: row.get(key, "") for key in repair_columns} for row in flow_rows),
            repair_columns,
        )

        reliability_columns = [
            "flow_id",
            "generated_inputs_count",
            "valid_generated_inputs_count",
            "valid_input_rate_pct",
            "reported_counterexamples_count",
            "reproduced_counterexamples_count",
            "counterexample_reproducibility_rate_pct",
            "inconclusive_sample_count",
            "inconclusive_rate_pct",
        ]
        _write_dict_csv(
            os.path.join(output_dir, "reliability_metrics.csv"),
            ({key: row.get(key, "") for key in reliability_columns} for row in flow_rows),
            reliability_columns,
        )

    metadata = {
        "experiment_id": experiment_id,
        "rate_unit": "percent",
        "gain_unit": "percentage points",
        "duration_unit": "seconds",
        "undefined_ratio_encoding": "empty CSV cell",
        "input_match_denominator": "confirmed runs = matches + mismatches",
        "final_rsr_definition": "candidate built at least once within compiler-repair budget R",
        "final_retained_executable_definition": "last candidate after all repair stages still builds",
    }
    with open(
        os.path.join(output_dir, "metric_units.json"),
        "w",
        encoding="utf-8",
    ) as handle:
        json.dump(metadata, handle, indent=2)

    print(
        f"[✓] Canonical metric CSVs exported to {output_dir} "
        "(% for rates, pp for gains, seconds for durations).",
        flush=True,
    )


base.export_metrics_csvs = export_metrics_csvs_fixed


if __name__ == "__main__":
    base.main()
