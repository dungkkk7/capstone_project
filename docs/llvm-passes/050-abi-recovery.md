# 050 — phục hồi ABI

**Plugin:** `BrightenABIRecoveryPass.so`  
**Tên pipeline:** `brighten-abi-recovery-pass`

Sau 020/030/040, subroutine lifted vẫn có transport ABI như
`ptr sub(ptr State, i64 PC, ptr Memory)`. Đó là ABI của lifter, không phải
program gốc. 050 phục hồi function boundary native explicit từ liveness
register-slot và callsite đã biết.

## Thứ tự rule

Entry point cố ý chạy transaction theo thứ tự:

```text
NormalizeRegisterAccesses
AnalyzeFunctionLiveIns
AnalyzeFunctionLiveOuts
AnalyzeCallsiteABI
InferFunctionABISignatures
CloneNativeFunctions
RewriteNativeFunctionBodies
RewriteKnownCallsites
NormalizeScanfI32Boundaries
LowerCallbackAndSharedStateABI
CreateRemillWrappers
RewriteMainWrapper
CleanupDeadRemillABI
```

Analysis đứng trước clone: signature clone phải chọn từ State/register use gốc
trước wrapper che callsite evidence. Direct call cũng phải rewrite trước
compatibility wrapper vì cùng lý do.

## Pass phục hồi cái gì

`AnalyzeFunctionLiveIns` finds an exact State offset read before a local
definition: that register field is a candidate input. `AnalyzeFunctionLiveOuts`
finds values written on return paths and used by callers: they become a scalar
return or a field in an aggregate return. `AnalyzeCallsiteABI` then checks that
each direct caller can supply/recover the same register values.

Với lifted function rút gọn:

```llvm
define ptr @sub_401000(ptr %state, i64 %pc, ptr %mem) {
  %rdi = load i64, ptr %state_rdi
  %out = add i64 %rdi, 1
  store i64 %out, ptr %state_rax
  ret ptr %mem
}
```

the intended native clone is conceptually:

```llvm
define i64 @sub_401000.native(i64 %arg_rdi) {
  %out = add i64 %arg_rdi, 1
  ret i64 %out
}
```

Code thật có thể cần aggregate result vì nhiều live-out register slot phải
return cùng nhau. 050 không coi mọi State field là C parameter thường:
field unresolved/observable ở lại sau compatibility boundary.

## Rewrite transaction

`InferFunctionABISignatures` creates a plan; `CloneNativeFunctions` makes
`.native` definitions; `RewriteNativeFunctionBodies` replaces proven State
loads with arguments and rewrites return state; `RewriteKnownCallsites` builds
the matching call and projects return fields. Only after this direct evidence
is consumed does `CreateRemillWrappers` retain a lifted wrapper for genuinely
dynamic users. `CleanupDeadRemillABI` removes old artifacts only when unused.

`LowerCallbackAndSharedStateABI` is separate because callbacks and a shared
register-State context have non-local lifetime/reentrancy conditions. An
unresolved callback must remain lifted rather than receiving a guessed native
prototype.

## Boundary riêng của scanf

`NormalizeScanfI32Boundaries` accepts only a fully proven direct
`scanf("%d", int*)` form and routes it through a typed wrapper. It does not
claim that arbitrary scanf memory is nocapture or readonly; that belongs to
the more detailed 060/090 memory contracts. `test_scanf_i32_boundary.ll` also
runs standard O3 to ensure the wrapper stays semantically valid after
optimization.

## Test

- `test_callback_native_abi.ll`: accepted callback native ABI.
- `test_callback_unresolved_preserved.ll`: unknown callback is retained.
- `test_deep_nonmemory_result.ll`: live-out result can survive non-memory
  transport.
- `test_guest_boundary_clone.ll`: default mode consumes ordinary direct calls;
  `-brighten-050-preserve-guest-boundary` retains only explicitly pinned
  compatibility boundary through O3.
- `test_scanf_i32_boundary.ll`: narrow typed scanf contract.

Runner áp FileCheck lên mọi fixture rồi kiểm pinned clone sống qua O3; ABI
rewrite nhìn đúng nhưng không ổn định dưới optimizer vẫn fail.

## Giải thích implementation, không chỉ tên rule

### Trước hết: ABI là gì trong pass này?

ABI là quy ước caller/callee trao đổi arguments và return. Trong lifted IR,
caller ghi RDI/RSi/... vào `State`, gọi `sub(state, pc, memory)`, sau đó load
RAX/RDX từ State. Trong native SysV ABI, caller truyền values làm LLVM function
arguments và callee `ret` value. 050 chỉ thay transport State bằng ABI native
khi cả hai phía có evidence.

### `NormalizeRegisterAccesses` và primitive nhận register

`IdentifyStateOffset` không chỉ nhìn name. Nó strip pointer cast/alias, dùng
`stripAndAccumulateConstantOffsets(DataLayout, ...)`, rồi accept base
`@__mcsema_reg_state` hoặc arg0 **chỉ** nếu function có canonical lifted shape
`(ptr, i64, ptr) -> ptr` (native `.native` có rule arg0 riêng). Offset âm,
base user pointer, hoặc GEP không resolve không phải State access. Sau đó
`IdentifyRegAccess` biến exact load/store thành `(ABIReg, offset, type, value,
isLoad/isStore)`. Đây là guard ngăn `alloca` application bị lầm thành RDI chỉ
vì nó dùng GEP large offset.

