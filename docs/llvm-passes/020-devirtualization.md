# 020 — devirtualization và region-SSA unflattening

**Plugin:** `BrightenDevirtPass.so`  
**Tên pipeline:** `brighten-devirt-pass`,
`brighten-region-ssa-unflatten-pass`

Control flow lifted thường mã hoá `call`, `jmp`, `ret` thành store State rồi
call vào PC dispatcher. 020 chỉ khôi phục CFG LLVM khi target **và** SSA value
transport qua edge mới đều được chứng minh; direct branch đẹp nhưng thiếu PHI
incoming vẫn là IR sai.

## `brighten-devirt-pass`

Entry point gọi đúng thứ tự:

```text
LowerExternalCalls
DevirtualizeRemillFunctionCalls
DevirtualizeRemillJumps
AnnotateRemillReturns
CleanupCallbackThunks
CleanupUnusedRemillDispatchers
LowerProvenConstantStateSwitches
VerifyDevirtualization
GlobalDCE
```

`ParseAddressName`, `ExtractConstantPC`, and `ResolveExternalFunction` follow
names, aliases, casts, loads and finite constants to map a guest PC to
`sub_<hex>` or external symbol. A dynamic PC is not guessed.

Shape được nhận, ví dụ:

```llvm
call ptr @__remill_function_call(ptr %state, i64 4198400, ptr %mem)
```

có thể thành direct call `sub_401000` chỉ khi dispatcher table và signature
khớp. `%pc` load từ State mutable phải giữ indirect; `mutable_guest_pc.ll` và
`dynamic_state_switch.ll` kiểm tra đúng refusal này.

`AnnotateRemillReturns` follows reaching definitions of RAX to tag/retain the
value which is semantically returned by the lifted routine. It refuses a call
boundary that may clobber State; `return_rax_reaching_definition.ll` is the
positive regression.

`LowerProvenConstantStateSwitches` removes a switch case only when the state
value reaching that switch is constant. `proven_state_switch.ll` additionally
runs original and rewritten IR with `lli` and compares exit status.

## Region SSA unflattening: bypass header chỉ khi dựng lại được value

`brighten-region-ssa-unflatten-pass` tách riêng vì direct edge có thể bypass
dispatcher/header đang tính PHI. Nó chỉ thread region nếu từng value target
dùng đều dựng lại được trên edge mới và dominance vẫn hợp lệ.

Các refusal test là phần cốt lõi:

- `region_ssa_cross_carried.ll`: cross-carried value cannot be partially
  threaded; no `region.thread` block may appear.
- `region_ssa_self_carried_refused.ll` and
  `region_ssa_header_value_refused.ll`: a header/self PHI value is unavailable
  on an edge that bypasses its defining iteration.
- `region_ssa_edge_local_carried.ll`: edge-local carried value is accepted and
  differential execution checks its result.

Proof thiếu thì dispatcher còn nguyên; partial de-flatten CFG là kết quả sai.

## Chi tiết source-grounded theo rule

### `LowerExternalCalls` chỉ là bridge tạm, không phải libc recovery đầy đủ

Rule tìm `CallInst` trực tiếp tới `@__remill_function_call`; `invoke` tương tự
chỉ log warning, không hạ. PC argument phải được `ResolveExternalFunction`
resolve thành external function. Sau đó rule loại ngay:

- `scanf` family: cần format-aware vararg/path proof, để 060 xử lý;
- mọi vararg generic;
- `setjmp/longjmp`, `qsort`, `bsearch`, `atexit`, signal, pthread, fork,
  system, exec: ABI/control effect đặc biệt;
- function không nằm trong whitelist libc safe;
- hơn 6 GP args (stack args), hơn 3 XMM args, aggregate/vector type, hoặc
  translator guest pointer chưa có body.

Với accepted non-vararg, rule đọc argument từ State offsets SysV:

```text
RDI 2296, RSI 2280, RDX 2264, RCX 2248, R8 2344, R9 2360
XMM0 16, XMM1 80, XMM2 144
```

Integer được trunc/zext theo destination type. Pointer argument không chỉ dựa
vào declaration: `IsPointerArg` có bảng theo tên (`puts`, `memcpy`, `fgets`,
`free`...) vì McSema có thể khai báo pointer ABI thành `i64`. Nó gọi
`__translate_guest_pointer(raw, is_write)` trước call; `is_write` true đúng ở
destination `memcpy/memmove/memset`, `fread`, `fgets`, `time`. Không coerce
được một argument thì **bỏ toàn bộ call**, không đưa null để “cho chạy”.

