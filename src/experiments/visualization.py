from __future__ import annotations

import html
import math
from pathlib import Path
from typing import Any, Dict

from .storage import atomic_write_json, atomic_write_text, sha256_file


METHOD_ORDER = ("P0", "A0", "B0")
METHOD_COLORS = {
    "P0": "#24324A",
    "A0": "#B4533C",
    "B0": "#287271",
}
METHOD_LINE_STYLES = {
    "P0": {"dash": "", "width": 5, "marker_radius": 9},
    "A0": {"dash": "16 9", "width": 4, "marker_radius": 6.5},
    "B0": {"dash": "3 8", "width": 3, "marker_radius": 4},
}
INK = "#172033"
MUTED = "#5F6877"
GRID = "#D9DDE4"
PAPER = "#FAF9F6"


def _escape(value: Any) -> str:
    return html.escape(str(value), quote=True)


def _methods(summary: Dict[str, Any]) -> list[str]:
    ordered = [method for method in METHOD_ORDER if method in summary]
    return ordered + sorted(set(summary) - set(ordered))


def _fmt_number(value: float | int | None, digits: int = 1) -> str:
    if value is None:
        return "N/A"
    number = float(value)
    if abs(number) >= 1_000_000:
        return f"{number / 1_000_000:.1f}M"
    if abs(number) >= 1_000:
        return f"{number / 1_000:.1f}k"
    if number.is_integer():
        return str(int(number))
    return f"{number:.{digits}f}"


def _svg_document(
    width: int,
    height: int,
    title: str,
    description: str,
    body: str,
) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">
  <title id="title">{_escape(title)}</title>
  <desc id="desc">{_escape(description)}</desc>
  <style>
    .title {{ font: 700 28px Georgia, serif; fill: {INK}; }}
    .subtitle {{ font: 14px "Liberation Sans", sans-serif; fill: {MUTED}; }}
    .label {{ font: 13px "Liberation Sans", sans-serif; fill: {INK}; }}
    .small {{ font: 12px "Liberation Sans", sans-serif; fill: {MUTED}; }}
    .value {{ font: 700 14px "Liberation Sans", sans-serif; fill: {INK}; }}
    .axis {{ stroke: {GRID}; stroke-width: 1; shape-rendering: crispEdges; }}
    .zero {{ stroke: {INK}; stroke-width: 1.5; }}
  </style>
  <rect width="{width}" height="{height}" fill="{PAPER}"/>
  <text class="title" x="56" y="52">{_escape(title)}</text>
  <text class="subtitle" x="56" y="80">{_escape(description)}</text>
  {body}
