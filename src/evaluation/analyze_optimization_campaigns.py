#!/usr/bin/env python3
"""Aggregate frozen B0/B1/B2/B3 and paired F3 O1/O2/O3 campaigns."""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
import re
import statistics
from collections import Counter, defaultdict
from itertools import combinations
from pathlib import Path
from typing import Any, Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[2]
STATUS_ORDER = ("PASS", "FAIL_COMPILE", "FAIL_BEHAVIORAL", "INCONCLUSIVE")


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _campaign_path(value: str) -> Path:
    path = Path(value)
    if not path.is_absolute():
        direct = (PROJECT_ROOT / path).resolve()
        path = direct if direct.is_dir() else (PROJECT_ROOT / "result" / value).resolve()
    if not path.is_dir():
        raise FileNotFoundError(f"Campaign directory not found: {path}")
    return path


def _load_flow(campaign: Path, flow_id: str) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}
    for path in sorted(campaign.glob(f"*/{flow_id}/flow_result.json")):
        payload = _read_json(path)
        sample_id = str(payload["sample_id"])
        if sample_id in records:
            raise RuntimeError(f"Duplicate {flow_id} result for {sample_id}")
        payload["artifact_dir"] = str(path.parent)
        records[sample_id] = payload
    return records


def _wilson(successes: int, total: int) -> tuple[float | None, float | None]:
    if total == 0:
        return None, None
    z = 1.959963984540054
    p = successes / total
    denominator = 1 + z * z / total
    centre = (p + z * z / (2 * total)) / denominator
    half = z * math.sqrt(p * (1 - p) / total + z * z / (4 * total * total)) / denominator
    return centre - half, centre + half


def _mcnemar_exact(left_only: int, right_only: int) -> float:
    discordant = left_only + right_only
    if discordant == 0:
        return 1.0
    tail = sum(
        math.comb(discordant, index) for index in range(min(left_only, right_only) + 1)
    ) / (2**discordant)
    return min(1.0, 2 * tail)


def _paired_bootstrap_ci(
    left: list[int], right: list[int], *, repetitions: int = 20_000
) -> tuple[float, float]:
    if not left or len(left) != len(right):
        return 0.0, 0.0
    rng = random.Random(260815)
    deltas = []
    for _ in range(repetitions):
        indexes = [rng.randrange(len(left)) for _ in left]
        deltas.append(
            sum(right[index] - left[index] for index in indexes) / len(indexes)
        )
    deltas.sort()
    return deltas[int(0.025 * repetitions)], deltas[int(0.975 * repetitions)]


def _status(record: dict[str, Any]) -> str:
    value = str(record.get("status") or "INCONCLUSIVE")
    return value if value in STATUS_ORDER else "INCONCLUSIVE"


def _flow_summary(label: str, records: dict[str, dict[str, Any]]) -> dict[str, Any]:
    count = len(records)
    passes = sum(_status(record) == "PASS" for record in records.values())
    total_calls = sum(int(record.get("llm_calls", 0) or 0) for record in records.values())
    total_input_tokens = sum(
        int(record.get("input_tokens", 0) or 0) for record in records.values()
    )
    total_output_tokens = sum(
        int(record.get("output_tokens", 0) or 0) for record in records.values()
    )
    total_runtime = sum(
        float(record.get("total_runtime", 0) or 0) for record in records.values()
    )
    lower, upper = _wilson(passes, count)
    return {
        "treatment": label,
        "n": count,
        "pass_count": passes,
        "pass_rate": passes / count if count else None,
        "pass_rate_ci95_low": lower,
        "pass_rate_ci95_high": upper,
        "statuses": dict(Counter(_status(record) for record in records.values())),
        "total_llm_calls": total_calls,
        "mean_llm_calls": total_calls / count if count else None,
        "total_input_tokens": total_input_tokens,
        "mean_input_tokens": total_input_tokens / count if count else None,
        "total_output_tokens": total_output_tokens,
        "mean_output_tokens": total_output_tokens / count if count else None,
        "total_runtime_seconds": total_runtime,
        "mean_runtime_seconds": total_runtime / count if count else None,
    }


