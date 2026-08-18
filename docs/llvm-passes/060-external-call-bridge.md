# 060 — nối lời gọi thư viện từ ABI đã lift về ABI native

**Plugin thực tế:** `BrightenExternCallBridgePass.so`  
**Tên trong pipeline:** `brighten-extern-call-bridge`  
**Điểm vào để đọc code:** `brighten_060_extern_call_bridge/main.cpp` và
`BrightenExternCallBridgePass.h`.

## 1. Bài toán chính xác mà pass này giải

McSema/Remill lift một lệnh `call puts` thành lời gọi runtime có hình dạng
gần như sau:

```llvm
; RDI của CPU khách đã được ghi vào byte 2296 của State.
store i64 %arg, ptr %state_plus_2296
%mem.next = call ptr @__remill_function_call(
    ptr %state, i64 ptrtoint (ptr @puts to i64), ptr %mem)
```

Ở đây `ptr %mem` **không phải** kết quả của `puts`. Nó là *memory token*: một
giá trị SSA mà IR lifted dùng để nối thứ tự các thao tác có thể tác động bộ
nhớ. Giá trị trả về thật theo SysV x86-64 lại nằm trong State: số nguyên/con
trỏ ở RAX (offset 2216), số thực ở XMM0 (offset 16). C code native không hiểu
ba đối số `(State, địa-chỉ-PC, memory-token)`, nên 060 chỉ được phép đổi nó
thành:

```llvm
%puts.ret = call i32 @puts(ptr %native_string)
store i64 (zext i32 %puts.ret), ptr %state_plus_2216
```

khi đã chứng minh đủ ba mệnh đề độc lập:

1. PC đích thực sự là một symbol thư viện mà `LibcSignatureDB` biết chữ ký.
2. Giá trị đã ghi vào từng thanh ghi đối số là giá trị đến được callsite trên
   *mọi đường đi*; riêng đối số con trỏ còn phải là địa chỉ host hợp lệ hoặc
   được dịch bằng fallback mà người dùng bật rõ ràng.
3. Thay `%mem.next` bằng `%mem` không làm mất một use chương trình. Tức mọi
   use của nó phải chỉ là vị trí memory-token tiếp theo, `return`, `phi` hay
   `select` chỉ truyền tiếp memory-token.

Không đủ một mệnh đề, kết quả đúng của pass là **giữ nguyên call lifted**. Đó
không phải “pass chạy hỏng”: một `i64` có thể là địa chỉ guest, địa chỉ host,
hoặc chỉ là số; ép nó thành `ptr` rồi đưa cho libc có thể khiến host đọc/ghi
sai vùng nhớ.

## 2. Thứ tự rule và dữ liệu chung

`run` tạo `ExternCallContext`, chọn `NativeStrict` mặc định; chỉ cờ
`-extern-compat-fallback` mới chọn `CompatFallback`. Sau đó code gọi đúng thứ
tự dưới đây, dùng chung callsite record, provenance, signature và `SkipReason`:

```text
DiscoverExternalSymbols
→ AnalyzeExternalCallsites
→ RecoverLibcArguments
→ RecoverVarargArguments
→ LowerMaterializedVAListCalls
→ LowerLiftedExternalABICalls
→ RewriteExternalCallsites
→ AnnotateDirectScanfDestinationNoCapture
→ RewriteExternalReturns
→ CleanupExternalCallArtifacts
→ VerifyExternalCallRecovery + PrintExternalCallRecoveryReport
```

Thứ tự có ý nghĩa. `RewriteExternalCallsites` không thể tự đoán format string
hay provenance; nó chỉ tiêu thụ record đã được ba rule trước đánh dấu hợp lệ.
`nocapture` chạy **sau** rewrite vì nó cũng có thể nhìn thấy call libc native
vừa tạo. Verify chạy cuối để kiểm tra cả LLVM verifier lẫn invariant của chế
độ strict.

## 3. Rule đọc State: matcher nhỏ nhưng là hàng rào an toàn

Các file phân tích có hàm `IdentifyStateOffset(ptr)`. Nó không nhận mọi GEP
tuỳ ý. Nó nhận một trong các dạng sau:

* global đúng tên `RDI`, `rdi`, `RAX`, …;
* global có prefix whitelist như `RDI_2296_xxx`, rồi parse số giữa hai dấu `_`;
* GEP/bitcast có offset hằng, base là `@__mcsema_reg_state`;
* trong vài đường phân tích, offset hằng từ argument 0 (State argument).

