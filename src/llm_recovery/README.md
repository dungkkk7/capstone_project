# Hướng dẫn LLM Recovery

Module này khôi phục Candidate C từ LLVM evidence và hỗ trợ compiler/behavioral
feedback cho các flow iterative. Backend pseudocode production là **LLVM2C**;
Ghidra không còn là một recovery backend.

## Chạy nhanh

Chạy từ root repository:

```bash
python3 src/main.py data/custom_dataset.csv llm-recovery
```

Chọn representation:

```bash
# Clean IR + LLVM2C pseudocode
python3 src/main.py data/custom_dataset.csv llm-recovery \
    --mode=clean_ir_and_pseudocode

# Chỉ LLVM2C pseudocode sinh từ Clean IR
python3 src/main.py data/custom_dataset.csv llm-recovery \
    --mode=clean_pseudocode

# Chỉ Clean IR
python3 src/main.py data/custom_dataset.csv llm-recovery \
    --mode=clean_ir

# Chỉ Raw IR chưa deobfuscate
python3 src/main.py data/custom_dataset.csv llm-recovery \
    --mode=raw_ir
```

`--mode` chỉ chọn representation. Muốn chạy đúng primary evaluation contract
thì dùng `src/evaluation/run_two_flow_experiment.py`.

## Evidence routing

| Representation | Raw IR | Clean IR trực tiếp | LLVM2C pseudocode |
|---|:---:|:---:|:---:|
| `clean_ir_and_pseudocode` | Không | Có | Có |
| `clean_pseudocode` | Không | Không | Có |
| `clean_ir` | Không | Có | Không |
| `raw_ir` | Có | Không | Không |

Original C chỉ được dùng cho đánh giá hậu nghiệm; tuyệt đối không được đưa vào
recovery prompt. Obfuscated Binary là behavioral reference khi differential
execution.

## Primary evaluation B0/F3 và feedback-policy ablations B1/B2/B3

| Flow | Cấu hình |
|---|---|
| B0 `LLM4DECOMPILE_GHIDRA_ONESHOT` | Original obfuscated ELF → Ghidra program pseudocode → đúng một provider call, không feedback |
| B1 `GHIDRA_PSEUDOCODE_ITERATIVE` | Cùng Ghidra evidence và byte-identical request đầu của B0 → validation-guided repair, tối đa năm response |
| B2 `LLM4DECOMPILE_ASSEMBLY_ONESHOT` | Original ELF → cleaned program-level `objdump -d` assembly → exact LLM4Decompile assembly prompt, một response |
| B3 `LLM4DECOMPILE_ASSEMBLY_ITERATIVE` | Cùng assembly và byte-identical request đầu của B2 → validation-guided repair, tối đa năm response |
| F3 `CLEAN_IR_ITERATIVE_MAIN` | Original obfuscated ELF → custom pass 010–100 → Clean IR → compiler/reproducible-counterexample repair |

Prompt, exact hash, paper provenance và call budget nằm trong
`src/evaluation/two_flow_protocol.py`. B1 và B3 là registered non-primary
feedback ablations; B2 là raw-assembly external baseline. Chúng không được đổi
tên thành primary flow hoặc dùng để thay thế frozen B0/F3. Các experiment
legacy không thuộc primary claim.

## Repair và behavioral oracle

Flow iterative tách riêng:

- compile repair: dùng diagnostics của compiler;
- behavioral repair: dùng reproducible counterexample;
- repair case count: số candidate fail được đưa vào repair;
- repair round count: số vòng sửa đã thực hiện.

Behavior của mỗi executable trên input `x` là:

```text
(stdout_bytes, stderr_bytes, exit_code, terminating_signal, timeout_status)
```

Chỉ match khi toàn bộ tuple giống nhau. Counterexample phải replay thành công
theo policy mới được kết luận `FAIL_BEHAVIORAL` hoặc dùng cho repair.

## Biến cấu hình thường dùng

- `LLM_RECOVERY_MAX_ITERS`: ngân sách vòng generation/repair.
- `LLM_RECOVERY_FUZZ_ITERS`: input budget cho behavioral validation.
- `LLM_RECOVERY_FUZZ_TIMEOUT`: timeout cho mỗi binary execution.
- `LLM_RECOVERY_TIMEOUT`: timeout request tới provider.
- `LLM_RECOVERY_MODEL`: model/provider model ID.

Token, cost hoặc resource metric mà provider/runtime không cung cấp phải được
lưu `null`; không tự ước lượng.

## Regenerate report offline

```bash
python3 src/evaluation/export_existing_metrics.py \
    result/eval_20260728_124405
```

Lệnh này chỉ đọc artifact đã lưu và tạo lại CSV, JSONL, Markdown, LaTeX, HTML
và figure PNG/SVG/PDF; không gọi lại LLM, compiler repair hay fuzzing.
