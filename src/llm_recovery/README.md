# Hướng dẫn dùng LLM Recovery

Folder này là nơi chạy luồng `llm-recovery` để tạo lại mã C từ LLVM IR.

Thiết kế prompt và flow chi tiết nằm trong [PROMPT_FLOW.md](PROMPT_FLOW.md).

## 1) Chạy nhanh

- Chế độ mặc định: two-stage (Ghidra pseudo -> LLM).
- Chạy từ root repo:

```bash
cd /home/dungbv/capstone_project
rtk python3 src/main.py data/llm_test.csv llm-recovery
```

Hoặc có thể dùng trực tiếp biến môi trường:

```bash
rtk LLM_RECOVERY_PSEUDO_BACKEND=1 python3 src/main.py data/llm_test.csv llm-recovery
```

## 2) Chọn luồng mode

- `Mode 1` (two-stage, khuyến nghị):
  - Ghidra headless decompile binary tham chiếu sang pseudo C.
  - Rồi gửi pseudo C cho LLM.
  - Thiết lập:

```bash
LLM_RECOVERY_PSEUDO_BACKEND=1
```

- `Mode 2` (direct IR):
  - Bỏ qua Ghidra, gửi trực tiếp IR cho LLM.
  - Thiết lập:

```bash
LLM_RECOVERY_TWO_STAGE=0
LLM_RECOVERY_PSEUDO_BACKEND=2
```

## 3) Chọn file cho Ghidra (quan trọng)

Mode 1 **không fallback về `original_binary` nữa**. Nó chỉ nhận:

`metadata["recovery_reference_binary"]`

Nội bộ pipeline sẽ truyền:

- Nếu delifted IR compile được sang binary tham chiếu: `.../<base>_delifted_ref.bin`
- Ngược lại, trong luồng hiện tại sẽ truyền `original_binary` như fallback từ `main.py` (khi metadata được set).

Nếu `recovery_reference_binary` thiếu -> mode 1 dừng, không tự chuyển sang mode 2.

Ghidra executable mặc định:

`/opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless`

Có thể ghi đè bằng `LLM_RECOVERY_GHIDRA_ANALYZE_HEADLESS`.

## 4) Khác biệt với AFL binary

- `bin1_afl.bin` chỉ là binary có instrumentation để sinh input trong fuzzing.
- Ghidra decompile **không** lấy `bin1_afl.bin`.

## 5) Ý nghĩa các flag thường dùng

- `LLM_RECOVERY_MAX_ITERS`: số vòng lặp fix lỗi + retry.
- `LLM_RECOVERY_FUZZ_ITERS`: số test cho mỗi lần fuzz trong recovery.
- `LLM_RECOVERY_FUZZ_TIMEOUT`: hard timeout mỗi binary execution (mặc định `0.1` giây).
- `LLM_RECOVERY_TIMEOUT`: timeout request tới LLM.

## 6) Gợi ý đọc log

Trong log bạn sẽ thấy:

  - `[LLM] Mode 1: decompile bằng Ghidra rồi gửi C-like pseudocode cho LLM.`
  - `[LLM] Ghidra analyzeHeadless: <path>`: executable Ghidra được dùng.
  - `Dừng mode 1`: Ghidra stage không chạy được; mode 2 phải được chọn rõ ràng.
