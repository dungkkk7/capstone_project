# P0/A0/B0 Binary Deobfuscation Experiment

Đây là codebase thực nghiệm khôi phục mã C11 từ ELF Linux bị obfuscate bằng
OLLVM. Hệ thống kết hợp McSema/Remill, chuỗi LLVM pass tùy biến, Ghidra,
LLM và differential testing để so sánh ba phương pháp `P0`, `A0`, `B0`
trên cùng chương trình và cùng behavioral oracle.

Tài liệu này là hướng dẫn vận hành chuẩn của project. Đặc tả triển khai đầy đủ
nằm tại
[`DAC_TA_CODING_B0_A0_EVALUATION_CHI_TIET.md`](DAC_TA_CODING_B0_A0_EVALUATION_CHI_TIET.md).

## 1. Câu hỏi nghiên cứu và nguyên tắc diễn giải

Giả thuyết nghiên cứu là P0 sẽ có tỷ lệ khôi phục đúng cao hơn A0 và B0 vì P0
được cung cấp representation đã brightening và có tối đa năm vòng
compiler/fuzz feedback. Đây là **giả thuyết cần kiểm chứng**, không phải điều
kiện để pipeline được coi là thành công.

Project không sửa prompt, denominator, corpus hay failure taxonomy để ép A0/B0
yếu hơn. Nếu kết quả thực nghiệm không cho thấy P0 tốt hơn, kết quả đó vẫn phải
được giữ nguyên và báo cáo.

So sánh chính là so sánh **end-to-end method performance**:

- P0 dùng representation tốt hơn và iterative repair;
- A0/B0 dùng một logical generation, không được sửa bằng feedback;
- do protocol generation khác nhau, `P0 - A0` và `P0 - B0` không phải
  representation-only causal effect.

Muốn đo riêng causal effect của representation cần thêm một nhánh khác, ví dụ
`P0-one-shot`, dùng cùng call budget với A0/B0. Nhánh đó không thuộc protocol
hiện tại vì P0-strict phải giữ pipeline legacy tối đa năm iteration.

## 2. Ba phương pháp

| Method | Representation đưa vào LLM | Generation policy | Final oracle |
|---|---|---|---|
| `P0` | Brightened LLVM IR và Ghidra pseudocode sinh từ output P0 | Legacy compiler/fuzz-feedback loop, early stop, tối đa 5 response hợp lệ | Original obfuscated ELF |
| `A0` | Raw McSema LLVM IR, không custom pass, không optimization, không pseudocode | Strict one-shot | Original obfuscated ELF |
| `B0` | Program-level Ghidra pseudocode decompile trực tiếp từ original obfuscated ELF | Strict one-shot | Original obfuscated ELF |

### 2.1. P0-strict

P0 được chạy qua adapter nhưng không bị đổi thuật toán:

1. lift original ELF bằng McSema;
2. chạy chuỗi brightening/deobfuscation hiện có;
3. kiểm tra brightened artifact với original ELF;
4. compile brightened artifact thành reference nội bộ của P0;
5. Ghidra decompile reference nội bộ đó;
6. mỗi request sử dụng đầy đủ P0 pseudocode và brightened textual IR;
7. compile/fuzz candidate sau từng response;
8. đưa feedback vào iteration tiếp theo;
9. early stop khi pass, tối đa 5 response hợp lệ.

`brightened_ref.bin` chỉ được dùng trong vòng repair nội bộ của P0. Candidate
cuối vẫn được evaluator chung so trực tiếp với original obfuscated ELF.

Model, location, temperature, top-p, candidate count, output-token ceiling và
thinking level của P0 được khóa từ cùng YAML với A0/B0. Các biến môi trường
`LLM_RECOVERY_MODEL`, `LLM_RECOVERY_TEMPERATURE` và
`LLM_RECOVERY_TOP_P` không được phép làm P0 drift khỏi experiment contract.

### 2.2. A0 raw-IR-only

A0 dừng ngay sau McSema:

```text
original ELF -> raw.bc -> llvm-dis -> raw.ll -> LLM one-shot
```

Invariant:

- `pass_pipeline == []`;
- `optimization_level == none`;
- không gọi brightening;
- không đưa Ghidra pseudocode vào request;
- build/fuzz failure không được trigger generation thứ hai.

### 2.3. B0 original-ELF pseudocode

B0 chạy Ghidra trên đúng `SampleIdentity.original_elf_path`. Builder kiểm tra
path và SHA-256 trước khi decompile. B0 không được dùng:

- raw hoặc brightened `.ll/.bc`;
- `brightened_ref.bin`;
- clean source;
- expected output, semantic report hoặc counterexample.

B0 prompt là prompt do nhóm thiết kế dựa trên task framing của BinDeObfBench và
output requirement của luận văn. Project không tuyên bố đây là exact prompt của
paper. Byte-exact template nằm tại `src/experiments/prompts.py` và được bảo vệ
bằng golden test.

## 3. Kiến trúc thực nghiệm

