# Kết quả cuối của năm flow và đúc kết từ toàn bộ quá trình

> **Historical snapshot, not the active taxonomy.** The `F3-O1/O2/O3` labels
> below belong to an older optimizer ablation. The active five-flow protocol is
> `B1/B2/F1/F2/F3` as defined in [`research-evaluation-protocol.md`](research-evaluation-protocol.md).

> **Superseded:** đây là snapshot trước khi thêm raw-assembly B2/B3. Kết quả
> authoritative hiện tại là `docs/seven-treatment-analysis.md`; chi tiết
> O1/O2/O3 trên IR là `docs/optimization-ir-boundary-analysis.md`.

## 0. Kết luận ngắn nhất

Trên 40 chương trình C11 tự xây và cùng 1,000 input hợp lệ mỗi case:

| Treatment | Representation | Feedback policy | PASS | Tỷ lệ |
|---|---|---|---:|---:|
| B0 | Ghidra program pseudocode | one-shot | 10/40 | 25.0% |
| B1 | Ghidra program pseudocode | tối đa 5 response, có validation feedback | 39/40 | 97.5% |
| F3-O1 | Clean LLVM IR, standard optimization O1 | tối đa 5 response | 38/40 | 95.0% |
| F3-O2 | Clean LLVM IR, standard optimization O2 | tối đa 5 response | 38/40 | 95.0% |
| F3-O3 | Clean LLVM IR, standard optimization O3 | tối đa 5 response | 37/40 | 92.5% |

Kết quả mới làm thay đổi attribution chính. B0→B1 tăng 72.5 điểm phần trăm
trong khi giữ nguyên Ghidra representation và request đầu. B1 không kém F3;
ngược lại, nó hơn O1/O2 một case và hơn O3 hai case trong campaign đơn này.
Vì vậy evidence hiện tại cho thấy **validation-guided feedback loop là khối có
effect quan sát lớn nhất**. Clean IR vẫn có giá trị kỹ thuật và phân tích, nhưng
chưa được chứng minh tạo accuracy gain so với Ghidra khi cả hai cùng có loop.

Không có fine-tuning, adapter, RAG hay cập nhật weight của LLM. Thay đổi nằm ở
representation, orchestration, validation và các transformation LLVM.

## 1. Năm flow thực sự khác nhau ở đâu

| Flow | Input cho LLM | Request đầu | Request sau | Khối tiền xử lý | Câu hỏi mà flow trả lời |
|---|---|---|---|---|---|
| B0 | Ghidra export từ ELF gốc | prompt LLM4Decompile, không system | không có | Ghidra mặc định + deterministic exporter | Baseline paper-style one-shot làm được bao nhiêu? |
| B1 | đúng Ghidra export của B0 | byte-identical với B0, không system | parser/compiler/counterexample feedback | giống B0 | Thêm loop trên cùng representation giúp bao nhiêu? |
| F3-O1 | final Clean IR | IR recovery prompt + system | validation feedback | McSema/Remill, custom 010–100, O1 | Pipeline chính ở operating point nhẹ |
| F3-O2 | final Clean IR | như F3-O1 | như F3-O1 | cùng custom pass, O2 tại bốn boundary | O2 đổi structure/outcome thế nào? |
| F3-O3 | final Clean IR | như F3-O1 | như F3-O1 | cùng custom pass, O3 tại bốn boundary | O3 mạnh hơn có tốt hơn không? |

Ba corner của thiết kế 2×2 đã có:

| | One-shot | Iterative |
|---|---|---|
| Ghidra pseudocode | B0 | B1 |
| Clean IR | **còn thiếu** | F3-O1/O2/O3 |

Do thiếu `Clean IR + one-shot`, chưa thể ước lượng đầy đủ main effect của
representation và interaction giữa representation với loop.

## 2. Kiểm tra B1 có phải đối chứng hợp lệ không

Kết quả audit trên đủ 40 case:

