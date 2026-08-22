# Phân tích cuối: bảy treatment B0–B3 và F3-O1/O2/O3

> **Historical snapshot.** This seven-treatment report predates the active
> five-flow taxonomy. Do not read `F3-O1/O2/O3` as current flow IDs; use
> [`research-evaluation-protocol.md`](research-evaluation-protocol.md) for the
> active `B1/B2/F1/F2/F3` contracts.

## 1. Kết quả trả lời trực tiếp câu hỏi nghiên cứu

Trên 40 chương trình C11 CLI tự xây, paired theo case và chấm bằng 1,000 input
hợp lệ/case:

| Treatment | Evidence đưa vào LLM | Feedback | PASS | Calls | Input tokens | Mean runtime |
|---|---|---|---:|---:|---:|---:|
| B0 | Ghidra program pseudocode | one-shot | 10/40 (25.0%) | 40 | 731,561 | 23.04 s |
| B1 | đúng Ghidra của B0 | tối đa 5 response | 39/40 (97.5%) | 76 | 1,484,419 | 31.75 s |
| B2 | raw `objdump -d` assembly | one-shot | 6/40 (15.0%) | 40 | 714,474 | 11.48 s |
| B3 | đúng assembly của B2 | tối đa 5 response | 38/40 (95.0%) | 93 | 2,708,225 | 52.36 s |
| F3-O1 | Clean LLVM IR O1 | tối đa 5 response | 38/40 (95.0%) | 60 | 3,851,372 | 56.66 s |
| F3-O2 | Clean LLVM IR O2 | tối đa 5 response | 38/40 (95.0%) | 65 | 3,994,570 | 58.23 s |
| F3-O3 | Clean LLVM IR O3 | tối đa 5 response | 37/40 (92.5%) | 72 | 4,390,944 | 65.66 s |

Kết luận attribution mạnh nhất không phải “ghép nhiều tool nên tốt”, mà là:

1. **Validation-guided feedback là effect lớn nhất đã được cô lập.** B0→B1
   tăng 72.5 điểm phần trăm; B2→B3 tăng 80 điểm.
2. **Raw assembly one-shot không phải baseline yếu giả tạo do Ghidra.** B2 chỉ
   đạt 15%, thấp hơn B0 10 điểm nhưng CI chứa 0.
3. **Khi đều có loop, representation không tạo khác biệt E2E rõ trên n=40.**
   B1=97.5%, B3=95%, F3-O1/O2=95%; các paired CI chứa 0.
4. **Giá trị riêng của F3 hiện là structured/auditable deobfuscation và một
   operating point tốt, không phải superiority về accuracy đã chứng minh.**
5. **Optimization không monotonic:** O1=O2=95%, O3=92.5%. Chi tiết IR giải
   thích vì sao nằm ở `optimization-ir-boundary-analysis.md`.

Không có fine-tuning, LoRA/adapter, RAG hay thay đổi model weight. LLM dùng
chung là `ag/gemini-3-flash-agent`; đóng góp nằm ở representation, LLVM
transformations, orchestration, validation và failure-preserving evaluation.

## 2. Bảy treatment thực sự kiểm soát gì

| Flow | Path | First request | Request sau | Vai trò |
|---|---|---|---|---|
| B0 | ELF gốc → Ghidra | paper-derived Ghidra prompt, no system | không có | pseudocode one-shot baseline |
| B1 | cùng ELF/export B0 | byte-identical B0 | parser/compiler/counterexample | ablation loop trên Ghidra |
| B2 | ELF gốc → `objdump -d` → cleaner | exact assembly wrapper công bố bởi LLM4Decompile, no system | không có | raw-assembly one-shot baseline |
| B3 | cùng ELF/assembly B2 | byte-identical B2 | parser/compiler/counterexample | ablation loop trên assembly |
| F3-O1 | ELF → lift → custom 010–100/O1 | Clean-IR prompt/system | validation feedback | phương pháp chính, optimizer nhẹ |
| F3-O2 | cùng pipeline, thay 4 biên bằng O2 | như O1 | như O1 | optimization treatment |
| F3-O3 | cùng pipeline, thay 4 biên bằng O3 | như O1 | như O1 | optimization treatment mạnh |

