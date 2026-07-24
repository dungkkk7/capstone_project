# ĐẶC TẢ KỸ THUẬT TRIỂN KHAI B0, A0 VÀ HỆ THỐNG EVALUATION CHO PIPELINE P0

**Phiên bản:** 2.1  
**Ngày:** 24/07/2026  
**Trạng thái:** Audited as-built specification / dùng trực tiếp cho coding agent  
**Phạm vi:** Bổ sung hai nhánh thực nghiệm B0, A0 và refactor evaluation để so sánh công bằng với P0 hiện có.

---

## 0. MỤC TIÊU CỦA TÀI LIỆU

Tài liệu này không phải mô tả học thuật chung. Đây là đặc tả kỹ thuật đủ chi tiết để một coding agent có thể:

1. đọc codebase P0 hiện tại;
2. thêm hai configuration thực nghiệm `B0` và `A0`;
3. tách logic sinh C khỏi vòng repair/fuzz hiện tại;
4. xây một evaluator chung cho `P0`, `A0`, `B0`;
5. lưu artifact, metric, failure reason và provenance có thể tái lập;
6. chạy pilot, resume và aggregate kết quả mà không cần suy đoán thêm về protocol.

Tài liệu ưu tiên các nguyên tắc sau:

- cùng sample, requested model/decoding, output requirements, compiler và behavioral oracle;
- khác representation **và generation protocol đã công bố**: P0 iterative tối đa 5 response, A0/B0 one-shot;
- B0/A0 không bị chặn bởi trạng thái của P0;
- không dùng clean source hoặc expected output trong prompt;
- mọi sample đã enrol đều phải có terminal result và nằm trong denominator;
- evaluation cuối cùng luôn so candidate với **original obfuscated ELF**;
- A0/B0 dùng **strict one-shot**; P0 giữ compiler/fuzz-feedback loop hiện tại.

---

## 1. QUYẾT ĐỊNH THỰC NGHIỆM BẮT BUỘC

### 1.1. Ba configuration

| ID | Tên | Representation đưa vào LLM | Vai trò |
|---|---|---|---|
| `B0` | Direct Obfuscated Pseudocode-to-C | Ghidra pseudocode lấy trực tiếp từ original obfuscated ELF | Primary literature-inspired baseline |
| `A0` | Raw Lifted-IR-only | Raw McSema LLVM IR, dừng trước toàn bộ brightening/deobfuscation/optimization | Primary ablation |
| `P0` | Full proposed pipeline | Brightened/simplified LLVM IR + C-like/Ghidra pseudocode từ output của pipeline P0 | Proposed method |

### 1.2. Pipeline chính xác

```text
B0:
original_obfuscated.elf
  -> Ghidra Headless trên chính original ELF
  -> full program-level obfuscated pseudocode
  -> common LLM strict one-shot
  -> candidate C11
  -> common compiler/runtime
  -> common differential evaluator vs original_obfuscated.elf

A0:
original_obfuscated.elf
  -> McSema lifting
  -> raw.bc + raw.ll
  -> KHÔNG custom LLVM pass
  -> KHÔNG standard LLVM optimization
  -> KHÔNG Ghidra pseudocode trong request
  -> common LLM strict one-shot
  -> candidate C11
  -> common compiler/runtime
  -> common differential evaluator vs original_obfuscated.elf

P0:
original_obfuscated.elf
  -> McSema lifting
  -> existing brightening/deobfuscation/optimization pipeline
  -> brightened/simplified IR
  -> C-like/Ghidra pseudocode của P0
  -> existing iterative LLM recovery
  -> compiler/fuzz feedback sau mỗi iteration
  -> dừng sớm khi pass, tối đa đúng 5 iteration
  -> final candidate C11
  -> common compiler/runtime
  -> common differential evaluator vs original_obfuscated.elf
```

### 1.3. Điều không được phép thay đổi ngầm

Coding agent không được tự ý:

- dùng model khác giữa ba method;
- thay đổi ngân sách call đã khóa: P0 tối đa 5, A0/B0 đúng một logical generation;
- cắt representation của một method nhưng không cắt method khác;
- dùng candidate-specific test feedback để regenerate A0/B0;
- thay đổi compiler/fuzz feedback loop hiện tại của P0;
- so B0/A0 với `brightened_ref.bin`;
- chạy Ghidra B0 trên brightened binary;
- đưa `.ll` hoặc `.bc` vào B0 request;
- đưa Ghidra pseudocode vào A0 request;
- loại sample khỏi denominator vì build fail, context overflow hoặc tool fail;
- dùng clean source, expected output, counterexample, semantic report hoặc test output trong LLM request.

---

## 2. HIỆN TRẠNG CODEBASE VÀ VẤN ĐỀ PHẢI REFACTOR

### 2.1. Cấu trúc đã quan sát

```text
src/
  main.py
  binary_lifting/
    lifting.py
  fuzzing_equi_check/
    fuzzing.py
    input_contracts.py
  llm_recovery/
    llm_recovery.py
    PROMPT_FLOW.md
  llvm_pass/
    britening_ir.py
    brighten_010_...
    ...
    brighten_095_ollvm_deobf/

data/
  custom_dataset.csv
  obfuscated/<problem_id>/...
  clean_src/<problem_id>/...
  seeds/<problem_id>/...
  input_contracts/custom_dataset.json
result/
  pipeline_<timestamp>/...
```

### 2.2. Hành vi hiện tại cần tách khỏi main experiment

Log P0 hiện tại cho thấy các đặc điểm sau:

- recovery chạy vòng lặp tối đa 5 iteration;
- candidate được compile và fuzz sau mỗi iteration;
- fuzz result được dùng để accept hoặc tiếp tục repair;
- request P0 có thể chứa đồng thời Ghidra pseudocode và brightened LLVM IR;
- recovery target hiện tại là `brightened_ref.bin`;
- LLM recovery chỉ bắt đầu sau một semantic baseline/precheck pass;
- input fuzz được sinh trong quá trình đánh giá candidate.

Các đặc điểm này được giữ nguyên cho P0-current theo yêu cầu thực nghiệm. Vì
P0 có tối đa 5 vòng kèm feedback còn A0/B0 one-shot, kết quả chính là so sánh
**end-to-end system**, không được diễn giải như causal effect riêng của
representation. Final evaluator, terminal taxonomy và denominator vẫn phải
đồng nhất giữa ba method.

### 2.3. Quyết định refactor

Phải khai báo rõ hai protocol cùng tồn tại trong báo cáo chính:

| Protocol | Mục đích | Số call | Feedback vào LLM | Dùng trong báo cáo chính |
|---|---|---:|---|---|
| `legacy_iterative_repair_max_5` | P0-current | tối đa 5, dừng sớm | compiler/fuzz feedback hiện tại | có |
| `strict_one_shot` | A0 và B0 | đúng 1 logical generation | không | có |

`llm_recovery.py` phải expose API generation-only cho A0/B0. P0 tiếp tục dùng
nguyên vòng compile/fuzz/repair hiện tại qua adapter.

---

## 3. KIẾN TRÚC MỤC TIÊU

![Kiến trúc thực nghiệm](experiment_architecture.png)

Nguyên tắc kiến trúc:

1. `SampleIdentity` được tạo một lần từ dataset row và original ELF.
2. Common corpus được chuẩn bị theo sample, độc lập với method.
3. Mỗi method có `RepresentationBuilder` riêng.
4. Cả ba builder trả về cùng một interface.
5. Generation giữ cùng model family/config đã freeze nhưng protocol theo
   method: P0-current iterative, A0/B0 one-shot.
6. Common `BuildRunner` và `DifferentialEvaluator` xử lý candidate.
7. Sau khi cả ba method chạy, evaluator tạo union input corpus và replay công bằng.
8. Aggregate đọc JSON artifact; không parse log text để tính metric.

### 3.1. Module mới đề xuất

```text
src/experiments/
  __init__.py
  enums.py
  models.py
  config.py
  identity.py
  storage.py
  hashing.py
  leakage.py
  runner.py
  cli.py

  representations/
    __init__.py
    base.py
    b0_ghidra.py
    a0_raw_ir.py
    p0_full.py
    ghidra_export.py
    token_budget.py

  generation/
    __init__.py
    prompt.py
    request_builder.py
    generator.py
    candidate_extract.py

  evaluation/
    __init__.py
    corpus.py
    build.py
    execute.py
    oracle.py
    fuzz_campaign.py
    union_replay.py
    finalize.py

  reporting/
    __init__.py
    aggregate.py
    metrics.py
    paired_stats.py
    export_csv.py
    markdown_report.py

configs/
  experiment_primary.yaml
  experiment_pilot.yaml

tests/
  experiments/
    unit/
    integration/
    fixtures/
```

### 3.2. Adapter thay vì rewrite toàn bộ

Không rewrite các phần đã hoạt động. Tạo adapter:

- `lifting.py` được gọi bởi `A0Builder` và `P0LegacyAdapter`;
- `britening_ir.py` chỉ được gọi bởi `P0LegacyAdapter`;
- logic Ghidra hiện tại được tách thành `ghidra_export.py` để B0 và P0 gọi với target khác nhau;
- `fuzzing.py` được refactor để nhận `precomputed_inputs` và trả structured result;
- API Vertex/Gemini hiện tại được bọc bởi `GenerationClient`.

---

## 4. DOMAIN MODEL VÀ ENUM BẮT BUỘC

### 4.1. Method và protocol

```python
from enum import Enum

class MethodId(str, Enum):
    P0 = "P0"
    A0 = "A0"
    B0 = "B0"

class GenerationProtocol(str, Enum):
    STRICT_ONE_SHOT = "strict_one_shot"
    ITERATIVE_REPAIR = "iterative_repair"
```

### 4.2. Stage

```python
class Stage(str, Enum):
    ENROLLED = "enrolled"
    REPRESENTATION = "representation"
    CONTEXT_CHECK = "context_check"
    GENERATION = "generation"
    CANDIDATE_EXTRACT = "candidate_extract"
    BUILD = "build"
    SMOKE_RUN = "smoke_run"
    FROZEN_REPLAY = "frozen_replay"
    FUZZ_DISCOVERY = "fuzz_discovery"
    UNION_REPLAY = "union_replay"
    FINALIZED = "finalized"
```

### 4.3. Terminal status

