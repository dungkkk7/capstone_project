#!/usr/bin/env python3
"""Run LLVM's O3 pipeline through the installed opt binary."""

import shutil
import subprocess
import sys


opt = shutil.which("opt-21") or shutil.which("opt")
if not opt:
    raise SystemExit("opt-21/opt not found")
subprocess.run(
    [opt, "-S", "-passes=default<O3>,verify", sys.argv[1], "-o", sys.argv[2]],
    check=True,
)
