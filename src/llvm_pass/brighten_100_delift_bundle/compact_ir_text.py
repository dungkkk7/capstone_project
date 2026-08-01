#!/usr/bin/env python3
"""Remove non-semantic whitespace from final textual LLVM IR."""
from pathlib import Path
import sys

src, dst = map(Path, sys.argv[1:3])
lines = src.read_text().splitlines()
# Standalone comments and blank lines carry no LLVM semantics. Keep inline
# predecessor comments because they share a label line and aid CFG debugging.
out = [line for line in lines if line.strip() and not line.lstrip().startswith(';')]
dst.write_text("\n".join(out) + "\n")
print(f"textual lines: {len(lines)} -> {len(out)}")
