"""CSV/JSON/Markdown/LaTeX/HTML exporters for evaluation framework v2."""

from __future__ import annotations

import csv
import html
import json
from pathlib import Path
from typing import Any, Iterable

from evaluation.aggregate import (
    aggregate_flows,
    failure_rows,
    stage_completion_rows,
)
from evaluation.metrics import format_ratio
from evaluation.schema import FLOW_LAYOUT_VERSION
from evaluation.statistical_analysis import paired_analysis
from evaluation.validation import validate_runs


FIGURE_GUIDES: dict[str, dict[str, str]] = {
    "overall_performance": {
        "meaning": (
            "So sánh ba kết quả chính của từng flow: compile ngay lần đầu, "
            "PASS hành vi cuối, và thành công end-to-end."
        ),
        "calculation": (
            "First-pass RSR = first compile success / initial candidates; "
            "Behavioral pass = final PASS / completed behavioral validations; "
            "Canonical E2E = accepted PASS / all eligible samples."
        ),
        "reading": (
            "Cột càng cao càng tốt. Ba cột có thể dùng mẫu số khác nhau; thanh "
            "đen là 95% CI, không phải lỗi chạy."
        ),
    },
    "compilation_performance": {
        "meaning": (
            "Cho biết repair có biến Candidate C compile lỗi thành executable "
            "được hay không và tốn bao nhiêu vòng."
        ),
        "calculation": (
            "Final RSR dùng any compile success trong budget; repair gain = "
            "Final RSR - First-pass RSR (điểm phần trăm); mean rounds chỉ tính "
            "các compile-repair case."
        ),
        "reading": (
            "Khoảng cách First/Final lớn nghĩa là compile repair hữu ích. Gain "
            "cao với ít vòng tốt hơn; N/A nghĩa là flow không bật repair."
        ),
    },
    "behavioral_performance": {
        "meaning": (
            "So sánh hành vi trước và sau repair, tỷ lệ input match, và tỷ lệ "
            "Candidate cuối còn counterexample."
        ),
        "calculation": (
            "Initial/Final pass = PASS / candidates hoàn thành validation tương "
            "ứng; Match Macro = trung bình (matches/valid inputs) theo sample; "
            "Counterexample rate = final reproducible counterexample / completed validations."
        ),
        "reading": (
            "Initial, Final và Match cao là tốt; Counterexample Detection thấp "
            "là tốt. Match Rate không phải ngưỡng PASS."
        ),
    },
    "repair_effectiveness": {
        "meaning": (
            "Đo riêng tác dụng của behavioral repair đối với các Candidate đã "
            "có divergence tái hiện được."
        ),
        "calculation": (
            "Semantic repair success = repair cases kết thúc bằng behavioral "
            "PASS / behavioral repair cases; Behavioral gain = Final pass rate "
            "- Initial pass rate."
        ),
        "reading": (
            "After cao hơn Before, success rate cao và gain dương nghĩa là "
            "repair có ích. F2 là one-shot nên các repair metric là N/A."
        ),
    },
    "cumulative_compile_success_by_round": {
        "meaning": (
            "Cho biết đến compile attempt thứ r đã có bao nhiêu run từng tạo "
            "được executable."
        ),
        "calculation": (
            "Tại r: runs có ít nhất một compile success trong attempts 1..r / "
            "toàn bộ runs của flow."
        ),
        "reading": (
            "Đường tăng nhanh và đạt mức cao sớm là tốt. Đường nằm ngang nghĩa "
            "là thêm attempt không cứu thêm sample."
        ),
    },
    "cumulative_behavioral_success_by_round": {
        "meaning": (
            "Cho biết đến behavioral campaign thứ r đã có bao nhiêu run từng "
            "đạt một campaign hoàn thành với zero mismatch."
        ),
        "calculation": (
            "Tại r: runs có ít nhất một completed zero-mismatch campaign trong "
            "campaigns 1..r / toàn bộ runs của flow."
        ),
        "reading": (
            "Đường cao sớm nghĩa là đạt behavioral pass nhanh. Đây là ever-pass "
            "cumulative, không thay thế trạng thái Candidate cuối."
        ),
    },
    "final_status_breakdown": {
        "meaning": "Phân rã trạng thái cuối của toàn bộ sample trong từng flow.",
        "calculation": (
            "Đếm sample theo PASS, FAIL_GENERATION, FAIL_COMPILE, "
            "FAIL_BEHAVIORAL và INCONCLUSIVE; mỗi sample thuộc đúng một nhóm."
        ),
        "reading": (
            "Phần PASS càng lớn càng tốt. Các phần fail cho biết pipeline dừng "
            "ở generation, compilation hay behavioral validation."
        ),
    },
    "failure_taxonomy": {
        "meaning": (
            "Cho biết lỗi thuộc loại compiler, divergence hành vi hay nguyên "
            "nhân inconclusive nào."
        ),
        "calculation": (
            "Compile panel đếm failed compile attempts; behavioral panel đếm "
            "sample theo divergence của campaign cuối; inconclusive panel đếm sample."
        ),
        "reading": (
            "Thanh dài chỉ ra failure mode phổ biến cần ưu tiên xử lý. Ba panel "
            "có đơn vị đếm khác nhau nên không so trực tiếp độ dài giữa panel."
        ),
    },
    "sample_flow_status_heatmap": {
        "meaning": "Hiển thị trạng thái của từng sample khi chạy qua từng flow.",
        "calculation": "Mỗi ô: FAIL=0, INCONCLUSIVE=1, PASS=2.",
        "reading": (
            "Đọc ngang để thấy một sample nhạy với component nào; đọc dọc để "
            "thấy flow nào ổn định hơn. Giá trị 0 gộp mọi loại FAIL."
        ),
    },
    "sample_flow_match_heatmap": {
        "meaning": (
            "Hiển thị phần trăm valid input có behavior tuple giống nhau cho "
            "từng cặp sample-flow."
        ),
        "calculation": (
            "Mỗi ô = fuzz matches / fuzz valid × 100%; ô trống là không có "
            "behavioral validation hợp lệ."
        ),
        "reading": (
            "100% nghĩa là không thấy mismatch trong corpus đã chạy, không chứng "
            "minh tương đương với mọi input."
        ),
    },
    "ablation_forest_plot": {
        "meaning": "Ước lượng chênh lệch Canonical E2E cho từng cặp flow paired.",
        "calculation": (
            "Effect = E2E(flow A) - E2E(flow B) theo cùng sample/repeat, đơn vị "
            "điểm phần trăm; interval là bootstrap 95% CI."
        ),
        "reading": (
            "Điểm bên phải 0 nghiêng về A, bên trái nghiêng về B. CI cắt đường "
            "0 nghĩa là dữ liệu chưa cho thấy khác biệt rõ."
        ),
    },
    "ablation_win_tie_loss": {
        "meaning": "Đếm kết quả thắng/hòa/thua của Flow A so với Flow B theo sample.",
        "calculation": (
            "A win: A E2E PASS và B FAIL; tie: cùng kết quả; B win: B PASS và A FAIL."
        ),
        "reading": (
            "So sánh phần A wins với B wins; nhiều tie nghĩa là hai flow thường "
            "cho cùng kết quả trên sample paired."
        ),
    },
    "tokens_vs_e2e": {
        "meaning": "Liên hệ lượng token của một run với kết quả Canonical E2E.",
        "calculation": (
            "Mỗi chấm là một run: trục X = total input + output tokens; trục Y "
            "= E2E No/Yes; màu/ký hiệu = flow."
        ),
        "reading": (
            "Xem nhóm PASS có cần nhiều token hơn không. Đây là association, "
            "không chứng minh tăng token gây ra PASS."
        ),
    },
    "runtime_vs_behavioral_pass": {
        "meaning": "Liên hệ tổng runtime của run với behavioral PASS cuối.",
        "calculation": (
            "Mỗi chấm là một run có runtime và behavioral verdict; X = total "
            "runtime seconds; Y = final behavioral No/Yes."
        ),
        "reading": (
            "Cho biết PASS thường nhanh hay chậm hơn trong dữ liệu; không suy ra "
            "runtime dài tự động cải thiện correctness."
        ),
    },
    "llvm_reduction_summary": {
        "meaning": "Đo Clean IR đã đơn giản hóa Raw IR bao nhiêu.",
        "calculation": (
            "Reduction = (raw count - clean count) / raw count × 100%, tính cho "
            "instructions, basic blocks và conditional branches rồi lấy mean theo sample."
        ),
        "reading": (
            "Cột cao nghĩa là IR giảm nhiều cấu trúc hơn; đây không phải bằng "
            "chứng semantic correctness."
        ),
    },
    "llvm_reduction_vs_behavior": {
        "meaning": (
            "Kiểm tra mô tả xem sample được giảm instruction nhiều có thường "
            "PASS hành vi ở nhiều flow hơn hay không."
        ),
        "calculation": (
            "Mỗi chấm là một sample: X = instruction reduction; Y = số flow "
            "behavioral PASS / số flow có behavioral verdict × 100%."
        ),
        "reading": (
            "Chỉ quan sát xu hướng điểm; không dùng reduction làm correctness "
            "oracle và không kết luận quan hệ nhân quả."
        ),
    },
    "stage_completion_funnel": {
        "meaning": "Cho biết tỷ lệ hoàn thành tại từng stage của pipeline.",
        "calculation": (
            "Mỗi stage = tổng completed flow-runs / tổng eligible flow-runs trên "
            "F1–F6; đây là pooled flow-runs, không phải unique samples."
        ),
        "reading": (
            "Stage giảm mạnh là bottleneck nơi nhiều run dừng lại. Candidate "
            "acceptance là điểm cuối."
        ),
    },
}


