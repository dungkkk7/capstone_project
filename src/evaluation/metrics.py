"""Metric formulas and aggregate helpers for the six-flow evaluation."""

from __future__ import annotations

import math
import statistics
from typing import Any, Iterable, Optional


Number = int | float


def rate(numerator: Number, denominator: Number) -> Optional[float]:
    if denominator <= 0:
        return None
    return float(numerator) / float(denominator) * 100.0


def gain(after: Optional[float], before: Optional[float]) -> Optional[float]:
    if after is None or before is None:
        return None
    return after - before


def reduction(before: Number, after: Number) -> Optional[float]:
    return None if before <= 0 else (float(before) - float(after)) / float(before) * 100.0


def first_pass_rsr(successes: int, candidates: int) -> Optional[float]:
    return rate(successes, candidates)


def final_rsr(successes: int, candidates: int) -> Optional[float]:
    return rate(successes, candidates)


def compilation_repair_success_rate(
    successful_cases: int, repair_cases: int
) -> Optional[float]:
    return rate(successful_cases, repair_cases)


def program_behavioral_pass_rate(
    passes: int, concluded_campaigns: int
) -> Optional[float]:
    return rate(passes, concluded_campaigns)


def input_match_rate(matches: int, valid: int) -> Optional[float]:
    return rate(matches, valid)


def counterexample_detection_rate(
    samples_with_reproducible_counterexample: int, completed_campaigns: int
) -> Optional[float]:
    return rate(samples_with_reproducible_counterexample, completed_campaigns)


def semantic_repair_success_rate(
    successful_cases: int, repair_cases: int
) -> Optional[float]:
    return rate(successful_cases, repair_cases)


def canonical_e2e_rate(successes: int, samples: int) -> Optional[float]:
    return rate(successes, samples)


def flow_specific_recovery_rate(successes: int, samples: int) -> Optional[float]:
    return rate(successes, samples)


def valid_input_rate(valid: int, generated: int) -> Optional[float]:
    return rate(valid, generated)


def executable_pair_execution_rate(executed: int, generated: int) -> Optional[float]:
    return rate(executed, generated)


def reproducibility_rate(reproduced: int, replayed: int) -> Optional[float]:
    return rate(reproduced, replayed)


def inconclusive_rate(inconclusive: int, samples: int) -> Optional[float]:
    return rate(inconclusive, samples)


def descriptive(values: Iterable[Number | None]) -> dict[str, Optional[float]]:
    clean = [float(value) for value in values if value is not None and math.isfinite(float(value))]
    if not clean:
        return {
            "n": 0,
            "mean": None,
            "median": None,
            "stddev": None,
            "min": None,
            "p25": None,
            "p75": None,
            "max": None,
        }
    ordered = sorted(clean)

    def percentile(p: float) -> float:
        if len(ordered) == 1:
            return ordered[0]
        position = (len(ordered) - 1) * p
        lower = math.floor(position)
        upper = math.ceil(position)
        if lower == upper:
            return ordered[lower]
        return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)

    return {
        "n": len(clean),
        "mean": statistics.mean(clean),
        "median": statistics.median(clean),
        "stddev": statistics.stdev(clean) if len(clean) > 1 else 0.0,
        "min": min(clean),
        "p25": percentile(0.25),
        "p75": percentile(0.75),
        "max": max(clean),
    }


def bootstrap_ci(
    values: Iterable[Number | None],
    *,
    seed: int = 20260728,
    iterations: int = 2000,
) -> tuple[Optional[float], Optional[float]]:
    import random

    clean = [float(value) for value in values if value is not None and math.isfinite(float(value))]
    if not clean:
        return None, None
    if len(clean) == 1:
        return clean[0], clean[0]
    rng = random.Random(seed)
    means = sorted(
        statistics.mean(rng.choices(clean, k=len(clean))) for _ in range(iterations)
    )
    return means[int(0.025 * iterations)], means[min(iterations - 1, int(0.975 * iterations))]


def format_ratio(numerator: int, denominator: int, percentage: Optional[float]) -> str:
    return "N/A" if percentage is None else f"{numerator}/{denominator} ({percentage:.1f}%)"
