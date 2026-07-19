#!/usr/bin/env python3
"""Deterministic property execution for proof-backed BV saturation."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


MODULE = r"""
define i32 @affine(i32 %x) {
  %a = mul i32 %x, 3
  %b = mul i32 %x, 5
  %c = add i32 %a, %b
  %d = mul i32 %x, 7
  %e = sub i32 %c, %d
  %r = add i32 %e, 9
  ret i32 %r
}

define i32 @and_ac(i32 %x, i32 %y) {
  %a = and i32 %x, %y
  %r = and i32 %a, %x
  ret i32 %r
}

define i32 @or_ac(i32 %x, i32 %y) {
  %a = or i32 %x, %y
  %r = or i32 %a, %y
  ret i32 %r
}

define i32 @xor_frozen_ac(i32 %x, i32 %y) {
  %f = freeze i32 %x
  %a = xor i32 %f, %y
  %r = xor i32 %a, %f
  ret i32 %r
}

define i1 @zf_sub8(i8 %a, i8 %b) {
  %r = sub i8 %a, %b
  %zf = icmp eq i8 %r, 0
  ret i1 %zf
}

define i1 @sf_xor_of8(i8 %a, i8 %b) {
  %r = sub i8 %a, %b
  %sf.shift = lshr i8 %r, 7
  %sf = trunc i8 %sf.shift to i1
  %ab = xor i8 %a, %b
  %ar = xor i8 %a, %r
  %of.bits = and i8 %ab, %ar
  %of.shift = lshr i8 %of.bits, 7
  %of = trunc i8 %of.shift to i1
  %result = xor i1 %sf, %of
  ret i1 %result
}

define i1 @standalone_sf8(i8 %a) {
  %shift = lshr i8 %a, 7
  %sf = trunc i8 %shift to i1
  ret i1 %sf
}

define i1 @add_cf8(i8 %a, i8 %b) {
  %sum = add i8 %a, %b
  %generate = and i8 %a, %b
  %either = or i8 %a, %b
  %not.sum = xor i8 %sum, -1
  %propagate = and i8 %either, %not.sum
  %carry.bits = or i8 %generate, %propagate
  %shift = lshr i8 %carry.bits, 7
  %cf = trunc i8 %shift to i1
  ret i1 %cf
}

define i1 @sub_cf8(i8 %a, i8 %b) {
  %diff = sub i8 %a, %b
  %not.a = xor i8 %a, -1
  %generate = and i8 %not.a, %b
  %ab = xor i8 %a, %b
  %not.ab = xor i8 %ab, -1
  %propagate = and i8 %not.ab, %diff
  %borrow.bits = or i8 %generate, %propagate
  %shift = lshr i8 %borrow.bits, 7
  %cf = trunc i8 %shift to i1
  ret i1 %cf
}

define i1 @pf8(i8 %value) {
  %s4 = lshr i8 %value, 4
  %x4 = xor i8 %value, %s4
  %s2 = lshr i8 %x4, 2
  %x2 = xor i8 %x4, %s2
  %s1 = lshr i8 %x2, 1
  %x1 = xor i8 %x2, %s1
  %odd = trunc i8 %x1 to i1
  %pf = xor i1 %odd, true
  ret i1 %pf
}

define i1 @cc_ae8(i8 %a, i8 %b) {
  %cf = icmp ult i8 %a, %b
  %ae = xor i1 %cf, true
  ret i1 %ae
}

define i1 @cc_a8(i8 %a, i8 %b) {
  %cf = icmp ult i8 %a, %b
  %zf = icmp eq i8 %a, %b
  %be = or i1 %cf, %zf
  %a.cc = xor i1 %be, true
  ret i1 %a.cc
}

define i1 @cc_ge8(i8 %a, i8 %b) {
  %l = icmp slt i8 %a, %b
  %ge = xor i1 %l, true
  ret i1 %ge
}