Ví dụ `getelementptr i8, ptr @__mcsema_reg_state, i64 2296` nhận là RDI;
`getelementptr i8, ptr %p, i64 %n` bị từ chối vì `%n` không hằng. Lý do không
phải để “đơn giản hoá”: một offset động không chứng minh nó là thanh ghi ABI
nào, nên lấy nó làm đối số `puts` là bịa dữ liệu.

### 3.1 Lấy giá trị thanh ghi tại callsite

`FindStoreBeforeCall(CI, offset)` duyệt ngược **chỉ trong BasicBlock chứa
`CI`**, lấy `store` gần nhất vào offset đó. Nó cố tình không BFS sang block
tiền nhiệm. Xét CFG hình kim cương:

```llvm
set:    store ptr @msg, ptr %slot      ; chỉ chạy nếu cond=true
unset:  br label %join
join:   %p = load ptr, ptr %slot
        store ptr %p, ptr %RDI
        %m = call ptr @__remill_function_call(... @puts ...)
```

Nếu search “một predecessor bất kỳ”, pass có thể chọn `set` ngay cả khi runtime
đã đi từ `unset`; `%slot` khi ấy không có định nghĩa phù hợp. Vì vậy rule trả
`nullptr`, callsite bị preserve. `test_branch_local_provenance.ll` kiểm tra
chính xác output còn `@__remill_function_call` và tuyệt đối không xuất hiện
`call i32 @puts`.

Khi provenance đi qua local `alloca`, `FindStoreToStackOffset` trước hết tìm
store cùng block, cùng *byte offset hằng*. Nếu không có, nó chỉ lấy store
dominates instruction đang đọc, chọn store gần nhất theo quan hệ dominance;
còn alloca bị capture thì trả `nullptr`. Giới hạn đệ quy là 4. Điều này chặn
hai lỗi: store ở nhánh không đi qua call, và một call khác đã có thể ghi đè
alloca. Giới hạn độ sâu cũng là policy fail-closed: sâu hơn 4 là “không biết”,
không phải “chắc chắn đúng”.

### 3.2 Phân loại provenance của con trỏ

`ClassifyPointerProvenance` theo tối đa 8 cạnh use-def. Các nguồn native được
chấp nhận là global string/object có initializer, `alloca`, kết quả
`malloc/calloc/realloc`, và GEP/bitcast/ptrtoint của chúng. Phi/select chỉ hợp
lệ khi mọi arm cùng provenance native; phép `add`/`sub` integer chỉ được giữ
provenance cho đúng một operand heap native cộng/trừ một operand chưa rõ.

Ngược lại `inttoptr (i64 0x6000)` là `GuestAddressConstant`, địa chỉ động là
`GuestAddressDynamic`, và độ sâu quá 8 là `Unknown`. Trong strict mode hai
loại guest/unknown không được truyền nguyên xi cho libc. Đây là ranh giới giữa
“số địa chỉ trong address-space binary gốc” và “con trỏ process đang chạy”.

## 4. Phục hồi chữ ký thường và vararg

`RecoverLibcArguments` tra `LibcSignatureDB` để biết, ví dụ,
`puts(ptr)`, `strncmp(ptr, ptr, i64)`, `fgets(ptr, i32, ptr)`. Nó lấy sáu
đối số integer theo thứ tự SysV `RDI, RSI, RDX, RCX, R8, R9` với offsets
`2296, 2280, 2264, 2248, 2344, 2360`; floating-point dùng XMM0..XMM7 ở
`16, 80, …, 464`. Sau khi giá trị đã có provenance, coercion kiểu mới được
phép tạo `inttoptr`, `ptrtoint`, `zext`, `trunc` tương ứng chữ ký. Coercion là
thay đổi *biểu diễn LLVM*, không phải bằng chứng provenance; bằng chứng đã
phải có trước đó.

Với `printf/scanf`, declaration `i32 (ptr, ...)` không cho biết có bao nhiêu
ellipsis. `RecoverVarargArguments` phải giải format string từ constant/global
(kể cả GEP interior và chuỗi ptrtoint), parse từng conversion và lấy đúng số
thanh ghi/save-slot. Nó không suy luận “slot stack kế tiếp” khi thiếu bằng
chứng: code `TryRecoverStackArg` trả null cho trường hợp đó. Nếu format, số
argument, kiểu hoặc provenance có conflict, `IsValid=false`, và rewrite bị
chặn.

