# O1/O2/O3 thực sự làm gì trên IR

## 1. Kết luận

O1, O2 và O3 không phải ba nhãn gắn ở cuối pipeline. Mỗi treatment thay đúng
bốn lần `default<O*>`: hai lần trong main brightening pipeline và hai lần trong
bundle 100. Phép đo mới đặt `print` ngay trước/sau hai biên main trong cùng một
process production, replay trực tiếp hai biên bundle, rồi đếm opcode và CFG.

Kết quả chính:

- O1 đã làm phần lớn việc “mở khóa” IR: inline helper, SROA/SSA cleanup, xóa
  call, load/store và GEP do lifting để lại.
- O2 dọn memory mạnh hơn O1, nhất là store và GEP sau khi custom pass đã làm lộ
  alias/data flow. Trên bộ tự xây, đây là điểm cân bằng cấu trúc tốt.
- O3 không phải O2 “dọn mạnh hơn”. Nó có thêm biến đổi scalar/CFG như
  call-site splitting, argument promotion, non-trivial loop unswitch và CHR.
  Vì vậy nó có thể tạo thêm block, PHI và nhánh để mở cơ hội tối ưu khác.
- Production chủ động tắt loop vectorization, SLP vectorization và loop
  unrolling. Do đó không được giải thích O3 bằng vectorization/unrolling trong
  thí nghiệm này; vector instruction sau các biên là 0.
- O2/O3 cho tổng opcode giống nhau trên bộ tự xây, nhưng chỉ trùng cấu trúc ở
  26/40 case sau biên main đầu và 29/40 ở bundle. Trên bộ public, chúng chỉ
  trùng 1/40 sau main và 2/40 ở bundle. Kết luận “O2 bằng O3” từ một dataset là
  sai.
- `delift_storage.py` và `strip_brighten_residuals.py` là no-op byte-identical
  ở toàn bộ 80 chương trình × 3 level × 2 script = 480 stage observations.
  Chúng chưa có evidence đóng góp trên phạm vi hiện tại.

## 2. Hai dataset trả lời hai câu hỏi khác nhau

| Dataset | 40 case | Dùng để kết luận gì | Không dùng để kết luận gì |
|---|---|---|---|
| `own_v1` | C11 CLI tự xây, 8 category | Kết quả LLM contamination-resistant, paired B0–B3/F3; tác động IR trên đúng task chính | Không chứng minh zero contamination hoặc external generality |
| `public_v1` | 40 case `pXXXXX` từ public corpus | Kiểm tra IR transformation có tổng quát sang chương trình lớn/khác phân bố không | Không dùng làm headline LLM vì nguy cơ train overlap |

Vì vậy headline behavioral vẫn lấy `own_v1`; public set là validation thứ hai
cho claim về optimizer. Đây là cách tránh hai lỗi đối lập: dùng public source để
khẳng định LLM không nhớ đáp án, hoặc chỉ dùng own source rồi tổng quát hóa quá
mức về LLVM pass.

## 3. Topology và cách đo causal boundary

Main pipeline có dạng rút gọn:

```text
raw lifted IR
  -> custom 010..095 + scalar preparation
  -> default<O*>                 [main boundary 1]
  -> native/ABI/residual/state/CFG custom passes
  -> default<O*>                 [main boundary 2]
  -> address/frame/native cleanup
  -> brightened IR
```

Bundle 100 có dạng:

```text
brightened IR
  -> exact sccp/instcombine/dce/simplifycfg
  -> default<O*>                 [bundle boundary 3]
  -> delift_storage              [observed no-op]
  -> strip_brighten_residuals    [observed no-op]
  -> default<O*>                 [bundle boundary 4]
  -> dedup + bounded 095 + scalar/native final cleanup
  -> final Clean IR
```

Với hai biên main, tách optimizer thành process khác là không hợp lệ vì custom
pass có state/naming và interaction với analysis cache. Instrumentation hiện
tại chèn LLVM `print` trước/sau `default<O*>`, nên không mutate module và vẫn
chạy trong đúng process. Với bundle, input/output đã persisted nên replay trực
tiếp được.

Validation replay:

| Dataset | Exact metric match | Structural hash match | Ghi chú |
|---|---:|---:|---|
| own | 120/120 | 120/120 | toàn bộ ba level hợp lệ |
| public | 119/120 | 10/120 | khác clone suffix/SSA name phổ biến; một `p02814/O1` có +24 instruction do custom-pass nondeterminism và bị loại khỏi tổng biên main O1 |

Do đó bảng public dùng `n=39` cho hai biên main O1, `n=40` cho mọi hàng còn
lại. Aggregate được gate bằng vector metric/opcode đầy đủ, không gate bằng tên
SSA hoặc suffix tự sinh.

## 4. Biên optimizer trên own dataset

Mọi số là tổng delta trên 40 case: số âm là opcode/block bị loại, số dương là
được tạo thêm.

| Level/biên | Instr | BB | Memory ops | Call | Load | Store | GEP | PHI | Cond br |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| O1 main-1 | -3,862 | -386 | -3,062 | -376 | -552 | -1,511 | -911 | +338 | -19 |
| O1 main-2 | -821 | -31 | -155 | -52 | +21 | -86 | -90 | -23 | -21 |
| O1 bundle-3 | -2,484 | -2 | -2,372 | -5 | -699 | -1,273 | -400 | -19 | 0 |
| O1 bundle-4 | -35 | 0 | -31 | 0 | -12 | -12 | -7 | 0 | 0 |
| O2 main-1 | -4,379 | -390 | -3,444 | -376 | -562 | -1,882 | -912 | +325 | -19 |
| O2 main-2 | -1,489 | -30 | -681 | -52 | +18 | -308 | -391 | -29 | -21 |
| O2 bundle-3 | -4,451 | -13 | -4,137 | -20 | -734 | -3,368 | -35 | -33 | -1 |
| O2 bundle-4 | -396 | 0 | -373 | 0 | 0 | -373 | 0 | 0 | 0 |
| O3 main-1 | -4,379 | -390 | -3,444 | -376 | -562 | -1,882 | -912 | +325 | -19 |
| O3 main-2 | -1,489 | -30 | -681 | -52 | +18 | -308 | -391 | -29 | -21 |
| O3 bundle-3 | -4,451 | -13 | -4,137 | -20 | -734 | -3,368 | -35 | -33 | -1 |
| O3 bundle-4 | -396 | 0 | -373 | 0 | 0 | -373 | 0 | 0 | 0 |

### 4.1 Main boundary 1

Đây là biên có hiệu ứng rộng nhất. `always-inline` và custom 010–095 trước đó
đã biến helper/state semantics thành IR mà optimizer hiểu; `default<O*>` mới có
thể:

- inline/xóa 376 call và 88 alloca;
- dùng SROA, early-CSE, instcombine và simplifycfg để đưa local state sang SSA;
- xóa 552–562 load, 1,511–1,882 store và khoảng 912 GEP;
- tạo thêm 325–338 PHI vì giá trị từ memory/state được hợp nhất theo CFG.

PHI tăng không phải regression tự động. Ở đây nó là dấu hiệu memory traffic đã
được chuyển thành SSA value. Tác dụng tốt là data flow rõ hơn cho pass sau và
LLM; tác dụng xấu là nếu CFG còn rối, nhiều PHI có thể làm representation khó
đọc.

O2/O3 hơn O1 chủ yếu ở 371 store bị xóa thêm tại chính biên này. Đây phù hợp
với aggressive instcombine, GVN/DSE và propagation mạnh hơn, không phải một
“deobfuscation algorithm” riêng.

### 4.2 Main boundary 2

Giữa hai biên, native cleanup, ABI recovery, local-state SSA, region unflatten,
jump-threading, SROA/mem2reg làm lộ pattern mới. Lần optimizer thứ hai vì vậy
không lặp vô ích:

- O1 xóa thêm 821 instruction, 52 call và 31 block.
- O2/O3 xóa 1,489 instruction; phần chênh chủ yếu là 222 store và 301 GEP hơn
  O1.
- Load tăng nhẹ (+18/+21) vì scalarization/CFG rewrite có thể thay một biểu
  thức memory tổng hợp bằng load explicit. Không nên dùng “mọi opcode đều phải
  giảm” làm tiêu chí tốt/xấu.

### 4.3 Exact pointer cleanup trước bundle-3