define i1 @cc_le8(i8 %a, i8 %b) {
  %l = icmp slt i8 %a, %b
  %zf = icmp eq i8 %a, %b
  %le = or i1 %l, %zf
  ret i1 %le
}

define i1 @cc_g8(i8 %a, i8 %b) {
  %l = icmp slt i8 %a, %b
  %zf = icmp eq i8 %a, %b
  %le = or i1 %l, %zf
  %g = xor i1 %le, true
  ret i1 %g
}

define i1 @cc_ne_sub8(i8 %a, i8 %b) {
  %result = sub i8 %a, %b
  %nz = icmp ne i8 %result, 0
  ret i1 %nz
}

define i32 @rotl13(i32 %x) {
  %left = shl i32 %x, 13
  %right = lshr i32 %x, 19
  %result = or i32 %left, %right
  ret i32 %result
}

define i32 @demorgan32(i32 %x, i32 %y) {
  %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %result = and i32 %nx, %ny
  ret i32 %result
}

define i32 @factor_zext8(i8 %x, i8 %y) {
  %zx = zext i8 %x to i32
  %zy = zext i8 %y to i32
  %result = or i32 %zx, %zy
  ret i32 %result
}

define i32 @factor_mask32(i32 %x, i32 %y) {
  %xm = and i32 %x, 16711935
  %ym = and i32 %y, 16711935
  %result = xor i32 %xm, %ym
  ret i32 %result
}

define i32 @inductive_loop(i32 %limit) {
entry:
  br label %header
header:
  %state = phi i32 [ 123, %entry ], [ %next, %latch ]
  %index = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %stable = icmp eq i32 %state, 123
  br i1 %stable, label %body, label %dead
body:
  %done = icmp uge i32 %index, %limit
  br i1 %done, label %exit, label %latch
latch:
  %is.seed = icmp eq i32 %state, 123
  %next = select i1 %is.seed, i32 123, i32 99
  %inc = add i32 %index, 1
  br label %header
exit:
  ret i32 17
dead:
  ret i32 99
}
"""

DRIVER = r"""
#include <stdint.h>

extern uint32_t affine(uint32_t);
extern uint32_t and_ac(uint32_t, uint32_t);
extern uint32_t or_ac(uint32_t, uint32_t);
extern uint32_t xor_frozen_ac(uint32_t, uint32_t);
extern _Bool zf_sub8(uint8_t, uint8_t);
extern _Bool sf_xor_of8(uint8_t, uint8_t);
extern _Bool standalone_sf8(uint8_t);
extern _Bool add_cf8(uint8_t, uint8_t);
extern _Bool sub_cf8(uint8_t, uint8_t);
extern _Bool pf8(uint8_t);
extern _Bool cc_ae8(uint8_t, uint8_t);
extern _Bool cc_a8(uint8_t, uint8_t);
extern _Bool cc_ge8(uint8_t, uint8_t);
extern _Bool cc_le8(uint8_t, uint8_t);
extern _Bool cc_g8(uint8_t, uint8_t);
extern _Bool cc_ne_sub8(uint8_t, uint8_t);
extern uint32_t rotl13(uint32_t);
extern uint32_t demorgan32(uint32_t, uint32_t);
extern uint32_t factor_zext8(uint8_t, uint8_t);
extern uint32_t factor_mask32(uint32_t, uint32_t);
extern uint32_t inductive_loop(uint32_t);

static uint32_t step(uint32_t *state) {
  uint32_t x = *state;
  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;
  return *state = x;
}

