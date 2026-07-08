# Tài liệu Phương pháp luận Brightening (Brightening Methodology)

## 1. Tổng quan về Brightening Methodology

### Đặt vấn đề
Trong kỹ thuật dịch ngược và phân tích mã độc sử dụng các công cụ nâng mã (binary lifters) như McSema và Remill, mã máy (x86_64) được chuyển đổi sang LLVM IR thông qua một mô hình giả lập trạng thái CPU (CPU-state emulation). Mô hình này lưu trữ toàn bộ trạng thái đăng ký (registers) và cờ hiệu (flags) của CPU vào một cấu trúc dữ liệu trung tâm gọi là struct `State`, đồng thời mô phỏng bộ nhớ vật lý thông qua một không gian nhớ phẳng gọi là bộ nhớ khách (`guest memory`). 

Kết quả thu được là một tệp LLVM IR thô cực kỳ cồng kềnh, chứa hàng ngàn chỉ thị tải/lưu liên tiếp vào struct `State`. Cấu trúc này làm mất đi hoàn toàn ngữ nghĩa lập trình nguyên bản: không còn các biến cục bộ trên stack, mất dấu vết biến toàn cục, luồng điều khiển bị phân mảnh qua các dispatcher động, các lời gọi hàm hệ thống bị wrap qua thunk, và kiểu dữ liệu bị đưa về dạng mảng byte thô. IR này hoàn toàn không thể tối ưu hóa bằng các pass chuẩn của LLVM và không thể dịch ngược thành mã nguồn sạch.

### Giải pháp: Brightening Methodology
**Brightening Methodology** là giải pháp phân tích tĩnh và biến đổi mã LLVM IR nhằm loại bỏ hoàn toàn các cấu trúc giả lập CPU giả (emulation artifacts), tái cấu trúc lại IR để tiệm cận nhất với mã LLVM IR được sinh ra từ trình biên dịch gốc (C/C++). Phương pháp này giúp IR trở nên dễ đọc hơn đối với con người, tạo điều kiện cho trình tối ưu hóa của LLVM hoạt động hiệu quả, và cho phép biên dịch lại thành các chương trình native sạch phục vụ kiểm thử vi sai (differential fuzzing).

---

## 2. Các giai đoạn trong Brightening Pipeline

Quy trình khôi phục native IR được chia làm 9 giai đoạn tuần tự (Phases):

```
+---------+     +-------------+     +-------------+     +-------------+     +-------------+
| Phase 1 | --> |  Phase 1.5  | --> |   Phase 2   | --> |   Phase 3   | --> |   Phase 4   |
| Repair  |     | Remill Comp |     |   Devirt    |     |  State SSA  |     | Stack Frame |
+---------+     +-------------+     +-------------+     +-------------+     +-------------+
                                                                                   |
                                                                                   v
+---------+     +-------------+     +-------------+     +-------------+     +-------------+
| Phase 9 | <-- |   Phase 8   | <-- |   Phase 7   | <-- |   Phase 6   | <-- |   Phase 5   |
| Cleanup |     |  Type Recon |     | Global Rec  |     | Extern Call |     |  ABI Recov  |
+---------+     +-------------+     +-------------+     +-------------+     +-------------+
```

### Phase 1: Structural Repair / IR Hygiene
Làm sạch IR thô, loại bỏ các cờ hoặc thuộc tính do lifter sinh ra có thể dẫn đến hành vi không xác định (Undefined Behavior - UB) giả hoặc làm crash trình tối ưu hóa.
* **Biến đổi:** Xóa bỏ các flag toán học nguy hiểm (`nsw`, `nuw`, `exact`, `inbounds`), loại bỏ các thuộc tính tham số sai lệch (`noalias`, `nonnull`, `align`), dọn dẹp các chỉ thị assembly rác nhúng trong inline asm, giải quyết alias trỏ vào struct `State`.

### Phase 1.5: Remill Compatibility Layer
Hiện thực hóa các Remill intrinsics cơ bản để mô-đun LLVM có thể liên kết (link) và thực thi kiểm thử ngữ nghĩa ở chế độ tương thích (compatibility mode) mà không bị thiếu ký hiệu (undefined symbols).
* **Biến đổi:** Định nghĩa các hàm helper mô phỏng đọc/ghi bộ nhớ (`__remill_read_memory`, `__remill_write_memory`), xử lý các giá trị chưa xác định (`__remill_undefined`) và các cờ hiệu toán học.

