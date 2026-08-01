#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 INPUT.ll OUTPUT_PREFIX" >&2
  exit 2
fi

INPUT=$(realpath "$1")
PREFIX="$2"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WORKDIR=$(dirname -- "$PREFIX")
BASE=$(basename -- "$PREFIX")
mkdir -p "$WORKDIR"

S1="$WORKDIR/${BASE}.01-verified-input.ll"
S2="$WORKDIR/${BASE}.02-pointer-opt.ll"
S3="$WORKDIR/${BASE}.03-storage-delift.ll"
S4="$WORKDIR/${BASE}.04-storage-o3.ll"
S5="$WORKDIR/${BASE}.05-unpinned.ll"
FINAL_LL="$WORKDIR/${BASE}.ll"
FINAL_O="$WORKDIR/${BASE}.o"
FINAL_BIN="$WORKDIR/${BASE}.bin"

"${OPT_BIN:-$(command -v opt-21 || command -v opt)}" -S -passes=verify "$INPUT" -o "$S1"
python3 "$SCRIPT_DIR/run_exact_llvm_passes.py" "$S1" "$S2"
DELIFT_OPT_PIPELINE='default<O3>,verify' python3 "$SCRIPT_DIR/run_o3_llvm.py" "$S2" "$S3"
python3 "$SCRIPT_DIR/delift_storage.py" "$S3" "$S4"
python3 "$SCRIPT_DIR/strip_brighten_residuals.py" "$S4" "$S5"
DELIFT_OPT_PIPELINE='default<O3>,verify' \
  python3 "$SCRIPT_DIR/run_o3_llvm.py" "$S5" "$FINAL_LL"
python3 "$SCRIPT_DIR/dedup_pointer_selects.py" "$FINAL_LL" "$FINAL_LL.dedup"
mv "$FINAL_LL.dedup" "$FINAL_LL"
# Run the deterministic (non-SMT) MBA cleanup once more after resolver
# centralisation.  The first 095 invocation runs before the mapper exists;
# this second pass sees the compacted arithmetic and is bounded by zero Z3
# queries, so it cannot turn the pipeline into an unbounded solver job.
DEOBF_PLUGIN="${DEOBF_PLUGIN:-$SCRIPT_DIR/../deobfuscate_095_deobfus_ollvm/build/lib095.so}"
if [[ -f "$DEOBF_PLUGIN" ]]; then
  OPT_TOOL="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
  "$OPT_TOOL" -load-pass-plugin="$DEOBF_PLUGIN" -S \
    -passes=095 -095-disable-deflatten \
    -095-max-z3-candidates=0 -095-max-opaque-z3-candidates=0 \
    "$FINAL_LL" -o "$FINAL_LL.post095"
  mv "$FINAL_LL.post095" "$FINAL_LL"
  # 095 exposes source-level comparisons and loop bounds. Run scalar cleanup
  # only: vectorization at this final presentation boundary makes recovered
  # pseudocode less readable without adding semantic information. LLVM 21's
  # one-pass fixpoint diagnostic is not a semantic verifier and can reject
  # valid newly opened CFGs, so use the same no-verify-fixpoint spelling as the
  # main brighten pipeline; the module verifier still runs below.
  "$OPT_TOOL" -S \
    -passes='function(instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,adce),globaldce,verify' \
    "$FINAL_LL" -o "$FINAL_LL.post095-o3"
  mv "$FINAL_LL.post095-o3" "$FINAL_LL"
  "$OPT_TOOL" -passes=verify -disable-output "$FINAL_LL"
fi
# The bundle's O3/095 stages are allowed to expose source-level loop PHIs, but
# they must not run after the authoritative native contract report. Consume
# only those late frame products, run bounded scalar cleanup, consume any
# affine pointer spelling exposed by that cleanup, then report the exact IR
# that will be compacted and compiled.  Both cleanup calls use the narrow
# post-frame contract; the second is the final convergence boundary after all
# standard scalar/ABI cleanup, not broad semantic recovery.  Keeping it last
# also defines fully overwritten aggregates that late instcombine may respell
# with a poison seed.
# This script always links a complete executable whose public entry is `main`.
# Once the first post-frame pass has created any required source-ABI adapters,
# LLVM's whole-program internalizer can make non-entry definitions local and
# global DCE can remove adapters with no in-module users.  The same closed
# callgraph lets LLVM's interprocedural constant propagation expose constant
# State-SSA parameters, then dead-argument elimination removes unused
# parameters and aggregate return fields with its ordinary ABI proof.  This is
# a linkage proof at the executable boundary; the reusable 090 module pass
# itself keeps externally visible compatibility wrappers.
NATIVE_CLEANUP_PLUGIN="${NATIVE_CLEANUP_PLUGIN:-$SCRIPT_DIR/../brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so}"
if [[ -f "$NATIVE_CLEANUP_PLUGIN" ]]; then
  OPT_TOOL="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
  "$OPT_TOOL" -load-pass-plugin="$NATIVE_CLEANUP_PLUGIN" -S \
    -passes='brighten-native-cleanup-post-frame-pass,internalize,ipsccp,deadargelim,globalopt,function(instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,adce,simplifycfg,instcombine<no-verify-fixpoint>,simplifycfg,dce,adce),globaldce,function(dce,adce),globaldce,ipsccp,deadargelim,function(instcombine<no-verify-fixpoint>,simplifycfg,dce,adce),globaldce,brighten-native-cleanup-post-frame-pass,brighten-native-cleanup-final-pass,verify' \
    "$FINAL_LL" -o "$FINAL_LL.native-final"
  mv "$FINAL_LL.native-final" "$FINAL_LL"
fi
python3 "$SCRIPT_DIR/compact_ir_text.py" "$FINAL_LL" "$FINAL_LL.compact"
mv "$FINAL_LL.compact" "$FINAL_LL"
"${OPT_BIN:-$(command -v opt-21 || command -v opt)}" -passes=verify -disable-output "$FINAL_LL"
CLANG_BIN="${CLANG_BIN:-$(command -v clang-21 || command -v clang || true)}"
if [[ -z "$CLANG_BIN" ]]; then
  echo "clang-21/clang not found" >&2
  exit 127
fi
"$CLANG_BIN" -O2 -c "$FINAL_LL" -o "$FINAL_O"
"$CLANG_BIN" -O2 "$FINAL_LL" -lm -o "$FINAL_BIN"

printf 'final IR:     %s\n' "$FINAL_LL"
printf 'final object: %s\n' "$FINAL_O"
printf 'final binary: %s\n' "$FINAL_BIN"
