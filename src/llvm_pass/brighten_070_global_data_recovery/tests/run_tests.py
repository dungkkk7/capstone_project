from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "build/BrightenGlobalDataRecoveryPass.so"
OPT = os.environ.get("OPT_BIN", "/usr/bin/opt-21")


def run_ir(text: str) -> str:
    with tempfile.TemporaryDirectory() as td:
        src = Path(td) / "in.ll"
        out = Path(td) / "out.ll"
        src.write_text(text)
        proc = subprocess.run(
            [
                OPT,
                f"-load-pass-plugin={PLUGIN}",
                "-passes=brighten-global-data-recovery-pass,verify",
                "-S",
                str(src),
                "-o",
                str(out),
            ],
            text=True,
            capture_output=True,
        )
        if proc.returncode:
            raise AssertionError(proc.stderr)
        return out.read_text()


DL = 'target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"\n'

# Exact typed range: every observed reference has identical provenance/type,
# so the segment byte range may become one native i32 global.
scalar = run_ir(
    DL
    + r'''
@seg_404000__data = internal global [8 x i8] c"\2A\00\00\00\00\00\00\00"
define i32 @f(i32 %x) {
entry:
  %p = getelementptr [8 x i8], ptr @seg_404000__data, i64 0, i64 0
  %a = load i32, ptr %p
  store i32 %x, ptr %p
  %b = load i32, ptr %p
  %r = add i32 %a, %b
  ret i32 %r
}
'''
)
assert "g_recovered_" in scalar
assert "load i32, ptr @g_recovered_" in scalar
assert "store i32 %x, ptr @g_recovered_" in scalar

# Immutable C-string consumer: bytes are copied exactly through the NUL and
# the call no longer points at the lifted segment.
string = run_ir(
    DL
    + r'''
@seg_402000__rodata = internal global [7 x i8] c"hello\0A\00"
declare i32 @puts(ptr)
define i32 @f() {
entry:
  %p = getelementptr [7 x i8], ptr @seg_402000__rodata, i64 0, i64 0
  %r = call i32 @puts(ptr %p)
  ret i32 %r
}
'''
)
assert ".str.recovered." in string
assert "call i32 @puts(ptr @.str.recovered." in string

# Overlapping incompatible typed views are one guest byte range with two LLVM
# interpretations. Splitting them would destroy aliasing, so the segment must
# remain authoritative.
overlap = run_ir(
    DL
    + r'''
@seg_500000__data = internal global [8 x i8] zeroinitializer
define i64 @f() {
entry:
  %p0 = getelementptr [8 x i8], ptr @seg_500000__data, i64 0, i64 0
  %p2 = getelementptr [8 x i8], ptr @seg_500000__data, i64 0, i64 2
  store i32 1, ptr %p0
  %x = load i32, ptr %p2
  %r = zext i32 %x to i64
  ret i64 %r
}
'''
)
assert "@seg_500000__data" in overlap
assert "g_recovered_" not in overlap

# A dynamic carrier is deliberately not converted into an independent native
# object; no range/alias proof exists yet.
dynamic = run_ir(
    DL
    + r'''
@seg_600000__data = internal global [32 x i8] zeroinitializer
define i8 @f(i64 %i) {
entry:
  %p = getelementptr [32 x i8], ptr @seg_600000__data, i64 0, i64 %i
  %v = load i8, ptr %p
  ret i8 %v
}
'''
)
assert "@seg_600000__data" in dynamic
assert "g_recovered_" not in dynamic

print("070 byte-range provenance tests: PASS")
