#!/usr/bin/env bash
# =============================================================================
# setup_revng.sh — Cài đặt rev.ng distributable trên máy mới
# Chạy 1 lần trên mỗi máy: bash tools/setup_revng.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_DIR="$PROJECT_ROOT/dependency/revng_dist"
REVNG_BIN_DIR="$INSTALL_DIR/revng"

# ---------------------------------------------------------------------------
# Detect shell config file
# ---------------------------------------------------------------------------
detect_shell_rc() {
    local shell_name
    shell_name="$(basename "${SHELL:-bash}")"
    case "$shell_name" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

# ---------------------------------------------------------------------------
# Add PATH export to shell rc (idempotent)
# ---------------------------------------------------------------------------
add_to_path() {
    local bin_dir="$1"
    local rc_file
    rc_file="$(detect_shell_rc)"

    local export_line="export PATH=\"\$PATH:$bin_dir\""
    local marker="# revng PATH (added by setup_revng.sh)"

    if grep -qF "$bin_dir" "$rc_file" 2>/dev/null; then
        echo "[✓] PATH đã có $bin_dir trong $rc_file — bỏ qua."
        return
    fi

    echo "" >> "$rc_file"
    echo "$marker" >> "$rc_file"
    echo "$export_line" >> "$rc_file"

    echo "[✓] Đã thêm vào $rc_file:"
    echo "    $export_line"
    echo ""
    echo "    Áp dụng ngay bằng:"
    echo "    source $rc_file"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "============================================================"
echo "==> rev.ng setup"
echo "==> Install dir: $INSTALL_DIR"
echo "============================================================"

# Bước 1: Kiểm tra xem revng đã có trong PATH chưa
if command -v revng &>/dev/null; then
    echo "[✓] revng đã có trong PATH: $(which revng)"
    revng --version 2>/dev/null || true
    echo ""
    echo "Không cần cài lại. Nếu muốn cài bản mới hơn, xóa $REVNG_BIN_DIR rồi chạy lại."
    exit 0
fi

# Bước 2: Kiểm tra xem đã download chưa
if [[ -x "$REVNG_BIN_DIR/revng" ]]; then
    echo "[✓] revng đã tải tại $REVNG_BIN_DIR"
else
    # Download distributable
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    echo "==> Đang tải rev.ng distributable (~2.1GB, chờ chút)..."
    curl -L -s https://rev.ng/downloads/revng-distributable/master/install.sh | bash
    echo "[✓] Tải và giải nén xong."
fi

echo ""

# Bước 3: Tự động thêm vào PATH trong shell rc
echo "==> Thêm revng vào PATH..."
add_to_path "$REVNG_BIN_DIR"

# Bước 4: Export cho session hiện tại
export PATH="$PATH:$REVNG_BIN_DIR"

echo ""
echo "============================================================"
echo "==> Kiểm tra:"
if command -v revng &>/dev/null; then
    echo "[✓] revng: $(which revng)"
    revng --version 2>/dev/null || true
else
    echo "[!] revng chưa có trong PATH của session này."
    echo "    Chạy: source $(detect_shell_rc)"
fi
echo "============================================================"
echo "Done."
