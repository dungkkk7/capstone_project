# Mô tả kỹ thuật Prompt

## Tên kỹ thuật

**Evidence-Grounded CEGIS Prompting**  
*(Prompt tổng hợp chương trình dựa trên bằng chứng và phản ví dụ)*

Tên đầy đủ:

**Evidence-Grounded Counterexample-Guided Inductive Synthesis Prompting**

Đây là một kỹ thuật prompt có cấu trúc, trong đó mô hình không tự đoán chương trình gốc mà phải:

1. Phân tích bằng chứng đầu vào.
2. Khôi phục hành vi quan sát được.
3. Sinh chương trình C ứng viên.
4. Kiểm tra bằng compiler và fuzzing.
5. Nhận phản ví dụ khi chương trình sai.
6. Sửa nguyên nhân ngữ nghĩa và sinh lại toàn bộ chương trình.

---

## Luồng xử lý

```text
Bằng chứng chương trình
        ↓
Phân tích ngữ nghĩa
        ↓
Sinh Candidate.c
        ↓
Biên dịch và kiểm thử
        ↓
Pass? ─── Có ───→ Recovered C Source
  │
 Không
  ↓
Phản ví dụ / lỗi kiểm thử
  ↓
LLM sửa nguyên nhân
  ↓
Candidate.c mới
```

---

## Bốn bài toán sử dụng cùng một kỹ thuật

Bốn cấu hình chỉ khác loại bằng chứng đưa vào mô hình:

### 1. Raw LLVM IR

Đầu vào là LLVM IR được lifting trực tiếp từ binary và vẫn còn:

- Control-flow flattening.
- Bogus control flow.
- Mixed Boolean Arithmetic.
- Dispatcher state.

Mô hình phải ưu tiên:

- Chuỗi def-use.
- Literal string.
- Lời gọi hàm và thứ tự tham số.
- Độ rộng dữ liệu.
- Truy cập bộ nhớ.
- Hành vi vào/ra.

---

### 2. Clean Pseudocode

Đầu vào là mã giả C được chuyển từ LLVM IR đã deobfuscate.

Pseudocode giúp đọc cấu trúc dễ hơn nhưng có thể sai:

- Kiểu dữ liệu.
- Signedness.
- Pointer và integer.
- Alias.
- Struct.
- Loop boundary.
- Prototype.

Vì vậy, pseudocode chỉ là giả thuyết có hướng dẫn, không phải sự thật tuyệt đối.

---

### 3. Clean LLVM IR

Đầu vào là LLVM IR sau khi loại bỏ obfuscation.

Mô hình ưu tiên:

- Phép toán chính xác.
- Branch predicate.
- Integer width.
- Signed và unsigned operation.
- Pointer arithmetic.
- Memory access.
- Call order.
- Return-value use.

Clean IR chính xác về ngữ nghĩa thấp tầng nhưng khó đọc ở mức source.

---

### 4. Clean LLVM IR + Clean Pseudocode

Mô hình nhận đồng thời hai biểu diễn.

Cách sử dụng:

- LLVM IR cung cấp ngữ nghĩa chính xác.
- Pseudocode hỗ trợ nhận diện cấu trúc dễ đọc.
- Khi hai nguồn mâu thuẫn, ưu tiên data flow, control flow và hành vi kiểm thử cụ thể.

Hai nguồn phải được hợp nhất thành một mô hình ngữ nghĩa chung, không được viết lại độc lập rồi chọn một kết quả.

---

## Các thành phần chính của kỹ thuật

### Evidence-Grounded Prompting

Mô hình chỉ được sử dụng:

- Artifact được cung cấp.
- Kết quả compile.
- Kết quả differential execution.
- Phản ví dụ từ fuzzing.

Không được tự tạo thêm:

- Output.
- Input constraint.
- Kích thước mảng.
- Prototype.
- Hành vi helper.
- Thuật toán quen thuộc nhưng không có bằng chứng.

---

### Evidence Hierarchy

Bằng chứng được chia theo độ tin cậy.

**Độ tin cậy cao:**

- Literal string.
- ABI call.
- Memory width.
- Branch predicate.
- Call argument order.
- Def-use chain.
- Validation feedback.

**Độ tin cậy trung bình:**

- Function boundary nhất quán.
- Stack offset.
- Cast xuất hiện lặp lại.
- Cấu trúc được nhiều phép truy cập hỗ trợ.

**Độ tin cậy thấp:**

- Tên biến.
- Tên hàm.
- Kiểu do decompiler đoán.
- Một cast riêng lẻ.
- Thuật toán nhìn có vẻ quen thuộc.

Bằng chứng yếu không được ghi đè bằng chứng mạnh.

---

### Task Decomposition

Prompt chia quá trình khôi phục thành các pha:

1. Chuẩn hóa bằng chứng.
2. Xác định observable contract.
3. Dựng call graph.
4. Dựng type và storage ledger.
5. Khôi phục control flow.
6. Tổng hợp mã C.
7. Tự kiểm tra.
8. Sửa theo phản ví dụ.

