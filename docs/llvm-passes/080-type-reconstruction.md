# 080 — phục hồi con trỏ native và layout type, không đoán từ inttoptr

**Plugin:** BrightenTypeReconstructionPass.so  
**Tên pass:** brighten-type-reconstruct; các biến thể là brighten-struct-recover,
brighten-array-recover, brighten-address-canonicalize,
brighten-heap-proven-resolver-collapse.

## 1. Bốn entry point không làm cùng một việc

brighten-type-reconstruct chạy theo đúng thứ tự:

~~~text
RecoverNativePointerIntegerRoundTrips
→ DiscoverCandidates → AnalyzePointerOffsets → PlanAndRewrite → VerifyReconstruction
~~~

Hai pass struct/array cũng gọi pointer-roundtrip trước, nhưng ép planner chỉ
chọn struct hoặc chỉ chọn array. Address canonicalize và heap-resolver collapse
là pass độc lập; chúng không tự chạy khi gọi type-reconstruct. Cờ command line
đặt policy: mode conservative/balanced/aggressive, confidence tối thiểu,
pointer-search depth (mặc định 4), số phần tử tối thiểu để suy array (mặc định
2), report JSON, verify, dump rejection. Mode thay ngưỡng chọn plan, không cho
phép vượt qua proof provenance bên dưới.

## 2. RecoverNativePointerIntegerRoundTrips: chính xác cái gì được đổi

Mẫu IR cần phục hồi có thể là:

~~~llvm
%bits = ptrtoint ptr %p to i64
%addr = add i64 %bits, 8
%q = inttoptr i64 %addr to ptr
%v = load i32, ptr %q
~~~

Rule không hiểu “mọi inttoptr i64 là pointer”. Nó bắt đầu từ từng IntToPtrInst,
rồi chứng minh integer source có một NativeBase.

Native base trực tiếp chỉ là:

- alloca hoặc GlobalValue;
- kết quả call có return attribute noalias, function/call attribute allocsize,
  AllocKind::Alloc, và không có Realloc.

Với nhánh ptrtoint, integer width phải đúng index-width của DataLayout, pointer
type không phải non-integral. Không đạt là từ chối: cắt/tràn i32/i64 không còn
là cùng biểu diễn pointer.

### 2.1 Pointer đã serialize qua slot cũng không tự nhiên “đúng”

Rule cho phép store ptrtoint vào một slot rồi load, sau đó inttoptr, nhưng
analyzeSerializedBase đòi toàn bộ các điều kiện:

1. load/store không volatile, không atomic, type integer giống nhau;
2. slot quy về cùng alloca và cùng byte offset hằng; kích thước load phải nằm
   trong allocation;
3. alloca không bị capture;
4. chỉ có một store provenance hợp lệ dominates load;
5. không có instruction may-write có thể đi được giữa store và load, đụng
   overlap cell đó.

mayClobberCell xét store, atomic RMW/CmpXchg, memintrinsic và call có pointer
argument cùng base. Với call may-write không nhận base làm argument, nó không
tự kết luận clobber; với overlap/size chưa biết nó từ chối. Đây là lý do
test_native_pointer_slot_roundtrip.ll là case dương, còn
test_native_pointer_slot_capture_negative.ll phải giữ inttoptr: slot đã escape
không còn là một ô riêng tư mà rule có thể chứng minh.

### 2.2 Offset được phép có hình gì

Nếu whole integer không phải base trực tiếp, rule chỉ nhận add(base, offset)
hoặc add(offset, base); sub(base, offset) bị từ chối ở nhánh này.
isAffineOffset cho offset qua add/sub, nhân với hằng, shift có amount hằng,
zext/sext; nó cấm ptrtoint/inttoptr lồng, phép nhân hai biến và opcode khác.
Như vậy pass biết integer phụ là độ dời, không phải địa chỉ thứ hai đã trộn
provenance.

Nó còn dùng ScalarEvolution lấy signed range của offset. Range phải hữu hạn,
không âm; max_offset + access_size phải nằm trong known object size. Nếu offset
khác 0, base phải known-nonzero tại điểm inttoptr. Đây là proof
dereferenceability: GEP từ null cộng offset có semantics khác với dereference
address integer tuỳ target.

### 2.3 Use graph bị giới hạn có chủ ý

getAccessShape chỉ cho phép mọi use của inttoptr là ordinary load hoặc store
với chính nó làm pointer operand; volatile, atomic, call, comparison, cast,
atomic RMW/CmpXchg đều từ chối. Rule cần biết loại access và size cố định; nếu
các access type không đồng nhất, nó vẫn có thể dùng GEP byte, nhưng không tự
khẳng định element type.

Trước rewrite còn hai hàng rào:

- integer bit của ptrtoint chỉ được dùng để dựng address tới target inttoptr,
  qua add/sub/mul/shl/zext/sext. So sánh integer, store, call, tag, hoặc
  derivation thứ hai làm bit-address quan sát được và bị từ chối;
- root pointer chỉ được dùng qua bridge, dereference, cast/GEP tiếp tục an
  toàn, hoặc icmp với null. Escape/callback, compare với pointer khác, hay
  propagation khác là identity observation và bị từ chối.

