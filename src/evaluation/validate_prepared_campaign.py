#!/usr/bin/env python3
"""Differentially validate finalized F3 binaries against original ELFs."""

from __future__ import annotations

import argparse
import csv
import json
import os
import random
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from fuzzing_equi_check.fuzzing import SemanticFuzzer
from fuzzing_equi_check.input_contracts import resolve_input_contract
from main import _resolve_seed_paths, _select_generator


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("campaign")
    parser.add_argument("--iterations", type=int, default=100)
    args = parser.parse_args()
    campaign = Path(args.campaign)
    if not campaign.is_absolute():
        campaign = (PROJECT_ROOT / campaign).resolve()
    manifest = json.loads(
        (campaign / "protocol_manifest.json").read_text(encoding="utf-8")
    )
    dataset = Path(manifest["dataset"])
    rows = list(csv.DictReader(dataset.open(newline="", encoding="utf-8")))
    results = []
    os.environ["BRIGHTEN_USE_AFL"] = "0"

    for index, row in enumerate(rows, 1):
        original = (PROJECT_ROOT / row["obfuscated_binary"]).resolve()
        case_id = original.parent.name
        finalized = campaign / case_id / f"{case_id}_final.bin"
        if not finalized.is_file():
            results.append({
                "sample_id": case_id,
                "status": "INCONCLUSIVE",
                "reason": "missing finalized executable",
            })
            continue
        generator, _ = _select_generator(PROJECT_ROOT, str(original))
        seeds, _ = _resolve_seed_paths(PROJECT_ROOT, str(original))
        contract = resolve_input_contract(PROJECT_ROOT, str(original))
        random.seed(260815 + index)
        fuzzer = SemanticFuzzer(
            str(finalized), str(original), seed_paths=seeds, input_contract=contract
        )
        try:
            fuzzer.compile()
            report = fuzzer.run_differential_test_fallback(
                iterations=args.iterations,
                generator=generator,
                timeout=0.1,
                compare_stderr=True,
                num_workers=4,
                strict_oracle=True,
            )
            mismatches = int(report.get("mismatches", 0) or 0)
            inconclusive = int(report.get("inconclusive", 0) or 0)
            results.append({
                "sample_id": case_id,
                "status": "PASS" if mismatches == 0 and inconclusive == 0 else "FAIL",
                "total_runs": int(report.get("total_runs", 0) or 0),
                "matches": int(report.get("matches", 0) or 0),
                "mismatches": mismatches,
                "inconclusive": inconclusive,
                "mismatch_examples": report.get("mismatch_examples", []),
            })
        except Exception as error:
            results.append({
                "sample_id": case_id,
                "status": "INCONCLUSIVE",
                "reason": f"{type(error).__name__}: {error}",
            })
        finally:
            fuzzer.cleanup()
        print(f"[{index}/{len(rows)}] {case_id}: {results[-1]['status']}", flush=True)

    payload = {
        "campaign": str(campaign),
        "optimization_level": manifest["f3_llvm_optimization_level"],
        "iterations_per_case": args.iterations,
        "counts": {
            status: sum(item["status"] == status for item in results)
            for status in ("PASS", "FAIL", "INCONCLUSIVE")
        },
        "cases": results,
    }
    output = campaign / "prepared_binary_validation.json"
    output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps(payload["counts"], sort_keys=True))
    return 1 if payload["counts"]["FAIL"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
