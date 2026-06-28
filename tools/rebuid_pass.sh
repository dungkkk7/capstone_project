#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS_DIR="$PROJECT_ROOT/src/llvm_pass"

cd "$PASS_DIR"

for d in brighten_{010_repair,020_devirt,030_state_ssa,040_stack_frame}_pass; do
    echo "==> Building $d"
    cmake -S "$d" -B "$d/build"
    cmake --build "$d/build" -j"$(nproc)"
done

echo "Done."