Việc chia pha giúp mô hình không sinh code quá sớm khi chưa hiểu chương trình.

---

### Observable Contract Recovery

Mô hình phải xác định trước:

- Cách chương trình nhận input.
- Cách chuyển đổi dữ liệu.
- Hành vi khi EOF hoặc input lỗi.
- Nội dung stdout và stderr.
- Khoảng trắng và newline.
- Exit code.
- Allocation failure.
- Early exit.
- Side effect có thể quan sát.

Mục tiêu là khôi phục hành vi, không phải hình thức source gốc.

---

### Semantic Ledger

Mô hình phải theo dõi nhất quán:

- Tham số hàm.
- Giá trị trả về.
- Biến local.
- Vùng nhớ dùng chung.
- Độ rộng dữ liệu.
- Signedness.
- Pointer và integer.
- Scalar và array.
- Value và address.
- Alias và lifetime.

Điều này hạn chế lỗi suy luận kiểu dữ liệu từ một instruction riêng lẻ.

---

### Constraint-Based Synthesis

Chương trình C được sinh ra phải bảo toàn:

- Integer width.
- Signedness.
- Wraparound.
- Truncation.
- Division và remainder.
- Pointer arithmetic.
- Call order.
- Callback operand order.
- Floating-point behavior.
- Output bytes.
- Exit status.

Mô hình không được thay chương trình bằng một phiên bản thuật toán textbook chỉ vì hình dạng có vẻ giống nhau.

---

### Self-Verification

Trước khi trả kết quả, mô hình phải tự kiểm tra:

- Thiếu helper function.
- Thiếu header.
- Sai prototype.
- Sai format string.
- Sai signedness.
- Sai array bound.
- Sai pointer offset.
- Thiếu lời gọi input/output.
- Sai EOF behavior.
- Sai return value hoặc exit code.

Sau bước này, compiler và fuzzing tiếp tục kiểm tra bên ngoài.

---

### Counterexample-Guided Repair

Khi candidate sai, lỗi kiểm thử được xem là một phản ví dụ.

Mô hình phải:

1. Xác định output hoặc trạng thái đầu tiên bị sai.
2. Trace ngược đến predicate, phép toán, biến hoặc memory access gây sai.
3. Tìm điểm phân kỳ sớm nhất.
4. Sửa quy luật ngữ nghĩa tổng quát.
5. Không hard-code input gây lỗi.
6. Kiểm tra nhánh lân cận và các caller liên quan.
7. Sinh lại toàn bộ translation unit.

Phản ví dụ chỉ chứng minh candidate sai; nó không phải giấy phép để vá riêng một test case.

---

## Vì sao dùng cùng một kỹ thuật cho cả bốn bài toán?

Cả bốn bài toán có cùng mục tiêu:

> Sinh một chương trình C11 độc lập có hành vi tương đương với binary.

Chúng chỉ khác biểu diễn bằng chứng.

Việc giữ cùng:

- System prompt.
- Quy trình phân tích.
- Quy tắc repair.
- Model.
- Temperature.
- Số vòng repair.
- Compile flags.
- Fuzzing budget.
- Tiêu chí pass.

giúp so sánh công bằng giữa các mode.

Khi đó, khác biệt kết quả chủ yếu đến từ chất lượng bằng chứng, không phải do mỗi mode được dùng một chiến lược prompt khác nhau.

---

## Phân tích phản biện

### Ưu điểm

- Giảm hallucination bằng evidence boundary rõ ràng.
- Tập trung vào behavioral equivalence.
- Phù hợp với reverse engineering.
- Kết hợp được compiler, differential execution và fuzzing.
- Repair hướng đến nguyên nhân gốc.
- Dùng được cho nhiều loại biểu diễn chương trình.
- Giúp đánh giá bốn mode công bằng hơn.

### Hạn chế

- Đây là **CEGIS-style**, không phải CEGIS hình thức hoàn toàn.
- LLM vẫn là bộ sinh xác suất.
- Fuzzing chỉ tìm được lỗi, không chứng minh tương đương tuyệt đối.
- Không tìm thấy mismatch không có nghĩa candidate hoàn toàn đúng.
- Chương trình lớn có thể vượt giới hạn context.
- Yêu cầu mô phỏng mọi execution path có thể không khả thi.
- Pseudocode và clean IR vẫn có thể chứa lỗi từ pipeline trước đó.

---

## Kết luận

Kỹ thuật phù hợp nhất cho hệ thống là:

> **Evidence-Grounded CEGIS Prompting**

Đây là phương pháp kết hợp:

- Prompt dựa trên bằng chứng.
- Phân cấp độ tin cậy.
- Phân rã nhiệm vụ.
- Theo dõi trạng thái ngữ nghĩa.
- Tổng hợp chương trình theo ràng buộc.
- Tự kiểm tra.
- Hợp nhất nhiều biểu diễn.
- Sửa lỗi dựa trên phản ví dụ.

Bốn bài toán sử dụng cùng một kỹ thuật; chỉ thay đổi loại evidence được cung cấp cho mô hình.
