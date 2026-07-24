# P0/A0/B0 Binary Deobfuscation Experiment

Codebase này là hệ thống thực nghiệm khôi phục mã nguồn C11 từ các file binary Linux ELF bị làm rối (obfuscate) bằng OLLVM. Dự án kết hợp McSema/Remill để nâng mã (lifting), Ghidra để dịch ngược giả mã (pseudocode), LLVM Pass tùy biến để làm sạch (brightening), và LLM (Gemini) cùng differential testing làm oracle để đánh giá hành vi.

Tài liệu chi tiết đặc tả coding nằm tại: `dependency/DAC_TA_CODING_B0_A0_EVALUATION_CHI_TIET.md`.

---

## **PHẦN 1: TỔNG QUAN HỆ THỐNG THỰC NGHIỆM**

### 1. Câu Hỏi Nghiên Cứu và Giả Thuyết
Giả thuyết nghiên cứu chính là: **Phương pháp P0 sẽ có tỷ lệ khôi phục chính xác (semantic equivalence) cao hơn A0 và B0 nhờ vào representation đã qua làm sạch (brightening) và quy trình lặp sửa lỗi (iterative repair loop tối đa 5 lượt).**
- **Oracle Diễn Giải**: Kết quả thực nghiệm được ghi nhận khách quan độc lập với giả thuyết ban đầu. Không có sự tinh chỉnh prompt hay corpus để hạ thấp B0 hay A0.
- **Tập Dữ Liệu**: Gồm 40 case mẫu từ tập dữ liệu thực nghiệm chuẩn (`data/custom_dataset.csv`), đại diện cho các binary bị làm rối với Flatting (FLA), BCF (Bogus Control Flow), và Instruction Substitution (SUB).

### 2. Ba Phương Phương So Sánh (P0 vs A0 vs B0)

| Phương Pháp | Representation Đầu Vào LLM | Phác Thảo Luồng Sinh Mã | Oracle Đánh Giá Hành Vi |
|---|---|---|---|
| **B0** | Ghidra C-like pseudocode từ ELF obfuscated gốc | One-shot trực tiếp | ELF obfuscated gốc |
| **A0** | Raw LLVM IR (`raw.ll`) từ McSema | One-shot trực tiếp | ELF obfuscated gốc |
| **P0** | Brightened LLVM IR + Ghidra pseudocode của bản tham chiếu | Vòng lặp sửa lỗi (Feedback loop tối đa 5 lần) | ELF obfuscated gốc |

---

## **PHẦN 2: CHI TIẾT KỸ THUẬT VÀ PHÂN RÃ HỆ THỐNG**

### 1. Cấu Trúc Mã Nguồn (Codebase Architecture)
- `src/binary_lifting/`: Điều phối McSema cfg-generator và lifter để nâng mã ELF lên LLVM IR thô (`raw.ll`).
- `src/llvm_pass/`: Chứa mã nguồn 10 pass LLVM C++ thực hiện tối ưu hóa, loại bỏ cấu trúc Remill/McSema giả lập.
- `src/llm_recovery/`: Pipeline giao tiếp API LLM, quản lý vòng lặp phản hồi feedback (AFL++ compiler/execution errors).
- `src/fuzzing_equi_check/`: Bộ fuzzer đối chứng hành vi sử dụng AFL++ sinh input và so sánh exit code / stdout / stderr.
- `src/experiments/`: Khung chạy thực nghiệm (CLI, Quota controller, Quản lý checkpoint trạng thái và lưu log).

### 2. Tiến Trình Chạy Thực Nghiệm (Pipeline Steps)

#### Bước 1: Binary Lifting (Lifting)
ELF Linux x86-64 gốc được McSema dịch ngược thành LLVM IR thô. Struct trạng thái CPU `%struct.State` được lưu làm biến toàn cục và mọi thanh ghi (RAX, RSP, RBP, v.v.) được load/store thông qua con trỏ trạng thái này.

