# Nền tảng: lifted IR khác native LLVM IR ở đâu

Muốn hiểu các pass Brighten, phải tách ba khái niệm mà code C bình thường che
đi: giá trị CPU, giá trị LLVM và địa chỉ process hiện tại. Nhiều rule tồn tại
chỉ vì ba khái niệm đó đã bị lifter trộn làm một.

## 1. Integer x86 và integer LLVM

Lệnh `add rax, rbx` của x86 luôn tính modulo `2^64`. Với hai input bất kỳ nó
cho một output 64-bit.

LLVM instruction không gắn flag cũng có tính modulo:

```llvm
%r = add i64 %a, %b
```

Nhưng các flag đổi semantics:

```llvm
%r1 = add nsw i64 %a, %b  ; signed overflow => poison
%r2 = add nuw i64 %a, %b  ; unsigned overflow => poison
%r3 = lshr exact i64 %a, 3 ; bit bị shift bỏ khác 0 => poison
```

`poison` không phải số nguyên bất kỳ. Nếu nó đi vào `br`, `switch`, địa chỉ
load/store, return hay instruction cần giá trị defined, execution có undefined
behavior. Optimizer vì vậy được phép dùng `nsw` để bỏ các path overflow. Một
lifter đặt `nsw` lên phép cộng máy x86 đã thay đổi ngôn ngữ chương trình trước
khi Brighten kịp phân tích nó.

## 2. `undef` và `poison` không phải “giá trị chưa khởi tạo C”

`undef` cho phép mỗi use chọn một giá trị không xác định khác nhau. `poison`
lan truyền và tạo UB ở use nhạy cảm. Cả hai không thể được thay bằng local
alloca chưa ghi hay số 0 chỉ để làm output đẹp.

Ví dụ:

```llvm
%x = phi i32 [ poison, %entry ], [ 7, %loop ]
%y = add i32 %x, 1
```

Rewire CFG hoặc thay `%x` bằng một local load có thể thay đổi tập hành vi. Đó
là lý do 095 không deflatten dispatcher có poison PHI carrier và 090 chỉ định
nghĩa construction scaffold khi nó chứng minh mọi byte observable đều bị ghi
đè trước khi đọc.

## 3. Pointer host không phải guest virtual address

Trong ELF gốc, `0x401020` là địa chỉ ảo của guest. Trong process chạy output,
`ptr @callback_sub_401020` là host pointer do linker/ASLR quyết định. Hai số
này thường không bằng nhau.

```llvm
; Sai nếu xem như guest PC:
%pc = ptrtoint ptr @callback_sub_401020 to i64

; Guest-PC canonical form:
%pc = add i64 0, 4198432 ; 0x401020
```

`ptrtoint`/`inttoptr` cũng mang provenance/lifetime ở LLVM. Không được biến
bất kỳ integer nào thành host pointer: `inttoptr i64 %guest_address to ptr`
không chứng minh `%guest_address` trỏ vào object native nào. 070/080/090 chỉ
hạ nó khi có range/object/native-stack proof.

## 4. GEP và `inbounds`

```llvm
%p = getelementptr i8, ptr %base, i64 %off
```

là phép tính địa chỉ theo layout type. Dạng `getelementptr inbounds` bổ sung
cam kết về object/provenance và overflow; không phải annotation hiệu năng.
Guest address mapper thường duyệt nhiều segment hoặc fake stack byte backing,
nên chưa có object proof cho `inbounds`. Nếu để cờ này, LLVM có thể tối ưu dựa
trên một object native mà chương trình gốc không có.

## 5. State, memory token và fake stack

Lifter thường biến register CPU thành offset trong `State`:

```llvm
%rax_ptr = getelementptr i8, ptr %state, i64 2216
store i64 %value, ptr %rax_ptr
```

và dùng một `ptr %memory` làm token để thứ tự/identity của guest-memory đi qua
helper:

```llvm
%memory2 = call ptr @__remill_write_memory_64(ptr %memory, i64 %addr, i64 %v)
```

Không thể đơn giản xoá `%memory` hay promote State khi external call/callback
còn có thể quan sát object đó. 030, 050 và 090 lần lượt chuyển dần State từ
memory sang SSA/ABI native, mỗi pass có proof boundary riêng.

Fake stack cũng không mặc định là local frame. Một read ở `%rsp-8` trước store
có thể là incoming argument, saved register hoặc persistent/global backing;
đổi nó thành fresh `alloca` sẽ thay giá trị ban đầu.

## 6. SSA, PHI và CFG rewrite

PHI chọn value theo edge vừa đi vào block:

```llvm
header:
  %state = phi i32 [ 1, %entry ], [ %next, %latch ]
```

Nếu deflatten pass thay edge `%entry -> dispatcher -> target` bằng
`%entry -> target`, mọi PHI ở `target` và mọi value từng được tính trong
dispatcher phải có incoming value mới đúng cho edge đó. Không thể chỉ đổi
terminator. 020/095 dùng bridge blocks, cloning payload và `SSAUpdater`; nếu
một value không dominate use mới thì transaction rollback.

## 7. Ba mức bằng chứng trong repository

1. **LLVM verifier**: type, CFG, PHI, dominance cơ bản đúng. Không chứng minh
   output là native hoặc tương đương binary.
2. **Structural proof**: matcher kiểm exact use graph, range, source/dest,
   ownership, alignment, callgraph, dominance.
3. **Behavioral proof**: differential execution của fixture/corpus trước và
   sau rewrite; 095 dùng thêm Z3 bit-vector proof cho expression hữu hạn.

Khi đọc các docs pass, “refuse” nghĩa là không đạt mức 2/3; đó thường là kết
quả đúng, không phải feature thiếu.
