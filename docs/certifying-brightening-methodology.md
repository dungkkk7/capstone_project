# Phương pháp Certifying Brightening cho IR do McSema lift

## 1. Phạm vi và tuyên bố có thể kiểm chứng

Mục tiêu của hệ thống không phải là tuyên bố mọi binary đều có thể được khôi phục
thành IR native, dễ đọc và tương đương tuyệt đối. Tuyên bố đó không kiểm chứng
được đối với chương trình tùy ý và dễ biến một kết quả thực nghiệm thành
marketing.

Tuyên bố của protocol v1 là:

> **100% artifact mang hậu tố `certified` phải vượt qua toàn bộ gate bắt buộc đã
> đóng băng, trên đúng byte của IR và executable được công bố. FAIL, ERROR,
> INCONCLUSIVE, timeout, thiếu tool hoặc thiếu evidence đều không được xem là
> PASS.**

Do đó, “100%” ở đây là tính toàn vẹn của quy trình cấp authority, không phải tỷ
lệ khôi phục trên mọi input. Một module không đủ bằng chứng vẫn có thể được lưu
với nhãn `validated-compat` hoặc `evidence`; nó không được gọi là fully native
hay universally equivalent.

## 2. Vấn đề nghiên cứu

Chuỗi pass hiện tại có nhiều nguồn tạo candidate: pattern/rule chính xác, phân
tích data-flow, LLVM simplification, proof bằng Z3 và các bước delift. Điểm yếu
không nằm ở việc có rule, mà ở chỗ candidate generation, validation và quyền
công bố output chưa được tách thành các lớp độc lập.

Các câu hỏi nghiên cứu được đóng băng như sau:

- **RQ1 — Correctness:** phương pháp fail-closed có làm giảm số output sai nhưng
  vẫn bị chấp nhận so với pipeline rule-only hay không?
- **RQ2 — Coverage:** kết hợp rule, data-flow và solver có tăng số module được
  chấp nhận mà không giảm precision của acceptance hay không?
- **RQ3 — Native delifting:** bao nhiêu module loại bỏ được State/Memory ABI,
  Remill/McSema residual và liên kết độc lập không cần compatibility runtime?
- **RQ4 — Cost:** chi phí thời gian, bộ nhớ, solver budget và số lần thực thi
  oracle tăng bao nhiêu cho mỗi module được chấp nhận thêm?
- **RQ5 — Failure attribution:** protocol có phân biệt được structural failure,
  behavioral divergence, native-contract failure, timeout và thiếu công cụ hay
  không?

Giả thuyết chính:

- **H1:** candidate discovery lai (rule + analysis + bounded solver) tăng safe
  coverage so với rule-only.
- **H2:** authority gate fail-closed đưa false acceptance trong tập đánh giá về
  0, với “false acceptance” là output được gắn `certified` nhưng có ít nhất một
  gate bắt buộc không PASS.
- **H3:** native-contract và independent-link gates ngăn việc đánh đồng một IR
  chạy được nhờ McSema runtime với IR đã delift native hoàn toàn.

## 3. Kiến trúc phương pháp

### 3.1 Candidate discovery không có quyền cấp chứng nhận

Mọi pass biến đổi chỉ tạo **candidate**. Candidate có thể đến từ:

1. rewrite rule có matcher chính xác;
2. constant propagation, alias/data-flow hoặc abstract interpretation;
3. bounded SMT proof cho MBA/opaque predicate;
4. standard LLVM optimization;
5. ABI, stack, global-data và type recovery;
6. delift bundle.

Một rule match hoặc solver trả SAT/UNSAT không tự động biến output thành
`certified`. Mỗi transformation family cần ghi:

- precondition;
- proof obligation;
- status `proved`, `disproved`, `unknown`, `unsupported`, `timeout` hoặc `error`;
- số candidate, số rewrite, số từ chối và lý do;
- hash input/output.

`unknown`, `unsupported` và `timeout` là từ chối an toàn, không phải thành công.

### 3.2 Transaction và rollback

Mỗi stage chạy trong thư mục riêng theo `run_id`:

1. đọc checkpoint được chấp nhận gần nhất;
2. xóa candidate cũ trước khi chạy action;
3. ghi candidate mới vào path khác input;
4. băm SHA-256;
5. chạy các gate chỉ-đọc;
6. so sánh hash trước/sau từng gate để phát hiện gate làm thay đổi artifact;
7. chỉ cập nhật `last_accepted_artifact` khi mọi gate required của stage PASS.

