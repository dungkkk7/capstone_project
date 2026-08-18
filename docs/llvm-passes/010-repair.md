# Pass 010 — Sửa semantic LLVM bị lifter diễn tả sai

**Plugin trong pipeline:** `BrightenRepairPass.so`  
**Tên pass:** `brighten-repair-pass`  
**Hàm bắt đầu:** `BrightenRepairPass::run(Module &M, ...)` trong
`src/llvm_pass/brighten_010_repair_pass/src/main.cpp`.

Tài liệu này cố ý không gọi pass là “dọn IR”. Nó sửa các câu khẳng định mà IR
đã nói với LLVM nhưng binary x86 gốc **không hề nói**. Nếu giữ các câu khẳng
định sai đó, LLVM optimizer được quyền bỏ đường chạy có thật trong binary.

## 0. Đọc được source pass này cần biết gì?

### LLVM module, function, basic block và instruction

Một file `.ll` là một **module**. Module chứa global như `@x` và function như
`@sub_401000`. Một function gồm nhiều **basic block**. Basic block là dãy
instruction chạy liên tiếp, kết thúc bằng một terminator như `br`, `switch`,
`ret`, hoặc `unreachable`.

Ví dụ:

```llvm
entry:
  %x = add i64 %a, 1
  %ok = icmp eq i64 %x, 0
  br i1 %ok, label %yes, label %no
```

`%x` là một `Value`: kết quả của `add`. `add`, `icmp`, `br` là instruction.
Pass 010 đi qua từng function, block, instruction để nhận một shape rất cụ
thể rồi sửa đúng instruction đó.

### `poison` là gì và vì sao nó nguy hiểm?

LLVM cho phép instruction có **precondition**. Nếu precondition sai, result
có thể là `poison`. `poison` lan sang instruction dùng nó. Dùng poison làm
điều kiện nhánh, địa chỉ memory, hoặc return tạo undefined behavior (UB).
UB không nghĩa là “runtime báo lỗi”; nó nghĩa là optimizer có thể giả sử case
đó không xảy ra và đổi/xóa code.

Ví dụ:

```llvm
%r = add nsw i64 %a, 1
```

`nsw` viết tắt của *no signed wrap*: tác giả IR hứa `%a + 1` không signed
overflow. Nếu `%a = 9223372036854775807`, lệnh x86 `add` thật trả
`-9223372036854775808`; LLVM instruction trên trả poison. Đây là khác biệt
semantic, không phải khác biệt tốc độ.

### Guest address và host pointer là hai thứ khác nhau

Tên `@callback_sub_401020` chứa guest virtual address `0x401020`. Còn:

```llvm
ptrtoint (ptr @callback_sub_401020 to i64)
```

là số biểu diễn **địa chỉ của object đó trong process đang chạy IR**. ASLR,
linker và layout host quyết định số này. Nó không phải guest PC `0x401020`.
Nhiều rule 010 tồn tại để tách hai representation đó ra.

## 1. Thứ tự code chạy thực tế

`main.cpp` gọi theo thứ tự sau:

```text
1. StripMcSemaInlineAsmDirectives
2. ResolveAliases
3. StripPoisonDrivingFlags
4. StripPoisonDrivingAttributes
5. RepairX86FPToIntIndefiniteGuards
6. RepairObfuscatedStackSubtractions
7. FixCallbackFunctionPointerStores
```

Mỗi dòng dùng `Changed |= Rule(M)`. Nghĩa là mọi rule vẫn chạy dù rule trước
đã sửa module; `Changed` chỉ dùng để nói với LLVM pass manager rằng các kết
quả analysis cũ không còn đáng tin.

### Evidence thiếu trong checkout hiện tại

Không được bỏ qua vấn đề này. `CMakeLists.txt` yêu cầu build các file:

```text
Helpers.cpp
RuleStripPoisonDrivingAttributes.cpp
RuleStripMcSemaInlineAsmDirectives.cpp
RuleRepairObfuscatedStackSubtractions.cpp
```