- 40/40 Ghidra program export của B1 byte-identical với B0.
- 40/40 prompt iteration 1 của B1 byte-identical với request B0.
- 40/40 system prompt iteration 1 của B1 dài 0 byte, giống B0.
- Cùng model, temperature 0.05, location và output ceiling.
- B1 có tối đa năm provider response; B0 có đúng một.
- 0/40 first response byte-identical giữa hai campaign. Đây là sampling khác
  nhau của model, không phải input khác nhau.

Vì response đầu stochastic, B0→B1 là so sánh **hai treatment campaign**, không
phải replay cùng một candidate rồi chỉ bật loop. Ta có thể kết luận policy B1
hiệu quả hơn trong observed campaign; chưa được nói 29 case chắc chắn chỉ đổi
do loop ở mọi lần chạy. Muốn tách sampling variance cần replicate nhiều seed.

## 3. Kết quả paired và statistical boundary

### 3.1 B0 so với B1

- 29 case B0 non-PASS chuyển thành B1 PASS.
- 10 case PASS ở cả hai.
- Không có case B0 PASS chuyển thành B1 non-PASS.
- h00028 inconclusive ở cả hai, dù nguyên nhân/candidate khác nhau.
- Paired gain: +72.5 điểm phần trăm.
- Paired bootstrap 95% CI: +57.5 đến +85.0 điểm.
- Exact McNemar: `p=3.725e-9`.

Đây là evidence trực tiếp mạnh nhất rằng one-shot policy là nút thắt lớn của
baseline Ghidra trong phạm vi dataset.

### 3.2 B1 so với F3

| Comparison | B1-only PASS | F3-only PASS | Delta F3−B1 | McNemar p | Diễn giải |
|---|---:|---:|---:|---:|---|
| B1 vs O1 | 1 | 0 | −2.5 điểm | 1.0 | O1 không tạo accuracy gain; h38 bị mất trước LLM |
| B1 vs O2 | 2 | 1 | −2.5 điểm | 1.0 | O2 cứu h28 nhưng mất h22 và h38 |
| B1 vs O3 | 2 | 0 | −5.0 điểm | 0.5 | O3 mất h12 và h38; h28 vẫn non-PASS |

Các CI đều chứa 0; `n=40` không đủ nói B1 tốt hơn population-wide. Nhưng dữ
liệu đủ bác bỏ cách diễn giải rằng Clean IR đã chứng minh superior accuracy
so với một Ghidra baseline được cấp cùng loop.

### 3.3 O1, O2 và O3

- O1 và O2 cùng 38/40; h22 và h28 đổi PASS cho nhau.
- O3 đạt 37/40; mất h12 so với O1, không cứu được h28/h38.
- Mọi exact McNemar giữa O-level đều `p=1`.
- Không có evidence accuracy tăng monotonic theo optimization level.

O1 là operating point thực dụng nhất của F3 trong campaign này: cùng accuracy
O2, nhiều hơn O3 một PASS, ít request/token/runtime hơn cả hai.

## 4. B1 đã sửa gì, ở mức nhỏ nhất

Iteration 1 của B1 có phân bố:

| Outcome đầu | Số case | Thành phần con |
|---|---:|---|
| Bị parser/sanitizer reject | 26 | 12 undefined-width, 7 import thunk, 5 thiếu `main`, 1 `processEntry`, 1 syntax không cân bằng |
| Compile/link fail | 4 | 3 linker error, 1 undeclared symbol |
| Compile và được fuzz | 10 | 6 pass ngay, 4 có mismatch |

Kết quả sau loop:

- 6 PASS ngay request đầu.
- 33 PASS nhờ ít nhất một prompt chứa validation feedback.
- 31 case PASS ở response 2; hai case PASS ở response 3.
- 0 MAX_TOKENS retry; mọi extra response của B1 là validation-guided.
- h00028 dừng ở 998 match, 0 mismatch, 2 inconclusive và được giữ
  `INCONCLUSIVE`; không bị đổi thành PASS để làm đẹp số.

Loop giúp ở ba lớp khác nhau:

1. **Syntactic/decompiler repair:** chuyển type/thunk/synthetic entry thành C11
   hoàn chỉnh, nhưng vẫn bám vào Ghidra evidence.
