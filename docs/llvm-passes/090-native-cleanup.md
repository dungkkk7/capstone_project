# 090 — cleanup native và cổng hợp đồng cuối, hai nhiệm vụ bị tách cứng

**Plugin:** BrightenNativeCleanupPass.so  
**Pass:** brighten-native-cleanup-pass, brighten-native-cleanup-post-frame-pass,
brighten-native-cleanup-final-pass.

## 1. Ba entry point, khác quyền thay đổi IR

main.cpp đăng ký ba pipeline name:

| Pass | Hàm thực thi | Có mutation? | Ý nghĩa |
| --- | --- | --- | --- |
| cleanup-pass | cleanupModule(M, false) | Có | recovery/cleanup rộng. |
| post-frame-pass | finalizeCompactedFrames(M) | Có, hẹp | chỉ tiêu thụ dạng frame/pointer đã lộ muộn. |
| final-pass | cleanupModule(M, true) | Không | chỉ reportNativeContract và trả false. |

Điểm cuối cùng đặc biệt quan trọng: final-pass không có quyền “sửa cho pass
qua”. Trong cleanupModule, nhánh EnforceStrict gọi reportNativeContract rồi
return false ngay. Vì thế report có giá trị audit: nếu final-pass làm input
trông native hơn thì nó đã không còn phát hiện được residual do chính nó che đi.

Cờ brighten-native-strict làm contract reject module vi phạm; cờ
brighten-native-state-ssa bật State ABI lowering. Khi strict hoặc state-ssa
bật, cleanup cố hạ ABI; nếu transaction State ABI trả false, các rewrite phụ
thuộc State ABI không được chạy trên lifted ABI cũ. Log nói rõ “preserving
dependent native rewrites”, không suy diễn một trạng thái nửa native.

## 2. Broad cleanup: thứ tự source và dependency thực

Nhánh mutation của cleanupModule có những cụm rule sau, theo thứ tự source:

1. ensureNativeEntrypointStackStorage chỉ tạo storage entry khi dựng được
   boundary C-entry có cấu trúc; zero initializer của global cũ không đủ chứng
   minh reset theo từng invocation. Sau đó strip Remill metadata nhưng giữ
   recovered guest-range tới khi external-pointer/scanf đã materialize.
2. materializeResidualLibcFormats, preserve recovered global,
   widenOverNarrowRecoveredScalars, canonicalize dead lifted arguments.
3. xử lý undef/poison cực hẹp: lowerFullyOverwrittenUndefinedScaffolds,
   lowerDirectFullyOverwrittenUndefinedScaffolds, unobserved shuffle lanes và
   single-lane vector broadcasts.
4. hạ pointer translation đã có proof; callback trampoline phải hạ **trước**
   wrapper inline; hạ x86 thread-pointer inline asm; inline external wrapper.
5. normalize ABI libc sớm, qsort array, guest constant pointer, missing scanf
   destination và segment pointer.
6. State ABI transaction; chỉ khi thành công mới chạy broad State/stack/data
   pointer rewrites, allocator RAX recovery và ABI libc lượt muộn.
7. các rewrite residual data aliases, relocation pointer, dynamic guest
   inttoptr, callback/qsort bridge, dead wrapper/lifted function. Xóa lifted
   function chạy fixed-point vì xóa clone có thể làm dispatcher khác chết.
8. normalize entrypoint, lower raw RSP inttoptr muộn, compact frame backing,
   rồi làm lại startup cleanup một lượt vì việc xóa function có thể bỏ root.

Đây là lý do không được đảo tùy tiện. Ví dụ callback qsort sau inline mất link
duy nhất từ trampoline đến comparator lifted; State-SSA trước normalize
vscanf.lifted_abi có thể rollback cả callgraph plan; strip guest-range quá sớm
làm scanf không còn chứng minh được guest object của destination.

## 3. State ABI lowering là transaction callgraph

Lifted native clone thường có State pointer làm nơi chở register:

~~~llvm
define ptr @sub_x.native(ptr %State, i64 %pc, ptr %memory)
; đọc/ghi State+2216 (RAX), State+2312 (RSP), ...
~~~

