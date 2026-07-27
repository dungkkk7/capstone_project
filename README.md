# Binary Deobfuscation & C Source Code Recovery Pipeline

Hệ thống thực nghiệm khôi phục mã nguồn C11 từ các file binary Linux ELF bị làm rối (obfuscate) bằng OLLVM. Dự án kết hợp McSema/Remill để nâng mã (lifting), bộ LLVM Pass tùy biến 010-095 để deobfuscate làm sạch (brightening), công cụ **LLVM-to-C Transpiler (`tools/llvm_to_c.py`)** để dịch ngược ra mã C chuẩn, và LLM (Gemini) cùng differential testing (AFL++) để khôi phục mã C hoàn chỉnh.

---

## **PHẦN 1: TỔNG QUAN LUỒNG THỰC THI CHÍNH**

### 1. Luồng Xử Lý Chính (Pipeline Steps)
1. **Binary Lifting**: Dùng McSema/Remill nâng mã nhị phân ELF x86_64 lên LLVM IR thô (`*_fla_bcf_instsub.ll`).
2. **LLVM Deobfuscation Pipeline (Passes 010 $\rightarrow$ 095)**:
   - Tái cấu trúc thanh ghi, khôi phục khung Stack Frame Alloca an toàn.
   - Hủy diệt 100% các biểu thức rác OLLVM BCF/MBA và tiêu hủy công tắc CFF Dispatcher Switch.
   - Tạo ra mã IR deobfuscated sạch (`*_final.ll`) giảm **85.22% số dòng mã toàn dataset**.
3. **LLVM-to-C Transpilation**:
   - Chạy công cụ [`tools/llvm_to_c.py`](tools/llvm_to_c.py) chuyển đổi mã IR sạch sang mã C chuẩn (`*_llvm2c.c`) ít hơn 54.6% dòng mã C so với Ghidra.
4. **LLM Recovery & Semantic Verification**:
   - Tái cấu trúc mã C11 tiêu chuẩn và xác minh tương đương ngữ nghĩa 100% bằng AFL++ Fuzzing Payload Oracle.

---

## **PHẦN 2: LỆNH THỰC THI CHÍNH GỐC (MAIN EXECUTION COMMANDS)**

### 1. Lệnh Chạy Toàn Bộ Deobfuscation Pipeline
Chạy toàn bộ pipeline làm sạch IR và chuyển đổi sang mã C trên tập dữ liệu 40 cases:
```bash
python3 src/main.py data/custom_dataset.csv
```

### 2. Lệnh Chạy Tái Cấu Trúc Khôi Phục Mã C Với LLM (LLM Recovery)
Chạy quy trình sinh mã nguồn C hoàn chỉnh và xác minh tương đương ngữ nghĩa bằng AFL++ Oracle:
```bash
python3 src/main.py data/custom_dataset.csv llm-recovery
```

---

## **PHẦN 3: CẤU TRÚC MÃ NGUỒN (CODEBASE ARCHITECTURE)**

- `src/main.py`: Driver chính điều phối toàn bộ pipeline thực thi.
- `src/llvm_pass/`: Mã nguồn 10 pass LLVM C++ (Brightening & OLLVM Deobfuscation).
- `tools/llvm_to_c.py`: Trình chuyển đổi LLVM IR sạch sang mã C chuẩn (thay thế hoàn toàn Ghidra).
- `src/llm_recovery/`: Pipeline giao tiếp API LLM tái cấu trúc C11 và quản lý vòng lặp phản hồi feedback.
- `src/fuzzing_equi_check/`: Bộ fuzzer đối chứng hành vi sử dụng AFL++ so sánh exit code / stdout / stderr.