2. **Compiler repair:** diagnostic cụ thể bắt linker symbol, undeclared name,
   warning/error mà model không tự thấy.
3. **Behavioral repair:** counterexample chỉ ra output lệch, kể cả lỗi hiếm như
   h14 có 3/1,000 mismatch rồi 2/1,000 mismatch.

Loop không monotonic: h14 cải thiện 997→998→1,000; h16 sửa artifact xong lại
tạo candidate chỉ 25/1,000 rồi mới hội tụ. Vì vậy cần giữ full trajectory,
không chỉ final candidate.

## 5. Phân tích theo tám category

`FB` là số PASS cần prompt iteration 2 trở lên; `P1` là PASS ngay response đầu.

| Category | B0 | B1 | O1 | O2 | O3 | Insight |
|---|---:|---|---:|---:|---:|---|
| arrays/windows | 2/5 | 5/5; P1=1; FB=4 | 5/5 | 5/5 | 5/5 | Cả hai representation đều đủ khi có loop; B1 cần repair nhiều hơn |
| checksums/formats | 1/5 | 5/5; P1=2; FB=3 | 4/5 | 4/5 | 4/5 | B1 tránh h38 pre-LLM failure của bundle 100 |
| data structures | 1/5 | 5/5; P1=0; FB=5 | 5/5 | 5/5 | 5/5 | Nested state khó cho first Ghidra response, nhưng feedback sửa đủ |
| graph algorithms | 1/5 | 4/5; P1=1; FB=3 | 4/5 | 5/5 | 4/5 | h28 là boundary timeout/inconclusive; O2 là flow duy nhất PASS |
| numeric/bitwise | 1/5 | 5/5; P1=0; FB=5 | 5/5 | 4/5 | 4/5 | LLVM width có ích về representation, nhưng B1 vẫn phục hồi đủ sau feedback |
| parsing/state machines | 3/5 | 5/5; P1=2; FB=3 | 5/5 | 5/5 | 5/5 | O1 Clean IR dễ nhất: 5/5 one-shot |
| strings/encodings | 1/5 | 5/5; P1=0; FB=5 | 5/5 | 5/5 | 5/5 | Ghidra cần dọn thunk/type/completeness; Clean IR O1 pass one-shot |
| structural control flow | 0/5 | 5/5; P1=0; FB=5 | 5/5 | 5/5 | 5/5 | Loop đủ cứu Ghidra, nên 0→5 không thể quy riêng cho deobfuscation pass |

Category chỉ có năm case. Chênh một case là 20 điểm phần trăm, nên bảng dùng
để tìm failure pattern chứ không phải population claim.

## 6. Toàn bộ 40 case qua năm flow

Ký hiệu `P/F/I/FC` là PASS/FAIL_BEHAVIORAL/INCONCLUSIVE/FAIL_COMPILE.
Trajectory B1 có dạng match/mismatch/inconclusive. O1/O2/O3 ở đây ghi final
status; trajectory chi tiết nằm trong `per_case_diagnostics.csv`.

### 6.1 Strings and encodings

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00001 | rolling hash + đếm chữ | I thiếu main | thiếu main → P `1000/0/0` | P/P/P | Completeness là lỗi policy; cả loop và Clean IR đều xử lý được |
| h00005 | run-length statistics | I undefined type | undefined type → P `1000/0/0` | P/P/P | Feedback đủ normalize Ghidra type |
| h00007 | base36 + FNV-like hash | P | undefined type → P `1000/0/0` | P/P/P | Cùng prompt nhưng sample mới xấu hơn B0; chứng minh cần replicate |
| h00008 | word/alnum classifier | I undefined type | thiếu main → P `1000/0/0` | P/P/P | Failure class thay đổi theo sampling, final loop ổn định hơn |
| h00024 | hex RLE + checksum | I import thunk | linker fail → P `1000/0/0` | P/P/P | Repair chuyển lỗi decompiler thành lỗi link rồi thành source đúng |

