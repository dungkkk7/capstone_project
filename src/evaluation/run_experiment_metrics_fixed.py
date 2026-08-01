#!/usr/bin/env python3
"""Run the existing experiment with metric tracking aligned to the thesis definitions.

Use this entry point instead of ``run_experiment.py``. The exported CSV files use:

* percentages for rate metrics (column suffix ``_pct``);
* percentage points for gain metrics (column suffix ``_pp``);
* counts for event/sample totals (column suffix ``_count``);
* seconds for durations (column suffix ``_seconds``);
* empty cells for undefined ratios.

No supplementary recovery-rate metric is added beyond the approved metric set.
"""

from __future__ import annotations

import csv
import json
import os
import statistics
import sys
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
    # Behavioral stage
    "fuzz_campaign_completed": False,
    "first_behavioral_pass": False,
    "final_behavioral_pass": False,
    "entered_behavioral_repair": False,
    # Final differential campaign
    "final_fuzz_total": 0,
    "final_fuzz_confirmed": 0,
    "final_fuzz_matches": 0,
    "final_fuzz_mismatches": 0,
    "final_fuzz_inconclusive": 0,
    # Reliability accounting across generated campaigns
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
    """Return an empty CSV cell for an undefined metric."""

    return "" if value is None else round(float(value), 4)


def _mean(values: List[int | float]) -> Optional[float]:
    return None if not values else float(statistics.mean(values))


def _median(values: List[int | float]) -> Optional[float]:
    return None if not values else float(statistics.median(values))


def _minimum(values: List[int | float]) -> Optional[float]:
    return None if not values else float(min(values))


def _maximum(values: List[int | float]) -> Optional[float]:
    return None if not values else float(max(values))


