#!/usr/bin/env python3
"""Runtime properties for byte-accurate overlapping State promotion."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


MODULE = r"""
%struct.State = type { [64 x i8] }

define i64 @patch_byte(i64 %base, i8 %value) {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %wide = getelementptr i8, ptr %state, i64 0
  %byte = getelementptr i8, ptr %state, i64 1
  store i64 %base, ptr %wide, align 8
  store i8 %value, ptr %byte, align 1
  %result = load i64, ptr %wide, align 8
  ret i64 %result
}

define i64 @patch_middle_i32(i64 %base, i32 %value) {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %wide = getelementptr i8, ptr %state, i64 8
  %middle = getelementptr i8, ptr %state, i64 10
  store i64 %base, ptr %wide, align 8
  store i32 %value, ptr %middle, align 2
  %result = load i64, ptr %wide, align 8
  ret i64 %result
}

define i32 @extract_unaligned_i16(i64 %base) {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %wide = getelementptr i8, ptr %state, i64 16
  %part = getelementptr i8, ptr %state, i64 17
  store i64 %base, ptr %wide, align 8
  %value = load i16, ptr %part, align 1
  %result = zext i16 %value to i32
  ret i32 %result
}
"""


DRIVER = r"""
#include <stdint.h>

extern uint64_t patch_byte(uint64_t, uint8_t);
extern uint64_t patch_middle_i32(uint64_t, uint32_t);
extern uint32_t extract_unaligned_i16(uint64_t);

static uint64_t step(uint64_t *state) {
  uint64_t x = *state;
  x ^= x << 13;
  x ^= x >> 7;
  x ^= x << 17;
  return *state = x;
}

int main(void) {
  uint64_t state = UINT64_C(0x9e3779b97f4a7c15);
  for (unsigned i = 0; i != 10000; ++i) {
    uint64_t base = step(&state);
    uint64_t bits = step(&state);
    uint8_t byte = (uint8_t)bits;
    uint32_t word = (uint32_t)(bits >> 8);
    uint64_t expect_byte = (base & ~UINT64_C(0xff00)) |
                           ((uint64_t)byte << 8);
    uint64_t expect_word = (base & ~UINT64_C(0x0000ffffffff0000)) |
                           ((uint64_t)word << 16);
    if (patch_byte(base, byte) != expect_byte) return 1;
    if (patch_middle_i32(base, word) != expect_word) return 2;
    if (extract_unaligned_i16(base) != (uint16_t)(base >> 8)) return 3;
  }
  return 0;
}
"""


GLOBAL_MODULE = r"""
target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

define internal void @patch_global_byte(ptr %state, i8 %value) {
entry:
  %byte = getelementptr i8, ptr %state, i64 1
  store i8 %value, ptr %byte, align 1
  ret void
}

define ptr @sub_global_patch(ptr %state, i64 %pc, ptr %memory,
                             i64 %base, i8 %value) {
entry:
  %wide = getelementptr i8, ptr %state, i64 0
  store i64 %base, ptr %wide, align 1
  call void @patch_global_byte(ptr %state, i8 %value)
  %merged = load i64, ptr %wide, align 1
  %result = getelementptr i8, ptr %state, i64 8
  store i64 %merged, ptr %result, align 1
  ret ptr %memory
}
"""


GLOBAL_DRIVER = r"""
#include <stdint.h>
#include <string.h>

extern void *sub_global_patch(void *, uint64_t, void *, uint64_t, uint8_t);

static uint64_t step(uint64_t *state) {
  uint64_t x = *state;
  x ^= x << 13;
  x ^= x >> 7;
  x ^= x << 17;
  return *state = x;
}

int main(void) {
  uint64_t random = UINT64_C(0xd1b54a32d192ed03);
  for (unsigned i = 0; i != 10000; ++i) {
    uint64_t state[2] = {0, 0};
    uint64_t base = step(&random);
    uint8_t byte = (uint8_t)step(&random);
    sub_global_patch(state, 0, 0, base, byte);
    uint64_t expected = (base & ~UINT64_C(0xff00)) |
                        ((uint64_t)byte << 8);
    if (state[1] != expected) return 1;
  }
  return 0;
}
"""


def checked(command):
    subprocess.run(command, check=True, capture_output=True, text=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--plugin", required=True)
    args = parser.parse_args()
    opt = shutil.which("opt-21") or shutil.which("opt")
    clang = shutil.which("clang-21") or shutil.which("clang")
    if not opt or not clang:
        raise SystemExit("LLVM opt and clang are required")

    with tempfile.TemporaryDirectory() as directory:
        directory = Path(directory)
        before = directory / "before.ll"
        after = directory / "after.ll"
        driver = directory / "driver.c"
        before.write_text(MODULE, encoding="utf-8")
        driver.write_text(DRIVER, encoding="utf-8")
        checked([
            opt, "-load-pass-plugin", args.plugin,
            "-passes=brighten-local-state-ssa-pass,verify",
            "-S", before, "-o", after,
        ])
        transformed = after.read_text(encoding="utf-8")
        assert "alloca %struct.State" not in transformed
        for module, output in ((before, directory / "before.bin"),
                               (after, directory / "after.bin")):
            checked([clang, "-O2", driver, module, "-o", output])
            checked([output])

        global_before = directory / "global-before.ll"
        global_after = directory / "global-after.ll"
        global_driver = directory / "global-driver.c"
        global_before.write_text(GLOBAL_MODULE, encoding="utf-8")
        global_driver.write_text(GLOBAL_DRIVER, encoding="utf-8")
        checked([
            opt, "-load-pass-plugin", args.plugin,
            "-passes=brighten-state-ssa-pass,verify",
            "-S", global_before, "-o", global_after,
        ])
        transformed_global = global_after.read_text(encoding="utf-8")
        assert "%state_0 = alloca i64" in transformed_global
        for module, output in (
            (global_before, directory / "global-before.bin"),
            (global_after, directory / "global-after.bin"),
        ):
            checked([clang, "-O2", global_driver, module, "-o", output])
            checked([output])


if __name__ == "__main__":
    main()
