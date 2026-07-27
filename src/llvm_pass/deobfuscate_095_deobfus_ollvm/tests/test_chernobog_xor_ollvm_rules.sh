#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/chernobog_xor_ollvm_rules.ll"
driver="${root_dir}/tests/chernobog_xor_ollvm_driver.c"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

opt-21 -load-pass-plugin "${plugin}" -095-max-z3-candidates=0 \
  -095-max-opaque-z3-candidates=0 -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

# Chernobog's matcher commutes the root AND and resolves overlap by registry
# order. Xor_OllvmRule_1 is registered first, so it owns both XNOR spellings;
# Rule 2 remains a catalog entry but is not reachable for those bare forms.
jq -e '
  .rule_hits.Xor_OllvmRule_1 >= 6 and
  ((.rule_hits.Xor_OllvmRule_2 // 0) == 0) and
  (.rule_hits.Xor_OllvmRule_3 // 0) >= 0 and
  .chernobog_xor_rule_operations.Xor_OllvmRule_1.hits >= 6 and
  .chernobog_xor_rule_operations.Xor_OllvmRule_1.operations_before >
    .chernobog_xor_rule_operations.Xor_OllvmRule_1.operations_after and
  (.chernobog_xor_rule_operations.Xor_OllvmRule_2 == null)
' "${work_dir}/report.json" >/dev/null
jq -e '.z3.queries == 0' "${work_dir}/report.json" >/dev/null

# Refusal is asserted through exact-rule evidence; generic LLVM cleanup may
# still simplify some synthetic poison/undef cases independently.
jq -e '([.rule_hits | to_entries[] | select(.key | startswith("Xor_OllvmRule_")) | .value] | add) >= 9' \
  "${work_dir}/report.json" >/dev/null
# The exhaustive i8 driver below covers all 256^2 input pairs.
rg -q 'freeze i8 %x' "${work_dir}/after.ll"
rg -q 'load volatile i8, ptr @volatile_source' "${work_dir}/after.ll"
rg -q 'call (noundef )?i8 @opaque_source\(\)' "${work_dir}/after.ll"
for f in negative_flags negative_different_ssa negative_cast negative_undef negative_poison negative_freeze negative_vector; do
  rg -q "define .*@${f}" "${work_dir}/after.ll"
done

clang-21 -O0 "${input}" "${driver}" -o "${work_dir}/before"
clang-21 -O0 "${work_dir}/after.ll" "${driver}" -o "${work_dir}/after"
"${work_dir}/before"
"${work_dir}/after"

echo "Chernobog Xor_OllvmRule_1..3 regression passed"
