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

`--mode` chỉ chọn representation. Muốn chạy đúng ablation contract, repair
policy và artifact logging của evaluation framework thì dùng
`src/evaluation/run_experiment.py`.

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

## Sáu evaluation flow

| Flow | Cấu hình |
|---|---|
| F1 `FULL` | Clean IR + LLVM2C pseudocode + error context, iterative |
| F2 `NO_ERROR_CONTEXT` | Clean IR + LLVM2C pseudocode, đúng một provider call |
| F3 `NO_PSEUDOCODE` | Clean IR + error context, iterative |
| F4 `NO_DIRECT_CLEAN_IR` | LLVM2C pseudocode + error context, iterative |
| F5 `RAW_IR_BASELINE` | Raw IR + error context, iterative |
| F6 `RAW_IR_NO_ERROR_CONTEXT_DERIVED` | Raw IR, checkpoint provider call đầu tiên của F5 |

F1–F5 là flow chạy độc lập. F6 được report generator suy ra từ lần gọi
provider thực tế đầu tiên của F5, bỏ retry `MAX_TOKENS` và mọi candidate/feedback
về sau. Vì thế F6 là paired derived checkpoint, không phải một pipeline run độc
lập. Artifact thiếu được ghi `CANCELLED`, không nội suy.

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
