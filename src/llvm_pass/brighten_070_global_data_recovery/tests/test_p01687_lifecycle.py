#!/usr/bin/env python3
"""Regression: 070 must remain total inside the production lifecycle.

Run manually or from the CI dataset lane.  This intentionally uses the
original lifted p01687 bitcode that previously crashed immediately after
global-data candidate generation.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
INPUT = os.path.join(
    ROOT,
    "result/pipeline_20260727_040826/p01687/"
    "s146593197_fla_bcf_instsub.bc",
)

if not os.path.exists(INPUT):
    print("SKIP: p01687 lifecycle fixture is not present")
    sys.exit(0)

with tempfile.TemporaryDirectory(prefix="brighten-070-p01687-") as tmp:
    output = os.path.join(tmp, "semantic_canary.bc")
    env = os.environ.copy()
    env.setdefault("BRIGHTEN_OPT_TIMEOUT", "300")
    result = subprocess.run(
        [sys.executable, "src/llvm_pass/britening_ir.py", "-i", INPUT,
         "-o", output],
        cwd=ROOT,
        env=env,
        timeout=330,
    )
    if result.returncode != 0 or not os.path.exists(output):
        raise SystemExit("p01687 lifecycle regression failed")

print("PASS: p01687 lifecycle")
