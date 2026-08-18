# Kết quả cuối và đúc kết từ quá trình thực nghiệm

> **Superseded:** đây là snapshot bốn treatment. Kết quả authoritative của bảy
> treatment nằm ở `docs/seven-treatment-analysis.md`; phân tích optimizer theo
> từng biên IR nằm ở `docs/optimization-ir-boundary-analysis.md`.

Phân tích xuống từng block/pass/category và đủ 40 case nằm trong
[`exhaustive-block-analysis.md`](exhaustive-block-analysis.md). Tài liệu hiện
tại giữ vai trò bản thảo luận kết quả rút gọn.

## 1. Phạm vi kết quả được sử dụng

Báo cáo này chỉ sử dụng bốn campaign đã khóa cấu hình và chạy trên cùng 40
chương trình C11 trong `own_dataset`:

| Treatment | Campaign | Vai trò |
|---|---|---|
| B0 | `twoflow_20260815_213257` | Ghidra pseudocode + prompt LLM4Decompile, đúng một request, không feedback |
| F3-O1 | `f3_o1_final_20260815` | Clean IR ở O1 + recovery loop |
| F3-O2 | `f3_o2_final_20260815` | Clean IR ở O2 + recovery loop |
| F3-O3 | `f3_o3_final_20260815` | Clean IR ở O3 + recovery loop |

Các pilot/campaign bị truncation hoặc dùng protocol cũ không được gộp vào kết
quả. Cả bốn treatment dùng cùng model `ag/gemini-3-flash-agent`, temperature
0.05, output budget 65,535 token và cùng phép kiểm tra 1,000 input hợp lệ cho
mỗi candidate. Source gốc chỉ được dùng làm oracle và tạo input contract; nó
không được đưa vào prompt.

## 2. Kết quả chính

| Treatment | PASS | Tỷ lệ | 95% Wilson CI | Request trung bình/ca | Input token trung bình/ca |
|---|---:|---:|---:|---:|---:|
| B0 | 10/40 | 25.0% | 14.2–40.2% | 1.000 | 18,289 |
| F3-O1 | 38/40 | 95.0% | 83.5–98.6% | 1.500 | 96,284 |
| F3-O2 | 38/40 | 95.0% | 83.5–98.6% | 1.625 | 99,864 |
| F3-O3 | 37/40 | 92.5% | 80.1–97.4% | 1.800 | 109,774 |

F3-O1 tăng tuyệt đối 70 điểm phần trăm so với B0 trên các cặp chương trình
tương ứng. Paired bootstrap 95% CI của mức tăng là 52.5–85.0 điểm phần trăm;
exact McNemar `p = 5.77e-8`. Đây là bằng chứng mạnh cho **toàn bộ F3** so với
baseline one-shot, không phải bằng chứng riêng cho một pass hoặc riêng cho
feedback loop.

Trạng thái chi tiết:

- B0: 10 PASS, 4 FAIL_COMPILE, 3 FAIL_BEHAVIORAL và 23 INCONCLUSIVE.
- F3-O1: 38 PASS, 1 FAIL_BEHAVIORAL và 1 INCONCLUSIVE.
- F3-O2: 38 PASS, 1 FAIL_BEHAVIORAL và 1 INCONCLUSIVE.
- F3-O3: 37 PASS, 2 FAIL_BEHAVIORAL và 1 INCONCLUSIVE.

## 3. Optimization đã giúp gì?

Chuỗi pass không được dùng như một lệnh `opt -O3` duy nhất. Nó được dùng để
đưa lifted IR qua các checkpoint: sửa IR, materialize runtime semantics,
devirtualize control flow, chuyển State sang SSA, phục hồi stack/ABI/global,
bridge external call, native cleanup, standard LLVM optimization, delift
storage và strip phần dư. Rewrite chỉ được áp dụng khi thỏa điều kiện an toàn;
trường hợp ngoài proof boundary được giữ nguyên hoặc bị từ chối.

