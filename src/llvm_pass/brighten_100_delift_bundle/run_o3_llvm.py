#!/usr/bin/env python3
"""Run LLVM's O3 pipeline through the installed opt binary."""

import shutil
import subprocess
import os
import sys


opt = shutil.which("opt-21") or shutil.which("opt")
if not opt:
    raise SystemExit("opt-21/opt not found")
pipeline = os.environ.get("DELIFT_OPT_PIPELINE", "default<O3>,verify")
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