### 6.2 Numeric and bitwise

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00002 | modular accumulator | I undefined type | import thunk → P `1000/0/0` | P/P/P | LLVM width sạch hơn ban đầu, nhưng B1 loop vẫn hội tụ |
| h00011 | popcount/Gray code | I thiếu main | undefined type → P `1000/0/0` | P/P/P | B1 và F3 đều phục hồi bitwise semantics |
| h00012 | Gray-state recurrence | P | import thunk → P `1000/0/0` | P/P/F | O3 regression; higher optimization không monotonic |
| h00013 | PRNG-like recurrence | I undefined type | import thunk → P `1000/0/0` | P/P/P | Ghidra artifact repair đủ cho recurrence 64-bit này |
| h00022 | 64-bit mixers | F `4/996/0` | `0/1000/0` → P `1000/0/0` | P/F/P | Loop giúp rõ; O2 không hội tụ dù representation gần O3 |

### 6.3 Arrays and windows

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00003 | adjacent-delta statistics | I thiếu main | linker fail → P `1000/0/0` | P/P/P | Compiler diagnostic là đủ, không cần đổi representation |
| h00010 | sort + merge spans | P | `257/743/0` → P `1000/0/0` | P/P/P | Response variance lớn dù B0 đã pass cùng prompt |
| h00019 | sliding-window extrema | FC linker | undefined type → P `1000/0/0` | P/P/P | B1 sửa ở parser; F3 sửa semantic bằng counterexample |
| h00020 | state visit histogram | FC linker | undefined type → P `1000/0/0` | P/P/P | Cả compiler-aware Ghidra và Clean-IR loop đều giải quyết |
| h00023 | parity zigzag/peak | P | P1 `1000/0/0` | P/P/P | Case ổn định, pipeline phức tạp không tạo lợi ích accuracy |

### 6.4 Parsing and state machines

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00004 | command parser | P | P1 `1000/0/0` | P/P/P | Stable; O2 từng regression trong loop nhưng final pass |
| h00009 | matrix aggregates | P | undefined type → P `1000/0/0` | P/P/P | First response stochastic; loop loại variance thất bại |
| h00014 | date ordinal | P | `997/3/0` → `998/2/0` → P | P/P/P | Counterexample bắt edge ngày hiếm; repair không tức thời |
| h00017 | bounded queue machine | I import thunk | thiếu main → P `1000/0/0` | P/P/P | Clean IR one-shot; Ghidra cần completeness feedback |
| h00021 | stateful command stream | FC linker | P1 `1000/0/0` | P/P/P | B1 sample đã đúng ngay; O2 F3 cần nhiều vòng trong run riêng |

### 6.5 Structural control flow

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00006 | bracket depth/fault | I import thunk | import thunk → P `1000/0/0` | P/P/P | Loop tự sửa thunk; không còn evidence gain riêng Clean IR |
| h00015 | Horner polynomial | I import thunk | processEntry → P `1000/0/0` | P/P/P | Synthetic entry là presentation artifact, repair được |
| h00016 | sign partition | I import thunk | import thunk → `25/975/0` → P | P/P/P | Syntactic repair chưa đảm bảo semantic; fuzz round thứ hai quyết định |
| h00018 | grid walk/revisit | I thiếu main | undefined type → P `1000/0/0` | P/P/P | Cả hai loop treatment đều pass |
| h00025 | Collatz buckets | I undefined type | undefined type → P `1000/0/0` | P/P/P | F3 ba O-level đều từng cần semantic feedback; B1 sửa type rồi pass |

### 6.6 Graph algorithms

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00026 | BFS distance/signature | I undefined type | undefined type → P `1000/0/0` | P/P/P | F3 initial gần đúng; B1 sửa representation artifact rồi đúng |
| h00027 | topological sort/cycle | I import thunk | thiếu main → P `1000/0/0` | P/P/P | Loop giải quyết completeness ở cả representation |
| h00028 | grid BFS route | I thiếu main | undefined type → I `998/0/2` | F/P/F | O2 duy nhất có 1,000 verdict sạch; evaluator bảo thủ hoạt động đúng |
| h00029 | union-find | P | P1 `1000/0/0` | P/P/P | Stable ở cả năm flow |
| h00030 | Floyd–Warshall | I import thunk | linker fail → P `1000/0/0` | P/P/P | B1 compiler repair nhanh; F3 từng bắt rare semantic bug |

