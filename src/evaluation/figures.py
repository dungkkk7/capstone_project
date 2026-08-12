"""Publication-ready figures generated exclusively from evaluation tables."""

from __future__ import annotations

import math
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from evaluation.schema import FLOW_ORDER


COLORS = (
    "#0072B2",
    "#E69F00",
    "#009E73",
    "#CC79A7",
    "#56B4E9",
    "#D55E00",
)
HATCHES = ("///", "\\\\\\", "xx", "..", "++", "oo")
PERCENT_AXIS_MAX = 106.0


def _style() -> None:
    plt.rcParams.update(
        {
            "font.size": 10,
            "axes.titlesize": 11,
            "axes.labelsize": 10,
            "legend.fontsize": 9,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "figure.dpi": 120,
            "savefig.dpi": 300,
            "axes.spines.top": False,
            "axes.spines.right": False,
        }
    )


def _save(fig: plt.Figure, directory: Path, name: str) -> None:
    fig.tight_layout()
    for extension in ("png", "svg", "pdf"):
        fig.savefig(directory / f"{name}.{extension}", bbox_inches="tight")
    plt.close(fig)


def _flow_lookup(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {row["flow_id"]: row for row in rows}


def _values(
    lookup: dict[str, dict[str, Any]], field: str
) -> list[float]:
    return [
        float(lookup.get(flow, {}).get(field))
        if lookup.get(flow, {}).get(field) is not None
        else np.nan
        for flow in FLOW_ORDER
    ]


def _flow_tick_labels(lookup: dict[str, dict[str, Any]]) -> list[str]:
    return [
        f"{flow}\nn={lookup.get(flow, {}).get('eligible_sample_count', 0)}"
        for flow in FLOW_ORDER
    ]


def _legend_above(
    ax: plt.Axes,
    *,
    columns: int,
    anchor_y: float = 1.02,
) -> None:
    ax.legend(
        ncol=columns,
        loc="lower center",
        bbox_to_anchor=(0.5, anchor_y),
        borderaxespad=0,
        frameon=True,
    )


def _single_metric_bars(
    ax: plt.Axes,
    lookup: dict[str, dict[str, Any]],
    field: str,
    *,
    color_index: int,
    ylabel: str,
    title: str,
    percent: bool = False,
) -> None:
    values = _values(lookup, field)
    x = np.arange(len(FLOW_ORDER))
    bars = ax.bar(
        x,
        np.nan_to_num(values, nan=0.0),
        color=COLORS[color_index % len(COLORS)],
        edgecolor="black",
        linewidth=0.5,
        hatch=HATCHES[color_index % len(HATCHES)],
    )
    for bar, value in zip(bars, values):
        if math.isnan(value):
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                0.03,
                "N/A",
                ha="center",
                va="bottom",
                rotation=90,
                fontsize=8,
                transform=ax.get_xaxis_transform(),
            )
    ax.set_xticks(x, _flow_tick_labels(lookup))
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    if percent:
        ax.set_ylim(0, PERCENT_AXIS_MAX)
    ax.grid(axis="y", alpha=0.25)


