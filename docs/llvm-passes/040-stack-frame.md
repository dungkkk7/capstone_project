# 040 — phục hồi stack frame

**Plugin:** `BrightenStackFramePass.so`  
**Tên pipeline:** `brighten-stack-frame-pass`,
`brighten-post-state-frame-pass`

040 đổi traffic stack local **đã chứng minh** thành storage local LLVM native.
Đây là pass rất bảo thủ vì rewrite sai có thể đổi incoming/persistent memory
thành `alloca` mới chưa khởi tạo.

## Phục hồi architectural stack

`StackFrameV2.cpp` models RSP/RBP as `StackExpr`:

```text
Unreachable | Unknown | NonStack | StackConst(base, offset) |
StackDynamic(base, constant offset, dynamic term)
```

Base lưu RSP/RBP, epoch và stability. Dataflow merge state block; incoming
không tương thích thành unknown thay vì chọn một form tuỳ ý.

Với entry-RSP frame được nhận, access như:

```llvm
%addr = add i64 %entry_rsp, -8
%p = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
store i64 42, ptr %p
```

thành byte GEP trong một local allocation, ví dụ:

```llvm
%native_local_frame = alloca [8 x i8]
%frame_ptr = getelementptr i8, ptr %native_local_frame, i64 0
store i64 42, ptr %frame_ptr
```

Acceptance đòi offset âm hữu hạn, range safe, không unsafe overlap, base/address
không escape, không volatile/atomic, không call truyền RSP, không unmodeled
call clobber, không entry ABI slot, và không read trước proven write. Frame
quá lớn/chưa proof cũng bị từ chối; các điều kiện giữ lifetime lẫn initial value.

`test_promoted_rsp_slot.ll` and `test_cyclic_affine_frame.ll` are positives.
`test_entry_rsp_abi_slot_refused.ll`, `test_finite_read_before_write.ll`,
`test_nonfinite_stack_phi.ll`, `test_mixed_stack_bases.ll`,
`test_call_clobbers_stack_state.ll`, and `test_large_unproven_frame.ll` each
exercise one refusal class.

## Compact frame sau State

State lowering có thể để lại byte backing global internal zero-initialized
synthetic. `BrightenPostStateFramePass` chỉ thay nó bằng `alloca` sau closed
proof:

- backing là `[N x i8]` zero global internal;
- metadata chứng nhận một entry invocation direct unique;
- mọi use là constant in-bounds GEP/bitcast và load/store hỗ trợ hoặc exact
  nonvolatile `memset`;
- toàn bộ use thuộc một owner function;
- read được complete initialization dominate;
- không có `ptrtoint`, escaping call, owner recursion/address-taken, volatile,
  atomic, typed overlap không tương thích hay saved-RBP traffic live.

Rewrite là transaction: một user fail thì global-backed form không đổi.
`test_post_state_frame_compaction.ll` là positive; `*_call_refused`,
`*_volatile_atomic_refused`, `*_ptrint_refused`, `*_persistent_read`,
`*_proof_refused`, `*_entry_contract_refused` cover từng failure boundary.

## Phục hồi slot pointer và scalar

Sau khi backing qua frame proof, constant typed slot chỉ thành local
`alloca ptr` hoặc integer alloca nếu complete use graph xác lập một exact type
và lifetime không escape. View partial/overlap/volatile/atomic giữ bytes.
`test_pointer_slot_retyping.ll`, `test_scalar_slot_localization.ll`,
`test_pointer_slot_lifecycle.ll` cover type recovery được nhận và stability
sau pass.

`test_activation_frame_audit.ll` proves audit mode is analysis-only: toggling
the audit environment flag must not change serialized IR, only diagnostics.

## Chi tiết implementation theo rule

### `RecoverStackFrame`: phân tích affine RSP/RBP, không match tên biến