Trung bình trên 40 ca, từ `raw_lift` đến `final_clean`:

| Treatment | Instruction giảm | Basic block giảm | Conditional branch giảm |
|---|---:|---:|---:|
| F3-O1 | 53.28% | 67.14% | 91.92% |
| F3-O2 | 53.79% | 67.20% | 91.92% |
| F3-O3 | 53.79% | 67.20% | 91.92% |

Insight chính không phải “O càng cao càng tốt”. Phần giảm lớn nhất đã xuất
hiện trước/sát standard optimization: raw IR trung bình có 1,445 instruction,
136 block và 49.8 nhánh điều kiện; final O1 còn 675 instruction, 44.8 block và
4.0 nhánh. Việc loại phần lớn dispatcher/State/runtime noise tạo evidence ngắn
và gần cấu trúc chương trình hơn cho LLM.

O2/O3 chỉ giảm thêm khoảng 7.3 instruction so với O1 ở final IR, tức khoảng
0.5% của raw IR. O2 và O3 còn có cùng số đo cấu trúc trung bình; 30/40 final IR
của hai mức giống hệt byte-for-byte, 10/40 khác nội dung nhưng không tạo lợi
thế pass rate cho O3. Vì vậy, standard optimization mạnh hơn sau khi đã
brighten có lợi ích biên rất nhỏ trên bộ dữ liệu này.

## 4. Feedback loop đã giúp gì?

Không nên dùng tổng số ca có nhiều response để tuyên bố loop hiệu quả, vì một
response thêm có thể chỉ là retry do `MAX_TOKENS`. Sau khi tách retry kỹ thuật
khỏi compiler/counterexample feedback, số ca cuối cùng PASS nhờ feedback là:

| Treatment | PASS nhờ feedback | Response `MAX_TOKENS` |
|---|---:|---:|
| F3-O1 | 11 | 5 |
| F3-O2 | 14 | 5 |
| F3-O3 | 14 | 10 |

Các case cho thấy loop hữu ích ở hai tình huống:

1. **Sai hoàn toàn nhưng lỗi có pattern rõ.** Ví dụ h00020 ở O2 và O3 đi từ
   0/1,000 lên 1,000/1,000 sau feedback. h00036 ở O1 đi từ 0/1,000 lên
   1,000/1,000.
2. **Sai hiếm ở edge case.** h00030-O1 ban đầu đạt 997/1,000 nhưng ba
   counterexample vẫn phát hiện lỗi. Candidate sau còn tụt xuống 983/1,000
   trước khi đạt 1,000/1,000. h00031-O1 tương tự: 996/1,000 → 923/1,000 →
   1,000/1,000. Vì vậy, accuracy gần 100% của một candidate chưa đủ để dừng.

Loop cũng không bảo đảm hội tụ. h00022-O2 giữ nguyên 0/1,000 qua bốn candidate;
một response khác bị `MAX_TOKENS`, nên hết giới hạn năm provider response và
ca này FAIL_BEHAVIORAL. h00012-O3 chỉ tăng 0 → 9 → 11 match trên 1,000 rồi hết
ngân sách. Giới hạn response kiểm soát chi phí nhưng có thể dừng trước khi tìm
được lời giải.

Theo nhóm chương trình ở O1, `strings_encodings` và
`parsing_state_machine` đều đạt 5/5 mà không cần behavioral feedback. Ngược
lại, 3/4 ca graph cuối cùng PASS và 2/5 ca data-structure cần feedback. Điều
này cho thấy loop đáng giá nhất khi lỗi chỉ xuất hiện ở cấu trúc dữ liệu hoặc
nhánh biên, thay vì dùng vô điều kiện cho mọi ca.

## 5. O1, O2 và O3: khi nào tốt, khi nào xấu?