Chuỗi cố định `sccp, instcombine, dce, simplifycfg` loại 353/370 instruction
và 107/116 PHI ở O1/O2-O3. Đây là cleanup hẹp để canonicalize pointer/constant
trước optimizer; không được gán phần giảm này cho `default<O*>`.

### 4.4 Bundle boundary 3

Đây là nơi khác biệt O1/O2 rõ nhất trên own set:

- O1 xóa 2,372 memory ops.
- O2/O3 xóa 4,137 memory ops, trong đó riêng store là 3,368.

Insight: custom/native passes tạo nhiều store trung gian để giữ semantics trong
quá trình delift. O2 có DSE/GVN và propagation đủ mạnh để chứng minh phần lớn
store không còn observable. Vì vậy O2 tốt cho độ gọn IR. Rủi ro là optimization
mạnh có thể restructure source idiom, làm C sinh ra kém tự nhiên dù semantics
không đổi; behavioral score không tăng tương ứng.

### 4.5 Bundle boundary 4 và custom final tail

Biên O thứ tư gần convergence: O1 chỉ xóa 35 instruction; O2/O3 xóa 396, hầu
hết là 373 store. Sau nó, custom final cleanup mới làm phần việc lớn còn lại:

| Level | Instr | BB | Memory | Call | Load | Store | GEP | PHI |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| O1 tail | -4,336 | -82 | -3,627 | -29 | -148 | -3,439 | -39 | -87 |
| O2 tail | -1,063 | -71 | -613 | -13 | -107 | -469 | -36 | -59 |
| O3 tail | -1,063 | -71 | -613 | -13 | -107 | -469 | -36 | -59 |

O1 để lại nhiều việc cho `internalize/ipsccp/deadargelim/globalopt`, scalar
cleanup và native-final passes. O2/O3 đã xóa sớm phần lớn dead store, nên tail
nhỏ hơn. Không được nhìn riêng “tail O1 xóa nhiều hơn” rồi kết luận O1 tốt hơn;
đó là work-shifting giữa các stage.

## 5. Biên optimizer trên public dataset

| Level/biên | n | Instr | BB | Memory ops | Call | Load | Store | GEP | PHI | Cond br |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| O1 main-1 | 39 | -25,596 | -369 | -9,222 | -553 | -1,222 | -1,867 | -5,988 | -101 | -153 |
| O1 main-2 | 39 | -8,542 | -74 | -2,589 | -78 | -375 | -536 | -1,674 | -14 | -2 |
| O1 bundle-3 | 40 | -4,578 | -44 | -1,318 | -8 | -362 | -627 | -328 | -62 | +12 |
| O1 bundle-4 | 40 | -516 | +8 | -102 | -11 | +6 | +133 | -241 | +2 | +14 |
| O2 main-1 | 40 | -32,403 | -440 | -13,205 | -604 | -1,792 | -3,490 | -7,768 | +178 | -141 |
| O2 main-2 | 40 | -4,292 | -63 | -262 | -85 | -19 | +115 | -354 | -86 | +5 |
| O2 bundle-3 | 40 | -4,745 | -35 | -1,618 | -1 | -361 | -799 | -458 | -38 | +11 |
| O2 bundle-4 | 40 | -607 | -18 | -200 | -4 | -40 | +7 | -167 | -19 | +3 |
| O3 main-1 | 40 | -32,385 | -439 | -13,133 | -614 | -1,783 | -3,439 | -7,756 | +177 | -134 |
| O3 main-2 | 40 | -3,939 | -45 | -146 | -91 | +1 | +255 | -398 | -63 | +13 |
| O3 bundle-3 | 40 | -4,373 | +8 | -1,504 | -5 | -374 | -757 | -367 | +15 | +27 |
| O3 bundle-4 | 40 | -739 | -15 | -346 | -3 | -47 | -87 | -212 | -11 | +5 |

Public programs lớn hơn làm lộ hành vi mà own set không kích hoạt:

- O3 bundle-3 xóa instruction nhưng tạo ròng 8 block, 15 PHI và 27 nhánh điều
  kiện. Đây là CFG specialization/unswitching: đổi code size và readability để
  mở đường thực thi chuyên biệt.
- O2 bundle-3 xóa nhiều instruction và memory ops hơn O3, đồng thời không tăng
  block. Trong cấu hình ưu tiên Clean IR dễ đọc, đây là bằng chứng nghiêng về
  O2 hơn O3.