```python
class TerminalStatus(str, Enum):
    PASS = "PASS"

    REPRESENTATION_FAILED = "REPRESENTATION_FAILED"
    CONTEXT_OVERFLOW = "CONTEXT_OVERFLOW"
    LLM_REQUEST_FAILED = "LLM_REQUEST_FAILED"
    LLM_EMPTY_RESPONSE = "LLM_EMPTY_RESPONSE"
    INVALID_CANDIDATE = "INVALID_CANDIDATE"
    BUILD_FAILED = "BUILD_FAILED"
    NOT_RUNNABLE = "NOT_RUNNABLE"
    BEHAVIOR_MISMATCH = "BEHAVIOR_MISMATCH"
    EVAL_INCONCLUSIVE = "EVAL_INCONCLUSIVE"
    INFRA_ERROR = "INFRA_ERROR"
    CANCELLED = "CANCELLED"
```

Quy tắc denominator:

- mọi `(sample_id, method)` sau khi `ENROLLED` phải có đúng một `TerminalStatus`;
- chỉ `PASS` được tính là E2E success;
- tất cả status còn lại là 0 trong primary E2E rate;
- `INFRA_ERROR` vẫn nằm trong intention-to-treat denominator, đồng thời báo riêng infra rate.

### 4.4. Dataclass cốt lõi

```python
@dataclass(frozen=True)
class SampleIdentity:
    sample_id: str
    dataset_row_index: int
    original_elf_path: str
    original_elf_sha256: str
    architecture: str
    input_contract_id: str
    seed_manifest_sha256: str
    obfuscation_tags: tuple[str, ...]

@dataclass(frozen=True)
class RepresentationArtifact:
    method: MethodId
    primary_path: str
    primary_sha256: str
    attachment_paths: tuple[str, ...]
    attachment_sha256: tuple[str, ...]
    byte_count: int
    token_count: int
    builder_version: str
    tool_versions: dict[str, str]
    provenance: dict[str, object]

@dataclass(frozen=True)
class GenerationRequest:
    method: MethodId
    protocol: GenerationProtocol
    model_id: str
    system_prompt: str
    user_prompt: str
    prompt_sha256: str
    representation_sha256: str
    input_token_count: int
    max_output_tokens: int
    decoding: dict[str, object]
    attachment_manifest: tuple[dict[str, str], ...]

@dataclass
class BuildResult:
    ok: bool
    command: list[str]
    compiler_version: str
    return_code: int | None
    stdout_path: str
    stderr_path: str
    executable_path: str | None
    executable_sha256: str | None
    duration_ms: int

@dataclass
class ExecutionOutcome:
    input_sha256: str
    timed_out: bool
    return_code: int | None
    signal: int | None
    stdout_path: str
    stdout_sha256: str
    stderr_path: str
    stderr_sha256: str
    duration_ms: int

@dataclass
class VariantResult:
    sample_id: str
    method: MethodId
    terminal_status: TerminalStatus
    final_stage: Stage
    e2e_pass: bool
    failure_code: str | None
    failure_message: str | None
    representation: dict | None
    generation: dict | None
    build: dict | None
    evaluation: dict | None
    timing: dict[str, int]
    provenance: dict[str, object]
```

---

## 5. ĐẶC TẢ B0 — DIRECT OBFUSCATED PSEUDOCODE-TO-C

## 5.1. Mục tiêu causal/comparative

B0 kiểm tra giả thuyết cạnh tranh:

> Có cần explicit lifting + IR deobfuscation trước LLM hay một general/code LLM có thể tự deobfuscate và reconstruct C trực tiếp từ decompiler pseudocode của obfuscated binary?

B0 phải giữ LLM, output target, compiler và evaluator giống P0; khác biệt chính là representation.

## 5.2. Input contract của B0

**Input duy nhất để tạo representation:** original obfuscated ELF của sample.

Không được dùng:

- raw McSema IR;
- brightened IR;
- `.bc`;
- `brightened_ref.bin`;
- clean source;
- expected output;
- P0 semantic report;
- counterexample;
- manually cleaned pseudocode.

## 5.3. Luồng B0 chi tiết

```text
1. Read dataset row.
2. Resolve original obfuscated ELF.
3. Verify SHA-256 equals SampleIdentity.original_elf_sha256.
4. Run Ghidra Headless against original ELF.
5. Export program-level pseudocode deterministically.
6. Build representation manifest and content hash.
7. Run leakage scan.
8. Count prompt tokens; do not truncate.
9. If overflow -> CONTEXT_OVERFLOW.
10. Call common LLM exactly once.
11. Save raw response and deterministically extract candidate C.
12. Compile with common build command.
13. Evaluate against original ELF using common corpus/oracle.
14. Persist VariantResult.
```

## 5.4. Ghidra target bắt buộc

```python
assert ghidra_target_path == sample.original_elf_path
assert sha256(ghidra_target_path) == sample.original_elf_sha256
assert "_brightened" not in ghidra_target_path
assert "_ref.bin" not in ghidra_target_path
```

Nếu assertion fail, B0 phải dừng với `INFRA_ERROR/B0_WRONG_DECOMPILE_TARGET`, không fallback.

## 5.5. Scope pseudocode program-level

B0 exporter phải tạo một file duy nhất, ví dụ:

```text
B0/representation/ghidra_original_program.c
```

Nội dung gồm:

1. metadata tối thiểu không tiết lộ method label;
2. recovered type declarations nếu Ghidra có;
3. global variables/constants có liên quan;
4. strings/data references cần thiết;
5. `main` hoặc function tương đương entry-to-main;
6. mọi user-defined function reachable từ `main`;
7. function được sắp theo địa chỉ entry tăng dần;
8. mỗi function có signature và decompiler body nguyên trạng;
9. không bỏ dispatcher, bogus block hoặc MBA expression bằng tay.

### 5.5.1. Runtime/library filtering

Chỉ được loại bằng rule deterministic đã công bố, ví dụ:

- imported external functions chỉ giữ prototype, không decompile body;
- PLT/thunk chỉ giữ declaration;
- known compiler/runtime startup stubs có thể loại khỏi body nếu exporter ghi rõ danh sách rule;
- function reachable nhưng chưa decompile được phải ghi placeholder **trong representation** theo dạng lỗi Ghidra gốc, không tự viết logic thay thế.

Rule không được tham chiếu clean source.

### 5.5.2. Không cho phép manual cleanup

Không được:

- rename variable bằng source;
- sửa type;
- thay pointer arithmetic;
- fold constant;
- remove opaque predicate;
- simplify state machine;
- chọn một subset “dễ” của function;
- xóa code vì nhìn giống obfuscation.

## 5.6. Determinism và cache B0

Cache key:

```text
sha256(
  original_elf_sha256
  + ghidra_version
  + ghidra_script_sha256
  + exporter_config_sha256
  + builder_version
)
```

B0 cache không được dùng chung key với P0 Ghidra output.

Manifest tối thiểu:

```json
{
  "method": "B0",
  "source_kind": "original_obfuscated_elf",
  "source_path": "...elf",
  "source_sha256": "...",
  "ghidra_version": "12.0.4_PUBLIC",
  "script_sha256": "...",
  "function_count": 17,
  "reachable_function_count": 15,
  "failed_decompilations": 0,
  "representation_path": "ghidra_original_program.c",
  "representation_sha256": "...",
  "bytes": 123456,
  "tokens": 45678
}
```

## 5.7. B0 prompt

System prompt phải dùng chung với A0; P0 giữ prompt legacy. User prompt B0:

```text
Representation type: decompiler-generated pseudocode from an OLLVM-obfuscated binary.
<OBFUSCATED_PSEUDOCODE>
{GHIDRA_PSEUDOCODE}
</OBFUSCATED_PSEUDOCODE>
```

Không thêm chữ `baseline`, `B0` hoặc câu gợi ý rằng đây là method yếu hơn.

## 5.8. B0 failure codes

| Failure code | Terminal status | Ý nghĩa |
|---|---|---|
| `B0_ELF_NOT_FOUND` | `REPRESENTATION_FAILED` | Không thấy original ELF |
| `B0_ELF_HASH_MISMATCH` | `INFRA_ERROR` | File thay đổi sau enrol |
| `B0_GHIDRA_FAILED` | `REPRESENTATION_FAILED` | Ghidra exit non-zero/timeout |
| `B0_NO_PROGRAM_PSEUDOCODE` | `REPRESENTATION_FAILED` | Export rỗng hoặc không có function |
| `B0_WRONG_DECOMPILE_TARGET` | `INFRA_ERROR` | Target không phải original ELF |
| `B0_FORBIDDEN_ARTIFACT_IN_REQUEST` | `INFRA_ERROR` | Request chứa IR/brightened/source leak |
| `B0_CONTEXT_OVERFLOW` | `CONTEXT_OVERFLOW` | Input không fit context, không truncate |

## 5.9. Acceptance tests riêng cho B0

```text
B0-AC-01: target path đúng original ELF và hash đúng identity.
B0-AC-02: request attachment list chỉ có B0 pseudocode/manifest được phép.
B0-AC-03: request body không chứa '.ll', '.bc', '_brightened', 'clean_src', 'expected_output'.
B0-AC-04: Ghidra output order ổn định giữa hai run cùng config.
B0-AC-05: thay đổi thứ tự chạy P0/A0/B0 không làm đổi B0 request_sha256.
B0-AC-06: P0 fail brightening không ngăn B0 chạy.
B0-AC-07: strict mode có model_call_count == 1.
```

---

## 6. ĐẶC TẢ A0 — RAW LIFTED-IR-ONLY ABLATION

## 6.1. Mục tiêu comparative

A0 loại bỏ toàn bộ post-lifting enhancement block để đo đóng góp của:

- custom deobfuscation passes;
- state/stack/ABI/type/global recovery passes;
- standard LLVM optimization sequence;
- C-like/Ghidra pseudocode bổ sung.

So sánh `P0 - A0` giữ model/decoding, compiler và evaluator cố định nhưng
không cô lập riêng effect của block trên, vì P0 iterative tối đa 5 response còn
A0 one-shot. IR/CFG reduction được dùng làm structural diagnosis; kết quả chính
vẫn là end-to-end method comparison.

## 6.2. Input contract của A0

**Input ban đầu:** original obfuscated ELF.  
**Representation duy nhất:** raw McSema LLVM IR sinh trực tiếp sau lifting.

A0 được phép dùng:

- disassembler/lifter version và flags giống P0;
- lifting cache nếu provenance/hash trùng tuyệt đối;
- raw `.bc`;
- raw `.ll` được tạo bằng `llvm-dis` từ raw `.bc`.

A0 không được dùng:

- bất kỳ `brighten-*` pass nào;
- `opt -O*`;
- `instcombine`, `simplifycfg`, `sroa`, `mem2reg`, `gvn`, `dce`, `adce`, `jump-threading` hoặc pass khác;
- textual regex cleanup làm thay đổi instruction;
- Ghidra pseudocode;
- P0 native contract report trong prompt;
- clean source/expected output/counterexample.

## 6.3. Luồng A0 chi tiết

```text
1. Read SampleIdentity and original ELF.
2. Call McSema lifting using the exact P0 lifting toolchain/version/flags.
3. Capture raw .bc before any P0 pass.
4. Produce raw .ll using llvm-dis only.
5. Verify no optimization/deobfuscation command was executed for A0.
6. Build representation manifest and hashes.
7. Run leakage/contamination scan.
8. Count prompt tokens; no truncation.
9. Call common LLM exactly once.
10. Compile candidate C with common compiler.
11. Evaluate candidate against original ELF.
12. Persist result.
```

## 6.4. Điểm cắt chính xác trong pipeline

A0 artifact phải được lấy tại vị trí:

```text
McSema successful output
  -> raw.bc
  -> llvm-dis raw.bc -> raw.ll
  -> STOP
```

Không được lấy `s092..._brightened.ll` rồi gọi nó là raw IR.

Assertion mẫu:

```python
assert raw_ll_path.name.endswith(".ll")
assert "brightened" not in raw_ll_path.name
assert "simplified" not in raw_ll_path.name
assert representation_manifest["pass_pipeline"] == []
assert representation_manifest["optimization_level"] == "none"
```

## 6.5. Canonicalization được phép

Để giữ đúng nghĩa raw IR, chỉ cho phép:

- line ending thành `\n`;
- UTF-8 encoding;
- đảm bảo file kết thúc bằng newline;
- wrapper tag trong prompt;
- copy file vào experiment directory.

Không cho phép:

- xóa metadata;
- đổi tên SSA variable;
- sort function;
- remove comments;
- strip attributes;
- rewrite target triple/data layout;
- run `llvm-as`/`llvm-dis` nhiều vòng để canonicalize nếu làm đổi text ngoài quy trình chuẩn.

`raw.ll` hash phải được tính sau đúng một lần `llvm-dis` theo version đã ghi trong manifest.

## 6.6. Lifting cache và provenance

A0 có thể reuse raw lift cache của P0 nếu và chỉ nếu:

```text
original_elf_sha256 giống nhau
McSema version giống nhau
Remill version giống nhau
disassembler version giống nhau
architecture giống nhau
lifting flags giống nhau
entrypoint/config giống nhau
raw.bc sha256 đã được cache manifest xác nhận
```

Nếu thiếu manifest provenance, không reuse cache trong experiment chính.

A0 manifest:

```json
{
  "method": "A0",
  "source_kind": "original_obfuscated_elf",
  "source_sha256": "...",
  "lifter": "mcsema",
  "mcsema_version": "...",
  "remill_version": "...",
  "disassembler": "ida-9.3",
  "lifting_flags": ["..."],
  "raw_bc_path": "raw.bc",
  "raw_bc_sha256": "...",
  "raw_ll_path": "raw.ll",
  "raw_ll_sha256": "...",
  "pass_pipeline": [],
  "optimization_level": "none",
  "bytes": 923456,
  "tokens": 231456
}
```

## 6.7. A0 prompt

```text
Representation type: raw LLVM IR lifted from an OLLVM-obfuscated binary by McSema.
No custom deobfuscation, control-flow recovery, type recovery, cleanup, or LLVM optimization has been applied.
Recover one complete Linux-compilable C11 source file that preserves the observable behavior of the represented program.

<RAW_LIFTED_LLVM_IR>
{RAW_LLVM_IR}
</RAW_LIFTED_LLVM_IR>
```

Không attach file Ghidra hoặc P0 report.

## 6.8. A0 context overflow

Raw IR có thể dài hơn P0. Không được truncate để “cứu” A0 vì truncation làm thay đổi task contract.

Quy tắc:

```text
required = system_tokens + user_template_tokens + representation_tokens
           + max_output_tokens + safety_margin_tokens

if required > model_context_window:
    terminal_status = CONTEXT_OVERFLOW
    model_call_count = 0
```

Phải lưu:

- representation byte count;
- exact token count hoặc provider count;
- context window;
- reserved output tokens;
- overflow amount.

## 6.9. A0 failure codes

| Failure code | Terminal status | Ý nghĩa |
|---|---|---|
| `A0_LIFT_FAILED` | `REPRESENTATION_FAILED` | McSema không tạo raw `.bc` |
| `A0_RAW_BC_MISSING` | `REPRESENTATION_FAILED` | Lift báo success nhưng artifact thiếu |
| `A0_LLVM_DIS_FAILED` | `REPRESENTATION_FAILED` | Không tạo được raw `.ll` |
| `A0_NON_RAW_ARTIFACT` | `INFRA_ERROR` | Artifact có dấu hiệu brightened/optimized |
| `A0_FORBIDDEN_PASS_EXECUTED` | `INFRA_ERROR` | Command trace có pass không được phép |
| `A0_FORBIDDEN_GHIDRA_ATTACHMENT` | `INFRA_ERROR` | Request chứa pseudocode |
| `A0_CONTEXT_OVERFLOW` | `CONTEXT_OVERFLOW` | Raw IR không fit context |

## 6.10. Acceptance tests riêng cho A0

```text
A0-AC-01: raw_ll_sha256 đúng file sinh trực tiếp từ raw_bc bằng llvm-dis.
A0-AC-02: pass_pipeline rỗng.
A0-AC-03: command trace không chứa opt/brighten/custom pass.
A0-AC-04: request không chứa Ghidra pseudocode.
A0-AC-05: P0 brightening fail không ngăn A0 hoàn thành raw lift/generation.
A0-AC-06: cùng raw cache provenance cho cùng binary tạo cùng representation hash.
A0-AC-07: strict mode có đúng một model call nếu context fit.
```

---

## 7. CHUẨN HÓA P0 ĐỂ SO SÁNH CÔNG BẰNG

Tài liệu này không thay đổi thuật toán P0, nhưng P0 phải chạy qua cùng experiment harness.

## 7.1. P0 representation

P0 builder dùng:

- raw lift từ McSema;
- existing custom brighten/deobfuscation passes;
- existing standard optimization sequence;
- brightened/simplified `.ll`;
- C-like/Ghidra pseudocode theo pipeline hiện tại.

Nếu P0 hiện decompile `brightened_ref.bin`, giữ hành vi đó và ghi rõ provenance. Không dùng original ELF pseudocode như B0.

## 7.2. P0-current iterative generation

P0 phải giữ nguyên hành vi hiện tại:

- dùng đầy đủ brightened IR và pseudocode của pipeline P0;
- compile candidate sau mỗi iteration;
- dùng compiler/fuzz feedback cho iteration kế tiếp;
- dừng sớm khi candidate pass;
- tối đa 5 iteration/model response;
- không inject semantic precheck output;
- không inject expected outputs.

Không được chuyển P0 sang one-shot vì điều đó tạo một method khác P0-current.

## 7.3. P0 precheck không được gate B0/A0

P0 có thể chạy các supporting checks:

- native contract status;
- brightened IR compile status;
- brightened-vs-original semantic precheck.

Nhưng orchestration phải theo rule:

```python
p0_result = run_p0_independently()
a0_result = run_a0_independently()
b0_result = run_b0_independently()
```

Không được:

```python
if p0_semantic_pass:
    run_all_methods()
```

Nếu P0 thiếu artifact bắt buộc, chỉ P0 có `REPRESENTATION_FAILED`.

## 7.4. Final oracle P0

Candidate P0 phải so trực tiếp với:

```text
SampleIdentity.original_elf_path
```

Không dùng `brightened_ref.bin` làm final oracle. `brightened_ref.bin` chỉ là intermediate artifact của P0.

---

## 8. A0/B0 ONE-SHOT GENERATION VÀ P0-CURRENT PROTOCOL

## 8.1. System prompt one-shot dùng chung cho A0/B0

```text
You are a highly skilled reverse engineer specializing in binary deobfuscation and C reconstruction.
Recover exactly one complete Linux-compilable C11 source file that preserves the observable behavior represented by the supplied low-level program representation.

Requirements:
1. Include main and every required user-defined function.
2. Include required standard headers, declarations, globals, constants, and helpers.
3. Simplify obfuscation artifacts only when justified by the input.
4. Do not omit behavior, use placeholders, or hard-code known test outputs.
5. Return C source only, without Markdown fences or explanations.
```

System prompt text và SHA-256 phải giống hệt giữa A0/B0. P0 tái sử dụng prompt
và feedback construction của pipeline hiện tại; provenance phải ghi rõ đây là
protocol khác.

## 8.2. Model freeze

Config phải freeze:

```yaml
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
  pricing_plan: standard_paygo_global
  pricing_usd_per_million_input_tokens: 1.25
  pricing_usd_per_million_output_tokens: 10.00
  pricing_long_context_threshold_tokens: 200000
  pricing_usd_per_million_input_tokens_long_context: 2.50
  pricing_usd_per_million_output_tokens_long_context: 15.00
  pricing_source: https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing
  pricing_verified_date: "2026-07-24"
```

Không dùng alias tự động trỏ sang model version mới nếu provider hỗ trợ snapshot/version. Phải lưu model response metadata.

## 8.3. Strict one-shot invariant của A0/B0

```python
assert protocol == "strict_one_shot"
assert max_model_calls == 1
assert compiler_feedback_enabled is False
assert test_feedback_enabled is False
assert fuzz_feedback_enabled is False
assert regenerate_on_failure is False
```

Nếu LLM API retry do network/transient error:

- retry transport được phép tối đa cấu hình;
- retry phải gửi cùng request bytes/idempotency key;
- transport retry không được thay prompt hoặc dùng feedback;
- `api_attempt_count` ghi mọi attempted API call;
- `model_call_count` chỉ tăng khi provider trả một model response;
- `logical_generation_count` phải bằng 1.

## 8.4. Candidate extraction one-shot

Không semantic-repair output. Áp dụng deterministic extraction giống nhau cho
A0/B0. P0 giữ extraction hiện tại trong legacy recovery loop:

1. lưu nguyên response thành `candidate_raw.txt`;
2. normalize line ending;
3. nếu response chỉ gồm đúng một Markdown code fence và whitespace ngoài fence, unwrap fence;
4. nếu có prose ngoài fence, không tự đoán; lưu raw thành candidate và để compiler quyết định hoặc đánh `INVALID_CANDIDATE` theo config;
5. không thêm header;
6. không thêm `main`;
7. không sửa syntax;
8. không chạy clang-format trước build;
9. lưu `candidate.c` và SHA-256.

