#!/usr/bin/env python3
"""Freeze p02814 late residual format recovery in the production lifecycle."""

from __future__ import annotations

from pathlib import Path
import json
import os
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[4]
INPUT = (ROOT / "result/pipeline_20260727_061847/p02814/"
         "s915631953_fla_bcf_instsub.ll")
PLUGIN = (ROOT / "src/llvm_pass/brighten_070_global_data_recovery/build/"
          "BrightenGlobalDataRecoveryPass.so")


def run_pipeline(output_bc: Path, *, disable_late_rule: bool) -> None:
    env = os.environ.copy()
    if disable_late_rule:
        env["BRIGHTEN_SKIP_PASSES"] = "brighten-late-residual-format-string-recovery"
    subprocess.run([
        sys.executable, "src/llvm_pass/britening_ir.py", "-i", str(INPUT),
        "-o", str(output_bc),
    ], cwd=ROOT, env=env, check=True)


def main() -> int:
    if not INPUT.exists() or not PLUGIN.exists():
        print("SKIP: p02814 late-format lifecycle fixture unavailable")
        return 0
    with tempfile.TemporaryDirectory(prefix="brighten-070-p02814-strings-") as tmp:
        work = Path(tmp)
        output_bc = work / "enabled.bc"
        output_ll = work / "enabled.ll"
        output_contract = work / "enabled_native_contract_report.json"
        disabled_bc = work / "disabled.bc"
        disabled_contract = work / "disabled_native_contract_report.json"
        run_pipeline(disabled_bc, disable_late_rule=True)
        run_pipeline(output_bc, disable_late_rule=False)
        subprocess.run(["opt-21", "-passes=verify", "-disable-output", str(output_bc)],
                       check=True)
        subprocess.run(["llvm-dis-21", str(output_bc), "-o", str(output_ll)],
                       check=True)
        subprocess.run(["clang-21", str(output_bc), "-o", str(work / "native")],
                       check=True)
        text = output_ll.read_text()
        expected = (
            'constant [3 x i8] c"%s\\00"',
            'constant [5 x i8] c"%d%d\\00"',
            'constant [3 x i8] c"%d\\00"',
            'constant [4 x i8] c"%d\\0A\\00"',
        )
        string_defs = [line for line in text.splitlines()
                       if line.startswith("@.late.residual.str.")]
        missing = [needle for needle in expected
                   if not any(needle in definition for definition in string_defs)]
        if missing:
            raise SystemExit("p02814 missing exact readonly strings: " +
                             ", ".join(missing))
        if len(string_defs) != 4:
            raise SystemExit("p02814 late string object count is not exactly four")
        if "@native_residual_403000__rodata_10" not in text:
            raise SystemExit("p02814 incorrectly removed mixed rodata residual")
        for line in text.splitlines():
            if "call" not in line or not any(name in line for name in (
                    "@printf", "@sscanf", "@vfscanf", "@vsprintf")):
                continue
            if "@native_residual_403000__rodata_10" in line:
                raise SystemExit("p02814 format call still uses residual: " + line)
        for line in text.splitlines():
            if line.startswith("@.late.residual.str.") and "!brighten.guest.range" in line:
                raise SystemExit("late native string retained guest-range metadata")
        disabled = json.loads(disabled_contract.read_text())
        current = json.loads(output_contract.read_text())
        if (current["metrics"]["native_contract_violations"] !=
                disabled["metrics"]["native_contract_violations"]):
            raise SystemExit("late format recovery changed native-contract findings")
    print("PASS: p02814 late residual format lifecycle")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
