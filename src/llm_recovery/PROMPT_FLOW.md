# Prompt va flow LLM recovery

Tai lieu nay mo ta flow dang dung de khoi phuc source C tu binary-lifting artifacts.
Muc tieu la khoi phuc hanh vi quan sat duoc, khong phai chi lam dep ma gia decompiler.

## 1. Flow tong quat

```text
brightened reference binary + brightened LLVM IR
                |
                v
semantic equivalence baseline
                |
                +-- pass -- chon mode 1 hoac mode 2
                |
                +-- fail -- khong bat dau LLM recovery

mode 1: reference binary
          -> Ghidra analyzeHeadless
          -> ghidra_pseudocode.c
          -> ghidra_recovery_input.c
          -> File API + message prompt
          -> LLM JSON {"source": "..."}

mode 2: brightened LLVM IR
          -> File API + message prompt
          -> LLM JSON {"source": "..."}

LLM candidate
    -> parse strict JSON
    -> compile check
    -> semantic/fuzz check
    -> pass: accept candidate
    -> fail: feedback + candidate + original evidence -> repair prompt
    -> lap lai toi da 5 vong
```

Hai mode la hai lua chon doc lap:

| Mode | Dau vao LLM | Khi dung |
| --- | --- | --- |
| `1` / `ghidra` | Pseudocode C-like do Ghidra export tu brightened reference binary | Muon LLM co cau truc C, ten ham, control-flow va data-flow de khoi phuc source |
| `2` / `ir` | Brightened LLVM IR truc tiep | Muon bo qua decompiler va de LLM lam viec voi IR goc |

Mode 1 khong fallback tu dong sang mode 2. Neu Ghidra khong tao duoc pseudocode,
run mode 1 dung lai de tranh vo tinh doi nguon bang chung. Muon dung IR thi chon
mode 2 tu dau.

`brightened_ref.bin` va pseudocode Ghidra deu duoc attach raw trong cung request mode 1.
Pseudocode la bang chung doc chinh; ELF la bang chung binary bo sung de model co them context.
O mode 2 khong can binary hay Ghidra, chi gui brightened LLVM IR.

## 2. Cac lop prompt

### System prompt

System prompt dat vai tro va bien an toan:

- **Role prompting:** senior reverse engineer va C11 compiler engineer.
- **Muc tieu:** mot translation unit C11 day du, compile duoc, bao toan observable behavior.
- **Evidence hierarchy:** constants/control-flow/calls va data-flow duoc uu tien hon ten ham,
  comment hoac type do decompiler doan.
- **Behavior contract:** giu I/O, exit status, return value, string/byte constants,
  integer width/signedness, pointer arithmetic, global state va external calls.
- **Brightening co kiem soat:** duoc dat ten de doc, gom control-flow, bo dead code va
  rut gon temporary neu khong doi hanh vi; khong duoc tuong minh hoa semantics moi.
- **Output contract:** chi mot JSON object co key `source`, khong markdown, khong prose,
  khong source dang do.
- **Reasoning boundary:** LLM duoc suy luan noi bo nhung khong duoc in chain-of-thought.

### Initial prompt

Initial prompt dong vai tro task template va gan bang chung cu the:

1. Gan metadata cua sample va mode dang chay.
2. Dan model input artifact trong block `MODEL_INPUT_ARTIFACT`.
   Day chi la pseudocode Ghidra co the sai/mat thong tin hoac LLVM IR da duoc tao cho case do,
   khong phai original source.
3. Tuyet doi khong dua original source, ground-truth C, source dung de semantic checker,
   hoac file tham chieu tu dataset vao request LLM.
4. Neu la mode Ghidra, yeu cau normalize decompiler noise thanh C11 hop le thay vi copy
   nguyen cac temporary/lifted state.
5. Nhac lai cac dieu kien compile, `main`, header va strict JSON.
6. Cam khong dummy value, placeholder, patch/diff va phan giai thich.

Day la **in-context grounding** ket hop mot one-shot demonstration tong hop:

- Demo duoc tao co dinh trong code, khong doc tu dataset va khong lay tu sample dang chay.
- Demo mo phong dung dang noise dang gap: Ghidra wrapper/unknown type hoac LLVM lifted code.
- Demo chi day cach normalize va format JSON; khong day logic, ten, string hay constant cua case.
- Moi request chi chen mot demo theo dung mode dang chay.
- Khong dung demo that vi co the leak ground-truth hoac lam model copy logic sample khac.