Rule dùng worklist dataflow với `BlockState{RSP,RBP}`. `StackExpr` có kind
`Unreachable`, `Unknown`, `NonStack`, `StackConst`, `StackDynamic`; stack base
chứa value root, kind RSP/RBP, epoch và cờ stable. Khi hai predecessor merge
không cùng exact base/epoch/offset/dynamic value, merge thành `Unknown` thay vì
chọn arbitrarily một expression. Epoch tách hai incarnation của RSP sau call/
state update, tránh coi offset giống số học là cùng frame.

Pointer access được record thành `[Begin, End)`, read/write, volatile/atomic,
escape. Frame chỉ được recover cho entry RSP base (`Key.V == nullptr`), range
âm hữu hạn, `0 < size <= 1 MiB`, có ít nhất một safe access, và mọi read có
definite initialization proof. Báo cáo verifier nội bộ còn assert recovered
range không được positive offset: offset dương là incoming ABI/caller area,
không phải local frame của callee.

Các explicit skip reason trong source là contract thực tế:

```text
escape, dynamic, volatile_or_atomic, positive_offset, non_entry_rsp,
non_rsp_base, stack_pointer_call, unsafe_overlap, no_safe_access,
invalid_range, frame_too_large, memory_boundary, read_before_write,
entry_abi_slot
```

Ví dụ `load [entry_rsp+8]` phải từ chối: nó có thể là return/incoming stack
argument. Ví dụ `load [entry_rsp-8]` trước store cũng phải từ chối: frame
allocation fresh có value undefined, còn original lifted memory có thể giữ
saved/persistent value. Cả hai không được “zero initialize cho tiện”, vì đó là
semantic rewrite.

`CallMayClobberGuestStackState` phân loại call boundary. A direct known
readnone/readonly call hoặc proven non-stack call có thể không invalidate;
unknown call, indirect call, call nhận stack pointer, hay call có guest-memory
effects làm base/range unsafe. Đây là nguyên nhân `test_call_clobbers_stack_state`
không tạo `native_local_frame`.

### `CompactProvenPostStateFrameBackings`: closed use graph trước mutation

`PostStateFrameProof::prove` yêu cầu backing là internal, zero-initialized
`[N x i8]`, N hữu hạn. `walkPointer` chỉ đi qua inbounds constant GEP và
bitcast; `ptrtoint`, dynamic GEP, phi/select/call pointer carrier hay address
escape trả false. Leaf use chỉ được là:

- nonvolatile/non-atomic load/store, với exact store size;
- exact `llvm.memset` destination, constant nonzero length, nonvolatile và
  argument 0 `nocapture`.

Mọi access phải thuộc cùng owner function và offset range nằm trong object.
Proof sau đó kiểm incompatible overlap: overlap chỉ được nếu cùng `[begin,end)`
và cùng type; packed byte/word alias bị từ chối, không tự chọn type lớn hơn.

Trước commit, code còn kiểm metadata creation binding + owner capability
`v1/attach_direct_unique`, owner không address-taken/recursive, no saved-RBP
State traffic, complete rewrite plan, và `readsAreInitialized`. Nếu bất kỳ
pointer use không nằm trong plan hoặc global không xoá được sau rewrite, không
có partial mutation.

### Pointer slot retyping không áp dụng cho integer observation

`recoverProvenPointerSlots` preflight một slot byte chỉ khi all loads/stores
biểu diễn pointer lifecycle closed: store canonical `ptrtoint` của native
pointer, load `inttoptr` dùng như pointer/null test/known consumer, range
resolver closure exact, không volatile/atomic/escape/recursive callback. Nếu
value integer được in, cộng có `nsw`, stored through another alias, hoặc mixed
pointer/guest resolver PHI, slot vẫn i64 bytes. Vì `ptrtoint` bits có thể là
observable data, đổi nó thành host `ptr` field sẽ thay semantics.

`recoverProvenScalarSlots` tương tự nhưng cần one identical scalar type tại
constant offset và non-overlap. Test `test_scalar_slot_localization.ll` cố ý
có neighbor, capture, volatile, atomic để chứng minh pass chỉ localize subset
đủ proof, không “tách hết byte backing”.