def _csv_value(value: Any) -> Any:
    if value is None:
        return ""
    if isinstance(value, (dict, list, tuple)):
        return json.dumps(value, sort_keys=True, ensure_ascii=False, default=str)
    return value


def write_csv(path: Path, rows: Iterable[dict[str, Any]], columns: list[str] | None = None) -> None:
    materialized = list(rows)
    if columns is None:
        columns = list(dict.fromkeys(key for row in materialized for key in row))
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in materialized:
            writer.writerow({key: _csv_value(row.get(key)) for key in columns})


def _select(rows: list[dict[str, Any]], columns: list[str]) -> list[dict[str, Any]]:
    return [{column: row.get(column) for column in columns} for row in rows]


def _materialize_counterexample_inputs(
    report_dir: Path, counterexamples: list[dict[str, Any]]
) -> None:
    import base64

    input_dir = report_dir / "counterexample_inputs"
    input_dir.mkdir(parents=True, exist_ok=True)
    for item in counterexamples:
        encoded = item.pop("input_base64", None)
        if not encoded:
            continue
        path = input_dir / f"{item['counterexample_id']}.bin"
        path.write_bytes(base64.b64decode(encoded))
        item["input_path"] = str(path)


def _rate_cell(
    row: dict[str, Any], numerator: str, denominator: str, percentage: str
) -> str:
    return format_ratio(
        int(row.get(numerator) or 0),
        int(row.get(denominator) or 0),
        row.get(percentage),
    )