### Phase 2: Devirtualization (Khử ảo hóa luồng điều khiển)
Chuyển đổi các lệnh nhảy gián tiếp hoặc lệnh gọi hàm gián tiếp thông qua PC thành các lệnh gọi hàm trực tiếp.
* **Biến đổi:** Quét các lời gọi `__remill_function_call` và `__remill_jump` chứa hằng số PC tĩnh, ánh xạ chúng trực tiếp tới các chương trình con được nâng mã tương ứng (`@sub_<hex_pc>`). Xóa bỏ các callback thunk thừa.

### Phase 3: State SSA Promotion
Đưa các trường thanh ghi trong struct `State` (đang được truy cập qua địa chỉ bộ nhớ) lên thành các thanh ghi SSA chuẩn của LLVM.
* **Biến đổi:** Phân tích luồng dữ liệu cục bộ và toàn cục trên struct `State`, loại bỏ các lệnh load/store dư thừa bằng cách lan truyền giá trị thông qua các biến trung gian phi-node và SSA registers.

### Phase 4: Stack Frame Recovery
Tái dựng lại stack frame cục bộ của từng hàm và chuyển đổi các truy cập offset dựa trên RSP/RBP thành các biến cục bộ native (`alloca`).
* **Biến đổi:** Nhận diện vùng không gian stack khách, xác định giới hạn kích thước frame, loại bỏ các lệnh đọc/ghi stack giả lập bằng các chỉ thị load/store trực tiếp vào biến `alloca` đã khôi phục.

### Phase 5: ABI & Function Signature Recovery
Khôi phục lại chữ ký hàm gốc (danh sách tham số đầu vào và kiểu trả về) thay vì chữ ký Remill chuẩn `(State*, PC, Memory*)`.
* **Biến đổi:** Phân tích các thanh ghi đầu vào còn sống (Live-in) và đầu ra còn sống (Live-out) theo chuẩn SysV ABI. Nhân bản thân hàm gốc sang một hàm native mới có chữ ký chuẩn, thực hiện ép kiểu và ánh xạ tham số từ các thanh ghi đầu vào vào các biến cục bộ.

### Phase 6: External Call Bridge
Chuyển đổi các lời gọi hàm hệ thống hoặc thư viện (như `printf`, `scanf`, `malloc`) từ mô hình giả lập thanh ghi sang lời gọi hàm native trực tiếp.
* **Biến đổi:** Phát hiện các điểm gọi hàm libc giả lập, trích xuất tham số từ các thanh ghi tương ứng theo ABI, tạo lời gọi trực tiếp tới hàm libc trên host (ví dụ `call i32 @printf(...)`), và lưu kết quả trả về vào thanh ghi RAX.

### Phase 7: Global/Data Recovery
Khôi phục các biến toàn cục, mảng, chuỗi ký tự cố định (`rodata`) và bảng nhảy (`jump table`) từ không gian bộ nhớ khách phẳng.
* **Biến đổi:** Phân tích phân đoạn dữ liệu, phát hiện các vùng nhớ đại diện cho chuỗi ký tự hoặc cấu trúc dữ liệu toàn cục, tạo các biến toàn cục LLVM tương ứng (`@.str`, `@g_var`), và sửa lại các tham chiếu địa chỉ trong IR để trỏ trực tiếp vào các biến này thông qua GEP.

### Phase 8: Type Reconstruction
Suy luận kiểu dữ liệu cấp cao (structs, arrays, pointers) từ các mô hình truy cập bộ nhớ thô dựa trên offset.
* **Biến đổi:** Sử dụng hệ thống ràng buộc kiểu (type constraints solver) để nhóm các vùng nhớ liên tiếp thành các trường của cấu trúc dữ liệu (struct) hoặc các phần tử của mảng, chuyển đổi các GEP byte-offset thô thành GEP có kiểu cụ thể.

### Phase 9: Final Native Cleanup
Dọn dẹp triệt để các tàn dư của quá trình giả lập và thực hiện pipeline tối ưu hóa chuẩn để thu được IR native sạch nhất.
* **Biến đổi:** Loại bỏ hoàn toàn struct `State` và `@__mcsema_reg_state` nếu không còn sử dụng, chạy các pass tối ưu hóa như `sroa`, `mem2reg`, `gvn`, `simplifycfg`, `globaldce` để chuẩn hóa IR.

---

## 3. Các vấn đề lớn được phát hiện & Giải pháp xử lý

Trong quá trình hoàn thiện pipeline làm đẹp mã IR cho các tệp nhị phân bị obfuscate, ba vấn đề nghiêm trọng liên quan đến sự tương thích của compiler và tính đúng đắn về ngữ nghĩa đã được phát hiện và xử lý triệt để:

### Vấn đề 1: Lỗi crash compiler (opt-21) do Assertion Casting trong ConstantExpr
* **Mô tả bài toán:** Trong LLVM 21, hệ thống kiểm tra kiểu động (`Casting.h`) áp dụng các ràng buộc cực kỳ nghiêm ngặt. Trong tệp `RuleBuildGuestAddressMap.cpp`, khi pass thực hiện duyệt đồ thị hằng số thông qua hàm `CE->getOperand(I)` trên đối tượng `ConstantExpr`, LLVM sẽ kích hoạt kiểm tra tĩnh để đảm bảo rằng mọi toán hạng trả về đều là một hằng số (`Constant`). Tuy nhiên, nếu một trong số các toán hạng bị thay đổi động hoặc biểu diễn dưới dạng toán tử đặc biệt, trình biên dịch sẽ báo lỗi assertion `isa<X>(Val) && "cast_if_present<Ty>() argument of incompatible type!"` và crash ngay lập tức.
* **Giải pháp:** Bằng cách ép kiểu tĩnh đối tượng `ConstantExpr*` sang lớp cha `User*` (`auto *U = cast<User>(CE)` hoặc `const User *U = CE`), ta có thể gọi phương thức `User::getOperand(I)` trả về con trỏ `Value*` thô. Việc này bỏ qua bước kiểm tra kiểu tĩnh của `ConstantExpr` nhưng vẫn cho phép ta duyệt qua toàn bộ toán hạng một cách an toàn, sau đó sử dụng `dyn_cast` để kiểm tra kiểu động một cách thủ công mà không gây crash trình biên dịch.

### Vấn đề 2: Lỗi use-after-free gây segfault trong LazyCallGraph khi chạy function-attrs
* **Mô tả bài toán:** Trong giai đoạn ABI Recovery, nếu một hàm được suy luận là trả về RAX (`ReturnKind::IntRAX`) nhưng khi tiến hành viết lại lệnh return (`RewriteReturns`), pass không thể tìm thấy lệnh ghi giá trị vào thanh ghi RAX trước chỉ thị return (thường xảy ra ở các khối lệnh unreachable hoặc do luồng điều khiển phức tạp), quá trình viết lại thất bại. Để xử lý, pass cũ đã tiến hành xóa bỏ hàm native mới khởi tạo bằng lệnh `eraseFromParent()`. Tuy nhiên, các hàm native khác được nhân bản song song trước đó đã được viết lại để gọi trực tiếp tới hàm native này. Vì trình biên dịch trên môi trường chạy là bản Release (tắt assert), lệnh `eraseFromParent()` âm thầm thực thi thành công mặc dù hàm vẫn còn các use-site hoạt động, để lại các con trỏ lơ lửng (dangling pointers) trỏ vào vùng nhớ đã bị giải phóng. Khi pass tiếp theo như `function-attrs` xây dựng lại call graph qua `LazyCallGraph::visitReferences`, nó dereference con trỏ lơ lửng này dẫn đến Segfault (lỗi 139).
* **Giải pháp:** Loại bỏ hoàn toàn hành vi xóa hàm khi khôi phục return thất bại. Thay vào đó, nếu không tìm thấy giá trị RAX hợp lệ, ta giữ lại hàm native để bảo vệ tính toàn vẹn của đồ thị cuộc gọi, sử dụng giá trị độc hại chuẩn của LLVM là `PoisonValue::get(RetTy)` để làm giá trị trả về cho lệnh return, đồng thời in ra cảnh báo. Điều này giúp IR luôn hợp lệ về mặt cấu trúc và vượt qua các bộ kiểm tra của LLVM.

