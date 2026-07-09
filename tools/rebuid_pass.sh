#!/usr/bin/env bash
# =============================================================================
# setup_revng.sh — Cài đặt / cập nhật rev.ng dependency
# Thay thế script build các McSema/Remill LLVM pass cũ.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REVNG_DEP="$PROJECT_ROOT/dependency/revng"

echo "============================================================"
echo "==> rev.ng dependency setup"
echo "==> TARGET: $REVNG_DEP"
echo "============================================================"

# -------------------------------------------------------------------
# 1. Clone or update revng source
# -------------------------------------------------------------------
if [[ -d "$REVNG_DEP/.git" ]]; then
    echo "==> revng source đã tồn tại, đang cập nhật..."
    git -C "$REVNG_DEP" pull --ff-only
else
    echo "==> Clone revng từ https://github.com/revng/revng.git ..."
    git clone https://github.com/revng/revng.git "$REVNG_DEP"
fi

echo
echo "==> revng source tại: $REVNG_DEP"
echo

# -------------------------------------------------------------------
# 2. Build revng (nếu có CMakeLists.txt)
# -------------------------------------------------------------------
if [[ -f "$REVNG_DEP/CMakeLists.txt" ]]; then
    echo "==> Phát hiện CMakeLists.txt, tiến hành build revng..."
    BUILD_DIR="$REVNG_DEP/build"
    mkdir -p "$BUILD_DIR"

    CMAKE_EXTRA_ARGS=()
    # Tìm LLVM installation
    for llvm_ver in 21 20 19 18; do
        LLVM_CFG="$(which llvm-config-${llvm_ver} 2>/dev/null || true)"
        if [[ -n "$LLVM_CFG" ]]; then
            CMAKE_EXTRA_ARGS+=("-DLLVM_DIR=$(${LLVM_CFG} --cmakedir)")
            echo "==> Sử dụng LLVM $llvm_ver: $LLVM_CFG"
            break
        fi
    done

    cmake -S "$REVNG_DEP" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        "${CMAKE_EXTRA_ARGS[@]}"

    cmake --build "$BUILD_DIR" -j"$(nproc)"

    # Tạo symlink bin/ nếu chưa có
    if [[ -f "$BUILD_DIR/bin/revng" ]] && [[ ! -d "$REVNG_DEP/bin" ]]; then
        ln -s "$BUILD_DIR/bin" "$REVNG_DEP/bin"
        echo "==> Symlink bin/ → build/bin/ đã tạo"
    fi

    echo "==> Build revng hoàn tất!"
else
    echo "==> Không tìm thấy CMakeLists.txt."
    echo "    revng có thể cần quy trình build đặc biệt."
    echo "    Xem: https://github.com/revng/revng#building"
    echo
    echo "    Hoặc tải pre-built release và đặt vào: $REVNG_DEP/bin/revng"
fi

echo
echo "============================================================"
echo "==> Kiểm tra cài đặt:"
REVNG_BIN="${REVNG_DEP}/bin/revng"
if command -v revng &>/dev/null; then
    echo "    revng (PATH): $(which revng)"
    revng --version 2>/dev/null || true
elif [[ -f "$REVNG_BIN" ]]; then
    echo "    revng (local): $REVNG_BIN"
    "$REVNG_BIN" --version 2>/dev/null || true
else
    echo "    [!] revng chưa sẵn sàng. Xem hướng dẫn build ở trên."
fi
echo "============================================================"
echo "Done."