def _paired_summary(
    left_label: str,
    right_label: str,
    left: dict[str, dict[str, Any]],
    right: dict[str, dict[str, Any]],
    case_ids: list[str],
) -> dict[str, Any]:
    left_values = [int(_status(left[case_id]) == "PASS") for case_id in case_ids]
    right_values = [int(_status(right[case_id]) == "PASS") for case_id in case_ids]
    left_only = sum(a == 1 and b == 0 for a, b in zip(left_values, right_values))
    right_only = sum(a == 0 and b == 1 for a, b in zip(left_values, right_values))
    ci_low, ci_high = _paired_bootstrap_ci(left_values, right_values)
    transitions = Counter(
        f"{_status(left[case_id])}->{_status(right[case_id])}" for case_id in case_ids
    )
    return {
        "comparison": f"{left_label}_vs_{right_label}",
        "n": len(case_ids),
        "left_pass_right_fail": left_only,
        "left_fail_right_pass": right_only,
        "paired_pass_rate_delta": (
            sum(right_values) - sum(left_values)
        ) / len(case_ids),
        "paired_delta_ci95_low": ci_low,
        "paired_delta_ci95_high": ci_high,
        "mcnemar_exact_p": _mcnemar_exact(left_only, right_only),
        "status_transitions": dict(sorted(transitions.items())),
    }


def _ir_counts(path: Path) -> dict[str, int]:
    instructions = blocks = branches = 0
    in_function = False
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        text = line.strip()
        if not text or text.startswith(";"):
            continue
        if text.startswith("define "):
            in_function = True
            blocks += 1
        elif text == "}":
            in_function = False
        elif in_function and re.match(r"^[A-Za-z0-9_%.$-]+:\s*(?:;.*)?$", text):
            blocks += 1
        elif in_function:
            instructions += 1
            if text.startswith("br i1") or text.startswith("switch"):
                branches += 1
    return {"instructions": instructions, "blocks": blocks, "branches": branches}


