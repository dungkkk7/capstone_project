#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Nếu script nằm ngay trong src/llvm_pass thì dùng luôn thư mục đó.
# Nếu script nằm ở root/scripts thì fallback về PROJECT_ROOT/src/llvm_pass.
if [[ -d "$SCRIPT_DIR/brighten_010_repair_pass" || -d "$SCRIPT_DIR/brighten_020_devirt_pass" ]]; then
    PASS_DIR="$SCRIPT_DIR"
else
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    PASS_DIR="$PROJECT_ROOT/src/llvm_pass"
fi

cd "$PASS_DIR"

echo "==> PASS_DIR: $PASS_DIR"
echo

# Rebuild sạch toàn bộ pass brighten_*
for d in brighten_*; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/CMakeLists.txt" ]] || {
        echo "==> Skipping $d: no CMakeLists.txt"
        continue
    }

    echo "============================================================"
    echo "==> Rebuilding $d"
    echo "============================================================"

    rm -rf "$d/build"
    cmake -S "$d" -B "$d/build"
    cmake --build "$d/build" -j"$(nproc)"

    echo
done

echo "Done."