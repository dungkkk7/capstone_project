#!/usr/bin/env python3
"""Replay and measure all four ``default<O*>`` boundaries used by F3.

The two early optimizer boundaries live inside the monolithic main brightening
pipeline.  This tool inserts LLVM's no-op ``print`` module pass immediately
before and after each boundary, keeping the optimizer and all custom passes in
the same production process.  Replay validity is gated on exact scalar and
opcode metrics.  ``llvm-diff`` and normalized structural hashes remain useful
diagnostics, but are not validity gates because custom passes may allocate
different clone suffixes or SSA names in a separate process.  The two bundle
boundaries are replayed directly from persisted inputs with the same
vectorization/unrolling policy as production.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import shutil
import subprocess
import sys
from itertools import combinations
from pathlib import Path
from typing import Any


SRC_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = SRC_ROOT.parent
sys.path.insert(0, str(SRC_ROOT))

from evaluation.analyze_ir_optimization_effects import ir_metrics
from llvm_pass.britening_ir import (
    DEFAULT_PASS_PIPELINE,
    brighten_ir,
    pipeline_for_optimization_level,
)


LEVELS = ("O1", "O2", "O3")
SCALAR_FIELDS = (
    "functions", "blocks", "instructions", "conditional_branches", "calls",
    "direct_calls", "indirect_calls", "intrinsics", "allocas", "loads",
    "stores", "geps", "phis", "selects", "switches", "unreachable",
    "memory_ops", "scalar_cleanup_ops", "vector_instructions",
)


def _campaign(value: str) -> Path:
    path = Path(value)
    if not path.is_absolute():
        direct = (PROJECT_ROOT / path).resolve()
        path = direct if direct.is_dir() else (PROJECT_ROOT / "result" / value).resolve()
    if not path.is_dir():
        raise FileNotFoundError(path)
    return path


def _write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def _run_instrumented_main(
    level: str,
    input_path: Path,
    output_path: Path,
    *,
    binary_path: Path,
    report_path: Path,
    log_path: Path,
) -> None:
    pipeline = pipeline_for_optimization_level(DEFAULT_PASS_PIPELINE, level)
    needle = f"default<{level}>"
    if pipeline.split(",").count(needle) != 2:
        raise RuntimeError(f"Expected exactly two main {needle} boundaries")
    # `print` only emits the current Module to stderr; it does not mutate IR or
    # force a serialization boundary.  Four dumps therefore capture exact
    # before/after states without changing the production pass interaction.
    pipeline = pipeline.replace(needle, f"print,{needle},print")
    prior_pipeline = os.environ.get("BRIGHTEN_PASS_PIPELINE")
    prior_report = os.environ.get("BRIGHTEN_095_REPORT")
    prior_log = os.environ.get("BRIGHTEN_DUMP_OPT_LOG")
    os.environ["BRIGHTEN_PASS_PIPELINE"] = pipeline
    os.environ["BRIGHTEN_095_REPORT"] = str(report_path)
    os.environ["BRIGHTEN_DUMP_OPT_LOG"] = str(log_path)
    try:
        if not brighten_ir(
            str(input_path),
            str(output_path),
            binary_path=str(binary_path),
        ):
            raise RuntimeError(
                f"Instrumented brightening failed: {input_path} -> {output_path}"
            )
    finally:
        if prior_pipeline is None:
            os.environ.pop("BRIGHTEN_PASS_PIPELINE", None)
        else:
            os.environ["BRIGHTEN_PASS_PIPELINE"] = prior_pipeline
        if prior_report is None:
            os.environ.pop("BRIGHTEN_095_REPORT", None)
        else:
            os.environ["BRIGHTEN_095_REPORT"] = prior_report
        if prior_log is None:
            os.environ.pop("BRIGHTEN_DUMP_OPT_LOG", None)
        else:
            os.environ["BRIGHTEN_DUMP_OPT_LOG"] = prior_log


def _extract_printed_modules(log_path: Path, targets: list[Path]) -> None:
    text = log_path.read_text(encoding="utf-8", errors="replace")
    marker = "; ModuleID = "
    starts = []
    cursor = 0
    while True:
        found = text.find(marker, cursor)
        if found < 0:
            break
        starts.append(found)
        cursor = found + len(marker)
    if len(starts) != len(targets):
        raise RuntimeError(
            f"Expected {len(targets)} LLVM print dumps in {log_path}, found {len(starts)}"
        )
    starts.append(len(text))
    for index, target in enumerate(targets):
        segment = text[starts[index]:starts[index + 1]]
        lines = segment.splitlines()
        # LLVM's printer emits named metadata last.  Custom-pass diagnostics
        # can follow a dump before the next print marker, so trim after the
        # final metadata definition instead of treating diagnostics as IR.
        metadata_indexes = [
            line_index
            for line_index, line in enumerate(lines)
            if line.startswith("!") and " = " in line
        ]
        if not metadata_indexes:
            raise RuntimeError(f"Printed module has no metadata terminator: {log_path}")
        module = "\n".join(lines[: metadata_indexes[-1] + 1]) + "\n"
        target.write_text(module, encoding="utf-8")


def _ll_for_bc(path: Path) -> Path:
    ll = path.with_suffix(".ll")
    if not ll.is_file():
        raise RuntimeError(f"Expected llvm-dis checkpoint: {ll}")
    return ll


def _llvm_equivalent(left: Path, right: Path) -> bool:
    llvm_diff = shutil.which("llvm-diff-21") or shutil.which("llvm-diff")
    if not llvm_diff:
        raise RuntimeError("llvm-diff-21/llvm-diff is required for replay validation")
    result = subprocess.run(
        [llvm_diff, str(left), str(right)],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def _run_bundle_opt(level: str, source: Path, output: Path) -> None:
    runner = (
        PROJECT_ROOT
        / "src/llvm_pass/brighten_100_delift_bundle/run_o3_llvm.py"
    )
    env = os.environ.copy()
    env["DELIFT_OPT_LEVEL"] = level
    env["DELIFT_OPT_PIPELINE"] = f"default<{level}>,verify"
    subprocess.run(
        [sys.executable, str(runner), str(source), str(output)],
        cwd=PROJECT_ROOT,
        env=env,
        check=True,
    )


def _boundary_row(
    dataset: str,
    level: str,
    case_id: str,
    boundary: str,
    before_path: Path,
    after_path: Path,
    *,
    production_replay_valid: bool,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    before = ir_metrics(before_path)
    after = ir_metrics(after_path)
    row: dict[str, Any] = {
        "dataset": dataset,
        "level": level,
        "sample_id": case_id,
        "boundary": boundary,
        "before_path": str(before_path),
        "after_path": str(after_path),
        "production_replay_valid": production_replay_valid,
    }
    for field in SCALAR_FIELDS:
        row[f"{field}_before"] = before[field]
        row[f"{field}_after"] = after[field]
        row[f"{field}_delta"] = after[field] - before[field]
    opcodes = []
    for opcode in sorted(set(before["opcodes"]) | set(after["opcodes"])):
        opcodes.append({
            "dataset": dataset,
            "level": level,
            "sample_id": case_id,
            "boundary": boundary,
            "production_replay_valid": production_replay_valid,
            "opcode": opcode,
            "before": before["opcodes"][opcode],
            "after": after["opcodes"][opcode],
            "delta": after["opcodes"][opcode] - before["opcodes"][opcode],
        })
    return row, opcodes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--o1", required=True)
    parser.add_argument("--o2", required=True)
    parser.add_argument("--o3", required=True)
    parser.add_argument("--dataset-label", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--pilot", type=int)
    parser.add_argument(
        "--skip-main-replay",
        action="store_true",
        help="Audit only persisted bundle boundaries 3 and 4",
    )
    args = parser.parse_args()
    campaigns = {
        "O1": _campaign(args.o1),
        "O2": _campaign(args.o2),
        "O3": _campaign(args.o3),
    }
    case_sets = {
        level: {path.name for path in campaign.glob("*") if (path / f"{path.name}.bc").is_file()}
        for level, campaign in campaigns.items()
    }
    if len({frozenset(items) for items in case_sets.values()}) != 1:
        raise RuntimeError(f"Campaigns are not paired: {case_sets}")
    case_ids = sorted(next(iter(case_sets.values())))
    if args.pilot:
        case_ids = case_ids[: args.pilot]
    output = (PROJECT_ROOT / args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, Any]] = []
    opcode_rows: list[dict[str, Any]] = []
    replay_rows: list[dict[str, Any]] = []
    for level in LEVELS:
        campaign = campaigns[level]
        for index, case_id in enumerate(case_ids, 1):
            print(f"[{args.dataset_label}] {level} {case_id} ({index}/{len(case_ids)})", flush=True)
            case_dir = campaign / case_id
            audit_dir = output / "artifacts" / level / case_id
            audit_dir.mkdir(parents=True, exist_ok=True)
            production_main = case_dir / f"{case_id}_brightened.ll"
            replay_valid = False
            if not args.skip_main_replay:
                preflight = json.loads(
                    (case_dir / "paired_preflight.json").read_text(encoding="utf-8")
                )
                binary = Path(preflight["original_binary"])
                raw_bc = case_dir / f"{case_id}.bc"
                checkpoints = [
                    audit_dir / "main_opt_1.before.ll",
                    audit_dir / "main_opt_1.after.ll",
                    audit_dir / "main_opt_2.before.ll",
                    audit_dir / "main_opt_2.after.ll",
                ]
                replay_bc = audit_dir / "main_instrumented_final.bc"
                replay_ll = audit_dir / "main_instrumented_final.ll"
                print_log = audit_dir / "main_instrumented.print.log"
                if (
                    not replay_ll.is_file()
                    or not print_log.is_file()
                    or any(not target.is_file() for target in checkpoints)
                ):
                    _run_instrumented_main(
                        level,
                        raw_bc,
                        replay_bc,
                        binary_path=binary,
                        report_path=audit_dir / "main_instrumented.095.json",
                        log_path=print_log,
                    )
                    _extract_printed_modules(print_log, checkpoints)
                replay_metrics = ir_metrics(replay_ll)
                production_metrics = ir_metrics(production_main)
                structural_match = (
                    replay_metrics["structural_sha256"]
                    == production_metrics["structural_sha256"]
                )
                llvm_equivalent = _llvm_equivalent(replay_ll, production_main)
                metric_match = (
                    all(
                        replay_metrics[field] == production_metrics[field]
                        for field in SCALAR_FIELDS
                    )
                    and replay_metrics["opcodes"] == production_metrics["opcodes"]
                )
                # The audit measures opcode/count deltas. LLVM's print pass is
                # observational, but several custom passes allocate numeric
                # clone suffixes from nondeterministic traversal order; that
                # makes normalized text and llvm-diff report false mismatches
                # even when every measured opcode is identical. Gate causal
                # metric attribution on exact scalar+opcode equality and keep
                # both stricter diagnostics as separate fields.
                replay_valid = metric_match
                replay_rows.append({
                    "dataset": args.dataset_label,
                    "level": level,
                    "sample_id": case_id,
                    "llvm_equivalent": llvm_equivalent,
                    "metric_match": metric_match,
                    "structural_match": structural_match,
                    "replay_sha256": replay_metrics["structural_sha256"],
                    "production_sha256": production_metrics["structural_sha256"],
                })
                for boundary, before, after in (
                    ("main_default_opt_1", checkpoints[0], checkpoints[1]),
                    ("main_default_opt_2", checkpoints[2], checkpoints[3]),
                ):
                    row, opcodes = _boundary_row(
                        args.dataset_label, level, case_id, boundary, before, after,
                        production_replay_valid=replay_valid,
                    )
                    rows.append(row)
                    opcode_rows.extend(opcodes)

            for boundary, source_name, production_name in (
                (
                    "bundle_default_opt_3",
                    f"{case_id}_final.02-pointer-opt.ll",
                    f"{case_id}_final.03-storage-delift.ll",
                ),
                (
                    "bundle_default_opt_4",
                    f"{case_id}_final.05-unpinned.ll",
                    None,
                ),
            ):
                source = case_dir / source_name
                replay = audit_dir / f"{boundary}.after.ll"
                if not replay.is_file():
                    _run_bundle_opt(level, source, replay)
                production_match = True
                if production_name:
                    production_match = _llvm_equivalent(
                        replay, case_dir / production_name
                    )
                row, opcodes = _boundary_row(
                    args.dataset_label, level, case_id, boundary, source, replay,
                    production_replay_valid=production_match,
                )
                rows.append(row)
                opcode_rows.extend(opcodes)
                if boundary == "bundle_default_opt_4":
                    # Everything after the fourth standard optimizer is the
                    # deterministic presentation/native-cleanup tail: pointer
                    # select deduplication, bounded 095, scalar cleanup and
                    # final native-contract cleanup.  The persisted final IR
                    # lets us measure this combined custom tail separately
                    # from default<O*> instead of attributing both together.
                    final_ir = case_dir / f"{case_id}_final.ll"
                    tail_row, tail_opcodes = _boundary_row(
                        args.dataset_label,
                        level,
                        case_id,
                        "bundle_post_opt_4_custom_cleanup",
                        replay,
                        final_ir,
                        production_replay_valid=production_match,
                    )
                    rows.append(tail_row)
                    opcode_rows.extend(tail_opcodes)

    grouped: dict[tuple[str, str], list[dict[str, Any]]] = {}
    for row in rows:
        grouped.setdefault((row["level"], row["boundary"]), []).append(row)
    summaries = []
    for (level, boundary), selected in grouped.items():
        metric_rows = [row for row in selected if row["production_replay_valid"]]
        if not metric_rows:
            metric_rows = selected
        summary: dict[str, Any] = {
            "dataset": args.dataset_label,
            "level": level,
            "boundary": boundary,
            "n": len(selected),
            "valid_replays": sum(row["production_replay_valid"] for row in selected),
            "metric_n": len(metric_rows),
        }
        for field in SCALAR_FIELDS:
            summary[f"mean_{field}_before"] = sum(
                row[f"{field}_before"] for row in metric_rows
            ) / len(metric_rows)
            summary[f"mean_{field}_after"] = sum(
                row[f"{field}_after"] for row in metric_rows
            ) / len(metric_rows)
            summary[f"total_{field}_delta"] = sum(
                row[f"{field}_delta"] for row in metric_rows
            )
            summary[f"cases_{field}_changed"] = sum(
                row[f"{field}_delta"] != 0 for row in metric_rows
            )
        summaries.append(summary)

    opcode_grouped: dict[tuple[str, str, str], list[dict[str, Any]]] = {}
    for row in opcode_rows:
        opcode_grouped.setdefault(
            (row["level"], row["boundary"], row["opcode"]), []
        ).append(row)
    opcode_summaries = []
    for (level, boundary, opcode), selected in opcode_grouped.items():
        metric_rows = [row for row in selected if row["production_replay_valid"]]
        if not metric_rows:
            metric_rows = selected
        opcode_summaries.append({
            "dataset": args.dataset_label,
            "level": level,
            "boundary": boundary,
            "opcode": opcode,
            "metric_n": len(metric_rows),
            "total_before": sum(row["before"] for row in metric_rows),
            "total_after": sum(row["after"] for row in metric_rows),
            "total_delta": sum(row["delta"] for row in metric_rows),
            "cases_changed": sum(row["delta"] != 0 for row in metric_rows),
        })

    row_lookup = {
        (str(row["level"]), str(row["sample_id"]), str(row["boundary"])): row
        for row in rows
    }
    metric_cache: dict[str, dict[str, Any]] = {}

    def structural_hash(path_value: str) -> str:
        if path_value not in metric_cache:
            metric_cache[path_value] = ir_metrics(Path(path_value))
        return str(metric_cache[path_value]["structural_sha256"])

    cross_level_rows = []
    boundaries = sorted({str(row["boundary"]) for row in rows})
    for left, right in combinations(LEVELS, 2):
        for boundary in boundaries:
            paired = [
                (
                    row_lookup[(left, case_id, boundary)],
                    row_lookup[(right, case_id, boundary)],
                )
                for case_id in case_ids
            ]
            cross_level_rows.append({
                "dataset": args.dataset_label,
                "left_level": left,
                "right_level": right,
                "boundary": boundary,
                "n": len(paired),
                "before_structural_matches": sum(
                    structural_hash(str(left_row["before_path"]))
                    == structural_hash(str(right_row["before_path"]))
                    for left_row, right_row in paired
                ),
                "after_structural_matches": sum(
                    structural_hash(str(left_row["after_path"]))
                    == structural_hash(str(right_row["after_path"]))
                    for left_row, right_row in paired
                ),
            })

    _write_csv(output / "optimization_boundary_case_metrics.csv", rows)
    _write_csv(output / "optimization_boundary_summary.csv", summaries)
    _write_csv(output / "optimization_boundary_opcode_case_deltas.csv", opcode_rows)
    _write_csv(output / "optimization_boundary_opcode_summary.csv", opcode_summaries)
    _write_csv(output / "main_pipeline_replay_validation.csv", replay_rows)
    _write_csv(output / "cross_level_boundary_structural_matches.csv", cross_level_rows)
    result = {
        "schema_version": 1,
        "dataset": args.dataset_label,
        "paired_cases": len(case_ids),
        "boundaries": sorted({row["boundary"] for row in rows}),
        "main_replay_llvm_equivalent": sum(
            row["llvm_equivalent"] for row in replay_rows
        ),
        "main_replay_metric_matches": sum(
            row["metric_match"] for row in replay_rows
        ),
        "main_replay_structural_matches": sum(
            row["structural_match"] for row in replay_rows
        ),
        "main_replay_count": len(replay_rows),
        "cross_level_structural_matches": cross_level_rows,
        "summaries": summaries,
    }
    (output / "optimization_boundary_analysis.json").write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
