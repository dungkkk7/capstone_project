#!/usr/bin/env bash

set -euo pipefail

INPUT_DIR="data/clean_src"
OUTPUT_DIR="data/obfuscated"

CLANG="clang-21"
LLVM_LINK="llvm-link-21"
LLVM_DIS="llvm-dis-21"

OLLVM_OBF="./dependency/ollvm/build/ollvm-obf"

COMPILE_FLAGS=(
    -O0
    -fno-vectorize
    -fno-slp-vectorize
   # -mno-sse
   # -mno-sse2
   # -mno-mmx
)

OBFUSCATE_FLAGS=(
   # --code-clone
    --substitute
    #--if-convert
    --flatten
 #   --opaque-predicates
    --bogus-control-flow
   # --const-unfold
   # --schedule-instructions
  #  --outline-functions
   #--arith-encode
    #--stack-randomize
   # --verify-each
   # --reg-pressure
   # --loop-to-recursion
    --seed=2976579765
    --transform-percent=100
)

mkdir -p "$OUTPUT_DIR"

CSV_FILE="data/obfuscated_bin_list.csv"
echo "binary_path" > "$CSV_FILE"

echo "[*] Building dataset"

for project_dir in "$INPUT_DIR"/*; do
    [ -d "$project_dir" ] || continue

    project=$(basename "$project_dir")

    echo
    echo "=================================================="
    echo "[*] Project: $project"
    echo "=================================================="

    out_dir="$OUTPUT_DIR/$project"
    rm -rf "$out_dir"
    mkdir -p "$out_dir/obj"

    bc_files=()

    #
    # Compile source -> LLVM BC
    #
    for src in "$project_dir"/*.c; do
        [ -f "$src" ] || continue

        base=$(basename "$src" .c)
        bc="$out_dir/obj/$base.bc"

        echo "[+] Compile $(basename "$src")"

        "$CLANG" \
            "${COMPILE_FLAGS[@]}" \
            -emit-llvm \
            -c \
            "$src" \
            -o "$bc"

        bc_files+=("$bc")
    done

    if [ ${#bc_files[@]} -eq 0 ]; then
        echo "[!] No C files found"
        continue
    fi

    #
    # Link all modules
    #
    clean_bc="$out_dir/clean.bc"

    echo "[+] Link clean.bc"

    "$LLVM_LINK" \
        "${bc_files[@]}" \
        -o "$clean_bc"

    #
    # Clean IR
    #
    echo "[+] Generate clean.ll"

    "$LLVM_DIS" \
        "$clean_bc" \
        -o "$out_dir/clean.ll"

    #
    # Clean binary
    #
    echo "[+] Build clean.bin"

    "$CLANG" \
        "$clean_bc" \
        -O0 \
        -o "$out_dir/clean.bin"

    #
    # Obfuscate
    #
    echo "[+] Obfuscate"

    obf_bc="$out_dir/obfuscated.bc"

    "$OLLVM_OBF" \
        "${OBFUSCATE_FLAGS[@]}" \
        "$clean_bc" \
        -o "$obf_bc"

    #
    # Obfuscated IR
    #
    echo "[+] Generate obfuscated.ll"

    "$LLVM_DIS" \
        "$obf_bc" \
        -o "$out_dir/obfuscated.ll"

    #
    # Obfuscated binary
    #
    echo "[+] Build obfuscated.bin"

    "$CLANG" \
        "$obf_bc" \
        -O0 \
        -o "$out_dir/obfuscated.bin"

    #
    # Stripped binary
    #
    echo "[+] Strip obfuscated.bin"

    strip \
        --strip-all \
        "$out_dir/obfuscated.bin"

    echo "data/obfuscated/$project/obfuscated.bin" >> "$CSV_FILE"

    rm -rf "$out_dir/obj"

    echo "[✓] Done"
done

echo
echo "[✓] Dataset complete"