</svg>
"""


def _write_figure(
    path: Path,
    *,
    title: str,
    description: str,
    svg: str,
    source: str,
) -> Dict[str, Any]:
    atomic_write_text(path, svg)
    return {
        "id": path.stem,
        "title": title,
        "description": description,
        "path": path.name,
        "source": source,
        "sha256": sha256_file(path),
    }


def _e2e_figure(
    figures_dir: Path, summary: Dict[str, Any]
) -> Dict[str, Any]:
    title = "End-to-end behavioral success"
    description = (
        "Unconditional PASS rate against the original obfuscated ELF; "
        "whiskers are Wilson confidence intervals."
    )
    width, height = 900, 540
    left, right, top, bottom = 100, 52, 120, 92
    chart_h = height - top - bottom
    chart_w = width - left - right
    elements = []
    for tick in range(0, 101, 20):
        y = top + chart_h * (1 - tick / 100)
        elements.append(
            f'<line class="axis" x1="{left}" y1="{y:.1f}" '
            f'x2="{left + chart_w}" y2="{y:.1f}"/>'
        )
        elements.append(
            f'<text class="small" x="{left - 14}" y="{y + 4:.1f}" '
            f'text-anchor="end">{tick}%</text>'
        )
    methods = _methods(summary)
    slot = chart_w / max(1, len(methods))
    bar_width = min(120, slot * 0.48)
    for index, method in enumerate(methods):
        item = summary[method]
        rate = float(item["e2e_rate"])
        x = left + slot * (index + 0.5)
        y = top + chart_h * (1 - rate)
        h = chart_h * rate
        color = METHOD_COLORS.get(method, "#6B7280")
        elements.append(
            f'<rect x="{x - bar_width / 2:.1f}" y="{y:.1f}" '
            f'width="{bar_width:.1f}" height="{h:.1f}" fill="{color}"/>'
        )
        ci = item.get("e2e_rate_wilson_ci")
        if ci:
            low_y = top + chart_h * (1 - float(ci[0]))
            high_y = top + chart_h * (1 - float(ci[1]))
            elements.extend(
                [
                    f'<line class="zero" x1="{x:.1f}" y1="{high_y:.1f}" '
                    f'x2="{x:.1f}" y2="{low_y:.1f}"/>',
                    f'<line class="zero" x1="{x - 10:.1f}" y1="{high_y:.1f}" '
                    f'x2="{x + 10:.1f}" y2="{high_y:.1f}"/>',
                    f'<line class="zero" x1="{x - 10:.1f}" y1="{low_y:.1f}" '
                    f'x2="{x + 10:.1f}" y2="{low_y:.1f}"/>',
                ]
            )
        value_y = max(top + 14, y - 12)
        elements.append(
            f'<text class="value" x="{x:.1f}" y="{value_y:.1f}" '
            f'text-anchor="middle">{rate * 100:.1f}%</text>'
        )
        elements.append(
            f'<text class="value" x="{x:.1f}" y="{top + chart_h + 30}" '
            f'text-anchor="middle">{_escape(method)}</text>'
        )
        elements.append(
            f'<text class="small" x="{x:.1f}" y="{top + chart_h + 50}" '
            f'text-anchor="middle">n={item["enrolled"]}; '
            f'PASS={item["pass"]}</text>'
        )
    svg = _svg_document(width, height, title, description, "\n".join(elements))
    return _write_figure(
        figures_dir / "fig01_e2e_success.svg",
        title=title,
        description=description,
        svg=svg,
        source="aggregate/method_summary.json",
    )


def _funnel_figure(
    figures_dir: Path, summary: Dict[str, Any]
) -> Dict[str, Any]:
    title = "Unconditional stage retention"
    description = (
        "Share of all enrolled programs retained at each end-to-end stage."
    )
    width, height = 1080, 560
    left, right, top, bottom = 92, 46, 122, 108
    chart_h = height - top - bottom
    chart_w = width - left - right
    stages = [
        ("Representation", "representation_success_unconditional"),
        ("Context fit", "context_fit_unconditional"),
        ("Generated", "generation_unconditional"),
        ("Built", "build_success_unconditional"),
        ("Runnable", "runnable_unconditional"),
        ("PASS", "e2e_rate"),
    ]
    elements = []
    for tick in range(0, 101, 20):
        y = top + chart_h * (1 - tick / 100)
        elements.append(
            f'<line class="axis" x1="{left}" y1="{y:.1f}" '
            f'x2="{left + chart_w}" y2="{y:.1f}"/>'
        )
        elements.append(
            f'<text class="small" x="{left - 12}" y="{y + 4:.1f}" '
            f'text-anchor="end">{tick}%</text>'
        )
    x_positions = [
        left + chart_w * index / (len(stages) - 1)
        for index in range(len(stages))
    ]
    for x, (label, _) in zip(x_positions, stages):
        elements.append(
            f'<text class="small" x="{x:.1f}" y="{top + chart_h + 32}" '
            f'text-anchor="middle">{_escape(label)}</text>'
        )
    series_lines = []
    series_markers = []
    for method in _methods(summary):
        color = METHOD_COLORS.get(method, "#6B7280")
        style = METHOD_LINE_STYLES.get(
            method, {"dash": "", "width": 3, "marker_radius": 5.5}
        )
        dash = (
            f' stroke-dasharray="{style["dash"]}"'
            if style["dash"]
            else ""
        )
        points = []
        for x, (_, metric) in zip(x_positions, stages):
            value = float(summary[method][metric])
            y = top + chart_h * (1 - value)
            points.append(f"{x:.1f},{y:.1f}")
            series_markers.append(
                f'<circle cx="{x:.1f}" cy="{y:.1f}" '
                f'r="{style["marker_radius"]}" fill="{PAPER}" '
                f'stroke="{color}" stroke-width="3"/>'
            )
        series_lines.append(
            f'<polyline points="{" ".join(points)}" fill="none" '
            f'stroke="{color}" stroke-width="{style["width"]}"{dash} '
            'stroke-linecap="round" stroke-linejoin="round"/>'
        )
    # Draw a thick solid P0 line first, then progressively narrower dashed
    # comparators.  Concentric marker radii keep coincident series visible
    # instead of allowing the final series to hide the other methods.
    elements.extend(series_lines)
    elements.extend(series_markers)
    legend_x = left
    for method in _methods(summary):
        color = METHOD_COLORS.get(method, "#6B7280")
        style = METHOD_LINE_STYLES.get(
            method, {"dash": "", "width": 3, "marker_radius": 5.5}
        )
        dash = (
            f' stroke-dasharray="{style["dash"]}"'
            if style["dash"]
            else ""
        )
        elements.append(
            f'<line x1="{legend_x}" y1="101" x2="{legend_x + 28}" y2="101" '
            f'stroke="{color}" stroke-width="{style["width"]}"{dash} '
            'stroke-linecap="round"/>'
        )
        elements.append(
            f'<text class="label" x="{legend_x + 38}" y="106">'
            f'{_escape(method)}</text>'
        )
        legend_x += 112
    svg = _svg_document(width, height, title, description, "\n".join(elements))
    return _write_figure(
        figures_dir / "fig02_stage_funnel.svg",
        title=title,
        description=description,
        svg=svg,
        source="aggregate/stage_funnel.csv",
    )


def _pairwise_figure(
    figures_dir: Path, statistics: list[Dict[str, Any]]
) -> Dict[str, Any] | None:
    if not statistics:
        return None
    title = "Paired effect versus P0-current"
    description = (
        "Risk difference in percentage points (P0 minus comparator); "
        "whiskers are paired bootstrap confidence intervals."
    )
    width = 1000
    row_h = 92
    height = 190 + row_h * len(statistics)
    left, right, top = 320, 70, 120
    chart_w = width - left - right
    x_min, x_max = -100.0, 100.0

    def x(value: float) -> float:
        return left + (value - x_min) / (x_max - x_min) * chart_w

    elements = []
    for tick in (-100, -50, 0, 50, 100):
        line_class = "zero" if tick == 0 else "axis"
        elements.append(
            f'<line class="{line_class}" x1="{x(tick):.1f}" y1="{top}" '
            f'x2="{x(tick):.1f}" y2="{height - 62}"/>'
        )
        elements.append(
            f'<text class="small" x="{x(tick):.1f}" y="{height - 36}" '
            f'text-anchor="middle">{tick:+d} pp</text>'
        )
    for index, item in enumerate(statistics):
        y = top + 42 + index * row_h
        comparison = str(item["comparison"]).replace(
            "P0-current_vs_", ""
        ).replace("-one-shot", "")
        delta = float(item["risk_difference_percentage_points"])
        ci = item["bootstrap_ci_percentage_points"]
        color = METHOD_COLORS.get(comparison, "#6B7280")
        elements.extend(
            [
                f'<text class="label" x="{left - 20}" y="{y + 5:.1f}" '
                f'text-anchor="end">P0 − {_escape(comparison)}</text>',
                f'<line x1="{x(float(ci[0])):.1f}" y1="{y:.1f}" '
                f'x2="{x(float(ci[1])):.1f}" y2="{y:.1f}" '
                f'stroke="{color}" stroke-width="4"/>',
                f'<line x1="{x(float(ci[0])):.1f}" y1="{y - 9:.1f}" '
                f'x2="{x(float(ci[0])):.1f}" y2="{y + 9:.1f}" '
                f'stroke="{color}" stroke-width="2"/>',
                f'<line x1="{x(float(ci[1])):.1f}" y1="{y - 9:.1f}" '
                f'x2="{x(float(ci[1])):.1f}" y2="{y + 9:.1f}" '
                f'stroke="{color}" stroke-width="2"/>',
                f'<circle cx="{x(delta):.1f}" cy="{y:.1f}" r="8" '
                f'fill="{color}"/>',
                f'<text class="value" x="{left + chart_w + 14}" '
                f'y="{y + 5:.1f}">{delta:+.1f} pp</text>',
            ]
        )
    elements.append(
        f'<text class="small" x="{left}" y="{height - 10}">'
        "Negative favors comparator; positive favors P0.</text>"
    )
    svg = _svg_document(width, height, title, description, "\n".join(elements))
    return _write_figure(
        figures_dir / "fig03_pairwise_effect.svg",
        title=title,
        description=description,
        svg=svg,
        source="aggregate/statistics.json",
    )


def _efficiency_figure(
    figures_dir: Path, summary: Dict[str, Any]
) -> Dict[str, Any]:
    title = "Resource-efficiency distributions"
    description = (
        "Median and interquartile range by method; scales are independent "
        "within each panel."
    )
    width, height = 1200, 570
    panels = [
        ("Accepted model calls", "model_call_distribution", "calls", 60),
        (
            "Total LLM evidence size",
            "evidence_token_distribution",
            "tokens",
            430,
        ),
        ("Wall-clock duration", "total_duration_ms_distribution", "ms", 800),
    ]
    elements = []
    methods = _methods(summary)
    for panel_title, metric, unit, panel_x in panels:
        panel_w = 330
        elements.append(
            f'<text class="value" x="{panel_x}" y="126">'
            f'{_escape(panel_title)}</text>'
        )
        distributions = [
            summary[method].get(metric) or {} for method in methods
        ]
        max_value = max(
            [float(item.get("max", 0) or 0) for item in distributions] + [1.0]
        )
        for index, (method, distribution) in enumerate(
            zip(methods, distributions)
        ):
            y = 180 + index * 102
            color = METHOD_COLORS.get(method, "#6B7280")
            elements.append(
                f'<text class="label" x="{panel_x}" y="{y + 5}">'
                f'{_escape(method)}</text>'
            )
            x0 = panel_x + 48
            x1 = panel_x + panel_w
            elements.append(
                f'<line class="axis" x1="{x0}" y1="{y}" x2="{x1}" y2="{y}"/>'
            )
            if not distribution:
                elements.append(
                    f'<text class="small" x="{x0}" y="{y - 10}">N/A</text>'
                )
                continue

            def scale(value: float) -> float:
                return x0 + float(value) / max_value * (x1 - x0)

            q1 = float(distribution["q1"])
            median = float(distribution["median"])
            q3 = float(distribution["q3"])
            elements.extend(
                [
                    f'<line x1="{scale(q1):.1f}" y1="{y}" '
                    f'x2="{scale(q3):.1f}" y2="{y}" '
                    f'stroke="{color}" stroke-width="8"/>',
                    f'<circle cx="{scale(median):.1f}" cy="{y}" r="7" '
                    f'fill="{PAPER}" stroke="{color}" stroke-width="3"/>',
                    f'<text class="small" x="{x0}" y="{y + 25}">'
                    f'median {_fmt_number(median)} {_escape(unit)}; '
                    f'IQR {_fmt_number(q1)}–{_fmt_number(q3)}</text>',
                ]
            )
    elements.append(
        '<text class="small" x="60" y="535">'
        "Missing provider token or timing data are shown as N/A.</text>"
    )
    svg = _svg_document(width, height, title, description, "\n".join(elements))
    return _write_figure(
        figures_dir / "fig04_efficiency.svg",
        title=title,
        description=description,
        svg=svg,
        source="aggregate/method_summary.json",
    )


def _percentile(values: list[float], probability: float) -> float:
    ordered = sorted(values)
    if not ordered:
        return 0.0
    position = probability * (len(ordered) - 1)
    low = math.floor(position)
    high = math.ceil(position)
    if low == high:
        return ordered[low]
    weight = position - low
    return ordered[low] * (1 - weight) + ordered[high] * weight


def _ir_figure(
    figures_dir: Path, ir_rows: list[Dict[str, Any]]
) -> Dict[str, Any] | None:
    if not ir_rows:
        return None
    title = "Structural reduction from A0 raw IR to P0 brightened IR"
    description = (
        "Median relative reduction with interquartile range across programs; "
        "this is descriptive and not a causal outcome."
    )
    metrics = [
        ("Instructions", "instruction_count_reduction"),
        ("Basic blocks", "basic_block_count_reduction"),
        ("CFG edges", "cfg_edge_count_reduction"),
        ("Functions", "function_count_reduction"),
    ]
    width, height = 1000, 560
    left, right, top, bottom = 260, 70, 120, 78
    chart_w = width - left - right
    values_by_metric = {
        key: [
            float(row[key]) * 100
            for row in ir_rows
            if row.get(key) is not None
        ]
        for _, key in metrics
    }
    all_values = [
        value for values in values_by_metric.values() for value in values
    ]
    lower = min([-10.0] + all_values)
    upper = max([100.0] + all_values)
    span = max(1.0, upper - lower)
    lower = math.floor((lower - span * 0.05) / 10) * 10
    upper = math.ceil((upper + span * 0.05) / 10) * 10

    def x(value: float) -> float:
        return left + (value - lower) / (upper - lower) * chart_w

    elements = []
    tick_count = 5
    for index in range(tick_count + 1):
        tick = lower + (upper - lower) * index / tick_count
        line_class = "zero" if abs(tick) < 1e-9 else "axis"
        elements.append(
            f'<line class="{line_class}" x1="{x(tick):.1f}" y1="{top}" '
            f'x2="{x(tick):.1f}" y2="{height - bottom}"/>'
        )
        elements.append(
            f'<text class="small" x="{x(tick):.1f}" y="{height - 42}" '
            f'text-anchor="middle">{tick:.0f}%</text>'
        )
    for index, (label, key) in enumerate(metrics):
        y = top + 54 + index * 78
        values = values_by_metric[key]
        elements.append(
            f'<text class="label" x="{left - 20}" y="{y + 5}" '
            f'text-anchor="end">{_escape(label)}</text>'
        )
        if not values:
            continue
        q1 = _percentile(values, 0.25)
        median = _percentile(values, 0.5)
        q3 = _percentile(values, 0.75)
        elements.extend(
            [
                f'<line x1="{x(q1):.1f}" y1="{y}" x2="{x(q3):.1f}" '
                f'y2="{y}" stroke="{METHOD_COLORS["P0"]}" stroke-width="8"/>',
                f'<circle cx="{x(median):.1f}" cy="{y}" r="7" '
                f'fill="{PAPER}" stroke="{METHOD_COLORS["P0"]}" '
                'stroke-width="3"/>',
                f'<text class="value" x="{left + chart_w + 14}" '
                f'y="{y + 5}">{median:+.1f}%</text>',
            ]
        )
    svg = _svg_document(width, height, title, description, "\n".join(elements))
    return _write_figure(
        figures_dir / "fig05_ir_reduction.svg",
        title=title,
        description=description,
        svg=svg,
        source="aggregate/ir_cfg_metrics.csv",
    )


def _dashboard(
    aggregate_dir: Path,
    summary: Dict[str, Any],
    statistics: list[Dict[str, Any]],
    figures: list[Dict[str, Any]],
    execution_context: Dict[str, Any],
    deobfuscation: Dict[str, Any],
) -> Path:
    method_rows = []
    detail_rows = []
    detail_metrics = (
        ("representation_success_unconditional", "Representation success"),
        ("context_fit_unconditional", "Context fit"),
        ("llm_response_unconditional", "LLM response"),
        ("generation_unconditional", "Candidate generation"),
        ("build_success_unconditional", "Build success"),
        ("runnable_unconditional", "Runnable"),
        ("confirmed_non_equivalence_unconditional", "Behavior mismatch"),
        ("inconclusive_unconditional", "Inconclusive"),
        ("infra_failure_unconditional", "Infrastructure failure"),
        ("total_discovery_tested_inputs", "Discovery tested inputs"),
        ("total_unique_discovered_inputs", "Unique discovered inputs"),
        ("estimated_total_cost_usd", "Estimated cost (USD)"),
        ("total_model_calls", "Accepted model calls"),
        ("total_api_attempts", "API attempts"),
        ("total_quota_wait_duration_ms", "Quota wait (s)"),
    )
    for method in _methods(summary):
        item = summary[method]
        ci = item.get("e2e_rate_wilson_ci") or [None, None]
        ci_text = (
            f"{ci[0] * 100:.1f}–{ci[1] * 100:.1f}%"
            if ci[0] is not None
            else "N/A"
        )
        method_rows.append(
            "<tr>"
            f"<th scope=\"row\">{_escape(method)}</th>"
            f"<td>{item['enrolled']}</td>"
            f"<td>{item['pass']}</td>"
            f"<td>{item['e2e_rate'] * 100:.1f}%</td>"
            f"<td>{ci_text}</td>"
            f"<td>{item['total_model_calls']}</td>"
            f"<td>{item.get('total_api_attempts', 0)}</td>"
            f"<td>{item.get('total_quota_wait_duration_ms', 0) / 1000:.1f}s</td>"
            "</tr>"
        )
        cells = []
        for key, _label in detail_metrics:
            value = item.get(key)
            if key.endswith("_unconditional"):
                text_value = f"{float(value or 0) * 100:.1f}%"
            elif key == "total_quota_wait_duration_ms":
                text_value = f"{float(value or 0) / 1000:.1f}"
            elif key == "estimated_total_cost_usd":
                text_value = "N/A" if value is None else f"{float(value):.4f}"
            else:
                text_value = str(value if value is not None else "N/A")
            cells.append(f"<td>{_escape(text_value)}</td>")
        detail_rows.append(
            f"<tr><th scope=\"row\">{_escape(method)}</th>"
            + "".join(cells)
            + "</tr>"
        )
    detail_headers = "".join(f"<th>{_escape(label)}</th>" for _, label in detail_metrics)
    figure_sections = "\n".join(
        "<figure>"
        f"<img src=\"figures/{_escape(item['path'])}\" "
        f"alt=\"{_escape(item['description'])}\">"
        f"<figcaption><strong>{_escape(item['title'])}.</strong> "
        f"{_escape(item['description'])}</figcaption>"
        "</figure>"
        for item in figures
    )
    pairwise_rows = ""
    for item in statistics:
        ci = item["bootstrap_ci_percentage_points"]
        pairwise_rows += (
            "<tr>"
            f"<th scope=\"row\">{_escape(item['comparison'])}</th>"
            f"<td>{item['risk_difference_percentage_points']:+.1f} pp</td>"
            f"<td>{ci[0]:+.1f} to {ci[1]:+.1f} pp</td>"
            f"<td>{item['mcnemar_exact_p']:.4g}</td>"
            f"<td>{item['holm_adjusted_p']:.4g}</td>"
            "</tr>"
        )
    pairwise_section = (
        """
        <section>
          <h2>Paired inference</h2>
          <div class="table-wrap"><table>
            <thead><tr><th>Comparison</th><th>Risk difference</th>
            <th>Paired bootstrap CI</th><th>McNemar p</th>
            <th>Holm-adjusted p</th></tr></thead>
            <tbody>"""
        + pairwise_rows
        + "</tbody></table></div></section>"
        if pairwise_rows
        else ""
    )
    ir_metric_keys = (
        ("median_instruction_count", "Instructions"),
        ("median_basic_block_count", "Basic blocks"),
        ("median_cyclomatic_complexity", "Cyclomatic"),
        ("median_indirect_call_count", "Indirect calls"),
        ("median_helper_reference_count", "Lifter/helper refs"),
    )
    source_metric_keys = (
        ("median_source_line_count", "Source lines"),
        ("median_function_count", "Functions"),
        ("median_cyclomatic_complexity", "Cyclomatic"),
        ("median_goto_count", "Gotos"),
        ("median_decompiler_artifact_count", "Decompiler artifacts"),
    )

    def metric_table(
        values: Dict[str, Any],
        keys: tuple[tuple[str, str], ...],
        first_header: str,
    ) -> str:
        if not values:
            return "<p>No complete artifacts were available for this metric group.</p>"
        headers = "".join(f"<th>{_escape(label)}</th>" for _, label in keys)
        rows = []
        for group, item in sorted(values.items()):
            cells = []
            for key, _label in keys:
                value = item.get(key)
                cells.append(
                    "<td>N/A</td>"
                    if value is None
                    else f"<td>{float(value):.2f}</td>"
                )
            rows.append(
                f"<tr><th scope=\"row\">{_escape(group)}</th>"
                + "".join(cells)
                + "</tr>"
            )
        return (
            "<div class=\"table-wrap\"><table><thead><tr>"
            f"<th>{_escape(first_header)}</th>{headers}</tr></thead>"
            f"<tbody>{''.join(rows)}</tbody></table></div>"
        )

    deobfuscation_section = (
        "<section><h2>Deobfuscation structure metrics</h2>"
        "<p>These descriptive metrics complement—not replace—the semantic "
        "PASS endpoint. LLVM counts are compared only across LLVM stages.</p>"
        "<h3>Raw → brightened → delifted LLVM IR (medians)</h3>"
        + metric_table(
            deobfuscation.get("ir_stage_medians") or {},
            ir_metric_keys,
            "IR stage",
        )
        + "<h3>Recovered C by method (medians)</h3>"
        + metric_table(
            deobfuscation.get("source_method_medians") or {},
            source_metric_keys,
            "Method",
        )
        + "<p>Full definitions and binary artifact characteristics: "
        "<a href=\"deobfuscation_metrics.json\">deobfuscation_metrics.json</a>, "
        "<a href=\"ir_stage_metrics.csv\">ir_stage_metrics.csv</a>, "
        "<a href=\"ir_transition_metrics.csv\">ir_transition_metrics.csv</a>, "
        "<a href=\"source_deobfuscation_metrics.csv\">"
        "source_deobfuscation_metrics.csv</a>, "
        "<a href=\"binary_artifact_metrics.csv\">"
        "binary_artifact_metrics.csv</a>.</p></section>"
    )
    fake_llm = bool(execution_context.get("fake_llm"))
    mode_label = (
        "FAKE-LLM · PIPELINE VALIDATION ONLY"
        if fake_llm
        else (
            "REAL PROVIDER · "
            + str(
                execution_context.get(
                    "evidence_eligibility",
                    "scoped_research_evidence",
                )
            )
            .replace("_", " ")
            .upper()
        )
    )
    warning = (
        """
        <aside class="warning" role="note">
          <strong>Not a research result.</strong> This run used a synthetic
          provider response to validate orchestration, auditing, evaluation,
          metrics, and visualization. It must not be cited as evidence of
          P0/A0/B0 recovery quality.
        </aside>
        """
        if fake_llm
        else (
            """
        <aside class="warning" role="note">
          <strong>Dirty-worktree scoped evidence.</strong> The run is
          cryptographically tied to its source snapshot, but it is not the
          canonical clean-commit primary study. Interpret it only within the
          recorded sample scope.
        </aside>
        """
            if execution_context.get("git_dirty")
            else ""
        )
    )
    run_label = (
        f"RUN {_escape(execution_context.get('run_id', 'unknown'))} · "
        f"{_escape(mode_label)} · "
        f"SCOPE {_escape(execution_context.get('study_scope', 'unspecified'))} "
        f"(n={_escape(execution_context.get('sample_count', 'unknown'))}) · "
        f"{_escape(execution_context.get('provider', 'unknown'))} / "
        f"{_escape(execution_context.get('model_id', 'unknown'))}"
    )
    document = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>P0/A0/B0 experiment evidence</title>
  <style>
    :root {{
      --paper: {PAPER}; --ink: {INK}; --muted: {MUTED}; --rule: {GRID};
      --p0: {METHOD_COLORS["P0"]}; --a0: {METHOD_COLORS["A0"]};
      --b0: {METHOD_COLORS["B0"]};
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0; background: var(--paper); color: var(--ink);
      font-family: "Liberation Sans", sans-serif; line-height: 1.58;
    }}
    main {{ width: min(1180px, calc(100% - 48px)); margin: 0 auto; }}
    header {{ padding: 72px 0 42px; border-bottom: 2px solid var(--ink); }}
    h1, h2 {{ font-family: Georgia, serif; text-wrap: balance; }}
    h1 {{ max-width: 850px; margin: 0 0 18px; font-size: clamp(38px, 6vw, 74px);
          line-height: .98; letter-spacing: -.035em; }}
    h2 {{ margin: 0 0 20px; font-size: 30px; }}
    p {{ max-width: 850px; color: var(--muted); text-wrap: pretty; }}
    section {{ padding: 44px 0; border-bottom: 1px solid var(--rule); }}
    .protocol {{ font-family: "DejaVu Sans Mono", monospace; font-size: 13px; }}
    .warning {{
      margin: 28px 0 0; padding: 18px 20px; border: 2px solid var(--a0);
      color: var(--ink); background: #FFF4EF; max-width: 900px;
    }}
    .warning strong {{ color: var(--a0); }}
    .keys {{ display: flex; gap: 22px; flex-wrap: wrap; margin-top: 28px; }}
    .key {{ display: inline-flex; align-items: center; gap: 8px; font-weight: 700; }}
    .swatch {{ width: 26px; height: 4px; background: currentColor; }}
    .p0 {{ color: var(--p0); }} .a0 {{ color: var(--a0); }}
    .b0 {{ color: var(--b0); }}
    .table-wrap {{ overflow-x: auto; }}
    table {{ width: 100%; border-collapse: collapse; font-variant-numeric: tabular-nums; }}
    th, td {{ padding: 12px 14px; border-bottom: 1px solid var(--rule);
              text-align: right; white-space: nowrap; }}
    th:first-child, td:first-child {{ text-align: left; }}
    thead th {{ color: var(--muted); font-size: 12px; letter-spacing: .04em;
                text-transform: uppercase; }}
    figure {{ margin: 0 0 52px; }}
    figure img {{ display: block; width: 100%; height: auto; border: 1px solid var(--rule); }}
    figcaption {{ margin-top: 12px; color: var(--muted); font-size: 14px; }}
    .files a {{ color: var(--ink); text-underline-offset: 3px; }}
    footer {{ padding: 36px 0 60px; color: var(--muted); font-size: 13px; }}
    @media print {{
      main {{ width: 100%; }} header {{ padding-top: 0; }}
      figure {{ break-inside: avoid; }} a {{ color: inherit; text-decoration: none; }}
    }}
    @media (max-width: 800px) {{
      main {{ width: min(100% - 24px, 1180px); }}
      th, td {{ padding: 10px 6px; font-size: 11px; white-space: normal; }}
      thead th {{ font-size: 9px; }}
    }}
  </style>
</head>
<body>
<!--
  Design assumptions: research-review audience; laptop and print viewing;
  calm editorial tone; charts remain secondary to machine-readable metrics.
-->
<main>
  <header>
    <div class="protocol">{run_label}</div>
    <h1>Binary reconstruction experiment results</h1>
    <p>P0 uses Ghidra pseudocode plus cleaned LLVM IR and at most five
    compiler/fuzz-guided LLM calls. A0 and B0 each use one logical generation.
    All end-to-end behavior is judged against the same original obfuscated ELF
    and union input corpus.</p>
    <div class="keys">
      <span class="key p0"><i class="swatch"></i>P0</span>
      <span class="key a0"><i class="swatch"></i>A0</span>
      <span class="key b0"><i class="swatch"></i>B0</span>
    </div>
    {warning}
  </header>
  <section>
    <h2>Primary outcome</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Method</th><th>Enrolled</th><th>PASS</th>
      <th>E2E rate</th><th>Wilson CI</th><th>Accepted calls</th>
      <th>API attempts</th><th>Quota wait</th></tr></thead>
      <tbody>{"".join(method_rows)}</tbody>
    </table></div>
  </section>
  <section>
    <h2>Full metric summary</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>Method</th>{detail_headers}</tr></thead>
      <tbody>{"".join(detail_rows)}</tbody>
    </table></div>
    <p>Excluded development-only precheck failures are reported in
    <a href="metrics.json">metrics.json</a> under each method's diagnostic
    fields and are not included in the research denominator.</p>
  </section>
  {pairwise_section}
  {deobfuscation_section}
  <section>
    <h2>Figures</h2>
    {figure_sections}
  </section>
  <section class="files">
    <h2>Machine-readable evidence</h2>
    <p><a href="metrics.json">metrics.json</a> ·
       <a href="metrics_long.csv">metrics_long.csv</a> ·
       <a href="variants.csv">variants.csv</a> ·
       <a href="statistics.json">statistics.json</a> ·
       <a href="deobfuscation_metrics.json">deobfuscation metrics</a> ·
       <a href="../audit/events.jsonl">audit/events.jsonl</a> ·
       <a href="../audit/artifact_manifest.json">artifact manifest</a></p>
  </section>
  <footer>Generated from structured experiment artifacts. Verify the linked
  artifact manifest before use. SVG figures are vector, accessible, and
  suitable for thesis export.</footer>
</main>
</body>
</html>
"""
    path = aggregate_dir / "dashboard.html"
    atomic_write_text(path, document)
    return path