## 8.5. Request manifest và leakage scan

Trước khi call model, tạo:

```json
{
  "sample_id": "p00001",
  "method": "B0",
  "protocol": "strict_one_shot",
  "model_id": "gemini-2.5-pro",
  "system_prompt_sha256": "...",
  "user_prompt_sha256": "...",
  "request_sha256": "...",
  "representation_sha256": "...",
  "attachments": [
    {"path": "...", "sha256": "...", "role": "program_representation"}
  ],
  "forbidden_scan": {
    "passed": true,
    "matches": []
  }
}
```

Forbidden roots/patterns mặc định:

```text
data/clean_src
/data/clean_src/
expected_output
semantic_report
counterexample
mismatch_input
recovered_iter
brightened_ref.bin   # forbidden cho B0/A0 request
_brightened.ll       # forbidden cho B0/A0 request
raw.ll               # forbidden cho B0 request
Ghidra                # attachment role forbidden cho A0
```

Scanner phải kiểm tra cả attachment path, attachment bytes nếu text, system prompt và user prompt.

---

## 9. HỆ THỐNG EVALUATION CHUNG

## 9.1. Mục tiêu

Evaluator trả lời:

> Candidate C có build được, chạy được và không xuất hiện behavioral divergence so với original obfuscated ELF trên tập input đã kiểm thử hay không?

`PASS` chỉ có nghĩa **no observed divergence in tested input space**, không phải formal equivalence.

## 9.2. Tách evaluation khỏi generation

Generation hoàn tất trước khi candidate thấy bất kỳ test result nào.

```text
representation -> one LLM call -> immutable candidate.c
                                      |
                                      v
                             compile/evaluate only
```

Candidate SHA-256 phải được khóa trước evaluation. Nếu file đổi sau evaluation bắt đầu, result invalid với `INFRA_ERROR/CANDIDATE_MUTATED`.

## 9.3. Common compiler contract

Tất cả candidate dùng cùng command template, ví dụ:

```yaml
build:
  compiler: /usr/bin/clang-21
  language: c11
  flags:
    - -std=c11
    - -O0
    - -fno-strict-aliasing
    - -fwrapv
    - -Wno-everything
  link_flags: []
  timeout_sec: 60
```

Coding agent phải lấy compiler/flags thực tế từ config, không hardcode trong builder.

Phải lưu:

- command array;
- compiler path/version;
- stdout/stderr;
- return code;
- duration;
- executable hash.

`BUILD_FAILED` là terminal E2E fail nhưng vẫn giữ candidate artifact.

## 9.4. Observable behavior contract

Mỗi execution được biểu diễn bởi tuple:

```text
O = (
  timeout_class,
  termination_class,
  exit_code_or_signal,
  stdout_bytes,
  stderr_bytes
)
```

Default comparison:

```yaml
evaluation:
  compare_stdout: exact_bytes
  compare_stderr: exact_bytes
  compare_exit_status: true
  normalize_line_endings: false
  ignore_trailing_whitespace: false
  environment:
    LC_ALL: C
    LANG: C
    TZ: UTC
  working_directory_policy: isolated_temp_dir
```

Không normalize output nếu chưa được protocol phê duyệt. Nếu project hiện chỉ coi stdout là observable, điều đó phải là config explicit và giống cho cả ba method.

## 9.5. Phân loại một input

### 9.5.1. Reference hoàn tất, candidate hoàn tất

- exact tuple match -> `MATCH`;
- khác exit code/signal/stdout/stderr -> `MISMATCH`.

### 9.5.2. Reference hoàn tất, candidate timeout

`MISMATCH_TIMEOUT_ASYMMETRY`.

### 9.5.3. Reference hoàn tất, candidate crash

`MISMATCH_CRASH_ASYMMETRY`.

### 9.5.4. Reference timeout

Input không cung cấp oracle hữu ích. Mặc định:

- candidate cũng timeout -> `INCONCLUSIVE_BOTH_TIMEOUT`;
- candidate hoàn tất/crash -> `INCONCLUSIVE_REFERENCE_TIMEOUT`.

Không tính cả hai timeout là semantic match trong primary metric.

### 9.5.5. Reference crash

Mặc định:

- candidate không cùng behavior -> mismatch asymmetry;
- cả hai crash cùng signal/output -> `INCONCLUSIVE_BOTH_CRASH`, trừ khi input contract định nghĩa crash là expected behavior.

## 9.6. Input corpus công bằng

### 9.6.1. Vấn đề của candidate-specific fuzzing

Nếu AFL++ instrument candidate và sinh input riêng cho từng method, ba method nhận test set khác nhau. Coverage và discovered paths cũng phụ thuộc candidate. Vì vậy không được lấy riêng result của từng fuzz campaign làm final comparison.

### 9.6.2. Thiết kế hai pha

**Pha A — Frozen common corpus**

Chuẩn bị trước hoặc độc lập với method:

```text
C_base = seed inputs
       ∪ deterministic contract supplements
       ∪ boundary cases
       ∪ previously frozen regression counterexamples (nếu pre-registered)
```

**Pha B — Discovery + union replay**

Mỗi runnable candidate có thể chạy fuzz campaign cùng budget để tìm thêm input:

```text
D_P0, D_A0, D_B0
```

Sau đó tạo:

```text
C_union = dedup(C_base ∪ D_P0 ∪ D_A0 ∪ D_B0)
```

Cuối cùng replay **chính C_union** trên:

- original obfuscated ELF;
- candidate P0;
- candidate A0;
- candidate B0.

Final behavioral status phải dựa trên union replay, không dựa riêng campaign của method.

### 9.6.3. Lợi ích

- input nào một method khám phá cũng được dùng để kiểm tra tất cả method;
- giữ cùng oracle và cùng bytes;
- tránh lợi thế do candidate sinh ít/many paths;
- vẫn tận dụng AFL++ như counterexample finder;
- replay có thể tái lập vì tất cả bytes được lưu.

## 9.7. Tạo frozen corpus

Config tham chiếu hành vi hiện tại:

```yaml
corpus:
  include_seed_files: true
  deterministic_supplement_count: 50
  fuzz_discovery_target_count: 50
  generator_seed: 4912026
  reject_malformed_by_input_contract: true
  deduplicate_by_sha256: true
  stable_sort: category_then_sha256
```

`input_contracts.py` được dùng ở evaluator, không được đưa nội dung source/expected output vào prompt.

Mỗi input artifact:

```json
{
  "input_id": "contract_00017",
  "category": "contract_supplement",
  "path": "inputs/contract_00017.bin",
  "sha256": "...",
  "size": 12,
  "contract_valid": true,
  "origin_method": null
}
```

Fuzz discovery input có `origin_method`, nhưng sau union replay không còn thuộc riêng method.

## 9.8. Reference output cache

Original ELF được chạy một lần cho mỗi input trong `C_union` và lưu:

```text
samples/<id>/common/reference_outputs/<input_sha256>.json
samples/<id>/common/reference_outputs/<input_sha256>.stdout
samples/<id>/common/reference_outputs/<input_sha256>.stderr
```

Cache key gồm:

```text
original_elf_sha256 + input_sha256 + timeout + env_hash + runner_version
```

## 9.9. Minimum evidence và inconclusive

Config:

```yaml
evaluation:
  per_input_timeout_sec: 0.1
  min_confirmed_inputs: 50
  max_reference_inconclusive_fraction: 0.20
  same_timeout_policy: inconclusive
  same_crash_policy: inconclusive
```

Final sample classification:

```text
if build failed:
    BUILD_FAILED
elif candidate not runnable on smoke set:
    NOT_RUNNABLE
elif any confirmed mismatch in C_union:
    BEHAVIOR_MISMATCH
elif confirmed_input_count < min_confirmed_inputs:
    EVAL_INCONCLUSIVE
elif reference_inconclusive_fraction > threshold:
    EVAL_INCONCLUSIVE
else:
    PASS
```

## 9.10. Smoke run

Trước fuzz/replay đầy đủ:

- chạy candidate và reference trên seed đầu tiên hoặc minimal valid input;
- mục tiêu chỉ phát hiện executable không start, missing loader, immediate crash;
- smoke fail không dùng feedback cho LLM;
- nếu candidate crash nhưng reference không crash -> `NOT_RUNNABLE` hoặc `BEHAVIOR_MISMATCH` theo stage policy;
- tất cả stdout/stderr phải lưu.

## 9.11. Nondeterminism check

Một subset input được chạy lặp `nondeterminism_repeats`, mặc định 3.

Nếu original ELF cho output khác nhau trên cùng input và environment:

- mark sample/input `REFERENCE_NONDETERMINISTIC`;
- input đó không tính confirmed;
- nếu vượt threshold -> `EVAL_INCONCLUSIVE`.

Nếu candidate nondeterministic còn reference deterministic:

- `BEHAVIOR_MISMATCH/CANDIDATE_NONDETERMINISTIC`.

## 9.12. Fuzz campaign

Config:

```yaml
fuzz:
  enabled: true
  engine: aflplusplus
  seconds_per_method: 60
  per_execution_timeout_sec: 0.1
  fixed_seed: 4912026
  max_saved_unique_inputs: 5000
  contract_filter: true
```

Fuzz coverage, exec/s, bitmap và paths chỉ là supporting metrics. Không dùng coverage cao để kết luận semantic correctness.

## 9.13. Không sử dụng test leakage

Các file sau chỉ được evaluator đọc sau candidate freeze:

- seeds;
- input contracts;
- expected outputs nếu project dùng làm supplementary oracle;
- reference execution outputs;
- mismatch inputs;
- fuzz queue.

Generation process không được có path hoặc handle tới các file này, ngoại trừ generic sample ID và representation.

---

## 10. METRIC — ĐỊNH NGHĨA VÀ CÁCH TÍNH

## 10.1. Ký hiệu

Với method `m ∈ {P0, A0, B0}`:

- `N_m`: tổng số variant đã enrol cho method `m`;
- `I(condition)`: 1 nếu condition đúng, ngược lại 0;
- mỗi sample chỉ có một terminal result cho mỗi method.

Vì ba method chạy trên cùng dataset, bình thường:

```text
N_P0 = N_A0 = N_B0 = N
```

Nếu runner không tạo result cho một method, aggregate phải coi đó là lỗi integrity, không âm thầm giảm denominator.

## 10.2. Primary metric: End-to-End Validated Recovery Rate

