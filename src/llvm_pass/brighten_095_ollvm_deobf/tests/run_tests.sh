#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PASS_DIR="$(cd -- "$TEST_DIR/.." && pwd)"
PLUGIN="$PASS_DIR/build/BrightenOLLVMDeobfPass.so"

cmake -S "$PASS_DIR" -B "$PASS_DIR/build"
cmake --build "$PASS_DIR/build" -j"$(nproc)"

for test_file in "$TEST_DIR"/*.ll; do
  temp_base="$(mktemp)"
  sed -n 's/^; RUN: //p' "$test_file" | while IFS= read -r command; do
    command="${command//\%plugin/$PLUGIN}"
    command="${command//\%s/$test_file}"
    command="${command//\%t/$temp_base}"
    bash -c "$command"
  done
  rm -f "$temp_base" "$temp_base.ll" "$temp_base.json"
done

python3 "$TEST_DIR/property_validate.py" --plugin "$PLUGIN"
python3 "$TEST_DIR/flag_bundle_property.py" --plugin "$PLUGIN"
