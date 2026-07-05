## Brighten Native Recovery Pipeline

Mục tiêu tổng thể: chuyển LLVM IR do McSema/Remill lift ra từ mô hình giả lập CPU-state sang LLVM IR native hơn, dễ tối ưu, dễ đọc, và có thể compile/fuzz kiểm tra semantic equivalence.

---

## PHASE 1 — Structural Repair / IR Hygiene

**Mục tiêu:** làm IR hợp lệ, bớt UB giả, bớt crash optimizer. Phase này chưa có nhiệm vụ biến IR thành native hoàn toàn.

**Input:** McSema lifted IR thô.

**Output:** IR đã được repair/normalize, nhưng có thể vẫn chưa link được nếu còn `__remill_function_call` hoặc `__remill_jump`.

**Pass chính:**

* `brighten-repair-pass`

**Cần làm:**

* Strip các flag/metadata dễ gây poison hoặc UB giả:

  * `nsw`
  * `nuw`
  * `exact`
  * `inbounds`
* Strip các attribute nguy hiểm trên lifted function/call-site:

  * `noalias`
  * `nonnull`
  * `noundef`
  * `dereferenceable`
  * `align` sai
* Loại bỏ các directive assembly cũ do McSema nhúng qua inline asm nếu chúng không mang semantic runtime:

  * `.cfi_*`
  * `.loc`
  * `.file`
  * `.type`
  * `.size`
  * `.p2align`
  * `.intel_syntax`
  * `.att_syntax`
* Resolve alias rác do McSema sinh ra, đặc biệt alias trỏ vào `__mcsema_reg_state`.
* Canonicalize guest address constants:

  * `ptrtoint(@data_xxx)`
  * `ptrtoint(@seg_xxx + offset)`
  * `ptrtoint(@sub_xxx)`
* Repair các mẫu stack subtraction bị obfuscate:

  * `RSP - ptrtoint(@data_xxx)`
  * `RSP + ptrtoint(@sub_xxx)`
* Fix callback function pointer stores:

  * `ptrtoint(@callback_sub_1234)` → `0x1234`
  * Sau đó xóa callback thunk nếu không còn use.

**Không nên làm trong phase này:**

* Không inject dispatcher runtime lớn.
* Không rewrite external libc call.
* Không translate mọi `inttoptr` thành runtime helper.
* Không synthesize `main`.
* Không save/restore callee-saved registers.

---

## PHASE 1.5 — Remill Runtime Compatibility Layer

**Mục tiêu:** materialize/lower toàn bộ Remill intrinsics còn lại sau Phase 1 để IR có thể link, compile, fuzz, và chạy semantic-equivalence ở chế độ compatibility.

**Lưu ý:** phase này làm IR chạy được và không thiếu symbol. Nó không phải native recovery thật sự, và có thể làm LOC tăng.

**Input:** IR sau Phase 1.

**Output:** IR linkable/runnable, không còn unresolved `__remill_*` declaration ngoài allowlist rõ ràng.

**Pass đề xuất:**

* `brighten-remill-runtime-pass`

**Rule layout đề xuất:**

* `RuleDefineRemillControlFlowRuntime.cpp`
* `RuleLowerRemillMemoryIntrinsics.cpp`
* `RuleDefineRemillPureValueIntrinsics.cpp`
* `RuleDefineRemillAtomicBarrierRuntime.cpp`
* `RuleDefineRemillArchHypercallStubs.cpp`
* `RuleVerifyNoUnresolvedRemillIntrinsics.cpp`

**Pass order đề xuất:**

```cpp
Changed |= DefineRemillControlFlowRuntime(M);
Changed |= LowerRemillMemoryIntrinsics(M);
Changed |= DefineRemillPureValueIntrinsics(M);
Changed |= DefineRemillAtomicBarrierRuntime(M);
Changed |= DefineRemillArchHypercallStubs(M);
Changed |= VerifyNoUnresolvedRemillIntrinsics(M);
```