B2 lấy template End2End công bố trong
[LLM4Decompile](https://arxiv.org/html/2403.05286v3): disassemble bằng objdump,
đưa assembly vào `# This is the assembly code: ... # What is the source code?`.
Cleaner cũng theo [repository chính thức](https://github.com/albertan017/LLM4Decompile):
bỏ address, byte column và comment. Paper đánh giá function-level và model đã
fine-tune; thí nghiệm này mở rộng thành whole-program assembly vì oracle là CLI
program có helper. Vì model khác và không fine-tune, B2 là **paper-derived
baseline**, không phải reproduction score của LLM4Decompile-End. B3 là ablation
do nhóm thiết kế, không phải flow được paper công bố.

Thiết kế factorial hiện có ba representation, nhưng còn thiếu `Clean IR +
one-shot`. Vì vậy B0/B1 và B2/B3 cô lập feedback policy; B1/B3/F3 so sánh hệ
thống hoàn chỉnh nhưng chưa cô lập tuyệt đối main effect của Clean IR.

## 3. Kiểm soát B0/B1 và B2/B3

### 3.1 Ghidra pair

- 40/40 representation byte-identical.
- 40/40 prompt đầu byte-identical và system prompt đầu rỗng.
- B0 đúng một response; B1 tối đa năm.
- First response chạy độc lập nên 0/40 byte-identical: đây là stochastic
  sampling, không phải input khác.

### 3.2 Assembly pair

- 40/40 cleaned assembly byte-identical.
- 40/40 prompt đầu byte-identical.
- 40/40 B2 và 40/40 B3 có initial system prompt rỗng.
- B2 đúng một response; B3 tối đa năm.
- 0/40 first response byte-identical do hai campaign gọi provider riêng.
- Không thiếu artifact kiểm soát.

Do đó có thể nói treatment policy có hiệu quả trong observed campaigns. Chưa
được nói mỗi case chắc chắn đổi chỉ do loop ở mọi seed; muốn đo sampling
variance cần lặp nhiều campaign/model seed.

## 4. Paired effect và statistical boundary

| Comparison | Left-only PASS | Right-only PASS | Delta right-left | Bootstrap 95% CI | McNemar p |
|---|---:|---:|---:|---:|---:|
| B0 → B1 | 0 | 29 | +72.5 pp | +57.5..+85.0 | 3.725e-9 |
| B2 → B3 | 0 | 32 | +80.0 pp | +67.5..+92.5 | 4.657e-10 |
| B0 → B2 | 8 | 4 | -10.0 pp | -27.5..+7.5 | 0.3877 |
| B1 → B3 | 2 | 1 | -2.5 pp | -10.0..+5.0 | 1.0 |
| B3 → F3-O1 | 2 | 2 | 0.0 pp | -10.0..+10.0 | 1.0 |
| B3 → F3-O2 | 2 | 2 | 0.0 pp | -10.0..+10.0 | 1.0 |
| B3 → F3-O3 | 3 | 2 | -2.5 pp | -12.5..+7.5 | 1.0 |

Hai pair one-shot→loop đều lớn, cùng chiều và không có reverse PASS→FAIL.
Ngược lại, các representation iterative chỉ lệch 0–2.5 điểm với CI rộng. Đây
là evidence rằng **khả năng quan sát lỗi và sửa lại quan trọng hơn việc chọn
Ghidra/assembly/Clean IR** trong phạm vi chương trình này.

## 5. B2 và B3 cho biết gì về raw assembly

B2 kết thúc với 6 PASS, 32 behavioral fail và 2 compile fail. Khác B0, assembly
không tạo nhiều pseudo-type/import-thunk reject; nó thường tạo C compile được
nhưng đoán sai semantic. Nghĩa là raw ISA evidence chính xác về instruction,
nhưng thiếu abstraction về variable, loop, signedness intent và program
structure.

B3 kết thúc 38 PASS và 2 behavioral fail:

- 5 case PASS ở response đầu;
- 33 case PASS sau validation feedback;
- 25 case dùng 2 calls, 5 dùng 1, 5 dùng 3, 2 dùng 4 và 3 dùng đủ 5;
- 4 response là retry do `MAX_TOKENS`, không được đếm là feedback-assisted;
- hai failure cuối là `h00021` và `h00037`.

Trajectory cho thấy loop không monotonic:

- `h00021`: candidate từng đạt 691/1,000, sau retry/correction lại về 0/1,000;
  output truncation tiêu tốn call budget.
- `h00037`: 0/1,000 → 0/1,000 → 884/1,000 → 999/1,000 → 0/1,000. Candidate
  tốt nhất gần đúng nhưng policy giữ final candidate cuối, nên fail.

Insight thiết kế: nên checkpoint “best validated candidate” và tách provider
truncation retry khỏi semantic repair budget. Tuy nhiên không được retroactively
đổi headline bằng best-of-trajectory nếu protocol đăng ký final candidate.

## 6. Kết quả theo category

| Category (5 case) | B0 | B1 | B2 | B3 | O1 | O2 | O3 |
|---|---:|---:|---:|---:|---:|---:|---:|
| arrays/windows | 2 | 5 | 1 | 5 | 5 | 5 | 5 |
| checksums/formats | 1 | 5 | 0 | 4 | 4 | 4 | 4 |
| data structures | 1 | 5 | 0 | 5 | 5 | 5 | 5 |
| graph algorithms | 1 | 4 | 0 | 5 | 4 | 5 | 4 |
| numeric/bitwise | 1 | 5 | 1 | 5 | 5 | 4 | 4 |
| parsing/state machine | 3 | 5 | 1 | 4 | 5 | 5 | 5 |
| strings/encodings | 1 | 5 | 1 | 5 | 5 | 5 | 5 |
| structural control flow | 0 | 5 | 2 | 5 | 5 | 5 | 5 |

Mỗi category chỉ có năm case nên chênh một case tương ứng 20 điểm phần trăm.
Bảng dùng để tìm pattern failure, không dùng để claim population superiority.

Các pattern đáng giữ:

- One-shot raw assembly tệ nhất ở data structures, graph và checksums: evidence
  instruction-level chưa tự tạo được abstraction/state invariant.
- Với counterexample, assembly đạt 5/5 ở structural control flow. Vì vậy không
  được quy toàn bộ gain structural của F3 riêng cho deflatten pass.
- O2 là flow duy nhất PASS đủ graph 5/5, nhưng mất một numeric case; optimization
  chuyển failure giữa case chứ không tăng tổng.
- Checksums còn 4/5 ở B3 và cả ba F3: đây là nhóm cần thêm targeted fixtures và
  counterexample strategy, không phải chọn O level cao hơn.

## 7. Từng khối nhỏ giúp gì, hại gì

| Khối | Implemented | Observed | Điều chưa được phép claim |
|---|---|---|---|
| Own dataset/provenance | 40 exact C11 mới, source/seed/oracle hash frozen, không vào prompt | paired 40 case, giảm khả năng nhớ exact answer | zero contamination; model vẫn có kiến thức thuật toán |
| Public IR set | 40 public programs khác phân bố | O2/O3 khác mạnh, bác kết luận từ một set | LLM generalization/contamination-safe accuracy |
| Obfuscator | cùng recipe instsub+fla+bcf | paired challenge đồng nhất | tổng quát mọi obfuscator/architecture |
| Ghidra exporter | deterministic whole-program pseudocode | B1 39/40, evidence đủ khi có repair | pseudocode tự nó tốt hơn mọi representation |
| Assembly exporter | `objdump -d`, bỏ address/bytes/comments, giữ functions | B2 6/40; B3 38/40 | reproduction model/score của paper |
| McSema/Remill lift | giữ width, State, guest-memory/data flow | tạo IR cho rule/proof và audit | accuracy gain riêng khi chưa ablate lifting |
| Pass 010 | bỏ poison-producing flags sai, sửa exact lifted patterns | downstream optimizer chạy trên semantics bảo thủ hơn | E2E effect size riêng |
| Pass 015 | materialize runtime/helper semantics khi whitelist | helper trở thành load/store/call analyzable | mọi Remill helper đều được native hóa |
| Pass 020 | devirtualize target có proof, giữ unresolved | giảm indirect target ambiguity | mọi call graph đã phục hồi hoàn chỉnh |
| Pass 030 | State/register sang SSA khi ownership chứng minh | 095 report ghi 9,954 register-state changes | 9,954 changes đồng nghĩa 9,954 correctness gains |
| Pass 040 | recover frame/local storage có provenance | tạo alloca/GEP để LLVM SROA | full source local-variable recovery |
| Pass 050 | recover ABI theo callsite/proof | cho interprocedural propagation | ABI hoàn toàn native; native report chưa đạt |
| Pass 060 | bridge external libc calls | C-facing call dễ đọc hơn | mọi external effect đã model đầy đủ |
| Pass 070 | recover globals/strings có evidence | expose format/global objects | exact original symbol/type names |
| Pass 080 | reconstruct width/aggregate shape | type evidence rõ hơn raw assembly | original typedef/struct identity |
| Pass 090 | native/state/frame cleanup theo refusal boundary | consumer quan trọng trước/sau O boundaries | clean IR hoàn toàn native |
| Pass 095 MBA | bounded pattern/Z3 proof | 152/152 candidate changed | từng change tạo E2E PASS |
| Pass 095 BCF | prove/refute opaque predicate | 536 changes/763 candidates; 520 Z3 proof, 458 disproof, 6 unknown ở O2/O3 | xóa predicate khi solver unknown |
| Pass 095 deflatten | rewrite khi đủ region/state proof | 11 changes, 10 unresolved | full CFF recovery |
| Standard O1 | conservative scalar cleanup/inlining | 38/40, ít calls/runtime nhất F3 | ít optimize luôn dễ đọc hơn cho mọi program |
| Standard O2 | thêm GVN/DSE/speculation/CFG cleanup | xóa memory/store mạnh; 38/40 | IR nhỏ hơn chắc chắn tăng LLM accuracy |
| Standard O3 | thêm scalar/CFG specialization | public tạo block/PHI/branch; 37/40 | level cao hơn deobfuscate tốt hơn |
| Bundle exact cleanup | SCCP/instcombine/DCE/simplifycfg trước O3 | giảm instruction/PHI riêng | gán số này cho `default<O*>` |
| Storage delift | script pattern rewrite | 240/240 runs no-op | contribution trên dataset hiện tại |
| Residual strip | xóa marker nếu còn | 240/240 runs no-op | contribution trên dataset hiện tại |
| Bundle final cleanup | internalize/IPSCCP/deadargelim/global/native cleanup | xóa phần memory/ABI còn lại, nhất là O1 | semantic correctness nếu không differential test |
| Sanitizer/parser | reject incomplete/unsafe artifact | biến lỗi thành repair signal | semantic oracle |
| Compiler | exact syntax/type/link diagnostics | sửa compile failures | behavioral equivalence |
| Differential runner | so tuple stdout/stderr/exit/signal/timeout trên valid inputs | bắt rare mismatch và tạo counterexample | formal proof; chỉ “no divergence found” |
| Input contracts | giữ mutation trong domain có nghĩa | giảm false failure từ invalid input | bao phủ toàn input space |

Pass 095 aggregate gần như giống ở ba level vì nó chạy trước optimizer treatment
chính: 984 query/level; 520 proved; O1 có 456 disproved/8 unknown, O2/O3 có
458/6; 152 MBA changes, 536 BCF changes, 11 deflatten changes và 10 unresolved.
Đây là bằng chứng pass thực sự kích hoạt, nhưng chưa phải causal accuracy
ablation. Muốn nói pass nào làm tăng bao nhiêu PASS phải chạy leave-one-pass-out
trên cùng 40 case.

## 8. Vì sao một dataset là không đủ

Own set là đúng lựa chọn cho LLM headline vì exact source được tạo và freeze
ngoài public corpus. Nhưng own set nhỏ khiến O2/O3 nhìn gần như giống nhau về
tổng opcode. Khi chạy thêm 40 public programs:

- O2/O3 chỉ structurally identical 1/40 sau main boundary đầu và 2/40 ở bundle,
  so với 26/40 và 29/40 trên own set;
- O3 bundle tạo ròng 8 block, 15 PHI và 27 conditional branches, trong khi O2
  giảm 35 block và 38 PHI;
- O2 final public IR trung bình nhỏ hơn O3 cả instruction lẫn block.

Vì vậy thí nghiệm được chia đúng claim:

- **LLM behavioral evaluation:** own dataset primary;
- **IR transformation generality:** own + public;
- **public LLM accuracy:** không dùng để phản biện contamination.

## 9. Native/semantic limitation phải ghi rõ

Prepared Clean-IR binary validation ở cả O1/O2/O3 chỉ đạt 15 PASS, 24 FAIL và
1 inconclusive. Có 117 report thuộc lớp `compat_runnable`, không phải fully
native. Điều này không phủ định 38/40 recovered-C behavioral result vì hai phép
đo khác nhau, nhưng nó giới hạn claim:

- được nói F3 tạo IR đủ để làm evidence cho LLM và compile qua compatibility
  path;
- chưa được nói pipeline đã luôn phục hồi fully-native IR hoặc binary tương
  đương độc lập runtime;
- native-contract failure phải là research target riêng, không được ẩn sau E2E
  recovered-C score.

## 10. Đóng góp nên viết trong luận văn

Đóng góp hợp lý, theo mức evidence hiện có:

1. Một protocol bảy treatment tách representation và validation policy, gồm
   hai baseline paper-derived và hai paired loop ablation.
2. Dataset 40 C11 CLI tự xây/frozen để giảm exact-answer contamination, cộng
   public set thứ hai cho IR generality.
3. Chuỗi deobfuscation có proof/refusal boundary và artifact per-pass, đặc biệt
   MBA/BCF/deflatten/State cleanup, thay vì chỉ gọi tool như black box.
4. Instrumentation bốn optimizer boundary cho biết O1/O2/O3 đổi opcode/CFG ở
   đâu; O2 là structural sweet spot, O3 không monotonic.
5. Validation-guided repair dùng parser/compiler/reproducible counterexample,
   được chứng minh là effect lớn nhất ở cả Ghidra và assembly representation.
6. Failure-preserving evaluation: compile failure, inconclusive, MAX_TOKENS,
   native-contract và no-op stage đều giữ trong report thay vì lọc khỏi mẫu số.

Không nên viết đóng góp là “kết hợp McSema + LLVM + LLM + AFL++”. Đó là mô tả
kiến trúc. Contribution khoa học nằm ở controlled ablation, proof/refusal rules,
boundary-level measurement và insight về điều kiện giúp/hại.

## 11. Việc còn thiếu để claim mạnh hơn

1. Thêm `Clean IR one-shot` để hoàn tất representation × feedback factorial.
2. Lặp mỗi treatment nhiều seed/campaign để ước lượng stochastic variance.
3. Leave-one-pass-out cho 010–095; targeted fixture kích hoạt hai script no-op.
4. Mở rộng own dataset sang nhiều compiler/architecture/obfuscator strength.
5. Tăng behavioral budget và thêm formal/symbolic checking cho case quan trọng.
6. Sửa B3 policy để checkpoint best candidate và tách truncation retry budget,
   rồi đăng ký protocol mới trước khi rerun.
7. Tách fully-native contract thành objective riêng và giảm 117
   `compat_runnable` reports.

## 12. Artifact chính

- `reports/final_seven_treatments_20260816/final_analysis.json`
- `reports/final_seven_treatments_20260816/per_case_matrix.csv`
- `reports/final_seven_treatments_20260816/paired_comparisons.csv`
- `reports/final_seven_treatments_20260816/category_results.csv`
- `reports/ir_boundary_own_20260816/optimization_boundary_analysis.json`
- `reports/ir_boundary_public_20260816/optimization_boundary_analysis.json`
- `docs/optimization-ir-boundary-analysis.md`
- `case_studies/h00035/README.md`: case hoàn chỉnh từ source, obfuscation,
  Ghidra/assembly, raw/Clean IR, pass 095, O-boundary, LLM loop đến validation.
