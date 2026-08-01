#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/frozen_dispatcher.ll"
work_dir="$(mktemp -d)"
output="${work_dir}/after.ll"
trap 'rm -rf "${work_dir}"' EXIT

opt-21 -load-pass-plugin="${plugin}" \
  -095-max-z3-candidates=0 -095-max-opaque-z3-candidates=0 \
  -passes='095,verify' -S "${input}" -o "${output}"
FileCheck-21 "${input}" --input-file="${output}"

clang-21 -O2 "${input}" -o "${work_dir}/before"
clang-21 -O2 "${output}" -o "${work_dir}/after"
"${work_dir}/before"
"${work_dir}/after"
