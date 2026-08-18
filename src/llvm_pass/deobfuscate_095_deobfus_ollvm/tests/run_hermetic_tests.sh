#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${PLUGIN:-${root_dir}/build/lib095.so}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for tool in opt-21 clang-21 jq rg cmp; do
  command -v "$tool" >/dev/null
done
[[ -f "$plugin" ]]

cat >"$work/input.ll" <<'EOF'
define i32 @add_or_and(i32 %x, i32 %y) {
entry:
  %o = or i32 %x, %y
  %a = and i32 %x, %y
  %r = add i32 %o, %a
  ret i32 %r
}

define i32 @add_xor_carry(i32 %x, i32 %y) {
entry:
  %xv = xor i32 %x, %y
  %a = and i32 %x, %y
  %twice = shl i32 %a, 1
  %r = add i32 %xv, %twice
  ret i32 %r
}

define i32 @and_demorgan(i32 %x, i32 %y) {
entry:
  %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %o = or i32 %nx, %ny
  %r = xor i32 %o, -1
  ret i32 %r
}

define i32 @or_demorgan(i32 %x, i32 %y) {
entry:
  %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %a = and i32 %nx, %ny
  %r = xor i32 %a, -1
  ret i32 %r
}

define i32 @sub_twos(i32 %x, i32 %y) {
entry:
  %ny = xor i32 %y, -1
  %s = add i32 %x, %ny
  %r = add i32 %s, 1
  ret i32 %r
}

define i32 @xor_hd(i32 %x, i32 %y) {
entry:
  %o = or i32 %x, %y
  %a = and i32 %x, %y
  %r = sub i32 %o, %a
  ret i32 %r
}

define i32 @double_not(i32 %x) {
entry:
  %n1 = xor i32 %x, -1
  %n2 = xor i32 %n1, -1
  ret i32 %n2
}

define i32 @double_neg(i32 %x) {
entry:
  %n1 = sub i32 0, %x
  %n2 = sub i32 0, %n1
  ret i32 %n2
}

define i32 @mul_minus_one(i32 %x) {
entry:
  %r = mul i32 %x, -1
  ret i32 %r
}

define i32 @carry_free_or(i32 %x, i32 %y) {
entry:
  %nx = xor i32 %x, -1
  %part = and i32 %y, %nx
  %r = add i32 %x, %part
  ret i32 %r
}

define i32 @predicate_select(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %zero = and i32 %x, %nx
  %p = icmp eq i32 %zero, 0
  %r = select i1 %p, i32 11, i32 13
  ret i32 %r
}

define i32 @jump_self(i32 %x) {
entry:
  %p = icmp ult i32 %x, %x
  br i1 %p, label %bad, label %good
bad:
  ret i32 9
good:
  ret i32 7
}

define i32 @logical_not_zero() {
entry:
  %n = xor i1 false, true
  %r = zext i1 %n to i32
  ret i32 %r
}

define i32 @opaque_fallback(i32 %x) {
entry:
  %xm1 = sub i32 %x, 1
  %prod = mul i32 %x, %xm1
  %odd = and i32 %prod, 1
  %pred = icmp eq i32 %odd, 0
  br i1 %pred, label %yes, label %no
yes:
  ret i32 17
no:
  ret i32 19
}

