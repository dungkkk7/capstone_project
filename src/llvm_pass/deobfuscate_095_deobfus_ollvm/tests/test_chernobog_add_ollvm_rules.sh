#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/chernobog_add_ollvm_rules.ll"
driver="${root_dir}/tests/chernobog_add_ollvm_driver.c"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

opt-21 -load-pass-plugin "${plugin}" -095-max-z3-candidates=0 \
  -095-max-opaque-z3-candidates=0 -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

for rule in Add_OllvmRule_1 Add_OllvmRule_2 Add_OllvmRule_3 Add_OllvmRule_4; do
  jq -e --arg rule "${rule}" \
    '.rule_hits[$rule] >= 3 and .chernobog_add_rule_operations[$rule].hits >= 3 and
     .chernobog_add_rule_operations[$rule].operations_before >
     .chernobog_add_rule_operations[$rule].operations_after' \
    "${work_dir}/report.json" >/dev/null
done
jq -e '.z3.queries == 0' "${work_dir}/report.json" >/dev/null
rg -q 'load volatile i8, ptr @volatile_source' "${work_dir}/after.ll"
rg -q 'call i8 @opaque_source\(\)' "${work_dir}/after.ll"

clang-21 -O0 "${input}" "${driver}" -o "${work_dir}/before"
clang-21 -O0 "${work_dir}/after.ll" "${driver}" -o "${work_dir}/after"
"${work_dir}/before"
"${work_dir}/after"

echo "Chernobog Add_OllvmRule_1..4 regression passed"
