# Tài liệu tham chiếu Brightening LLVM pass

Tài liệu này mô tả pipeline đang được driver gọi, không phải một thiết kế
lý tưởng hoá. Source of truth là `src/llvm_pass/britening_ir.py` (biến
`PASS_PIPELINE`), entry point `run` của mỗi plugin, và test fixture cùng
runner nằm cạnh plugin.

## Cách đọc

IR đầu vào là *lifted IR* từ McSema/Remill. Nó không phải C/LLVM native bình
thường: thanh ghi nằm trong `%State` hoặc `@__mcsema_reg_state`, memory được
thread qua token `ptr`, program counter là số nguyên guest, indirect jump là
dispatcher, và stack/data thường là các blob byte. Vì vậy một rewrite chỉ hợp
lệ khi nó giữ được semantics của máy khách, chứ không chỉ làm LLVM verifier
chấp nhận.

Mỗi tài liệu trả lời năm câu hỏi:

1. Pass nhận dạng hình IR nào.
2. Nó biến đổi chính xác thành gì.
3. Tại sao phép biến đổi giữ semantics, hoặc vì sao phải từ chối.
4. Pass nào cần output đó và do đó thứ tự có ý nghĩa gì.
5. Fixture/test nào là executable specification cho boundary đó.

Đọc [000-lifted-ir-semantics.md](000-lifted-ir-semantics.md) trước nếu chưa
quen `poison`, `inbounds`, guest pointer, State/memory token và PHI. Đây là
nền tảng cho các lý do kỹ thuật trong từng pass.

## Pipeline hiện tại

`britening_ir.py` load các plugin dưới đây. Chuỗi pass còn có các LLVM pass
chuẩn (`sroa`, `mem2reg`, `instcombine`, `simplifycfg`, `default<O*>`...) để
dọn pattern sau khi các custom pass làm lộ chúng.

`BRIGHTEN_OPT_LEVEL=O1|O2|O3` chọn cùng một standard-optimizer treatment cho
hai điểm `default<O*>` trong driver và hai điểm trong bundle 100. Default
production là `O3`; experiment phải ghi level vào protocol manifest.

| Phase | Plugin / pass name | Tài liệu |
| --- | --- | --- |
| 010 | `brighten-repair-pass` | [010-repair.md](010-repair.md) |
| 015 | `brighten-remill-runtime-pass` | [015-runtime-materialization.md](015-runtime-materialization.md) |
| 020 | `brighten-devirt-pass`, `brighten-region-ssa-unflatten-pass` | [020-devirtualization.md](020-devirtualization.md) |
| 030 | `brighten-state-ssa-pass`, `brighten-local-state-ssa-pass` | [030-state-ssa.md](030-state-ssa.md) |
| 040 | `brighten-stack-frame-pass`, `brighten-post-state-frame-pass` | [040-stack-frame.md](040-stack-frame.md) |
| 050 | `brighten-abi-recovery-pass` | [050-abi-recovery.md](050-abi-recovery.md) |
| 060 | `brighten-extern-call-bridge` | [060-external-call-bridge.md](060-external-call-bridge.md) |
| 070 | `brighten-global-data-recovery-pass` and late resolver/string passes | [070-global-data.md](070-global-data.md) |
| 080 | `brighten-type-reconstruct` and pointer canonicalizers | [080-type-reconstruction.md](080-type-reconstruction.md) |
| 090 | native cleanup/post-frame/final contract passes | [090-native-cleanup.md](090-native-cleanup.md) |
| 095 | `095` proof-driven OLLVM deobfuscator | [095-deobfuscation.md](095-deobfuscation.md) |
| 100 | post-delift executable bundle | [100-delift-bundle.md](100-delift-bundle.md) |

## Contract dùng xuyên pipeline

Mặc định là **fail closed**. Pass có thể để fake stack, guest pointer chưa
resolve, opaque predicate hoặc dispatcher trong output. Nó không được thay
chúng bằng host pointer đoán, `undef`, type tuỳ ý hay CFG edge direct chỉ vì
decompiled output nhìn đẹp hơn.

`verify` chỉ chứng minh LLVM structural validity. Final contract 090 là
boundary proof/report riêng cho việc output còn lifted/guest artifact hay
không.