Nếu action hoặc gate thất bại, checkpoint trước vẫn giữ nguyên. Artifact stale từ
lần chạy cũ không thể được dùng như kết quả mới.

### 3.3 Gate bắt buộc của protocol v1

Danh sách và thứ tự authority gate được đóng băng tại
`configs/certification_protocol_v1.json`.

| Gate | PASS khi và chỉ khi |
|---|---|
| `llvm_verify` | `opt -passes=verify` chấp nhận đúng final candidate |
| `entrypoint` | `llvm-nm` thấy symbol entrypoint cấu hình là public và defined |
| `bundle_link` | bundle tạo executable ELF không rỗng, có quyền execute và hash được ghi nhận |
| `behavior` | mọi input trong corpus hợp lệ đã đóng băng cho cùng observable tuple; không mismatch, không inconclusive, không early stop |
| `native_contract` | final native reporter ghi 0 violation trên đúng candidate |
| `native_compile` | final IR liên kết độc lập thành executable mà không dùng McSema compatibility runtime |

Gate structural không thay thế gate behavioral. LLVM verifier chỉ chứng minh module
well-formed theo IR rules; nó không chứng minh chương trình có cùng hành vi với
binary gốc. Tương tự, executable chạy được nhờ runtime không đồng nghĩa với
fully-native.

### 3.4 Behavioral oracle có miền đầu vào đóng băng

Random byte fuzzing không đủ để cấp chứng nhận cho chương trình có grammar đầu
vào. Protocol yêu cầu:

- một valid-input contract dạng JSON;
- seed corpus được băm;
- deterministic RNG seed;
- exact ordered corpus được lưu base64 và băm theo length-delimited SHA-256;
- replay đúng byte của toàn bộ corpus;
- strict oracle so sánh exit status, signal/crash, timeout, stdout và stderr;
- một-sided timeout được xác nhận lại theo policy của fuzzer;
- unstable observation được ghi `inconclusive`, không được tính là match.

Behavior gate chỉ PASS khi `total_runs == confirmed_runs == matches == N`,
`mismatches == 0`, `inconclusive == 0`, corpus replay hash đúng và byte của cả
candidate/reference không đổi trong quá trình chạy.

Kết luận của gate là **“không tìm thấy divergence trên corpus đã đăng ký”**, không
phải chứng minh tương đương trên mọi input.

### 3.5 Local translation validation

Alive2 hoặc SMT equivalence checker có thể được bổ sung cho rewrite cục bộ trong
subset được hỗ trợ. Nó phải nằm ở ranh giới transformation và trả về trạng thái
ba giá trị: proved, disproved hoặc unknown. Không suy rộng một local proof thành
interprocedural whole-program equivalence; các phép biến đổi ABI, external call,
I/O và runtime vẫn phải qua structural, link và behavioral gates.

## 4. Phân lớp output

- **`certified`**: mọi gate trong frozen certification policy PASS.
- **`validated-compat`**: structural gates và behavior PASS, nhưng một hoặc nhiều
  native gate không PASS. Output có thể hữu ích để phân tích nhưng chưa fully
  native.
- **`evidence`**: LLVM verifier PASS nhưng evidence structural/behavioral chưa
  đầy đủ. Không publish executable có authority.
- **`rejected`**: không có candidate đủ điều kiện công bố.

Tên file là một phần của contract. Một run mới xóa mọi alias authority cũ trước
khi bắt đầu; run thất bại không được để lại `.certified.*` từ lần trước.

## 5. Thiết kế thực nghiệm

### 5.1 Đơn vị phân tích

Đơn vị chính là một cặp `(reference ELF, lifted module)` cùng manifest gồm:

- SHA-256 của ELF, raw IR, plugin và config;
- compiler, optimization level, obfuscation family/seed;
- McSema/Remill/LLVM version;
- pass pipeline và solver budget;
- input contract, seed corpus và corpus RNG seed.

Một module chỉ xuất hiện trong một split. Các biến thể cùng source family phải ở
cùng split để tránh leakage.

### 5.2 Split và protocol freeze