`test_scanf_vararg.ll` là đường chấp nhận tối giản: format `"%d %s"`, `%x`
và `%buf` là `alloca`; RDI/RSI/RDX lần lượt chứa format/destination/destination.
FileCheck đòi `call @scanf(... %x, ... %buf)` và đòi call Remill biến mất.
Nó chứng minh matcher có cả *đủ số đối số* lẫn provenance native, không chỉ
thấy tên `scanf`.

## 5. `LowerMaterializedVAListCalls`: đọc một va_list SysV đã materialize

Cleanup trước đó có thể biến vararg thành vùng save-area explicit. Rule này
chỉ nhận `vprintf`, `vscanf` (2 đối số) hoặc `vsscanf` (3 đối số), và chỉ khi
vẽ được cấu trúc `va_list` SysV:

```text
offset 0: gp_offset (i32)        offset 8: overflow_arg_area (ptr)
offset 16: reg_save_area (ptr)
```

Nó lần từ `va` về root `alloca`, tìm store không volatile/non-atomic ở offset
chính xác, rồi chỉ đọc các slot mà format thực sự tiêu thụ. Vì vậy slot thứ ba
`0xdeadbeef` trong `vsscanf_unconsumed_slot` không thể thành argument thứ ba.
GEP định offset có thể được hoist sang entry còn store/call ở block sau; test
`vsscanf_entry_geps_later_call` xác nhận rule dùng cấu trúc/provenance, không
đòi GEP đứng sát call.

Đối với destination là literal guest address, rule chỉ rebase nó khi một
object `!brighten.guest.range` **duy nhất** chứa đầy vùng ghi cần thiết. Ví dụ
`4096` và `4100` trong range `[4096,4104)` được biến thành pointer vào
`@guest.dest`; `4096` xuất hiện trong hai range chồng nhau ở
`test_materialized_vsscanf_overlap.ll` thì không có owner duy nhất nên giữ
nguyên `@vsscanf`. `vsscanf_dynamic_destination`, out-of-range, store volatile
và atomic cũng đều có CHECK giữ call cũ. Các refusal này ngăn libc dereference
một số nguyên guest hay chọn tuỳ tiện một backing khi hai backing cùng khớp.

Với overflow area thuộc recovered native frame, rule có thể tạo GEP từ anchor;
với giá trị State đã là `ptrtoint(frame_top) + delta`, nó tạo `inttoptr` của
địa chỉ tuyệt đối, không cộng `frame_top` lần nữa. `test_materialized_valist.ll`
kiểm tra cả hai spelling, guest rebase, và affine heap dispatch.

## 6. Rule rewrite: transaction hoặc không làm gì

`RewriteExternalCallsites` duyệt chỉ các record `Resolved`, có `Signature`,
không `SkipReason`, không action `preserve`. Trước khi mutate, nó kiểm tra:

1. từng `Arg.IsValid` phải true (`arg-type-conflict` nếu không);
2. `OldCallResultIsMemoryOnly` đi qua use graph tối đa 16 tầng: call chỉ hợp
   lệ ở arg memory của Remill hoặc arg0 của `.native`, `return`, `phi`,
   `select`; bất kỳ data use nào hay vượt budget cho kết quả `memory-result-use-unsafe`;
3. call cũ có use sống thì phải có đủ arg2 memory, nếu không
   `live-result-without-memory-operand`;
4. với `noreturn`, mọi instruction sau call (trừ terminator) phải `use_empty`;
   nếu không `noreturn-tail-has-live-users`.

Điều kiện (2) lý giải `test_deep_nonmemory_result.ll`: 18 `select` che một
`ptrtoint` rồi return. Đệ quy chỉ cho 16 tầng, nên pass không thể chứng minh
đó là memory-token; nó giữ call lifted thay vì thay use bằng `%mem` và làm
mất giá trị chương trình. Ngược lại `test_native_memory_token_phi.ll` có PHI
vòng lặp rồi truyền arg0 vào `consume.native(memory)`; đó là vị trí memory
được nhận diện, nên `pow` được rewrite và return double còn được store XMM0.

