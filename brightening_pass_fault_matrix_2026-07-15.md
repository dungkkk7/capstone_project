# Brightening IR — Ma trận pass sai, thiếu và chưa hiệu quả

Ngày đánh giá: 2026-07-15

## Quy ước mức kết luận

- **S — Sai semantics đã xác định:** Có thể dựng counterexample trực tiếp từ rewrite trong source; không cần dựa vào suy đoán hiệu năng.
- **U — Unsound nếu thiếu proof:** Rewrite chỉ đúng dưới một tiền điều kiện semantic nhưng pass chưa chứng minh đầy đủ tiền điều kiện đó.
- **M — Thiếu recovery:** Pass không đủ coverage để native hóa; giữ artifact không phải lỗi, nhưng không được dùng fallback giả để che phần thiếu.
- **I — Chưa hiệu quả/khó kiểm chứng:** Thứ tự hoặc phạm vi pass làm mất provenance, khó xác định pass đầu tiên gây divergence, hoặc tạo ít native IR.

## Kết luận nhanh

| Thành phần | Kết luận chính | Mức |
|---|---|---|
| `brighten_010_repair_pass` | Repair quá rộng; bỏ poison-driving flags trên toàn module, không có provenance gate | U/I |
| `brighten_015_runtime_helper_materialization` | Compatibility shim bị đưa vào native pipeline và inline; placeholder có thể trở thành semantics cuối | S/U/I |
| `brighten_020_devirt_pass` | `PC == 0` chưa resolve bị biến thành trả Memory và xóa jump | **S/P0** |
| `brighten_030_state_ssa_pass` | Thiếu proof cho overlapping state bytes, subregisters, calls và state escape | U/M |
| `brighten_040_stack_frame_pass` | Coverage stack chưa đủ; nguy cơ split một stack object thành alloca và guest-memory/fake-stack | U/M |
| `brighten_050_abi_recovery` | Zero State, fabricate PC/Memory, null live result, có nguy cơ xóa target theo LLVM use-list | **S/P0** |
| `brighten_060_extern_call_bridge` | ABI/prototype suy từ symbol table và fixed State offsets; không đủ cho SysV | **U/P0** |
| `brighten_070_global_data_recovery` | Thiếu relocation/alias/TLS/interior-pointer proof; dead-segment logic không được dựa direct use-list | U/M |
| `brighten_080_type_reconstruction` | Unknown byte/unsupported constant bị đổi thành zero/null initializer | **S/P0-P1** |
| `brighten_090_native_cleanup` | Blanket `freeze`, PHI fabrication, fake global stack, null `envp`; cleanup đang invent semantics | **S/P0** |
| `britening_ir.py` | Compat shim + inline + O3 trước semantic gate; strict mặc định tắt; verifier bị dùng như acceptance | **Thiết kế P0** |

---

## 010 — `brighten_010_repair_pass`

### Vấn đề đã thấy

`RuleStripPoisonDrivingFlags.cpp:91-140` bỏ `nsw`, `nuw`, `exact` và `inbounds` trên phạm vi toàn module.

Bỏ các flag có thể hợp lý cho machine arithmetic do lifter gắn sai, nhưng không thể áp dụng như một repair mặc định cho:

- helper code đã có semantics riêng;
- native function đã recover;
- GEP mà `inbounds` là một fact đã chứng minh;
- instruction không có provenance từ McSema/Remill.

### Loại lỗi

- **U:** Chỉ hợp lệ khi chứng minh flag là artifact của lifter hoặc không phản ánh machine behavior.
- **I:** Làm mất bằng chứng về lỗi pass trước và khiến IR dễ optimize hơn trước khi semantics được xác nhận.

### Có thể gây lệch thế nào

- Một execution từng tạo poison/UB trong LLVM IR được biến thành wraparound hoặc pointer value cụ thể.
- O3 sau đó có thể chọn CFG/dataflow khác.
- Khó phân biệt repair đúng với việc chỉ làm verifier/optimizer chấp nhận.

### Cách sửa