**Nhóm bắt buộc:**

* Control-flow runtime:

  * `__remill_function_call`
  * `__remill_jump`
  * `__remill_function_return`
  * `__remill_missing_block`
  * `__remill_error`
  * `__remill_async_hyper_call`
  * `__remill_sync_hyper_call`

  `__remill_function_call` và `__remill_jump` dispatch PC tới `sub_<pc>` hoặc `ext_<pc>_*`. `__remill_function_return`, `__remill_missing_block`, `__remill_error`, và hypercall chưa model được thì fallback return memory trong fuzz mode.

* Memory runtime:

  * `__remill_read_memory_{8,16,32,64}`
  * `__remill_write_memory_{8,16,32,64}`
  * `__remill_read_memory_{f32,f64,f80,f128}`
  * `__remill_write_memory_{f32,f64,f80,f128}`

  Compatibility mode lower qua `__translate_guest_pointer(addr, true)` rồi dùng LLVM `load/store`. Native clean object/GEP recovery để Phase 2+.

* Undefined-value runtime:

  * `__remill_undefined_{8,16,32,64}`
  * `__remill_undefined_{f32,f64}`
  * nếu input có `f80/f128`, dùng deterministic zero theo return type.

  Không return `undef`; integer undefined trả `0`, float undefined trả `0.0`.

* Flags/compare runtime:

  * `__remill_flag_computation_{zero,sign,overflow,carry}` nếu xuất hiện trong IR.
  * `__remill_compare_{sle,slt,sge,sgt,ule,ult,ugt,uge,eq,neq}` nếu xuất hiện trong IR.

  Compatibility mode trả deterministic fallback hoặc passthrough result argument nếu signature cho phép. Logic đúng để Phase 3 flag-lower.

* Barrier/atomic/delay-slot runtime:

  * `__remill_barrier_load_load`
  * `__remill_barrier_load_store`
  * `__remill_barrier_store_load`
  * `__remill_barrier_store_store`
  * `__remill_atomic_begin`
  * `__remill_atomic_end`
  * `__remill_delay_slot_begin`
  * `__remill_delay_slot_end`
  * `__remill_compare_exchange_memory_{8,16,32,64,128}`
  * `__remill_fetch_and_{add,sub,and,or,xor,nand}_{8,16,32,64}`

  Barrier/atomic begin/end/delay-slot return memory. Atomic RMW translate addr, load old, compute/store new, update reference arg, return memory.

* FPU runtime:

  * `__remill_fpu_exception_test_and_clear`
  * `__remill_fpu_exception_test`, `__remill_fpu_exception_clear`, `__remill_fpu_exception_raise`, `__remill_fpu_set_rounding`, `__remill_fpu_get_rounding` nếu có trong input.

  Nếu chưa map sang `cfenv`, fallback deterministic: exception test trả `0`, clear/raise/set no-op, get_rounding trả default/nearest.

* I/O port runtime:

  * `__remill_read_io_port_{8,16,32}`
  * `__remill_write_io_port_{8,16,32}`

  Userspace compatibility: read trả `0`, write return memory.

* Architecture-specific runtime:

  * `__remill_x86_*`
  * `__remill_amd64_*`
  * `__remill_aarch64_*`
  * `__remill_aarch32_*`
  * `__remill_sparc_*`
  * `__remill_ppc_*`

  Với x86_64 McSema, ưu tiên x86/amd64. Fallback return memory/zero theo return type và emit warning; control/debug register helpers phải được log vì là case đặc biệt.

**Verifier cuối phase:**

* Scan mọi `Function` declaration có prefix `__remill_`.
* Nếu còn unresolved:

  * strict mode: fail pass.
  * fuzz mode: materialize trap/fallback stub và warning.

**Không nên nhầm với Phase 2:** đây chỉ là compatibility layer để chạy được, chưa phải devirtualization/native-clean IR.