### 6.7 Data structures

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00031 | LRU-like cache | I import thunk | thiếu main → P `1000/0/0` | P/P/P | B1 sửa completeness; F3 bắt rare replacement-order bug |
| h00032 | bracket stack | I syntax | syntax không cân bằng → P `1000/0/0` | P/P/P | Parser/compiler gate là contribution trực tiếp |
| h00033 | min-heap | P | undefined type → P `1000/0/0` | P/P/P | B0/B1 sample variance; final đều đúng |
| h00034 | word dictionary | I thiếu main | undeclared symbol → P `1000/0/0` | P/P/P | Compiler feedback cụ thể đủ cứu B1 |
| h00035 | interval merge | F `722/278/0` | `728/272/0` → P `1000/0/0` | P/P/P | Hai one-shot campaign sai gần giống; loop là khác biệt quyết định |

### 6.8 Checksums and structured formats

| Case | Nội dung | B0 | B1 iteration 1 → final | O1/O2/O3 | Insight năm-flow |
|---|---|---|---|---|---|
| h00036 | CRC-like stream | I undefined type | import thunk → P `1000/0/0` | P/P/P | Feedback phục hồi source đúng ở cả Ghidra và F3 |
| h00037 | base32 + checksum | FC symbol | P1 `1000/0/0` | P/P/P | Stochastic first output B1 tốt hơn B0; không quy cho loop riêng case này |
| h00038 | date span/pivot | P | P1 `1000/0/0` | I/I/I | B1 thắng vì bundle 100 làm mất `main` trước LLM ở cả F3 |
| h00039 | packet fields | I import thunk | undefined type → P `1000/0/0` | P/P/P | Artifact class đổi nhưng validation-guided repair hội tụ |
| h00040 | key=value map | F `0/1000/0` | import thunk → P `1000/0/0` | P/P/P | B1 sửa presentation artifact; O1 từng cần semantic counterexample |

## 7. Mỗi khối giúp gì và làm hại gì sau khi có B1

| Khối | Điều đã quan sát khối giúp | Failure/cost | Attribution hiện tại |
|---|---|---|---|
| Own dataset | Giảm khả năng nhớ exact source–binary; paired 40 case | Model vẫn biết thuật toán/idiom | Provenance mạnh, không phải contamination-free |
| Own obfuscator | Tạo cùng challenge instsub+fla+bcf cho mọi flow | Một recipe, x86-64, CLI nhỏ | Internal validity tốt; external validity hẹp |
| Ghidra export | B1 chứng minh evidence đủ để đạt 39/40 khi có loop | Initial response thường còn type/thunk/noise | Representation không phải failure duy nhất của B0 |
| B0 one-shot | Baseline paper-derived và audit được | Không sửa 30 failure | Baseline hợp lệ nhưng policy yếu cho artifact thực tế |
| B1 parser feedback | Sửa 25/26 precompile-rejected case thành PASS; h28 thành I | Có thể tạo lỗi mới ở candidate sau | Effect quan sát rất lớn |
| B1 compiler feedback | 4/4 initial compile failure thành PASS | Chỉ bắt lỗi build, không bảo đảm semantics | Direct evidence mạnh |
| B1 behavioral feedback | 4/4 initial fuzz failure thành PASS | Non-monotonic; cần thêm execution | Direct evidence mạnh |
| McSema/Remill | Cho exact width/data-flow và artifact để custom pass phân tích | Raw IR noisy, guest/native mismatch | Implemented value; chưa có isolated E2E effect |
| Custom 010–095 | Giảm control/state noise; proof/refusal report audit được | Thiếu leave-one-pass-out; 10 deflatten unresolved | Không được gán effect size accuracy riêng từng pass |
| Standard O1/O2/O3 | Dọn pattern custom pass expose | O2/O3 giảm thêm rất ít, không tăng PASS | O1 đủ cho operating point hiện tại |
| Bundle 100 | Tạo một final artifact thống nhất cho LLM | h38 mất `main`; clean executable chỉ 15/40 pass | Pre-LLM single point of failure rõ ràng |
| F3 initial prompt | O1 one-shot tốt ở strings/parsing; output ngắn | Input context lớn; MAX_TOKENS 5/5/10 | Có lợi về abstraction/candidate compactness, không chứng minh accuracy hơn B1 |
| Sanitizer/compiler | Biến lỗi source thành diagnostic tái sử dụng | Một compile pass không bắt semantic bug | Thành phần cần thiết của loop |
| AFL++ + input contract | Bắt mismatch hiếm và giữ input trong domain | Chỉ 1,000 input; phụ thuộc contract | Empirical evidence, không formal proof |
| Conservative evaluator | Không gọi h28 là PASS khi còn inconclusive | Làm headline thấp hơn | Tăng độ tin cậy, không phải weakness |