```text
E2E_m = (Σ_i I(status_i,m == PASS)) / N_m × 100%
```

`PASS` yêu cầu:

1. representation thành công;
2. context fit;
3. LLM trả candidate;
4. candidate compile/link thành executable;
5. executable chạy được;
6. không có confirmed divergence trên common union corpus;
7. đủ số input confirmed;
8. không vi phạm protocol integrity.

Denominator là toàn bộ input được giao cho method, không chỉ candidate build được.

## 10.3. Stage-level funnel

Cho mỗi stage, báo cả **unconditional rate** và **conditional transition rate**.

### 10.3.1. Representation Success Rate

```text
RepSuccess_m = n(representation_ok) / N_m
```

### 10.3.2. Context Fit Rate

```text
ContextFit_uncond_m = n(context_fit) / N_m
ContextFit_cond_m   = n(context_fit) / n(representation_ok)
```

### 10.3.3. LLM Response Rate

```text
LLMResponse_uncond_m = n(valid_api_response) / N_m
LLMResponse_cond_m   = n(valid_api_response) / n(context_fit)
```

### 10.3.4. Candidate C Extraction Rate

```text
CGeneration_uncond_m = n(candidate_c_saved) / N_m
CGeneration_cond_m   = n(candidate_c_saved) / n(valid_api_response)
```

### 10.3.5. Unconditional Build Success Rate

```text
BuildSuccess_m = n(build_ok) / N_m
```

Không dùng denominator là số generated candidate trong headline table; conditional build rate có thể báo phụ:

```text
BuildSuccess_cond_m = n(build_ok) / n(candidate_c_saved)
```

### 10.3.6. Runnable Rate

```text
Runnable_m = n(smoke_run_ok) / N_m
```

### 10.3.7. Behavioral Validation Pass Rate

```text
BehaviorPass_m = n(PASS) / N_m
```

Về số học bằng primary E2E nếu PASS chỉ được gán sau full chain.

## 10.4. Failure metrics

### 10.4.1. Confirmed Non-equivalence Rate

```text
ConfirmedNonEq_uncond_m = n(BEHAVIOR_MISMATCH) / N_m
ConfirmedNonEq_cond_m   = n(BEHAVIOR_MISMATCH) / n(runnable)
```

### 10.4.2. Inconclusive Rate

```text
Inconclusive_m = n(EVAL_INCONCLUSIVE) / N_m
```

### 10.4.3. Context Overflow Rate

```text
ContextOverflow_m = n(CONTEXT_OVERFLOW) / N_m
```

A0 có thể có rate cao hơn do raw IR dài; đây là kết quả thực nghiệm, không được loại khỏi denominator.

### 10.4.4. Infrastructure Failure Rate

```text
InfraFailure_m = n(INFRA_ERROR) / N_m
```

Phải báo riêng vì infra failure không phải quality của method, nhưng primary intention-to-treat vẫn tính là non-pass.

## 10.5. Behavioral metrics ở input level

Với runnable candidate:

```text
ConfirmedInputRate = confirmed_inputs / total_union_inputs
MismatchInputRate  = mismatch_inputs / confirmed_inputs
TimeoutAsymmetryRate = candidate_only_timeouts / confirmed_inputs
CrashAsymmetryRate = candidate_only_crashes / confirmed_inputs
```

Không aggregate hàng triệu input như độc lập về mặt thống kê để tuyên bố significance; statistical unit chính là program/sample.

## 10.6. Representation metrics

Cho từng method:

- representation bytes;
- representation line count;
- estimated/provider token count;
- prompt input tokens;
- context utilization:

```text
ContextUtilization = input_tokens / context_window_tokens
```

- number of functions;
- number of globals nếu exporter có;
- count of decompiler failures;
- A0 raw instruction/basic-block/function count;
- P0 simplified instruction/basic-block/function count.

## 10.7. IR/CFG simplification metrics

Chỉ là supporting evidence, không phải semantic metric.

Với A0 raw IR và P0 enhanced IR:

```text
InstructionReduction = (inst_A0 - inst_P0) / inst_A0
BasicBlockReduction  = (bb_A0 - bb_P0) / bb_A0
CFGEdgeReduction     = (edge_A0 - edge_P0) / edge_A0
FunctionCountChange  = func_P0 - func_A0
```

Cần parser LLVM thống nhất. Nếu metric không extract được, ghi null, không đoán.

## 10.8. Token, latency và cost

Mỗi variant lưu:

- logical generation count;
- accepted model call count;
- API attempt count, gồm cả request bị 429;
- quota throttle count và quota wait duration;
- input tokens;
- response output tokens;
- thinking/reasoning tokens;
- billable output tokens = response output + thinking/reasoning;
- total tokens;
- model latency;
- representation build time;
- compile time;
- evaluation time;
- total wall-clock;
- estimated cost theo pricing table đã freeze trong config; fake-LLM run luôn
  để cost `null`.

Aggregate bằng:

- median;
- IQR;
- min/max;
- tổng cost;
- cost per E2E PASS.

```text
CostPerPass_m = total_cost_m / n(PASS_m)
```

Nếu `n(PASS)=0`, báo `undefined`, không chia 0.

Rate-limit rejection không được tính như một generation:

```text
api_attempt_count >= model_call_count
model_call_count == logical_generation_count
P0 model_call_count <= 5
A0/B0 model_call_count == 1
```

Ví dụ P0 nhận đủ 5 response nhưng có 2 lần HTTP 429:

```text
logical_generation_count = 5
model_call_count = 5
api_attempt_count = 7
quota_throttle_count = 2
```

## 10.9. Coverage/fuzzer metrics

Báo phụ:

- AFL bitmap coverage;
- execs/s;
- unique generated inputs;
- contract accepted/rejected;
- unique counterexamples;
- discovery origin method.

Không dùng coverage để thay behavioral oracle.

---

## 11. SO SÁNH P0 VỚI B0 VÀ A0

## 11.1. Pairing bắt buộc

So sánh theo cùng `sample_id`. Không so rate từ hai dataset khác nhau.

Hai comparison chính:

```text
C1: P0 vs B0 — IR-assisted recovery vs direct pseudocode-to-LLM
C2: P0 vs A0 — contribution of post-lifting enhancement block
```

## 11.2. Win/loss/tie table

Với comparison P0 vs X:

| P0 | X | Category |
|---|---|---|
| PASS | FAIL | P0 win |
| FAIL | PASS | P0 loss |
| PASS | PASS | tie-pass |
| FAIL | FAIL | tie-fail |

Trong report phải có count và danh sách sample cho `win` và `loss`.

## 11.3. Effect size chính

```text
RiskDifference(P0, X) = E2E_P0 - E2E_X
```

Báo theo percentage points, ví dụ `+17.5 pp`.

Có thể báo relative improvement:

```text
RelativeImprovement = (E2E_P0 - E2E_X) / E2E_X
```

Nhưng nếu `E2E_X = 0`, báo `undefined`; không dùng relative improvement làm headline.

## 11.4. Paired bootstrap confidence interval

Implementation choice:

1. sample N paired rows with replacement;
2. tính delta E2E cho mỗi bootstrap sample;
3. dùng fixed seed;
4. mặc định 10,000 resamples;
5. lấy percentile 2.5% và 97.5%.

```yaml
statistics:
  bootstrap_resamples: 10000
  bootstrap_seed: 4912026
  confidence_level: 0.95
```

Output:

```text
P0 - B0 risk difference: +X pp, 95% paired bootstrap CI [L, U]
P0 - A0 risk difference: +Y pp, 95% paired bootstrap CI [L, U]
```

## 11.5. Exact McNemar test

Dùng binary pass/fail per sample.

```text
b = count(P0 PASS, X FAIL)
c = count(P0 FAIL, X PASS)
n = b + c
```

Exact two-sided p-value dựa trên Binomial(n, 0.5). Nếu `n=0`, p=1.

Có hai primary hypotheses, áp dụng Holm correction alpha 0.05.

Không tuyên bố superiority chỉ dựa p-value; phải kèm effect size và CI.

## 11.6. Stage diagnosis

Nếu E2E khác nhau, report phải chỉ rõ chênh lệch xuất hiện ở stage nào:

- representation fail;
- context overflow;
- generation invalid;
- build fail;
- runtime fail;
- semantic mismatch;
- inconclusive.

Tạo waterfall/funnel table per method và pairwise transition counts.

## 11.7. Stratified analysis

Nếu dataset manifest có tag, aggregate theo:

- obfuscation type: `fla`, `bcf`, `sub/instsub`, combinations;
- program size quartile;
- raw representation token quartile;
- native contract status của P0;
- context fit vs overflow.

Không suy tag từ source. Dùng dataset metadata hoặc deterministic filename parser và lưu parser version.

---

## 12. OUTPUT DIRECTORY VÀ ARTIFACT CONTRACT

## 12.1. Layout

```text
result/experiments/<run_id>/
  experiment_manifest.json
  config_resolved.json
  integrity_report.json
  audit/
    events.jsonl
    artifact_manifest.json

  samples/<sample_id>/
    identity.json
    common/
      corpus_manifest.json
      inputs/
      reference_outputs/
      union_replay_manifest.json

    B0/
      representation/
        ghidra_original_program.c
        representation_manifest.json
      generation/
        request.json
        response.json
        candidate_raw.txt
        candidate.c
      build/
        build.json
        stdout.log
        stderr.log
        candidate.bin
      evaluation/
        frozen_replay.json
        fuzz_discovery.json
        union_replay.json
      result.json

    A0/
      representation/
        raw.bc
        raw.ll
        representation_manifest.json
      generation/...
      build/...
      evaluation/...
      result.json

    P0/
      representation/
        brightened.bc
        brightened.ll
        p0_pseudocode.c
        native_contract_report.json
        representation_manifest.json
      generation/...
      build/...
      evaluation/...
      result.json

  aggregate/
    variants.csv
    metrics.json
    metrics_long.csv
    stage_funnel.csv
    failures.csv
    pairwise_p0_b0.csv
    pairwise_p0_a0.csv
    method_summary.json
    statistics.json
    ir_cfg_metrics.csv
    figures_manifest.json
    dashboard.html
    figures/
      fig01_e2e_success.svg
      fig02_stage_funnel.svg
      fig03_pairwise_effect.svg
      fig04_efficiency.svg
      fig05_ir_reduction.svg
    report.md
```

`fig03` chỉ sinh khi có paired comparison; `fig05` chỉ sinh khi extract được
IR metrics. Không tạo dữ liệu giả để lấp biểu đồ.

## 12.2. Experiment manifest