```text
data/custom_dataset.csv
          |
          v
  immutable enrolment
  ELF + seed + input-contract SHA-256
          |
          +----------------+----------------+
          |                |                |
          v                v                v
       P0 adapter       A0 builder       B0 builder
   bright IR+pseudo       raw IR       original pseudo
       <=5 calls         1 call           1 call
          |                |                |
          +----------------+----------------+
                           |
                           v
                    common C11 build
                           |
                           v
            equal-time candidate discovery
                           |
                           v
    frozen union(base ∪ D_P0 ∪ D_A0 ∪ D_B0)
                           |
                           v
           replay every built candidate on union
                           |
                           v
              compare with original ELF
                           |
                           v
        metrics + paired statistics + SVG/dashboard
                           |
                           v
            hash-chain audit + artifact seal
```

Các module chính:

| Path | Trách nhiệm |
|---|---|
| `src/experiments/config.py` | Default config, merge YAML, validation và config hash |
| `src/experiments/identity.py` | Enrol sample, khóa ELF/seed/input-contract identity |
| `src/experiments/representations.py` | Raw lift cache, A0 builder, B0 Ghidra builder |
| `src/experiments/p0_legacy.py` | Adapter giữ P0 current và khóa model parity |
| `src/experiments/prompts.py` | Byte-exact A0/B0 prompt policy |
| `src/experiments/generation.py` | Context gate, leakage scan, strict one-shot |
| `src/experiments/quota.py` | 429 scheduler, checkpoint và accepted-response cache |
| `src/experiments/evaluation.py` | Build, discovery, frozen union và behavioral replay |
| `src/experiments/runner.py` | Orchestration, terminal state, resume và integrity |
| `src/experiments/reporting.py` | Denominator, metrics, paired inference và CSV/JSON |
| `src/experiments/visualization.py` | Publication-ready SVG và evidence dashboard |
| `src/experiments/audit.py` | Hash-chained event log và artifact ledger |
| `src/llm_recovery/llm_recovery.py` | Existing P0 recovery loop và Vertex client |
| `src/llvm_pass/` | Brightening/deobfuscation LLVM passes của P0 |
| `src/fuzzing_equi_check/` | Semantic fuzzer và input-contract support |

## 4. Scientific invariants

Một main run chỉ hợp lệ khi các invariant sau đều đúng:

1. Cùng enrolled sample set cho ba method.
2. Cùng requested model và decoding policy.
3. `candidate_count == 1`.
4. P0 có tối đa 5 accepted model responses.
5. A0/B0 có đúng 1 logical generation và 1 accepted model response khi
   generation thành công.
6. HTTP 429 không được tính là model response.
7. A0 không có brightening/Ghidra evidence.
8. B0 không có LLVM/P0 evidence.
9. Candidate không được sửa sau generation.
10. Mọi built candidate của cùng sample được replay trên cùng frozen union
    corpus hash.
11. Final reference hash phải là original ELF hash.
12. Failed variant vẫn nằm trong intention-to-treat denominator.
13. Aggregate không được chạy khi còn variant nonterminal như
    `WAITING_FOR_QUOTA`.
14. P0/A0/B0 dùng cùng compiler contract và evaluator.
15. Result chỉ được dùng sau khi `verify-integrity` pass.

Integrity verifier kiểm tra lại invariant từ artifact thực tế, không chỉ tin
vào log.

## 5. Yêu cầu môi trường

Project nhắm tới Linux x86-64. Python cần hỗ trợ type syntax của Python 3.10+.

### 5.1. Công cụ bắt buộc

- Python và `PyYAML`;
- LLVM/Clang, cấu hình mẫu dùng LLVM/Clang 21;
- McSema/Remill dưới `dependency/mcsema/`;
- IDA headless dùng bởi McSema disassembler;
- Ghidra `analyzeHeadless`;
- các shared-object LLVM pass đã build;
- Google Vertex AI credentials cho real LLM run.

AFL++ được ưu tiên từ `dependency/AFLplusplus/` hoặc `PATH`. Nếu không có,
semantic fuzzer có bounded-generator fallback; engine thực tế phải được đọc từ
structured fuzz report, không được giả định.

### 5.2. Python packages

Các package phụ thuộc vào đường gọi:

```bash
python3 -m pip install pyyaml requests pytest
python3 -m pip install google-genai
```

`google-genai` chỉ cần cho SDK path; Vertex REST fallback vẫn cần `requests` và
Application Default Credentials.

### 5.3. Vertex authentication

Thiết lập project bằng một trong các biến:

```bash
export VERTEX_PROJECT="your-project-id"
# hoặc GOOGLE_CLOUD_PROJECT / GCLOUD_PROJECT
```

Credentials có thể đến từ `GOOGLE_APPLICATION_CREDENTIALS` hoặc Application
Default Credentials của môi trường. Không commit credential vào repository,
config, audit log hay result directory.

### 5.4. LLVM passes