def generate_visualizations(
    aggregate_dir: str | Path,
    method_summary: Dict[str, Any],
    statistics: list[Dict[str, Any]],
    ir_rows: list[Dict[str, Any]],
    execution_context: Dict[str, Any],
    deobfuscation: Dict[str, Any],
) -> Dict[str, Any]:
    aggregate = Path(aggregate_dir)
    figures_dir = aggregate / "figures"
    figures_dir.mkdir(parents=True, exist_ok=True)
    figures = [
        _e2e_figure(figures_dir, method_summary),
        _funnel_figure(figures_dir, method_summary),
        _efficiency_figure(figures_dir, method_summary),
    ]
    pairwise = _pairwise_figure(figures_dir, statistics)
    if pairwise:
        figures.insert(2, pairwise)
    ir_figure = _ir_figure(figures_dir, ir_rows)
    if ir_figure:
        figures.append(ir_figure)
    dashboard = _dashboard(
        aggregate,
        method_summary,
        statistics,
        figures,
        execution_context,
        deobfuscation,
    )
    manifest = {
        "schema_version": "1.1",
        "execution_context": execution_context,
        "design": {
            "audience": "thesis reviewers and experiment auditors",
            "medium": "laptop, print, and vector export",
            "visual_language": "scientific editorial",
            "method_colors": METHOD_COLORS,
        },
        "figure_count": len(figures),
        "figures": figures,
        "dashboard": {
            "path": dashboard.name,
            "sha256": sha256_file(dashboard),
        },
    }
    atomic_write_json(aggregate / "figures_manifest.json", manifest)
    return manifest
