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

OPT_TOOL="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
CLANG_TOOL="${CLANG_BIN:-$(command -v clang-21 || command -v clang)}"
NM_TOOL="${NM_BIN:-$(command -v llvm-nm-21 || command -v llvm-nm || command -v nm)}"
DEOBF_PLUGIN="${DEOBF_PLUGIN:-$SCRIPT_DIR/../deobfuscate_095_deobfus_ollvm/build/lib095.so}"
NATIVE_PLUGIN="${NATIVE_CLEANUP_PLUGIN:-$SCRIPT_DIR/../brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so}"

for tool in "$OPT_TOOL" "$CLANG_TOOL" "$NM_TOOL"; do
  [[ -x "$tool" ]] || { echo "required tool missing: $tool" >&2; exit 127; }
done
[[ -f "$DEOBF_PLUGIN" ]] || { echo "missing 095 plugin: $DEOBF_PLUGIN" >&2; exit 127; }
[[ -f "$NATIVE_PLUGIN" ]] || { echo "missing 090 plugin: $NATIVE_PLUGIN" >&2; exit 127; }

LEVEL="${DELIFT_OPT_LEVEL:-${BRIGHTEN_OPT_LEVEL:-O2}}"
[[ "$LEVEL" =~ ^O[123]$ ]] || { echo "DELIFT_OPT_LEVEL must be O1/O2/O3" >&2; exit 2; }

S1="$WORKDIR/${BASE}.01-verified.ll"
S2="$WORKDIR/${BASE}.02-proof-deobf.ll"
S3="$WORKDIR/${BASE}.03-scalar-clean.ll"
FINAL_LL="$WORKDIR/${BASE}.ll"
FINAL_O="$WORKDIR/${BASE}.o"
FINAL_BIN="$WORKDIR/${BASE}.bin"

rm -f "$S1" "$S2" "$S3" "$FINAL_LL" "$FINAL_O" "$FINAL_BIN"

# 100 does not invent source semantics. It only consumes facts established by
# 010-095, performs proof-backed deobfuscation once more after the last scalar
# exposure, and refuses publication unless 090 proves there is no live lifted
# runtime/state residue left.
"$OPT_TOOL" -S -passes=verify "$INPUT" -o "$S1"
"$OPT_TOOL" -load-pass-plugin="$DEOBF_PLUGIN" -S \
  -passes='095,verify' "$S1" -o "$S2"
"$OPT_TOOL" -S \
  -passes="default<${LEVEL}>,function(instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,adce),globaldce,verify" \
  "$S2" -o "$S3"

# Whole-program publication boundary. Keep only the process entry externally
# visible; everything else may be internalized and DCE'd before the strict
# native contract runs on the exact bytes that will be compiled.
"$OPT_TOOL" -load-pass-plugin="$NATIVE_PLUGIN" -S \
  -internalize-public-api-list=main \
  -passes='brighten-native-cleanup-post-frame-pass,internalize,ipsccp,deadargelim,globalopt,function(instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,adce),globaldce,brighten-native-cleanup-post-frame-pass,brighten-native-cleanup-final-pass,verify' \
  "$S3" -o "$FINAL_LL"

"$CLANG_TOOL" -O2 -c "$FINAL_LL" -o "$FINAL_O"
if ! "$NM_TOOL" --defined-only "$FINAL_O" | grep -Eq '(^|[[:space:]])main$'; then
  echo "strict clean publication rejected: public main is missing" >&2
  exit 1
fi
if "$NM_TOOL" -u "$FINAL_O" | grep -Eq '__remill_|__mcsema_|__lifter_|__translate_guest_pointer'; then
  echo "strict clean publication rejected: unresolved lifted runtime symbol" >&2
  "$NM_TOOL" -u "$FINAL_O" >&2 || true
  exit 1
fi

# No McSema compatibility runtime is allowed at the Clean-IR boundary.
"$CLANG_TOOL" -O2 "$FINAL_LL" -lm -o "$FINAL_BIN"

printf 'clean IR:     %s\n' "$FINAL_LL"
printf 'clean object: %s\n' "$FINAL_O"
printf 'clean binary: %s\n' "$FINAL_BIN"