---

## PHASE 2 — Call / Return Devirtualization

**Mục tiêu:** loại bỏ Remill-style indirect control flow và chuyển call/return/jump về LLVM control flow trực tiếp hơn.

**Input:** IR sau Phase 1, hoặc Phase 1.5 nếu cần chạy được.

**Output:** IR giảm phụ thuộc vào `__remill_function_call`, `__remill_jump`, dispatcher, callback thunk.

**Pass chính:**

* `brighten-devirt-pass`
* `brighten-remill-call-lower`
* `brighten-remill-jump-lower`
* `brighten-remill-return-lower`

**Cần làm:**

* Chuyển call qua PC constant:

  `__remill_function_call(state, 0x401230, mem)`

  thành:

  `call @sub_401230(state, 0x401230, mem)`

* Chuyển jump PC constant:

  `__remill_jump(state, 0x401500, mem)`

  thành direct branch hoặc direct call tới block/function tương ứng.

* Lower return thô:

  * McSema thường lưu return value vào RAX trong State rồi return memory/void.
  * Cần chuyển thành LLVM `ret` trả về giá trị thật nếu đã xác định được ABI return.

* Xóa callback thunk/dispatcher không còn ai dùng.

**Cleanup sau phase:**

* `globaldce`
* `dce`
* `simplifycfg`
* `called-value-propagation`
* `ipsccp` nếu an toàn

---

## PHASE 3 — Register State SSA Recovery

**Mục tiêu:** thay mô hình load/store register trong `%struct.State` bằng SSA value cục bộ.

**Input:** IR sau devirtualization, vẫn còn nhiều truy cập `__mcsema_reg_state` hoặc `%state`.

**Output:** register guest như RAX/RBX/RDI/RSI/RSP/RIP dần trở thành SSA value thay vì load/store qua memory.

**Pass chính:**

* `brighten-state-ssa-pass`
* `brighten-flag-lower`

**Cần làm:**

* Nhận diện các slot register trong `%struct.State`.
* Promote load/store register thành SSA nếu phạm vi an toàn.
* Tách state field thành virtual register:

  * `RAX`
  * `RBX`
  * `RCX`
  * `RDX`
  * `RSP`
  * `RBP`
  * `RDI`
  * `RSI`
  * `R8`–`R15`
  * `RIP`
* Lower CPU flags:

  * `CF`
  * `ZF`
  * `SF`
  * `OF`
  * `PF`
* Chuyển các phép tính flag phức tạp thành logic `i1` cục bộ để LLVM `gvn`, `instcombine`, `dce` có thể tối giản branch.

**Cleanup sau phase:**

* `mem2reg`
* `sroa`
* `early-cse`
* `instcombine`
* `gvn`
* `dce`
* `simplifycfg`

---

## PHASE 4 — Stack Frame Recovery

**Mục tiêu:** thay guest stack dựa trên RSP bằng stack native LLVM dựa trên `alloca`.

**Input:** IR sau State SSA, trong đó RSP đã dễ trace hơn.

**Output:** local variable được biểu diễn bằng `alloca`, GEP, load/store native thay vì `inttoptr(RSP + offset)`.

**Pass chính:**

* `brighten-stack-model`
* `brighten-host-frame`
* `brighten-stack-frame-pass`

**Cần làm:**

* Dựng stack frame map bằng cách trace toán hạng RSP trong SSA.

* Nhận diện offset stack:

  * local variable
  * spilled register
  * temporary slot
  * outgoing call argument

* Thay thế access kiểu:

  `inttoptr(RSP - 0x20)`

  bằng:

  `alloca` hoặc GEP vào frame object.

* Phân biệt:

  * stack local cố định
  * stack argument
  * dynamic stack allocation
  * stack slot bị escape

**Trường hợp khó cần xử lý:**