O1 và O2 cùng đạt 38/40 nhưng không PASS trên đúng cùng tập case: h00028 chỉ
PASS ở O2, còn h00022 chỉ PASS ở O1. So sánh paired có một chuyển đổi theo mỗi
chiều, exact McNemar `p = 1.0`. O3 thấp hơn O1 một ca (37/40 so với 38/40),
nhưng exact McNemar cũng `p = 1.0`. Với 40 ca và một lần lấy mẫu mỗi treatment,
không có bằng chứng thống kê rằng một mức optimization có pass rate thực sự
cao hơn mức khác.

Dù vậy, chi phí quan sát được tăng đều: 1.500 → 1.625 → 1.800 request/ca và
96,284 → 99,864 → 109,774 input token/ca từ O1 đến O3. O3 còn gặp 10 response
`MAX_TOKENS`, gấp đôi O1/O2. Đây là quan sát của campaign, chưa đủ để quy toàn
bộ nguyên nhân cho optimization vì LLM vẫn có stochasticity.

Kết luận thực dụng từ lần chạy này là chọn **O1 làm cấu hình mặc định**: nó đạt
pass rate cao nhất ngang O2, dùng ít request/token hơn, và không bị mất ca
h00012 như O3. O2/O3 chỉ nên được xem là treatment thay thế hoặc chạy fallback
theo ca; chưa có cơ sở gọi O3 là cấu hình tốt nhất.

## 6. Cái gì chưa tốt trong pipeline?

### 6.1 Clean IR chưa phải executable tương đương đã được chứng minh

Khi compile và kiểm riêng final Clean IR trước LLM bằng 100 input/ca, cả O1,
O2 và O3 đều chỉ có 15 PASS, 24 FAIL và 1 INCONCLUSIVE. Ca h00038 bị mất
`main` trong finalization ở cả ba mức. Toàn bộ 117 native-contract report được
tạo thành công chỉ đạt `compat_runnable`, không đạt tiêu chuẩn fully native.

Do đó không được tuyên bố chuỗi pass đã biến mọi binary thành một executable
native tương đương. Kết quả 38/40 của F3 vẫn hợp lệ cho **source recovery** vì
candidate C được so trực tiếp với ELF obfuscated gốc; nhưng Clean IR hiện là
evidence giúp LLM suy luận, chưa phải một đầu ra deobfuscation độc lập đã được
chứng minh bảo toàn ngữ nghĩa.

### 6.2 “Không mismatch” chưa chắc là PASS

h00028-O3 có 998 match, 0 mismatch và 2 inconclusive. Recovery loop dừng vì
không còn mismatch, nhưng evaluator cuối vẫn gán FAIL_BEHAVIORAL một cách bảo
thủ. Timeout/crash bất đối xứng không được phép biến mất khỏi mẫu số để tạo
kết quả đẹp hơn.

### 6.3 Baseline thất bại chủ yếu ở representation và one-shot policy

Trong 23 ca B0 INCONCLUSIVE, 16 response còn artifact kiểu decompiler không
được C compiler hỗ trợ và 7 response thiếu chương trình C hoàn chỉnh. Vì B0
chỉ có một request nên nó không có cơ hội sửa các lỗi này. Điều đó giải thích
vì sao F3 tốt hơn về mặt hệ thống: Clean IR tránh nhiều artifact của Ghidra và
loop sửa được output không compile/sai hành vi.

Tuy nhiên B0 và F3 thay đổi đồng thời cả representation lẫn repair policy. Vì
vậy 70 điểm phần trăm là đóng góp của pipeline end-to-end, chưa thể chia bao
nhiêu điểm do Clean IR và bao nhiêu điểm do loop.

## 7. Dataset tự xây và rủi ro model đã biết đáp án

`own_dataset` gồm 40 chương trình CLI mới, tám nhóm, mỗi nhóm năm ca. Mỗi ca có
source, seed/input contract, oracle và ELF obfuscated bằng cùng recipe
`fla+bcf+instsub`; manifest/hash được cố định trước campaign. Bộ này không lấy
nguyên source từ benchmark công khai nên làm giảm khả năng model đã ghi nhớ
đúng cặp binary–source trên Internet.