nhưng chúng không có trong `src/`. `tests/run_tests.sh` còn gọi
`tests/ub_attrs.ll`, cũng không có. Có `.so` cũ trong `build/`, nhưng source
hiện tại không chứng minh nó được build từ revision nào. Vì vậy các mục 2, 5,
7 bên dưới là source hiện có; ba rule thiếu source được ghi rõ là **không thể
giải thích implementation hiện hành**. Không dùng binary cũ hay mô tả lịch sử
để giả làm evidence mới.

## 2. `ResolveAliases`: alias register State được thay bằng pointer thật

**Source hiện có:** `RuleResolveAliases.cpp`.

### Input mà rule nhận

`GlobalAlias` là một tên thứ hai trỏ tới constant pointer expression. McSema
có thể tạo alias register như ý tưởng sau:

```llvm
@__mcsema_reg_state = global %State zeroinitializer
@RAX_view = alias i64, ptr getelementptr (%State, ptr null, i64 0, i32 1)
```

`ptr null` trong shape này không có nghĩa program muốn dereference null. Nó
là cách lifter dùng offset của type `%State` như một biểu thức constant.

### Từng điều kiện source kiểm tra

1. `M.getGlobalVariable("__mcsema_reg_state")` phải tìm được State global.
   Không có global này thì return `false`, không đụng alias nào.
2. Nếu State global là thread-local, rule gọi `setThreadLocal(false)`.
3. Rule copy danh sách alias vào `SmallVector` trước. Lý do: nó sẽ
   `eraseFromParent()` alias khi đang duyệt; duyệt trực tiếp container sẽ làm
   iterator invalid.
4. Alias có tên bắt đầu `data_` bị `continue` ngay lập tức.
5. Alias còn lại chỉ được special-rewrite khi aliasee là `GEPOperator`, pointer
   operand là `null` hoặc constant cast của null.
6. Rule giữ nguyên source element type, toàn bộ indices và cờ `inbounds` của
   GEP; chỉ thay base null bằng `@__mcsema_reg_state` (bitcast nếu pointer type
   khác).
7. Cuối cùng `GA->replaceAllUsesWith(Replacement)` rồi `GA->eraseFromParent()`.

### Trước và sau

```llvm
; trước: offset State bị neo ở null
@RAX_view = alias i64, ptr getelementptr (%State, ptr null, i64 0, i32 1)

; sau: mọi use của alias dùng pointer từ object State thật
; getelementptr (%State, ptr @__mcsema_reg_state, i64 0, i32 1)
```

Điều pass bảo toàn là offset/type của register field. Nó không invent offset
mới; indices của original GEP được copy nguyên.

### Vì sao `data_*` không được thay?

Ví dụ `@data_405040` chứa **guest address trong tên**. Nếu thay alias data
sớm bằng GEP vào aggregate host, alignment/padding LLVM có thể làm byte offset
host khác offset ELF. 070 có byte image, relocation và guest-range analysis để
quyết định object/data pointer; 010 chưa có evidence đó. Tự thay ở đây cũng có
thể làm 020 nhìn integerized data pointer như dynamic code target.

### Function tồn tại nhưng không chạy

File còn định nghĩa `PreserveCalleeSavedRegisters`: nó load RBX/RBP/R12–R15
trước guest call, call, rồi restore. Nhưng `main.cpp` không gọi function này.
Nó không phải behavior của `brighten-repair-pass` hiện tại. Đây là lý do tài
liệu không được liệt kê mọi function trong source như thể nó active.

## 3. `StripPoisonDrivingFlags`: bỏ promise LLVM sai trên lifted machine code

**Source hiện có:** `RuleStripPoisonDrivingFlags.cpp`.

### Scope: rule không chạy trên toàn module

Tên function phải bắt đầu `sub_` hoặc `auto_sub_`; nếu tên chứa `.native`,
`.compat`, `.wrapper` thì skip. Rationale nằm ngay source: native clone,
runtime helper và compatibility wrapper có semantics LLVM riêng; bỏ flag của
chúng khi không có bằng chứng là unsound.

### Exact rewrite