### Repair prompt

Moi vong sua dung ba khoi du lieu:

- `VALIDATION_FEEDBACK`: loi parse, compile, semantic mismatch, timeout hoac crash.
- `CANDIDATE_SOURCE`: source cua vong truoc.
- `MODEL_INPUT_ARTIFACT`: pseudocode Ghidra hoac IR cua case dang recovery de model khong sua
  theo feedback mot cach mu quang. Day khong phai source goc.

Repair prompt yeu cau sua toi thieu nhung van tra ve **toan bo** translation unit. Neu candidate
bi cat ngang, model phai viet lai tu model input artifact, khong duoc tra ve declarations, diff hoac mot doan
patch. Day la **iterative self-refinement co external verifier**, trong do compiler va semantic
checker la nguoi danh gia, khong phai tu-danh-gia bang text cua LLM.

## 3. Thu tu uu tien khi prompt co xung dot

LLM nen xu ly bang chung theo thu tu sau:

1. Hanh vi quan sat duoc va feedback tu compiler/fuzzer.
2. Control-flow, call graph, constants, memory/data-flow trong artifact.
3. Declarations va type hints co the xac minh.
4. Ten ham, comment va type do Ghidra suy doan.
5. Suy luan bo sung, chi dung khi can thiet va phai conservative.

Comment canh bao cua Ghidra, `undefined`, `unknown`, ten `FUN_*` va temporary lift khong phai
la ly do de tao behavior moi.

## 4. Output va validation contract

LLM phai tra:

```json
{"source":"#include ...\nint main(...) { ... }"}
```

Adapter se parse JSON, lay `source`, compile candidate va dua candidate vao semantic/fuzz check.
Moi request gui day du system/task prompt va attach nguyen artifact. Input khong bi cat. Request
dung output ceiling toi da theo model (`65,535` token voi `gemini-3.5-flash`), khong dung cap
32K rieng cua adapter. Gioi han recovery van la `max_iter=5`; loi parse/compile/semantic va
`finishReason` cua provider duoc dua vao feedback cua vong ke tiep.

Prompt yeu cau model thuc hien noi bo program mapping, I/O analysis, semantic deobfuscation,
algorithm reconstruction va validation discipline truoc khi sinh code. Adapter van chi nhan JSON
`{"source":"..."}` de co the parse/compile; cac muc report dai trong prompt cua nguoi dung la
checklist noi bo, khong phai format response cua adapter.

Neu JSON khong hop le, source khong compile, hoac semantic check fail, feedback duoc dua vao vong
repair tiep theo. Chi candidate pass verifier moi duoc danh dau recovery thanh cong.

## 5. Cach chay

Chon Ghidra pseudocode:

```bash
LLM_RECOVERY_PSEUDO_BACKEND=1 python3 src/main.py data/llm_test.csv llm-recovery
```

Chon LLVM IR truc tiep:

```bash
LLM_RECOVERY_PSEUDO_BACKEND=2 python3 src/main.py data/llm_test.csv llm-recovery
```

Neu can chi ro executable Ghidra:

```bash
LLM_RECOVERY_GHIDRA_ANALYZE_HEADLESS=/opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless \
LLM_RECOVERY_PSEUDO_BACKEND=1 \
python3 src/main.py data/llm_test.csv llm-recovery
```

Khong can dat `LLM_RECOVERY_TWO_STAGE`. Bien nay khong phai lua chon input hien tai; lua chon
duy nhat la mode `1`/`ghidra` hoac `2`/`ir`.

## 6. Artifact va log quan trong

- `ghidra_pseudocode.c`: output export cua Ghidra.
- `ghidra_recovery_input.c`: file pseudocode duoc attach qua File API cho request LLM.
- `recovery_iter*.response.txt`: response raw cua model.
- `recovery_iter*.candidate.c`: source da extract.
- `recovery_iter*.parse.txt`: loi parse/compile/semantic dung lam feedback.

File attach va message prompt cung nam trong cung request; message noi cach dung evidence,
con file cung cap noi dung day du ma khong can cat IR.