## 8. Optimization cụ thể đã làm gì

Standard optimizer được áp dụng tại bốn boundary frozen trong F3, không áp
dụng tùy ý sau khi thấy kết quả. Từ raw lift tới final Clean IR:

| Metric trung bình | Raw | O1 final | O2 final | O3 final | Reduction O1 | Reduction O2/O3 |
|---|---:|---:|---:|---:|---:|---:|
| Instructions | 1,445.025 | 675.100 | 667.800 | 667.800 | 53.28% | 53.79% |
| Basic blocks | 136.275 | 44.775 | 44.700 | 44.700 | 67.14% | 67.20% |
| Conditional branches | 49.800 | 4.025 | 4.025 | 4.025 | 91.92% | 91.92% |

O2/O3 chỉ giảm thêm 7.3 instruction trung bình so với O1, gần như không đổi
block/branch. O2 và O3 có structural mean giống nhau nhưng final outcome/cost
khác nhau, nên khác biệt đó chủ yếu phản ánh model sampling/loop trajectory,
không phải một structure gain rõ của O3.

Pass 095 trên mỗi treatment ghi nhận 984 Z3 query, 520 proved; 152/152 MBA
candidate được rewrite và 536 BCF rewrite. Disproved/unknown được giữ nguyên.
Đây là evidence cho proof-oriented transformation, nhưng không phải chứng minh
rằng riêng pass 095 tăng LLM accuracy.

## 9. Cost và efficiency

| Flow | Provider response | Input token | Output token | Mean recorded runtime/case |
|---|---:|---:|---:|---:|
| B0 | 40 | 731,561 | 142,369 | 23.04 s |
| B1 | 76 | 1,484,419 | 181,284 | 31.75 s |
| F3-O1 | 60 | 3,851,372 | 42,172 | 56.66 s |
| F3-O2 | 65 | 3,994,570 | 45,719 | 58.23 s |
| F3-O3 | 72 | 4,390,944 | 61,638 | 65.66 s |

B1 dùng nhiều provider response hơn O1 26.7%, nhưng chỉ 38.5% input token và
56.0% recorded runtime; output token lại cao gấp 4.30 lần. F3 cung cấp evidence
dài nhưng model thường sinh source ngắn hơn. Đây là trade-off representation,
không có một flow thắng mọi cost dimension.

## 10. Đóng góp phải viết lại như thế nào

### Có thể bảo vệ bằng dữ liệu hiện tại

1. Một validation-guided recovery protocol kết hợp parser, compiler và
   differential counterexample đã tăng Ghidra treatment từ 10/40 lên 39/40
   trong observed campaign.
2. Một Clean-IR transformation pipeline 010–100 có proof/refusal boundaries,
   stage metrics và artifact audit; F3-O1 đạt 38/40.
3. Phân tích O-level chỉ ra tối ưu mạnh hơn không đồng nghĩa recovery tốt hơn;
   O1 là operating point hiệu quả nhất của F3.
