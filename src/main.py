#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

import argparse
import csv
import datetime
import json
import os
import sys
from typing import Optional

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from binary_lifting.lifting import recover_binary
from llvm_pass.britening_ir import brighten_ir
from fuzzing_equi_check.fuzzing import (
    DEFAULT_TEMPLATES,
    SemanticFuzzer,
    TemplateEvaluator,
    make_bytes_generator,
)


class Color:
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    GRAY = "\033[90m"
    BOLD = "\033[1m"
    END = "\033[0m"


def read_binary_list(csv_path: str) -> list[str]:
    with open(csv_path, newline="", encoding="utf-8") as stream:
        rows = list(csv.reader(stream))
    if not rows:
        return []

    header = [cell.strip().lower() for cell in rows[0]]
    column: Optional[int] = None
    for name in ["binary_path", "binary", "path", "file", "filepath"]:
        if name in header:
            column = header.index(name)
            break

    start = 1 if column is not None else 0
    column = 0 if column is None else column
    result: list[str] = []
    for row in rows[start:]:
        if len(row) > column and row[column].strip():
            result.append(row[column].strip())
    return result


def build_case_dir(result_root: str, binary: str, project_root: str) -> str:
    """Create a stable, collision-free directory for binaries sharing a basename."""
    binary = os.path.abspath(binary)
    candidate_roots = [
        os.path.join(project_root, "data", "obfuscated"),
        os.path.join(project_root, "data", "clean_src"),
        project_root,
    ]
    relative = None
    for candidate in candidate_roots:
        candidate = os.path.abspath(candidate)
        try:
            common = os.path.commonpath([binary, candidate])
        except ValueError:
            continue
        if common == candidate:
            relative = os.path.relpath(binary, candidate)
            break
    if relative is None:
        digest = __import__("hashlib").sha256(binary.encode("utf-8")).hexdigest()[:12]
        relative = os.path.join(digest, os.path.basename(binary))
    stem = os.path.splitext(relative)[0]
    return os.path.join(result_root, stem)


def select_generator(path: str):
    lowered = path.lower()
    for key, template in DEFAULT_TEMPLATES.items():
        if key in lowered:
            print(f"{Color.YELLOW}[!] Dùng template: {key}{Color.END}")
            return TemplateEvaluator(template)
    print(f"{Color.YELLOW}[!] Không có template phù hợp; dùng random bytes.{Color.END}")
    return make_bytes_generator()


