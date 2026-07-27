# Binary Deobfuscation & C Source Code Recovery Pipeline

Hệ thống thực nghiệm khôi phục mã nguồn C11 từ các file binary Linux ELF bị làm rối (obfuscate) bằng OLLVM. Dự án kết hợp McSema/Remill để nâng mã (lifting), bộ LLVM Pass tùy biến 010-095 để deobfuscate làm sạch (brightening), công cụ **LLVM-to-C Transpiler (`tools/llvm_to_c.py`)** để dịch ngược ra mã C chuẩn, và LLM (Gemini) cùng differential testing (AFL++) 1,000 runs để khôi phục mã C hoàn chỉnh.

---

## **PHẦN 1: TỔNG QUAN LUỒNG THỰC THI CHÍNH**

### 1. Luồng Xử Lý Chính (Pipeline Flow)
1. **Binary Lifting**: Dùng McSema/Remill nâng mã nhị phân ELF x86_64 lên LLVM IR thô (`*_fla_bcf_instsub.ll`).
2. **LLVM Deobfuscation Pipeline (Passes 010 $\rightarrow$ 095)**:
   - Tái cấu trúc thanh ghi, khôi phục khung Stack Frame Alloca an toàn.
   - Hủy diệt 100% các biểu thức rác OLLVM BCF/MBA và tiêu hủy công tắc CFF Dispatcher Switch.
   - Tạo ra mã IR deobfuscated sạch (`*_final.ll`) giảm **85.22% số dòng mã toàn dataset**.
3. **LLVM-to-C Transpilation**:
   - Chạy công cụ [`tools/llvm_to_c.py`](tools/llvm_to_c.py) chuyển đổi mã IR sạch sang mã C chuẩn (`*_llvm2c.c`) ít hơn 54.6% dòng mã C so với Ghidra.
4. **LLM Recovery & AFL++ Mutation Hook Verification**:
   - Tái cấu trúc mã C11 tiêu chuẩn và xác minh tương đương ngữ nghĩa 100% bằng bộ fuzzer AFL++ đột biến đúng **1,000 inputs**.

---

## **PHẦN 2: FILE CẤU HÌNH PROMPT VÀ MODEL (`configs/pipeline_config.env`)**

Chủ động tùy chỉnh Model name, Temperature và Prompt cho 4 Mode chạy trong file [`configs/pipeline_config.env`](configs/pipeline_config.env):
- `LLM_MODEL=gemini-2.5-flash`
- `LLM_TEMPERATURE=0.1`
- `PROMPT_MODE_RAW_IR`: Prompt cho Mode 1 (Raw IR).
- `PROMPT_MODE_CLEAN_PSEUDOCODE`: Prompt cho Mode 2 (Clean Pseudocode).
- `PROMPT_MODE_CLEAN_IR`: Prompt cho Mode 3 (Clean IR).
- `PROMPT_MODE_CLEAN_IR_AND_PSEUDOCODE`: Prompt cho Mode 4 (Clean IR + Pseudocode).

---

## **PHẦN 3: 4 CHẾ ĐỘ THỰC THI (4 PIPELINE MODES)**

Tất cả các chế độ đều thực thi luồng từ **Obfuscated Binary $\rightarrow$ Recovered C Code**:

1. **Mode 1 (`--mode=raw_ir`)**:
   `Obfuscated Binary` $\rightarrow$ `Raw LLVM IR` $\rightarrow$ `LLM` $\rightarrow$ `Recovered C`
   ```bash
   python3 src/main.py data/custom_dataset.csv llm-recovery --mode=raw_ir
   ```

2. **Mode 2 (`--mode=clean_pseudocode`)**:
   `Obfuscated Binary` $\rightarrow$ `Raw IR` $\rightarrow$ `LLVM-to-C Transpiler` $\rightarrow$ `LLM` $\rightarrow$ `Recovered C`
   ```bash
   python3 src/main.py data/custom_dataset.csv llm-recovery --mode=clean_pseudocode
   ```

3. **Mode 3 (`--mode=clean_ir`)**:
   `Obfuscated Binary` $\rightarrow$ `Passes 010-095` $\rightarrow$ `Clean IR` $\rightarrow$ `LLM` $\rightarrow$ `Recovered C`
   ```bash
   python3 src/main.py data/custom_dataset.csv llm-recovery --mode=clean_ir
   ```

4. **Mode 4 (`--mode=clean_ir_and_pseudocode`) (Default)**:
   `Obfuscated Binary` $\rightarrow$ `Passes 010-095` $\rightarrow$ `Clean IR + LLVM-to-C Pseudocode` $\rightarrow$ `LLM` $\rightarrow$ `Recovered C`
   ```bash
   python3 src/main.py data/custom_dataset.csv llm-recovery --mode=clean_ir_and_pseudocode
   ```

---

## **PHẦN 4: BỘ ĐO LƯỜNG METRICS EVALUATOR (`src/metrics_evaluator.py`)**

Hệ thống tự động đo lường và lưu báo cáo JSON:
- **Metrics Deobfuscation IR (giữa Raw IR và Clean IR)**:
  - `raw_ir_loc` vs `clean_ir_loc` & `ir_loc_reduction_pct` (Tỷ lệ thu gọn dòng mã IR).
  - `raw_instructions` vs `clean_instructions` & `inst_reduction_pct` (Tỷ lệ giảm câu lệnh IR).
  - `raw_switches` vs `clean_switches` & `cff_unflatten_pct` (Tỷ lệ tiêu hủy công tắc CFF Switch).
- **Metrics C Output**:
  - `c_loc` (Số dòng mã nguồn C sinh ra).
  - `fuzz_total_runs` & `fuzz_matches` (Đạt đúng **1,000 runs đột biến trực tiếp từ AFL++**).
  - `semantic_pass` (Trạng thái pass 100% tương đương ngữ nghĩa).