Pipeline P0 cần các plugin `Brighten*.so` dưới từng thư mục pass. Script
`tools/rebuid_pass.sh` rebuild toàn bộ pass nhưng sẽ xóa từng thư mục `build/`
trước khi compile; chỉ chạy khi chấp nhận hành vi đó.

## 6. Dataset contract

Dataset mặc định:

```text
data/custom_dataset.csv
```

Mỗi row phải resolve được tới original obfuscated ELF. Enrolment khóa:

- dataset row index;
- sample ID;
- absolute ELF path và ELF SHA-256;
- architecture;
- input-contract SHA-256;
- seed-manifest SHA-256;
- obfuscation tags suy ra từ filename.

Seed nằm tại:

```text
data/seeds/<sample_id>/
```

Input contract nằm tại:

```text
data/input_contracts/custom_dataset.json
```

Thay ELF, seed, contract, dataset selection hoặc method set rồi dùng lại cùng
`run_id` sẽ bị refuse resume. `--pilot N` chọn N sample đầu sau khi sort theo
`sample_id`, không phải N row ngẫu nhiên.

## 7. Cấu hình

Ba config chuẩn:

- `configs/experiment_pilot.yaml`: smoke/pilot budget nhỏ, cho phép dirty Git;
- `configs/experiment_three_case.yaml`: đủ budget primary nhưng scope cố định
  cho nghiên cứu ba case, cho phép dirty Git và ghi rõ scope trong artifacts;
- `configs/experiment_primary.yaml`: main budget và bắt buộc clean Git.

### 7.1. Các giá trị phải freeze trước real run

Model card chính thức của Gemini 2.5 Pro được kiểm tra ngày `2026-07-24`:
context window `1,048,576`, maximum output `65,535`. Config dùng output cap
`65,535` và lưu cả URL nguồn/ngày xác minh. Trước một đợt primary ở thời điểm
khác, phải re-verify exact provider/model version:

<https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/2-5-pro>

```yaml
experiment:
  methods: [P0, A0, B0]
  variant_order: [B0, A0, P0]
  study_scope: primary_full_dataset
  run_seed: 4912026
  resume: true
  fail_fast: false
  require_clean_git: true

llm:
  provider: vertex_ai
  model_id: gemini-2.5-pro
  location: global
  temperature: 0.0
  top_p: 1.0
  candidate_count: 1
  max_output_tokens: 65535
  thinking_level: HIGH
  request_timeout_sec: 900
  context_window_tokens: 1048576
  model_spec_source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/2-5-pro
  model_spec_verified_date: "2026-07-24"
  context_safety_margin_tokens: 1024
  transport_retries: 2
  pricing_plan: standard_paygo_global
  pricing_usd_per_million_input_tokens: 1.25
  pricing_usd_per_million_output_tokens: 10.00
  pricing_long_context_threshold_tokens: 200000
  pricing_usd_per_million_input_tokens_long_context: 2.50
  pricing_usd_per_million_output_tokens_long_context: 15.00
  pricing_source: https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing
  pricing_verified_date: "2026-07-24"
```

Nếu provider hỗ trợ snapshot/version cố định, dùng snapshot thay cho alias tự
động trỏ sang model mới. Requested model và response `model_version` đều được
lưu vào artifact.

### 7.2. Variant order

`experiment.methods` xác định enrolled methods. `variant_order` phải là một
permutation chính xác của methods và chỉ xác định thứ tự generation. Config
chuẩn chạy B0/A0 trước P0 để tránh vô tình ưu tiên proposed method.

CLI `--methods` dùng cho debug/substudy; nó tự lọc `variant_order`. Primary
comparison phải giữ đủ `P0,A0,B0`.

### 7.3. Compiler contract

Config primary mặc định:

```yaml
build:
  compiler: /usr/bin/clang-21
  flags:
    - -std=c11
    - -O0
    - -fno-strict-aliasing
    - -fwrapv
    - -Wno-everything
  link_flags: [-lm]
  timeout_sec: 60
```

Không thay compiler/flags giữa method. Compiler version và command thực tế được
lưu theo variant.

### 7.4. Context gate

A0/B0 dùng deterministic conservative estimate:

```text
required =
    estimated_input_tokens
  + max_output_tokens
  + context_safety_margin_tokens
```

Nếu `required > context_window_tokens`, variant kết thúc bằng
`CONTEXT_OVERFLOW`. Representation không bị truncate vì truncation làm đổi task.
Context overflow vẫn ở E2E denominator và được báo riêng để không nhầm với
semantic failure.

P0 giữ request construction/file-attachment path của legacy pipeline; provider
usage metadata được lưu cho từng accepted response.

### 7.5. Pricing

Hai config canonical khóa giá Standard PayGo trên global endpoint được xác minh
ngày `2026-07-24`:

```yaml
llm:
  pricing_plan: standard_paygo_global
  pricing_usd_per_million_input_tokens: 1.25
  pricing_usd_per_million_output_tokens: 10.00
  pricing_long_context_threshold_tokens: 200000
  pricing_usd_per_million_input_tokens_long_context: 2.50
  pricing_usd_per_million_output_tokens_long_context: 15.00
  pricing_source: https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing
  pricing_verified_date: "2026-07-24"
```

