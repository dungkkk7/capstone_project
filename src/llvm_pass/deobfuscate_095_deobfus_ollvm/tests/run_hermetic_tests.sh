#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${PLUGIN:-${root_dir}/build/lib095.so}"
input="${root_dir}/tests/production_cases.ll"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

for tool in opt-21 clang-21 jq rg; do
  command -v "${tool}" >/dev/null
 done
[[ -f "${plugin}" ]]

# End-to-end synthetic production case: exact direct/pointer cleanup,
# proof-backed BCF/MBA and dispatcher removal must preserve executable output.
opt-21 -load-pass-plugin "${plugin}" \
  -095-z3-timeout-ms=50 \
  -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

clang-21 -O2 "${input}" -o "${work_dir}/before"
clang-21 -O2 "${work_dir}/after.ll" -o "${work_dir}/after"
"${work_dir}/before" >"${work_dir}/before.stdout"
"${work_dir}/after" >"${work_dir}/after.stdout"
cmp "${work_dir}/before.stdout" "${work_dir}/after.stdout"

jq -e '.schema == "deobfuscate-095-report-v1"' "${work_dir}/report.json" >/dev/null
jq -e '.z3.unknown_is_evidence == false' "${work_dir}/report.json" >/dev/null
jq -e '.stages.deflatten.changes > 0' "${work_dir}/report.json" >/dev/null
jq -e '(.stages.normalize.changes + .stages.resolve_objects_pointers.changes) > 0' \
  "${work_dir}/report.json" >/dev/null

if rg -q 'switch i32' "${work_dir}/after.ll"; then
  echo "dispatcher switch survived the exact synthetic regression" >&2
  exit 1
fi
if rg -q 'call i32 %' "${work_dir}/after.ll"; then
  echo "proven constant indirect call was not resolved" >&2
  exit 1
fi

# Hermetic semantic/proof suites. Dataset lifecycle canaries remain in the
# full runner and are executed only in the repository's McSema environment.
"${root_dir}/tests/test_opaque_predicates.sh"
"${root_dir}/tests/test_opaque_select.sh"
"${root_dir}/tests/test_opaque_semantic_proof.sh"
"${root_dir}/tests/test_opaque_parity_semantic_proof.sh"
"${root_dir}/tests/test_signed_compare_flags.sh"
"${root_dir}/tests/test_frozen_dispatcher.sh"
"${root_dir}/tests/test_chernobog_add_ollvm_rules.sh"
"${root_dir}/tests/test_chernobog_and_ollvm_rules.sh"
"${root_dir}/tests/test_chernobog_xor_ollvm_rules.sh"

echo "095 hermetic proof and differential tests: PASS"