- Chỉ sửa instruction có provenance lifted-machine-op.
- Ghi audit record: instruction, flag bị bỏ, lý do, source rule.
- Không sửa helper/native region mặc định.
- Repair không được tạo constant, pointer hay control-flow mới nếu không có proof.

---

## 015 — `brighten_015_runtime_helper_materialization`

### Vấn đề đã thấy

Pass materialize runtime helper/dispatcher để module có thể chạy hoặc tiếp tục transform. Trong `RuleDefineRemillControlFlowRuntime.cpp`, default dispatcher đi tới `__remill_missing_block`; các đường missing/error/return/hypercall không thể mặc định được coi là “trả incoming Memory”.

Hiện pipeline còn chạy `always-inline` ngay sau materialization. Kết quả là compatibility semantics bị nhúng thẳng vào lifted function và mất marker cho các pass sau.

### Loại lỗi

- **S nếu fallback reachable:** no-op/Memory-passthrough không tương đương missing block, trap, error, hypercall hay unresolved transfer.
- **U:** Chỉ được materialize để fuzz/compat nếu mọi path placeholder được theo dõi và không được cấp chứng nhận native.
- **I:** Inline quá sớm phá provenance và làm root-cause localization khó hơn.

### Có thể gây lệch thế nào

- Binary gốc trap/crash nhưng candidate return bình thường.
- Binary gốc tiếp tục dispatcher nhưng candidate thoát sớm.
- Mất side effect của hypercall/runtime.
- Timeout thành exit hoặc ngược lại.

### Cách sửa

- Tách `compat` pipeline khỏi `native` pipeline.
- Placeholder phải mang metadata/attribute rõ ràng và làm `native_strict` fail.
- Không inline compatibility helper trước khi chứng minh toàn bộ callsite đã recover.
- Unknown control-flow phải được giữ nguyên hoặc fail-closed, không no-op.

---

## 020 — `brighten_020_devirt_pass`

### Rewrite sai chắc chắn

`RuleDevirtualizeRemillJumps.cpp:110-124` có nhánh tương đương:

```cpp
if (PC là hằng 0 && không tìm thấy lifted target) {
  replaceAllUsesWith(Memory);
  erase __remill_jump;
}
```

Một unresolved jump không có semantics “trả lại memory token”. PC bằng 0 cũng không tự chứng minh function return.

### Loại lỗi

- **S/P0:** Có counterexample trực tiếp. Runtime có thể gọi missing-block/trap; rewrite biến nó thành normal continuation/return.

### Có thể gây lệch thế nào

- Early exit, sai exit code.
- Bỏ call hoặc bỏ loop.
- Crash của binary gốc thành success ở candidate.
- Output bị cắt ngắn.

### Thiếu/chưa hiệu quả

- Devirtualization chỉ nên commit khi target được chứng minh từ constant provenance, relocation, closed jump table hoặc path constraints.
- Không resolve được phải giữ dispatcher; không được guess.
- Cần report từng callsite: target-set, proof source và unresolved reason.

### Cách sửa bắt buộc

- Xóa hoàn toàn special case `PC == 0`.
- Dùng transactional rewrite: resolve toàn bộ semantics của callsite hoặc không đụng vào nó.
- Test riêng: PC=0, missing address, valid address 0 nếu address-space cho phép, multi-target PHI/select, jump table, indirect tail call.

---

## 030 — `brighten_030_state_ssa_pass`

### Không thấy forced constant rõ như pass 020/050, nhưng proof còn thiếu

State SSA chỉ sound nếu pass chứng minh được byte-range và effect của mọi access. Trên x86-64 phải xử lý:

- `AL/AH/AX/EAX/RAX` chồng lấn;
- EAX write zero-extend sang RAX;
- vector lanes và partial writes;
- flags/condition-code fields;
- GEP/bitcast khác hình thức nhưng cùng byte;
- call/helper/inline asm có thể đọc hoặc ghi `State`;
- `State*` escape qua call, global hoặc return;
- loop PHI và edge-specific value.

### Loại lỗi

- **U:** Nếu promotion dựa exact GEP/type hoặc offset đơn mà không xét overlapping byte ranges và clobber.
- **M:** Các access phức tạp không promote được; đây là thiếu coverage, không nên “sửa” bằng freeze ở 090.

