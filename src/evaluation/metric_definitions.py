"""Canonical metric formulas for the source-recovery experiment.

All rate functions return percentages in the closed interval [0, 100].
Gain functions return percentage points (pp), not percentages.
Undefined ratios return ``None`` instead of an artificial 0% or 100%.
"""

from __future__ import annotations

from typing import Optional


Percent = Optional[float]


def percentage(numerator: int | float, denominator: int | float) -> Percent:
    """Return ``numerator / denominator * 100`` in percent.

    ``None`` is returned when the denominator is zero because the metric is
    undefined for an empty evaluation population.
    """

    if denominator <= 0:
        return None
    return float(numerator) / float(denominator) * 100.0


def percentage_point_gain(after_pct: Percent, before_pct: Percent) -> Percent:
    """Return an absolute difference in percentage points (pp)."""

    if after_pct is None or before_pct is None:
        return None
    return float(after_pct) - float(before_pct)


def reduction_percentage(before: int | float, after: int | float) -> Percent:
    """Return ``(before - after) / before * 100`` in percent.

    A zero baseline has no meaningful reduction percentage and therefore
    returns ``None``.
    """

    if before <= 0:
        return None
    return (float(before) - float(after)) / float(before) * 100.0


def first_pass_rsr(initial_build_successes: int, initial_candidates: int) -> Percent:
    return percentage(initial_build_successes, initial_candidates)


def final_rsr_at_r(build_success_within_r: int, initial_candidates: int) -> Percent:
    return percentage(build_success_within_r, initial_candidates)


def compilation_repair_success_rate(
    repaired_initial_failures: int,
    initial_compile_failures: int,
) -> Percent:
    return percentage(repaired_initial_failures, initial_compile_failures)


def program_behavioral_pass_rate(
    behavioral_passes: int,
    completed_fuzz_campaigns: int,
) -> Percent:
    return percentage(behavioral_passes, completed_fuzz_campaigns)


def input_behavioral_match_rate(matches: int, confirmed_runs: int) -> Percent:
    """Return the input-level match rate over runs with a semantic verdict.

    Inconclusive runs are excluded from the denominator. At flow level this is
    the micro-averaged rate when counts are pooled across samples.
    """

    return percentage(matches, confirmed_runs)


def counterexample_detection_rate(
    candidates_with_counterexample: int,
    completed_fuzz_campaigns: int,
) -> Percent:
    return percentage(candidates_with_counterexample, completed_fuzz_campaigns)


def semantic_repair_success_rate(
    successfully_repaired_candidates: int,
    candidates_entering_behavioral_repair: int,
) -> Percent:
    return percentage(
        successfully_repaired_candidates,
        candidates_entering_behavioral_repair,
    )


def valid_input_rate(valid_inputs: int, generated_inputs: int) -> Percent:
    return percentage(valid_inputs, generated_inputs)


def counterexample_reproducibility_rate(
    reproduced_counterexamples: int,
    reported_counterexamples: int,
) -> Percent:
    return percentage(reproduced_counterexamples, reported_counterexamples)


def inconclusive_rate(inconclusive_samples: int, input_samples: int) -> Percent:
    return percentage(inconclusive_samples, input_samples)


def end_to_end_recovery_rate(successful_recoveries: int, input_samples: int) -> Percent:
    return percentage(successful_recoveries, input_samples)


def format_percent(value: Percent, digits: int = 2) -> str:
    return "N/A" if value is None else f"{value:.{digits}f}%"


def format_percentage_points(value: Percent, digits: int = 2) -> str:
    return "N/A" if value is None else f"{value:+.{digits}f} pp"