### Vấn đề 3: Lỗi chuyển đổi sai các hằng số toán học/offset thành địa chỉ bộ nhớ khách
* **Mô tả bài toán:** Khi tệp nhị phân có phân đoạn dữ liệu khách bắt đầu từ địa chỉ `0x0` (hoặc kích thước phân đoạn bao phủ các dải số nhỏ), các hằng số integer như `32` (dùng làm shift amount trong lệnh `shl`) hoặc `24880` (dùng làm offset stack cục bộ kiểu `RBP - 24880`) đều được hàm `TryExtractGuestAddr` nhận dạng là địa chỉ khách hợp lệ. Tiếp theo, pass Global Recovery tiến hành viết lại các hằng số này thành con trỏ bộ nhớ host tương ứng dưới dạng `ptrtoint(ptr getelementptr ...)`. Hậu quả là chỉ thị dịch bit biến thành dịch bit bởi một địa chỉ host khổng lồ (Undefined Behavior gây loop vô hạn hoặc crash), và phép toán offset stack biến thành phép trừ một con trỏ host khổng lồ, làm lệch hoàn toàn tính toán bộ nhớ stack và gây Segmentation Fault khi thực thi.
* **Giải pháp:** Triển khai một bộ lọc ngữ cảnh chặt chẽ thông qua hàm `IsLikelyGuestAddress` và `IsStackPointer`:
  1. Loại bỏ tất cả các hằng số nằm ở vị trí toán hạng chỉ số (index) của chỉ thị `GetElementPtrInst` (`OpIdx > 0`).
  2. Loại bỏ các hằng số nằm ở vị trí toán hạng lượng dịch (shift amount) của các lệnh dịch bit `shl`, `lshr`, `ashr` (`OpIdx == 1`).
  3. Loại bỏ các hằng số là trường hợp so sánh case của chỉ thị `SwitchInst` (`OpIdx > 0`).
  4. Loại bỏ các hằng số toán học (`add`/`sub`) nếu toán hạng còn lại được xác định là con trỏ stack (`RSP` hoặc `RBP`), dựa trên việc kiểm tra offset thanh ghi đặc trưng (`2312` cho RSP và `2328` cho RBP) hoặc tên biến được gán.
---

## 4. Tiêu chuẩn mục tiêu (Target Standards)

Một tệp LLVM IR được coi là làm đẹp thành công và đạt chất lượng native cao khi đáp ứng các tiêu chuẩn sau:

1. **Tính hợp lệ của cấu trúc IR (IR Validity):** Vượt qua hoàn toàn pass kiểm tra `verifyModule` của LLVM mà không phát sinh bất kỳ cảnh báo hoặc lỗi cú pháp/kiểu nào.
2. **Khử hoàn toàn CPU-state:** Vùng nhớ của struct `State` phải được giải phóng hoàn toàn khỏi các hàm native chính. Không còn các lệnh load/store gián tiếp vào các offset thanh ghi.
3. **Chữ ký hàm sạch:** Các hàm nội bộ sử dụng kiểu dữ liệu C tiêu chuẩn làm tham số và kiểu trả về thay vì truyền con trỏ `State*`.
4. **Tương đương ngữ nghĩa tuyệt đối (Semantic Equivalence):** Khi biên dịch lại thành tệp nhị phân host và chạy kiểm thử vi sai bằng AFL++ fuzzer so với tệp nhị phân obfuscated ban đầu, tỉ lệ tương đương ngữ nghĩa phải đạt **100.00%** trên toàn bộ các ca kiểm thử đầu vào ngẫu nhiên và biên (không xảy ra crash hoặc lệch kết quả đầu ra).
---
## 5. Hạn chế tồn đọng & Hướng phát triển tương lai

Dù phương pháp luận hiện tại đã giúp khôi phục thành công các hàm obfuscated cơ bản và sửa chữa các lỗi crash compiler nghiêm trọng, vẫn còn một số thách thức kỹ thuật lớn cần giải quyết:

* **Khôi phục Jump Table gián tiếp phức tạp:** Đối với mã nguồn bị obfuscate luồng điều khiển nặng bằng các kỹ thuật như Control Flow Flattening (Làm phẳng luồng điều khiển) hoặc Opaque Predicates (Tiền đề mập mờ), bảng nhảy động thường chứa các giá trị tính toán phi tuyến tính phức tạp. Việc phân tích tĩnh để dựng lại câu lệnh `switch` sạch trong các trường hợp này vẫn gặp nhiều khó khăn và dễ bị sót CFG edge.
* **Alias Analysis (Phân tích biệt danh con trỏ):** McSema chuyển đổi toàn bộ bộ nhớ thành một mảng phẳng. Khi khôi phục các biến cục bộ (`alloca`), nếu mã nguồn gốc sử dụng ép kiểu con trỏ không an toàn hoặc truy cập vùng nhớ chồng chéo (unions), phân tích tĩnh có thể suy luận sai ranh giới của biến, dẫn đến viết lại sai ngữ nghĩa bộ nhớ.
* **Hỗ trợ kiểu dữ liệu đệ quy:** Hiện tại Phase 8 mới chỉ hỗ trợ khôi phục các cấu trúc struct và array phẳng đơn giản. Việc tái dựng lại các kiểu dữ liệu đệ quy phức tạp như danh sách liên kết (linked lists), cây nhị phân (trees) từ biểu diễn bộ nhớ thô vẫn chưa được hiện thực hóa.