```json
{
  "schema_version": "2.1",
  "run_id": "exp_20260724_001",
  "created_at_utc": "2026-07-24T00:00:00Z",
  "dataset_path": "data/custom_dataset.csv",
  "dataset_sha256": "...",
  "methods": ["P0", "A0", "B0"],
  "protocols": {
    "P0": "legacy_iterative_repair_max_5",
    "A0": "strict_one_shot",
    "B0": "strict_one_shot"
  },
  "config_sha256": "...",
  "git_commit": "...",
  "git_dirty": false,
  "tool_versions": {
    "python": "...",
    "ghidra": "12.0.4_PUBLIC",
    "ida": "9.3",
    "mcsema": "...",
    "remill": "...",
    "llvm": "21",
    "clang": "21",
    "aflplusplus": "..."
  },
  "model": {
    "provider": "vertex_ai",
    "model_id": "gemini-2.5-pro",
    "location": "global"
  }
}
```

## 12.3. Variant result JSON

```json
{
  "schema_version": "2.0",
  "run_id": "exp_20260724_001",
  "sample_id": "p00001",
  "method": "A0",
  "terminal_status": "PASS",
  "final_stage": "finalized",
  "e2e_pass": true,
  "failure_code": null,
  "failure_message": null,
  "identity": {
    "original_elf_sha256": "...",
    "input_contract_id": "p00001"
  },
  "representation": {
    "status": "ok",
    "primary_sha256": "...",
    "bytes": 123,
    "tokens": 456,
    "context_fit": true
  },
  "generation": {
    "protocol": "strict_one_shot",
    "logical_generation_count": 1,
    "model_call_count": 1,
    "api_attempt_count": 2,
    "quota_throttle_count": 1,
    "quota_wait_duration_ms": 3600000,
    "request_sha256": "...",
    "candidate_sha256": "...",
    "input_tokens": 456,
    "output_tokens": 789,
    "thinking_tokens": 123,
    "billable_output_tokens": 912,
    "latency_ms": 1000
  },
  "build": {
    "ok": true,
    "executable_sha256": "...",
    "duration_ms": 500
  },
  "evaluation": {
    "reference_sha256": "...original elf...",
    "corpus_manifest_sha256": "...",
    "union_input_count": 100,
    "confirmed_inputs": 100,
    "matches": 100,
    "mismatches": 0,
    "inconclusive": 0,
    "candidate_only_timeouts": 0,
    "candidate_only_crashes": 0,
    "behavior_pass": true
  },
  "integrity": {
    "leakage_scan_passed": true,
    "candidate_immutable": true,
    "reference_is_original_elf": true
  }
}
```

## 12.4. CSV variants

Columns tối thiểu:

```text
run_id,sample_id,method,terminal_status,e2e_pass,
original_elf_sha256,representation_sha256,representation_bytes,representation_tokens,
context_fit,model_call_count,api_attempt_count,quota_throttle_count,
quota_wait_duration_ms,input_tokens,output_tokens,thinking_tokens,
billable_output_tokens,llm_latency_ms,
candidate_sha256,build_ok,build_duration_ms,runnable,
union_input_count,confirmed_inputs,matches,mismatches,inconclusive,
reference_sha256,corpus_manifest_sha256,
representation_duration_ms,generation_duration_ms,
generation_pipeline_duration_ms,evaluation_duration_ms,total_duration_ms,
failure_code
```

## 12.5. Audit event log và artifact seal

`audit/events.jsonl` là append-only theo vòng đời command. Mỗi dòng chứa:

- `sequence`, `timestamp_utc`, `run_id`;
- `event_type`, `sample_id`, `method`, `stage`, `status`;
- payload nhỏ gồm duration, call count và hash quan trọng;
- `previous_event_sha256`;
- `event_sha256`, tính trên canonical JSON của toàn event trừ chính field hash.

Event đầu dùng genesis hash 64 ký tự `0`. Trước khi append phải verify toàn
chain; nếu log đã hỏng thì fail closed.

Khi command hoàn tất, runner ghi event `artifacts_sealed`, sau đó tạo
`audit/artifact_manifest.json` gồm relative path, byte size và SHA-256 của mọi
artifact. `verify-integrity` phải phát hiện:

- event bị sửa, xóa, chèn hoặc reorder;
- artifact sau seal bị sửa/xóa;
- artifact mới xuất hiện nhưng không có trong ledger.

Đây là tamper-evident local audit, không được mô tả như external timestamp,
digital signature hoặc write-once storage.

Khi provider trả HTTP 429/`RESOURCE_EXHAUSTED`, runner phải:

1. ghi `quota_throttled`;
2. chuyển variant sang nonterminal `WAITING_FOR_QUOTA`;
3. checkpoint request SHA-256, P0 iteration và `next_retry_at_utc`;
4. ghi `quota_wait_started`;
5. chờ `Retry-After`, hoặc 3600 giây nếu provider không gửi header;
6. ghi `quota_resumed` và retry đúng request;
7. không tăng logical generation/model call cho attempt bị từ chối.

Tổng wait budget tối đa 3600 giây. Nếu vẫn bị throttle, run phải giữ trạng
thái incomplete và fail integrity; không biến lỗi quota thành semantic non-pass.

## 12.6. Metric và visualization contract

`aggregate/metrics.json` là canonical research metric document, bắt buộc ghi:

- primary endpoint, numerator, denominator và original-ELF reference;
- study-design caveat P0 iterative vs A0/B0 one-shot;
- metric definitions;
- method summaries, Wilson CI, pairwise statistics và IR metrics nếu có.

`aggregate/metrics_long.csv` dùng tidy/long format để tái phân tích độc lập:

```text
scope,method,comparison,metric,statistic,value,unit,denominator
```

Visualization dùng SVG vector để chèn trực tiếp vào luận văn:

1. unconditional E2E PASS rate + Wilson CI;
2. unconditional stage funnel;
3. paired risk difference + paired bootstrap CI;
4. median/IQR của call, token và duration;
5. A0-to-P0 IR structural reduction nếu extract được.

`dashboard.html` chỉ là print-friendly evidence index. Mọi con số trong hình
phải xuất phát từ structured aggregate; không parse free-form log và không có
metric chỉ tồn tại trong HTML/SVG.

---

## 13. CONFIG YAML ĐẦY ĐỦ

```yaml
schema_version: "2.0"

experiment:
  methods: [P0, A0, B0]
  run_seed: 4912026
  fail_fast: false
  resume: true
  variant_order: [B0, A0, P0]
  study_scope: primary_full_dataset
  require_clean_git: true

paths:
  result_root: result/experiments
  ghidra_headless: /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
  ida_disassembler: /opt/ida-pro-9.3/idat
  llvm_dis: /usr/bin/llvm-dis-21
  clang: /usr/bin/clang-21

representation:
  no_truncation: true
  b0:
    ghidra_timeout_sec: 900
    use_cache: true
  a0:
    allow_passes: []
    allow_optimizations: false

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
  # Official Gemini 3.5 Flash model card, verified 2026-07-24.
  context_window_tokens: 1048576
  model_spec_source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/2-5-pro
  model_spec_verified_date: "2026-07-24"
  context_safety_margin_tokens: 1024
  transport_retries: 2
  rate_limit:
    enabled: true
    max_wait_seconds: 3600
    default_retry_after_seconds: 3600
  # Standard PayGo, global endpoint; official pricing verified 2026-07-24.
  pricing_plan: standard_paygo_global
  pricing_usd_per_million_input_tokens: 1.25
  pricing_usd_per_million_output_tokens: 10.00
  pricing_long_context_threshold_tokens: 200000
  pricing_usd_per_million_input_tokens_long_context: 2.50
  pricing_usd_per_million_output_tokens_long_context: 15.00
  pricing_source: https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing
  pricing_verified_date: "2026-07-24"

p0:
  max_iterations: 5
  fuzz_iterations: 100
  fuzz_timeout_sec: 0.5
  use_lifting_cache: true

build:
  compiler: /usr/bin/clang-21
  flags: [-std=c11, -O0, -fno-strict-aliasing, -fwrapv, -Wno-everything]
  link_flags: [-lm]
  timeout_sec: 60

corpus:
  deterministic_supplement_count: 50
  generator_seed: 4912026

fuzz:
  enabled: true
  seconds_per_method: 60
  max_saved_unique_inputs: 5000
  target_accepted_inputs: 50

evaluation:
  compare_stdout: true
  compare_stderr: true
  compare_exit_status: true
  per_input_timeout_sec: 0.1
  min_confirmed_inputs: 50
  max_reference_inconclusive_fraction: 0.20
  nondeterminism_repeats: 3
  environment:
    LC_ALL: C
    LANG: C
    TZ: UTC

statistics:
  bootstrap_resamples: 10000
  bootstrap_seed: 4912026
  confidence_level: 0.95
  alpha: 0.05
```

`context_window_tokens: 0` phải làm config validation fail. Giá trị đang khóa là
`1,048,576` theo model card chính thức của Gemini 3.5 Flash, xác minh ngày
`2026-07-24`; coding agent không được tự đoán model context trong production
run. Pricing đang khóa theo Standard PayGo trên global endpoint, cũng được xác
minh ngày `2026-07-24`; manifest và metrics phải giữ plan, rate, URL nguồn và
ngày xác minh. Estimate chỉ dùng provider-reported input/output token, không
thay thế invoice; fake-LLM run không được phát sinh estimated cost.
Runtime config parser từ chối unknown key; hai file YAML trong `configs/` là
nguồn cấu hình canonical.

---

## 14. CLI VÀ WORKFLOW

## 14.1. Một lệnh chạy toàn bộ

```bash
python3 src/main.py data/custom_dataset.csv experiment \
  --methods P0,A0,B0 \
  --config configs/experiment_primary.yaml \
  --run-id exp_20260724_001
```

## 14.2. Pilot

```bash
python3 src/main.py data/custom_dataset.csv experiment \
  --methods P0,A0,B0 \
  --config configs/experiment_pilot.yaml \
  --pilot 1
```

## 14.3. Staged commands đề xuất

```bash
python3 -m src.experiments.cli prepare --run-id ...
python3 -m src.experiments.cli generate --run-id ...
python3 -m src.experiments.cli evaluate --run-id ...
python3 -m src.experiments.cli aggregate --run-id ...
python3 -m src.experiments.cli verify-integrity --run-id ...
```

Lợi ích:

- resume riêng từng stage;
- không gọi lại LLM khi chỉ sửa aggregate;
- candidate freeze trước evaluator;
- dễ audit.

## 14.4. Resume semantics

