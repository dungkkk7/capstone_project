#!/usr/bin/env python3
"""Exhaustive i8 execution for producer-wide sub/add/test flag bundles."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


SUB_DRIVER = r"""
#include <stdint.h>

extern uint8_t sub_flag_bundle(uint8_t, uint8_t);

int main(void) {
  for (unsigned a = 0; a != 256; ++a) {
    for (unsigned b = 0; b != 256; ++b) {
      uint8_t av = (uint8_t)a, bv = (uint8_t)b;
      uint8_t diff = (uint8_t)(av - bv);
      unsigned zf = diff == 0;
      unsigned sf = diff >> 7;
      unsigned of = (((av ^ bv) & (av ^ diff)) >> 7) & 1;
      unsigned cf = av < bv;
      unsigned pf = __builtin_parity((unsigned)diff) == 0;
      unsigned l = (int8_t)av < (int8_t)bv;
      unsigned le = (int8_t)av <= (int8_t)bv;
      unsigned ae = av >= bv;
      uint8_t expected = (uint8_t)(zf | (sf << 1) | (of << 2) |
                                   (cf << 3) | (pf << 4) | (l << 5) |
                                   (le << 6) | (ae << 7));
      if (sub_flag_bundle(av, bv) != expected) return 1;
    }
  }
  return 0;
}
"""

ADD_DRIVER = r"""
#include <stdint.h>

extern uint8_t add_flag_bundle(uint8_t, uint8_t);

int main(void) {
  for (unsigned a = 0; a != 256; ++a) {
    for (unsigned b = 0; b != 256; ++b) {
      uint8_t av = (uint8_t)a, bv = (uint8_t)b;
      uint8_t sum = (uint8_t)(av + bv);
      unsigned zf = sum == 0;
      unsigned sf = sum >> 7;
      unsigned of = (((~(av ^ bv)) & (av ^ sum)) >> 7) & 1;
      unsigned cf = sum < av;
      unsigned pf = __builtin_parity((unsigned)sum) == 0;
      uint8_t expected = (uint8_t)(zf | (sf << 1) | (of << 2) |
                                   (cf << 3) | (pf << 4));
      if (add_flag_bundle(av, bv) != expected) return 1;
    }
  }
  return 0;
}
"""

TEST_DRIVER = r"""
#include <stdint.h>

extern uint8_t test_flag_bundle(uint8_t, uint8_t);

int main(void) {
  for (unsigned a = 0; a != 256; ++a) {
    for (unsigned b = 0; b != 256; ++b) {
      uint8_t result = (uint8_t)a & (uint8_t)b;
      unsigned zf = result == 0;
      unsigned sf = result >> 7;
      unsigned pf = __builtin_parity((unsigned)result) == 0;
      unsigned nz = result != 0;
      uint8_t expected = (uint8_t)(zf | (sf << 1) | (pf << 2) | (nz << 3));
      if (test_flag_bundle((uint8_t)a, (uint8_t)b) != expected) return 1;
    }
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
    opt = shutil.which("opt-21")
    extract = shutil.which("llvm-extract-21")
    clang = shutil.which("clang-21")
    if not opt or not extract or not clang:
        raise SystemExit("opt-21, llvm-extract-21, and clang-21 are required")
    with tempfile.TemporaryDirectory() as directory:
        directory = Path(directory)
        cases = (
            ("x86_sub_flag_bundle.ll", "sub_flag_bundle", SUB_DRIVER),
            ("x86_add_flag_bundle.ll", "add_flag_bundle", ADD_DRIVER),
            ("x86_test_flag_bundle.ll", "test_flag_bundle", TEST_DRIVER),
        )
        for filename, function, driver_text in cases:
            source = Path(__file__).with_name(filename)
            stem = function.removesuffix("_flag_bundle")
            after = directory / f"{stem}.after.ll"
            ledger = directory / f"{stem}.ledger.json"
            driver = directory / f"{stem}.driver.c"
            driver.write_text(driver_text)
            checked([
                opt, "-load-pass-plugin", args.plugin,
                f"-ollvm-deobf-report={ledger}",
                "-passes=brighten-ollvm-deobf-pass,verify", "-S", source,
                "-o", after,
            ])
            for module, phase in ((source, "before"), (after, "after")):
                extracted = directory / f"{stem}.{phase}.bc"
                binary = directory / f"{stem}.{phase}.bin"
                checked([extract, f"--func={function}", module, "-o", extracted])
                checked([clang, "-O2", driver, extracted, "-o", binary])
                checked([binary])


if __name__ == "__main__":
    main()
