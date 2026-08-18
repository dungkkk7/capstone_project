# 015 — materialize runtime helper: khai báo opaque thành body LLVM có semantics

**Plugin:** `BrightenRuntimeHelperPass.so`  
**Tên pipeline:** `brighten-remill-runtime-pass`

Lifted IR có declaration như `__remill_read_memory_*` và
`__remill_function_call`. Tên gợi ý một operation, nhưng với LLVM đó vẫn là
opaque call: optimizer không biết nó đọc/ghi gì, trap ra sao hay có quay lại
không. 015 chỉ có hai kết quả hợp lệ: tạo body LLVM đúng shape/semantics đã
chứng minh, hoặc giữ helper unresolved. Nó không được bịa body no-op để các
pass sau chạy tiếp, vì no-op có thể xoá fault hay side effect của binary gốc.

## Thứ tự rule và dependency

Entry point chạy:

```text
LowerMcSemaAttachThunks → PreserveX86DivideFaults → ImplementExternCallBridge
→ CanonicalizeGuestAddressConstants → repair external/inttoptr dereferences
→ DefineRemillControlFlowRuntime → LowerRemillMemoryIntrinsics
→ DefineRemillPureValueIntrinsics → DefineRemillAtomicBarrierRuntime
→ DefineRemillArchHypercallStubs → VerifyNoUnresolvedRemillIntrinsics
```

020 cần PC dispatcher có body/shape nhận diện được để resolve Remill call/jump.
030 cần load/store thật, không phải opaque memory-helper call. Vì thế 015 đứng
trước devirtualization và State SSA: đảo thứ tự sẽ buộc pass sau đoán effect
của call runtime.

## Các rule chính — phần sau đọc matcher và rewrite cụ thể

### Attach thunk và lifetime entry

`LowerMcSemaAttachThunks` nhận attach function McSema và biến attachment entry
direct/unique đã chứng minh thành IR thường. Nó chỉ gắn capability
`brighten.entry_single_invocation` khi owner không recursion, không
address-taken và không có provenance global live giữ entry path khác. 040 sau
đó dựa capability này mới biến global byte backing thành `alloca` mỗi lần gọi;
nếu không, read có thể thấy invocation trước và localize sẽ sai.

Fixture `entry_single_invocation_positive` cùng biến thể `two_calls`,
`recursive`, `address_taken`, `indirect_callback`, `*_provenance_global` tạo
matrix proof/refusal cho lifetime này.

### Giữ fault chia x86

Lifted division thường model x86 #DE bằng guard/abort. x86 fault khi divisor
zero và signed `MIN / -1`; thay nó bằng LLVM division thường làm đổi signal
observable. `PreserveX86DivideFaults` phải nhận cả guard hoàn chỉnh rồi mới
materialize SIGFPE.

`divide_fault_signal.ll` is compiled and run with three argument shapes. The
runner requires exit status 136 (SIGFPE) before accepting the rewrite.

### Body Remill: memory/control/value/atomic

- `DefineRemillControlFlowRuntime` supplies PC-dispatcher/control helpers.
- `LowerRemillMemoryIntrinsics` turns recognized reads/writes into LLVM memory
  operations with a threaded memory result.
- `DefineRemillPureValueIntrinsics` materializes pure arithmetic/flag helpers.
- `DefineRemillAtomicBarrierRuntime` defines fences, atomic RMW and cmpxchg
  helpers at supported widths; unsupported width/order remains unresolved.
- `DefineRemillArchHypercallStubs` handles supported architecture stubs.

Atomic handling is intentionally not a “replace with ordinary load/store”
cleanup: atomic ordering is observable between threads.

### Verify helper còn unresolved

`VerifyNoUnresolvedRemillIntrinsics` is the safety catch. Tests include
`unresolved_helpers_preserved`, which ensures an unknown helper is retained
rather than silently modeled incorrectly, and `atomic_runtime`, which checks
the accepted runtime subset.

## Chi tiết triển khai theo từng rule

Phần đầu tài liệu là overview. Phần này bám trực tiếp vào matcher và body mà
source hiện hành tạo ra.

### 1. `LowerMcSemaAttachThunks`: biến inline-asm attach thành call LLVM

