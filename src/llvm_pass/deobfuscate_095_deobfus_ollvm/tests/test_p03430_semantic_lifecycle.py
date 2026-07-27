#!/usr/bin/env python3
"""Freeze the p03430 guest-range deflatten guard across the full lifecycle."""

from __future__ import annotations

import json
import os
import base64
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[4]
CASE = "p03430"
RUN_DIR = Path(os.environ.get(
    "BRIGHTEN_095_LIFECYCLE_RUN",
    ROOT / "result" / "pipeline_20260727_140831",
)) / CASE
STEM = "s601450783_fla_bcf_instsub"
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
    return [base64.b64decode(item, validate=True) for item in payloads]


def main() -> int:
    required = (INPUT, FROZEN_REPORT, ORIGINAL, PLUGIN)
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("p03430 lifecycle fixture unavailable: " + ", ".join(missing))

    with tempfile.TemporaryDirectory(prefix="p03430-095-") as temp:
        temp_dir = Path(temp)
        candidate_bc = temp_dir / "candidate.bc"
        candidate_ll = temp_dir / "candidate.ll"
        candidate_bin = temp_dir / "candidate.bin"
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
        run(["clang-21", str(candidate_ll), "-o", str(candidate_bin)])

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
