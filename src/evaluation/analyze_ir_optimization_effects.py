#!/usr/bin/env python3
"""Explain what O1/O2/O3 actually change in the persisted LLVM IR.

This analysis deliberately separates pure standard-optimizer boundaries from
transitions that also contain custom transformations.  It never attributes a
combined transition to ``default<O*>`` alone.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
import statistics
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
LEVELS = ("O1", "O2", "O3")
STAGES = (
    ("raw_lift", "{case}.ll"),
    ("brightened_main", "{case}_brightened.ll"),
    ("bundle_verified_input", "{case}_final.01-verified-input.ll"),
    ("bundle_pointer_opt", "{case}_final.02-pointer-opt.ll"),
    ("bundle_standard_opt_3", "{case}_final.03-storage-delift.ll"),
    ("bundle_storage_delift", "{case}_final.04-storage-o3.ll"),
    ("bundle_residual_strip", "{case}_final.05-unpinned.ll"),
    ("final_clean", "{case}_final.ll"),
)
TRANSITIONS = (
    (
        "main_combined_custom_plus_opt_1_2",
        "raw_lift",
        "brightened_main",
        False,
    ),
    (
        "bundle_exact_pointer_passes",
        "bundle_verified_input",
        "bundle_pointer_opt",
        False,
    ),
    (
        "llvm_default_opt_boundary_3",
        "bundle_pointer_opt",
        "bundle_standard_opt_3",
        True,
    ),
    (
        "custom_storage_delift",
        "bundle_standard_opt_3",
        "bundle_storage_delift",
        False,
    ),
    (
        "custom_residual_strip",
        "bundle_storage_delift",
        "bundle_residual_strip",
        False,
    ),
    (
        "final_tail_opt_4_plus_custom_cleanup",
        "bundle_residual_strip",
        "final_clean",
        False,
    ),
)

KNOWN_OPCODES = (
    "fneg", "add", "fadd", "sub", "fsub", "mul", "fmul", "udiv", "sdiv",
    "fdiv", "urem", "srem", "frem", "shl", "lshr", "ashr", "and", "or",
    "xor", "extractelement", "insertelement", "shufflevector", "extractvalue",
    "insertvalue", "alloca", "load", "store", "fence", "cmpxchg", "atomicrmw",
    "getelementptr", "trunc", "zext", "sext", "fptrunc", "fpext", "fptoui",
    "fptosi", "uitofp", "sitofp", "ptrtoint", "inttoptr", "bitcast",
    "addrspacecast", "icmp", "fcmp", "phi", "select", "freeze", "call",
    "va_arg", "landingpad", "catchpad", "cleanuppad", "ret", "br", "switch",
    "indirectbr", "invoke", "callbr", "resume", "catchswitch", "catchret",
    "cleanupret", "unreachable",
)
OPCODE_PATTERN = re.compile(
    r"\b(" + "|".join(sorted(KNOWN_OPCODES, key=len, reverse=True)) + r")\b"
)
LABEL_PATTERN = re.compile(r"^[A-Za-z$._%][-A-Za-z$._0-9%]*:\s*(?:;.*)?$")


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


def _opcode(line: str) -> str | None:
    body = line.split(";", 1)[0].strip()
    if not body:
        return None
    if "=" in body:
        body = body.split("=", 1)[1].strip()
    match = OPCODE_PATTERN.search(body)
    return match.group(1) if match else None


def ir_metrics(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8", errors="replace")
    opcodes: Counter[str] = Counter()
    functions = blocks = conditional_branches = 0
    direct_calls = indirect_calls = intrinsics = vector_instructions = 0
    in_function = False
    normalized_instructions: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("define "):
            functions += 1
            blocks += 1
            in_function = True
            normalized_instructions.append(re.sub(r"\s+", " ", line))
            continue
        if in_function and line == "}":
            in_function = False
            normalized_instructions.append("}")
            continue
        if not in_function or not line or line.startswith(";"):
            continue
        if LABEL_PATTERN.match(line):
            blocks += 1
            normalized_instructions.append(re.sub(r"\s+", " ", line.split(";", 1)[0]))
            continue
        opcode = _opcode(line)
        if opcode is None:
            continue
        opcodes[opcode] += 1
        body = line.split(";", 1)[0]
        normalized_instructions.append(re.sub(r"\s+", " ", body.strip()))
        if opcode == "br" and re.search(r"\bbr\s+i1\b", body):
            conditional_branches += 1
        elif opcode == "switch":
            conditional_branches += 1
        if opcode in {"call", "invoke", "callbr"}:
            target = re.search(r"@([A-Za-z$._][-A-Za-z$._0-9]*)\s*\(", body)
            if target:
                direct_calls += 1
                if target.group(1).startswith("llvm."):
                    intrinsics += 1
            else:
                indirect_calls += 1
        if re.search(r"<\s*\d+\s+x\s+", body):
            vector_instructions += 1

    instructions = sum(opcodes.values())
    memory_ops = sum(opcodes[name] for name in (
        "alloca", "load", "store", "getelementptr", "cmpxchg", "atomicrmw"
    ))
    scalar_cleanup_ops = sum(opcodes[name] for name in (
        "phi", "select", "icmp", "fcmp", "bitcast", "ptrtoint", "inttoptr",
        "zext", "sext", "trunc",
    ))
    fingerprint = hashlib.sha256(
        "\n".join(normalized_instructions).encode("utf-8")
    ).hexdigest()
    return {
        "functions": functions,
        "blocks": blocks,
        "instructions": instructions,
        "conditional_branches": conditional_branches,
        "calls": opcodes["call"] + opcodes["invoke"] + opcodes["callbr"],
        "direct_calls": direct_calls,
        "indirect_calls": indirect_calls,
        "intrinsics": intrinsics,
        "allocas": opcodes["alloca"],
        "loads": opcodes["load"],
        "stores": opcodes["store"],
        "geps": opcodes["getelementptr"],
        "phis": opcodes["phi"],
        "selects": opcodes["select"],
        "switches": opcodes["switch"],
        "unreachable": opcodes["unreachable"],
        "memory_ops": memory_ops,
        "scalar_cleanup_ops": scalar_cleanup_ops,
        "vector_instructions": vector_instructions,
        "structural_sha256": fingerprint,
        "opcodes": opcodes,
    }


def _delta(before: float, after: float) -> tuple[float, float | None]:
    difference = after - before
    return difference, difference / before if before else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--o1", required=True)
    parser.add_argument("--o2", required=True)
    parser.add_argument("--o3", required=True)
    parser.add_argument("--dataset-label", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    campaigns = {
        "O1": _campaign(args.o1),
        "O2": _campaign(args.o2),
        "O3": _campaign(args.o3),
    }
    case_sets = {
        level: {
            path.name
            for path in campaign.iterdir()
            if path.is_dir() and any((path / pattern.format(case=path.name)).is_file() for _, pattern in STAGES)
        }
        for level, campaign in campaigns.items()
    }
    if len({frozenset(items) for items in case_sets.values()}) != 1:
        raise RuntimeError(f"O-level campaigns are not paired: {case_sets}")
    case_ids = sorted(next(iter(case_sets.values())))
    output = (PROJECT_ROOT / args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)

    metrics: dict[tuple[str, str, str], dict[str, Any]] = {}
    stage_rows: list[dict[str, Any]] = []
    missing: list[dict[str, str]] = []
    scalar_fields = (
        "functions", "blocks", "instructions", "conditional_branches", "calls",
        "direct_calls", "indirect_calls", "intrinsics", "allocas", "loads",
        "stores", "geps", "phis", "selects", "switches", "unreachable",
        "memory_ops", "scalar_cleanup_ops", "vector_instructions",
    )
    for level, campaign in campaigns.items():
        for case_id in case_ids:
            for stage, pattern in STAGES:
                path = campaign / case_id / pattern.format(case=case_id)
                if not path.is_file():
                    missing.append({"level": level, "sample_id": case_id, "stage": stage})
                    continue
                row_metrics = ir_metrics(path)
                metrics[(level, case_id, stage)] = row_metrics
                stage_rows.append({
                    "dataset": args.dataset_label,
                    "level": level,
                    "sample_id": case_id,
                    "stage": stage,
                    **{field: row_metrics[field] for field in scalar_fields},
                    "structural_sha256": row_metrics["structural_sha256"],
                })
    if missing:
        raise RuntimeError(f"Missing {len(missing)} IR checkpoints; first={missing[:5]}")

    transition_rows: list[dict[str, Any]] = []
    opcode_case_deltas: list[dict[str, Any]] = []
    for level in LEVELS:
        for case_id in case_ids:
            for transition, before_stage, after_stage, pure_opt in TRANSITIONS:
                before = metrics[(level, case_id, before_stage)]
                after = metrics[(level, case_id, after_stage)]
                row: dict[str, Any] = {
                    "dataset": args.dataset_label,
                    "level": level,
                    "sample_id": case_id,
                    "transition": transition,
                    "before_stage": before_stage,
                    "after_stage": after_stage,
                    "pure_default_optimizer_boundary": pure_opt,
                }
                for field in scalar_fields:
                    difference, ratio = _delta(before[field], after[field])
                    row[f"{field}_before"] = before[field]
                    row[f"{field}_after"] = after[field]
                    row[f"{field}_delta"] = difference
                    row[f"{field}_delta_ratio"] = ratio
                transition_rows.append(row)
                all_opcodes = set(before["opcodes"]) | set(after["opcodes"])
                for opcode in sorted(all_opcodes):
                    opcode_case_deltas.append({
                        "dataset": args.dataset_label,
                        "level": level,
                        "sample_id": case_id,
                        "transition": transition,
                        "pure_default_optimizer_boundary": pure_opt,
                        "opcode": opcode,
                        "before": before["opcodes"][opcode],
                        "after": after["opcodes"][opcode],
                        "delta": after["opcodes"][opcode] - before["opcodes"][opcode],
                    })

    grouped_transitions: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for row in transition_rows:
        grouped_transitions[(row["level"], row["transition"])].append(row)
    transition_summary: list[dict[str, Any]] = []
    for (level, transition), rows in grouped_transitions.items():
        summary: dict[str, Any] = {
            "dataset": args.dataset_label,
            "level": level,
            "transition": transition,
            "n": len(rows),
            "pure_default_optimizer_boundary": rows[0]["pure_default_optimizer_boundary"],
        }
        for field in scalar_fields:
            summary[f"mean_{field}_before"] = statistics.fmean(
                row[f"{field}_before"] for row in rows
            )
            summary[f"mean_{field}_after"] = statistics.fmean(
                row[f"{field}_after"] for row in rows
            )
            summary[f"total_{field}_delta"] = sum(
                row[f"{field}_delta"] for row in rows
            )
            summary[f"cases_{field}_changed"] = sum(
                row[f"{field}_delta"] != 0 for row in rows
            )
        transition_summary.append(summary)

    opcode_groups: dict[tuple[str, str, str], list[dict[str, Any]]] = defaultdict(list)
    for row in opcode_case_deltas:
        opcode_groups[(row["level"], row["transition"], row["opcode"])].append(row)
    opcode_summary = []
    for (level, transition, opcode), rows in opcode_groups.items():
        opcode_summary.append({
            "dataset": args.dataset_label,
            "level": level,
            "transition": transition,
            "pure_default_optimizer_boundary": rows[0]["pure_default_optimizer_boundary"],
            "opcode": opcode,
            "total_before": sum(row["before"] for row in rows),
            "total_after": sum(row["after"] for row in rows),
            "total_delta": sum(row["delta"] for row in rows),
            "cases_changed": sum(row["delta"] != 0 for row in rows),
        })

    equality_rows = []
    for stage, _ in STAGES:
        for left, right in (("O1", "O2"), ("O1", "O3"), ("O2", "O3")):
            equal = sum(
                metrics[(left, case_id, stage)]["structural_sha256"]
                == metrics[(right, case_id, stage)]["structural_sha256"]
                for case_id in case_ids
            )
            equality_rows.append({
                "dataset": args.dataset_label,
                "stage": stage,
                "comparison": f"{left}_vs_{right}",
                "n": len(case_ids),
                "structurally_identical": equal,
                "structurally_different": len(case_ids) - equal,
            })

    _write_csv(output / "ir_stage_metrics.csv", stage_rows)
    _write_csv(output / "ir_transition_case_metrics.csv", transition_rows)
    _write_csv(output / "ir_transition_summary.csv", transition_summary)
    _write_csv(output / "ir_opcode_case_deltas.csv", opcode_case_deltas)
    _write_csv(output / "ir_opcode_summary.csv", opcode_summary)
    _write_csv(output / "ir_cross_level_equality.csv", equality_rows)

    pure = [
        row for row in transition_summary
        if row["transition"] == "llvm_default_opt_boundary_3"
    ]
    top_opcode: dict[str, list[dict[str, Any]]] = {}
    for level in LEVELS:
        selected = [
            row for row in opcode_summary
            if row["level"] == level
            and row["transition"] == "llvm_default_opt_boundary_3"
            and row["total_delta"]
        ]
        top_opcode[level] = sorted(
            selected, key=lambda row: (-abs(row["total_delta"]), row["opcode"])
        )[:15]

    result = {
        "schema_version": 1,
        "dataset": args.dataset_label,
        "campaigns": {level: str(path) for level, path in campaigns.items()},
        "paired_cases": len(case_ids),
        "stage_count_per_case": len(STAGES),
        "pure_standard_optimizer_boundaries_available": [
            "llvm_default_opt_boundary_3"
        ],
        "combined_boundaries_not_causally_attributed_to_default_opt": [
            "main_combined_custom_plus_opt_1_2",
            "final_tail_opt_4_plus_custom_cleanup",
        ],
        "pure_boundary_summary": pure,
        "top_pure_boundary_opcode_changes": top_opcode,
        "cross_level_equality": equality_rows,
    }
    (output / "ir_optimization_analysis.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
