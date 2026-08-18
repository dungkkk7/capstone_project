# 100 — bundle giao hàng sau delift, không phải LLVM pass

**File thực thi:** brighten_100_delift_bundle/run_brighten_delift_pipeline.sh.  
Nó nhận INPUT.ll và OUTPUT_PREFIX, tạo các checkpoint .01 đến .05, final .ll,
.o và .bin. Vì script dùng set -euo pipefail, command lỗi, biến chưa đặt hay
pipeline lỗi đều dừng build; không có output nửa thành công bị in là final.

## 1. Sản phẩm và checkpoint

Script resolve INPUT bằng realpath, tạo WORKDIR từ PREFIX, rồi đặt:

~~~text
01-verified-input: input LLVM hợp lệ
02-pointer-opt: exact LLVM cleanup đã chọn
03-storage-delift: sau default<O*> có verify
04-storage-o3: sau delift_storage
05-unpinned: residual Brighten bị strip có cấu trúc
PREFIX.ll: IR cuối để compact, verify, compile
PREFIX.o / PREFIX.bin: artifact clang -O2
~~~

Checkpoint có mục đích debug: nếu executable đổi behavior, có thể differential
giữa stage; không phải chỉ một temp file trang trí.

## 2. Trình tự chính xác và vì sao thứ tự này tồn tại

~~~text
verify input
→ run_exact_llvm_passes.py
→ default<O*> + verify
→ delift_storage.py
→ strip_brighten_residuals.py
→ default<O*> + verify
→ dedup_pointer_selects.py
→ deterministic 095 + scalar cleanup + verify (nếu plugin tồn tại)
→ 090 post-frame + interprocedural cleanup + 090 final + verify (nếu plugin tồn tại)
→ compact_ir_text.py → verify → clang object/bin
~~~

Bước đầu chạy opt -passes=verify trước bất kỳ rewrite để lỗi input không bị
đổ oan cho bundle. exact LLVM passes tách script riêng vì đây là danh sách
đã chọn/test, không dùng “default O3” như một black box cho tất cả việc.

Standard optimizer treatment chạy trước delift_storage vì fold/canonicalize có
thể làm storage pattern lộ rõ. delift_storage sau đó hạ representation storage; strip residuals chỉ
chạy sau vì nó cần biết artifact nào đã thật sự dead/được thay, không được xóa
một global lẽ ra còn làm backing. Treatment lần hai dọn artifact do hai bước
đó tạo. `DELIFT_OPT_LEVEL` (fallback `BRIGHTEN_OPT_LEVEL`) chỉ nhận
`O1`/`O2`/`O3`; mặc định là `O3`.

dedup_pointer_selects centralize các select pointer cùng semantics. Chính nó có
thể làm cây MBA/resolver compact hiện ra; vì vậy 095 deterministic chạy *sau*
dedup, không phải trước.

## 3. Lượt 095 cuối deliberately không phải deobfuscation đầy đủ

Nếu DEOBF_PLUGIN file tồn tại, script gọi:

~~~text
-passes=095
-095-disable-deflatten
-095-max-z3-candidates=0
-095-max-opaque-z3-candidates=0
~~~

Nghĩa là chỉ direct deterministic MBA rules còn được dùng. Deflatten bị tắt,
SMT MBA và opaque predicate đều có budget zero. Lý do không phải “Z3 xấu”:
lượt đầu trong pipeline chính đã có quyền deobfuscate có proof/budget; lượt
bundle này chỉ presentation cleanup sau khi mapper/dedup lộ arithmetic mới.
Zero budget bảo đảm input adversarial không biến packaging thành solver job,
và bundle không mở một CFG recovery mới sau đã gần contract final.

Sau 095, opt chạy đúng scalar pipeline:
function(instcombine no-verify-fixpoint, simplifycfg, gvn, dce, adce),
globaldce, verify. Nó không vectorize vì vectorization làm pseudocode recovered
khó đọc nhưng không tăng semantic information. no-verify-fixpoint không phải
bỏ LLVM verifier: comment giải thích LLVM 21 fixpoint diagnostic có thể reject
CFG valid vừa mở; module verifier vẫn chạy ngay trong pipeline và lại chạy
-disable-output sau đó.

## 4. 090 cuối: pass nào có quyền gì ở boundary executable

Nếu NATIVE_CLEANUP_PLUGIN tồn tại, script chạy:

1. brighten-native-cleanup-post-frame-pass;
2. internalize, ipsccp, deadargelim, globalopt và chuỗi scalar cleanup/globaldce;
3. post-frame-pass lần nữa;
4. brighten-native-cleanup-final-pass;
5. verify.

Post-frame lượt đầu tạo bất kỳ adapter source-ABI cần thiết. Sau đó executable
chỉ export main, nên internalize có whole-program linkage proof để làm non-entry
definition local; IPSCCP làm lộ State-SSA parameter constant; deadargelim chỉ
bỏ argument/aggregate field sau ABI proof thông thường. Lượt post-frame thứ hai
là convergence boundary: interprocedural/scalar cleanup có thể mới lộ affine
frame/poison scaffold. final-pass ngay trước verify báo contract cho **đúng IR
sắp compact/compile**, và theo định nghĩa 090 final không mutate.

Một lựa chọn có chủ ý: không có Attributor hay function-attrs. Test differential
corpus từng thấy hai inference pass này khai thác UB/provenance còn tiềm trong
lifted IR, tạo binary tối ưu segfault khi original hoàn thành. internalize +
ipsccp + deadargelim là tập hẹp có behavior được test; compile thành công hay
LLVM verifier pass không thay thế cho chứng minh equivalence.

## 5. Plugin có thể vắng và ý nghĩa đó

Hai đoạn 095/090 chỉ chạy nếu file plugin tồn tại. Đây là behavior source hiện
tại: bundle vẫn tiến tới compact/compile khi plugin thiếu, không tự build plugin
hay giả vờ đã làm deobfuscation/native-contract. Vì thế log/artifact consumer
phải biết có plugin nào được nạp; final LLVM verify chỉ chứng minh IR hợp lệ,
không chứng minh contract 090 đã được đánh giá.

## 6. Dòng cuối: compact và compile không được đảo

compact_ir_text chỉ đổi trình bày textual sau final contract. Script verify lại
PREFIX.ll sau compact để tool text không vô tình tạo/sai IR. Sau đó clang -O2
compile object và link executable với -lm. Nếu clang không tìm thấy, script
exit 127 thay vì bỏ qua binary.

Kết luận kiểm thử cho bundle cần có ba lớp:

- verify ở checkpoint để bắt malformed IR;
- 090 final report/strict mode để bắt residual semantic-lifter artifact;
- run/differential output .bin để bắt semantic regression.

Một lớp không suy ra hai lớp còn lại. Đây là lý do 100 được gọi là bundle giao
hàng, không phải “một pass cleanup cuối”.