`--resume`:

- đọc `result.json` và stage manifests;
- verify artifact hash trước khi skip;
- nếu config hash khác -> refuse resume trừ `--fork-run`;
- nếu request đã thành công, không call model lại;
- nếu evaluation config đổi, tạo evaluation revision mới, không overwrite raw generation;
- run nhiều lần phải idempotent.

---

## 15. THAY ĐỔI FILE-BY-FILE

## 15.1. `src/main.py`

Thêm subcommand `experiment`.

Trách nhiệm:

- parse dataset/config/methods/protocol;
- tạo run manifest;
- gọi `ExperimentRunner`;
- exit non-zero chỉ cho run-level fatal integrity error, không vì một sample fail.

Không đặt logic B0/A0 trực tiếp trong `main.py`.

## 15.2. `src/llm_recovery/llm_recovery.py`

Tách:

```python
def generate_candidate(request: GenerationRequest) -> GenerationResponse:
    """One logical generation; no compile, no fuzz, no repair."""
```

Giữ API cũ:

```python
def recover_with_iterative_feedback(...):
    """Supplementary engineering mode only."""
```

Không để `generate_candidate` import `fuzzing.py`.

## 15.3. `src/binary_lifting/lifting.py`

Expose structured API:

```python
def lift_binary(
    original_elf: Path,
    output_dir: Path,
    config: LiftingConfig,
) -> LiftResult:
    ...
```

`LiftResult` trả raw paths, hashes, commands, versions, cache provenance.

Không tự động brightening bên trong hàm này.

## 15.4. `src/llvm_pass/britening_ir.py`

Giữ P0-specific:

```python
def brighten_raw_ir(raw_bc: Path, output_dir: Path, config: BrightenConfig) -> BrightenResult:
    ...
```

A0 không import/call module này.

## 15.5. `src/fuzzing_equi_check/fuzzing.py`

Tách ba API:

```python
def run_inputs(reference_bin, candidate_bin, inputs, config) -> ReplayResult:
    ...

def discover_inputs(candidate_bin, seed_inputs, contract, config) -> DiscoveryResult:
    ...

def compare_outcomes(reference_outcome, candidate_outcome, config) -> Comparison:
    ...
```

`run_inputs` phải nhận exact input bytes và không tự sinh thêm input.

## 15.6. `src/fuzzing_equi_check/input_contracts.py`

Expose deterministic generator:

```python
def generate_contract_inputs(contract, count, seed) -> list[bytes]:
    ...
def validate_input(contract, data: bytes) -> bool:
    ...
```

Cùng seed phải tạo cùng ordered bytes.

## 15.7. `src/experiments/representations/b0_ghidra.py`

Implement `B0Builder`:

```python
class B0Builder(RepresentationBuilder):
    method = MethodId.B0

    def build(self, sample, ctx) -> RepresentationArtifact:
        # target original ELF
        # deterministic Ghidra export
        # hash + manifest + leakage validation
        ...
```

## 15.8. `src/experiments/representations/a0_raw_ir.py`

Implement `A0Builder`:

```python
class A0Builder(RepresentationBuilder):
    method = MethodId.A0

    def build(self, sample, ctx) -> RepresentationArtifact:
        # lift only
        # llvm-dis raw.bc
        # no opt/pass/Ghidra
        ...
```

## 15.9. `src/experiments/representations/p0_full.py`

Adapter existing P0:

- use lift result;
- call brightening;
- build P0 pseudocode;
- return both attachments;
- do not evaluate/generate internally.

## 15.10. `src/experiments/runner.py`

Orchestrator không chứa method-specific logic ngoài registry.

```python
BUILDERS = {
    MethodId.B0: B0Builder,
    MethodId.A0: A0Builder,
    MethodId.P0: P0LegacyAdapter,
}
```

Phải catch exception theo variant và persist terminal result thay vì làm chết toàn run.

## 15.11. `src/experiments/reporting/aggregate.py`

Chỉ đọc structured JSON.

Validation trước aggregate:

- đủ N × 3 variant result;
- unique `(sample_id, method)`;
- same reference hash per sample;
- same union corpus hash per sample;
- strict protocol call count hợp lệ;
- no forbidden leak flag;
- candidate hash không đổi.

---

## 16. THUẬT TOÁN ORCHESTRATION CHUẨN

```python
def run_experiment(dataset, config):
    run = initialize_run(dataset, config)

    for row_index, row in enumerate(dataset):
        sample = enroll_sample(row_index, row, config)
        persist_identity(sample)

        base_corpus = prepare_frozen_base_corpus(sample, config)

        variant_states = {}

        for method in config.experiment.methods:
            state = initialize_variant(sample, method)
            variant_states[method] = state

            try:
                rep = BUILDERS[method](config).build(sample, run.context)
                persist_representation(rep)

                request = build_common_generation_request(sample, rep, config)
                verify_no_leakage(request, method, config)
                verify_context_fit(request, config)

                response = generate_candidate(request)
                candidate = extract_candidate(response, config)
                freeze_candidate(candidate)

                build = build_candidate(candidate, config)
                if not build.ok:
                    finalize_terminal(state, BUILD_FAILED)
                    continue

                smoke = smoke_run(sample.original_elf, build.executable, base_corpus, config)
                if not smoke.runnable:
                    finalize_terminal(state, NOT_RUNNABLE)
                    continue

                frozen_replay = replay_common_inputs(
                    sample.original_elf,
                    build.executable,
                    base_corpus,
                    config,
                )

                discovery = discover_inputs(
                    build.executable,
                    base_corpus,
                    sample.input_contract,
                    config,
                )

                state.record_nonterminal_results(...)

            except ContextOverflow as exc:
                finalize_terminal(state, CONTEXT_OVERFLOW, exc)
            except RepresentationError as exc:
                finalize_terminal(state, REPRESENTATION_FAILED, exc)
            except LLMError as exc:
                finalize_terminal(state, LLM_REQUEST_FAILED, exc)
            except Exception as exc:
                finalize_terminal(state, INFRA_ERROR, exc)

        union_corpus = build_union_corpus(
            base_corpus,
            [state.discovery_inputs for state in variant_states.values()],
            config,
        )

        reference_cache = execute_reference_once(
            sample.original_elf,
            union_corpus,
            config,
        )

        for method, state in variant_states.items():
            if state.has_runnable_candidate:
                replay = replay_candidate_against_cached_reference(
                    state.executable,
                    union_corpus,
                    reference_cache,
                    config,
                )
                terminal = classify_final_result(state, replay, config)
                finalize_terminal(state, terminal)

    verify_run_integrity(run)
    aggregate_run(run)
```

Quan trọng: variant đã build fail không chạy union replay, nhưng vẫn có terminal result và denominator.

---

## 17. TEST PLAN

## 17.1. Unit tests — identity/hash/config

```text
T-ID-01: cùng ELF tạo cùng SHA-256 và identity.
T-ID-02: sửa một byte ELF làm identity hash đổi.
T-CFG-01: context_window_tokens=0 làm validation fail.
T-CFG-02: P0 max_iterations khác 5 làm validation fail.
T-CFG-03: A0 allow_passes không rỗng làm validation fail.
```

## 17.2. Unit tests — B0 contamination

```text
T-B0-01: target original ELF.
T-B0-02: reject brightened_ref target.
T-B0-03: reject .ll attachment.
T-B0-04: deterministic function order.
T-B0-05: no clean_src/expected_output string in request.
```

## 17.3. Unit tests — A0 purity

```text
T-A0-01: raw .bc produced before P0 pass.
T-A0-02: command trace contains no opt.
T-A0-03: command trace contains no Brighten*.so.
T-A0-04: request attachment role is raw_ir only.
T-A0-05: raw_ll hash stable.
```

## 17.4. Unit tests — generation

```text
T-GEN-01: A0/B0 one-shot calls client đúng một logical generation.
T-GEN-02: A0/B0 compiler error không trigger generation thứ hai.
T-GEN-03: A0/B0 fuzz mismatch không trigger generation thứ hai.
T-GEN-04: P0 giữ early-stop và không vượt 5 iteration.
T-GEN-05: response and candidate hashes persisted.
```

## 17.5. Unit tests — outcome comparison

Fixtures:

- exact match;
- stdout mismatch;
- exit-code mismatch;
- candidate timeout only;
- both timeout;
- candidate crash only;
- both crash;
- reference nondeterminism.

Expected classification phải đúng Section 9.5.

## 17.6. Unit tests — metric formulas

Với fixture 4 samples:

```text
P0: PASS, PASS, FAIL, PASS -> 75%
B0: FAIL, PASS, FAIL, PASS -> 50%
A0: FAIL, FAIL, FAIL, PASS -> 25%
```

Kiểm tra:

- E2E;
- stage funnel;
- P0-B0 wins/losses;
- risk difference;
- exact McNemar inputs;
- bootstrap deterministic với seed.

## 17.7. Integration tests

### IT-01 — One sample, fake LLM

- build B0/A0/P0 representations;
- fake LLM trả C đã biết;
- compile;
- replay 10 input;
- ba result JSON hoàn chỉnh.

### IT-02 — P0 failure independence

- force brightening fail;
- B0 và A0 vẫn generation/evaluation;
- P0 `REPRESENTATION_FAILED`.

### IT-03 — A0 lift failure independence

- force McSema fail;
- A0 fail;
- B0 vẫn chạy;
- P0 behavior theo khả năng riêng/cached lift, không bị runner kill.

### IT-04 — Union replay fairness

- B0 fuzz khám phá input gây P0 mismatch;
- input đó được đưa vào union;
- P0 final status phải mismatch dù P0 campaign không tự tìm thấy.

### IT-05 — Resume

- stop sau generation;
- resume evaluation;
- không call LLM lại;
- request/candidate hash giữ nguyên.

### IT-06 — Variant order invariance

Chạy `[B0,A0,P0]` và `[P0,B0,A0]` với fake deterministic tools. Per-method request hash, corpus hash và final classification phải giống.

## 17.8. Pilot acceptance

Pilot 1 sample chỉ đạt khi:

- có đủ 3 `result.json`;
- original reference hash giống trong cả ba;
- union corpus hash giống;
- B0 request không có IR;
- A0 request không có Ghidra;
- P0 request có đúng P0 artifacts;
- A0/B0 logical generation count = 1 khi context-fit;
- P0 model call/iteration count không vượt 5 và giữ early-stop;
- aggregate chạy được;
- audit chain và artifact manifest verify pass;
- `metrics.json`, `metrics_long.csv`, SVG figures và dashboard sinh được;
- rerun `--resume` không đổi result.

