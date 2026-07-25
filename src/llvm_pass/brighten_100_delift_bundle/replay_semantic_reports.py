#!/usr/bin/env python3
"""Replay frozen semantic-report payloads against the current delift bundle."""

from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
import subprocess
import sys
import tempfile


PROJECT_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from fuzzing_equi_check.fuzzing import (  # noqa: E402
    check_equivalence,
    compile_to_binary,
    is_inconclusive_pair,
    is_stable_observation,
    run_binary,
)


def report_payloads(report: dict, first_mismatch: bool) -> list[bytes]:
    if first_mismatch:
        examples = report.get("mismatch_examples") or []
        if examples and isinstance(examples[0].get("stdin"), str):
            return [examples[0]["stdin"].encode()]
    decoded = []
    for encoded in report.get("tested_payloads") or []:
        try:
            decoded.append(base64.b64decode(encoded, validate=True))
        except (ValueError, TypeError):
            continue
    return decoded


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    parser.add_argument("--failed-only", action="store_true")
    parser.add_argument("--first-mismatch", action="store_true")
    parser.add_argument("--case", action="append", dest="cases")
    args = parser.parse_args()

    runner = Path(__file__).with_name("run_brighten_delift_pipeline.sh")
    failures = []
    checked = 0
    for report_path in sorted(args.run_dir.glob("p*/**/*_semantic_report.json")):
        if "_delift_semantic_report" in report_path.name:
            continue
        report = json.loads(report_path.read_text())
        if args.failed_only and report.get("is_fully_equivalent") is True:
            continue
        case_id = report_path.parent.name
        if args.cases and case_id not in args.cases:
            continue
        brightened = next(report_path.parent.glob("*_brightened.ll"), None)
        originals = sorted((PROJECT_ROOT / "data" / "obfuscated" / case_id).glob("*.elf"))
        payloads = report_payloads(report, args.first_mismatch)
        if brightened is None or not originals or not payloads:
            failures.append((case_id, "missing regression input/artifact"))
            continue

        timeout = float((report.get("fuzz_config") or {}).get("timeout_seconds", 0.5))
        with tempfile.TemporaryDirectory(prefix=f"delift-replay-{case_id}-") as tmp:
            prefix = Path(tmp) / "candidate"
            completed = subprocess.run(
                ["bash", str(runner), str(brightened), str(prefix)],
                capture_output=True,
                text=True,
            )
            if completed.returncode:
                failures.append((case_id, f"bundle rc={completed.returncode}"))
                continue
            candidate = Path(tmp) / "candidate.eval.bin"
            compile_to_binary(str(prefix.with_suffix(".ll")), str(candidate))
            mismatch = None
            for index, payload in enumerate(payloads):
                result1 = run_binary(str(candidate), [], payload, timeout)
                result2 = run_binary(str(originals[0]), [], payload, timeout)
                equivalent, reason = check_equivalence(
                    result1,
                    result2,
                    compare_stderr=False,
                    stdin_data=payload,
                    case_id=case_id,
                )
                if not equivalent:
                    stable1 = is_stable_observation(
                        str(candidate), [], payload, timeout, result1, False
                    )
                    stable2 = is_stable_observation(
                        str(originals[0]), [], payload, timeout, result2, False
                    )
                    if (
                        not stable1
                        or not stable2
                        or is_inconclusive_pair(result1, result2)
                        or (
                            result1["status"] == "timeout"
                            and result2["status"] == "timeout"
                        )
                    ):
                        continue
                if not equivalent:
                    mismatch = (
                        f"payload={index} reason={reason} "
                        f"candidate={result1['status']}:{result1['returncode']} "
                        f"original={result2['status']}:{result2['returncode']}"
                    )
                    break
            checked += 1
            if mismatch:
                failures.append((case_id, mismatch))
                print(f"FAIL {case_id} {mismatch}")
            else:
                print(f"PASS {case_id} payloads={len(payloads)}")

    print(f"SUMMARY checked={checked} failed={len(failures)}")
    for case_id, reason in failures:
        print(f"  {case_id}: {reason}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