Sau preflight, rule lấy/tạo declaration đúng `FunctionType`. Nếu module đã có
declaration tên đó nhưng kiểu khác, nó chỉ thay declaration không body; có
body khác kiểu thì fail (`external-declaration-conflict`) vì không thể đổi ABI
của định nghĩa user. Nó tạo native `CallInst`, ghi non-void return về State:
integer/pointer → RAX (pointer qua `ptrtoint`, integer co về 64 bit), floating
point → XMM0. `ReplaceImmediateReturnLoads` quét trong cùng block sau call,
thay load RAX/XMM0 bằng SSA result, dừng khi gặp store cùng slot hoặc call khác.

Call lifted sau đó bị erase và các use memory-token hợp lệ được thay bằng arg2
memory cũ. Với `exit`, `NoReturn` là thuộc tính signature: rule xoá cạnh CFG
tới successor (đồng thời xoá incoming PHI), xoá tail, tạo `unreachable`.
`test_exit_noreturn.ll` đòi đúng `call void @exit(i32 1)` tiếp ngay
`unreachable`; phần test thứ hai có một tail value còn live nên CHECK đòi
`@__remill_function_call` còn lại. Đây là lý do không được “cứ rewrite
noreturn rồi xoá block”: cần chứng minh không xoá giá trị còn có user.

`RewriteExternalReturns` làm lượt thứ hai cho load RAX/XMM0 chưa bắt được
ngay lập tức: tìm call native theo symbol trong caller rồi gọi lại matcher
load. Nó vẫn chỉ thay load gần trong block theo hàng rào store/call, nên không
tự nhận một load ở CFG khác là return value.

## 7. `scanf` destination `captures(none)` không phải thuộc tính trang trí

`AnnotateDirectScanfDestinationNoCapture` chỉ xét call trực tiếp mà signature
database nhận là `scanf`, `sscanf` hoặc `fscanf`. Nó phải resolve format hằng,
parse trọn vẹn, có đúng số destination pointer, và không gặp positional `$`,
suppress `*`, `%n`, hay conversion malformed. Khi toàn bộ điều kiện đúng, nó
gắn riêng `captures(none)` lên mỗi destination. Nghĩa của thuộc tính: callee
không giữ pointer sau khi call return; nó **không** nói destination readonly,
và pass không thêm memory-effect attribute.

`test_scanf_destination_nocapture.ll` kiểm tra ba họ scanf và hai destination.
`test_scanf_destination_nocapture_refusals.ll` có format động, `%*d`, `%2$d`,
`%n`, `%` dang dở và call indirect; tất cả CHECK call còn nguyên không có
`captures(none)`. Nếu annotate một near miss, optimizer có thể dựa vào lời hứa
sai để biến đổi lifetime/alias của pointer user.

## 8. Cleanup và verification: biết giới hạn của chính rule

`CleanupExternalCallArtifacts` *tìm* store setup RDI..R9 không còn load cùng
block, nhưng code cố tình **không xoá** chúng (`(void)DeadStores`). Không có
phân tích liveness qua CFG/call thì xoá là unsound. Thay đổi cleanup duy nhất
là xoá declaration `.old` không còn use sau khi đổi function type.

`VerifyExternalCallRecovery` báo lỗi nếu strict mode còn callsite external
chưa rewrite, nếu native strict lại dùng fallback translator, nếu vararg đã
rewrite nhưng thiếu số conversion tiêu thụ, hoặc LLVM `verifyModule` lỗi.
Nó không tự rollback; vì thế đây là contract CI/report, còn các rule mutation
đã preflight fail-closed từ trước.

Runner chạy plugin hai lần trên fixture. Lượt hai là test **idempotence**:
output của lượt một không được bị nhận lầm là lifted call mới hay bị đổi type
lần nữa. Các check `CHECK-NOT` trong fixtures vì vậy vừa kiểm tra rewrite vừa
kiểm tra fixed point.

## 9. Cách đọc và tái tạo một test mới

Muốn thêm rule, test phải có cả đường nhận và ít nhất một near-miss từ chối.
Với một external call, hãy viết: (a) state slot offset hằng, (b) store thực sự
dominates/cùng block call, (c) symbol trong `LibcSignatureDB`, (d) pointer
native hoặc unique guest mapping, (e) use của return chỉ là memory-token.
Sau đó FileCheck phải kiểm tra instruction native cụ thể **và** `CHECK-NOT`
cho instruction cũ. Bỏ bất kỳ tiền đề nào thì test phải đòi preserve. Đó mới
khóa được lý do kỹ thuật của rule, không chỉ khóa tên pass.