---

## 18. PR PLAN CHO CODING AGENT

## PR-1 — Experiment core và schema

Deliverables:

- enums/dataclasses/config loader;
- hashing/storage;
- run/sample/variant manifests;
- config validation;
- tests schema/idempotency.

Definition of done:

- có thể enrol dataset và tạo terminal placeholder cho N × 3 variants.

## PR-2 — Refactor generation-only API

Deliverables:

- `generate_candidate` không compile/fuzz;
- strict protocol guard;
- prompt/request manifest;
- leakage scanner;
- candidate extraction.

Definition of done:

- fake LLM test chứng minh một logical call.

## PR-3 — B0 builder

Deliverables:

- Ghidra original ELF exporter;
- deterministic program-level pseudocode;
- B0 manifest/cache/purity tests.

Definition of done:

- request B0 không có bất kỳ IR/P0 artifact.

## PR-4 — A0 builder

Deliverables:

- structured lifting result;
- raw `.bc`/`.ll` stop point;
- pass trace purity check;
- A0 manifest/cache/context handling.

Definition of done:

- A0 request hash đúng raw IR và không call brightening/Ghidra.

## PR-5 — P0 adapter

Deliverables:

- P0 builder dùng existing pipeline;
- strict one-shot adapter;
- original ELF final reference;
- P0 failure không gate B0/A0.

## PR-6 — Common evaluator

Deliverables:

- build runner;
- execution outcome;
- frozen corpus;
- discovery input;
- union replay;
- timeout/crash/nondeterminism classification.

## PR-7 — Aggregate/statistics/report

Deliverables:

- stage funnel;
- E2E rate;
- pairwise P0-B0/P0-A0;
- bootstrap CI;
- exact McNemar + Holm;
- CSV/JSON/Markdown report;
- canonical metrics JSON + tidy CSV;
- publication-ready SVG figures + HTML evidence index.

## PR-8 — Full integration, docs và pilot

Deliverables:

- CLI;
- resume;
- integrity verifier;
- hash-chained audit log và SHA-256 artifact seal;
- pilot evidence;
- README runbook.

---

## 19. DEFINITION OF DONE TOÀN BỘ

Implementation chỉ được coi là hoàn thành khi tất cả điều sau đúng:

1. Có `B0Builder`, `A0Builder` và `P0LegacyAdapter` với artifact contract chung.
2. B0 decompile đúng original ELF.
3. A0 chỉ dùng raw McSema `.ll`, không pass/opt/pseudocode.
4. P0 dùng nguyên full pipeline hiện tại, compiler/fuzz feedback, early-stop và tối đa 5 iteration.
5. A0/B0 strict one-shot; P0-current dùng legacy iterative protocol và khác biệt này được ghi rõ.
6. A0/B0 không dùng compiler/test/fuzz feedback để regenerate.
7. Final reference của cả ba là original obfuscated ELF.
8. Mỗi sample có common union corpus và same corpus hash giữa methods.
9. Mọi variant có terminal result.
10. Primary E2E denominator là toàn bộ enrolled set.
11. Có stage funnel và failure taxonomy.
12. Có pairwise P0-B0 và P0-A0 theo sample.
13. Có effect size, paired CI, exact McNemar/Holm.
14. Request leakage scan pass.
15. Candidate immutable sau generation.
16. Resume không call lại LLM hoặc đổi hash.
17. Variant order không làm đổi kết quả deterministic.
18. Pilot và test suite pass.
19. Aggregate không parse free-form logs.
20. Có hash-chained audit log và sealed artifact manifest verify được.
21. Có canonical metric JSON, tidy CSV, SVG figures và HTML evidence index.
22. Báo cáo không diễn giải P0-vs-A0/B0 như representation-only causal effect.

---

## PHỤ LỤC A — PROMPT ĐẦY ĐỦ

### A.1. System prompt chung

```text
You are a highly skilled reverse engineer specializing in binary deobfuscation and C reconstruction.
Recover exactly one complete Linux-compilable C11 source file that preserves the observable behavior represented by the supplied low-level program representation.

Requirements:
1. Include main and every required user-defined function.
2. Include required standard headers, declarations, globals, constants, and helpers.
3. Simplify obfuscation artifacts only when justified by the input.
4. Do not omit behavior, use placeholders, or hard-code known test outputs.
5. Return C source only, without Markdown fences or explanations.
```

### A.2. User prompt B0

```text
Representation type: decompiler-generated pseudocode from an OLLVM-obfuscated binary.
<OBFUSCATED_PSEUDOCODE>
{GHIDRA_PSEUDOCODE}
</OBFUSCATED_PSEUDOCODE>
```

### A.3. User prompt A0

```text
Representation type: raw LLVM IR lifted from an OLLVM-obfuscated binary by McSema.
No custom deobfuscation, control-flow recovery, type recovery, cleanup, or LLVM optimization has been applied.
Recover one complete Linux-compilable C11 source file that preserves the observable behavior of the represented program.

<RAW_LIFTED_LLVM_IR>
{RAW_LLVM_IR}
</RAW_LIFTED_LLVM_IR>
```

### A.4. User prompt P0

```text
Representation type: post-lifting enhanced LLVM IR and C-like pseudocode produced by a binary deobfuscation pipeline.
Recover one complete Linux-compilable C11 source file that preserves the observable behavior of the represented program.

<ENHANCED_LLVM_IR>
{BRIGHTENED_LLVM_IR}
</ENHANCED_LLVM_IR>

<C_LIKE_PSEUDOCODE>
{P0_PSEUDOCODE}
</C_LIKE_PSEUDOCODE>
```

---

## PHỤ LỤC B — TERMINAL STATUS DECISION TABLE

| Representation | Context | LLM | Candidate | Build | Behavior | Terminal |
|---|---|---|---|---|---|---|
| fail | - | - | - | - | - | `REPRESENTATION_FAILED` |
| ok | overflow | - | - | - | - | `CONTEXT_OVERFLOW` |
| ok | fit | API fail | - | - | - | `LLM_REQUEST_FAILED` |
| ok | fit | empty | invalid | - | - | `LLM_EMPTY_RESPONSE`/`INVALID_CANDIDATE` |
| ok | fit | ok | saved | fail | - | `BUILD_FAILED` |
| ok | fit | ok | saved | ok | not runnable | `NOT_RUNNABLE` |
| ok | fit | ok | saved | ok | mismatch | `BEHAVIOR_MISMATCH` |
| ok | fit | ok | saved | ok | insufficient oracle | `EVAL_INCONCLUSIVE` |
| ok | fit | ok | saved | ok | no observed divergence | `PASS` |

---

## PHỤ LỤC C — CODING AGENT PROMPT

```text
You are modifying an existing Python/LLVM binary deobfuscation project. Implement the specification in this document exactly.

Primary objective:
- add B0 direct original-ELF Ghidra pseudocode-to-C;
- add A0 raw McSema LLVM-IR-only;
- adapt existing P0 unchanged with at most five compiler/fuzz-feedback iterations;
- implement a common original-ELF differential evaluator and paired metrics.

Hard constraints:
1. Do not change the scientific contract.
2. Do not put IR into B0.
3. Do not put Ghidra pseudocode or optimization into A0.
4. Do not compare final candidates to brightened_ref.bin.
5. Do not use compiler/fuzz feedback for A0/B0; preserve it for P0-current.
6. Do not allow P0 failure to block B0/A0.
7. Do not use clean source, expected outputs, semantic reports, or counterexamples in LLM requests.
8. Do not drop failed variants from denominators.
9. Persist structured JSON and hashes for every stage.
10. Use the existing iterative recovery path as the primary P0-current method.
11. Persist a hash-chained audit log and seal artifacts with SHA-256.
12. Export canonical metrics and publication-ready visualizations.

Implementation process:
- inspect current APIs before editing;
- create adapters rather than duplicate tool logic;
- implement PR-1 through PR-8 in order;
- add unit and integration tests listed in Section 17;
- run pilot with one sample;
- produce a final implementation report listing changed files, commands run, tests, unresolved environment issues, and example output paths.

When the existing code conflicts with this spec, preserve P0-current behavior
through its legacy adapter; enforce strict one-shot only for A0/B0.
```

---

## PHỤ LỤC D — CÁC GIÁ TRỊ PHẢI FREEZE TRƯỚC MAIN RUN

Coding có thể hoàn thành trước, nhưng trước khi chạy main experiment phải điền và khóa:

1. exact model snapshot/version;
2. context window tokens;
3. compiler path/version/flags;
4. main fuzz seconds per method;
5. per-input timeout;
6. minimum confirmed inputs;
7. compare stderr policy;
8. dataset SHA-256;
9. git commit;
10. all tool versions;
11. Ghidra export script SHA-256;
12. LLVM pass pipeline hash của P0.

---

## PHỤ LỤC E — KẾT QUẢ REAL-PROVIDER BA CASE

Run `real_three_case_20260724_03` là kết quả authoritative cho scoped study
trên `p00001`, `p00008`, `p00033`. Run `_01` được giữ làm forensic baseline vì
generator không phủ count-growth boundary; run `_02` được giữ vì timeout 0.1s
đã phân loại boundary reference thành inconclusive. `_03` dùng generator đã
thêm `{1,2,4,8,16,64}` và reference timeout 2.0s.

| Method | PASS | E2E | Accepted calls | API attempts | Estimated cost |
|---|---:|---:|---:|---:|---:|
| P0 | 3/3 | 100% | 7 | 7 | $3.607287 |
| A0 | 0/3 | 0% | 3 | 3 | $2.151878 |
| B0 | 2/3 | 66.67% | 3 | 3 | $0.484121 |

P0 − A0 là `+100.0 pp`; P0 − B0 là `+33.33 pp`, với paired bootstrap CI
`[0,+100]` và exact McNemar `p=1`. A0 có một `BEHAVIOR_MISMATCH` và hai
`BUILD_FAILED` sau `MAX_TOKENS`. B0 có ba confirmed crash asymmetries trên
`p00033` count probes `N=8,16,64`; P0 tái hiện cùng crash và pass. Ba probe P0
là `INCONCLUSIVE_BOTH_CRASH`, dưới ngưỡng reference-inconclusive 0.20.

Kết luận đúng: dữ liệu scoped ủng hộ A0 yếu hơn P0 và ủng hộ mô tả rằng P0
vượt B0 một case; `n=3` không đủ cho confirmatory inference. Không được dùng
run `_01`/`_02` thay cho `_03`, cherry-pick sample hoặc đổi denominator.
