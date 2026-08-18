#!/usr/bin/env bash
set -euo pipefail
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${PLUGIN:-${root_dir}/build/lib095.so}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
for tool in opt-21 clang-21 jq rg; do command -v "$tool" >/dev/null; done
[[ -f "$plugin" ]]

cat >"$work/input.ll" <<'EOF'
define i32 @opaque(i32 %x) {
entry:
  %xm1 = sub i32 %x, 1
  %prod = mul i32 %x, %xm1
  %odd = and i32 %prod, 1
  %pred = icmp eq i32 %odd, 0
  br i1 %pred, label %yes, label %no
yes:
  ret i32 7
no:
  ret i32 9
}

define i32 @mba(i32 %x, i32 %y) {
entry:
  %xy = xor i32 %x, %y
  %both = and i32 %x, %y
  %twice = shl i32 %both, 1
  %r = add i32 %xy, %twice
  ret i32 %r
}

define i32 @dynamic(i32 %x) {
entry:
  %c = icmp sgt i32 %x, 0
  br i1 %c, label %p, label %n
p:
  ret i32 1
n:
  ret i32 0
}
EOF

cat >"$work/driver.c" <<'EOF'
#include <stdio.h>
extern int opaque(int);
extern int mba(int,int);
extern int dynamic(int);
int main(void) {
  long long acc=0;
  for (int x=-32;x<=32;++x) {
    acc += opaque(x) + dynamic(x);
    for (int y=-16;y<=16;++y) acc += mba(x,y);
  }
  printf("%lld\n", acc);
  return 0;
}
EOF

opt-21 -load-pass-plugin "$plugin" -095-z3-timeout-ms=100 \
  -095-report="$work/report.json" -passes=095 "$work/input.ll" -S -o "$work/after.ll"
opt-21 -passes=verify "$work/after.ll" -disable-output
jq -e '.schema == "deobfuscate-095-proof-v2"' "$work/report.json" >/dev/null
jq -e '.unknown_is_evidence == false and .z3.unknown_is_evidence == false' "$work/report.json" >/dev/null
jq -e '.predicates.proved >= 1' "$work/report.json" >/dev/null
# The real dynamic branch must remain; the opaque branch must disappear.
test "$(rg -c 'br i1' "$work/after.ll")" -eq 1
rg -q 'define i32 @dynamic' "$work/after.ll"

clang-21 -O2 "$work/input.ll" "$work/driver.c" -o "$work/before"
clang-21 -O2 "$work/after.ll" "$work/driver.c" -o "$work/after"
"$work/before" >"$work/before.stdout"
"$work/after" >"$work/after.stdout"
cmp "$work/before.stdout" "$work/after.stdout"

echo '095 proof-driven differential tests: PASS'
