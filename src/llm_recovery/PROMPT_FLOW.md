Có. **Không có một “tiêu chuẩn ISO cho prompt” duy nhất**, nhưng prompt trong file của mày đang áp dụng khá nhiều kỹ thuật prompt engineering bài bản.

### Các kỹ thuật đang dùng

| Kỹ thuật                            | Nó làm gì                                                                                                                               |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Role prompting**                  | Gán vai trò “senior reverse engineer và C11 compiler engineer” để xác định chuyên môn, phạm vi và cách trả lời.                         |
| **Grounding / evidence discipline** | Buộc model chỉ dựa trên Ghidra pseudocode hoặc LLVM IR, không tự đoán source gốc hay hành vi không có bằng chứng.                       |
| **Task decomposition**              | Chia quá trình thành program map, I/O contract, data flow, control flow, thuật toán, boundary cases rồi mới sinh C.                     |
| **Constraint prompting**            | Quy định phải có C11 đầy đủ, `main`, header, đúng signedness, output, exit code; cấm placeholder, assembly và code fragment.            |
| **Few-shot / In-context learning**  | Đưa một ví dụ giả lập Ghidra/LLVM → C để model học kiểu chuyển đổi mong muốn.                                                           |
| **Delimiter prompting**             | Dùng các thẻ như `<MODEL_INPUT_ARTIFACT>`, `<VALIDATION_FEEDBACK>`, `<CANDIDATE_SOURCE>` để model phân biệt dữ liệu với chỉ thị.        |
| **Output contract**                 | Yêu cầu duy nhất một object có trường `source`, nhằm giảm prose và markdown thừa.                                                       |
| **Iterative refinement**            | Compile/fuzz lỗi thì đưa feedback và candidate cũ vào prompt sửa ở vòng sau. Nó giống compiler-guided repair hơn là hỏi model một lần.  |
| **Deterministic generation**        | Temperature thấp và chỉ lấy một candidate để kết quả ổn định hơn.                                                                       |
| **Post-generation validation**      | Parser kiểm tra JSON, source đầy đủ, cân bằng dấu ngoặc, có `main`, không chứa placeholder trước khi compile.                           |

### Kiến trúc đúng nên là 3 lớp

**Lớp 1 — Prompt semantic**

Nói cho model biết phải khôi phục hành vi gì, nguồn bằng chứng nào được phép dùng và điều gì không được tự bịa.

**Lớp 2 — Structured output**

Không chỉ ghi trong prompt là “return JSON”. Phải ép tại API bằng response schema:

```text
object
└── source: string, required
```

Cách này mạnh hơn “JSON only” rất nhiều, vì yêu cầu trong prompt chỉ là ràng buộc mềm.

**Lớp 3 — Parser và validator**

Dù đã ép schema vẫn phải kiểm tra:

```text
JSON parse
    ↓
source tồn tại
    ↓
cú pháp cân bằng
    ↓
có main
    ↓
clang compile
    ↓
differential fuzz
```

Đây mới là cách làm ổn định. **Không nên tin prompt một mình**.

### Prompt này thuộc kiểu nào?

Tên gọi phù hợp nhất là:

> **Schema-constrained, evidence-grounded, compiler-in-the-loop recovery prompt**

Nó kết hợp:

```text
Evidence-grounded generation
+ Few-shot prompting
+ Prompt-as-contract
+ Structured output
+ Compiler-guided iterative repair
+ Differential validation
```

### Điểm bản cũ chưa tốt

Bản cũ có nhiều chỉ thị bị lặp như “strict JSON”, “no markdown”, “complete translation unit”. Lặp quá nhiều không bảo đảm tuân thủ tốt hơn, đôi khi còn khiến model tập trung vào format hơn semantics. Ngoài ra, repair prompt từng chứa candidate trong markdown fence, trong khi lại cấm model trả markdown, tạo ra ví dụ hành vi không nhất quán.

Bản sửa đã đi theo hướng tốt hơn: **prompt ngắn và phân tầng hơn, schema xử lý format, parser xử lý lỗi cấu trúc, compiler/fuzzer xử lý tính đúng**. Đây là kiến trúc đúng bài hơn việc tiếp tục nhồi thêm câu “MUST RETURN VALID JSON” vào prompt.