Vì vậy test_native_pointer_direct_safety_negative.ll và
test_native_pointer_provenance_negative.ll không phải “case chưa hỗ trợ”: nếu
rewrite chúng, pass sẽ xoá một integer/pointer identity mà chương trình có thể
quan sát.

Sau proof, rule thay inttoptr bằng base hoặc getelementptr. Nếu access element
type thống nhất và SCEV chứng minh offset là bội element-size, nó tạo exact
sdiv offset, size rồi GEP typed; nếu không dùng GEP i8. exact là claim còn chia
dư thì poison, nên chỉ được dùng sau proof constant multiple.

## 3. Candidate type: chỉ raw byte aggregate mới được retype

DiscoverCandidates chọn:

- alloca có allocated type đúng [N x i8], allocated type sized, array count
  đúng constant 1;
- global có value type [N x i8], sized và size khác 0.

Điều kiện alloca array count == 1 rất quan trọng. alloca [16 x i8], i64 %n cấp
n object, không phải một object 16 byte; tạo một inferred alloca sẽ làm co
allocation. Kể cả count hằng lớn hơn 1 cũng bị bỏ cho đến khi planner biết bảo
toàn outer count. test_alloca_array_count.ll khóa biên này.

AnalyzePointerOffsets thu access có offset/type; planner thử array trước (trừ
struct-only), rồi struct. Nếu không có type hợp lệ, candidate bị tính
ObjectsRejectedUnknownOffset; candidate escape bị loại trước đó và đếm
ObjectsRejectedEscape. PrevalidateTypePlan chạy trước mutation: initializer
không rebuild được là ObjectsRejectedInitializer, không phải “đã đổi nửa global
rồi mới phát hiện lỗi”.

Ví dụ accesses i32 tại 0, 8, 12 trong object 16 byte buộc plan struct phải có
padding [4 x i8] ở offset 4; không được tạo ba i32 sát nhau vì chúng biểu diễn
offset 0,4,8, sai layout. Overlap kiểu mâu thuẫn, offset unknown, escaped base,
initializer không model được là các lý do reject có thể xuất trong report JSON.

## 4. Commit alloca/global khác nhau vì ABI khác nhau

Với stack candidate, planner tạo alloca inferred type ở entry block, cùng
address space/alignment, rewrite pointer use theo plan rồi chỉ xoá old alloca
khi use_empty.

Với global internal đủ kín, planner rebuild initializer thành type mới, tạo
global mới, copy attributes và metadata (đặc biệt brighten.guest.range),
rewrite typed uses; nếu use residual còn, nó replaceAllUsesWith(NewGV) trước
erase old global. Opaque pointer khiến hai global có cùng LLVM value type ptr;
giữ cả hai sẽ tạo hai host allocation cho một guest object: libc có thể ghi
một cái, indexed access đọc cái kia.

Global external/weak/linkonce hoặc externally_initialized không được đổi storage
type: linker/translation unit khác có thể phụ thuộc ABI storage cũ. Rule chỉ
RewritePointerUses(GV, GV,...), tức tạo typed overlay/GEP trên cùng backing.
test_externally_initialized_global.ll và test_unresolved_pointer_initializer.ll
là các test cho ranh giới đó.

## 5. Hai simplifier proof-only

### CanonicalizeAddresses

Header quy định cancellation modular chỉ hợp lệ sau khi chứng minh root pointer
không undef/poison ở use và integer representation không bị quan sát ở nơi
khác. Nó không có quyền đổi arbitrary resolver/inttoptr. Fixture
test_same_anchor_ptrint_affine.ll kiểm tra cùng anchor qua integer affine, còn
negative fixture kiểm tra không nuốt identity/poison của address arithmetic.

### CollapseHeapProvenPointerResolvers

Rule này nhận một mạng select range-dispatch của static-image globals chỉ khi:

1. metadata brighten.guest.range của từng global có đúng hai constant và Begin < End;
2. predicate là exact unsigned range condition dạng icmp ult (addr - Begin), End-Begin;
3. arms không overlap;
4. fallback truy về allocation mới có provenance, noalias/non-null (hoặc null
   được chứng minh rơi đúng fallback), root không có forbidden use;
5. address không có tag/comparison observation.

Nếu fallback là heap object, nó không thể đồng thời là global static-image arm,
nên select range chain có thể collapse về heap plus index. Replacement là GEP
không inbounds. Code giữ integer index qua sub; điều này giữ poison của add/sub
flagged và bit modulo, còn inbounds sẽ thêm claim bounds/lifetime mà original
không có. test_heap_proven_resolver_collapse.ll là acceptance test;
test_heap_proven_resolver_lifecycle.ll kiểm tra output không phá lifecycle/
provenance.

## 6. Cách đọc kết quả/test

Report JSON có số object analyzed/reconstructed, structs/arrays, globals/
allocas retyped, GEP rewritten và từng nhóm reject. Khi đánh giá một thay đổi,
không chỉ nhìn GEPsRewritten: hãy đối chiếu một positive fixture với một
negative fixture cho cùng rule. Positive chứng minh matcher có hiệu lực;
negative chứng minh nó không đổi nghĩa integer address, object size, atomic
ordering hay ABI storage khi thiếu proof.

