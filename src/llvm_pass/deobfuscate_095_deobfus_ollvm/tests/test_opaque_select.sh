#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/opaque_select_integration.ll"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

opt-21 -load-pass-plugin "${plugin}" \
  -095-disable-mba \
  -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

jq -e '.stages.bcf_opaque_predicates.changes >= 1' "${work_dir}/report.json" >/dev/null
jq -e '.rule_hits["opaque.DatasetLowBitComplementRule"] >= 1' "${work_dir}/report.json" >/dev/null
! rg -q 'select i1' "${work_dir}/after.ll"
rg -q 'ret i32 -7' "${work_dir}/after.ll"

echo "opaque select integration path applied and reported"