int main(void) {
  uint32_t state = 0x6d2b79f5u;
  for (unsigned i = 0; i != 10000; ++i) {
    uint32_t x = step(&state);
    uint32_t y = step(&state);
    if (affine(x) != x + 9u) return 1;
    if (and_ac(x, y) != (x & y)) return 2;
    if (or_ac(x, y) != (x | y)) return 3;
    if (xor_frozen_ac(x, y) != y) return 4;
    if (rotl13(x) != ((x << 13) | (x >> 19))) return 7;
    if (demorgan32(x, y) != (~x & ~y)) return 8;
    if (factor_zext8((uint8_t)x, (uint8_t)y) !=
        (uint32_t)((uint8_t)x | (uint8_t)y)) return 9;
    if (factor_mask32(x, y) != ((x ^ y) & 0x00ff00ffu)) return 14;
    if (inductive_loop(x & 31u) != 17u) return 15;
  }
  for (unsigned a = 0; a != 256; ++a) {
    if (standalone_sf8((uint8_t)a) != ((int8_t)a < 0)) return 10;
    if (pf8((uint8_t)a) != (__builtin_parity(a) == 0)) return 11;
    for (unsigned b = 0; b != 256; ++b) {
      if (zf_sub8((uint8_t)a, (uint8_t)b) != (a == b)) return 5;
      if (sf_xor_of8((uint8_t)a, (uint8_t)b) !=
          ((int8_t)a < (int8_t)b)) return 6;
      if (add_cf8((uint8_t)a, (uint8_t)b) !=
          ((uint8_t)(a + b) < (uint8_t)a)) return 12;
      if (sub_cf8((uint8_t)a, (uint8_t)b) != (a < b)) return 13;
      if (cc_ae8((uint8_t)a, (uint8_t)b) != (a >= b)) return 16;
      if (cc_a8((uint8_t)a, (uint8_t)b) != (a > b)) return 17;
      if (cc_ge8((uint8_t)a, (uint8_t)b) !=
          ((int8_t)a >= (int8_t)b)) return 18;
      if (cc_le8((uint8_t)a, (uint8_t)b) !=
          ((int8_t)a <= (int8_t)b)) return 19;
      if (cc_g8((uint8_t)a, (uint8_t)b) !=
          ((int8_t)a > (int8_t)b)) return 20;
      if (cc_ne_sub8((uint8_t)a, (uint8_t)b) != (a != b)) return 21;
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
    clang = shutil.which("clang-21")
    if not opt or not clang:
        raise SystemExit("opt-21 and clang-21 are required")

    with tempfile.TemporaryDirectory() as directory:
        directory = Path(directory)
        before = directory / "before.ll"
        after = directory / "after.ll"
        driver = directory / "driver.c"
        ledger = directory / "ledger.json"
        before.write_text(MODULE)
        driver.write_text(DRIVER)
        checked([
            opt, "-load-pass-plugin", args.plugin,
            f"-ollvm-deobf-report={ledger}",
            "-passes=brighten-ollvm-deobf-pass,verify", "-S", before,
            "-o", after,
        ])
        for module, output in ((before, directory / "before.bin"),
                               (after, directory / "after.bin")):
            checked([clang, "-O2", driver, module, "-o", output])
            checked([output])
        report = json.loads(ledger.read_text())
        proofs = [item for item in report["proofs"]
                  if item["kind"] == "bv_egraph_rewrite"]
        engines = {item["proof_engine"] for item in proofs}
        assert "affine_saturation_z3_unsat" in engines
        assert "ac_saturation_z3_unsat" in engines
        assert "rotate_idiom_z3_unsat" in engines
        assert "demorgan_z3_unsat" in engines
        assert "bitwise_cast_factor_z3_unsat" in engines
        assert "mask_factor_z3_unsat" in engines
        flag_proofs = [item for item in report["proofs"]
                       if item["kind"] == "x86_flag_recovery"]
        tuple_flag_proofs = [item for item in flag_proofs
                             if item["proof_engine"] ==
                             "z3_bv_tuple_equivalence_unsat"]
        single_flag_proofs = [item for item in flag_proofs
                              if item["proof_engine"] ==
                              "z3_bv_equivalence_unsat"]
        assert len(flag_proofs) == 14
        assert len(tuple_flag_proofs) == 3
        assert len(single_flag_proofs) == 11
        assert all(item["old_hash"] and item["new_hash"] and
                   item["proof_query_hash"] for item in proofs)


if __name__ == "__main__":
    main()
