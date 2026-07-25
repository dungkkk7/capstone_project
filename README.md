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

### 3. Chạy Toàn Bộ Chuỗi Thực Nghiệm E2E

Một lệnh dưới đây chạy đúng ba phase có ranh giới artifact rõ ràng:

### Phase 1 — Preparation

Phase này không gọi LLM hoặc fuzzer (`llm_calls=0`, `fuzz_calls=0`). Nó tạo và
freeze toàn bộ đầu vào mà model sẽ nhận:

- **B0:** Ghidra C-like pseudocode từ original obfuscated ELF;
- **A0:** raw LLVM IR từ McSema, không chạy brightening/optimization pass;
- **P0:** raw lift, brightened LLVM IR, internal reference binary và Ghidra
  pseudocode của brightened reference;
- deterministic base corpus dùng cho processing/fuzzing.

Mỗi sample có `preparation_manifest.json`; mỗi method có
`representation/representation_manifest.json`. Hash của primary artifact và
mọi attachment được kiểm tra lại trước khi processing.

### Phase 2 — Processing

Phase này chỉ tiêu thụ representation đã freeze, không chạy lại lifting,
brightening hoặc Ghidra:

1. chạy P0 semantic precheck, sau đó gọi LLM (B0/A0 one-shot, P0 repair tối đa
   5 vòng);
2. extract và build candidate C;
3. fuzz discovery từng method;
4. hợp nhất common union corpus;
5. chạy original ELF làm oracle và replay P0/A0/B0 trên cùng corpus;
6. ghi raw comparison data vào `result.json` và `processing/`.

### Phase 3 — Evaluation

Phase này không gọi LLM, compiler hay fuzzer. Nó chỉ đọc raw processing data để:

- tính metric/pass rate/failure funnel;
- pairwise P0–A0 và P0–B0;
- bootstrap confidence interval và exact McNemar;
- tổng hợp token/cost và IR/CFG metrics;
- sinh CSV, JSON, report Markdown, SVG và dashboard HTML;
- seal artifact và verify integrity.

Chạy thực nghiệm chuẩn cho tập dữ liệu 40 case:

`experiment_primary.yaml` là chế độ nghiên cứu chính thức và yêu cầu Git
worktree sạch (`require_clean_git: true`). Hãy commit đúng các thay đổi đã
chốt trước khi chạy. Không commit artifact/generated files ngoài ý muốn.

```bash
python3 -m src.experiments.cli e2e data/custom_dataset.csv --config configs/experiment_primary.yaml --run-id=my_experiment_run
```

Chạy thử nghiệm Pilot (2 case mẫu) để kiểm tra nhanh pipeline:

Config này cho phép worktree dirty và phù hợp với development/pilot; kết quả
không được gọi là primary full-dataset outcome.

```bash
python3 -m src.experiments.cli e2e data/custom_dataset.csv --config configs/experiment_three_case.yaml --run-id=pilot_run --pilot=2
```

`run` vẫn là tên chính thức và tương đương hoàn toàn với alias `e2e`. Nếu bị
gián đoạn hoặc chờ quota, chạy lại đúng lệnh với cùng `--run-id`; mặc định
runner sẽ resume từ checkpoint. Lệnh trả exit code `0` khi hoàn tất và `75`
khi generation đã checkpoint nhưng còn chờ resume. Kết quả cuối nằm tại
`result/experiments/<run-id>/aggregate/`, còn báo cáo kiểm tra nằm tại
`result/experiments/<run-id>/integrity_report.json`.

Có thể chạy từng phase độc lập với cùng dataset/config/run-id:

Khi worktree còn thay đổi, dùng `configs/experiment_three_case.yaml` hoặc
`configs/experiment_pilot.yaml` cho cả ba lệnh dưới đây. Chỉ chuyển sang
`experiment_primary.yaml` sau khi đã commit và bắt đầu một `run-id` mới.

```bash
python3 -m src.experiments.cli prepare  data/custom_dataset.csv --config configs/experiment_three_case.yaml --run-id=dev_phase_run
python3 -m src.experiments.cli process  data/custom_dataset.csv --config configs/experiment_three_case.yaml --run-id=dev_phase_run
python3 -m src.experiments.cli evaluate data/custom_dataset.csv --config configs/experiment_three_case.yaml --run-id=dev_phase_run
```

`precompute` là alias tương thích cũ của preparation; `generate` là alias tương
thích cũ của processing.

Phase contract này dùng experiment manifest schema `3.0`. Không resume run tạo
bởi harness cũ qua ranh giới phase mới; phải dùng `--run-id` mới để artifact và
metric provenance không bị trộn.

### 4. Chạy Hệ Thống Unit Tests
```bash
python3 -m pytest -v
```
