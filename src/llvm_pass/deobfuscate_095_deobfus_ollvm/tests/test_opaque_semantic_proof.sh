#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin="${root_dir}/build/lib095.so"
input="${root_dir}/tests/opaque_predicate_semantic_proof.ll"
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

# Disable the MBA stage so this test exercises only the bounded opaque
# predicate prover.  Three candidates let the positive proof and both
# counterexamples reach the prover in one scan.
opt-21 -load-pass-plugin "${plugin}" \
  -095-disable-mba \
  -095-max-opaque-z3-candidates=3 \
  -095-report="${work_dir}/report.json" \
  -passes=095 "${input}" -S -o "${work_dir}/after.ll"
opt-21 -passes=verify "${work_dir}/after.ll" -disable-output

# (x + 1) - 1 == x is true in i8 modular arithmetic, including x = 255.
jq -e '.rule_hits["opaque.SetRuleZ3"] >= 1 and .z3.proved >= 1' \
  "${work_dir}/report.json" >/dev/null
rg -U -q '(?s)define i32 @proven_modular_identity.*br label %yes' \
  "${work_dir}/after.ll"

# x + 1 wraps at 255 under unsigned comparison and at 127 under signed
# comparison.  Both conditions are non-constant and must remain branches.
rg -U -q '(?s)define i32 @unsigned_wrap_counterexample.*icmp ugt i8 %same_bits, %x.*br i1 %increased' \
  "${work_dir}/after.ll"
rg -U -q '(?s)define i32 @signed_wrap_counterexample.*icmp sgt i8 %same_bits, %x.*br i1 %increased' \
  "${work_dir}/after.ll"

# Neither LLVM's poison nor per-use undef choice is a boolean constant.  The
# native simplifier may erase the undef comparison itself, but it must retain
# the undef branch rather than choose an edge.
rg -U -q '(?s)define i32 @undef_counterexample.*br i1 undef' \
  "${work_dir}/after.ll"
rg -U -q '(?s)define i32 @poison_counterexample.*br i1 poison' \
  "${work_dir}/after.ll"

echo "bounded opaque semantic-proof regression passed"
