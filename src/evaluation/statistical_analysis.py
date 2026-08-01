"""Paired ablation contrasts and statistical inference."""

from __future__ import annotations

import math
import random
import statistics
from typing import Any

from evaluation.aggregate import invalid_keys
from evaluation.schema import FLOW_LAYOUT_VERSION


CONTRASTS = (
    ("F1_VS_F2_ERROR_CONTEXT", "F1", "F2"),
    ("F1_VS_F3_PSEUDOCODE", "F1", "F3"),
    ("F1_VS_F4_CLEAN_IR_DIRECT", "F1", "F4"),
    ("F3_VS_F5_DEOBFUSCATION", "F3", "F5"),
    ("F5_VS_F6_RAW_ERROR_CONTEXT", "F5", "F6"),
    ("F1_VS_F5_FULL_VS_RAW_MULTIFACTOR", "F1", "F5"),
)

LEGACY_CONTRASTS = (
    ("F2_VS_F4_PSEUDOCODE", "F2", "F4"),
    ("F2_VS_F1_CLEAN_IR", "F2", "F1"),
    ("F4_VS_F3_DEOBFUSCATION", "F4", "F3"),
    ("F2_VS_F5_ITERATIVE_FEEDBACK", "F2", "F5"),
    ("F2_VS_F3_FULL_VS_RAW_MULTIFACTOR", "F2", "F3"),
)

METRICS = (
    ("First-pass RSR", "compile_success_first", "binary", True),
    ("Final RSR", "any_compile_success_within_budget", "binary", True),
    ("Program Behavioral Pass Rate", "final_behavioral_pass", "binary", True),
    ("Initial Behavioral Pass Rate", "first_behavioral_pass", "binary", True),
    ("Final Behavioral Pass Rate", "final_behavioral_pass", "binary", True),
    ("Input Match Rate", "input_match_rate", "continuous", True),
    ("Counterexample Detection Rate", "reproducible_final_counterexample", "binary", False),
    ("Canonical E2E Rate", "canonical_e2e_success", "binary", True),
    ("Flow-specific Recovery Rate", "flow_specific_recovery_success", "binary", True),
    ("Compile Repair Rounds", "compile_repair_rounds", "continuous", False),
    ("Behavioral Repair Rounds", "behavioral_repair_rounds", "continuous", False),
    ("LLM Calls", "llm_calls", "continuous", False),
    ("Tokens", "total_tokens", "continuous", False),
    ("Runtime", "total_runtime", "continuous", False),
    ("Cost", "estimated_api_cost", "continuous", False),
    ("Readability", "readability_overall", "ordinal", True),
    ("SLOC Ratio", "sloc_ratio", "continuous", False),
)


def _bootstrap_difference(
    left: list[float], right: list[float], seed: int = 20260728
) -> tuple[float | None, float | None]:
    if not left:
        return None, None
    differences = [a - b for a, b in zip(left, right)]
    if len(differences) == 1:
        return differences[0], differences[0]
    rng = random.Random(seed)
    means = sorted(
        statistics.mean(rng.choices(differences, k=len(differences)))
        for _ in range(2000)
    )
    return means[50], means[1950]


def _mcnemar(left: list[float], right: list[float]) -> tuple[float | None, float | None]:
    from scipy.stats import binomtest

    a_only = sum(bool(a) and not bool(b) for a, b in zip(left, right))
    b_only = sum(not bool(a) and bool(b) for a, b in zip(left, right))
    discordant = a_only + b_only
    if discordant == 0:
        return 1.0, 0.0
    pvalue = float(binomtest(a_only, discordant, 0.5).pvalue)
    effect = (a_only - b_only) / discordant
    return pvalue, effect


def _wilcoxon(left: list[float], right: list[float]) -> tuple[float | None, float | None]:
    from scipy.stats import wilcoxon

    differences = [a - b for a, b in zip(left, right)]
    nonzero = [value for value in differences if value != 0]
    if not nonzero:
        return 1.0, 0.0
    try:
        result = wilcoxon(left, right, zero_method="wilcox")
        positive = sum(value > 0 for value in nonzero)
        negative = sum(value < 0 for value in nonzero)
        effect = (positive - negative) / len(nonzero)
        return float(result.pvalue), effect
    except ValueError:
        return None, None


def _holm(rows: list[dict[str, Any]]) -> None:
    eligible = [
        (index, row["raw_p_value"])
        for index, row in enumerate(rows)
        if row["raw_p_value"] is not None
    ]
    ordered = sorted(eligible, key=lambda item: item[1])
    running = 0.0
    total = len(ordered)
    for rank, (index, pvalue) in enumerate(ordered):
        adjusted = min(1.0, pvalue * (total - rank))
        running = max(running, adjusted)
        rows[index]["holm_adjusted_p_value"] = running