def _flow_summary(flow_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in flow_rows:
        rows.append(
            {
                "Flow": row["flow_id"],
                "N": row["sample_count"],
                "Eligible N": row["eligible_sample_count"],
                "First-pass RSR": _rate_cell(
                    row,
                    "first_compile_success_count",
                    "initial_candidate_count",
                    "first_pass_rsr_percent",
                ),
                "Final RSR@R": _rate_cell(
                    row,
                    "compile_success_within_budget_count",
                    "initial_candidate_count",
                    "final_rsr_percent",
                ),
                "Program Behavioral Pass Rate": _rate_cell(
                    row,
                    "behavioral_pass_count",
                    "completed_behavioral_validation_count",
                    "program_behavioral_pass_rate_percent",
                ),
                "Initial Behavioral Pass Rate": _rate_cell(
                    row,
                    "initial_behavioral_pass_count",
                    "initial_behavioral_validation_count",
                    "initial_behavioral_pass_rate_percent",
                ),
                "Final Behavioral Pass Rate": _rate_cell(
                    row,
                    "behavioral_pass_count",
                    "completed_behavioral_validation_count",
                    "final_behavioral_pass_rate_percent",
                ),
                "Input Match Macro": (
                    "N/A"
                    if row["input_match_macro_percent"] is None
                    else f"{row['input_match_macro_percent']:.1f}%"
                ),
                "Input Match Micro": (
                    "N/A"
                    if row["input_match_micro_percent"] is None
                    else f"{row['input_match_micro_percent']:.1f}%"
                ),
                "Counterexample Detection Rate": _rate_cell(
                    row,
                    "counterexample_sample_count",
                    "completed_behavioral_validation_count",
                    "counterexample_detection_rate_percent",
                ),
                "Canonical E2E": _rate_cell(
                    row,
                    "canonical_e2e_success_count",
                    "eligible_sample_count",
                    "canonical_e2e_rate_percent",
                ),
                "Compilation Repair Gain": (
                    "N/A"
                    if row["compilation_repair_gain_pp"] is None
                    else f"{row['compilation_repair_gain_pp']:+.1f} pp"
                ),
                "Behavioral Repair Gain": (
                    "N/A"
                    if row["behavioral_repair_gain_pp"] is None
                    else f"{row['behavioral_repair_gain_pp']:+.1f} pp"
                ),
                "Mean Tokens": (
                    "N/A" if row["mean_tokens"] is None else f"{row['mean_tokens']:.0f}"
                ),
                "Mean Runtime": (
                    "N/A"
                    if row["mean_runtime_seconds"] is None
                    else f"{row['mean_runtime_seconds']:.1f}s"
                ),
            }
        )
    return rows


def _markdown_table(rows: list[dict[str, Any]]) -> str:
    if not rows:
        return ""
    columns = list(rows[0])
    lines = [
        "| " + " | ".join(columns) + " |",
        "|" + "|".join("---" for _ in columns) + "|",
    ]
    lines.extend(
        "| " + " | ".join(str(row.get(column, "")) for column in columns) + " |"
        for row in rows
    )
    return "\n".join(lines)


def _latex_escape(value: Any) -> str:
    text = str(value)
    for old, new in (
        ("\\", r"\textbackslash{}"),
        ("_", r"\_"),
        ("%", r"\%"),
        ("&", r"\&"),
        ("#", r"\#"),
    ):
        text = text.replace(old, new)
    return text


def _latex_table(rows: list[dict[str, Any]]) -> str:
    if not rows:
        return ""
    columns = list(rows[0])
    body = [
        r"\begin{longtable}{" + "l" * len(columns) + "}",
        " & ".join(_latex_escape(column) for column in columns) + r" \\ \hline",
    ]
    for row in rows:
        body.append(
            " & ".join(_latex_escape(row.get(column, "")) for column in columns)
            + r" \\"
        )
    body.append(r"\end{longtable}")
    return "\n".join(body)


def _report_markdown(
    experiment_id: str,
    summary_rows: list[dict[str, Any]],
    errors: list[dict[str, Any]],
    comparisons: list[dict[str, Any]],
    manifest: list[dict[str, str]],
    flow_layout_version: str | None,
    metric_guide_rows: list[dict[str, Any]],
    historical_artifacts: bool,
) -> str:
    error_count = sum(error["severity"] == "ERROR" for error in errors)
    warning_count = sum(error["severity"] == "WARNING" for error in errors)
    contrast_rows = [
        {
            "Contrast": row["contrast_id"],
            "Metric": row["metric_name"],
            "n": row["paired_sample_count"],
            "A": "N/A" if row["flow_a_value"] is None else f"{row['flow_a_value']:.3g}",
            "B": "N/A" if row["flow_b_value"] is None else f"{row['flow_b_value']:.3g}",
            "Difference": "N/A" if row["absolute_difference"] is None else f"{row['absolute_difference']:.3g}",
            "W/T/L": f"{row['flow_a_wins']}/{row['ties']}/{row['flow_b_wins']}",
        }
        for row in comparisons
        if row["metric_name"] == "Canonical E2E Rate"
    ]
    figures = "\n".join(
        f"- `{item['figure_id']}`: {item['caption']}" for item in manifest
    )
    one_shot_flow = (
        "F2 and derived F6"
        if flow_layout_version == FLOW_LAYOUT_VERSION
        else "F5"
    )
    one_shot_errors = sum(
        error["severity"] == "ERROR"
        and error["violated_rule"] == "RULE_1_ONESHOT_CONTRACT"
        for error in errors
    )
    multifactor_note = (
        "F1 vs F5 is the full-configuration versus Raw-IR baseline and is a "
        "multi-factor comparison, not a single-factor ablation."
        if flow_layout_version == FLOW_LAYOUT_VERSION
        else "F2 vs F3 is a multi-factor comparison, not a single-factor ablation."
    )
    historical_oracle_note = (
        """
- The historical tracker read the wrong provider token keys. This report reads
  token counts directly from per-call metadata.
- Historical prompt bodies, per-attempt latency/cost, exact compiler version,
  and most earlier raw fuzz reports were not persisted; these fields are null.
- The historical oracle replayed mismatches, but stderr comparison was not
  enabled globally, sample-specific policies existed, and the campaign used a
  Clean-IR-compiled reference rather than the mandated obfuscated binary.
  Consequently, behavioral rates are faithful summaries of the historical
  recorded oracle, not a retroactive strict-oracle claim.
"""
        if historical_artifacts
        else ""
    )
    return f"""# Six-flow source recovery evaluation

Experiment: `{experiment_id}`

This report was regenerated only from existing artifacts. It did not call the
LLM, compiler, or fuzzer. A behavioral PASS means: no reproducible final
divergence was detected within the recorded valid-input corpus and fuzzing
budget. It does not prove equivalence for every input.

**F6 provenance:** F6 is derived from the first actual provider call of each
F5 run. It is a paired one-call checkpoint, not an independent recovery run.
Missing first-call or first-campaign artifacts are marked CANCELLED.

## How to read the metrics

{_markdown_table(metric_guide_rows)}

Flow order: F1 Full; F2 no error context; F3 no pseudocode; F4 no direct
Clean IR; F5 Raw IR iterative; F6 Raw IR one-call derived from F5. F6 is not
an independent recovery run. Error bars in rate figures are 95% confidence
intervals. `n` is the number of eligible samples after data validation.

## Flow summary

{_markdown_table(summary_rows)}

`Canonical E2E` measures accepted recovery over all eligible samples. The
flow-specific rate remains available in machine-readable CSV output but is
omitted here because it is identical to Canonical E2E in this campaign.
Rate cells show `numerator/denominator (percentage)`. {one_shot_flow}
repair metrics are N/A because error context is disabled.

## Data validity and historical limitations

- Validation: {error_count} error(s), {warning_count} provenance warning(s).
- {one_shot_errors} run(s) violate the one-shot invariant and are excluded from
  eligible aggregates and paired inference.
{historical_oracle_note}
- Exact five-tuple comparison is implemented for schema-v2 observations.
- Readability is N/A because no evaluator record exists. SLOC Ratio is N/A when
  the required common `clang-format` tool is unavailable.
- LLVM reduction measures simplification only and is not a correctness oracle.

See `data_validation_errors.csv` for every affected paired key.

## Main paired contrasts (Canonical E2E)

{_markdown_table(contrast_rows)}

{multifactor_note} Statistical inference is marked underpowered when paired
n < 20; descriptive statistics are still emitted.

## Figures

{figures}
"""


def _html_document(title: str, body: str) -> str:
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>{html.escape(title)}</title>
<style>
body{{font:15px/1.5 system-ui,sans-serif;max-width:1500px;margin:auto;padding:2rem;color:#18212b}}
table{{border-collapse:collapse;width:100%;font-size:12px}}th,td{{border:1px solid #ccd3da;padding:.35rem;text-align:left}}
th{{background:#eef3f7;position:sticky;top:0}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(560px,1fr));gap:1.25rem}}
figure{{margin:0;border:1px solid #d9e0e6;padding:.8rem;background:white}}img{{max-width:100%}}figcaption{{font-weight:700;margin:.4rem 0 .65rem}}
.figure-guide{{background:#f7f9fb;border-left:4px solid #0072b2;padding:.55rem .7rem;font-size:13px}}.figure-guide p{{margin:.25rem 0}}
.derived-note{{background:#fff4d6;border-left:4px solid #e69f00;padding:.7rem .9rem;margin:1rem 0}}
code{{background:#eef3f7;padding:.1rem .25rem}}
@media(max-width:650px){{.grid{{grid-template-columns:1fr}}body{{padding:1rem}}}}
</style></head><body>{body}</body></html>"""


def export_report(data: dict[str, Any], report_dir: Path) -> dict[str, Any]:
    from evaluation.figures import generate_figures

    report_dir.mkdir(parents=True, exist_ok=True)
    # This directory is a generated artifact.  Remove stale plots and two
    # legacy visual-table files whose formulas predate schema v2, while leaving
    # the immutable campaign under result/ untouched.
    figure_dir = report_dir / "figures"
    if figure_dir.is_dir():
        for pattern in ("*.png", "*.svg", "*.pdf"):
            for path in figure_dir.glob(pattern):
                path.unlink()
    for obsolete in ("per_sample_visual_table.csv", "per_sample_visual_table.html"):
        obsolete_path = report_dir / obsolete
        if obsolete_path.is_file():
            obsolete_path.unlink()
    _materialize_counterexample_inputs(report_dir, data["counterexamples"])
    errors = validate_runs(data["runs"])
    flow_rows = aggregate_flows(data["runs"], errors, data["counterexamples"])
    stages = stage_completion_rows(data["runs"], errors)
    failures = failure_rows(
        data["runs"], data["compile_attempts"], data["counterexamples"]
    )
    comparisons, tests = paired_analysis(data["runs"], errors)
    summary_rows = _flow_summary(flow_rows)
    metric_guide_rows = [
        {
            "Metric": "First-pass RSR",
            "Meaning": "The first Candidate C compiled, linked, and created an executable.",
            "Denominator": "Samples that produced an initial candidate.",
        },
        {
            "Metric": "Final RSR@R",
            "Meaning": "At least one executable was created within the compile-repair budget.",
            "Denominator": "Samples that produced an initial candidate.",
        },
        {
            "Metric": "Program Behavioral Pass Rate",
            "Meaning": "The final candidate completed fuzzing with no reproducible final mismatch.",
            "Denominator": "Samples that completed behavioral validation; generation and compile failures are excluded.",
        },
        {
            "Metric": "Initial / Final Behavioral Pass",
            "Meaning": "Behavioral success before repair versus after the final repair round.",
            "Denominator": "Candidates that completed the corresponding behavioral validation.",
        },
        {
            "Metric": "Input Match Macro / Micro",
            "Meaning": "Average per-sample match rate / all matching valid inputs pooled together.",
            "Denominator": "Valid inputs executed on both reference and candidate.",
        },
        {
            "Metric": "Counterexample Detection Rate",
            "Meaning": "A reproducible divergence was found for the final candidate.",
            "Denominator": "Samples that completed behavioral validation.",
        },
        {
            "Metric": "Canonical E2E",
            "Meaning": "The complete canonical pipeline ended with an accepted behavioral PASS.",
            "Denominator": "All eligible samples, including generation and compile failures.",
        },
        {
            "Metric": "Repair Gain",
            "Meaning": "Final rate minus initial rate, measured in percentage points.",
            "Denominator": "N/A for F2 and F6 because error context and repair are disabled.",
        },
        {
            "Metric": "Mean Tokens / Runtime",
            "Meaning": "Average recorded LLM tokens and total execution time per run.",
            "Denominator": "Eligible runs with a recorded value.",
        },
    ]

    per_attempt = data["llm_attempts"] + data["compile_attempts"]
    write_csv(report_dir / "per_sample_results.csv", data["runs"])
    write_csv(report_dir / "per_attempt_results.csv", per_attempt)
    write_csv(report_dir / "per_flow_metrics.csv", flow_rows)
    write_csv(
        report_dir / "compilation_metrics.csv",
        flow_rows,
        [
            "flow_id",
            "eligible_sample_count",
            "initial_candidate_count",
            "first_compile_success_count",
            "first_pass_rsr_percent",
            "first_pass_rsr_ci_low",
            "first_pass_rsr_ci_high",
            "compile_success_within_budget_count",
            "final_rsr_percent",
            "final_rsr_ci_low",
            "final_rsr_ci_high",
            "compilation_repair_gain_pp",
            "compile_repair_case_count",
            "compile_repair_success_count",
            "compilation_repair_success_rate_percent",
            "compile_repair_budget_exhausted_count",
            "compile_repair_rounds_mean",
            "compile_repair_rounds_median",
            "compile_repair_rounds_stddev",
            "compile_repair_rounds_min",
            "compile_repair_rounds_p25",
            "compile_repair_rounds_p75",
            "compile_repair_rounds_max",
            "compiler_attempts_mean",
        ],
    )
    write_csv(
        report_dir / "behavioral_metrics.csv",
        flow_rows,
        [
            "flow_id",
            "completed_behavioral_validation_count",
            "behavioral_pass_count",
            "program_behavioral_pass_rate_percent",
            "initial_behavioral_validation_count",
            "initial_behavioral_pass_count",
            "initial_behavioral_pass_rate_percent",
            "final_behavioral_pass_rate_percent",
            "input_match_macro_percent",
            "input_match_micro_percent",
            "input_match_median_percent",
            "input_match_percent_bootstrap_ci_low",
            "input_match_percent_bootstrap_ci_high",
            "counterexample_sample_count",
            "counterexample_detection_rate_percent",
            "counterexample_ever_detected_rate_percent",
            "final_counterexample_rate_percent",
        ],
    )
    write_csv(
        report_dir / "repair_metrics.csv",
        flow_rows,
        ["flow_id"] + [key for key in flow_rows[0] if "repair" in key],
    )
    write_csv(
        report_dir / "reliability_metrics.csv",
        flow_rows,
        [
            "flow_id",
            "fuzz_generated_count",
            "fuzz_executed_on_both_count",
            "fuzz_valid_count",
            "valid_input_rate_percent",
            "executable_pair_execution_rate_percent",
            "counterexample_replay_count",
            "counterexample_replay_success_count",
            "counterexample_reproducibility_rate_percent",
            "inconclusive_count",
            "inconclusive_rate_percent",
        ],
    )
    write_csv(report_dir / "llvm_metrics.csv", data["llvm_samples"])
    write_csv(
        report_dir / "source_quality_metrics.csv",
        data["runs"],
        [
            "experiment_id",
            "sample_id",
            "flow_id",
            "repeat_id",
            "readability_variables",
            "readability_loops",
            "readability_conditions",
            "readability_logic_flow",
            "readability_structure",
            "readability_overall",
            "evaluator_id",
            "evaluation_method",
            "original_sloc",
            "recovered_sloc",
            "sloc_ratio",
        ],
    )
    cost_columns = [
        "experiment_id",
        "sample_id",
        "flow_id",
        "repeat_id",
        "llm_calls",
        "input_tokens",
        "output_tokens",
        "total_tokens",
        "estimated_api_cost",
        "llm_latency",
        "preprocessing_time",
        "compile_time",
        "fuzzing_time",
        "total_runtime",
        "time_to_first_candidate",
        "time_to_first_compilable_candidate",
        "time_to_first_behavioral_pass_candidate",
        "compiler_attempts",
        "compile_repair_rounds",
        "behavioral_repair_rounds",
        "counterexamples_used",
        "peak_memory",
        "cpu_time",
    ]
    write_csv(report_dir / "cost_metrics.csv", data["runs"], cost_columns)
    write_csv(report_dir / "stage_completion_metrics.csv", stages)
    write_csv(report_dir / "ablation_comparisons.csv", comparisons)
    write_csv(report_dir / "statistical_tests.csv", tests)
    write_csv(report_dir / "failure_breakdown.csv", failures)
    write_csv(report_dir / "counterexamples.csv", data["counterexamples"])
    write_csv(report_dir / "data_validation_errors.csv", errors)
    write_csv(report_dir / "flow_summary_table.csv", summary_rows)

    raw_path = report_dir / "raw_results.jsonl"
    with raw_path.open("w", encoding="utf-8") as handle:
        for record_type, records in (
            ("run", data["runs"]),
            ("llm_attempt", data["llm_attempts"]),
            ("compile_attempt", data["compile_attempts"]),
            ("fuzz_campaign", data["campaigns"]),
            ("counterexample", data["counterexamples"]),
        ):
            for record in records:
                payload = {**record, "record_type": record_type}
                handle.write(json.dumps(payload, ensure_ascii=False, default=str) + "\n")

    manifest = generate_figures(
        report_dir / "figures",
        data["runs"],
        flow_rows,
        stages,
        failures,
        comparisons,
        data["llvm_samples"],
        data["compile_attempts"],
        data["campaigns"],
    )
    (report_dir / "figures_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    layout_versions = {
        run.get("flow_layout_version")
        for run in data["runs"]
        if run.get("flow_layout_version")
    }
    flow_layout_version = (
        next(iter(layout_versions))
        if len(layout_versions) == 1
        else FLOW_LAYOUT_VERSION
        if not layout_versions
        else None
    )
    historical_artifacts = any(
        run.get("source_flow_layout_version")
        and run.get("source_flow_layout_version") != FLOW_LAYOUT_VERSION
        for run in data["runs"]
    )
    markdown = _report_markdown(
        data["experiment_id"],
        summary_rows,
        errors,
        comparisons,
        manifest,
        flow_layout_version,
        metric_guide_rows,
        historical_artifacts,
    )
    (report_dir / "report.md").write_text(markdown, encoding="utf-8")
    (report_dir / "flow_summary_table.md").write_text(
        _markdown_table(summary_rows) + "\n", encoding="utf-8"
    )
    latex_table = _latex_table(summary_rows)
    (report_dir / "flow_summary_table.tex").write_text(
        latex_table + "\n", encoding="utf-8"
    )
    latex = (
        r"\documentclass{article}" "\n"
        r"\usepackage[margin=1in]{geometry}" "\n"
        r"\usepackage{longtable,graphicx}" "\n"
        r"\begin{document}" "\n"
        r"\section*{Six-flow source recovery evaluation}" "\n"
        + _latex_escape(
            "PASS means no reproducible final divergence was detected within the recorded valid inputs and budget; it is not a universal equivalence proof."
        )
        + "\n"
        + latex_table
        + "\n"
        + "\n".join(
            r"\begin{figure}[p]\centering\includegraphics[width=.9\linewidth]{figures/"
            + item["figure_id"]
            + r".pdf}\caption{"
            + _latex_escape(item["caption"])
            + r"}\end{figure}"
            for item in manifest
        )
        + "\n"
        + r"\end{document}"
        + "\n"
    )
    (report_dir / "report.tex").write_text(latex, encoding="utf-8")
    metric_guide_html = "<table><thead><tr>" + "".join(
        f"<th>{html.escape(column)}</th>" for column in metric_guide_rows[0]
    ) + "</tr></thead><tbody>" + "".join(
        "<tr>" + "".join(
            f"<td>{html.escape(str(row[column]))}</td>"
            for column in metric_guide_rows[0]
        ) + "</tr>"
        for row in metric_guide_rows
    ) + "</tbody></table>"
    table_html = "<table><thead><tr>" + "".join(
        f"<th>{html.escape(column)}</th>" for column in summary_rows[0]
    ) + "</tr></thead><tbody>" + "".join(
        "<tr>" + "".join(
            f"<td>{html.escape(str(row[column]))}</td>" for column in summary_rows[0]
        ) + "</tr>" for row in summary_rows
    ) + "</tbody></table>"
    figure_cards: list[str] = []
    for item in manifest:
        guide = FIGURE_GUIDES[item["figure_id"]]
        figure_cards.append(
            f"<figure>"
            f"<img src=\"figures/{item['figure_id']}.png\" "
            f"alt=\"{html.escape(item['caption'])}\">"
            f"<figcaption>{html.escape(item['caption'])}</figcaption>"
            f"<div class=\"figure-guide\">"
            f"<p><b>Ý nghĩa:</b> {html.escape(guide['meaning'])}</p>"
            f"<p><b>Cách tính:</b> {html.escape(guide['calculation'])}</p>"
            f"<p><b>Cách đọc:</b> {html.escape(guide['reading'])}</p>"
            f"</div></figure>"
        )
    figures_html = '<div class="grid">' + "".join(figure_cards) + "</div>"
    report_html = _html_document(
        data["experiment_id"],
        f"<h1>Six-flow source recovery evaluation</h1><p>Offline regeneration; no LLM or fuzzing was executed.</p><div class=\"derived-note\"><b>F6 provenance:</b> F6 is derived from the first actual provider call of each F5 run. It is a paired one-call checkpoint, not an independent recovery run. Missing first-call or first-campaign artifacts are marked CANCELLED rather than guessed.</div><h2>How to read the metrics</h2>{metric_guide_html}<p><b>Flow order:</b> F1 Full; F2 no error context; F3 no pseudocode; F4 no direct Clean IR; F5 Raw IR iterative; F6 Raw IR one-call derived from F5. Error bars are 95% confidence intervals, and <code>n</code> is the eligible sample count after validation.</p><h2>Flow summary</h2>{table_html}<h2>Figures</h2>{figures_html}",
    )
    (report_dir / "report.html").write_text(report_html, encoding="utf-8")
    (report_dir / "dashboard.html").write_text(report_html, encoding="utf-8")

    experiment_summary = {
        "schema_version": data["schema_version"],
        "experiment_id": data["experiment_id"],
        "campaign_dir": data["campaign_dir"],
        "run_count": len(data["runs"]),
        "independent_run_count": sum(
            run.get("independent_run", True) is not False
            for run in data["runs"]
        ),
        "derived_run_count": sum(
            run.get("independent_run") is False for run in data["runs"]
        ),
        "sample_count": len({run["sample_id"] for run in data["runs"]}),
        "flow_metrics": flow_rows,
        "validation": {
            "error_count": sum(error["severity"] == "ERROR" for error in errors),
            "warning_count": sum(error["severity"] == "WARNING" for error in errors),
        },
        "tool_versions": data["tool_versions"],
        "git_commit": data["git_commit"],
        "regenerated_without_llm_or_fuzzing": True,
        "null_policy": "Unknown or undefined values are null in JSON and empty in CSV.",
    }
    (report_dir / "experiment_summary.json").write_text(
        json.dumps(experiment_summary, indent=2, ensure_ascii=False, default=str),
        encoding="utf-8",
    )
    return {
        "flow_rows": flow_rows,
        "validation_errors": errors,
        "comparisons": comparisons,
        "tests": tests,
        "manifest": manifest,
    }