State-SSA đổi các slot proven live-in thành argument explicit và các live-out
thành result field/SSA, rồi cập nhật tập function native liên thông. Nó không
coi một State global shared là local chỉ vì tên giống State. Callback, recursion,
address-taken function, unknown call, guest boundary hay memory-token use có
thể quan sát State; một plan gặp các edge đó phải rollback toàn transaction.

Hai test minh họa:

- state_ssa_native.ll là đường dương: register slot qua internal native call
  được explicit hóa.
- state_ssa_guest_boundary.ll, shared_state_context.ll và
  mixed_native_memory_token.ll kiểm tra boundary: không đẩy State qua nơi
  guest/runtime có thể quan sát nó.
- explicit_argument_overrides_state.ll kiểm tra khi callee có argument ABI mới
  và snapshot State cũ cho cùng register, argument explicit thắng. Đọc
  snapshot cũ làm caller/callee thấy hai RDI khác nhau, tức đổi ABI.

Khi transaction thành công, rule còn thử lower State scratch buffer ở entry
và oversized guest stack buffer. Nó không tạo “fake native stack” để làm proof
dễ hơn; không có frame anchor proven thì pointer translation còn nguyên.

## 4. Undef/poison: chỉ định nghĩa scaffold khi mọi byte quan sát được bị ghi đè

Code có comment cấm lấp incoming undef/poison của PHI: common value ở những
edge khác không chứng minh architectural state của edge thiếu. Nó cũng cấm
freeze unresolved register/flag; freeze chỉ chọn một giá trị ổn định, không
phục hồi nghĩa máy.

Ngoại lệ narrow là aggregate/scaffold mà analysis chứng minh mọi field/byte
có thể quan sát đều bị overwrite trước read. fully_overwritten_undefined_scaffold.ll
và direct_overwritten_undefined_scaffold.ll là acceptance. Fixture
partially_overwritten_undefined_scaffold.ll, frozen_undefined.ll và
uninitialized_local_seed_phi.ll phải còn finding/reject. Nếu biến partial
undef thành local zero hoặc arbitrary value, output có thể chạy “đẹp” nhưng
đã đổi nguồn dữ liệu observable.

## 5. Frame compaction và post-frame fixed point

Broad cleanup chỉ compact recovered fake stack khi proof đủ: root/GEP offset
hữu hạn và đúng, complete use graph, không escape, không volatile/atomic,
không unknown/recursive call, không partial write rồi read. Các refusal
native_main_stack_read_before_write_refused, partial_write_refused,
unknown_call_refused, nonzero_root_gep_refused, unsupported_user_rollback
đều khóa điều kiện riêng; native_main_stack_fully_initialized là positive và
runner chạy lại để kiểm tra idempotence.

post-frame-pass chạy sau 040/080/O3 vì lúc đó pointer PHI hay affine
ptr-int round-trip có thể mới xuất hiện. Nó gọi lần lượt trong một vòng
fixed-point:

~~~text
forwardProvenNativeFramePointerIntegerLoads
→ lowerNativeAffinePointerRoundTrips
→ collapseNativeOutlinedRecoveredAddressResolverCalls
→ collapseProvenNativeRecoveredPointerDispatches
→ canonicalizeLocalFrameRelativePhis / promoteMirroredFrameLoopPhis
→ forwardExactDominatingLocalFrameLoads
→ eraseGloballyUnreadFrameStores
→ cleanup dead instructions
~~~

Vòng chỉ dừng khi một round không thay đổi. Lý do: forward spill có thể lộ
resolver; collapse resolver lại làm call-footprint chính xác hơn và cho phép
xóa store. Dựa vào “pipeline có thể chạy lần nữa” sẽ làm pass một lần không
idempotent.

Sau vòng, post-frame xử lý fully-overwritten aggregate lại, split finite local
frame slots, xóa write-only local frame, scalarize closed register storage,
reclassify residual storage, canonicalize affine PHI, outline resolver exact,
materialize constant-offset residual views, strip metadata và report contract.

## 6. Frame load / scanf không dùng heuristic “call có vẻ không ghi”

