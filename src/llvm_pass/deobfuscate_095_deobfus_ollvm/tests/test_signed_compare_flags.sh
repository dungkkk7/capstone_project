#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/signed_compare_flags.ll"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

opt-21 -load-pass-plugin "${plugin}" \
  -095-max-z3-candidates=0 -095-max-opaque-z3-candidates=0 \
  -095-report="${work_dir}/report.json" \
  -passes='095,function(instcombine,dce),verify' -S "${input}" \
  -o "${work_dir}/after.ll"

rg -q 'icmp sgt i32 %x, -1|icmp sge i32 %x, 0' "${work_dir}/after.ll"
rg -q 'icmp sle i32 %a, %b' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_slt_nonnegative_rhs' "${work_dir}/after.ll"
rg -q 'icmp slt i32 %a, %b' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_slt_complete_overflow' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_slt_reassociated' "${work_dir}/after.ll"
rg -q 'icmp slt i32 %a, 10' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_sle_difference_zero' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_sgt_nonnegative_rhs' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_sgt_complete_nonnegative_sign' "${work_dir}/after.ll"
rg -q 'icmp sgt i32 %a, %b' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_slt_narrow_sign_test' "${work_dir}/after.ll"
rg -q 'icmp slt i8 %x, 32' "${work_dir}/after.ll"
rg -q 'define i1 @lifted_sgt_narrow_nonnegative_test' "${work_dir}/after.ll"
rg -q 'icmp sgt i8 %x, 32' "${work_dir}/after.ll"
! rg -q 'xor i1 %negative.narrow' "${work_dir}/after.ll"
! rg -q 'xor i1 %nonnegative.narrow.gt' "${work_dir}/after.ll"
rg -q 'define i1 @near_miss' "${work_dir}/after.ll"
rg -q 'icmp eq i32 %signs, 1' "${work_dir}/after.ll"
jq -e '.rule_hits["mba.SignedNonnegativeFlagsRule"] > 0' \
  "${work_dir}/report.json" >/dev/null
jq -e '.rule_hits["mba.SignedLessEqualFlagsRule"] > 0' \
  "${work_dir}/report.json" >/dev/null
jq -e '.rule_hits["mba.SignedLessThanFlagsRule"] > 0' \
  "${work_dir}/report.json" >/dev/null
jq -e '.rule_hits["mba.SignedGreaterThanFlagsRule"] > 0' \
  "${work_dir}/report.json" >/dev/null

clang-21 -O2 "${input}" -o "${work_dir}/before"
clang-21 -O2 "${work_dir}/after.ll" -o "${work_dir}/after"
"${work_dir}/before" >"${work_dir}/before.stdout"
"${work_dir}/after" >"${work_dir}/after.stdout"
cmp "${work_dir}/before.stdout" "${work_dir}/after.stdout"