- Final mean của public là O1 1,069.475 instruction/87.85 block; O2
  1,058.3/86.6; O3 1,067.975/88.125. O3 không tối thiểu hóa IR.

## 6. O-level gồm những nhóm biến đổi nào

Đây là giải thích implementation dựa trên expanded LLVM 21 pipeline, không
phải attribution riêng từng internal pass:

| Level | Nhóm chính được kích hoạt | Hiệu ứng quan sát phù hợp |
|---|---|---|
| O1 | SROA, early-CSE, instcombine, simplifycfg, conservative inline, LICM/indvars, memcpyopt, SCCP/DCE | xóa helper/state/memory noise lớn, chuyển memory sang SSA |
| O2 | O1 + speculative execution, jump threading, correlated propagation, aggressive instcombine, constraint elimination, GVN, DSE, loop transforms | xóa store/GEP và memory ops mạnh hơn |
| O3 | O2 + call-site splitting, arg promotion, non-trivial loop unswitch, CHR, O3 unroll policy | CFG/PHI/branch thay đổi mạnh trên public; không bảo đảm IR nhỏ hơn |

Lưu ý: nominal pipeline O2/O3 có vector/SLP và O3 unroll policy, nhưng runner
truyền `-vectorize-loops=false`, `-vectorize-slp=false` và
`-disable-loop-unrolling`. Vì thế ba nhóm này không thực thi trong treatment.

## 7. Liên hệ với behavioral result

| Treatment | PASS own | Calls | Mean runtime |
|---|---:|---:|---:|
| F3-O1 | 38/40 | 60 | 56.66 s |
| F3-O2 | 38/40 | 65 | 58.23 s |
| F3-O3 | 37/40 | 72 | 65.66 s |

Không có gain monotonic: O2 gọn IR hơn nhưng không tăng tổng PASS; O3 vừa tốn
hơn vừa mất một PASS. Giải thích hợp lý là optimizer có hai tác động ngược:

1. xóa lifting/obfuscation noise, giảm gánh suy luận cho LLM;
2. restructure CFG/data flow, có thể làm mất source idiom hoặc tạo PHI/branch
   khó diễn giải.

Campaign hiện tại đo tổng của hai tác động, không chứng minh opcode nào trực
tiếp gây PASS/FAIL. Muốn causal đến internal pass cần leave-one-pass-out hoặc
pass-by-pass randomized ablation. Kết luận hợp lệ hiện tại: O1 đủ tốt về E2E,
O2 là operating point gọn IR hơn, O3 không có lợi trong cấu hình readability.

## 8. Khối nào giữ, khối nào phải sửa claim

| Khối | Evidence | Quyết định/claim hợp lệ |
|---|---|---|
| Bốn `default<O*>` | delta opcode/CFG tại đúng biên, hai dataset | giữ; mô tả vai trò expose-and-clean, không gọi là deobfuscator độc lập |
| Exact pointer cleanup | giảm PHI/instruction trước bundle-3 | giữ; tách số khỏi optimizer |
| `delift_storage.py` | 240/240 execution no-op | conditionalize hoặc thêm fixture kích hoạt trước khi claim contribution |
| `strip_brighten_residuals.py` | 240/240 execution no-op | cùng kết luận trên |
| Final native/scalar cleanup | giảm lớn, đặc biệt sau O1 | giữ; đây là consumer quan trọng của optimizer output |
| O3 | không tăng PASS; tạo CFG trên public | không chọn mặc định chỉ vì level cao hơn |

## 9. Artifact để audit

- `reports/ir_boundary_own_20260816/optimization_boundary_analysis.json`
- `reports/ir_boundary_public_20260816/optimization_boundary_analysis.json`
- `reports/ir_boundary_*/optimization_boundary_case_metrics.csv`
- `reports/ir_boundary_*/optimization_boundary_opcode_case_deltas.csv`
- `reports/ir_boundary_*/main_pipeline_replay_validation.csv`
- `reports/ir_optimization_*/ir_transition_summary.csv`
- `src/evaluation/run_ir_optimization_boundary_audit.py`

Mọi số trong tài liệu này có thể truy ngược về case, level, boundary và opcode.
