# Full pipeline với một `run-id`

Runbook này mô tả cách chạy P0/A0/B0 từ preparation đến metrics, report và
visualization bằng **một `run-id` duy nhất**.

## Nguyên tắc

- Freeze đủ `P0`, `A0`, `B0` ngay từ lần chạy đầu.
- Khi resume, giữ nguyên dataset, config, model, source snapshot và method set.
- Không đổi `--methods`, `--config`, dataset hoặc `--no-resume` giữa chừng.
- Mọi artifact nằm tại `result/experiments/<run-id>/`.
- Không sửa/xoá `result.json`, quota state hoặc recovery state thủ công.

## 1. Kiểm tra môi trường

```bash
rtk git status --short
rtk test -f data/custom_dataset.csv
rtk test -f configs/experiment_three_case.yaml
rtk test -x /usr/bin/clang-21
rtk test -x /usr/bin/llvm-dis-21
rtk test -x /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
rtk python3 -m pytest -q
```

Nếu LLVM pass vừa thay đổi, build lại trước khi chạy:

```bash
rtk bash tools/rebuid_pass.sh
```

`experiment_primary.yaml` yêu cầu Git worktree sạch. Khi đang phát triển hoặc
worktree dirty, dùng `experiment_three_case.yaml`; kết quả đó không phải
primary outcome.

## 2. Vertex AI và default trên máy này

Pipeline hiện tại dùng các default đã có sẵn trong config, không cần tạo biến
`VERTEX_PROJECT`/`VERTEX_LOCATION` thủ công:

```text
config:       /home/dungbv/ev/capstone_project/configs/experiment_three_case.yaml
dataset:      /home/dungbv/ev/capstone_project/data/custom_dataset.csv
result root:  /home/dungbv/ev/capstone_project/result/experiments
clang:        /usr/bin/clang-21
llvm-dis:     /usr/bin/llvm-dis-21
ghidra:       /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
ADC:          /home/dungbv/.config/gcloud/application_default_credentials.json
location:     global
```

Kiểm tra ADC hiện tại:

```bash
rtk gcloud auth application-default print-access-token >/dev/null
```

Chỉ cần chạy login nếu lệnh trên thất bại:

```bash
rtk gcloud auth application-default login
```

`llm.model_id`, endpoint và pricing lấy từ config. Các giá trị này được freeze
vào manifest; đổi model giữa chừng sẽ bị từ chối khi resume.

## 3. Chọn config và tạo run ID

Development/pilot trên máy này:

```bash
CONFIG="configs/experiment_three_case.yaml"
```

Primary full dataset, chỉ dùng sau khi đã commit:

```bash
CONFIG="configs/experiment_primary.yaml"
```

```bash
RUN_ID="full_$(date -u +%Y%m%dT%H%M%SZ)"
echo "$RUN_ID"
```

Không dùng lại run ID cho dataset, model, prompt hoặc config khác.

## 4. Chạy toàn bộ E2E

```bash
rtk env PYTHONUNBUFFERED=1 python3 -m src.experiments.cli e2e \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" \
  --run-id "$RUN_ID"
```

Không truyền `--pilot` nếu muốn chạy toàn bộ dataset. E2E gồm:

```text
PREPARATION: base corpus + McSema/Remill raw lift + brightening intermediate + P0 delifted IR
PROCESSING: LLM + clang build + fuzz discovery + union corpus + oracle replay
EVALUATION: metrics + statistics + analysis + CSV/JSON/Markdown/SVG/HTML
```

Preparation không gọi LLM/fuzzer. Evaluation không gọi lại LLM/compiler/fuzzer.

## 5. Cho A0/B0 chạy trước P0

Đặt thứ tự trước lần chạy đầu:

```yaml
experiment:
  methods: [A0, B0, P0]
  variant_order: [A0, B0, P0]
```

Không chạy lần đầu với chỉ `A0,B0` rồi thêm `P0` sau. Manifest sẽ báo
`method order/set changed`. Dùng cùng config này cho toàn bộ run.

## 6. Chạy từng phase cùng một run ID

```bash
rtk python3 -m src.experiments.cli prepare \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" --run-id "$RUN_ID"

rtk python3 -m src.experiments.cli process \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" --run-id "$RUN_ID"

rtk python3 -m src.experiments.cli evaluate \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" --run-id "$RUN_ID"
```

`process` chỉ chạy sau khi preparation freeze đủ representation. `evaluate` chỉ
chạy sau khi raw comparison data của mọi sample đã sẵn sàng.

## 7. Resume và xử lý lỗi