* Biến local bị truyền địa chỉ sang hàm khác.
* Stack pointer bị arithmetic phức tạp.
* Local array.
* Struct nằm trên stack.
* `memcpy`, `memset`, `scanf`, `fgets`, `read` ghi vào stack buffer.

**Cleanup sau phase:**

* `sroa`
* `mem2reg`
* `instcombine`
* `dse`
* `gvn`
* `dce`

---

## PHASE 5 — ABI Recovery / Function Signature Rewrite

**Mục tiêu:** chuyển function signature từ Remill-style sang LLVM/native ABI-style.

**Input:** function vẫn có dạng gần như:

`ptr @sub_xxx(ptr %state, i64 %pc, ptr %mem)`

**Output:** function có signature gần với C/native IR hơn:

`i32 @foo(i32 %a, ptr %buf)`

**Pass chính:**

* `brighten-livein-liveout`
* `brighten-abi-rewrite`
* `brighten-return-rewrite`

**Cần làm:**

* Phân tích live-in register của từng hàm để xác định tham số:

  * `RDI`
  * `RSI`
  * `RDX`
  * `RCX`
  * `R8`
  * `R9`
  * XMM registers nếu cần
* Phân tích live-out register để xác định return value:

  * `RAX`
  * `RDX:RAX`
  * XMM0
* Rewrite function signature.
* Rewrite call sites tương ứng.
* Xóa tham số `%state`, `%pc`, `%mem` nếu không còn cần.
* Chạy `deadargelim` ngay sau đó để xóa tham số ABI mặc định nhưng không dùng.

**Cleanup sau phase:**

* `deadargelim`
* `globalopt`
* `function-attrs`
* `ipsccp`
* `dce`

---

## PHASE 6 — External Call / Libc ABI Recovery

**Mục tiêu:** chuyển external call stub do McSema sinh ra thành call native tới libc/API thật.

**Input:** IR còn external-call stub hoặc call gián tiếp qua PC tới external symbol.

**Output:** call trực tiếp như LLVM IR bình thường.

**Pass chính:**

* `brighten-extern-call-bridge`
* `brighten-vararg-call-recover`
* `brighten-libc-signature-fix`

**Cần làm:**

* Nhận diện external call stub:

  `__remill_function_call(state, ptrtoint(@printf), mem)`

* Đọc argument từ ABI register.

* Convert guest pointer sang pointer native nếu đã recover được global/stack object.

* Gọi trực tiếp external function:

  `call i32 @printf(ptr %fmt, ...)`

* Ghi return value về SSA/native return path thay vì RAX nếu Phase 5 đã hoàn tất.

* Xử lý vararg function:

  * `printf`
  * `scanf`
  * `fprintf`
  * `sprintf`
  * `sscanf`

**Lưu ý:** không nên dùng runtime helper quá rộng kiểu translate mọi `inttoptr` nếu mục tiêu là IR native. Chỉ dùng fallback cho fuzz/runtime mode.

---

## PHASE 7 — Global / Data Recovery

**Mục tiêu:** khôi phục global variable, string literal, jump table, rodata/data section thành LLVM global rõ nghĩa.

**Input:** IR còn nhiều `@seg_...`, `@data_...`, raw byte array, guest address constant.

**Output:** global/data rõ ràng hơn, dễ đọc và dễ optimize xóa bỏ `@seg_...`, `@data_...` .

**Pass chính:**

* `brighten-string-recover`
* `brighten-global-object-recover`
* `brighten-jumptable-recover`

**Cần làm:**

* Quét các phân đoạn:

  * `@seg_...__rodata`
  * `@seg_...__data`
  * `@data_xxx`

* Recover string literal:

  `@.str = private unnamed_addr constant [N x i8] c"...\00"`

* Thay guest address trỏ vào rodata bằng GEP tới string/global tương ứng.

* Recover global scalar/array nếu pattern rõ.

* Nhận diện jump table:

  * table chứa PC/address
  * index tính từ condition
  * indirect jump/switch qua table

