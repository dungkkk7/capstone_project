#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/opaque_predicate_rules.ll"
driver="${root_dir}/tests/opaque_predicate_driver.c"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

opt-21 -load-pass-plugin "${plugin}" \
  -095-disable-mba \
  -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

expected_rules='[
  "LnotLnotRule", "LnotOneRule", "LnotZeroRule", "SetConstRule",
  "SetRuleZ3", "SetaSelfRule", "SetaeSelfRule", "SetaeZeroRule",
  "SetbSelfRule", "SetbZeroRule", "SetbeSelfRule", "SetgSelfRule",
  "SetgeSelfRule", "SetlSelfRule", "SetleSelfRule",
  "SetnzOrComplementRule", "SetnzOrMinusOneRule", "SetnzOrOneRule",
  "SetnzSelfRule", "SetnzXorSelfRule", "SetzAndComplementRule",
  "SetzAndZeroRule", "SetzSelfRule", "SetzXorSelfRule"
]'
jq -e --argjson rules "${expected_rules}" '
  .stages.bcf_opaque_predicates.changes == 24 and
  ([.rule_hits | keys[] | select(startswith("opaque.")) |
      sub("^opaque\\."; "")] | sort) == ($rules | sort)
' "${work_dir}/report.json" >/dev/null

for rule in $(jq -r '.[]' <<<"${expected_rules}"); do
  jq -e --arg key "opaque.${rule}" '.rule_hits[$key] == 1' \
    "${work_dir}/report.json" >/dev/null
done

# Only the double-lnot canonicalized branch and the four deliberately
# non-constant negative cases may remain conditional.
test "$(rg -c 'br i1' "${work_dir}/after.ll")" -eq 5
rg -q 'br i1 %base, label %yes, label %no' "${work_dir}/after.ll"
rg -q 'define i32 @negative_width_cast' "${work_dir}/after.ll"
rg -q 'define i32 @negative_signed_or_odd' "${work_dir}/after.ll"
rg -q 'define i32 @negative_undef' "${work_dir}/after.ll"
rg -q 'define i32 @negative_poison' "${work_dir}/after.ll"

clang-21 -O2 "${input}" "${driver}" -o "${work_dir}/before"
clang-21 -O2 "${work_dir}/after.ll" "${driver}" -o "${work_dir}/after"
"${work_dir}/before" >"${work_dir}/before.stdout"
"${work_dir}/after" >"${work_dir}/after.stdout"
cmp "${work_dir}/before.stdout" "${work_dir}/after.stdout"

echo "opaque predicate semantics covered"