### Dừng do terminal, SSH hoặc máy restart

Chạy lại đúng lệnh `e2e`/`process` với cùng `$RUN_ID`. Các sample/method đã xong
sẽ được skip.

### Quota, HTTP 429 hoặc `RESOURCE_EXHAUSTED`

Runner lưu `WAITING_FOR_QUOTA`, `quota_state.json` và recovery checkpoint. Exit
code `75` nghĩa là chưa hoàn tất, không phải semantic failure:

```bash
rtk python3 -m src.experiments.cli process \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" --run-id "$RUN_ID"
```

Chạy lại lệnh trên khi quota trở lại. Không đổi model/config/run ID.

### LLM response lỗi hoặc candidate không compile

Đây là failure của method/sample. Giữ nguyên các artifact:

```text
generation/recovery_iter*.response.txt
generation/recovery_iter*.meta.json
generation/recovery_iter*.parse.txt
generation/recovery_iter*.compile.txt
build/stderr.txt
result.json
```

Không sửa `result.json` để biến failure thành pass. Muốn đổi prompt/model thì
tạo run ID mới.

### Lifting, Ghidra, brightening hoặc delift fail

Retry cùng run ID chỉ khi lỗi môi trường tạm thời. Nếu source/pass/config đã đổi,
tạo run ID mới vì fingerprint trong manifest đã đổi.

### Một sample fail

Với `fail_fast: false`, runner ghi failure code riêng và tiếp tục sample khác.
Không xoá sample fail khỏi dataset để thay đổi denominator. Muốn retry riêng:

```bash
rtk python3 -m src.experiments.cli e2e \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" \
  --run-id "${RUN_ID}_retry_p00033" --sample-id p00033
```

### Worktree dirty hoặc config bị đổi

Primary run sẽ bị chặn nếu worktree dirty. Hãy commit thay đổi và dùng run ID
mới, hoặc dùng config development. Không dùng `--no-resume` để vượt kiểm tra.

### Timeout, crash, inconclusive

Đây là kết quả evaluation cần ghi nhận, không tự động coi là MATCH. Kiểm tra
`evaluation`, `processing/`, reference outputs và `integrity_report.json`.

## 8. Kiểm tra hoàn tất

Chỉ coi run hoàn tất khi lệnh kết thúc với exit code `0` và có đủ:

```bash
RUN_ROOT="result/experiments/$RUN_ID"
rtk test -f "$RUN_ROOT/experiment_manifest.json"
rtk test -f "$RUN_ROOT/evaluation_manifest.json"
rtk test -f "$RUN_ROOT/integrity_report.json"
rtk test -f "$RUN_ROOT/aggregate/metrics.json"
rtk test -f "$RUN_ROOT/aggregate/metrics_long.csv"
rtk test -f "$RUN_ROOT/aggregate/report.md"
rtk test -f "$RUN_ROOT/aggregate/dashboard.html"
```

Verify độc lập, không gọi LLM/fuzzer:

```bash
rtk python3 -m src.experiments.cli verify-integrity \
  /home/dungbv/ev/capstone_project/data/custom_dataset.csv \
  --config "/home/dungbv/ev/capstone_project/$CONFIG" --run-id "$RUN_ID"
```

Kiểm tra thêm: đủ P0/A0/B0, không còn `WAITING_FOR_QUOTA`, hash candidate không
đổi, reference là original ELF, union corpus nhất quán và audit chain hợp lệ.

## 9. Đọc kết quả

```text
aggregate/metrics.json       metric machine-readable
aggregate/metrics_long.csv   dữ liệu phân tích
aggregate/statistics.json    bootstrap/McNemar/CI
aggregate/report.md          báo cáo tổng hợp
aggregate/dashboard.html     dashboard tương tác
aggregate/*.svg              visualization
```

Đối chiếu pass rate với `MISMATCH`, `BUILD_FAILED`, `NOT_RUNNABLE`, `TIMEOUT`,
`CRASH`, `EVAL_INCONCLUSIVE`, confirmed input count, quota/cost và integrity.
Không gộp metrics giữa các run khác model, config hoặc dataset.

## 10. Checklist đóng run

- [ ] Exit code cuối là `0`.
- [ ] Đủ P0/A0/B0 cho mọi sample.
- [ ] Không còn pending generation hoặc `WAITING_FOR_QUOTA`.
- [ ] `verify-integrity` thành công.
- [ ] Đã lưu run ID, config/hash, dataset hash và Git commit.
- [ ] Đã lưu raw results, report và dashboard cho audit.