Return integer/pointer được store về RAX; FP float/double được bitcast và store
XMM0. Original Remill memory result, nếu có use, được thay bằng original memory
argument—not by native call result—vì đó là contract memory token của lifted
call. Đây là bridge tạm; 050/060/090 mới loại State transport hoàn toàn.

### `AnnotateRemillReturns` không đổi `ret`, nó đưa evidence cho 050

RAX location được nhận dạng bằng alias name `RAX_*` hoặc GEP constant offset
2216 từ `@__mcsema_reg_state`. Với mỗi `ret`, pass đi ngược CFG tối đa depth
32:

1. quét ngược instruction trong block, lấy store gần nhất vào RAX;
2. nếu gặp call có thể ghi memory/State trước store đó, dừng (không dùng RAX
   stale);
3. không có store thì recurse mọi predecessor;
4. mọi predecessor cùng value thì dùng value đó; khác value chỉ accept nếu
   block đã có PHI có đúng incoming `(pred,value)`.

Giá trị tìm được chỉ được gắn operand bundle `llvm.sideeffect
["brighten_return_rax"(value)]` ngay trước ret nếu definition dominate ret.
Bundle là use thật, ngăn DCE xoá evidence; metadata `brighten.return_rax.info`
và `brighten.return_candidate` mô tả type/name. Không dominate thì skip, vì
gắn value từ một predecessor lên join return sẽ làm IR invalid.

### `CleanupUnusedRemillDispatchers`

Các `__remill_*` dispatcher defined external linkage được internalize. Sau đó
`GlobalDCE` được plugin schedule ngay sau pass. Điều này không tự xóa dispatcher
động còn use: nó vẫn live và diagnostic “still needed”; nó chỉ bỏ SCC lifter
không reachable từ entry. `ext_*` use-empty cũng được xoá.

### `LowerProvenConstantStateSwitches`: proof rất hẹp

Rule không đánh giá “switch nhìn giống OLLVM”. Condition phải là một PHI trong
hub, có one use, bọc bởi chuỗi one-use `add/sub/mul/xor` với đúng một constant
operand mỗi bước và **không có `nsw/nuw`**. Với từng incoming `(constant,
predecessor)` của PHI, predecessor phải là unconditional branch thẳng vào hub.
Pass evaluate selector bằng `APInt`, chọn exact switch destination, rồi thay
branch predecessor bằng destination.

Trước mutation, hub chỉ được chứa switch, selector instructions và dead PHI;
live PHI/side effect làm từ chối. Không successor nào được có PHI, vì bypass
hub sẽ cần edge-sensitive incoming repair. Nếu có incoming dynamic, selector
flagged, nested dispatch có payload, hoặc destination quay lại hub, pass giữ
nguyên switch. Đây là lý do `dynamic_state_switch.ll` và
`carried_state_switch.ll` phải sống.

### `LowerRegionSSAStateSwitches`: trường hợp CFG mang application values

Rule riêng này xử lý shape `header PHIs -> switch hub -> case -> latch PHIs ->
header`. Nó cho phép affine selector `add/sub/mul/xor` qua hub hoặc pure
unconditional predecessor, nhưng trước first mutation phải chứng minh:

- unique latch và header/latch PHI có type/đường incoming tương ứng;
- mỗi transition constant resolve được qua switch/nested pure-switch path;
- mọi payload value có thể clone/map và dominate use mới;
- target PHI có incoming edge hợp lệ;
- không có self/header-carried value bị dùng trên direct edge bypass header.

Accepted transition tạo bridge `region.thread.*`, clone payload/latch
instructions theo edge, dùng `SSAUpdater` để chọn reaching value đúng, rồi sửa
PHI. Nếu một edge/budget/type/dominance check fail, candidate root không được
partial-thread. Vì vậy các fixture `region_ssa_phi_carried` và
`region_ssa_edge_local_carried` positive khác hoàn toàn với
`region_ssa_cross_carried`, `region_ssa_self_carried_refused`,
`region_ssa_header_value_refused` negative.

## Test evidence của 020

Runner không chỉ FileCheck: `proven_state_switch`, `region_ssa_state_switch`,
`region_ssa_self_hub`, `region_ssa_phi_carried`, `region_ssa_edge_local_carried`
đều chạy original và transformed bằng `lli-21` rồi so exit status. Đây là bằng
chứng rằng rewrite CFG giữ behavior của fixture, còn FileCheck xác nhận shape
IR được/không được tạo.