def _grouped_bars(
    name: str,
    fields: list[tuple[str, str]],
    lookup: dict[str, dict[str, Any]],
    directory: Path,
    *,
    percent: bool = True,
    confidence_intervals: dict[str, tuple[str, str]] | None = None,
) -> None:
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    x = np.arange(len(FLOW_ORDER))
    width = 0.8 / max(1, len(fields))
    for index, (label, field) in enumerate(fields):
        values = _values(lookup, field)
        yerr = None
        if confidence_intervals and field in confidence_intervals:
            low_field, high_field = confidence_intervals[field]
            lows = _values(lookup, low_field)
            highs = _values(lookup, high_field)
            yerr = np.array(
                [
                    [
                        max(0.0, value - low)
                        if not math.isnan(value) and not math.isnan(low)
                        else 0.0
                        for value, low in zip(values, lows)
                    ],
                    [
                        max(0.0, high - value)
                        if not math.isnan(value) and not math.isnan(high)
                        else 0.0
                        for value, high in zip(values, highs)
                    ],
                ]
            )
        bars = ax.bar(
            x - 0.4 + width / 2 + index * width,
            np.nan_to_num(values, nan=0.0),
            width,
            label=label,
            color=COLORS[index % len(COLORS)],
            edgecolor="black",
            linewidth=0.5,
            hatch=HATCHES[index % len(HATCHES)],
            yerr=yerr,
            capsize=2 if yerr is not None else 0,
        )
        for bar, value in zip(bars, values):
            if math.isnan(value):
                ax.text(
                    bar.get_x() + bar.get_width() / 2,
                    2 if percent else 0.05,
                    "N/A",
                    ha="center",
                    va="bottom",
                    rotation=90,
                    fontsize=8,
                )
    ax.set_xticks(x, _flow_tick_labels(lookup))
    ax.set_ylabel("Rate (%)" if percent else "Value")
    if percent:
        ax.set_ylim(0, PERCENT_AXIS_MAX)
    ax.grid(axis="y", alpha=0.25)
    _legend_above(ax, columns=min(3, len(fields)))
    _save(fig, directory, name)