def paired_analysis(
    runs: list[dict[str, Any]], errors: list[dict[str, Any]]
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    invalid = invalid_keys(errors)
    lookup = {
        (run["sample_id"], run["repeat_id"], run["flow_id"]): run for run in runs
    }
    samples = sorted({(run["sample_id"], run["repeat_id"]) for run in runs})
    layout_versions = {
        run.get("flow_layout_version")
        for run in runs
        if run.get("flow_layout_version")
    }
    if len(layout_versions) > 1:
        raise ValueError(
            "Cannot aggregate multiple flow-layout versions in one experiment: "
            f"{sorted(layout_versions)}"
        )
    contrasts = (
        CONTRASTS
        if layout_versions == {FLOW_LAYOUT_VERSION} or not layout_versions
        else LEGACY_CONTRASTS
    )
    comparisons: list[dict[str, Any]] = []
    tests: list[dict[str, Any]] = []
    for contrast_id, flow_a, flow_b in contrasts:
        for metric_name, field, kind, higher_is_better in METRICS:
            left: list[float] = []
            right: list[float] = []
            exclusions: dict[str, int] = {}
            for sample_id, repeat_id in samples:
                a = lookup.get((sample_id, repeat_id, flow_a))
                b = lookup.get((sample_id, repeat_id, flow_b))
                if a is None or b is None:
                    exclusions["MISSING_PAIR"] = exclusions.get("MISSING_PAIR", 0) + 1
                    continue
                if (
                    (sample_id, flow_a, repeat_id) in invalid
                    or (sample_id, flow_b, repeat_id) in invalid
                ):
                    exclusions["DATA_VALIDATION_ERROR"] = exclusions.get(
                        "DATA_VALIDATION_ERROR", 0
                    ) + 1
                    continue
                value_a = a.get(field)
                value_b = b.get(field)
                if value_a is None or value_b is None:
                    exclusions["METRIC_UNDEFINED"] = exclusions.get(
                        "METRIC_UNDEFINED", 0
                    ) + 1
                    continue
                left.append(float(value_a))
                right.append(float(value_b))
            differences = [a - b for a, b in zip(left, right)]
            mean_a = statistics.mean(left) if left else None
            mean_b = statistics.mean(right) if right else None
            absolute = (
                mean_a - mean_b if mean_a is not None and mean_b is not None else None
            )
            relative = (
                absolute / abs(mean_b) * 100.0
                if absolute is not None and mean_b not in (None, 0)
                else None
            )
            wins = ties = losses = 0
            for a, b in zip(left, right):
                oriented = (a - b) if higher_is_better else (b - a)
                if math.isclose(oriented, 0.0, abs_tol=1e-12):
                    ties += 1
                elif oriented > 0:
                    wins += 1
                else:
                    losses += 1
            low, high = _bootstrap_difference(left, right)
            comparison = {
                "contrast_id": contrast_id,
                "flow_a": flow_a,
                "flow_b": flow_b,
                "metric_name": metric_name,
                "paired_sample_count": len(left),
                "excluded_sample_count": sum(exclusions.values()),
                "exclusion_reasons": "; ".join(
                    f"{key}={value}" for key, value in sorted(exclusions.items())
                ),
                "flow_a_value": mean_a,
                "flow_b_value": mean_b,
                "absolute_difference": absolute,
                "relative_difference_percent": relative,
                "ci_95_low": low,
                "ci_95_high": high,
                "flow_a_wins": wins,
                "ties": ties,
                "flow_b_wins": losses,
            }
            comparisons.append(comparison)
            if kind == "binary":
                pvalue, effect = _mcnemar(left, right) if left else (None, None)
                test_name = "McNemar exact test"
            else:
                pvalue, effect = _wilcoxon(left, right) if left else (None, None)
                test_name = "Wilcoxon signed-rank test"
            tests.append(
                {
                    **comparison,
                    "test_name": test_name,
                    "n": len(left),
                    "mean_difference": (
                        statistics.mean(differences) if differences else None
                    ),
                    "median_difference": (
                        statistics.median(differences) if differences else None
                    ),
                    "effect_size": effect,
                    "raw_p_value": pvalue,
                    "holm_adjusted_p_value": None,
                    "underpowered": len(left) < 20,
                }
            )
    _holm(tests)
    return comparisons, tests