#### Bước 2: Brightening (Làm Sạch IR)
Chuỗi 10 pass C++ tùy biến được thực thi tuần tự thông qua driver `src/llvm_pass/britening_ir.py`:
1. **Brighten Repair Pass** (`brighten-repair-pass`): Sửa các UB giả, strip flag poison/noundef và các chỉ thị assembly nhúng vô nghĩa.
2. **Compatibility Layer** (`brighten-remill-runtime-pass`): Khôi phục các Remill memory intrinsics (`__remill_read_memory_...`) và control flow.
3. **Register State SSA** (`brighten-state-ssa-pass`): Tối giản CPU State, chuyển các thanh ghi thành SSA value trực tiếp, khôi phục flag CPU thành boolean logic `i1`.
4. **Stack Frame Recovery** (`brighten-stack-frame-pass`): Phát hiện stack ảo của McSema và chuyển thành local `alloca` có kiểu (typed stack frame).
5. **ABI & Function Signature Rewrite** (`brighten-abi-recovery-pass`): Khôi phục danh sách tham số (Arguments) và giá trị trả về (Return) nguyên bản của hàm thay vì State/Memory.
6. **Extern Call Bridge** (`brighten-extern-call-bridge`): Chuyển hướng các lệnh gọi hàm thư viện ( printf, scanf, malloc, v.v.) về hàm libc native tương đương.
7. **Global & Data Recovery** (`brighten-global-data-recovery-pass`): Khôi phục biến toàn cục, mảng tĩnh và các string literal từ byte blob `@seg_...`.
8. **Type Reconstruction** (`brighten-type-reconstruct`): Phân tích offset GEP để nhóm biến thành struct và mảng hợp lệ.
9. **Final Native Cleanup** (`brighten-native-cleanup-pass`): Dọn dẹp State toàn cục và tối ưu hóa (`sroa`, `mem2reg`, `gvn`, `simplifycfg`).
10. **OLLVM Deobfuscation** (`brighten-ollvm-deobf-pass` - Opt-in): Loại bỏ cấu trúc loop điều khiển dispatcher làm rối của OLLVM.

#### Bước 3: LLM Generation (Sinh Mã C)
- Mã giả C-like (Ghidra pseudocode) và LLVM IR đã brightening được dùng làm prompt đầu vào.
- LLM (Gemini 3.5 Flash) tái khôi phục cấu trúc chương trình C chuẩn.

#### Bước 4: Fuzzing & Semantic Check (Đánh Giá Hành Vi)
- Candidate C được biên dịch thành binary bằng `clang-21`.
- Chạy differential execution trên 100 inputs (AFL++ generated + contract-based inputs).
- Kết quả được phân loại thành: `MATCH` (khớp hành vi), `MISMATCH` (lệch exit code/stdout/stderr), `TIMEOUT`, `CRASH`.

---

## **PHẦN 3: HƯỚNG DẪN VẬN HÀNH (OPERATIONAL INSTRUCTIONS)**

### 1. Chuẩn Bị Môi Trường
Cài đặt thư viện Python:
```bash
python3 -m pip install pyyaml requests pytest google-genai
```
Yêu cầu hệ thống đã cài đặt `opt-21`, `clang-21` và `analyzeHeadless` của Ghidra.

### 2. Biên Dịch Lại Các Pass C++
```bash
bash tools/rebuid_pass.sh
```

### 3. Chạy Toàn Bộ Chuỗi Thực Nghiệm
Chạy thực nghiệm chuẩn cho tập dữ liệu 40 case:
```bash
python3 -m src.experiments.cli run data/custom_dataset.csv configs/experiment_three_case.yaml --run-id=my_experiment_run
```

Chạy thử nghiệm Pilot (2 case mẫu) để kiểm tra nhanh pipeline:
```bash
python3 -m src.experiments.cli run data/custom_dataset.csv configs/experiment_three_case.yaml --run-id=pilot_run --pilot=2
```

### 4. Chạy Hệ Thống Unit Tests
```bash
python3 -m pytest -v
```
