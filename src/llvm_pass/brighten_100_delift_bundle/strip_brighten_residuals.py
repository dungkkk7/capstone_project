#!/usr/bin/env python3
from pathlib import Path
import re, sys

if len(sys.argv) != 3:
    raise SystemExit(f'usage: {sys.argv[0]} INPUT.ll OUTPUT.ll')

src, dst = map(Path, sys.argv[1:])
s = src.read_text()

# Brighten preserves synthetic data/register maps through llvm.used metadata.
# Once all live native.data.pointer.select chains and fake storage references are gone,
# these roots only prevent normal LLVM GlobalDCE from deleting dead residual blobs.
s, n_used = re.subn(r'^@llvm\.used\s*=.*\n', '', s, flags=re.M)
s, n_compiler_used = re.subn(r'^@llvm\.compiler\.used\s*=.*\n', '', s, flags=re.M)

dst.write_text(s)
print(f'removed llvm.used definitions: {n_used}')
print(f'removed llvm.compiler.used definitions: {n_compiler_used}')
