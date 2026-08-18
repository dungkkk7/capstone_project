# 030 — đưa register State về SSA

**Plugin:** `BrightenStateSSAPass.so`  
**Tên pipeline:** `brighten-state-ssa-pass`, `brighten-local-state-ssa-pass`

Code lifted ghi register/flag kiến trúc vào byte offset của State shared. Dạng
này che data-flow thường:

```llvm
store i64 %next, ptr %state_rip
%rip = load i64, ptr %state_rip
```

Khi mọi use local và không observable, SSA là dạng tương đương:

```llvm
; use %next directly, adding PHIs at control-flow joins when required
```

Nhờ đó pass sau có thể chứng minh PC/RSP/flag hằng. Nhưng không hợp lệ nếu
pointer field escape, call có thể quan sát nó, hay ordering memory observable.

## Rule theo thứ tự

1. `LowerKnownFlagComputations`: forward công thức flag x86 đã biết thành
   Boolean `i1` khi safe.
2. `PromoteStateToSSA`: dùng State offset và def-use boundary để promote slot
   register safe.
3. `PromoteLocalStateAllocas`: tương tự với State copy local function.
4. `SimplifyFlagConsumers`: chuẩn hoá byte boolean, mask `and 1`, flag load
   thành branch/select `i1` canonical.

`StateOffsetResolver` là primitive proof chung: pointer phải resolve qua
GEP/cast được hỗ trợ về exact State byte offset. Integer-to-pointer tuỳ ý hay
offset động nằm ngoài rule.

## Test: mỗi fixture khóa một boundary

- `state_promotion_boundaries.ll`: safe slots promote, unsafe boundaries stay
  memory-backed.
- `flag_memory_observability.ll`: observable flag memory is not scalarized.
- `raw_flag_phi_preserved.ll`: unresolved/raw PHI flag remains as-is.
- `local_state_alloca_promotion.ll`: the local pass is run twice; output must
  be stable, proving the rewrite is idempotent.

## Chi tiết implementation theo rule

### `LowerKnownFlagComputations`: thực tế là forwarding an toàn, không phải xoá flag store toàn cục

Source tìm State global và `DiscoverFlagSlots`; nếu layout flag không resolve
được thì return không đổi. Nó scan toàn module để biết offset flag nào có
constant-offset load. Sau đó chỉ trong lifted function không có unsupported
State boundary, nó giữ map `LastFlagI8[offset]` trong **một basic block**.

```llvm
store i8 %zf, ptr %state_zf
%old = load i8, ptr %state_zf
```

thành use trực tiếp `%zf` chỉ khi load có exact same offset/type và kể từ store
không có volatile/atomic, unknown store/non-flag store, hay non-inline-asm call.
Mỗi invalidator clear toàn map. Rule không forward qua block boundary/PHI và
không xoá State store chỉ vì “chưa thấy load”: callback, dynamic offset hay
linked runtime có thể quan sát State. Biến `DeadCount` hiện luôn 0; comment
source xác nhận không có dead-store deletion ở rule này.

### `PromoteStateToSSA`: State field thành alloca trung gian, rồi LLVM SSA

Chỉ lifted ABI canonical mới được xét; một native function tình cờ có pointer
arg0 + GEP lớn không được hiểu nhầm là State. `invoke`, `callbr` và `musttail`
làm cả function bị skip vì flush/reload State quanh boundary đó chưa có proof.

Pass thu exact load/store offsets qua `ResolveStateOffset`. Nó từ chối toàn
function nếu State base lẫn `Arg0` và global, hoặc có volatile/atomic state
access. Với mỗi offset, lấy **maximum access width** và tạo alloca integer
width đó, ví dụ access i32/i64 tại offset 2216 dùng `alloca i64`. Các interval
khác offset nhưng overlap bị loại cả hai; scalarizing hai byte-overlap slots sẽ
làm write một slot không còn coherent với load slot kia.

Body rewrite:

```llvm
; entry
%state_2216 = alloca i64, !brighten.state.offset !{i64 2216}
%init = load i64, ptr %state+2216
store i64 %init, ptr %state_2216

; later original load/store State
%x = load i32, ptr %state+2216
store i32 %v, ptr %state+2216
```

trở thành load/store alloca. Sub-register store i32 vào alloca i64 dùng
mask-clear low 32 bits + zext value + or; vì x86 write phần register không
phải luôn overwrite whole lifted State cell. Pointer load/store dùng
`inttoptr`/`ptrtoint`; float/vector dùng bitcast theo exact store size.

Trước call có thể observe State, pass flush mọi eligible alloca về State;
sau call reload lại. Declaration libc không nhận State được bỏ qua. Trước mọi
`ret`, pass flush lần nữa. Điều này giải thích tại sao pass chưa “xoá State”:
nó tách local data flow để `mem2reg`/pass sau tối ưu, nhưng giữ observable ABI
boundary.

### `PromoteLocalStateAllocas`: local register file chỉ được split nếu closed graph

Candidate là static alloca có tên `state/State`, named struct State/ArchState,
hoặc array/counted array từ 1000 elements. `collectPointerUsers` chỉ cho phép:

- exact load/store không volatile/atomic;
- constant-offset GEP, bitcast, addrspacecast;
- một zero `memset` hoặc aggregate-zero store làm initializer.

Unknown call, pointer escape, dynamic/negative offset, scalable size hoặc nonzero
initializer làm reject whole candidate. Sau đó rule đòi zero initializer
dominate **mọi** access, types tại cùng offset identical và các range không
overlap. Chỉ khi pass materialize được slot cho mọi load, nó tạo `alloca` typed
per offset, redirect access, xoá zero init/old pointer graph và gọi
`PromoteMemToReg` với DominatorTree. Không complete thì original alloca sống;
không substitute zero cho load chưa model.

### `SimplifyFlagConsumers`: i8 flag chỉ thành i1 khi tất cả incoming là boolean

Rule lấy i8 PHI và chỉ canonicalize PHI khi mọi incoming là một trong:

- `zext i1`;
- constant 0 hoặc 1;
- `and X, 1`;
- sign-bit idiom `trunc (lshr value, bitwidth-1)`;
- PHI đã được chứng minh canonical trong fixed point.

Raw load từ State flag offset **không** đủ: State byte ở entry/boundary có thể
là 2, 255 hoặc giá trị observable khác, dù offset trông là cờ. Với accepted PHI
rule tạo i1 PHI, chuyển từng incoming; `icmp ne/eq %flag,0` dùng trực tiếp i1
hoặc `not`; store back State dùng `zext i1 -> i8`; use i8 khác nhận zext.
Ngoài PHI, pattern `icmp {eq,ne} (zext i1 X), 0` được hạ trực tiếp.

### Test map

- `state_promotion_boundaries.ll`: mixed base, volatile/atomic/overlap/call
  boundary không được promote bừa.
- `flag_memory_observability.ll`: unknown memory/call invalidates forwarding.
- `raw_flag_phi_preserved.ll`: raw State-byte PHI không biến thành i1.
- `local_state_alloca_promotion.ll`: graph closed + zero init positive; runner
  chạy local pass hai lần để đảm bảo pass second run không sinh rewrite mới.
