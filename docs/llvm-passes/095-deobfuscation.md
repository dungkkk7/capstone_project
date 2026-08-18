# 095 — deobfuscation OLLVM/Chernobog: chỉ rewrite khi có đẳng thức hoặc proof

**Plugin:** lib095.so  
**Tên pipeline:** 095.

## 1. 095 không phải một lượt tối ưu hoá LLVM chung chung

Obfuscator có thể thay x + y bằng cây bitwise/arithmetic MBA, thêm nhánh luôn
đúng/sai, hoặc biến CFG thành dispatcher state-machine. 095 chỉ xóa lớp đó nếu
biết output tương đương *theo bit-vector và CFG*. Nó không được dùng kết quả
“trông đơn giản hơn” làm proof.

Report công khai sắp stage:

~~~text
normalize → resolve_objects_pointers → mba → bcf_opaque_predicates
→ deflatten → cfg_cleanup → fake_stack → register_state
~~~

Trong code, direct Chernobog rule chạy trước generic normalization và trước SMT
để report còn biết rewrite đến từ rule nào, bao nhiêu operation trước/sau. Sau
mỗi CFG stage module được verify. Sau cleanup có tối đa hai round bounded:
một rewrite có thể lộ candidate cho round sau, nhưng không được lặp vô hạn.

Các cờ giới hạn gồm disable MBA, disable deflatten, max residual MBA expression
mỗi function, max Z3 recipe cho một expression, max opaque Z3 candidate,
max deflatten round/instruction/PHI edge; budget là ranh giới thuật toán chứ
không phải chỉ log hiệu năng.

## 2. Chernobog direct rules: matcher exact, không “nhớ công thức rồi thay”

Các family Add, And, Or, Sub, Xor, Misc, Jump là port tách file. Chúng chỉ
nhận DAG integer scalar pure; vector, freeze, undef, poison, side effect,
tree không đúng shape hoặc type không thích hợp bị từ chối. Mỗi rule giữ
metrics tên rule; generic LLVM simplifier không được tính là coverage cho một
rule Chernobog.

Một số rewrite minh họa, theo modulo 2^n cùng width:

~~~text
(x & y) + (x | y)              → x + y
(x ^ y) + 2 * (x & y)          → x + y
(x | y) & ~(x ^ y)             → x & y
~(~x & ~y)                     → x | y
x + ~y + 1                     → x - y
(~x | y) & (x | ~y)            → ~(x ^ y)
-x - 1                         → ~x
~x + 1                         → -x
~~~

Ví dụ rule đầu không được match expression gần giống
(x & y) + (x | z): leaf y/z khác nên identity không còn đúng. Với LLVM,
flag nsw/nuw và poison còn là một lý do không được tái kết hợp bừa; rule chỉ
tạo replacement ở shape/semantics nó đã port. test_chernobog_add_ollvm_rules,
and và xor chạy fixture dương, kiểm tra report hit đúng tên, đồng thời có
volatile/atomic/call/freeze/negative case để bảo đảm matcher không đi xuyên
instruction có behavior khác.

Jump rules xử lý predicate shape như self compare, (x & ~x)==0, (x ^ x)==0.
Đây là simplification điều kiện, không có nghĩa mọi icmp có hai operand
algebraically “na ná” là opaque. Cần exact operand identity và predicate đúng.

## 3. Z3Prover: proof nghĩa là gì, unknown nghĩa là không làm gì

Z3Prover chỉ dịch expression integer width 1–64 sang bit-vector. Translator
giới hạn độ sâu 32 và tối đa 8 leaf; nó hiểu constant, arithmetic/bitwise,
shift, cast, icmp, select và wrapping flags trong subset hỗ trợ. Value không
dịch được không bị “coi như variable vô điều kiện”: query trả không có evidence.

Để chứng minh condition boolean C luôn true, solver hỏi C != 1 có satisfiable
không; luôn false thì hỏi C != 0. Để chứng minh candidate S thay original E,
nó hỏi E != S. Kết quả có ba nghĩa:

| Kết quả solver | Hành động |
| --- | --- |
| unsat | Không có counterexample trong bit-vector model; rewrite được. |
| sat | Có input làm khác; giữ original. |
| unknown/timeout/translation fail | Thiếu proof; giữ original. |

