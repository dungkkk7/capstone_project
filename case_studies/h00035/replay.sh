#!/usr/bin/env bash
set -euo pipefail

CASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$CASE_DIR/../.." && pwd)
REFERENCE="$PROJECT_ROOT/data/own_dataset/obfuscated/h00035/n26081535_fla_bcf_instsub.elf"
RECOVERED="$CASE_DIR/recovered_f3_o1.c"
SEED="$CASE_DIR/seed.txt"
EXPECTED="$CASE_DIR/expected.txt"
CASE_TMP=$(mktemp -d)
trap 'rm -r -- "$CASE_TMP"' EXIT

CLANG_BIN=${CLANG_BIN:-$(command -v clang-21 || command -v clang)}
"$CLANG_BIN" -std=c11 -O2 -Wall -Wextra -Werror "$RECOVERED" -o "$CASE_TMP/recovered.bin"

"$REFERENCE" < "$SEED" > "$CASE_TMP/reference.out"
"$CASE_TMP/recovered.bin" < "$SEED" > "$CASE_TMP/recovered.out"

echo "Reference output:"
sed -n '1,20p' "$CASE_TMP/reference.out"
echo "Recovered output:"
sed -n '1,20p' "$CASE_TMP/recovered.out"

diff -u "$EXPECTED" "$CASE_TMP/reference.out"
diff -u "$CASE_TMP/reference.out" "$CASE_TMP/recovered.out"
echo "PASS: frozen seed output is byte-identical."
