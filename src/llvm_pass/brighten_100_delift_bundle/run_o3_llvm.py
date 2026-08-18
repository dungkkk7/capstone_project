#!/usr/bin/env python3
"""Run a declared LLVM default<O1/O2/O3> pipeline through opt."""

import shutil
import subprocess
import os
import sys


opt = shutil.which("opt-21") or shutil.which("opt")
if not opt:
    raise SystemExit("opt-21/opt not found")
level = os.environ.get("DELIFT_OPT_LEVEL", os.environ.get("BRIGHTEN_OPT_LEVEL", "O3"))
level = level.strip().upper()
if level not in {"O1", "O2", "O3"}:
    raise SystemExit(f"DELIFT_OPT_LEVEL must be O1, O2, or O3; received {level!r}")
pipeline = os.environ.get("DELIFT_OPT_PIPELINE", f"default<{level}>,verify")
command = [opt, "-S"]
if os.environ.get("DELIFT_ENABLE_VECTORIZATION", "0").lower() not in {
    "1", "true", "yes", "on"
}:
    command.extend(["-vectorize-loops=false", "-vectorize-slp=false"])
if os.environ.get("DELIFT_ENABLE_LOOP_UNROLLING", "0").lower() not in {
    "1", "true", "yes", "on"
}:
    command.append("-disable-loop-unrolling")
command.extend([f"-passes={pipeline}", sys.argv[1], "-o", sys.argv[2]])
subprocess.run(command, check=True)