### Có thể gây lệch thế nào nếu proof sai

- Dùng stale register qua call.
- Sai ZF/CF/OF dẫn đến đi nhầm branch.
- Partial write làm mất upper bits hoặc giữ upper bits sai.
- Loop không hội tụ hoặc đi sai iteration count.

### Cách sửa

- Canonicalize State thành byte-range SSA có known-mask.
- Promotion barrier tại mọi unknown call/effect; flush trước call, reload sau call.
- Không promote khi State escapes.
- PHI phải được tạo theo từng byte/field với predecessor coverage đầy đủ.
- Unit tests bắt buộc cho toàn bộ subregister và flags matrix.

---

## 040 — `brighten_040_stack_frame_pass`

### Thiếu chính

Pass stack recovery chưa đủ để thay guest stack trong các trường hợp:

- dynamic/non-affine RSP;
- stack pivot;
- 128-byte SysV red zone;
- stack arguments và return-address-relative access;
- alignment/realignment;
- address escape sang extern/callback;
- recursion, reentrancy, multi-thread;
- overlapping slots hoặc reuse theo lifetime;
- variable-size objects.

### Nguy cơ semantic

Nguy hiểm nhất là **partial recovery**: cùng một byte stack gốc bị biểu diễn vừa bằng native `alloca`, vừa bằng guest-memory/fake-stack. Khi đó alias bị tách và hai phía không còn thấy cùng write.

### Loại lỗi

- **U:** Commit partial frame khi chưa chứng minh mọi alias/use của frame object.
- **M:** Không recover được dynamic/escaping stack.
- **I:** Phần thiếu hiện bị pass 090 che bằng global fake stack, làm số artifact giảm nhưng semantics xấu hơn.

### Có thể gây lệch thế nào

- Extern ghi vào pointer stack nhưng native load đọc từ object khác.
- Recursion ghi đè frame trước.
- Red-zone local bị map sai.
- Wrong stack alignment làm crash ở code dùng SSE.
- Uninitialized local trở thành zero do fake backing.

### Cách sửa

- Recovery theo object phải transactional.
- Chỉ tạo `alloca` khi toàn bộ accesses thuộc một affine, non-escaping frame object đã được chứng minh.
- Escaping pointer cần một representation duy nhất và lifetime đúng.
- Native strict phải fail nếu còn unresolved stack; không chuyển sang global zero buffer.

---

## 050 — `brighten_050_abi_recovery`

### Rewrite sai chắc chắn

Trong `RuleRewriteMainWrapper.cpp`:

1. Dòng 38-55: `memset` zero toàn bộ local `State`.
2. Dòng 131-138: tạo hidden `PC = 0`, `Memory = null`.
3. Dòng 167-169: nếu wrapper call còn uses, thay toàn bộ result bằng null rồi xóa call.
4. Logic xóa lifted target/dispatcher dựa LLVM use-list là không đủ, vì guest indirect edge có thể chỉ tồn tại dưới dạng địa chỉ số/relocation và không tạo LLVM `Use`.

### Vì sao sai

- ABI không quy định toàn bộ architectural State bằng zero.
- Hidden PC/Memory là runtime contract, không phải optional placeholders.
- Live result không thể đổi thành null chỉ để cleanup.
- `use_empty()` không chứng minh guest-unreachable.

### Loại lỗi

- **S/P0.** Đây là semantic invention trực tiếp.

### Có thể gây lệch thế nào

- `argc/argv/envp` hoặc register đầu vào sai.
- Branch phụ thuộc flag/register chưa khởi tạo bị ép về zero.
- Mất return object/memory token.
- Indirectly reachable function bị xóa.
- Crash, wrong output, wrong exit và timeout đều có thể xảy ra.

### Phần ABI còn thiếu

Một native ABI recovery đúng cần cover ít nhất:

- GPR và XMM argument classes;
- stack-passed arguments;
- aggregate classification và `sret`;
- varargs và `%al` XMM-count;
- sign/zero extension;
- integer/FP/vector returns;
- callee-saved/caller-saved registers;
- stack alignment và red zone;
- tail calls, callbacks, noreturn, exception/longjmp boundary;
- `main(argc, argv, envp)`.