### `AnalyzeFunctionLiveIns`

Rule (trong `RuleAnalyzeFunctionLiveIns.cpp`) dùng register-access primitive
để ghi `LiveIns`: register được load trước definition local là candidate input;
type và load count cũng được ghi. Nó không tự kết luận “mọi RDI load là C arg”:
callsite evidence ở rule sau còn có thể đổi/merge type.

### `AnalyzeFunctionLiveOuts`

Với từng summary, rule thu mọi store vào return register. Mỗi `ret` phải có
reaching RAX value do `FindRegisterValueBeforeReturn` tìm được; tất cả ret
phải return original memory argument. RDX được kiểm full width `i64`/pointer
riêng. Thiếu một return edge thì `HasCompleteReturnValues=false`, không tạo
native return dựa trên một happy path.

Metadata `brighten.return_candidate` do 020 tạo cũng là evidence, nhưng không
đủ một mình để suy luận i128. RDX:RAX chỉ thành one `i128` return nếu callee
có store RDX live-out, RDX không là input ABI, và **một cùng callsite** observe
cả RAX lẫn RDX. Nếu góp RAX từ caller A và RDX từ caller B, pass sẽ bịa ABI
composite không hề tồn tại.

### `AnalyzeCallsiteABI`

Với direct call target có summary, rule scan ngược trong cùng basic block từ
call. Nó lấy store gần nhất của mỗi argument register; gặp inline asm hoặc
barrier call thì dừng, vì store xa hơn có thể đã bị clobber. Sau call, nó scan
đến khi gặp store register/call non-intrinsic để biết caller có thật load RAX
hay RDX không. Kết quả `CallsiteABIInfo` chứa stored argument values/types,
observes return và cờ `RewritableMemoryResult`.

Memory result lifted chỉ được replace nếu call không có use, hoặc summary đã
chứng minh mỗi return trả original memory argument. Nếu call return pointer có
meaning khác mà code thay bằng native return/void thì memory dependency bị mất.

### `InferFunctionABISignatures`

`InferHiddenArgs` giữ State/PC/Memory argument nếu argument gốc còn use trong
body clone; 050 không cố loại hidden argument trước khi body rewrite chứng
minh được dead. `InferArgs` đi SysV argument order, lấy register có live-in
hoặc callsite store evidence, rồi `MergeABIType(live-in type, callsite type)`;
không merge được thì dùng default type của register. `InferReturn` tạo void,
RAX hoặc RDX:RAX theo proof phía trên.

Function recursion không bị loại tự động. Clone native được tạo trước, sau đó
`RewriteKnownCallsites` retarget self-call trong cloned body; bỏ recursive
function sẽ để State/PC/Memory ABI sống không cần thiết.

### `CloneNativeFunctions` và `RewriteNativeFunctionBodies`

Clone rule rename original `foo` thành `foo.remill`, tạo internal
`foo.native`, đặt params theo thứ tự hidden args còn live rồi args SysV
recovered, map old arguments sang new arguments bằng `ValueToValueMapTy` và
`CloneFunctionBodyInto`.

Body rewrite mới canonicalize State pointer, replace proven live-in loads bằng
native args, và đổi returns thành `ret` recovered value/aggregate. Nó không
thể replace load State chưa có argument evidence; value đó tiếp tục State
transport. Đây là lý do “clone đã có `.native`” không đồng nghĩa full native.

### Các rule sau clone

- `RewriteKnownCallsites`: materialize arguments từ exact stores đã thu, call
  `.native`, nối return fields về RAX/RDX users, chỉ xóa old call khi memory
  result safe như phân tích trên.
- `NormalizeScanfI32Boundaries`: chỉ direct `%d` + `i32*` proven boundary;
  không thay scanf hay claim arbitrary pointer nocapture.
- `LowerCallbackAndSharedStateABI`: handles callback/shared State context vì
  ordinary direct-call rewrite không chứng minh lifetime/reentrancy.
- `CreateRemillWrappers`: old lifted wrapper là compatibility boundary cho
  dynamic users còn lại, không được tạo trước khi direct calls đã recover.
- `RewriteMainWrapper`: chuyển entry wrapper sang native public `main` shape.
- `CleanupDeadRemillABI`: only dead old functions/wrappers/artifacts bị xoá.

### Test đọc như proof

`test_callback_unresolved_preserved.ll` tồn tại để chặn việc đoán prototype
callback. `test_deep_nonmemory_result.ll` kiểm return không biến thành memory
token. `test_guest_boundary_clone.ll` chạy default và option preserve; option
chỉ giữ function đã có `noinline`/versioned boundary marker, rồi O3 phải vẫn
call clone đó. `test_scanf_i32_boundary.ll` chạy O3 sau pass: check không chỉ
shape output first pass mà contract tồn tại qua optimizer.
