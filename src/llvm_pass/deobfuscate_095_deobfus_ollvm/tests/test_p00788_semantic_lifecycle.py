#!/usr/bin/env python3
"""Freeze the p00788 semantic canary across the production lifecycle."""

from __future__ import annotations

import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[4]
CASE = "p00788"
STEM = "s998194081_fla_bcf_instsub"


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
REPORT = RUN_DIR / f"{STEM}_semantic_report.json"
ORIGINAL = ROOT / "data" / "obfuscated" / CASE / "s998194081_fla_bcf_instsub.elf"
PLUGIN = ROOT / "src" / "llvm_pass" / "deobfuscate_095_deobfus_ollvm" / "build" / "lib095.so"
PRODUCTION_CASES = (
    ROOT / "src" / "llvm_pass" / "deobfuscate_095_deobfus_ollvm" / "tests" / "production_cases.ll"
)


def run(command: list[str], **kwargs: object) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(command, check=True, **kwargs)


def frozen_payloads() -> list[bytes]:
    report = json.loads(REPORT.read_text())
    payloads = report.get("tested_payloads")
    if not isinstance(payloads, list) or not payloads:
        raise SystemExit("p00788 frozen payload evidence is absent")
    decoded = [base64.b64decode(item, validate=True) for item in payloads]
    # 2026-08-01 semantic canary: deflattening a dispatcher with undef-backed
    # PHI carriers changed the chosen denominator and raised SIGFPE.
    sigfpe_counterexample = b"250 350\n46 61\n203 233\n4 96\n0 0\n"
    if sigfpe_counterexample not in decoded:
        decoded.append(sigfpe_counterexample)
    return decoded


def main() -> int:
    required = (INPUT, REPORT, ORIGINAL, PLUGIN, PRODUCTION_CASES)
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("p00788 lifecycle fixture unavailable: " + ", ".join(missing))

    with tempfile.TemporaryDirectory(prefix="p00788-095-") as temp:
        temp_dir = Path(temp)
        candidate_bc = temp_dir / "candidate.bc"
        candidate_ll = temp_dir / "candidate.ll"
        candidate_prefix = temp_dir / "candidate.final"
        candidate_bin = temp_dir / "candidate.final.bin"
        env = {"BRIGHTEN_OPT_TIMEOUT": "120"}
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
            env={**os.environ, **env},
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

        for index, payload in enumerate(frozen_payloads()):
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
                raise SystemExit(f"p00788 frozen differential mismatch at payload {index}")

        # Negative overmatch: a clean SSA dispatcher has no undef/poison PHI
        # carriers and must remain eligible for normal 095 deflattening.
        clean_ll = temp_dir / "clean.ll"
        clean_report = temp_dir / "clean.json"
        run([
            "opt-21", "-load-pass-plugin", str(PLUGIN),
            f"-095-report={clean_report}", "-passes=095", str(PRODUCTION_CASES),
            "-S", "-o", str(clean_ll),
        ])
        if json.loads(clean_report.read_text())["stages"]["deflatten"]["changes"] <= 0:
            raise SystemExit("undef/poison PHI gate overmatched clean SSA dispatcher")

    print("p00788 lifecycle + frozen differential regression passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