### Cách sửa bắt buộc

- Chỉ initialize State fields có source evidence từ entry ABI/loader.
- Một hidden argument chưa recover được phải hủy toàn rewrite.
- Live result phải được reconstruct hoặc giữ wrapper.
- Reachability phải hợp nhất LLVM CFG, numeric target map, relocations, address-taken set và external escape.

---

## 060 — `brighten_060_extern_call_bridge`

### Vấn đề cốt lõi

Bridge hiện dựa vào nhận diện symbol/signature table và các vị trí register trong Remill State. Tên hàm cộng vài fixed offsets không phải proof cho x86-64 System V ABI.

### Các trường hợp dễ sai

- FP/vector arguments ở XMM registers;
- aggregate/sret;
- stack arguments;
- variadic functions như `printf`, `scanf`, `open`;
- return-width và extension;
- custom prototype, alias, symbol interposition;
- callbacks/function pointers;
- errno/TLS, `setjmp/longjmp`, noreturn;
- pointer guest/native chưa translate đầy đủ;
- external function đọc/ghi memory mà memory-token/state effects bị bỏ.

### Loại lỗi

- **U/P0:** Rewrite direct native call chỉ sound khi callsite signature, argument sources, return sinks và memory effects đều được chứng minh.
- **M:** Unknown externs không có prototype evidence.
- **I:** Chạy bridge lần nữa sau cleanup/O3 làm khó biết bridge nào gây divergence.

### Có thể gây lệch thế nào

- Wrong arguments hoặc truncated return.
- `printf` đọc sai variadic slots, crash hoặc output rác.
- `read/write/memcpy` dùng pointer sai representation.
- Callback quay lại lifted/native boundary với State sai.

### Cách sửa

- ABI classifier độc lập theo SysV psABI, không hard-code chỉ six GPRs.
- Signature evidence từ debug info, relocation/import declaration, callsite dataflow và callee summary; tên chỉ là hint.
- Format-string recovery chỉ là bổ sung evidence, không phải proof duy nhất.
- Unknown/ambiguous call giữ compatibility bridge và làm native strict fail.
- Mỗi bridge phải có explicit memory-effect summary.

---

## 070 — `brighten_070_global_data_recovery`

### Thiếu proof

Global recovery cần giữ nguyên byte layout và address/alias identity. Các phần cần cover nhưng chưa đủ bằng chứng trong pipeline:

- relocations và addends;
- interior pointers;
- overlapping objects/segments;
- mutable data và self-modifying/aliasing writes;
- BSS/zero-fill khác file bytes;
- GOT/PLT, copy relocation, symbol interposition;
- TLS/per-thread storage;
- function pointers và jump tables;
- integer-to-pointer round trips;
- section alignment và permissions.

### Nguy cơ semantic

- Mapping một numeric address sang “global gần nhất” mà không có relocation/range proof.
- Reconstruct hai LLVM globals từ một overlapping byte region, làm mất alias.
- Xóa segment/global chỉ vì không có direct LLVM uses, trong khi địa chỉ có thể đi qua integer, relocation hoặc extern.

### Loại lỗi

- **U:** Global rewrite/deletion thiếu complete address-use proof.
- **M:** TLS, dynamic relocation, opaque integer pointer flow.
- **I:** Type recovery sau đó có thể làm sai initializer trở nên khó nhận biết.

### Có thể gây lệch thế nào

- Sai string/table/function pointer.
- Write không được alias sang reader.
- Candidate crash khi extern dereference address đã remap sai.
- Wrong indirect branch target.

### Cách sửa

- Global object model theo byte interval + relocation graph + mutability.
- Không split overlapping intervals nếu chưa chứng minh non-alias.
- Dead-data elimination tách khỏi recovery và chỉ chạy sau whole-program address-escape proof.
- Byte/relocation checksum trước-sau phải giống tuyệt đối.

---

## 080 — `brighten_080_type_reconstruction`

### Rewrite sai chắc chắn

Trong `IRTypeRewriter.cpp`:

- `ExtractByteFromConstant` (khoảng dòng 61-119) trả `0` khi offset ngoài range, constant form không được hỗ trợ hoặc không tìm thấy field.
- `RebuildConstant` (khoảng dòng 152-252) dùng các byte zero đó để dựng integer/float/array mới.
- Nhánh type không hỗ trợ có thể trả `Constant::getNullValue(NewTy)`.

Unknown không đồng nghĩa zero. Unsupported initializer không đồng nghĩa null initializer.

### Loại lỗi

- **S/P0-P1:** Có counterexample byte-level trực tiếp.

### Có thể gây lệch thế nào

- String/global constant đổi byte.
- Jump table/function pointer bị zero.
- Float bit-pattern thay đổi.
- Pointer relocation mất, dẫn tới crash hoặc wrong target.

### Phần inference còn thiếu

- Signedness, union, semantic field boundary và source-level type không thể suy chắc chỉ từ load/store shape.
- Type reconstruction phải là layout-preserving; không được thay bytes để khớp type mong muốn.

### Cách sửa bắt buộc

- `extractKnownByte` phải trả `Expected` hoặc `(known, value)`.
- Một byte/relocation unknown làm rollback toàn reconstruction plan.
- Không có fallback null/zero.
- Verify byte-for-byte, relocation-for-relocation và alignment trước khi commit.

---

## 090 — `brighten_090_native_cleanup`

### Rewrite sai/nguy hiểm đã xác định

#### 1. Blanket `freeze` và PHI fabrication

`NativeCleanup.cpp:167-264`, được gọi quanh dòng 4786-4797:

- thay incoming `undef`/`poison` của PHI bằng common value;
- chèn `freeze` cho gần như mọi operand còn `undef`/`poison`.

Trong binary recovery, undef thường là register/flag/call-clobber/edge semantics chưa recover. `freeze` làm lỗi reconstruction thành một giá trị tùy ý nhưng ổn định, rồi O3 có thể fold CFG quanh nó.

#### 2. Fake stack global 16 MiB

`NativeCleanup.cpp:3942-4054` tạo đại ý:

```llvm
@frame_storage_backing.main =
  internal global [16777216 x i8] zeroinitializer, align 16
```

Đây không phải native stack:

- uninitialized bytes thành zero;
- mọi invocation/thread dùng chung object;
- recursion/reentrancy sai;
- lifetime/alias/fault behavior sai;
- out-of-frame access có thể không fault như binary.

#### 3. Làm mất `envp`

Khu vực 4034-4049 tạo wrapper `main(i32, ptr)` và truyền null cho formal parameters sau tham số thứ hai. Với `main(i32, char **, char **)`, `envp` có thể observable.

#### 4. Cleanup kiêm semantic recovery và certification

Pass vừa fabricate values/stack, vừa xóa artifact, vừa quyết định module “native”. Nó còn chạy hai lần, với O3 ở giữa.

### Loại lỗi

- **S/P0:** Fake stack, null `envp`, PHI value invention.
- **U/P0:** Blanket freeze không phải equivalence proof cho missing architectural semantics.
- **I/P0:** Monolithic, order-sensitive, chạy lặp và làm mất first-divergence evidence.

### Có thể gây lệch thế nào

- Wrong branch/output do frozen flag/register.
- Recursion/thread corruption.
- Uninitialized-stack behavior đổi thành zero.
- Environment-dependent program sai vì `envp = null`.
- O3 biến sai khác cục bộ thành DCE/constant-folding trên phạm vi lớn.

### Cách sửa bắt buộc

- Native cleanup chỉ canonicalize/xóa code proven-dead; không invent values.
- Bỏ blanket freeze và common-value PHI repair khỏi native mode.
- Fake stack chỉ được phép trong explicit `compat` mode và phải mang non-native marker.
- Giữ đúng entry signature, bao gồm `envp` khi live/unknown.
- Tách certification thành pass read-only, không rewrite.

---

## Driver — `src/llvm_pass/britening_ir.py`

### Vấn đề thiết kế

Pipeline hiện gần như:

1. repair;
2. runtime materialization;
3. devirt;
4. always-inline;
5. state SSA;
6. stack;
7. ABI;
8. extern bridge;
9. global;
10. devirt lần hai;
11. type recovery;
12. generic optimization;
13. native cleanup;
14. extern bridge lần hai;
15. O3;
16. native cleanup lần hai;
17. unflatten/deobfuscation;
18. final cleanup/verify.

Các lỗi hệ thống:

- Compatibility helper được materialize rồi inline trước khi native recovery hoàn tất.
- O3 chạy trước semantic acceptance gate.
- `BRIGHTEN_NATIVE_STRICT` mặc định tắt.
- Module non-compliant vẫn có thể được trả về như output thành công.
- Verifier chỉ chứng minh well-formed LLVM IR, không chứng minh tương đương binary.
- Không lưu per-pass executable/IR oracle nên 109 mismatch hiện chưa gắn được với first divergent pass.

### Cách tổ chức đúng

Ba output class riêng:

- `compat_runnable`: chạy/fuzz được, được phép có shim/fake model;
- `native_candidate`: structural contract đạt nhưng chưa qua corpus;
- `native_certified`: structural contract đạt và không-regression semantic đạt.

Phase đề xuất:

- **Repair:** chỉ malformed/lifter-contract violations có provenance.
- **Compatibility lowering:** pipeline riêng, không được cấp native status.
- **Native recovery:** 020-080 với evidence gate và rollback.
- **Deobfuscation:** sau khi CFG/memory/ABI ổn định.
- **Cleanup:** canonicalization semantics-preserving.
- **Certification:** read-only structural checks + corpus differential gate.

---

## Gắn triệu chứng với pass nghi ngờ

| Triệu chứng | Pass nghi ngờ cao nhất | Cơ chế |
|---|---|---|
| Binary crash, candidate exit bình thường | 015, 020, 050, 090 | missing jump/error thành return; hidden values/null/freeze |
| Candidate crash, binary chạy | 040, 050, 060, 070, 080, 090 | stack/ABI/pointer/global/initializer sai |
| Output khác nhưng cùng exit | 030, 050, 060, 070, 080, 090 | flags/register/arguments/data bytes/env sai |
| Candidate timeout | 020, 030, 050, 090 | wrong CFG target, stale flags, target deletion, O3 trên fabricated value |
| Candidate exit sớm | 015, 020, 050 | helper/jump no-op, wrapper result/target bị xóa |
| Chỉ sai với recursion/thread | 040, 090 | global fake stack/shared lifetime |
| Chỉ sai với varargs/FP/struct | 050, 060 | SysV classifier thiếu |
| Chỉ sai với globals/jump tables | 070, 080 | relocation/byte reconstruction sai |

Lưu ý: corpus report hiện chỉ so final executables, nên bảng trên là causal ranking từ source, chưa phải attribution thống kê cho từng mismatch.

---

## Thứ tự sửa không-regression

1. **020:** bỏ special case `PC == 0`.
2. **050:** bỏ zero/null fabrication và use-list-only deletion.
3. **090:** bỏ blanket freeze/PHI invention; fake stack compat-only; giữ `envp`.
4. **080:** fail-closed trên unknown initializer byte/type.
5. **015:** tách compatibility mode và cấm inline fallback trong native path.
6. **060:** bridge chỉ khi có full ABI/signature/effect proof.
7. **040/030/070:** xây byte-range/effect/alias/relocation model và transactional commit.
8. **010:** giới hạn repair theo provenance.
9. **Driver:** strict mặc định, per-pass checkpoints, stage bisection và corpus gate.

## Acceptance gate tối thiểu

- Không giảm baseline **931 confirmed matches** trên đúng payload/toolchain.
- Không tăng asymmetric crash hoặc asymmetric timeout.
- Replay toàn bộ known counterexamples.
- Lưu output sau từng pass để xác định first divergent stage.
- Structural nativeness và behavioral equivalence là hai chỉ số riêng.
- `llvm::verifyModule` pass không được tính là semantic evidence.
- Bất kỳ rewrite thiếu proof phải rollback, không được zero/null/freeze để compile.
