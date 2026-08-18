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
ENTRYPOINT_SYMBOL="${BRIGHTEN_ENTRYPOINT_SYMBOL:-main}"
ENTRYPOINT_CHECK="$SCRIPT_DIR/entrypoint_contract.py"
ENTRYPOINT_PRE_REPORT="$WORKDIR/${BASE}.entrypoint-before-native.json"
ENTRYPOINT_FINAL_REPORT="$WORKDIR/${BASE}.entrypoint-final.json"

# Direct bundle invocations may reuse an output prefix.  Remove every authority
# artifact and report before the first command so an early failure cannot make a
# stale file look like the result of the current run.
rm -f   "$S1" "$S2" "$S3" "$S4" "$S5"   "$FINAL_LL" "$FINAL_O" "$FINAL_BIN"   "$ENTRYPOINT_PRE_REPORT" "$ENTRYPOINT_FINAL_REPORT"

"${OPT_BIN:-$(command -v opt-21 || command -v opt)}" -S -passes=verify "$INPUT" -o "$S1"
python3 "$SCRIPT_DIR/run_exact_llvm_passes.py" "$S1" "$S2"
DELIFT_OPT_LEVEL="${DELIFT_OPT_LEVEL:-${BRIGHTEN_OPT_LEVEL:-O3}}"
if [[ ! "$DELIFT_OPT_LEVEL" =~ ^O[123]$ ]]; then
  echo "DELIFT_OPT_LEVEL must be O1, O2, or O3; got: $DELIFT_OPT_LEVEL" >&2
  exit 2
fi
DELIFT_OPT_PIPELINE="default<${DELIFT_OPT_LEVEL}>,verify" python3 "$SCRIPT_DIR/run_o3_llvm.py" "$S2" "$S3"
python3 "$SCRIPT_DIR/delift_storage.py" "$S3" "$S4"
python3 "$SCRIPT_DIR/strip_brighten_residuals.py" "$S4" "$S5"
DELIFT_OPT_PIPELINE="default<${DELIFT_OPT_LEVEL}>,verify" \
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

# This bundle emits a complete executable, not a library.  Freeze the public
# entrypoint contract before the interprocedural cleanup tail.  The check uses
# llvm-as/llvm-nm and therefore cannot be fooled by comments or textual names.
python3 "$ENTRYPOINT_CHECK" "$FINAL_LL" \
  --symbol "$ENTRYPOINT_SYMBOL" --report "$ENTRYPOINT_PRE_REPORT"

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
# global DCE can remove adapters with no in-module users.  Preserve the entry
# symbol explicitly: relying on incidental linkage caused h00038 to lose
# `main` during the finalization tail.
NATIVE_CLEANUP_PLUGIN="${NATIVE_CLEANUP_PLUGIN:-$SCRIPT_DIR/../brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so}"
if [[ -f "$NATIVE_CLEANUP_PLUGIN" ]]; then
  OPT_TOOL="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
  "$OPT_TOOL" -load-pass-plugin="$NATIVE_CLEANUP_PLUGIN" -S \
    "-internalize-public-api-list=$ENTRYPOINT_SYMBOL" \
    -passes='brighten-native-cleanup-post-frame-pass,internalize,ipsccp,deadargelim,globalopt,function(instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,adce,simplifycfg,instcombine<no-verify-fixpoint>,simplifycfg,dce,adce),globaldce,function(dce,adce),globaldce,ipsccp,deadargelim,function(instcombine<no-verify-fixpoint>,simplifycfg,dce,adce),globaldce,brighten-native-cleanup-post-frame-pass,brighten-native-cleanup-final-pass,verify' \
    "$FINAL_LL" -o "$FINAL_LL.native-final"
  mv "$FINAL_LL.native-final" "$FINAL_LL"
fi
python3 "$SCRIPT_DIR/compact_ir_text.py" "$FINAL_LL" "$FINAL_LL.compact"
mv "$FINAL_LL.compact" "$FINAL_LL"
"${OPT_BIN:-$(command -v opt-21 || command -v opt)}" -passes=verify -disable-output "$FINAL_LL"

# A verifier-successful module can still be unusable as an executable.  Make
# entrypoint preservation a hard release gate and persist machine-readable
# evidence beside the final artifact.
python3 "$ENTRYPOINT_CHECK" "$FINAL_LL" \
  --symbol "$ENTRYPOINT_SYMBOL" --report "$ENTRYPOINT_FINAL_REPORT"

CLANG_BIN="${CLANG_BIN:-$(command -v clang-21 || command -v clang || true)}"
if [[ -z "$CLANG_BIN" ]]; then
  echo "clang-21/clang not found" >&2
  exit 127
fi
"$CLANG_BIN" -O2 -c "$FINAL_LL" -o "$FINAL_O"
LINK_ARGS=("$FINAL_LL" -lm)
# Compatibility-class IR may retain McSema's callback trampoline solely
# through CRT constructor/destructor wrappers.  Link the matching audited
# McSema runtime only when that symbol is actually unresolved; fully-native IR
# remains independent of the compatibility runtime.
MCSEMA_RUNTIME_LIB="${MCSEMA_RUNTIME_LIB:-$SCRIPT_DIR/../../../dependency/mcsema/mcsema/lib/libmcsema_rt64-10.0.a}"
if "${NM_BIN:-$(command -v nm)}" -u "$FINAL_O" | grep -q '__mcsema_attach_call'; then
  if [[ ! -f "$MCSEMA_RUNTIME_LIB" ]]; then
    echo "missing McSema compatibility runtime: $MCSEMA_RUNTIME_LIB" >&2
    exit 1
  fi
  LINK_ARGS+=("$MCSEMA_RUNTIME_LIB")
fi
"$CLANG_BIN" -O2 "${LINK_ARGS[@]}" -o "$FINAL_BIN"

printf 'final IR:     %s\n' "$FINAL_LL"
printf 'final object: %s\n' "$FINAL_O"
printf 'final binary: %s\n' "$FINAL_BIN"
printf 'entrypoint:   %s\n' "$ENTRYPOINT_FINAL_REPORT"
