#!/usr/bin/env python3
"""Run pass 095 and differential replay over every authoritative pass-40 case."""

from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
from typing import Any


def run(
    argv: list[str],
    *,
    stdin: bytes | None = None,
    timeout: float,
) -> dict[str, Any]:
    started = time.monotonic()
    process = subprocess.Popen(
        argv,
        stdin=subprocess.PIPE if stdin is not None else subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    try:
        stdout, stderr = process.communicate(stdin, timeout=timeout)
        return {
            "kind": "exit",
            "returncode": process.returncode,
            "stdout": stdout,
            "stderr": stderr,
            "seconds": time.monotonic() - started,
        }
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        stdout, stderr = process.communicate()
        return {
            "kind": "timeout",
            "returncode": None,
            "stdout": stdout,
            "stderr": stderr,
            "seconds": time.monotonic() - started,
        }


def command_result(result: dict[str, Any]) -> dict[str, Any]:
    return {
        "kind": result["kind"],
        "returncode": result["returncode"],
        "seconds": round(float(result["seconds"]), 4),
        "stderr": result["stderr"].decode("utf-8", "replace")[-4000:],
    }


def observations_match(left: dict[str, Any], right: dict[str, Any]) -> bool:
    if left["kind"] == "timeout" or right["kind"] == "timeout":
        return left["kind"] == right["kind"]
    if left["returncode"] != 0 or right["returncode"] != 0:
        # The dataset's existing semantic checker classifies a shared crash as
        # equivalent.  Exact successful behavior remains mandatory below.
        return left["returncode"] != 0 and right["returncode"] != 0
    return (
        left["returncode"] == right["returncode"]
        and left["stdout"] == right["stdout"]
        and left["stderr"] == right["stderr"]
    )


def load_payloads(report_path: Path) -> list[bytes]:
    report = json.loads(report_path.read_text(encoding="utf-8"))
    result: list[bytes] = []
    for encoded in report.get("tested_payloads", []):
        try:
            result.append(base64.b64decode(encoded, validate=True))
        except Exception:
            continue
    return result


def residual_counts(ir: str) -> dict[str, int]:
    return {
        "switch": len(re.findall(r"(?m)^\s*switch\s", ir)),
        "indirectbr": len(re.findall(r"(?m)^\s*indirectbr\s", ir)),
        "conditional_branches": len(re.findall(r"(?m)^\s*br\s+i1\s", ir)),
        "select": len(re.findall(r"(?m)^\s*%[^=]+\s*=\s*select\s", ir)),
    }


def find_cases(dataset_root: Path, summary_path: Path) -> list[tuple[str, Path]]:
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    requested: list[str] = []
    for item in summary.get("cases", []):
        binary = Path(item["binary"])
        requested.append(binary.parent.name)
    if len(requested) != int(summary["counts"]["requested"]):
        raise RuntimeError("pipeline summary case count is internally inconsistent")

    result: list[tuple[str, Path]] = []
    for case_id in requested:
        candidates = sorted((dataset_root / case_id).glob("*_brightened.ll"))
        if len(candidates) != 1:
            raise RuntimeError(
                f"{case_id}: expected one brightened IR, found {len(candidates)}"
            )
        result.append((case_id, candidates[0]))
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", type=Path, required=True)
    parser.add_argument("--pipeline-summary", type=Path, required=True)
    parser.add_argument("--plugin", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--opt", default="opt-21")
    parser.add_argument("--clang", default="clang-21")
    parser.add_argument("--z3-timeout-ms", type=int, default=100)
    parser.add_argument("--max-z3-candidates", type=int, default=512)
    parser.add_argument("--max-deflatten-rounds", type=int, default=128)
    parser.add_argument("--max-deflatten-instructions", type=int, default=50000)
    parser.add_argument("--opt-timeout", type=float, default=300.0)
    parser.add_argument("--run-timeout", type=float, default=2.0)
    parser.add_argument(
        "--retry-timeout", type=float, default=10.0,
        help="Longer replay timeout used only to confirm a timeout mismatch",
    )
    parser.add_argument("--differential", action="store_true")
    parser.add_argument(
        "--case", action="append", dest="selected_cases",
        help="Audit only this case id (repeatable); default is all summary cases",
    )
    args = parser.parse_args()

    cases = find_cases(args.dataset_root, args.pipeline_summary)
    if args.selected_cases:
        selected = set(args.selected_cases)
        cases = [item for item in cases if item[0] in selected]
        missing = selected.difference(case_id for case_id, _ in cases)
        if missing:
            raise RuntimeError(f"unknown case ids: {sorted(missing)}")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    results: list[dict[str, Any]] = []

    for index, (case_id, source_ir) in enumerate(cases, 1):
        case_out = args.output_dir / case_id
        case_out.mkdir(parents=True, exist_ok=True)
        output_ir = case_out / "deobfuscated.ll"
        report_path = case_out / "095-report.json"
        before_text = source_ir.read_text(encoding="utf-8")

        opt_result = run(
            [
                args.opt,
                "-load-pass-plugin",
                str(args.plugin),
                f"-095-z3-timeout-ms={args.z3_timeout_ms}",
                f"-095-max-z3-candidates={args.max_z3_candidates}",
                f"-095-max-deflatten-rounds={args.max_deflatten_rounds}",
                f"-095-max-deflatten-instructions={args.max_deflatten_instructions}",
                f"-095-report={report_path}",
                "-passes=095",
                str(source_ir),
                "-S",
                "-o",
                str(output_ir),
            ],
            timeout=args.opt_timeout,
        )
        case_result: dict[str, Any] = {
            "case": case_id,
            "source": str(source_ir),
            "opt": command_result(opt_result),
        }
        if opt_result["kind"] != "exit" or opt_result["returncode"] != 0:
            case_result["status"] = "opt_failed"
            results.append(case_result)
            print(f"[{index:02d}/{len(cases)}] {case_id}: opt_failed", flush=True)
            continue

        verify_result = run(
            [args.opt, "-passes=verify", str(output_ir), "-disable-output"],
            timeout=60,
        )
        after_text = output_ir.read_text(encoding="utf-8")
        plugin_report = json.loads(report_path.read_text(encoding="utf-8"))
        case_result.update(
            {
                "verify": command_result(verify_result),
                "plugin_report": plugin_report,
                "before": residual_counts(before_text),
                "after": residual_counts(after_text),
                "line_count_before": len(before_text.splitlines()),
                "line_count_after": len(after_text.splitlines()),
            }
        )
        if verify_result["kind"] != "exit" or verify_result["returncode"] != 0:
            case_result["status"] = "verify_failed"
            results.append(case_result)
            print(f"[{index:02d}/{len(cases)}] {case_id}: verify_failed", flush=True)
            continue

        if args.differential:
            before_bin = case_out / "before.bin"
            after_bin = case_out / "after.bin"
            compile_before = run(
                [args.clang, "-O2", str(source_ir), "-lm", "-o", str(before_bin)],
                timeout=120,
            )
            compile_after = run(
                [args.clang, "-O2", str(output_ir), "-lm", "-o", str(after_bin)],
                timeout=120,
            )
            case_result["compile_before"] = command_result(compile_before)
            case_result["compile_after"] = command_result(compile_after)
            if any(
                item["kind"] != "exit" or item["returncode"] != 0
                for item in (compile_before, compile_after)
            ):
                case_result["status"] = "compile_failed"
                results.append(case_result)
                print(f"[{index:02d}/{len(cases)}] {case_id}: compile_failed", flush=True)
                continue

            semantic_candidates = sorted(source_ir.parent.glob("*_semantic_report.json"))
            semantic_candidates = [
                item
                for item in semantic_candidates
                if "valid_domain" not in item.name
            ]
            if len(semantic_candidates) != 1:
                case_result["status"] = "payload_report_missing"
                results.append(case_result)
                print(
                    f"[{index:02d}/{len(cases)}] {case_id}: payload_report_missing",
                    flush=True,
                )
                continue
            payloads = load_payloads(semantic_candidates[0])
            mismatches: list[dict[str, Any]] = []
            for payload_index, payload in enumerate(payloads):
                before_run = run(
                    [str(before_bin)], stdin=payload, timeout=args.run_timeout
                )
                after_run = run(
                    [str(after_bin)], stdin=payload, timeout=args.run_timeout
                )
                if (
                    not observations_match(before_run, after_run)
                    and "timeout" in (before_run["kind"], after_run["kind"])
                ):
                    # Parallel batch load can push a normally ~1s crashing
                    # sample across the short timeout boundary on only one
                    # side.  Re-run both observations with the same longer
                    # budget before classifying a semantic mismatch.
                    before_run = run(
                        [str(before_bin)], stdin=payload,
                        timeout=args.retry_timeout,
                    )
                    after_run = run(
                        [str(after_bin)], stdin=payload,
                        timeout=args.retry_timeout,
                    )
                if observations_match(before_run, after_run):
                    continue
                mismatches.append(
                    {
                        "index": payload_index,
                        "payload_base64": base64.b64encode(payload).decode("ascii"),
                        "before": command_result(before_run),
                        "after": command_result(after_run),
                    }
                )
                if len(mismatches) >= 10:
                    break
            case_result["differential"] = {
                "payloads": len(payloads),
                "matches": len(payloads) - len(mismatches),
                "mismatches": mismatches,
            }
            case_result["status"] = "pass" if not mismatches else "mismatch"
        else:
            case_result["status"] = "pass"
        results.append(case_result)
        print(
            f"[{index:02d}/{len(cases)}] {case_id}: {case_result['status']} "
            f"switch {case_result['before']['switch']}->{case_result['after']['switch']} "
            f"report={plugin_report['status']}",
            flush=True,
        )

    counts: dict[str, int] = {}
    for item in results:
        counts[item["status"]] = counts.get(item["status"], 0) + 1
    summary = {
        "schema": "deobfuscate-095-pass40-audit-v1",
        "requested": len(cases),
        "counts": counts,
        "all_passed": counts == {"pass": len(cases)},
        "cases": results,
    }
    summary_path = args.output_dir / "summary.json"
    summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: summary[k] for k in ("requested", "counts", "all_passed")}))
    return 0 if summary["all_passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
