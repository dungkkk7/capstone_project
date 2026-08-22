# LLM recovery

Module này tạo Candidate C và hỗ trợ compiler/behavioral feedback cho các flow
iterative. Campaign chuẩn phải chạy qua:

```bash
python3 src/evaluation/run_experiment.py data/custom_dataset.csv \
  --fuzz-iterations 1000
```

## Evidence routing

| Flow | Evidence đưa vào model | Policy |
|---|---|---|
| `B1` | Ghidra pseudocode từ original obfuscated ELF | one-shot |
| `B2` | cleaned `objdump` assembly từ original obfuscated ELF | one-shot |
| `F1` | Clean IR sau custom pipeline | iterative recovery |
| `F2` | Raw IR sau binary lifting | iterative recovery |
| `F3` | Clean IR sau custom pipeline | one-shot, không repair loop |

Prompt, provenance và call budget nằm trong
`src/evaluation/five_flow_protocol.py`. Original C, seed và expected output chỉ
dùng hậu nghiệm; chúng không được đưa vào prompt. Obfuscated ELF luôn là
behavioral reference.

## Repair và oracle

`F1` và `F2` có tối đa năm provider call. `F3` chỉ có một provider call.
Compile repair chỉ dùng compiler diagnostics; behavioral repair chỉ dùng
reproducible counterexample. `B1` và `B2` cũng không có repair call.

Behavior trên mỗi input là:

```text
(stdout_bytes, stderr_bytes, exit_code, terminating_signal, timeout_status)
```

Toàn bộ tuple phải giống nhau. `F3` vẫn tạo candidate C và được differential
test với original obfuscated ELF; chỉ không phát hành request repair thứ hai.

## Cấu hình thường dùng

- `LLM_RECOVERY_MAX_ITERS`: ngân sách generation/repair cho flow iterative.
- `LLM_RECOVERY_FUZZ_ITERS`: input budget cho behavioral validation.
- `LLM_RECOVERY_FUZZ_TIMEOUT`: timeout mỗi lần chạy binary.
- `LLM_RECOVERY_TIMEOUT`: timeout request provider.
- `LLM_RECOVERY_MODEL`: model/provider ID.

Các giá trị token/cost provider không cung cấp phải để `null` hoặc `0` theo
schema hiện hành; không tự ước lượng.
