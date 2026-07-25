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
python3 "$SCRIPT_DIR/delift_storage.py" "$S2" "$S3"
python3 "$SCRIPT_DIR/run_o3_llvm.py" "$S3" "$S4"
python3 "$SCRIPT_DIR/strip_brighten_residuals.py" "$S4" "$S5"
python3 "$SCRIPT_DIR/run_o3_llvm.py" "$S5" "$FINAL_LL"
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