Rule chỉ duyệt `main`, `start`, `.init_proc`, `compar`, và `callback_sub_*` có
inline asm chứa substring `$$0x`. Hàm `ParsePCFromInlineAsm` tìm phần hex ngay
sau đó trong asm dạng:

```asm
pushq $0;pushq $$0x401000;jmpq *$1;
```

Nó không cố parse mọi inline asm. Không thấy `$$0x`, không có PC; không có PC,
function không phải attach thunk của rule. Từ PC, `FindWrapperOrSub` tìm first
defined `<tên-thunk>_wrapper`, nếu không có mới tìm defined function có prefix
`sub_<hex>`. Không tìm được target thì rule chỉ in diagnostic và để original
thunk nguyên vẹn.

Khi target có exact signature `(ptr State, integer PC, ptr Memory) -> ptr`,
body asm bị xoá và thay bởi call trực tiếp với State, PC hằng đã parse, và
memory token null. Với target khác signature đó, rule chỉ `call Target()`;
không bitcast/bịa arguments cho target.

Với `main`, code tạo đúng một entry boundary:

```llvm
%entry_guest_stack = alloca [65536 x i8], align 16
%top = getelementptr [65536 x i8], ptr %entry_guest_stack, i64 0, i64 65536
%return_slot = getelementptr inbounds i8, ptr %top, i64 -8
store i64 0, ptr %return_slot, align 8
store i64 ptrtoint (ptr %return_slot to i64), ptr %state_rsp
```

Nó còn store `argc -> RDI(2296)`, `argv -> RSI(2280)`, `envp -> RDX(2264)`;
call target; load `RAX(2216)` rồi coerce về return type `main`. Cần phân biệt
frame này với recovered local variable: nó có metadata
`brighten.entry_guest_stack.transitional`, và comment source cấm xem nó là
provenance cho guest address khác. Nếu dùng một global fake stack lớn, read
guest address ngoài range có thể biến từ fault thật thành host load hợp lệ.

`compar` là nhánh riêng. `qsort` yêu cầu comparator `(ptr lhs, ptr rhs) ->
i32`, còn McSema thunk không có arguments. Khi và chỉ khi có RegState và target
memory-threading, rule tạo `compar.native_callback`, store `ptrtoint(lhs)` vào
RDI và `ptrtoint(rhs)` vào RSI, gọi target rồi load low `i32` từ RAX. Đây là
adapter có contract cụ thể, không phải suy luận ABI callback tổng quát.

Sau rewrite, capability metadata `brighten.entry_single_invocation =
!{!"v1", !"attach_direct_unique"}` chỉ được cấp khi entry không có use/alias,
owner local có đúng call từ entry, owner không alias và mọi use global còn lại
là constant dead provenance rất hẹp. 040 dùng capability này để quyết định
global backing có thể thành fresh alloca. Một callback, recursion, address-take,
retention list hoặc global use live làm capability bị từ chối.

### 2. `PreserveX86DivideFaults`: abort chỉ đổi khi chứng minh là x86 #DE

Rule lấy từng integer `sdiv`/`udiv`. Một basic block candidate phải có đúng
`call @abort` duy nhất (bỏ qua debug intrinsic) rồi `unreachable`. Với từng
predecessor branch của block đó, rule xác định fault edge và match một trong
hai form:

```llvm
; chia 0: true edge là fault
%zero = icmp eq i64 %divisor, 0
br i1 %zero, label %fault, label %normal

; signed overflow: true edge là fault
%a = icmp eq i64 %dividend, -9223372036854775808
%b = icmp eq i64 %divisor, -1
%overflow = and i1 %a, %b
br i1 %overflow, label %fault, label %normal
```

`IsZeroEquivalentTo` không coi bất kỳ expression bằng 0 là divisor: chỉ accept
same SSA value, `zext/sext` preserve-zero, hoặc exact structural form
`ashr exact (shl X,K),K` với cùng constant K. Signed overflow cũng accept một
range-check quotient đặc biệt, nhưng không accept algebra arbitrary “có vẻ
tương đương”. Một predecessor lạ làm block `Ambiguous`, và ambiguity của một
division bỏ cả function. Cuối cùng rule yêu cầu chính xác một zero-fault và,
với `sdiv`, đúng một overflow-fault; shared abort hoặc duplicate candidate bị
từ chối.

