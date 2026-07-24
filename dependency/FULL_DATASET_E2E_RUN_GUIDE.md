# Hướng dẫn chạy full-dataset E2E (P0/A0/B0)

Tài liệu này mô tả cách chạy thực nghiệm đầy đủ trên toàn bộ dataset, dùng
Gemini 2.5 Pro qua Vertex AI ADC. Run full phải dùng `run-id` mới; không ghi đè
run cũ và không dùng artifact Flash làm kết quả Pro.

## 1. Kiểm tra trước khi chạy

```bash
rtk git status --short
rtk test -f data/custom_dataset.csv
rtk test -f configs/experiment_three_case.yaml
rtk env PYTHONPATH=src python3 -m pytest -q
```

Nếu worktree có thay đổi chưa được ghi nhận, lưu lại `git diff` cùng run ID để
audit. Không xoá các run cũ.

## 2. Cấu hình ADC và Vertex

Đăng nhập đúng tài khoản Google Cloud và tạo ADC:

```bash
rtk gcloud auth application-default login
rtk gcloud auth application-default print-access-token >/dev/null
```

Đặt project/location (không hard-code token vào shell history):

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
export VERTEX_PROJECT="<PROJECT_ID_MOI>"
export VERTEX_LOCATION="global"
```

Smoke test phải trả về `finishReason: STOP` và `modelVersion` đúng model. Việc
Flash smoke test thành công chỉ chứng minh ADC/endpoint hoạt động; không thay
thế cho kiểm tra Pro.

```bash
PROJECT_ID="$VERTEX_PROJECT" LOCATION="$VERTEX_LOCATION" MODEL="gemini-2.5-pro"
rtk curl -s -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H 'Content-Type: application/json' \
  "https://aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL}:generateContent" \
  -d '{"contents":[{"role":"user","parts":[{"text":"Trả lời đúng một từ: OK"}]}]}'
```

## 3. Chạy full dataset

Không truyền `--pilot`; khi đó runner lấy toàn bộ sample trong
`data/custom_dataset.csv` (P0/A0/B0 theo config).

```bash
RUN_ID="real_full_$(date -u +%Y%m%dT%H%M%SZ)_gemini25pro"
rtk env GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS" \
  VERTEX_PROJECT="$VERTEX_PROJECT" VERTEX_LOCATION="$VERTEX_LOCATION" \
  PYTHONUNBUFFERED=1 python3 -m src.experiments.cli run \
  data/custom_dataset.csv \
  --config configs/experiment_three_case.yaml \
  --run-id "$RUN_ID"
```

Lưu lại `RUN_ID`; mọi artifact nằm dưới
`result/experiments/$RUN_ID/`.

## 4. Resume khi bị gián đoạn hoặc 429

Chạy lại **cùng** `RUN_ID` và không dùng `--no-resume`:

```bash
rtk env GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS" \
  VERTEX_PROJECT="$VERTEX_PROJECT" VERTEX_LOCATION="$VERTEX_LOCATION" \
  PYTHONUNBUFFERED=1 python3 -m src.experiments.cli run \
  data/custom_dataset.csv --config configs/experiment_three_case.yaml \
  --run-id "$RUN_ID"
```

HTTP 429/`RESOURCE_EXHAUSTED` được ghi là `WAITING_FOR_QUOTA`, không tính vào
logical generation của P0. Scheduler giữ request hash, iteration và resume sau
`Retry-After`/quota reset (tối đa một giờ theo protocol). HTTP 499
`CANCELLED`, 400 cấu hình sai, hoặc lỗi compile là failure thật và phải ghi
riêng trong báo cáo; không tự động đổi thành PASS.

## 5. Kiểm tra hoàn tất và integrity

```bash
rtk env PYTHONPATH=src python3 -m src.experiments.cli verify-integrity \
  data/custom_dataset.csv --config configs/experiment_three_case.yaml \
  --run-id "$RUN_ID"
```

Chỉ coi run là hoàn tất khi có `metrics.json`, `metrics_long.csv`, audit log,
manifest và integrity report trong thư mục run. Đọc `metrics.json` để lấy
`e2e_pass`, pass rate, mismatch/inconclusive, model ID, token usage và cost.

## 6. Visualization và audit

Các SVG và `dashboard.html` được sinh trong thư mục run sau aggregate. Mở
dashboard bằng trình duyệt và kiểm tra:

1. model ID là `gemini-2.5-pro`, project/run ID đúng;
2. số sample/method khớp dataset;
3. quota fields (`quota_throttled`, `quota_wait_started`,
   `quota_resumed`, `quota_wait_duration_ms`) không bị bỏ trống;
4. mọi failure có error code và artifact path truy nguyên được.

Không dùng dashboard thay cho `metrics.json`; dashboard chỉ là evidence index.
Khi báo cáo luận văn, đính kèm run ID, config hash, dataset hash, event-log
hash và external seal (nếu đã tạo).

## 7. Các lỗi thường gặp

- **Model vẫn là Flash**: kiểm tra `config_resolved.json` của run; không tin
  biến shell nếu config vẫn ghi model khác.
- **HTTP 429**: để scheduler chờ và resume cùng run ID; không tạo generation
  mới để “né” quota.
- **HTTP 499**: request bị provider huỷ; ghi failure, kiểm tra timeout/quota,
  rồi quyết định rerun bằng run ID mới cho một thí nghiệm mới.
- **Candidate compile fail/JSON sai**: đó là lỗi generation của method, không
  phải lỗi evaluator; giữ response và traceback trong artifact.
- **Kết quả cũ khác model**: không gộp metrics giữa Flash và Pro; mỗi model,
  ADC/project hoặc prompt freeze phải có run ID riêng.