Không có nhánh “timeout thì giả sử true”. Per-query timeout và counters trong
report ngăn MBA do adversary tạo thành solver DoS. Direct Chernobog rule vẫn
chạy khi generic Z3 MBA budget bằng 0 vì nó là matcher hữu hạn đã biết identity.

## 4. Opaque predicate / BCF: thay terminator sau proof, không phải trước

removeOpaquePredicates duyệt branch và select condition sau các direct rule/MBA
rewrite. Nó thử deterministic predicate rule trước; nếu chưa đủ và còn budget,
gọi proveBooleanConstant. Khi condition proven, pass chọn đúng successor,
sửa incoming của PHI ở dead successor trước rồi thay terminator. Nếu sửa edge
mà không sửa PHI, LLVM verifier sẽ bắt predecessor không còn tồn tại; nếu
thay condition chưa proven, binary có thể đi nhánh khác.

test_opaque_predicates.sh kiểm tra 24 predicate-rule declared được cover, hit
evidence và số conditional branch còn lại, rồi differential execute. Các test
signed_compare_flags, opaque_predicate_semantic_proof, opaque_parity_semantic_proof
và opaque_select_integration kiểm tra compare signed/flagged, parity, select,
không chỉ hằng trivial.

## 5. Deflatten: xây CFG mới theo transaction

Flattening điển hình đưa tất cả basic block về một header switch theo state,
rồi mỗi payload ghi state kế tiếp. Rule tìm State PHI/header/latch, decode case
và transition. Với transition proven, nó tạo bridge edge, clone *payload thực
sự chạy trên transition đó*, dùng SSAUpdater cho value mang qua edge, và sửa
target PHI khi dominance cùng mọi incoming value được chứng minh.

Nó không clone toàn dispatcher rồi hy vọng DCE cứu. Trước commit, root dispatcher
được snapshot. Thiếu target/state decode, payload path mismatch, instruction
không clone được, PHI mismatch, dominance fail, verifier fail, EH/callbr/
convergent restriction hay vượt instruction/edge budget đều rollback snapshot.
Dispatcher còn sót vì vậy nói rằng proof thiếu; nó không tự là lỗi của tool.

Một chi tiết về poison: frozen_dispatcher.ll có freeze(select(...)). freeze
biến undef/poison thành một lựa chọn defined nhưng không được phép biến branch
mới thành br poison. Test đòi preserved defined choices và check verifier.

## 6. Fake stack, register state và object/pointer cleanup

Sau CFG cleanup, các rule residual có thể hạ fake stack/register state chỉ
khi object/pointer provenance và use graph cho phép. Thứ tự sau deflatten là
cần thiết: dispatcher opacity có thể che store/load reachability; chạy frame
cleanup sớm sẽ suy alias/lifetime trên CFG giả. Report stage counts tách
fake_stack và register_state để không gộp kết quả này vào số MBA.

production_cases.ll được run trước/sau và runner kiểm tra JSON stage counts
cùng việc dispatcher/indirect call đã proven không còn. Test lifecycle Python
p03430/p00788 và audit scripts bổ sung kiểm tra pipeline báo cáo/behavior,
không chỉ FileCheck shape.

## 7. Cách đọc evidence của test 095

Một test hợp lệ cần có ba lớp assertion:

1. IR assertion: instruction/tree/branch cũ biến mất và replacement đúng.
2. evidence assertion: named rule hit hoặc Z3 attempt/proven counter.
3. semantic assertion: compile/run before-after hoặc differential result.

Chỉ có 1 là chưa đủ: optimizer khác có thể vô tình tạo cùng output. Chỉ có 2
là chưa đủ: report có thể đếm rule nhưng CFG/PHI hỏng. Bởi vậy các shell runner
cho Chernobog và opaque predicate đều dùng cả report và executable driver.

## 8. Tích hợp thực tế

README cũ của 095 nói stage này tách khỏi britening_ir.py, nhưng driver hiện
tại nạp lib095.so và có 095 trong PASS_PIPELINE. Khi hai mô tả mâu thuẫn, source
driver hiện tại là bằng chứng integration; README lịch sử không được dùng để
suy pipeline thực thi.

