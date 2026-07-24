#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${root_dir}/build"
plugin="${build_dir}/lib095.so"
input="${root_dir}/tests/production_cases.ll"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

cmake -S "${root_dir}" -B "${build_dir}" -G Ninja \
  -DLLVM_DIR=/usr/lib/llvm-21/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo >/dev/null
cmake --build "${build_dir}" -j"$(nproc)" >/dev/null

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
jq -e '.pipeline == ["normalize", "resolve_objects_pointers", "mba", "bcf_opaque_predicates", "deflatten", "cfg_cleanup", "fake_stack", "register_state"]' "${work_dir}/report.json" >/dev/null
jq -e '.z3.unknown_is_evidence == false' "${work_dir}/report.json" >/dev/null
jq -e '.stages.deflatten.changes > 0' "${work_dir}/report.json" >/dev/null
jq -e '(.stages.normalize.changes + .stages.resolve_objects_pointers.changes) > 0' "${work_dir}/report.json" >/dev/null

if rg -q 'switch i32' "${work_dir}/after.ll"; then
  echo "dispatcher switch survived the exact single-carrier regression" >&2
  exit 1
fi
if rg -q 'call i32 %' "${work_dir}/after.ll"; then
  echo "proven constant indirect call was not resolved" >&2
  exit 1
fi

echo "095 regression and differential test passed"