Nguồn chính thức:
<https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing>.
Các giá long-context áp dụng khi một request vượt 200K input tokens theo bảng
giá của Gemini 2.5 Pro. Khi có đủ giá, report sinh
estimated total cost và cost per PASS từ provider-reported tokens. `output_tokens`
chỉ là response; `thinking_tokens` là reasoning; `billable_output_tokens` bằng
response + reasoning và là giá trị dùng cho output cost. Estimate không gồm
những SKU khác và không thay thế provider invoice. Fake-LLM run luôn trả cost
`null`, kể cả khi config có pricing, vì nó chỉ có giá trị kiểm thử pipeline.

## 8. Chạy experiment

Chạy từ repository root.

### 8.1. One-command pilot

Với model spec đã verify và freeze:

```bash
python3 src/main.py data/custom_dataset.csv experiment \
  --config configs/experiment_pilot.yaml \
  --run-id pilot_001 \
  --pilot 1 \
  --methods P0,A0,B0
```

CLI native tương đương:

```bash
python3 -m src.experiments.cli run data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml \
  --run-id pilot_001 \
  --pilot 1
```

`run_id` chỉ cho phép chữ, số, `.`, `_`, `-`, bắt đầu bằng chữ hoặc số, tối đa
128 ký tự. Path traversal bị reject.

### 8.2. Staged workflow

```bash
python3 -m src.experiments.cli prepare data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml --run-id pilot_001 --pilot 1

python3 -m src.experiments.cli generate data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml --run-id pilot_001 --pilot 1

python3 -m src.experiments.cli evaluate data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml --run-id pilot_001 --pilot 1

python3 -m src.experiments.cli aggregate data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml --run-id pilot_001 --pilot 1

python3 -m src.experiments.cli verify-integrity data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml --run-id pilot_001 --pilot 1
```

`aggregate` sẽ fail nếu còn variant nonterminal hoặc thiếu method. Điều này cố ý
ngăn report coi quota/interruption là method failure.

### 8.3. Full-budget study trên ba case

Lệnh dưới đây chọn deterministic ba `sample_id` đầu sau khi sort:
`p00001`, `p00008`, `p00033`. Mỗi case chạy đủ B0, A0 và P0 với generation,
fuzz-discovery, common union replay, aggregate, figures và integrity seal:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
export VERTEX_PROJECT="your-project-id"

python3 -m src.experiments.cli run data/custom_dataset.csv \
  --config configs/experiment_three_case.yaml \
  --run-id real_three_case_001 \
  --pilot 3
```

Đây là `scoped_three_case_full_budget`, không phải estimate cho toàn dataset.
Không thêm `--fake-response-path` vào real run.

### 8.4. Chạy sample cụ thể

```bash
python3 -m src.experiments.cli run data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml \
  --run-id debug_p00001 \
  --sample-id p00001
```

Lặp `--sample-id` để chọn nhiều sample.

### 8.5. Fake-LLM integration run

Để test plumbing mà không gọi provider:

```bash
python3 -m src.experiments.cli run data/custom_dataset.csv \
  --config configs/experiment_pilot.yaml \
  --run-id fake_pipeline_001 \
  --pilot 1 \
  --fake-response-path tests/experiments/fixtures/fake_candidate.c
```

Fake run kiểm tra lifting, representations, build, evaluator, metrics và audit;
nó không cung cấp bằng chứng về chất lượng LLM và không được trộn vào primary
results. `metrics.json`, `figures_manifest.json`, `report.md` và
`dashboard.html` tự ghi `pipeline_validation_only`; dashboard hiện cảnh báo
“Not a research result” để tránh ảnh fake pilot bị dùng nhầm trong luận văn.

## 9. Resume và quota-aware scheduling

### 9.1. Resume contract

Resume chỉ được phép khi các identity sau không đổi:

- config SHA-256;
- dataset SHA-256;
- enrolled sample/ELF/seed/input-contract fingerprint;
- method set và order;
- run ID.

Union corpus được ghi một lần với `frozen: true`. Nếu evaluate bị ngắt sau khi
union đã tạo, lần resume đọc lại đúng manifest và input hash thay vì rebuild từ
chỉ các method chưa finalize.

Accepted LLM response được cache theo exact request SHA-256. Nếu process crash
sau khi provider đã trả response nhưng trước khi stage hoàn tất, resume replay
response và metadata đã cache, không gọi model lần hai.

P0 `recovery_state.json` lưu iteration, candidate, feedback và request hash.
Nếu pseudocode/config drift làm request mới khác hash đã checkpoint, resume bị
refuse thay vì gửi một request khác dưới cùng experiment.

### 9.2. HTTP 429/quota

```yaml
llm:
  rate_limit:
    enabled: true
    max_wait_seconds: 3600
    default_retry_after_seconds: 3600