Điều có thể khẳng định là **contamination-resistant**, không phải
“contamination-free”. Model vẫn có thể đã học thuật toán checksum, graph,
parser hoặc các idiom C tương tự. Mục tiêu của thiết kế mới là buộc model khôi
phục một composition, hằng số, format I/O và edge case mới; không phải chứng
minh model chưa từng biết các khái niệm thành phần.

## 8. Đóng góp nên được phát biểu thế nào?

Đóng góp không phải là “ghép Ghidra, McSema, LLVM, LLM và AFL++”. Các tool này
không được fine-tune và bản thân việc gọi chúng không phải novelty. Phần đóng
góp có bằng chứng là:

1. Chuỗi custom LLVM transformation 010–100 có checkpoint, audit và
   proof/refusal boundary để chuyển lifted IR thành evidence ít noise hơn.
2. Recovery orchestration dùng compiler/counterexample feedback, cùng phép đo
   cho biết loại ca nào được cứu và loại ca nào không hội tụ.
3. Phân tích paired O1/O2/O3 cho thấy aggressive optimization không mặc nhiên
   tốt hơn; O1 là điểm vận hành hợp lý nhất trong dữ liệu hiện tại.
4. Bộ 40 chương trình tự xây, frozen manifest và protocol tách source oracle
   khỏi prompt để giảm nguy cơ đánh giá bằng dữ liệu model đã ghi nhớ.

Không có fine-tuning LLM. Thay đổi nằm ở representation, custom passes,
prompt/orchestration, giới hạn retry, input contract và evaluator.

## 9. Những gì vẫn thiếu để có kết luận nhân quả mạnh hơn

Các campaign hiện tại đủ để báo cáo hiệu quả end-to-end và phân tích quan sát
O1/O2/O3. Để trả lời chặt hơn “thành phần nào tạo ra bao nhiêu hiệu quả”, vẫn
cần:

1. Ablation `Ghidra + iterative feedback` và `Clean IR + one-shot` để tách tác
   động của representation khỏi feedback policy.
2. Lặp lại mỗi O-level với nhiều random seed/model run; hiện mỗi treatment chỉ
   có một campaign nên khác biệt từng ca có thể là nhiễu lấy mẫu.
3. Sửa lỗi h00038 và nâng tỷ lệ tương đương của final Clean-IR executable; nếu
   sửa pipeline thì phải mở campaign ID mới, không ghi đè kết quả frozen này.
4. Mở rộng sang compiler, kiến trúc và recipe obfuscation khác; 40 ca x86-64
   với một recipe chưa đại diện cho toàn bộ deobfuscation.
5. Nếu muốn tuyên bố semantic equivalence thay vì empirical equivalence, cần
   thêm proof hoặc symbolic validation; 1,000 input fuzzing chỉ là bằng chứng
   thực nghiệm có giới hạn.

## 10. Câu kết luận có thể dùng trong luận văn

> Trên 40 chương trình CLI tự xây, pipeline Clean-IR iterative đạt 38/40 ca ở
> O1 và O2, so với 10/40 của baseline Ghidra one-shot. Mức tăng paired 70 điểm
> phần trăm có ý nghĩa theo exact McNemar, nhưng là hiệu quả end-to-end của cả
> representation và feedback loop. O3 không cải thiện kết quả và quan sát được
> chi phí cao hơn; do đó O1 là cấu hình vận hành phù hợp nhất trong phạm vi thử
> nghiệm. Kết quả cũng chỉ ra giới hạn: final Clean IR chưa luôn là executable
> tương đương, fuzzing không phải proof, và dataset tự xây chỉ giảm chứ không
> loại bỏ hoàn toàn nguy cơ kiến thức đã có của LLM.