define i32 @dynamic(i32 %x) {
entry:
  %p = icmp sgt i32 %x, 0
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
EOF

cat >"$work/driver.c" <<'EOF'
#include <stdint.h>
#include <stdio.h>

extern uint32_t add_or_and(uint32_t, uint32_t);
extern uint32_t add_xor_carry(uint32_t, uint32_t);
extern uint32_t and_demorgan(uint32_t, uint32_t);
extern uint32_t or_demorgan(uint32_t, uint32_t);
extern uint32_t sub_twos(uint32_t, uint32_t);
extern uint32_t xor_hd(uint32_t, uint32_t);
extern uint32_t double_not(uint32_t);
extern uint32_t double_neg(uint32_t);
extern uint32_t mul_minus_one(uint32_t);
extern uint32_t carry_free_or(uint32_t, uint32_t);
extern int predicate_select(uint32_t);
extern int jump_self(uint32_t);
extern int logical_not_zero(void);
extern int opaque_fallback(uint32_t);
extern int dynamic(int32_t);

int main(void) {
  uint64_t acc = 0;
  for (uint32_t x = 0; x != 257; ++x) {
    uint32_t y = x * UINT32_C(0x9e3779b9) + 7;
    acc += add_or_and(x, y);
    acc += add_xor_carry(x, y);
    acc += and_demorgan(x, y);
    acc += or_demorgan(x, y);
    acc += sub_twos(x, y);
    acc += xor_hd(x, y);
    acc += double_not(x);
    acc += double_neg(x);
    acc += mul_minus_one(x);
    acc += carry_free_or(x, y);
    acc += (uint32_t)predicate_select(x);
    acc += (uint32_t)jump_self(x);
    acc += (uint32_t)opaque_fallback(x);
    acc += (uint32_t)dynamic((int32_t)x - 128);
  }
  acc += (uint32_t)logical_not_zero();
  printf("%llu\n", (unsigned long long)acc);
  return 0;
}
EOF

# Hot path: catalog certification is requested for CI, but runtime fallback
# remains disabled. No input expression is sent to Z3.
opt-21 -load-pass-plugin "$plugin" \
  -095-verify-rule-catalog \
  -095-report="$work/rules.json" \
  -passes=095 "$work/input.ll" -S -o "$work/rules.ll"
opt-21 -passes=verify "$work/rules.ll" -disable-output

jq -e '.schema == "deobfuscate-095-rule-first-v3"' \
  "$work/rules.json" >/dev/null
jq -e '
  .catalog.mba_registered == 108 and
  .catalog.predicate_registered == 22 and
  .catalog.jump_registered == 9 and
  .catalog.verified == 108 and
  .catalog.rejected == 0 and
  .catalog.matcher_verified == 108 and
  .catalog.matcher_rejected == 0 and
  .catalog.width_checks == 540
' "$work/rules.json" >/dev/null
jq -e '
  .z3_fallback.enabled == false and
  .z3_fallback.queries == 0 and
  .rule_engine.mba_rewrites >= 10 and
  .rule_engine.predicate_rewrites >= 2
' "$work/rules.json" >/dev/null

for rule in \
  Add_HackersDelightRule_2 \
  Add_HackersDelightRule_3 \
  And_HackersDelightRule_3 \
  Or_MbaRule_1 \
  Sub_HackersDelightRule_1 \
  Xor_HackersDelightRule_1 \
  Bnot_HackersDelightRule_1 \
  Neg_HackersDelightRule_1 \
  Mul_Rule_4 \
  Add_CarryFreeOrRule
do
  jq -e --arg rule "$rule" '.rule_engine.hits[$rule] >= 1' \
    "$work/rules.json" >/dev/null
done
jq -e '.rule_engine.hits["predicate.SetzAndComplementRule"] >= 1' \
  "$work/rules.json" >/dev/null
jq -e '.rule_engine.hits["jump.JbRule1"] >= 1' \
  "$work/rules.json" >/dev/null
jq -e '.rule_engine.hits["predicate.LnotZeroRule"] >= 1' \
  "$work/rules.json" >/dev/null

# A real dynamic branch and the non-catalog opaque predicate remain.
test "$(rg -c 'br i1' "$work/rules.ll")" -eq 2

clang-21 -O2 "$work/input.ll" "$work/driver.c" -o "$work/before"
clang-21 -O2 "$work/rules.ll" "$work/driver.c" -o "$work/rule_after"
"$work/before" >"$work/before.stdout"
"$work/rule_after" >"$work/rule.stdout"
cmp "$work/before.stdout" "$work/rule.stdout"

# Every direct predicate and jump rule has a positive LLVM matcher regression.
opt-21 -load-pass-plugin "$plugin" \
  -095-report="$work/direct.json" \
  -passes=095 "$root_dir/tests/direct_rule_catalog.ll" \
  -S -o "$work/direct.ll"
opt-21 -passes=verify "$work/direct.ll" -disable-output

direct_rules=(
  predicate.SetzSelfRule
  predicate.SetnzSelfRule
  predicate.SetbSelfRule
  predicate.SetaeSelfRule
  predicate.SetaSelfRule
  predicate.SetbeSelfRule
  predicate.SetlSelfRule
  predicate.SetgeSelfRule
  predicate.SetgSelfRule
  predicate.SetleSelfRule
  predicate.SetzAndComplementRule
  predicate.SetnzOrComplementRule
  predicate.SetzXorSelfRule
  predicate.SetnzXorSelfRule
  predicate.SetnzOrOneRule
  predicate.SetzAndZeroRule
  predicate.SetnzOrMinusOneRule
  predicate.SetbZeroRule
  predicate.SetaeZeroRule
  predicate.SetConstRule
  predicate.LnotOneRule
  predicate.LnotZeroRule
  jump.JnzRule1
  jump.JnzRule2
  jump.JnzRule3
  jump.JnzRule4
  jump.JzRule1
  jump.JzRule2
  jump.JbRule1
  jump.JaeRule1
  jump.JzConstRule
)
for rule in "${direct_rules[@]}"; do
  jq -e --arg rule "$rule" '.rule_engine.hits[$rule] >= 1' \
    "$work/direct.json" >/dev/null
done
test "$(jq '[.rule_engine.hits | keys[] |
  select(startswith("predicate.") or startswith("jump."))] | length' \
  "$work/direct.json")" -eq 31

# Explicit fallback test: only unmatched predicates are queried.
opt-21 -load-pass-plugin "$plugin" \
  -095-enable-z3-fallback \
  -095-max-predicate-z3-candidates=16 \
  -095-max-mba-candidates=0 \
  -095-z3-timeout-ms=100 \
  -095-report="$work/fallback.json" \
  -passes=095 "$work/input.ll" -S -o "$work/fallback.ll"
opt-21 -passes=verify "$work/fallback.ll" -disable-output
jq -e '
  .z3_fallback.enabled == true and
  .z3_fallback.predicate_candidates > 0 and
  .z3_fallback.predicate_proofs >= 1 and
  .z3_fallback.queries > 0
' "$work/fallback.json" >/dev/null

# The catalog/jump rules remove their branches and Z3 removes the parity
# opaque branch; only the truly dynamic branch survives.
test "$(rg -c 'br i1' "$work/fallback.ll")" -eq 1
clang-21 -O2 "$work/fallback.ll" "$work/driver.c" \
  -o "$work/fallback_after"
"$work/fallback_after" >"$work/fallback.stdout"
cmp "$work/before.stdout" "$work/fallback.stdout"

echo "095: 108/108 MBA rules certified; rule-first differential tests PASS"