def generate_figures(
    directory: Path,
    runs: list[dict[str, Any]],
    flow_rows: list[dict[str, Any]],
    stage_rows: list[dict[str, Any]],
    failure_rows: list[dict[str, Any]],
    comparisons: list[dict[str, Any]],
    llvm_rows: list[dict[str, Any]],
    compile_attempts: list[dict[str, Any]],
    campaigns: list[dict[str, Any]],
) -> list[dict[str, str]]:
    _style()
    directory.mkdir(parents=True, exist_ok=True)
    lookup = _flow_lookup(flow_rows)
    manifest: list[dict[str, str]] = []

    _grouped_bars(
        "overall_performance",
        [
            ("First-pass RSR", "first_pass_rsr_percent"),
            ("Behavioral pass", "program_behavioral_pass_rate_percent"),
            ("Re-executability", "re_executability_rate_percent"),
        ],
        lookup,
        directory,
        confidence_intervals={
            "first_pass_rsr_percent": (
                "first_pass_rsr_ci_low",
                "first_pass_rsr_ci_high",
            ),
            "program_behavioral_pass_rate_percent": (
                "program_behavioral_pass_rate_ci_low",
                "program_behavioral_pass_rate_ci_high",
            ),
            "re_executability_rate_percent": (
                "re_executability_ci_low",
                "re_executability_ci_high",
            ),
        },
    )
    manifest.append({"figure_id": "overall_performance", "caption": "Primary recovery outcomes with executable availability over all eligible samples; F6 is derived from F5's first provider call."})

    fig, axes = plt.subplots(1, 3, figsize=(11.5, 4.2))
    x = np.arange(len(FLOW_ORDER))
    width = 0.36
    for index, (label, field) in enumerate(
        (
            ("First-pass RSR", "first_pass_rsr_percent"),
            ("Final RSR@R", "final_rsr_percent"),
        )
    ):
        axes[0].bar(
            x + (index - 0.5) * width,
            np.nan_to_num(_values(lookup, field), nan=0.0),
            width,
            label=label,
            color=COLORS[index],
            edgecolor="black",
            linewidth=0.5,
            hatch=HATCHES[index],
        )
    axes[0].set_xticks(x, _flow_tick_labels(lookup))
    axes[0].set(
        ylabel="Rate (%)",
        title="Compilation success",
        ylim=(0, PERCENT_AXIS_MAX),
    )
    axes[0].grid(axis="y", alpha=0.25)
    _legend_above(axes[0], columns=2, anchor_y=1.14)
    _single_metric_bars(
        axes[1],
        lookup,
        "compilation_repair_gain_pp",
        color_index=2,
        ylabel="Percentage points",
        title="Compilation repair gain",
    )
    _single_metric_bars(
        axes[2],
        lookup,
        "compile_repair_rounds_mean",
        color_index=3,
        ylabel="Rounds",
        title="Mean repair effort",
    )
    _save(fig, directory, "compilation_performance")
    manifest.append({"figure_id": "compilation_performance", "caption": "Compilation success before and after repair."})

    _grouped_bars(
        "behavioral_performance",
        [
            ("Initial pass", "initial_behavioral_pass_rate_percent"),
            ("Final pass", "final_behavioral_pass_rate_percent"),
            ("Input match macro", "input_match_macro_percent"),
            ("Counterexample detection", "counterexample_detection_rate_percent"),
        ],
        lookup,
        directory,
    )
    manifest.append({"figure_id": "behavioral_performance", "caption": "Behavioral outcomes over conclusive campaigns."})

    fig, axes = plt.subplots(1, 3, figsize=(11.5, 4.2))
    x = np.arange(len(FLOW_ORDER))
    width = 0.36
    for index, (label, field) in enumerate(
        (
            ("Before repair", "initial_behavioral_pass_rate_percent"),
            ("After repair", "final_behavioral_pass_rate_percent"),
        )
    ):
        axes[0].bar(
            x + (index - 0.5) * width,
            np.nan_to_num(_values(lookup, field), nan=0.0),
            width,
            label=label,
            color=COLORS[index],
            edgecolor="black",
            linewidth=0.5,
            hatch=HATCHES[index],
        )
    axes[0].set_xticks(x, _flow_tick_labels(lookup))
    axes[0].set(
        ylabel="Rate (%)",
        title="Before vs after repair",
        ylim=(0, PERCENT_AXIS_MAX),
    )
    axes[0].grid(axis="y", alpha=0.25)
    _legend_above(axes[0], columns=2, anchor_y=1.14)
    _single_metric_bars(
        axes[1],
        lookup,
        "semantic_repair_success_rate_percent",
        color_index=2,
        ylabel="Rate (%)",
        title="Semantic repair success",
        percent=True,
    )
    _single_metric_bars(
        axes[2],
        lookup,
        "behavioral_repair_gain_pp",
        color_index=3,
        ylabel="Percentage points",
        title="Behavioral repair gain",
    )
    _save(fig, directory, "repair_effectiveness")
    one_shot_flows = [
        flow
        for flow in FLOW_ORDER
        if lookup.get(flow, {}).get("error_context_enabled") is False
    ]
    one_shot_label = ", ".join(one_shot_flows) or "the one-shot flow"
    manifest.append(
        {
            "figure_id": "repair_effectiveness",
            "caption": (
                "Behavioral repair effectiveness; "
                f"{one_shot_label} repair fields are N/A."
            ),
        }
    )

    # Direct matched-evidence view for the iterative-feedback ablation. This
    # uses the common all-eligible re-executability denominator instead of mixing
    # behavioral-campaign counts or conditional pass rates.
    feedback_pairs = (
        ("Clean IR + LLVM2C", "F2", "F1"),
        ("Raw IR", "F6", "F5"),
    )
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    y_positions = np.arange(len(feedback_pairs))[::-1]
    for y_position, (evidence, one_shot_flow, iterative_flow) in zip(
        y_positions, feedback_pairs
    ):
        one_shot = lookup[one_shot_flow]
        iterative = lookup[iterative_flow]
        one_shot_rate = float(one_shot["re_executability_rate_percent"])
        iterative_rate = float(iterative["re_executability_rate_percent"])
        one_shot_count = int(one_shot["re_executability_success_count"])
        iterative_count = int(iterative["re_executability_success_count"])
        denominator = int(iterative["eligible_sample_count"])
        gain = iterative_rate - one_shot_rate

        ax.annotate(
            "",
            xy=(iterative_rate, y_position),
            xytext=(one_shot_rate, y_position),
            arrowprops={
                "arrowstyle": "-|>",
                "color": "#666666",
                "linewidth": 2.5,
                "mutation_scale": 16,
            },
            zorder=1,
        )
        ax.scatter(
            one_shot_rate,
            y_position,
            s=150,
            marker="o",
            color=COLORS[1],
            edgecolor="black",
            linewidth=0.7,
            zorder=3,
        )
        ax.scatter(
            iterative_rate,
            y_position,
            s=165,
            marker="D",
            color=COLORS[0],
            edgecolor="black",
            linewidth=0.7,
            zorder=3,
        )
        ax.text(
            one_shot_rate,
            y_position - 0.18,
            f"{one_shot_flow} one-shot\n{one_shot_count}/{denominator} · "
            f"{one_shot_rate:.1f}%",
            ha="center",
            va="top",
            fontsize=9,
            color="#9A6700",
        )
        ax.text(
            iterative_rate,
            y_position - 0.18,
            f"{iterative_flow} iterative\n{iterative_count}/{denominator} · "
            f"{iterative_rate:.1f}%",
            ha="center",
            va="top",
            fontsize=9,
            color="#005A8D",
            fontweight="bold",
        )
        ax.text(
            (one_shot_rate + iterative_rate) / 2,
            y_position + 0.14,
            f"+{gain:.1f} pp",
            ha="center",
            va="bottom",
            fontsize=10,
            fontweight="bold",
            color="#007A5E",
            bbox={"facecolor": "white", "edgecolor": "none", "pad": 1.5},
        )

    ax.set_yticks(y_positions, [pair[0] for pair in feedback_pairs])
    ax.set_xlim(0, 103)
    ax.set_ylim(-0.52, 1.52)
    ax.set_xticks(np.arange(0, 101, 20))
    ax.set_xlabel("Re-executability (% of eligible cases)")
    ax.set_title("Effect of iterative feedback", fontweight="bold")
    ax.grid(axis="x", alpha=0.25)
    ax.tick_params(axis="y", length=0, pad=10)
    _save(fig, directory, "iterative_feedback_vs_one_shot")
    manifest.append(
        {
            "figure_id": "iterative_feedback_vs_one_shot",
            "caption": (
                "Matched-evidence re-executability comparison of iterative "
                "feedback against one-shot reconstruction."
            ),
        }
    )

    # Exact cumulative compile success from attempt records.
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    for index, flow in enumerate(FLOW_ORDER):
        flow_runs = [run for run in runs if run["flow_id"] == flow]
        by_run: dict[str, list[dict[str, Any]]] = {}
        for attempt in compile_attempts:
            if attempt["flow_id"] == flow:
                by_run.setdefault(attempt["run_id"], []).append(attempt)
        max_round = max((len(value) for value in by_run.values()), default=1)
        rounds = list(range(1, max_round + 1))
        cumulative = [
            100.0
            * sum(
                any(item["compile_success"] for item in by_run.get(run["run_id"], [])[:round_index])
                for run in flow_runs
            )
            / len(flow_runs)
            if flow_runs
            else 0.0
            for round_index in rounds
        ]
        ax.plot(rounds, cumulative, marker="o", color=COLORS[index], label=f"{flow} (n={len(flow_runs)})")
    ax.set(
        xlabel="Compile attempt",
        ylabel="Cumulative success (%)",
        ylim=(0, PERCENT_AXIS_MAX),
    )
    ax.grid(alpha=0.25)
    _legend_above(ax, columns=3)
    _save(fig, directory, "cumulative_compile_success_by_round")
    manifest.append({"figure_id": "cumulative_compile_success_by_round", "caption": "Cumulative executable creation by compile attempt."})

    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    for index, flow in enumerate(FLOW_ORDER):
        flow_runs = [run for run in runs if run["flow_id"] == flow]
        by_run: dict[str, list[dict[str, Any]]] = {}
        for campaign in campaigns:
            if campaign["flow_id"] == flow:
                by_run.setdefault(campaign["run_id"], []).append(campaign)
        max_round = max((len(value) for value in by_run.values()), default=1)
        rounds = list(range(1, max_round + 1))
        cumulative = []
        for round_index in rounds:
            successes = 0
            for run in flow_runs:
                observed = by_run.get(run["run_id"], [])[:round_index]
                successes += any(
                    item.get(
                        "fuzzing_completed",
                        item.get("is_fully_equivalent", False),
                    )
                    and item.get("fuzz_mismatches", 0) == 0
                    for item in observed
                )
            cumulative.append(100.0 * successes / len(flow_runs) if flow_runs else 0)
        ax.plot(rounds, cumulative, marker="s", color=COLORS[index], label=f"{flow} (n={len(flow_runs)})")
    ax.set(
        xlabel="Behavioral campaign",
        ylabel="Cumulative behavioral pass (%)",
        ylim=(0, PERCENT_AXIS_MAX),
    )
    ax.grid(alpha=0.25)
    _legend_above(ax, columns=3)
    _save(fig, directory, "cumulative_behavioral_success_by_round")
    manifest.append({"figure_id": "cumulative_behavioral_success_by_round", "caption": "Cumulative behavioral pass by campaign."})

    statuses = [
        "PASS",
        "FAIL_GENERATION",
        "FAIL_COMPILE",
        "FAIL_BEHAVIORAL",
        "INCONCLUSIVE",
        "CANCELLED",
    ]
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    bottom = np.zeros(len(FLOW_ORDER))
    for index, status in enumerate(statuses):
        values = np.array(
            [sum(run["flow_id"] == flow and run["status"] == status for run in runs) for flow in FLOW_ORDER]
        )
        ax.bar(FLOW_ORDER, values, bottom=bottom, label=status, color=COLORS[index], edgecolor="black", linewidth=0.4, hatch=HATCHES[index])
        bottom += values
    ax.set_ylabel("Samples")
    _legend_above(ax, columns=3)
    _save(fig, directory, "final_status_breakdown")
    manifest.append({"figure_id": "final_status_breakdown", "caption": "Final status distribution without collapsing INCONCLUSIVE into failure."})

    fig, axes = plt.subplots(1, 3, figsize=(11, 4.2))
    taxonomies = ("COMPILE_FAILURE", "BEHAVIORAL_DIVERGENCE", "INCONCLUSIVE")
    for ax, taxonomy in zip(axes, taxonomies):
        subset = [row for row in failure_rows if row["taxonomy"] == taxonomy]
        counts: dict[str, int] = {}
        for row in subset:
            counts[row["category"]] = counts.get(row["category"], 0) + int(row["count"])
        labels = list(counts) or ["N/A"]
        values = list(counts.values()) or [0]
        ax.barh(labels, values, color=COLORS[: len(labels)] if len(labels) <= 5 else COLORS[0])
        ax.set_title(taxonomy.replace("_", " ").title())
        ax.set_xlabel("Samples/events")
    _save(fig, directory, "failure_taxonomy")
    manifest.append({"figure_id": "failure_taxonomy", "caption": "Compilation, behavioral, and inconclusive taxonomies."})

    sample_ids = sorted({run["sample_id"] for run in runs})
    status_value = {
        "PASS": 2,
        "INCONCLUSIVE": 1,
        "CANCELLED": 1,
        "FAIL_GENERATION": 0,
        "FAIL_COMPILE": 0,
        "FAIL_BEHAVIORAL": 0,
    }
    status_matrix = np.full((len(sample_ids), len(FLOW_ORDER)), np.nan)
    match_matrix = np.full_like(status_matrix, np.nan)
    lookup_run = {(run["sample_id"], run["flow_id"]): run for run in runs}
    for row_index, sample in enumerate(sample_ids):
        for column_index, flow in enumerate(FLOW_ORDER):
            run = lookup_run.get((sample, flow))
            if run:
                status_matrix[row_index, column_index] = status_value.get(run["status"], np.nan)
                if run["input_match_rate"] is not None:
                    match_matrix[row_index, column_index] = run["input_match_rate"]
    for name, matrix, cmap, vmin, vmax, label in (
        ("sample_flow_status_heatmap", status_matrix, "viridis", 0, 2, "0=fail, 1=unresolved, 2=pass"),
        ("sample_flow_match_heatmap", match_matrix, "cividis", 0, 100, "Input match (%)"),
    ):
        fig, ax = plt.subplots(figsize=(7.2, max(5, len(sample_ids) * 0.18)))
        image = ax.imshow(matrix, aspect="auto", cmap=cmap, vmin=vmin, vmax=vmax)
        ax.set_xticks(range(len(FLOW_ORDER)), FLOW_ORDER)
        ax.set_yticks(range(len(sample_ids)), sample_ids, fontsize=7)
        fig.colorbar(image, ax=ax, label=label)
        _save(fig, directory, name)
        manifest.append({"figure_id": name, "caption": label + " by paired sample and flow."})

    forest = [
        row
        for row in comparisons
        if row["metric_name"] == "Re-executability Rate"
        and row["absolute_difference"] is not None
    ]
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    positions = np.arange(len(forest))
    effects = [row["absolute_difference"] * 100.0 for row in forest]
    lows = [row["ci_95_low"] * 100.0 for row in forest]
    highs = [row["ci_95_high"] * 100.0 for row in forest]
    ax.errorbar(
        effects,
        positions,
        xerr=[
            [effect - low for effect, low in zip(effects, lows)],
            [high - effect for effect, high in zip(effects, highs)],
        ],
        fmt="o",
        color=COLORS[0],
        capsize=3,
    )
    ax.axvline(0, color="black", linewidth=0.8)
    ax.set_yticks(positions, [row["contrast_id"] for row in forest], fontsize=8)
    ax.set_xlabel("Paired effect (percentage points)")
    _save(fig, directory, "ablation_forest_plot")
    manifest.append({"figure_id": "ablation_forest_plot", "caption": "Paired re-executability effects with bootstrap 95% CI."})

    wtl = [
        row for row in comparisons if row["metric_name"] == "Re-executability Rate"
    ]
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    y = np.arange(len(wtl))
    left = np.zeros(len(wtl))
    for field, label, color, hatch in (
        ("flow_a_wins", "Flow A wins", COLORS[2], HATCHES[0]),
        ("ties", "Ties", "#999999", HATCHES[1]),
        ("flow_b_wins", "Flow B wins", COLORS[3], HATCHES[2]),
    ):
        values = np.array([row[field] for row in wtl])
        ax.barh(y, values, left=left, label=label, color=color, edgecolor="black", hatch=hatch)
        left += values
    ax.set_yticks(y, [row["contrast_id"] for row in wtl], fontsize=8)
    ax.set_xlabel("Paired samples")
    _legend_above(ax, columns=3)
    _save(fig, directory, "ablation_win_tie_loss")
    manifest.append({"figure_id": "ablation_win_tie_loss", "caption": "Paired win/tie/loss counts for re-executability."})

    for name, x_field, y_field, x_label, y_label in (
        ("tokens_vs_e2e", "total_tokens", "re_executability_success", "Total tokens", "Re-executability outcome"),
        ("runtime_vs_behavioral_pass", "total_runtime", "final_behavioral_pass", "Runtime (seconds)", "Behavioral pass outcome"),
    ):
        fig, ax = plt.subplots(figsize=(7.2, 4.2))
        for index, flow in enumerate(FLOW_ORDER):
            subset = [
                run for run in runs
                if run["flow_id"] == flow and run.get(x_field) is not None and run.get(y_field) is not None
            ]
            ax.scatter(
                [run[x_field] for run in subset],
                [float(run[y_field]) + (index - 2) * 0.015 for run in subset],
                label=f"{flow} (n={len(subset)})",
                color=COLORS[index],
                marker=("o", "s", "^", "D", "P", "X")[index],
                alpha=0.7,
            )
        ax.set_xlabel(x_label)
        ax.set_ylabel(y_label)
        ax.set_yticks([0, 1], ["No", "Yes"])
        _legend_above(ax, columns=3)
        ax.grid(alpha=0.2)
        _save(fig, directory, name)
        manifest.append({"figure_id": name, "caption": f"{x_label} versus {y_label}."})

    reductions = [
        ("Instructions", "instruction_reduction_percent"),
        ("Basic blocks", "basic_block_reduction_percent"),
        ("Conditional branches", "conditional_branch_reduction_percent"),
    ]
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    means = [
        np.nanmean([row[field] for row in llvm_rows if row[field] is not None])
        for _, field in reductions
    ]
    ax.bar([label for label, _ in reductions], means, color=COLORS[:3], edgecolor="black", hatch=HATCHES[:3])
    ax.set_ylabel("Mean reduction (%)")
    ax.set_ylim(min(0, min(means) - 5), max(PERCENT_AXIS_MAX, max(means) + 5))
    ax.grid(axis="y", alpha=0.25)
    _save(fig, directory, "llvm_reduction_summary")
    manifest.append({"figure_id": "llvm_reduction_summary", "caption": "LLVM simplification metrics; these are not correctness claims."})

    behavior_by_sample = {
        sample: np.mean(
            [float(run["final_behavioral_pass"]) for run in runs if run["sample_id"] == sample and run["final_behavioral_pass"] is not None]
        )
        for sample in sample_ids
        if any(run["sample_id"] == sample and run["final_behavioral_pass"] is not None for run in runs)
    }
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    points = [
        (row["instruction_reduction_percent"], behavior_by_sample[row["sample_id"]])
        for row in llvm_rows
        if row["instruction_reduction_percent"] is not None and row["sample_id"] in behavior_by_sample
    ]
    if points:
        ax.scatter([point[0] for point in points], [point[1] * 100 for point in points], color=COLORS[0], alpha=0.75)
    ax.set(
        xlabel="Instruction reduction (%)",
        ylabel="Behavioral pass share across flows (%)",
        ylim=(0, PERCENT_AXIS_MAX),
    )
    ax.grid(alpha=0.25)
    _save(fig, directory, "llvm_reduction_vs_behavior")
    manifest.append({"figure_id": "llvm_reduction_vs_behavior", "caption": "Association view only; LLVM reduction is not a semantic oracle."})

    fig, ax = plt.subplots(figsize=(7.2, 5.2))
    stage_names = []
    stage_values = []
    for stage in dict.fromkeys(row["stage"] for row in stage_rows):
        subset = [row for row in stage_rows if row["stage"] == stage]
        numerator = sum(row["numerator"] for row in subset)
        denominator = sum(row["denominator"] for row in subset)
        stage_names.append(stage.replace("_", " ").title())
        stage_values.append(100.0 * numerator / denominator if denominator else np.nan)
    positions = np.arange(len(stage_names))
    ax.barh(positions, stage_values, color=COLORS[0], edgecolor="black", hatch=HATCHES[0])
    ax.set_yticks(positions, stage_names)
    ax.invert_yaxis()
    ax.set(xlabel="Completion rate (%)", xlim=(0, PERCENT_AXIS_MAX))
    ax.grid(axis="x", alpha=0.25)
    _save(fig, directory, "stage_completion_funnel")
    manifest.append({"figure_id": "stage_completion_funnel", "caption": "Stage completion rates with explicit numerators and denominators in the report."})

    return manifest