def _fuzz_generated_counts(report: Dict[str, Any]) -> tuple[int, int]:
    """Extract raw generated-input count N_G and valid-input count N_V.

    For AFL++, ``afl_candidates`` is the number of payloads presented to the
    input-contract filter and ``afl_accepted`` is the number accepted. For the
    fallback contract generator, accepted and rejected contract counts are
    used. When no raw-generation denominator is recorded, ``(0, 0)`` is
    returned so Valid Input Rate is exported as undefined rather than 100%.
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

    return 0, 0


# ---------------------------------------------------------------------------
# Tracker persistence
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
# Stage tracking
# ---------------------------------------------------------------------------

_original_compile_check = base._run_compile_check_tracked
_original_fuzzing = base.run_fuzzing_tracked


def _compile_check_fixed(
    candidate_path: str,
    output_dir: str,
    tracker: Any,
):
    """Track first-pass build success and monotonic build success within R."""

    _ensure_fields(tracker)
    ok, diagnostics = _original_compile_check(candidate_path, output_dir, tracker)

    if int(tracker.compiler_attempts) == 1:
        tracker.compile_success_first = bool(ok)

    if ok:
        # Monotonic by definition: later behavioral-repair regressions must not
        # erase a build success already achieved within the compiler budget.
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
    """Track final-campaign correctness and campaign-level reliability data."""

    _ensure_fields(tracker)
    is_first_completed_campaign = not tracker.fuzz_campaign_completed

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
    # Unstable executions are excluded from the valid-input denominator.
    # A completed campaign passes when it has no reproducible mismatch.
    fully_equivalent = bool(completed and mismatches == 0)

    if completed:
        if is_first_completed_campaign:
            tracker.first_behavioral_pass = fully_equivalent

        tracker.fuzz_campaign_completed = True
        tracker.final_behavioral_pass = fully_equivalent
        tracker.final_fuzz_total = total
        tracker.final_fuzz_confirmed = confirmed
        tracker.final_fuzz_matches = matches
        tracker.final_fuzz_mismatches = mismatches
        tracker.final_fuzz_inconclusive = inconclusive

    generated, valid = _fuzz_generated_counts(report)
    tracker.generated_input_count += generated
    tracker.valid_generated_input_count += valid

    # The fuzzer moves unstable observations into the inconclusive bucket.
    # Remaining mismatches are therefore confirmed counterexamples.
    tracker.reported_counterexample_count += mismatches
    tracker.reproduced_counterexample_count += mismatches

    # The one-shot flow must not be counted as entering a repair stage.
    if mismatches > 0 and base.FLOW_SPECS[tracker.flow_id].iterative:
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
    "compile_repair_rounds_count",
    "behavioral_repair_rounds_count",
    "fuzz_campaign_completed",
    "first_behavioral_pass",
    "final_behavioral_pass",
    "entered_behavioral_repair",
    "fuzz_total_runs_count",
    "fuzz_confirmed_runs_count",
    "fuzz_matches_count",
    "fuzz_mismatches_count",
    "fuzz_inconclusive_runs_count",
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
    return {
        "sample_id": t.sample_id,
        "flow_id": t.flow_id,
        "llm_calls_count": t.llm_calls,
        "compiler_attempts_count": t.compiler_attempts,
        "behavioral_repairs_count": t.behavioral_repairs,
        "compile_success_first": bool(t.compile_success_first),
        "compile_success_ever_within_r": bool(t.compile_success_ever_within_r),
        "compile_repair_rounds_count": t.compile_repair_rounds,
        "behavioral_repair_rounds_count": t.behavioral_repair_rounds,
        "fuzz_campaign_completed": bool(t.fuzz_campaign_completed),
        "first_behavioral_pass": bool(t.first_behavioral_pass),
        "final_behavioral_pass": bool(t.final_behavioral_pass),
        "entered_behavioral_repair": bool(t.entered_behavioral_repair),
        "fuzz_total_runs_count": t.final_fuzz_total,
        "fuzz_confirmed_runs_count": t.final_fuzz_confirmed,
        "fuzz_matches_count": t.final_fuzz_matches,
        "fuzz_mismatches_count": t.final_fuzz_mismatches,
        "fuzz_inconclusive_runs_count": t.final_fuzz_inconclusive,
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


def _write_dict_csv(
    path: str,
    rows: Iterable[Dict[str, Any]],
    columns: List[str],
) -> None:
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)


def _flow_metrics(flow_ts: List[Any]) -> Dict[str, Any]:
    for tracker in flow_ts:
        _ensure_fields(tracker)

    n = len(flow_ts)

    # Compilation metrics
    initial_success = sum(bool(t.compile_success_first) for t in flow_ts)
    success_within_r = sum(bool(t.compile_success_ever_within_r) for t in flow_ts)
    initial_failures = n - initial_success
    repaired_initial_failures = sum(
        (not bool(t.compile_success_first))
        and bool(t.compile_success_ever_within_r)
        for t in flow_ts
    )
    first_pct = first_pass_rsr(initial_success, n)
    final_pct = final_rsr_at_r(success_within_r, n)

    compile_rounds = [
        int(t.compile_repair_rounds)
        for t in flow_ts
        if not bool(t.compile_success_first)
    ]
    compile_failed_after_budget = sum(
        (not bool(t.compile_success_first))
        and (not bool(t.compile_success_ever_within_r))
        for t in flow_ts
    )

    # Behavioral correctness metrics use only completed final campaigns.
    fuzzed = [t for t in flow_ts if bool(t.fuzz_campaign_completed)]
    nf = len(fuzzed)
    behavioral_passes = sum(bool(t.final_behavioral_pass) for t in fuzzed)
    confirmed_runs = sum(int(t.final_fuzz_confirmed) for t in fuzzed)
    matches = sum(int(t.final_fuzz_matches) for t in fuzzed)

    # A sample is counted once when at least one confirmed counterexample was
    # found during its recovery process.
    cex_samples = sum(
        int(t.reported_counterexample_count) > 0
        for t in fuzzed
    )

    # Behavioral repair metrics
    repair_candidates = [
        t for t in flow_ts if bool(t.entered_behavioral_repair)
    ]
    nbr = len(repair_candidates)
    nbrs = sum(bool(t.final_behavioral_pass) for t in repair_candidates)
    behavioral_rounds = [
        int(t.behavioral_repair_rounds) for t in repair_candidates
    ]

    before_behavior_rate = program_behavioral_pass_rate(
        sum(bool(t.first_behavioral_pass) for t in fuzzed),
        nf,
    )
    after_behavior_rate = program_behavioral_pass_rate(
        behavioral_passes,
        nf,
    )

    # Reliability and E2E metrics
    generated = sum(int(t.generated_input_count) for t in flow_ts)
    valid_generated = sum(int(t.valid_generated_input_count) for t in flow_ts)
    reported_cex = sum(int(t.reported_counterexample_count) for t in flow_ts)
    reproduced_cex = sum(int(t.reproduced_counterexample_count) for t in flow_ts)
    inconclusive_samples = sum(t.status == "INCONCLUSIVE" for t in flow_ts)
    e2e_successes = sum(t.status == "PASS" for t in flow_ts)

    return {
        "sample_count": n,

        "initial_compile_success_count": initial_success,
        "build_success_within_r_count": success_within_r,
        "initial_compile_failure_count": initial_failures,
        "repaired_initial_compile_failure_count": repaired_initial_failures,
        "compiler_repair_failed_after_budget_count": compile_failed_after_budget,
        "first_pass_rsr_pct": _nullable(first_pct),
        "final_rsr_at_r_pct": _nullable(final_pct),
        "compilation_repair_gain_pp": _nullable(
            percentage_point_gain(final_pct, first_pct)
        ),
        "compilation_repair_success_rate_pct": _nullable(
            compilation_repair_success_rate(
                repaired_initial_failures,
                initial_failures,
            )
        ),
        "mean_compile_repair_rounds_count": _nullable(_mean(compile_rounds)),
        "median_compile_repair_rounds_count": _nullable(_median(compile_rounds)),
        "min_compile_repair_rounds_count": _nullable(_minimum(compile_rounds)),
        "max_compile_repair_rounds_count": _nullable(_maximum(compile_rounds)),

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
        "behavioral_pass_rate_before_repair_pct": _nullable(
            before_behavior_rate
        ),
        "behavioral_pass_rate_after_repair_pct": _nullable(
            after_behavior_rate
        ),
        "behavioral_repair_gain_pp": _nullable(
            percentage_point_gain(
                after_behavior_rate,
                before_behavior_rate,
            )
        ),
        "mean_behavioral_repair_rounds_count": _nullable(
            _mean(behavioral_rounds)
        ),
        "median_behavioral_repair_rounds_count": _nullable(
            _median(behavioral_rounds)
        ),
        "min_behavioral_repair_rounds_count": _nullable(
            _minimum(behavioral_rounds)
        ),
        "max_behavioral_repair_rounds_count": _nullable(
            _maximum(behavioral_rounds)
        ),

        "generated_inputs_count": generated,
        "valid_generated_inputs_count": valid_generated,
        "valid_input_rate_pct": _nullable(
            valid_input_rate(valid_generated, generated)
        ),
        "reported_counterexamples_count": reported_cex,
        "reproduced_counterexamples_count": reproduced_cex,
        "counterexample_reproducibility_rate_pct": _nullable(
            counterexample_reproducibility_rate(
                reproduced_cex,
                reported_cex,
            )
        ),
        "inconclusive_sample_count": inconclusive_samples,
        "inconclusive_rate_pct": _nullable(
            inconclusive_rate(inconclusive_samples, n)
        ),

        "e2e_recovery_count": e2e_successes,
        "e2e_recovery_rate_pct": _nullable(
            end_to_end_recovery_rate(e2e_successes, n)
        ),

        # Existing resource measurements retained with explicit units.
        "mean_llm_calls_count": round(
            sum(t.llm_calls for t in flow_ts) / n,
            4,
        ),
        "mean_tokens_count": round(
            sum(t.input_tokens + t.output_tokens for t in flow_ts) / n,
            4,
        ),
        "mean_runtime_seconds": round(
            sum(t.total_runtime for t in flow_ts) / n,
            4,
        ),
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
            "compiler_repair_failed_after_budget_count",
            "compilation_repair_success_rate_pct",
            "compilation_repair_gain_pp",
            "mean_compile_repair_rounds_count",
            "median_compile_repair_rounds_count",
            "min_compile_repair_rounds_count",
            "max_compile_repair_rounds_count",
            "behavioral_repair_candidate_count",
            "successful_behavioral_repair_count",
            "semantic_repair_success_rate_pct",
            "behavioral_repair_gain_pp",
            "mean_behavioral_repair_rounds_count",
            "median_behavioral_repair_rounds_count",
            "min_behavioral_repair_rounds_count",
            "max_behavioral_repair_rounds_count",
        ]
        _write_dict_csv(
            os.path.join(output_dir, "repair_metrics.csv"),
            (
                {key: row.get(key, "") for key in repair_columns}
                for row in flow_rows
            ),
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
            (
                {key: row.get(key, "") for key in reliability_columns}
                for row in flow_rows
            ),
            reliability_columns,
        )

    metadata = {
        "experiment_id": experiment_id,
        "rate_unit": "percent",
        "gain_unit": "percentage points",
        "count_unit": "count",
        "duration_unit": "seconds",
        "undefined_ratio_encoding": "empty CSV cell",
        "input_match_denominator": "confirmed runs = matches + mismatches",
        "final_rsr_definition": (
            "candidate built at least once within compiler-repair budget R"
        ),
    }
    with open(
        os.path.join(output_dir, "metric_units.json"),
        "w",
        encoding="utf-8",
    ) as handle:
        json.dump(metadata, handle, indent=2)

    # Preserve this historical entry point while making schema v2 the
    # authoritative final output.
    try:
        from pathlib import Path
        from evaluation.artifact_loader import load_campaign
        from evaluation.reporting import export_report

        project_root = Path(__file__).resolve().parents[2]
        campaign_id = experiment_id.replace("experiment_", "eval_", 1)
        campaign_dir = project_root / "result" / campaign_id
        if campaign_dir.is_dir():
            export_report(
                load_campaign(project_root, campaign_dir, experiment_id),
                Path(output_dir),
            )
    except Exception as exc:
        print(f"[!] Schema-v2 export failed: {exc}", flush=True)

    print(
        f"[✓] Canonical metric CSVs exported to {output_dir} "
        "(% for rates, pp for gains, counts for totals, seconds for durations).",
        flush=True,
    )


base.export_metrics_csvs = export_metrics_csvs_fixed


if __name__ == "__main__":
    base.main()
