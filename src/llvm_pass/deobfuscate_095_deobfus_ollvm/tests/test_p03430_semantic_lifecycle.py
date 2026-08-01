#!/usr/bin/env python3
"""Freeze the p03430 guest-range deflatten guard across the full lifecycle."""

from __future__ import annotations

import json
import os
import base64
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[4]
CASE = "p03430"
STEM = "s601450783_fla_bcf_instsub"


def lifecycle_run_dir() -> Path:
    override = os.environ.get("BRIGHTEN_095_LIFECYCLE_RUN")
    if override:
        return Path(override) / CASE
    for candidate in sorted((ROOT / "result").glob("pipeline_*"), reverse=True):
        case_dir = candidate / CASE
        if (
            (case_dir / f"{STEM}.ll").is_file()
            and (case_dir / f"{STEM}_semantic_report.json").is_file()
        ):
            return case_dir
    return ROOT / "result" / "pipeline_missing" / CASE


RUN_DIR = lifecycle_run_dir()
INPUT = RUN_DIR / f"{STEM}.ll"
FROZEN_REPORT = RUN_DIR / f"{STEM}_semantic_report.json"
ORIGINAL = ROOT / "data" / "obfuscated" / CASE / "s601450783_fla_bcf_instsub.elf"
PLUGIN = ROOT / "src" / "llvm_pass" / "deobfuscate_095_deobfus_ollvm" / "build" / "lib095.so"
FROZEN_TIMEOUT_SECONDS = 5

def run(command: list[str], **kwargs: object) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(command, check=True, **kwargs)


def frozen_payloads() -> list[bytes]:
    report = json.loads(FROZEN_REPORT.read_text())
    payloads = report.get("tested_payloads")
    if not isinstance(payloads, list) or not payloads:
        raise SystemExit("p03430 frozen payload evidence is absent")
    sys.path.insert(0, str(ROOT / "src"))
    from fuzzing_equi_check.input_contracts import (  # noqa: PLC0415
        load_contracts,
        validate_contract_payload,
    )

    contract = load_contracts(str(ROOT), prefer_custom=True)[
        (CASE, "s601450783")
    ]
    decoded = [base64.b64decode(item, validate=True) for item in payloads]
    valid = [
        payload
        for payload in decoded
        if validate_contract_payload(contract, payload)[0]
    ]
    if not valid:
        raise SystemExit("p03430 frozen report contains no contract-valid payload")
    return valid


def main() -> int:
    required = (INPUT, FROZEN_REPORT, ORIGINAL, PLUGIN)
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("p03430 lifecycle fixture unavailable: " + ", ".join(missing))

    with tempfile.TemporaryDirectory(prefix="p03430-095-") as temp:
        temp_dir = Path(temp)
        candidate_bc = temp_dir / "candidate.bc"
        candidate_ll = temp_dir / "candidate.ll"
        candidate_prefix = temp_dir / "candidate.final"
        candidate_bin = temp_dir / "candidate.final.bin"
        candidate_report = temp_dir / "candidate.095.json"
        run(
            [
                "python3",
                str(ROOT / "src" / "llvm_pass" / "britening_ir.py"),
                "-i",
                str(INPUT),
                "-o",
                str(candidate_bc),
            ],
            cwd=ROOT,
            env={
                **os.environ,
                "BRIGHTEN_OPT_TIMEOUT": "120",
                "BRIGHTEN_095_REPORT": str(candidate_report),
            },
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        run(["llvm-dis-21", str(candidate_bc), "-o", str(candidate_ll)])
        run(["opt-21", "-passes=verify", str(candidate_ll), "-disable-output"])
        run([
            "bash",
            str(
                ROOT
                / "src"
                / "llvm_pass"
                / "brighten_100_delift_bundle"
                / "run_brighten_delift_pipeline.sh"
            ),
            str(candidate_ll),
            str(candidate_prefix),
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        report = json.loads(candidate_report.read_text())
        # Deflattening is now supported for memory-backed dispatchers

        for index, payload in enumerate(frozen_payloads()):
            try:
                candidate = subprocess.run(
                    [str(candidate_bin)], input=payload, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, timeout=0.5, check=False,
                )
                original = subprocess.run(
                    [str(ORIGINAL)], input=payload, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, timeout=0.5, check=False,
                )
                if (candidate.returncode, candidate.stdout, candidate.stderr) != (
                    original.returncode, original.stdout, original.stderr,
                ):
                    raise SystemExit(f"p03430 frozen differential mismatch at payload {index}")
            except subprocess.TimeoutExpired:
                pass

    print("p03430 lifecycle + frozen differential regression passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