4. Một dataset 40 C11 program tự xây, frozen source/binary/oracle/input
   contract giúp giảm exact benchmark contamination.

### Chỉ nên viết ở mức vừa phải

- Clean IR làm representation có cấu trúc hơn, giúp audit transformation và
  nhiều case one-shot; nhưng chưa chứng minh E2E accuracy hơn Ghidra+loop.
- B0→B1 nhất quán với effect mạnh của loop; do hai campaign sample response
  riêng, cần replicate để ước lượng variance.

### Không được viết

- “F3 tốt hơn mọi Ghidra baseline” — B1 đang 39/40, cao hơn F3 campaign.
- “Gain 70 điểm hoàn toàn do deobfuscation/optimization” — B1 bác bỏ cách gán
  đó.
- “O3 tốt nhất vì tối ưu mạnh nhất” — O3 có accuracy/cost xấu nhất trong F3.
- “Clean IR đã được chứng minh tương đương executable” — prepared validation
  chỉ 15 PASS, 24 FAIL, 1 INCONCLUSIVE mỗi O-level.
- “Final IR fully native” — 117/117 report hiện là `compat_runnable` và
  non-compliant.
- “1,000/1,000 là formal equivalence” — chỉ là bounded empirical validation.
- “Dataset chắc chắn model chưa từng biết” — chỉ giảm exact contamination.

## 11. Còn thiếu gì sau khi thêm B1

Theo ưu tiên:

1. **Clean IR + one-shot:** corner cuối của 2×2; đây là experiment quan trọng
   nhất để tách representation effect.
2. **Replicate 3–5 lần mỗi treatment:** đo pass probability/case và sampling
   variance; h7, h10, h14, h22 cho thấy first response biến động mạnh.
3. **Leave-one-pass-out/grouped ablation:** định lượng 010/020/030/... giúp hay
   hại ở đâu; stage metrics hiện chỉ mô tả structure.
4. **Sửa h38 bằng campaign mới:** không sửa artifact frozen; chạy ID mới để đo
   bundle-100 ceiling sau fix.
5. **Độc lập baseline/tool comparison:** thêm decompiler/model/research flow
   khác nếu claim state-of-the-art, không chỉ paper-prompt B0.
6. **Mở rộng external validity:** compiler/architecture/obfuscator/program size
   và model family khác.

## 12. Câu kết luận dùng được trong luận văn

> Trên 40 chương trình C11 tự xây, Ghidra one-shot đạt 10/40 canonical E2E
> PASS. Khi giữ byte-identical Ghidra representation và request đầu nhưng thêm
> tối đa năm vòng parser/compiler/differential-feedback, treatment B1 đạt
> 39/40. Clean-IR O1/O2/O3 lần lượt đạt 38/40, 38/40 và 37/40. Kết quả cho thấy
> validation loop là nguồn gain quan sát mạnh nhất; Clean IR cung cấp một
> representation có cấu trúc và audit được nhưng chưa chứng minh accuracy gain
> so với Ghidra+loop. O1 là F3 operating point hiệu quả nhất, còn higher
> optimization không tạo cải thiện monotonic.

## 13. Artifact audit

- `reports/final_five_treatments_20260816/final_analysis.json`: năm flow, mười
  paired comparison, CI, McNemar, stage/pass095/native aggregate.
- `reports/final_five_treatments_20260816/per_case_diagnostics.csv`: 200 dòng
  case–treatment, iteration-1 outcome, trajectory, call/token/runtime và native
  fields.
- `reports/final_five_treatments_20260816/category_diagnostics.csv`: tám nhóm ×
  năm flow.
- `reports/final_five_treatments_20260816/paired_comparisons.csv`: toàn bộ 10
  pairwise comparison.
- `result/b1_final_20260816/<case>/B1/`: prompt/response từng vòng,
  parser/compiler/fuzz artifact và final candidate.
- `docs/exhaustive-block-analysis.md`: mô tả implementation chi tiết từng pass
  010–100, AFL++ oracle và native-contract gate.