```

Khi gặp HTTP 429 hoặc `RESOURCE_EXHAUSTED`:

1. ghi `quota_throttled`;
2. persist exact request hash và iteration;
3. chuyển variant sang nonterminal `WAITING_FOR_QUOTA`;
4. ghi `quota_wait_started`;
5. chờ `Retry-After` hoặc fallback, với tổng budget tối đa một giờ;
6. ghi `quota_resumed`;
7. retry đúng request.

Semantics của counter:

| Counter | 429 có tăng không? | Provider response có tăng không? |
|---|---:|---:|
| `api_attempt_count` | Có | Có |
| `model_call_count` | Không | Có |
| `logical_generation_count` | Không | Theo protocol |
| P0 five-response budget | Không | Có |

Nếu hết wait budget mà provider vẫn throttle, variant giữ
`WAITING_FOR_QUOTA`; aggregate/integrity từ chối coi run là hoàn tất.

## 10. Common evaluator

### 10.1. Base corpus

Base corpus gồm exact seeds và deterministic contract-valid supplements. Nếu
không có seed/contract, evaluator dùng boundary input tối thiểu. Generator seed
được freeze trong YAML.

### 10.2. Candidate-specific discovery nhưng common replay

Mỗi built candidate nhận cùng discovery time/budget:

```text
D_P0, D_A0, D_B0
```

Sau discovery:

```text
C_union = dedup(C_base ∪ D_P0 ∪ D_A0 ∪ D_B0)
```

Tất cả built candidate được replay trên cùng `C_union`. Nhờ đó input do B0 khám
phá vẫn có thể làm lộ mismatch của P0/A0 và ngược lại.

### 10.3. Observable behavior

Mặc định evaluator so:

- stdout bytes;
- stderr bytes;
- exit status;
- crash signal;
- timeout/asymmetry.

Environment được freeze:

```yaml
LC_ALL: C
LANG: C
TZ: UTC
```

Mỗi execution chạy trong temporary working directory riêng.

### 10.4. PASS policy

`PASS` yêu cầu:

- zero confirmed mismatch;
- số confirmed input đạt `min_confirmed_inputs`;
- reference inconclusive fraction không vượt ngưỡng;
- candidate thỏa smoke-runnable contract;
- executable hash không đổi trước/sau replay.

PASS nghĩa là **không quan sát thấy divergence trên frozen corpus**, không phải
chứng minh formal equivalence.

Reference nondeterminism được kiểm tra lặp trên subset đầu của union theo
`nondeterminism_repeats`. Reference timeout/crash có policy inconclusive riêng,
không tự động được tính là MATCH.

## 11. Terminal statuses

| Status | Ý nghĩa |
|---|---|
| `PASS` | Đạt behavioral validation contract |
| `REPRESENTATION_FAILED` | Lift/brighten/decompile không tạo representation |
| `CONTEXT_OVERFLOW` | Request không fit frozen context, không truncate |
| `LLM_REQUEST_FAILED` | Provider/transport lỗi sau policy retry |
| `LLM_EMPTY_RESPONSE` | Provider không trả usable content |
| `INVALID_CANDIDATE` | Response không thể tạo candidate C |
| `BUILD_FAILED` | Candidate không compile/link |
| `NOT_RUNNABLE` | Candidate timeout/crash/không thực thi được ở smoke contract |
| `BEHAVIOR_MISMATCH` | Có ít nhất một observable mismatch |
| `EVAL_INCONCLUSIVE` | Không đủ confirmed oracle evidence |
| `INFRA_ERROR` | Integrity/tool/runtime contract bị vi phạm |
| `WAITING_FOR_QUOTA` | Nonterminal checkpoint, không phải method failure |
| `CANCELLED` | Internal in-progress/enrolled placeholder |

Mọi terminal failure vẫn nằm trong primary denominator. `WAITING_FOR_QUOTA` và
`CANCELLED` không được aggregate.

## 12. Metrics và thống kê

### 12.1. Primary endpoint

```text
E2E_m = PASS_m / all enrolled programs of method m
```

Primary interval là Wilson score interval ở configured confidence level.

### 12.2. Stage/failure metrics

Report gồm:

- representation success;
- context fit;
- accepted LLM response;
- candidate extraction;
- build success;
- runnable rate;
- exact-behavior PASS;
- confirmed non-equivalence;
- inconclusive rate;
- context-overflow rate;
- infrastructure-failure rate.

Headline rates dùng unconditional enrolled denominator. Conditional rates vẫn
có denominator thực tế trong `metrics_long.csv`.

### 12.3. Resource metrics

- primary representation bytes/tokens;
- total LLM evidence bytes/tokens;
- provider input, response-output, thinking/reasoning, billable-output và total
  tokens;
- accepted model calls;
- API attempts;
- quota throttles và total wait;
- discovery engine, tested/unique inputs và AFL++ coverage counters;
- latency/build/evaluation/total duration;
- optional estimated cost và cost per PASS.

P0 total evidence size tính cả brightened IR và pseudocode, không chỉ primary
IR file.

### 12.4. Paired comparison

Mỗi sample là statistical unit. Report tạo:

- `P0_WIN`, `P0_LOSS`, `TIE_PASS`, `TIE_FAIL`;
- paired risk difference `P0 - comparator`;
- paired bootstrap confidence interval;
- two-sided exact McNemar test;
- Holm adjustment cho hai primary comparisons.

Input-level observations không được giả thành independent samples để phóng đại
statistical significance.

### 12.5. Diễn giải “P0 tốt hơn”

Chỉ kết luận có evidence P0 tốt hơn khi:

1. point estimate `P0 - A0/B0` dương;
2. paired win/loss table ủng hộ cùng hướng;
3. confidence interval được báo đầy đủ;
4. context/infra failure không phải nguyên nhân giả tạo;
5. model freeze và integrity verification pass.

Không được chỉ nhìn bar chart. Không được đổi sample, bỏ context overflow hoặc
rerun riêng A0/B0 cho đến khi kết quả “đẹp”.

## 13. Output contract

Mỗi run nằm tại:

```text
result/experiments/<run_id>/
```

Layout chính:

```text
experiment_manifest.json
config_resolved.json
samples/<sample_id>/
  identity.json
  common/
    raw_lift/
    base_corpus/
    union_inputs/
    union_replay_manifest.json
    reference_outputs/
  P0|A0|B0/
    representation/
    generation/
    build/
    evaluation/
    result.json