* Chuyển jump table thành LLVM `switch` hoặc CFG sạch.

**Cleanup sau phase:**

* `globalopt`
* `constmerge`
* `simplifycfg`
* `jump-threading`
* `dce`

---

## PHASE 8 — Type Reconstruction

**Mục tiêu:** dựng lại kiểu dữ liệu cấp cao hơn từ pattern load/store/GEP.

**Input:** IR đã có stack/global object rõ hơn nhưng type còn thô như `i8*`, `[N x i8]`, integer offset.

**Output:** IR có struct/array/pointer type hợp lý hơn.

**Pass chính:**

* `brighten-type-reconstruct`
* `brighten-struct-recover`
* `brighten-array-recover`

**Cần làm:**

* Phân tích GEP/load/store theo offset.
* Nhóm các field liên tiếp thành struct.
* Nhận diện array bằng stride đều.
* Dựa trên alloca/global recovered từ Phase 4 và Phase 7 để suy luận type.
* Rewrite GEP byte-offset thành typed GEP nếu an toàn.

**Trạng thái:** Đã hoàn thành thiết kế, implement và kiểm thử (21/21 tests passed).

**Lưu ý:** phase này nên chạy sau stack/global recovery. Nếu chạy sớm, type inference dễ sai vì object boundary chưa rõ.

---

## PHASE 9 — Final Native Cleanup

**Mục tiêu:** xóa phần McSema/Remill còn sót và chuẩn hóa IR native cuối cùng.

**Input:** IR đã native hóa phần lớn.

**Output:** LLVM IR sạch, ít State/Remill artifact, tối ưu được bằng LLVM chuẩn.

**Pass chính:**

* `brighten-type-cleanup`
* `brighten-remill-artifact-cleanup`
* LLVM cleanup pipeline

**Cần làm:**

* Xóa `%struct.State` nếu không còn dùng.
* Xóa `__mcsema_reg_state` nếu không còn dùng.
* Xóa Remill helpers không còn dùng:

  * `__remill_function_call`
  * `__remill_jump`
  * `__remill_function_return`
  * callback thunk
  * dispatcher
* Xóa type thừa, global thừa, declaration thừa.
* Chạy inference attribute:

  * `function-attrs`
  * `argpromotion`
  * `attributor` nếu ổn định
* Chạy cleanup cuối:

  * `sroa`
  * `mem2reg`
  * `instcombine`
  * `simplifycfg`
  * `gvn`
  * `dse`
  * `dce`
  * `globaldce`
  * `globalopt`

---

## Hai pipeline nên tách riêng

### 1. Pipeline để xem IR repair sạch

Dùng khi muốn kiểm tra Phase 1 không inject thêm runtime code.

```text
brighten-repair-pass
```

Output có thể chưa link được.

### 2. Pipeline để fuzz / semantic equivalence

Dùng khi cần compile `.bc` thành executable.

```text
brighten-repair-pass,
brighten-remill-runtime-pass,
brighten-devirt-pass,
brighten-state-ssa-pass,
brighten-stack-frame-pass,lll
brighten-abi-rewrite-pass,
brighten-global-recover-pass,
brighten-final-cleanup-pass
```

Nếu chưa đủ pass native recovery, ít nhất cần:

```text
brighten-repair-pass,
brighten-remill-runtime-pass
```

để tránh lỗi unresolved `__remill_*` khi compile/fuzz.

---

## Nguyên tắc quan trọng

* Phase 1 chỉ sửa IR, không cố làm IR chạy được.
* Remill runtime compatibility nên là phase riêng.
* Devirtualization nên chạy trước State SSA.
* State SSA nên chạy trước Stack Frame Recovery.
* Stack/Global recovery nên chạy trước Type Reconstruction.
* Native cleanup chỉ chạy cuối, khi artifact Remill/McSema đã thật sự không còn cần.