Chỉ khi đạt toàn bộ điều kiện, `call @abort` thành `call @raise(SIGFPE)`.
`raise` không `noreturn` vì signal handler có thể return; `unreachable` cũ giữ
termination original. `divide_fault_signal.ll` không chỉ FileCheck: runner
compile rồi yêu cầu executable trả status 136 ở zero signed, zero unsigned và
`INT_MIN / -1`.

### 3. `DefineRemillControlFlowRuntime`: declaration PC thành switch thật

`DefinePCDispatcher` chỉ chạy khi helper là declaration và có exact
memory-threading signature. Nó gom mọi defined function cùng exact type, parse
PC từ tên, sort theo PC (trùng PC ưu tiên `sub_`), rồi tạo:

```llvm
switch i64 %pc, label %fallback [
  i64 4198400, label %case_sub_401000
]
case_sub_401000:
  %m2 = call ptr @sub_401000(ptr %state, i64 %pc, ptr %memory)
  ret ptr %m2
fallback:
  %m3 = call ptr @__remill_missing_block(ptr %state, i64 %pc, ptr %memory)
  ret ptr %m3
```

Như vậy 020 có material switch để collapse PC hằng. `__remill_function_return`,
`missing_block`, `error` và hypercall không được thân hàm “return memory” vì
điều đó sẽ bịa semantics return/error/hypercall; rule log và preserve chúng.

### 4. `LowerRemillMemoryIntrinsics`: guest access thành load/store align 1

Read chỉ accept declaration `__remill_read_memory_*` có ít nhất hai args,
address integer/pointer và return void/first-class. Body call translator với
write bit `false`, rồi load return type từ pointer. Alignment luôn `align 1`:
x86 cho unaligned access; claim `align 8` sẽ làm valid guest address lệch thành
LLVM UB. Suffix `_f80`/`_f128` chỉ accept return floating type và dùng type
`x86_fp80`/`fp128` trước khi cast.

Write yêu cầu ít nhất ba args, address integer/pointer, value first-class, và
return void hoặc pointer cùng type memory argument 0. Nó gọi translator write
bit `true`, store align 1 và return original memory token. Signature khác giữ
declaration; không fabricate return zero/integer.

### 5. `DefineRemillPureValueIntrinsics`: hiện tại cố ý không làm gì

Tên rule dễ gây hiểu lầm. Source hiện hành chỉ log helper
`__remill_undefined_*`, FPU, compare, flag computation không có exact lowering
và return `false`. Không có identity/zero replacement. Điều này bảo vệ branch
và floating semantics; 030 phải tự chứng minh flag formula thay vì dựa vào
body giả.

### 6. `DefineRemillAtomicBarrierRuntime`: whitelist signature/width

`compare_exchange_memory_<bits>` và `fetch_and_{add,sub,and,or,xor,nand}_<bits>`
chỉ lower khi `<bits>` thuộc 8/16/32/64/128 và argument/return shape khớp.
RMW tạo `atomicrmw ... seq_cst`, store old value lại value pointer và return
memory token. Compare-exchange tạo `cmpxchg seq_cst/seq_cst`, extract old value
và store lại expected pointer.

Barrier mapping là `load_load -> acquire`, `store_store -> release`,
`load_store/store_load -> seq_cst`; delay-slot begin/end trả memory token. I/O
port và `atomic_begin/end` chỉ diagnostic: hạ port I/O thành host memory access
là sai side effect.

### 7. Test matrix đúng của pass 015

- `unresolved_helpers_preserved.ll`: helper lạ phải sống, không được noop.
- `atomic_runtime.ll`: subset atomic/barrier có body hợp lệ.
- `divide_faults.ll`: structural guard matcher.
- `divide_fault_signal.ll`: semantic signal test.
- `entry_single_invocation_positive.ll`: metadata positive.
- `entry_single_invocation_two_calls.ll`, `*_recursive.ll`,
  `*_address_taken.ll`, `*_indirect_callback.ll`: callgraph/lifetime refusal.
- `*_dead_provenance_global.ll`, `*_used_provenance_global.ll`,
  `*_live_provenance_global.ll`: phân biệt provenance global dead có thể bỏ
  với used/live global không thể dùng làm proof unique owner.