- **development:** dùng để sửa matcher, proof obligation và timeout;
- **validation:** chọn budget và policy trước khi báo cáo;
- **held-out test:** chỉ chạy sau khi code, plugin, prompt/config và manifest đã
  đóng băng.

Nên stratify theo compiler, `O0/O1/O2/O3`, obfuscation family, control-flow shape,
I/O grammar và kích thước. Không sửa rule theo lỗi riêng của held-out test rồi
báo lại cùng tập như kết quả độc lập.

### 5.3 Baseline và ablation

Chạy cùng dataset, toolchain và budget tổng:

1. raw McSema IR;
2. current rule-only configuration;
3. rule + data-flow;
4. rule + data-flow + bounded Z3;
5. full candidate pipeline nhưng không authority gate;
6. full certifying pipeline;
7. ablation bỏ lần lượt behavior, native contract, independent compile và
   rollback/hash immutability.

Ablation số 5 đo coverage; số 6 đo safe accepted coverage. Không dùng output bị
rejected để làm tăng tỷ lệ thành công.

### 5.4 Chỉ số

Báo cáo tối thiểu:

- `candidate_rate`, `accepted_rate`, `certified_rate`;
- acceptance precision trên tập có oracle;
- mismatch, crash, timeout và inconclusive rate;
- fully-native rate và compatibility-only rate;
- residual count theo family: State/Memory ABI, Remill intrinsic, dispatcher,
  guest-address cast, compatibility runtime symbol;
- rewrite/proof/refusal count theo pass;
- wall time, peak RSS, solver calls/timeouts và oracle executions;
- coverage của valid-input corpus nếu có instrumentation.

Dùng paired analysis vì mọi treatment chạy trên cùng module. Với biến nhị phân,
báo McNemar exact test và paired bootstrap confidence interval cho chênh lệch
rate. Với thời gian/coverage, báo median, IQR, paired effect size và Wilcoxon
signed-rank khi phù hợp. Luôn công bố denominator và số inconclusive.

## 6. Reproducibility và audit

Mỗi `*.certification.json` phải chứa:

- protocol version và protocol hash;
- `run_id`, timestamp, git commit/dirty state;
- tool path/version;
- plugin path/hash;
- environment ảnh hưởng pipeline;
- action command, stdout/stderr và return code;
- input/candidate/binary/reference hashes;
- từng gate result, duration, metrics và evidence path;
- exact frozen behavior corpus;
- final output class và hash của file đã publish.

Gate evidence là append-only theo run directory. Không tái sử dụng report của
module khác hoặc report được tạo trước mutation cuối.

CI chạy unit test cho các invariant fail-closed: stale output, gate
inconclusive, gate mutation, path escape, thiếu entrypoint, thay đổi hash sau
validation và policy đủ sáu gate.

## 7. Cách chạy

```bash
python3 src/llvm_pass/run_certifying_brightening.py \
  --input artifacts/case_lifted.bc \
  --reference binaries/case_obfuscated \
  --output-prefix artifacts/case \
  --domain-contract data/contracts/case.json \
  --seed-dir data/seeds/case \
  --iterations 1000 \
  --corpus-seed 12648430 \
  --jobs 4
```

Kết quả authoritative chỉ có thể là một trong:

```text
case.certified.ll / case.certified.bin
case.validated-compat.ll / case.validated-compat.bin
case.evidence.ll
case.certification.json
```

Exit code 0 chỉ dành cho `certified`. Các lớp còn lại trả non-zero để automation
không vô tình coi evidence chưa đủ là release thành công.

## 8. Tiêu chí hoàn thành nghiên cứu

Một phiên bản được xem là sẵn sàng báo cáo khi:

1. protocol và dataset manifest đã freeze;
2. unit/negative/metamorphic tests của từng pass PASS;
3. không có stale authority artifact sau injected failures;
4. held-out campaign chạy hết với report đầy đủ;
5. mọi bảng kết quả phân biệt candidate, accepted, compatibility và certified;
6. claim trong luận văn khớp đúng authority class và miền input được kiểm tra;
7. toàn bộ artifact, counterexample và script tổng hợp có thể tái tạo từ commit
   được công bố.

Phương pháp này không hứa “biến đổi bằng mọi giá”. Nó hứa rằng khi hệ thống nói
`certified`, bằng chứng yêu cầu bởi protocol đã thực sự tồn tại và gắn với đúng
artifact được phát hành.