def _stage_metrics(campaign: Path, case_ids: Iterable[str]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    suffixes = (
        ("raw_lift", ".ll"),
        ("brightened_010_095", "_brightened.ll"),
        ("verified_input", "_final.01-verified-input.ll"),
        ("pointer_opt", "_final.02-pointer-opt.ll"),
        ("standard_opt", "_final.03-storage-delift.ll"),
        ("storage_delift", "_final.04-storage-o3.ll"),
        ("residual_strip", "_final.05-unpinned.ll"),
        ("final_clean", "_final.ll"),
    )
    for case_id in case_ids:
        case_dir = campaign / case_id
        for stage, suffix in suffixes:
            path = case_dir / f"{case_id}{suffix}"
            if path.is_file():
                rows.append({"sample_id": case_id, "stage": stage, **_ir_counts(path)})
    return rows


def _failure_reason(record: dict[str, Any]) -> str:
    artifact_dir = Path(str(record.get("artifact_dir", "")))
    failure = artifact_dir / "failure.json"
    if failure.is_file():
        payload = _read_json(failure)
        return f"{payload.get('type', 'ERROR')}: {payload.get('message', '')}"
    compile_records = sorted(artifact_dir.glob("recovery_iter*.compile.json"))
    if compile_records:
        payload = _read_json(compile_records[-1])
        if payload.get("failure_category"):
            return str(payload["failure_category"])
    return _status(record)


def _write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    fields = list(rows[0])
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def _mean_stage(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        grouped[str(row["stage"])].append(row)
    output = []
    for stage, selected in grouped.items():
        output.append({
            "stage": stage,
            "n": len(selected),
            "mean_instructions": statistics.fmean(row["instructions"] for row in selected),
            "mean_blocks": statistics.fmean(row["blocks"] for row in selected),
            "mean_conditional_branches": statistics.fmean(row["branches"] for row in selected),
        })
    return output


def _fuzz_trajectory(artifact_dir: Path) -> str:
    """Return every completed behavioral check in physical iteration order."""
    rows = []
    paths = sorted(
        artifact_dir.glob("recovery_iter*.fuzz.json"),
        key=lambda path: int(re.search(r"iter(\d+)", path.name).group(1)),
    )
    for path in paths:
        payload = _read_json(path)
        iteration = int(re.search(r"iter(\d+)", path.name).group(1))
        rows.append(
            f"i{iteration}:{int(payload.get('matches', 0) or 0)}/"
            f"{int(payload.get('mismatches', 0) or 0)}/"
            f"{int(payload.get('inconclusive', 0) or 0)}"
        )
    return ";".join(rows)


def _has_validation_feedback_round(artifact_dir: Path) -> bool:
    """Whether a later logical iteration received validation feedback.

    Iteration-1 MAX_TOKENS retries are physical provider calls but are not
    compiler/fuzzer feedback.  A persisted iteration-2-or-later prompt is the
    auditable boundary used here because every such prompt is produced only
    after parser, compiler, or behavioral validation rejected a candidate.
    """
    return any(artifact_dir.glob("recovery_iter[2-9].prompt.txt"))


def _iteration_outcome(artifact_dir: Path, iteration: int) -> str:
    """Return the most specific auditable outcome for one recovery iteration."""
    prefix = artifact_dir / f"recovery_iter{iteration}"
    parse_path = prefix.with_suffix(".parse.txt")
    if parse_path.is_file():
        message = " ".join(
            parse_path.read_text(encoding="utf-8", errors="replace").split()
        )
        classifications = (
            ("missing a real int main", "REJECT_MISSING_MAIN"),
            ("undefined-width type", "REJECT_UNDEFINED_WIDTH"),
            ("import-thunk pointer", "REJECT_IMPORT_THUNK"),
            ("processEntry type", "REJECT_PROCESS_ENTRY"),
            ("unbalanced C syntax", "REJECT_UNBALANCED_SYNTAX"),
        )
        for needle, label in classifications:
            if needle in message:
                return label
        return f"REJECT_OTHER: {message[:240]}"
    compile_path = prefix.with_suffix(".compile.json")
    if compile_path.is_file():
        compile_result = _read_json(compile_path)
        if not compile_result.get("compile_success"):
            return f"COMPILE_{compile_result.get('failure_category') or 'FAIL'}"
    fuzz_path = prefix.with_suffix(".fuzz.json")
    if fuzz_path.is_file():
        fuzz = _read_json(fuzz_path)
        return (
            f"FUZZ_{int(fuzz.get('matches', 0) or 0)}/"
            f"{int(fuzz.get('mismatches', 0) or 0)}/"
            f"{int(fuzz.get('inconclusive', 0) or 0)}"
        )
    if prefix.with_suffix(".max_tokens.response.txt").is_file():
        return "MAX_TOKENS"
    return "NO_COMPLETED_VALIDATION"


def _b1_control_audit(
    baseline: Path, b1_campaign: Path, case_ids: Iterable[str]
) -> dict[str, int]:
    """Verify the three frozen controls that make B0/B1 interpretable."""
    counts = {
        "cases": 0,
        "prompt_byte_identical": 0,
        "representation_byte_identical": 0,
        "empty_initial_system": 0,
        "first_response_byte_identical": 0,
        "missing_control_artifacts": 0,
    }
    for case_id in case_ids:
        counts["cases"] += 1
        b0_dir = baseline / case_id / "B0"
        b1_dir = b1_campaign / case_id / "B1"
        paths = {
            "b0_prompt": b0_dir / "request.prompt.txt",
            "b1_prompt": b1_dir / "recovery_iter1.prompt.txt",
            "b0_representation": b0_dir / "representation/ghidra_original_program.c",
            "b1_representation": b1_dir / "representation/ghidra_original_program.c",
            "b1_system": b1_dir / "recovery_iter1.system.txt",
            "b0_response": b0_dir / "response.txt",
            "b1_response": b1_dir / "recovery_iter1.response.txt",
        }
        if not all(path.is_file() for path in paths.values()):
            counts["missing_control_artifacts"] += 1
            continue
        if paths["b0_prompt"].read_bytes() == paths["b1_prompt"].read_bytes():
            counts["prompt_byte_identical"] += 1
        if (
            paths["b0_representation"].read_bytes()
            == paths["b1_representation"].read_bytes()
        ):
            counts["representation_byte_identical"] += 1
        if paths["b1_system"].stat().st_size == 0:
            counts["empty_initial_system"] += 1
        if paths["b0_response"].read_bytes() == paths["b1_response"].read_bytes():
            counts["first_response_byte_identical"] += 1
    return counts


def _b23_control_audit(
    campaign: Path, case_ids: Iterable[str]
) -> dict[str, int]:
    """Verify that B2/B3 differ only by permission to consume feedback."""
    counts = {
        "cases": 0,
        "prompt_byte_identical": 0,
        "representation_byte_identical": 0,
        "empty_b2_initial_system": 0,
        "empty_b3_initial_system": 0,
        "first_response_byte_identical": 0,
        "missing_control_artifacts": 0,
    }
    for case_id in case_ids:
        counts["cases"] += 1
        b2_dir = campaign / case_id / "B2"
        b3_dir = campaign / case_id / "B3"
        paths = {
            "b2_prompt": b2_dir / "recovery_iter1.prompt.txt",
            "b3_prompt": b3_dir / "recovery_iter1.prompt.txt",
            "b2_representation": b2_dir / "representation/objdump_original_program.s",
            "b3_representation": b3_dir / "representation/objdump_original_program.s",
            "b2_system": b2_dir / "recovery_iter1.system.txt",
            "b3_system": b3_dir / "recovery_iter1.system.txt",
            "b2_response": b2_dir / "recovery_iter1.response.txt",
            "b3_response": b3_dir / "recovery_iter1.response.txt",
        }
        if not all(path.is_file() for path in paths.values()):
            counts["missing_control_artifacts"] += 1
            continue
        if paths["b2_prompt"].read_bytes() == paths["b3_prompt"].read_bytes():
            counts["prompt_byte_identical"] += 1
        if (
            paths["b2_representation"].read_bytes()
            == paths["b3_representation"].read_bytes()
        ):
            counts["representation_byte_identical"] += 1
        if paths["b2_system"].stat().st_size == 0:
            counts["empty_b2_initial_system"] += 1
        if paths["b3_system"].stat().st_size == 0:
            counts["empty_b3_initial_system"] += 1
        if paths["b2_response"].read_bytes() == paths["b3_response"].read_bytes():
            counts["first_response_byte_identical"] += 1
    return counts


def _pass095_summary(campaign: Path, case_ids: Iterable[str]) -> dict[str, Any]:
    summary: dict[str, Any] = {
        "reports": 0,
        "z3": {"queries": 0, "proved": 0, "disproved": 0, "unknown": 0},
        "stages": {},
    }
    for case_id in case_ids:
        paths = sorted(campaign.joinpath(case_id).glob("*_brightened.095.json"))
        if not paths:
            continue
        payload = _read_json(paths[-1])
        summary["reports"] += 1
        for field in ("queries", "proved", "disproved", "unknown"):
            summary["z3"][field] += int((payload.get("z3") or {}).get(field, 0) or 0)
        for stage, values in (payload.get("stages") or {}).items():
            target = summary["stages"].setdefault(
                stage, {"candidates": 0, "changes": 0, "unresolved": 0}
            )
            for field in ("candidates", "changes", "unresolved"):
                target[field] += int(values.get(field, 0) or 0)
    return summary


def _native_summary(rows: list[dict[str, Any]], label: str) -> dict[str, Any]:
    selected = [row for row in rows if row["treatment"] == label]
    violations = [int(row["violations"] or 0) for row in selected]
    return {
        "reports": len(selected),
        "status_counts": dict(Counter(row["status"] for row in selected)),
        "output_class_counts": dict(Counter(row["output_class"] for row in selected)),
        "mean_violations": statistics.fmean(violations) if violations else None,
        "min_violations": min(violations) if violations else None,
        "max_violations": max(violations) if violations else None,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True)
    parser.add_argument(
        "--b1",
        help="Optional Ghidra-pseudocode iterative feedback-policy ablation",
    )
    parser.add_argument(
        "--b23",
        help="Optional paired raw-assembly one-shot/iterative campaign",
    )
    parser.add_argument("--o1", required=True)
    parser.add_argument("--o2", required=True)
    parser.add_argument("--o3", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--dataset-manifest", default="data/own_dataset/manifest.json"
    )
    args = parser.parse_args()

    campaigns = {"B0": _campaign_path(args.baseline)}
    if args.b1:
        campaigns["B1"] = _campaign_path(args.b1)
    if args.b23:
        campaigns["B2"] = _campaign_path(args.b23)
        campaigns["B3"] = campaigns["B2"]
    campaigns.update({
        "F3-O1": _campaign_path(args.o1),
        "F3-O2": _campaign_path(args.o2),
        "F3-O3": _campaign_path(args.o3),
    })
    records = {"B0": _load_flow(campaigns["B0"], "B0")}
    if "B1" in campaigns:
        records["B1"] = _load_flow(campaigns["B1"], "B1")
    if "B2" in campaigns:
        records["B2"] = _load_flow(campaigns["B2"], "B2")
        records["B3"] = _load_flow(campaigns["B3"], "B3")
    records.update({
        "F3-O1": _load_flow(campaigns["F3-O1"], "F3"),
        "F3-O2": _load_flow(campaigns["F3-O2"], "F3"),
        "F3-O3": _load_flow(campaigns["F3-O3"], "F3"),
    })
    case_sets = {label: set(items) for label, items in records.items()}
    if len({frozenset(values) for values in case_sets.values()}) != 1:
        raise RuntimeError(f"Campaigns are not paired on identical cases: {case_sets}")
    case_ids = sorted(next(iter(case_sets.values())))

    manifest_path = (PROJECT_ROOT / args.dataset_manifest).resolve()
    dataset = _read_json(manifest_path)
    categories = {
        str(case["case_id"]): str(case["category"]) for case in dataset["cases"]
    }
    if set(case_ids) - set(categories):
        raise RuntimeError("Dataset manifest does not cover every campaign case")

    output = (PROJECT_ROOT / args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    flow_summaries = [_flow_summary(label, records[label]) for label in records]
    comparisons = []
    for left, right in combinations(records, 2):
        comparisons.append(
            _paired_summary(left, right, records[left], records[right], case_ids)
        )

    category_rows = []
    category_diagnostic_rows = []
    for category in sorted(set(categories.values())):
        selected = [case_id for case_id in case_ids if categories[case_id] == category]
        for label in records:
            selected_records = [records[label][case_id] for case_id in selected]
            passed = sum(_status(record) == "PASS" for record in selected_records)
            category_rows.append({
                "category": category,
                "treatment": label,
                "n": len(selected),
                "pass_count": passed,
                "pass_rate": passed / len(selected),
            })
            category_diagnostic_rows.append({
                "category": category,
                "treatment": label,
                "n": len(selected),
                "pass_count": passed,
                "one_request_passes": sum(
                    _status(record) == "PASS"
                    and int(record.get("llm_calls", 0) or 0) == 1
                    for record in selected_records
                ),
                "feedback_assisted_passes": sum(
                    _status(record) == "PASS"
                    and _has_validation_feedback_round(
                        Path(str(record.get("artifact_dir", "")))
                    )
                    for record in selected_records
                ),
                "compile_repair_rounds": sum(
                    int(record.get("compile_repair_rounds", 0) or 0)
                    for record in selected_records
                ),
                "behavioral_repair_rounds": sum(
                    int(record.get("behavioral_repair_rounds", 0) or 0)
                    for record in selected_records
                ),
                "mean_llm_calls": statistics.fmean(
                    int(record.get("llm_calls", 0) or 0)
                    for record in selected_records
                ),
                "mean_input_tokens": statistics.fmean(
                    int(record.get("input_tokens", 0) or 0)
                    for record in selected_records
                ),
                "mean_output_tokens": statistics.fmean(
                    int(record.get("output_tokens", 0) or 0)
                    for record in selected_records
                ),
            })

    case_rows = []
    for case_id in case_ids:
        row: dict[str, Any] = {"sample_id": case_id, "category": categories[case_id]}
        for label in records:
            record = records[label][case_id]
            prefix = label.lower().replace("-", "_")
            row[f"{prefix}_status"] = _status(record)
            row[f"{prefix}_llm_calls"] = int(record.get("llm_calls", 0) or 0)
            row[f"{prefix}_failure_reason"] = _failure_reason(record)
        case_rows.append(row)

    stage_by_treatment: dict[str, list[dict[str, Any]]] = {}
    native_rows = []
    prepared_binary_validation = {}
    prepared_case_status: dict[str, dict[str, str]] = {}
    pass095_summaries = {}
    f3_labels = tuple(label for label in records if label.startswith("F3-"))
    iterative_labels = tuple(
        label
        for label in records
        if label in {"B1", "B3"} or label.startswith("F3-")
    )
    for label in f3_labels:
        stage_rows = _stage_metrics(campaigns[label], case_ids)
        stage_by_treatment[label] = _mean_stage(stage_rows)
        pass095_summaries[label] = _pass095_summary(campaigns[label], case_ids)
        for row in stage_rows:
            row["treatment"] = label
        _write_csv(output / f"stage_metrics_{label.lower()}.csv", stage_rows)
        for case_id in case_ids:
            reports = sorted(campaigns[label].joinpath(case_id).glob("*_final_native_contract_report.json"))
            if reports:
                report = _read_json(reports[-1])
                native_rows.append({
                    "sample_id": case_id,
                    "treatment": label,
                    "status": report.get("status"),
                    "output_class": report.get("output_class"),
                    "violations": (report.get("metrics") or {}).get("native_contract_violations"),
                })
        validation_path = campaigns[label] / "prepared_binary_validation.json"
        if validation_path.is_file():
            validation = _read_json(validation_path)
            prepared_binary_validation[label] = validation.get("counts", {})
            prepared_case_status[label] = {
                str(row["sample_id"]): str(row["status"])
                for row in validation.get("cases", [])
            }

    native_lookup = {
        (str(row["sample_id"]), str(row["treatment"])): row for row in native_rows
    }
    detailed_case_rows = []
    for case_id in case_ids:
        for label, treatment_records in records.items():
            record = treatment_records[case_id]
            artifact_dir = Path(str(record.get("artifact_dir", "")))
            native = native_lookup.get((case_id, label), {})
            detailed_case_rows.append({
                "sample_id": case_id,
                "category": categories[case_id],
                "treatment": label,
                "status": _status(record),
                "failure_reason": _failure_reason(record),
                "llm_calls": int(record.get("llm_calls", 0) or 0),
                "input_tokens": int(record.get("input_tokens", 0) or 0),
                "output_tokens": int(record.get("output_tokens", 0) or 0),
                "total_runtime_seconds": float(record.get("total_runtime", 0) or 0),
                "compile_success_first": record.get("compile_success_first"),
                "compile_success_final": record.get("compile_success_final"),
                "iteration1_outcome": _iteration_outcome(artifact_dir, 1),
                "compiler_attempts": int(record.get("compiler_attempts", 0) or 0),
                "compile_repair_rounds": int(record.get("compile_repair_rounds", 0) or 0),
                "behavioral_repair_rounds": int(record.get("behavioral_repair_rounds", 0) or 0),
                "behavior_before_repair": record.get("behavior_before_repair", ""),
                "behavior_after_repair": record.get("behavior_after_repair", ""),
                "fuzz_total": int(record.get("fuzz_total", 0) or 0),
                "fuzz_matches": int(record.get("fuzz_matches", 0) or 0),
                "fuzz_trajectory_matches_mismatches_inconclusive": _fuzz_trajectory(artifact_dir),
                "max_tokens_responses": sum(
                    1 for _ in artifact_dir.glob("recovery_iter*.max_tokens.response.txt")
                ),
                "instructions_raw": int(record.get("instructions_raw", 0) or 0),
                "instructions_clean": int(record.get("instructions_clean", 0) or 0),
                "instruction_reduction": record.get("instruction_reduction"),
                "basic_blocks_raw": int(record.get("basic_blocks_raw", 0) or 0),
                "basic_blocks_clean": int(record.get("basic_blocks_clean", 0) or 0),
                "bb_reduction": record.get("bb_reduction"),
                "conditional_branches_raw": int(record.get("conditional_branches_raw", 0) or 0),
                "conditional_branches_clean": int(record.get("conditional_branches_clean", 0) or 0),
                "branches_reduction": record.get("branches_reduction"),
                "prepared_binary_status": prepared_case_status.get(label, {}).get(case_id, ""),
                "native_contract_status": native.get("status", ""),
                "native_output_class": native.get("output_class", ""),
                "native_contract_violations": native.get("violations", ""),
            })

    multi_call_passes = {}
    feedback_assisted_passes = {}
    max_tokens_retry_responses = {}
    for label in iterative_labels:
        multi_call_passes[label] = sum(
            _status(record) == "PASS" and int(record.get("llm_calls", 0) or 0) > 1
            for record in records[label].values()
        )
        feedback_assisted_passes[label] = sum(
            _status(record) == "PASS"
            and _has_validation_feedback_round(
                Path(str(record.get("artifact_dir", "")))
            )
            for record in records[label].values()
        )
        max_tokens_retry_responses[label] = sum(
            1
            for record in records[label].values()
            for _ in Path(str(record.get("artifact_dir", ""))).glob(
                "recovery_iter*.max_tokens.response.txt"
            )
        )

    b1_control_audit = None
    if "B1" in campaigns:
        b1_control_audit = _b1_control_audit(
            campaigns["B0"], campaigns["B1"], case_ids
        )
        required_controls = (
            "prompt_byte_identical",
            "representation_byte_identical",
            "empty_initial_system",
        )
        if (
            b1_control_audit["missing_control_artifacts"]
            or any(
                b1_control_audit[field] != b1_control_audit["cases"]
                for field in required_controls
            )
        ):
            raise RuntimeError(f"B1 control audit failed: {b1_control_audit}")

    b23_control_audit = None
    if "B2" in campaigns:
        b23_control_audit = _b23_control_audit(campaigns["B2"], case_ids)
        required_controls = (
            "prompt_byte_identical",
            "representation_byte_identical",
            "empty_b2_initial_system",
            "empty_b3_initial_system",
        )
        if (
            b23_control_audit["missing_control_artifacts"]
            or any(
                b23_control_audit[field] != b23_control_audit["cases"]
                for field in required_controls
            )
        ):
            raise RuntimeError(f"B2/B3 control audit failed: {b23_control_audit}")

    result = {
        "schema_version": 2,
        "campaigns": {label: str(path) for label, path in campaigns.items()},
        "dataset_manifest": str(manifest_path),
        "paired_case_count": len(case_ids),
        "flow_summaries": flow_summaries,
        "paired_comparisons": comparisons,
        "stage_means": stage_by_treatment,
        "pass095_summaries": pass095_summaries,
        "passes_requiring_multiple_physical_calls": multi_call_passes,
        "feedback_assisted_passes": feedback_assisted_passes,
        "max_tokens_retry_responses": max_tokens_retry_responses,
        "b1_control_audit": b1_control_audit,
        "b23_control_audit": b23_control_audit,
        "prepared_binary_validation": prepared_binary_validation,
        "native_contract_counts": dict(Counter(row["output_class"] for row in native_rows)),
        "native_contract_by_treatment": {
            label: _native_summary(native_rows, label)
            for label in f3_labels
        },
    }
    (output / "final_analysis.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    _write_csv(output / "flow_summary.csv", flow_summaries)
    _write_csv(output / "paired_comparisons.csv", comparisons)
    _write_csv(output / "category_results.csv", category_rows)
    _write_csv(output / "category_diagnostics.csv", category_diagnostic_rows)
    _write_csv(output / "per_case_matrix.csv", case_rows)
    _write_csv(output / "per_case_diagnostics.csv", detailed_case_rows)
    _write_csv(output / "native_contract_results.csv", native_rows)

    best = max(
        (row for row in flow_summaries if row["treatment"].startswith("F3-")),
        key=lambda row: (row["pass_rate"], -row["mean_llm_calls"]),
    )
    baseline = flow_summaries[0]
    best_comparison = next(
        row for row in comparisons if row["comparison"] == f"B0_vs_{best['treatment']}"
    )
    b1_summary = next(
        (row for row in flow_summaries if row["treatment"] == "B1"), None
    )
    b1_comparison = next(
        (row for row in comparisons if row["comparison"] == "B0_vs_B1"), None
    )
    b1_result = ""
    b1_ablation_line = ""
    if b1_summary and b1_comparison:
        b1_result = (
            f"- B1 passed {b1_summary['pass_count']}/{b1_summary['n']} cases "
            f"({b1_summary['pass_rate']:.1%}); the paired gain over B0 was "
            f"{b1_comparison['paired_pass_rate_delta']:.1%} "
            f"(95% CI {b1_comparison['paired_delta_ci95_low']:.1%} to "
            f"{b1_comparison['paired_delta_ci95_high']:.1%}; exact McNemar "
            f"p={b1_comparison['mcnemar_exact_p']:.4g}).\n"
        )
        b1_ablation_line = (
            "- B1 is the feedback-policy ablation: it preserves B0's Ghidra "
            "representation and byte-identical first request, then permits "
            "validation-guided repair.\n"
        )
    b2_summary = next(
        (row for row in flow_summaries if row["treatment"] == "B2"), None
    )
    b3_summary = next(
        (row for row in flow_summaries if row["treatment"] == "B3"), None
    )
    b23_comparison = next(
        (row for row in comparisons if row["comparison"] == "B2_vs_B3"), None
    )
    b23_result = ""
    if b2_summary and b3_summary and b23_comparison:
        b23_result = (
            f"- B2 raw assembly one-shot passed {b2_summary['pass_count']}/"
            f"{b2_summary['n']} ({b2_summary['pass_rate']:.1%}); B3 raw "
            f"assembly plus validation loop passed {b3_summary['pass_count']}/"
            f"{b3_summary['n']} ({b3_summary['pass_rate']:.1%}). Their paired "
            f"delta was {b23_comparison['paired_pass_rate_delta']:.1%} "
            f"(95% CI {b23_comparison['paired_delta_ci95_low']:.1%} to "
            f"{b23_comparison['paired_delta_ci95_high']:.1%}; exact McNemar "
            f"p={b23_comparison['mcnemar_exact_p']:.4g}).\n"
        )
    markdown = f"""# Final observed results

This report is generated only from the {len(records)} frozen campaigns listed in `final_analysis.json`. The {len(case_ids)} cases are paired by sample ID.

## Primary result

- B0 passed {baseline['pass_count']}/{baseline['n']} cases ({baseline['pass_rate']:.1%}).
{b1_result}{b1_ablation_line}{b23_result}- The best F3 treatment was {best['treatment']}, passing {best['pass_count']}/{best['n']} cases ({best['pass_rate']:.1%}).
- Its paired absolute gain over B0 was {best_comparison['paired_pass_rate_delta']:.1%} (paired bootstrap 95% CI {best_comparison['paired_delta_ci95_low']:.1%} to {best_comparison['paired_delta_ci95_high']:.1%}; exact McNemar p={best_comparison['mcnemar_exact_p']:.4g}).

## What the iterative loop contributed

Cases that eventually passed after parser, compiler, or behavioral feedback: {', '.join(f"{label}={count}" for label, count in feedback_assisted_passes.items())}. Cases requiring multiple physical calls are reported separately because a `MAX_TOKENS` retry is not evidence that validation feedback helped.

## Interpretation boundary

B0 versus B1 isolates the configured feedback-policy difference on Ghidra pseudocode; B2 versus B3 isolates the same permission on raw objdump assembly. Both remain subject to stochastic model sampling because the first responses come from separate calls. B1/B3 versus F3 changes representation and prompt profile, so it is informative but not a complete factorial estimate of Clean IR alone. A Clean-IR one-shot arm and repeated model seeds would be needed for a full representation-by-feedback interaction and sampling-variance estimate. O1/O2/O3 differ only in the frozen standard LLVM optimization treatment and therefore provide the cleanest optimization-specific comparison. Native-contract compliance is reported separately from behavioral equivalence; compatibility-runnable IR is not called fully native.
"""
    (output / "findings.md").write_text(markdown, encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