aggregate/
  metrics.json
  metrics_long.csv
  variants.csv
  failures.csv
  stage_funnel.csv
  statistics.json
  pairwise_p0_a0.csv
  pairwise_p0_b0.csv
  ir_cfg_metrics.csv
  report.md
  dashboard.html
  figures/
audit/
  events.jsonl
  artifact_manifest.json
integrity_report.json
```

### 13.1. Canonical outputs

- `metrics.json`: canonical metric definitions và summaries;
- `metrics_long.csv`: tidy observations cho R/Python/spreadsheet;
- `variants.csv`: một row trên `(sample, method)`;
- `statistics.json`: paired inference;
- `report.md`: concise generated report;
- `dashboard.html`: print-friendly evidence index;
- `figures_manifest.json`: figure path, source và SHA-256.

### 13.2. Figures

Hệ thống sinh SVG vector:

1. `fig01_e2e_success.svg` — E2E rate và Wilson CI;
2. `fig02_stage_funnel.svg` — unconditional stage retention;
3. `fig03_pairwise_effect.svg` — paired risk difference và CI;
4. `fig04_efficiency.svg` — accepted calls, total evidence tokens, duration;
5. `fig05_ir_reduction.svg` — A0-to-P0 IR structural reduction khi extract được.

SVG là artifact nghiên cứu; dashboard chỉ là index, không thay thế
machine-readable JSON/CSV. Các series trong stage funnel dùng đồng thời màu,
dash pattern và marker size nên vẫn phân biệt được khi nhiều method có giá trị
trùng hoàn toàn.

## 14. Audit và integrity

`audit/events.jsonl` là append-only logical log với:

- monotonic sequence;
- UTC timestamp;
- run/sample/method/stage/status;
- compact payload;
- `previous_event_sha256`;
- current `event_sha256`.

`audit/artifact_manifest.json` seal mọi artifact bằng relative path, byte size và
SHA-256. Integrity verification kiểm tra:

- event hash chain;
- sealed artifact set, missing/extra/mutated file;
- Python/Java source snapshot và từng P0 pass-plugin binary hash;
- result completeness;
- one-shot/five-call rules;
- request hash và prompt-policy drift;
- representation/attachment hashes;
- model freeze parity;
- leakage scan;
- common union/reference hashes;
- candidate immutability;
- quota counters.

Hash chain làm local tampering trở nên detectable nhưng không thay thế external
signed timestamp hoặc write-once storage. Với publication-grade provenance,
copy final manifest hash sang hệ thống độc lập sau khi run hoàn tất.

Primary config đặt `require_clean_git: true`. Vì vậy code/config phải được commit
và worktree sạch trước main data collection. Pilot có thể chạy dirty nhưng
manifest sẽ ghi `git_dirty` và hash của porcelain status.

## 15. Test và validation

Chạy toàn bộ test:

```bash
pytest -q
```

Chỉ test experiment:

```bash
pytest -q tests/experiments src/llm_recovery/tests/test_vertex_endpoint.py
```

Compile-check Python:

```bash
python3 -m compileall -q src tests
```

Trước primary run:

1. test suite pass;
2. pilot fake pass;
3. pilot real một sample pass về integrity, dù candidate có thể semantic fail;
4. rerun cùng pilot bằng resume không gọi lại accepted response;
5. mở `dashboard.html`;
6. parse mọi SVG;
7. chạy `verify-integrity`;
8. commit code/config và bảo đảm clean worktree;
9. dùng run ID mới cho primary.

## 16. Troubleshooting

### Config báo context window bằng 0

Đây là intentional safety gate nếu giá trị bị xóa/đặt lại thành `0`. Re-verify
model card rồi điền context window của exact model version. Không tắt
`no_truncation` và không giảm representation để cứu riêng A0.

### Primary run báo dirty Git

Commit toàn bộ harness, prompt, config và test cần cho experiment; bảo đảm
`git status --short` sạch. Không đổi `require_clean_git` thành false chỉ để chạy
main.

### `WAITING_FOR_QUOTA`

Đọc:

```text
samples/<id>/<method>/generation/quota_state.json
```

Kiểm tra request hash, iteration, `next_retry_at_utc`, attempts và wait budget.
Không xóa checkpoint nếu muốn resume đúng request.

### Aggregate từ chối nonterminal variant

Hoàn tất/resume `generate` và `evaluate` trước. Không sửa `result.json` bằng tay.
Nếu variant đang chờ quota, aggregate từ chối là hành vi đúng.

### Resume báo request hash drift

Representation, pseudocode, prompt hoặc config đã đổi sau checkpoint. Không gửi
request mới dưới run cũ; giữ artifact để audit và bắt đầu run ID mới sau khi xác
định nguyên nhân.

### B0 Ghidra failure

Kiểm tra:

- `paths.ghidra_headless`;
- `ghidra_stdout.log`;
- `ghidra_stderr.log`;
- timeout;
- original ELF hash;
- export script hash trong manifest.

### A0 lift failure

Kiểm tra IDA path, McSema/Remill binaries, raw-lift manifest và `llvm-dis`.
A0 không được fallback sang brightened IR.

### P0 precheck failure

Chỉ P0 nhận failure. A0/B0 vẫn phải tiếp tục. Không dùng precheck output làm
feedback cho A0/B0.

### Integrity seal mismatch

Artifact đã bị thêm, xóa hoặc sửa sau seal, hoặc command trước bị ngắt giữa
chừng. Không dùng report cho nghiên cứu cho đến khi xác định nguyên nhân và
`verify-integrity` pass.

## 17. Threats to validity

- Behavioral testing không phải formal equivalence proof.
- P0 có nhiều call và feedback hơn A0/B0; comparison không cô lập representation.
- Context overflow có thể ảnh hưởng A0 nhiều hơn vì raw IR dài; phải báo riêng.
- Provider alias/model implementation có thể thay đổi nếu không dùng snapshot.
- LLM backend có thể vẫn không deterministic hoàn toàn dù temperature bằng 0.
- Tool versions, CPU load và quota có thể ảnh hưởng latency/cost.
- Ghidra/McSema failure là một phần của end-to-end method reliability nhưng phải
  tách khỏi confirmed semantic non-equivalence.
- Nondeterminism check chỉ lặp trên configured subset, không chứng minh toàn bộ
  program deterministic.
- Input contracts và seed quality giới hạn behavioral coverage.

Các limitation này không phải lý do để bỏ failure khỏi denominator; chúng là lý
do phải đọc stage funnel, failure taxonomy và paired sample table cùng primary
E2E result.

## 18. Research run checklist

- [ ] Dataset/ELF/seed/input-contract đã freeze.
- [ ] Exact model version và context window đã xác minh.
- [ ] Temperature/top-p/candidate count giống nhau giữa methods.
- [ ] Compiler, flags, timeouts và fuzz budgets đã freeze.
- [ ] B0 request chỉ chứa original-ELF pseudocode.
- [ ] A0 request chỉ chứa raw McSema IR.
- [ ] P0 evidence có cả brightened IR và P0 pseudocode.
- [ ] P0 accepted calls không vượt 5.
- [ ] A0/B0 logical generation bằng 1.
- [ ] Không có variant `WAITING_FOR_QUOTA`/`CANCELLED`.
- [ ] Mỗi sample có cùng union corpus hash giữa built methods.
- [ ] Final reference hash là original ELF.
- [ ] Aggregate đủ P0/A0/B0 trên cùng sample set.
- [ ] `verify-integrity` pass.
- [ ] Artifact manifest hash đã lưu ngoài run directory.
- [ ] Report diễn giải đây là end-to-end comparison, không phải
      representation-only causal proof.

## 19. Superseded real-provider run (forensic baseline)

Run `real_three_case_20260724_01` sử dụng Gemini 3.5 Flash thật, đủ budget
primary trên `p00001`, `p00008`, `p00033`. Đây là
`scoped_three_case_full_budget`, không phải primary estimate cho toàn dataset.
Worktree có các deletion tồn tại trước nên dashboard chủ động gắn nhãn
`scoped_research_evidence_dirty_worktree`; manifest vẫn freeze source snapshot
SHA-256 `3436a09c…a07b`, config, dataset, model, tools và mọi artifact.

### 19.1. Primary outcome

| Method | PASS / enrolled | E2E rate | Accepted calls | API attempts | Estimated cost |
|---|---:|---:|---:|---:|---:|
| P0 | 3 / 3 | 100% | 4 | 4 | $1.720773 |
| A0 | 0 / 3 | 0% | 3 | 3 | $2.128091 |
| B0 | 3 / 3 | 100% | 3 | 3 | $0.476201 |

Không có 429 trong run này: quota throttle và quota wait đều bằng zero.
Integrity verifier pass với 39 hash-chained audit events và 3,122 sealed
artifacts.

### 19.2. Kết quả paired theo case

| Case | P0 | A0 | B0 | Ghi chú chính |
|---|---|---|---|---|
| `p00001` | PASS 51/51 | BEHAVIOR_MISMATCH 0/51 | PASS 51/51 | P0 và B0 hòa |
| `p00008` | PASS 94/94 | BUILD_FAILED | PASS 94/94 | A0 hit `MAX_TOKENS` |
| `p00033` | PASS 103/103 | BUILD_FAILED | PASS 103/103 | P0 cần iteration 2; A0 hit `MAX_TOKENS` |

Paired effect:

- P0 − A0: `+100.0` percentage points, observed paired bootstrap interval
  `[+100.0, +100.0]`, exact McNemar `p=0.25`, Holm-adjusted `p=0.50`;
- P0 − B0: `0.0` percentage points, interval `[0.0, 0.0]`,
  exact McNemar `p=1.0`.

Với `n=3`, effect mô tả P0 − A0 rất lớn nhưng chưa đạt statistical
significance; không được dùng interval bootstrap degenerate để thay thế cảnh
báo small-sample. Dữ liệu này **ủng hộ A0 yếu hơn P0**, nhưng **không ủng hộ B0
yếu hơn P0**. B0 đạt cùng 3/3 PASS, ít accepted call hơn và estimated cost thấp
hơn. Không được đổi sample hoặc bỏ B0 PASS để ép giả thuyết mong muốn.

### 19.3. Failure mechanism và giá trị của P0 repair

A0 phải đưa raw IR lớn vào model: median input `182,037` tokens. Hai case dùng
`62,9xx` reasoning tokens và chạm tổng billable output `65,531`, sát output cap
`65,535`; provider trả `MAX_TOKENS`, candidate không build. Case còn lại build
nhưng mismatch toàn bộ common union corpus.

B0 chỉ dùng median `10,491` input tokens và pass cả ba case. P0 dùng evidence
giàu hơn; `p00033` iteration 1 đạt 99/103 internal matches, iteration 2 dùng
feedback sửa thành 101/101 rồi final oracle đạt 103/103. Cơ chế iterative repair
do đó được quan sát hoạt động, dù chưa tạo outcome advantage so với B0 trên
sample nhỏ này.

Machine-readable và visual artifacts:

- `result/experiments/real_three_case_20260724_01/aggregate/metrics.json`;
- `result/experiments/real_three_case_20260724_01/aggregate/variants.csv`;
- `result/experiments/real_three_case_20260724_01/aggregate/dashboard.html`;
- `result/experiments/real_three_case_20260724_01/integrity_report.json`;
- `result/experiments/real_three_case_20260724_01.external_seal.json`;
- `EXPERIMENT_COMPLETION_AUDIT.md`.

Run `_01` is retained for audit only. Its counted-list generator preserved the
leading `N`, so it never exercised valid `p00033` growth probes; its 3/3 P0 and
3/3 B0 result is not the authoritative outcome. Run `_02` added those probes
but used a 0.1s reference timeout, classifying the same probes as inconclusive.

## 20. Corrected authoritative scoped study

Run `real_three_case_20260724_03` is the primary result for this scoped study.
It uses the boundary-aware generator and `per_input_timeout_sec: 2.0`, with the
same full-budget three-case design and real Vertex provider. Integrity passed
with 39 hash-chained events and 3,207 sealed artifacts; no 429 occurred.

| Method | PASS / enrolled | E2E rate | Accepted calls | API attempts | Estimated cost |
|---|---:|---:|---:|---:|---:|
| P0 | 3 / 3 | 100% | 7 | 7 | $3.607287 |
| A0 | 0 / 3 | 0% | 3 | 3 | $2.151878 |
| B0 | 2 / 3 | 66.67% | 3 | 3 | $0.484121 |

P0 exceeds B0 by one paired case descriptively (`+33.33 pp`, paired bootstrap
CI `[0,+100]`, McNemar `p=1`) and exceeds A0 by three cases (`+100 pp`, exact
McNemar `p=0.25`). On `p00033`, B0 has three confirmed crash asymmetries on
`N=8,16,64`; P0 reproduces the same crash and passes. Three P0 boundary probes
are `INCONCLUSIVE_BOTH_CRASH`, below the pre-registered 20% ceiling. These are
small-sample descriptive results, not confirmatory evidence.

Authoritative artifacts:

- `result/experiments/real_three_case_20260724_03/aggregate/metrics.json`;
- `result/experiments/real_three_case_20260724_03/aggregate/dashboard.html`;
- `result/experiments/real_three_case_20260724_03/integrity_report.json`;
- `result/experiments/real_three_case_20260724_03.external_seal.json`;
- `EXPERIMENT_COMPLETION_AUDIT.md`.