May-write summary interprocedural chỉ nhận direct internal call hữu hạn và các
libc operation có footprint bounded. Với local frame load, mỗi alternative của
GEP/PHI/select phải là constant finite; recursion, indirect call, overlap,
unbounded size, pointer-int escape hay trên 16 alternative đều giữ load.

scanf/vscanf là phần khó: format phải constant, mỗi conversion có destination
width hữu hạn, va_list local và GP save-area phải có exact dominating stores.
Một call scanf chung chung không chứng minh một stack slot đã initialize hay
là pointer. Các fixture scanf_missing_destination,
scanf_does_not_retype_unrelated_varargs, scanf_failed_longlong_poison,
vscanf_overflow_pointer và scanf_absolute_frame_anchor_delta tồn tại để chặn
mỗi dạng suy đoán này.

## 7. Resolver outline/collapse dùng equality cấu trúc, không tin tên helper

outlineExactRecoveredAddressResolvers chỉ outline các resolver lặp lại nếu mọi
arm cùng profile có:

- predicate unsigned exact: (address - begin) < size;
- GEP cùng biểu thức global + address - begin;
- fallback i64 giống nhau;
- ordered range profile giống nhau;
- range được authoritative guest-range metadata hoặc allocation size exact
  chứng minh.

Một arm lệch 1 byte, object size khác, carrier không do generator tạo hay
range overlap giữ nguyên toàn resolver. Helper được đánh noinline internal
nhưng consumer vẫn revalidate body; tên/attribute không phải proof.
recovered_resolver_outlining.ll và native_outlined_resolver_call.ll là positive;
range_guard_counter_negative.ll, affine_frame_helper_proof_refused.ll và
affine_frame_helper_dispatcher_refused.ll là refusal.

collapse ở consumer còn đòi guest-address operand có native affine provenance
trọn vẹn. Phi trộn guest/native, loaded integer không exact forwarding proof,
flagged arithmetic hay fallback unknown giữ call. Với flagged form, boundary
giữ guest-producing add/sub tại caller và helper tái tạo cùng nsw/nuw; không
reassociate để có shape tiện hơn vì reassociation có thể đổi nơi poison sinh.

## 8. Scalar hóa residual/state storage không được tạo object alias mới

Closed native register storage chỉ scalarize khi complete recursive use graph
gồm exact in-bounds nonvolatile integer load/store. Byte/word overlap cùng
little-endian component dùng một scalar slot; component không có original read
được xóa trước khi partial store tạo load-mask-merge giả. Dynamic offset,
address escape, atomic, type không hỗ trợ, overlap rộng hơn 16 byte từ chối cả
transaction.

Với native_residual_* còn phải giữ, constant offset view chỉ là GlobalAlias
vào cùng allocation: native_scalar_<address> đòi toàn bộ direct use tại anchor
là load/store non-atomic/nonvolatile cùng một single-value type; khác đi dùng
native_object byte view. Không có scalar mới tách storage, nên dynamic index,
relocation, escape vẫn alias backing gốc.

## 9. Final contract kiểm tra thứ LLVM verifier không biết

LLVM verify chỉ kiểm tra IR well-formed. reportNativeContract còn báo residual:

- State type/global, lifted 3-argument ABI, Remill/McSema call;
- guest translator/select fallback, flattened guest dispatcher/stack;
- segment image/data alias, integerized guarded pointer;
- undef/poison/freeze scaffolding hay inline asm rủi ro;
- synthetic entry stack không có transition contract.

clean_native.ll và final_contract_native_malloc.ll là positive. lifted_not_native,
residual_guest_artifacts, residual_flattened_stack,
residual_zero_initialized_fake_stack, final_contract_residuals,
final_contract_overlapping_pointer_fallback,
final_contract_transitional_entry_stack, thread_pointer_inline_asm là negative
catalogue. Với strict, finding là build failure; không có automatic repair ở
cổng này.

Khi đọc test 090, hãy luôn tìm cặp positive/refusal. Sự vắng mặt của rewrite
thường là kết quả đúng: nó nói một proof về alias, initialization, ABI hoặc
poison chưa tồn tại, chứ không đơn thuần nói matcher chưa được viết.

