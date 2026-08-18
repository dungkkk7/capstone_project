# 070 — phục hồi dữ liệu global mà không nhân đôi một vùng nhớ guest

**Plugin:** \`BrightenGlobalDataRecoveryPass.so\`  
**Tên pass:** \`brighten-global-data-recovery-pass\`  
**Hai pass hẹp đi kèm:** \`brighten-guest-pointer-resolver-canonicalize\` và
\`brighten-late-residual-format-string-recovery\`.

## 1. Sai lầm mà pass này phải tránh

Một binary lifted thường có một global byte aggregate cho nguyên section ELF:

\`\`\`llvm
@seg_408000__rodata = constant [16 x i8] c"ok\00............."
%p = getelementptr i8, ptr @seg_408000__rodata, i64 %index
%x = load i8, ptr %p
\`\`\`

Ta muốn biến một đoạn đã biết là chuỗi thành \`@.str.0\` để có
\`puts(@.str.0)\`. Nhưng không được biến nó thành *một global độc lập* nếu vẫn
còn access có thể đụng những byte ấy qua \`@seg_...\`: LLVM sẽ coi hai global là
hai storage khác nhau. Với segment writable, \`store @g_scalar\` và \`load
@seg\` có thể bị optimizer cho là không alias, trong khi ở binary gốc chúng là
cùng byte.

Vì vậy mục tiêu của 070 không phải “reconstruct được càng nhiều object càng
tốt”. Invariant của nó là:

> Một byte guest có ghi/đọc còn sống chỉ có một chủ sở hữu storage LLVM, trừ
> khi toàn bộ reference tương ứng đã được rewrite trong cùng transaction.

\`Candidate\` chỉ là giả thuyết “đoạn này có thể là StringLiteral/Scalar/Array…”.
\`RecoveredObject\` mới là backing đã commit. \`GuestAddressRef\` lưu từng nơi
IR dùng một guest address, consumer-kind và evidence. Nhờ phân biệt này, pass
có thể bỏ candidate nguy hiểm nhưng vẫn rewrite candidate độc lập ở segment
khác.

## 2. Pipeline thực tế và lý do phân tầng

\`run\` gọi các rule theo thứ tự:

\`\`\`text
DiscoverGuestSegments → FlattenSegmentBytes → BuildGuestAddressMap
→ InstallMappedPageTailOwners → GenerateObjectCandidates
→ ResolveObjectConflicts
→ RefuseCandidatesWithUnresolvedDynamicAlias
→ RefuseCandidatesWithObservedAddressIdentity
→ RefusePartialWritableCandidatesInAuthoritativeMap
→ MaterializeRecoveredGlobals → RecoverJumpTableCFG
→ RewriteGuestDataReferences → RewriteGuestPointerTranslatorCalls
→ RemoveDeadSegmentConstantUsers → CleanupDeadSegmentArtifacts → Verify
\`\`\`

Phần đầu không được mutate IR: nó thu segment, flatten initializer/relocation,
gán guest address, rồi tạo candidate có evidence như \`LibcStringArg\`,
\`LoadStoreWidth\`, \`IndexedStrideAccess\`, \`RelocationEntry\`,
\`ReadonlySection\` hay \`WriteObserved\`. Ba rule \`Refuse…\` chạy **sau**
conflict resolution: chúng có thể nhìn candidate cuối cùng, và trong source có
check \`if (!Candidate)\` vì conflict resolver để tombstone rỗng. Chạy
materialization trước các refusal sẽ đã lỡ tạo storage mới, không còn
fail-closed.

\`ObjectKind\` gồm \`StringLiteral\`, \`WideStringLiteral\`, \`Scalar\`,
\`Array\`, \`PointerTable\`, \`JumpTable\`, \`RawBytes\`. Không phải mọi kind có
cùng quyền rewrite: Array/RawBytes có thể là backing của access động;
scalar/string chỉ chứng minh một interval hay consumer cụ thể.

## 3. Dynamic carrier: rule từ chối quan trọng nhất

\`IsDynamicAddressCarrier(I)\` nhận:

- GEP có ít nhất một index không phải \`ConstantInt\`;
- \`inttoptr\` từ giá trị không constant;
- \`add\`/\`sub\` có operand không constant.

Ví dụ \`%p = gep i8, @seg, i64 %index\` là dynamic. Rule không cố đoán range
của \`%index\`; một dynamic carrier được coi có thể phủ bất kỳ candidate nào
trong source segment.

\`RefHasOwnedDynamicBacking(ref, Ctx)\` chỉ trả true khi ref không dynamic, hoặc
tồn tại candidate **cùng \`SourceSegment\`, cùng
\`Begin == ref.GuestAddr\`**, và kind là \`Array\` hoặc \`RawBytes\`. Ba điều
kiện đồng thời là bằng chứng dynamic base có backing byte-range riêng do rule
recovery sở hữu. Có chuỗi ở offset tương tự không đủ: chuỗi chỉ là typed view
của prefix, không chứng minh mọi \`%index\` còn nằm trong chuỗi.

\`RefuseCandidatesWithUnresolvedDynamicAlias\` gom source segment có ref không
có owned backing, rồi loại toàn bộ candidate của từng segment đó. Nó không
return sớm cả pass: comment source giải thích preflight all-or-nothing cũ từng
làm format string của section A không recover được vì section B có carrier
động. Giá phải trả là source segment nguy hiểm giữ residual bytes; candidate
segment an toàn vẫn được materialize.

\`test_same_segment_dynamic_refuses_string_split.ll\` là chứng cứ trực tiếp:
nó vừa gọi \`puts\` với prefix \`"ok\0"\`, vừa load từ GEP \`%index\` trên cùng
\`@seg_408000__rodata\`. CHECK yêu cầu global source còn, \`@.str.0\` không được
tạo và GEP động còn nguyên. Nếu chỉ test \`puts\` thì không khóa được điều kiện
alias; fixture này khóa đúng tình huống rule buộc phải từ chối.

## 4. So sánh địa chỉ: nội dung giống nhau không đồng nghĩa địa chỉ thay được

\`DataConsumerKind::ComparisonOnly\` biểu diễn dùng address để \`icmp\`, chứ
không load/store bytes. Với segment writable,
\`RefuseCandidatesWithObservedAddressIdentity\` duyệt candidate; nếu có
comparison ref cùng segment và address nằm trong \`[Begin, End)\`, candidate bị
bỏ với reason \`address-identity-observable\`.

Ví dụ \`@seg\` và \`@.str.0\` đều chứa \`"hello\0"\` nhưng
\`%p == @seg\` phụ thuộc identity của storage. Rewriting comparison sang pointer
native có thể thành phụ thuộc ASLR hay đổi kết quả. Source áp guard này chỉ lên
\`Writable\`: policy readonly hiện hữu cho phép giữ source identity carrier
trong khi rewrite content use đã chứng minh riêng.

\`test_mixed_buffer_identity.ll\` thể hiện đúng policy readonly: CHECK yêu cầu
\`puts(@.str.0)\` nhưng identity GEP/icmp vẫn trỏ
\`@seg_406000__rodata\`. Source global constant giữ identity, còn call content
use được retarget có chủ đích.

## 5. PT_LOAD map và mapped page tail

Khi module có metadata PT_LOAD,
\`buildAuthoritativeGuestAddressMap\` tạo list
\`[Begin, End) → GuestSegment\`, sort theo Begin và từ chối nếu hai interval
overlap (\`previous.End > current.Begin\`), size zero, base chưa resolve hoặc
phép \`base + size\` overflow. Chỉ map xây xong mới bật
\`HasAuthoritativeGuestAddressMap\`; nếu fail, code không chọn một global chồng
chéo “ngẫu nhiên”.

Một mapped page tail zero-fill đã là byte object concrete.
\`InstallMappedPageTailOwners\` đăng ký chính \`Seg->GV\` thành
\`RecoveredObject{RawBytes}\`, thay vì tạo scalar/dyn_bytes trong tail. Nhưng
nó scan ref: chỉ cần một dynamic carrier trong tail, nó **không** retarget base
sang zero tail. Carrier chưa có range proof có thể tạo địa chỉ out-of-tail;
rebasing sớm biến access đó thành zero read/write sai. Report ghi
\`requires-structural-cfg-range-proof\` và physical lifted backing tiếp tục là
owner.

\`RefusePartialWritableCandidatesInAuthoritativeMap\` áp invariant mạnh hơn
cho writable PT region. Nó đánh unsafe khi:

- segment là mapped page tail writable;
- ref có \`SkipReason\`, là \`ComparisonOnly\`, hoặc dynamic carrier;
- ref fixed nhưng không nằm trong candidate của cùng source segment.

Toàn bộ candidate thuộc source unsafe bị remove với reason
\`authoritative-map-region-not-transactionally-covered\`. Trong
\`test_pt_load_transactional_writable_refusal.ll\`, \`@data_3000\` vừa bị so
sánh identity vừa có GEP \`%idx\`; FileCheck cấm \`@dyn_bytes_\`,
\`@g_scalar_\`, \`@g_arr_\` và đòi GEP cũ tồn tại. Đây là test cho việc *không
tạo sibling storage*, không phải test “global recovery không làm gì”.

## 6. Từ candidate sang rewrite

Sau preflight, \`MaterializeRecoveredGlobals\` mới tạo global typed.
\`RewriteGuestDataReferences\` chỉ retarget ref đã có object/range/evidence phù
hợp; \`RewriteGuestPointerTranslatorCalls\` thay translator call có mapping đã
chứng minh. \`RecoverJumpTableCFG\` là rule khác: chỉ khi bảng entry và target
đều resolve thì đổi indirect dispatch sang CFG LLVM; bảng \`PointerTable\` hay
\`JumpTable\` chưa resolve đủ phải ở residual.

\`RemoveDeadSegmentConstantUsers\` và \`CleanupDeadSegmentArtifacts\` không
được “dọn đẹp” source chỉ vì có object mới. Nếu unresolved consumer còn dùng
segment, segment là byte-preserving residual và phải sống. Đây là điểm khiến
recovery partial vẫn sound thay vì copy-propagation sai alias.

## 7. Hai pass tách riêng trong cùng plugin

\`BrightenGuestPointerResolverCanonicalizePass\` chỉ gọi
\`CanonicalizeGuestPointerResolvers(M)\`: nó canonicalize spelling của resolver
guest pointer **đã được chứng minh** sau object recovery, không discover object
và không đổi range candidate.
\`BrightenLateResidualFormatStringRecoveryPass\` chỉ chạy muộn sau external ABI
bridge đã lộ direct libc format operand; nó không được dùng để “recover
arbitrary residual object”. Tách pass ngăn simplification pattern vô tình có
quyền materialize data mới.

Các fixture \`test_guest_pointer_resolver_canonicalize.ll\`,
\`test_late_residual_format_strings.ll\` và
\`test_late_residual_format_refusals.ll\` kiểm tra đường chấp nhận và biên từ
chối của hai pha hẹp đó.

## 8. Verify là rule có hiệu lực, không phải log cho đẹp

Ở \`NativeStrict\`, sau mutation, \`VerifyGlobalDataRecovery\` lỗi thì \`run\`
gọi \`report_fatal_error\`, trừ khi environment
\`BRIGHTEN_GLOBAL_AUDIT_ONLY\` được đặt. Code còn in unresolved carrier chưa
cover; ngoại lệ chỉ cho translator infrastructure, comparison-only và
arithmetic-only intermediate. \`LoadStorePointer\` hay dynamic actual consumer
không được im lặng bỏ qua.

Vì thế khi thêm test/rule mới, phải ghi rõ ref nào là actual memory consumer,
candidate nào owns range, nào là residual, và CHECK nào chứng minh không có
global sibling. Chỉ kiểm tra “đã có \`@.str\`” không đủ để chứng minh correctness
của pass này.