Với `BinaryOperator`:

```llvm
add nsw  -> add
sub nuw  -> sub
mul nsw nuw -> mul
lshr exact -> lshr
```

Source dùng `OverflowingBinaryOperator` để clear `hasNoSignedWrap` và
`hasNoUnsignedWrap`; dùng `PossiblyExactOperator` để clear `isExact`.

Với `GetElementPtrInst`:

```llvm
getelementptr inbounds T, ptr %p, ...
        -> getelementptr T, ptr %p, ...
```

### Ví dụ overflow đầy đủ

```llvm
define i64 @sub_1000(i64 %a) {
entry:
  %x = add nsw i64 %a, 1
  %negative = icmp slt i64 %x, 0
  br i1 %negative, label %wrapped, label %not_wrapped
}
```

Khi `%a = INT64_MAX`, binary x86 đi `wrapped`: result wrap thành `INT64_MIN`.
Với `nsw`, case đó poison trước `icmp`; optimizer được quyền không giữ
`wrapped` như behavior defined. Sau pass:

```llvm
%x = add i64 %a, 1
```

LLVM lại có arithmetic modulo 64 bit, giống instruction x86 `add`.

### `inbounds` không chỉ là “address còn trong mảng”

`inbounds` nói với LLVM phép tính pointer không overflow và traversal vẫn
thuộc object hợp lệ theo provenance LLVM. Guest mapper thường nhận số nguyên
guest rồi chọn segment/frame khác nhau; ở phase 010 chưa có object proof.

```llvm
%p = getelementptr inbounds i8, ptr %segment, i64 %guest_delta
```

giữ `inbounds` sẽ làm LLVM có thêm assumption mà binary gốc không hứa. Rule
bỏ cờ nhưng vẫn giữ GEP và `%guest_delta`: address arithmetic vẫn tồn tại,
chỉ proof claim bị gỡ.

### Điều rule cố ý không làm

File có helper đệ quy `DropInBoundsFromConstantExpr`, nhưng `StripPoisonDrivingFlags`
không gọi nó. Comment hiện hành nói global constant expression có relocation/
layout provenance, thuộc ownership của 070. Vì vậy:

```llvm
@p = global ptr getelementptr inbounds ([4 x i64], ptr @buf, i64 0, i64 8)
```

phải giữ nguyên ở 010, dù instruction GEP bên trong `@sub_*` bị bỏ inbounds.

### Test đọc từng assertion

`tests/ub_flags.ll` input có:

```llvm
%x = add nsw i64 %a, %b
%y = sub nuw i64 %x, 1
%p = getelementptr inbounds i64, i64* %base, i64 %y
```

và FileCheck:

```text
CHECK-NOT: nsw
CHECK-NOT: nuw
CHECK-NOT: getelementptr inbounds
```

Nó không chứng minh toàn module không còn `inbounds`; nó kiểm output fixture
không có các token đó sau rewrite lifted function.

`tests/ub_flags_constexpr.ll` có global `@p` và:

```text
CHECK: @p = global ptr getelementptr inbounds
```

Đây là negative boundary test: nếu ai “refactor” 010 để rewrite ConstantExpr,
test phải fail.

## 4. `RepairX86FPToIntIndefiniteGuards`: sửa NaN path CVTT

**Source hiện có:** `RuleRepairX86FPToIntIndefiniteGuards.cpp`.

### Hai semantic cần phân biệt

X86 `CVTTSD2SI`/`CVTTSS2SI` chuyển float sang signed integer bằng truncate.
NaN hoặc out-of-range không tạo LLVM poison; CPU trả *integer indefinite*.
Với destination 32 bit, bits là `0x80000000` = decimal unsigned `2147483648`.

LLVM:

```llvm
%i = fptosi double %x to i32
```

có poison nếu `%x` là NaN/out-of-range. Lifter bao bằng select để mô phỏng x86,
nhưng nếu dùng ordered compare (`ogt`) thì NaN không đi vào fallback arm.

Truth table cần nhớ:

| `%abs` | `fcmp ogt %abs, limit` | `fcmp ugt %abs, limit` |
| --- | --- | --- |
| số nhỏ hơn limit | false | false |
| số lớn hơn limit | true | true |
| NaN | false | true |

`u` là *unordered*: compare trả true nếu có NaN.

### Exact matcher

Rule chỉ sửa `SelectInst`, và mọi điều kiện dưới đây phải đúng:

1. condition là `FCmpInst` predicate đúng `FCMP_OGT`;
2. true value là `ConstantInt` bằng signed-min của **bit-width destination
   `fptosi`**;
3. false value sau khi bỏ một chuỗi `zext`/`sext` là `FPToSIInst`;
4. operand 0 compare là intrinsic `llvm.fabs` đúng một argument;
5. argument `fabs` là cùng `Value*` với input của `fptosi`;
6. operand 1 compare là `ConstantFP`.

Nếu một condition thiếu, không đổi compare. Rule không “mọi `ogt fabs` thành
`ugt`”, vì ordinary program compare NaN có thể cần ordered semantics.

### Trước và sau exact fixture

```llvm
%truncated = call double @llvm.trunc.f64(double %input)
%absolute = call double @llvm.fabs.f64(double %truncated)
%outside = fcmp ogt double %absolute, 0x41DFFFFFFFC00000
%converted = fptosi double %truncated to i32
%extended = zext i32 %converted to i64
%result = select i1 %outside, i64 2147483648, i64 %extended
```

Rule đổi một token:

```llvm
%outside = fcmp ugt double %absolute, 0x41DFFFFFFFC00000
```

NaN bây giờ chọn constant, không consume `%converted` poison. Test còn có
`@unrelated_ordered_compare` với `select 7, 9`; FileCheck yêu cầu `fcmp ogt`
vẫn còn. Đó là bằng chứng matcher không mở rộng quá scope.

## 5. `FixCallbackFunctionPointerStores`: giữ guest PC khi thunk bị DCE

**Source hiện có:** `RuleFixCallbackFunctionPointerStores.cpp`.

### Input và bug

```llvm
define internal void @callback_sub_401020() { ret void }

call void @callback_sub_401020()
store i64 ptrtoint (ptr @callback_sub_401020 to i64), ptr %slot
```

Lời gọi trực tiếp là host function use hợp lệ. Nhưng store là representation
guest PC cho Remill dispatcher. Sau optimize/DCE, private naked callback thunk
có thể mất; host `ptrtoint` cũng không phải `0x401020`. Dispatcher switch cần
literal `4198432`, không cần process pointer.

### Matcher và rewrite

`ParseCallbackPC` accept name `callback_sub_<hex>` hoặc `sub_<hex>`, parse hết
đoạn hexadecimal liên tiếp sau prefix. Rule làm hai pass:

1. Với mỗi defined `callback_sub_*`, lấy user là `ConstantExpr ptrtoint` và
   replace mọi use bằng `ConstantInt` cùng integer type, value PC parsed.
2. Với mọi `PtrToIntInst` trong body:
   - operand là `ConstantExpr inttoptr(integer)`: replace bằng integer (cast
     integer nếu width khác);
   - operand sau strip pointer casts là `GlobalValue` named callback/sub: replace
     bằng PC constant.

Nó không replace function itself hay direct call. Điều đó được test bằng:

```text
CHECK: call void @callback_sub_401020()
CHECK: store i64 4198432, ptr %slot
```

Nếu first assertion mất, rule đã biến host direct call thành integer và sai.

## 6. Rule có tên trong pipeline nhưng source không hiện diện

`StripMcSemaInlineAsmDirectives`, `StripPoisonDrivingAttributes`,
`RepairObfuscatedStackSubtractions` được `run` gọi, nhưng current source/test
không đủ để mô tả matcher/rewrite/testcase. Tài liệu cố ý dừng ở đây thay vì
nói “nó xoá asm/attribute/sửa stack” mà không giải thích được instruction nào,
condition nào và failure mode nào. Khôi phục các file đó là điều kiện để hoàn
thành phần rule-level của pass 010.
