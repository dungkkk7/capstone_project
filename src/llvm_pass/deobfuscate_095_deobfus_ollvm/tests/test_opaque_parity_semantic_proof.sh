#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/opaque_parity_semantic_proof.ll"
driver="${root_dir}/tests/opaque_parity_driver.c"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

# Keep the normal lifecycle enabled: this proves the structural rule runs in
# its pre-deflattening placement.  Disable only residual opaque SMT so a
# solver cannot mask a matcher regression.
opt-21 -load-pass-plugin "${plugin}" \
  -095-max-opaque-z3-candidates=0 \
  -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

jq -e '.rule_hits["opaque.ParityConsecutiveLowBitRule"] == 3' \
  "${work_dir}/report.json" >/dev/null
rg -U -q '(?s)define i32 @parity_i8_not.*br label %yes' "${work_dir}/after.ll"
rg -U -q '(?s)define i32 @parity_i32_next.*br label %yes' "${work_dir}/after.ll"
rg -U -q '(?s)define i64 @parity_i64_integer.*ret i64 0' "${work_dir}/after.ll"

for f in negative_different_ssa negative_nsw negative_nuw \
         negative_unproven_parameter negative_freeze negative_poison \
         negative_comparison_polarity; do
  rg -U -q "(?s)define i32 @${f}.*br i1" "${work_dir}/after.ll"
done
# InstCombine may independently choose one concrete undef execution while
# normalizing this synthetic input.  The exact rule's hit count above remains
# the ownership assertion: it did not accept this explicit-undef pattern.
rg -q 'define i32 @negative_undef' "${work_dir}/after.ll"
rg -U -q '(?s)define <4 x i1> @negative_vector.*ret <4 x i1> %c' \
  "${work_dir}/after.ll"

clang-21 -O0 "${input}" "${driver}" -o "${work_dir}/before"
clang-21 -O0 "${work_dir}/after.ll" "${driver}" -o "${work_dir}/after"
"${work_dir}/before" >"${work_dir}/before.stdout"
"${work_dir}/after" >"${work_dir}/after.stdout"
cmp "${work_dir}/before.stdout" "${work_dir}/after.stdout"

echo "parity opaque semantic-proof regression passed"