def print_report(report: dict) -> None:
    ratio = report.get("equivalence_ratio", 0.0)
    confirmed = report.get("confirmed_equivalence_ratio", 0.0)
    if report.get("afl_mode"):
        print(f"    AFL++ mode={report['afl_mode']} target={report.get('afl_target', 'N/A')}")
    if report.get("afl_stats"):
        stats = report["afl_stats"]
        print(
            "    AFL++ coverage: "
            f"bitmap={stats.get('bitmap_cvg', 'N/A')} "
            f"paths={stats.get('paths_total', 'N/A')} "
            f"execs={stats.get('execs_done', 'N/A')} "
            f"exec/s={stats.get('execs_per_sec', 'N/A')}"
        )
    print(
        f"    total={report['total_runs']} "
        f"matches={report['matches']} mismatches={report['mismatches']}"
    )
    print(
        f"    inconclusive={report.get('inconclusive', 0)} "
        f"strict={ratio:.2f}% confirmed={confirmed:.2f}%"
    )
    if report.get("is_fully_equivalent"):
        print(
            f"{Color.GREEN}[✓] Không tìm thấy khác biệt giữa binary gốc và "
            f"rev.ng translated executable trên bộ input đã chạy.{Color.END}"
        )
    elif report.get("mismatches", 0):
        print(f"{Color.RED}[✗] Phát hiện semantic mismatch ở runtime translation.{Color.END}")
        for sample in report.get("mismatch_examples", []):
            print(f"    case #{sample['index']}: {sample['reason']}")
    else:
        print(f"{Color.YELLOW}[!] Kết quả chưa đủ kết luận do timeout/crash.{Color.END}")


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "binary → runtime LLVM IR + clean/native-looking LLVM IR + "
            "rev.ng semantic differential test"
        )
    )
    parser.add_argument("csv", help="CSV chứa đường dẫn binary")
    parser.add_argument("--no-cache", action="store_true")
    parser.add_argument("--force-relift", action="store_true")
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--timeout", type=float, default=1.0)
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument("--compare-stderr", action="store_true")
    parser.add_argument(
        "--semantic-runtime",
        choices=["isolated", "root"],
        default="isolated",
        help="Executable rev.ng dùng để so sánh với binary gốc",
    )
    args = parser.parse_args(argv)

    csv_path = os.path.abspath(args.csv)
    if not os.path.isfile(csv_path):
        print(f"{Color.RED}[✗] Không tồn tại CSV: {csv_path}{Color.END}")
        return 1

    binaries = read_binary_list(csv_path)
    if not binaries:
        print(f"{Color.YELLOW}[!] CSV không có binary.{Color.END}")
        return 0

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    timestamp = datetime.datetime.now().strftime("pipeline_%Y%m%d_%H%M%S")
    result_root = os.path.join(project_root, "result", timestamp)
    os.makedirs(result_root, exist_ok=True)

    success_count = 0
    for item in binaries:
        binary = os.path.abspath(item)
        name = os.path.splitext(os.path.basename(binary))[0]
        case_dir = build_case_dir(result_root, binary, project_root)
        os.makedirs(case_dir, exist_ok=True)

        print("\n" + "=" * 80)
        print(f"{Color.BOLD}Processing: {binary}{Color.END}")

        artifacts = recover_binary(
            binary,
            case_dir,
            use_cache=not args.no_cache,
            force_relift=args.force_relift,
            optimize_native_ir=True,
        )
        if not artifacts.success:
            print(f"{Color.RED}[✗] Recovery thất bại: {artifacts.error}{Color.END}")
            continue

        # Brightening is applied to the Clang/native-looking representation.
        # Success means LLVM-valid + object-compilable, not standalone linkable.
        bright_bc = os.path.join(case_dir, f"{name}.brightened.bc")
        bright_ll = os.path.join(case_dir, f"{name}.brightened.ll")
        if not brighten_ir(artifacts.native_bc, bright_bc, opt_level="O1"):
            print(f"{Color.RED}[✗] Brightening thất bại.{Color.END}")
            continue
        if not os.path.isfile(bright_ll):
            print(f"{Color.RED}[✗] Không tạo được {bright_ll}{Color.END}")
            continue

        semantic_executable = (
            artifacts.translated_executable
            if args.semantic_runtime == "isolated"
            else artifacts.runtime_executable
        )
        if not semantic_executable or not os.path.isfile(semantic_executable):
            print(f"{Color.RED}[✗] Không có rev.ng semantic executable.{Color.END}")
            continue

        # Important: compare the runtime-linked rev.ng translation against the
        # original. Do not try to link native-looking per-function IR directly.
        fuzzer = SemanticFuzzer(semantic_executable, binary)
        try:
            fuzzer.compile()
            report = fuzzer.run_differential_test(
                iterations=args.iterations,
                generator=select_generator(binary),
                timeout=args.timeout,
                compare_stderr=args.compare_stderr,
                num_workers=args.workers,
            )
        finally:
            fuzzer.cleanup()

        report["semantic_scope"] = {
            "left": semantic_executable,
            "right": binary,
            "left_kind": f"revng-recompile-{args.semantic_runtime}",
            "brightened_ir_runtime_tested": False,
            "brightened_ir_validation": "LLVM valid and object-compilable",
            "note": (
                "The native-looking/brightened module is not treated as a standalone "
                "application because it can lack main and runtime helper definitions."
            ),
        }

        report_path = os.path.join(case_dir, f"{name}.semantic-report.json")
        with open(report_path, "w", encoding="utf-8") as stream:
            json.dump(report, stream, indent=2, ensure_ascii=False)

        print_report(report)
        print(f"    runtime root IR:   {artifacts.runtime_root_ll}")
        print(f"    cleanup IR:        {artifacts.cleanup_ll}")
        print(f"    native-looking IR: {artifacts.native_ll}")
        print(f"    brightened IR:     {bright_ll}")
        print(f"    semantic exe:      {semantic_executable}")
        print(f"    artifact manifest: {artifacts.manifest_path}")
        print(f"    semantic report:   {report_path}")
        print(
            f"{Color.YELLOW}[!] Semantic report applies to rev.ng runtime translation, "
            "not to direct Clang linking of brightened IR.{Color.END}"
        )

        if report.get("is_fully_equivalent"):
            success_count += 1

    print("\n" + "=" * 80)
    print(f"Semantic-equivalent runtime translations on tested inputs: {success_count}/{len(binaries)}")
    print(f"Results: {result_root}")
    return 0 if success_count == len(binaries) else 2


if __name__ == "__main__":
    sys.exit(main())
