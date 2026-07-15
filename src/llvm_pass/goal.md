
   Nếu muốn triệt tiêu hoàn toàn mọi dấu vết lifted/non-native, tiêu chuẩn phải áp dụng toàn module, không chỉ reachable call graph.

  # Definition of Done: Fully Native LLVM IR

  ## 1. Không còn CPU State

  [ ] Không còn %struct.State hoặc architecture State tương đương
  [ ] Không còn @__mcsema_reg_state
  [ ] Không còn alias RAX_*, RSP_*, RIP_*, ZF_*, CF_*, ...
  [ ] Không còn load/store register thông qua offset của State
  [ ] Không còn truyền ptr %state giữa các hàm

  Register phải được chuyển thành:

  - LLVM SSA values.
  - Function arguments.
  - Function return values.
  - Local variables khi thật sự cần địa chỉ.

  ———

  ## 2. Không còn lifted function ABI

  Cấm dạng:

  define ptr @sub_x(ptr %state, i64 %pc, ptr %memory)

  Yêu cầu:

  [ ] Không còn tham số State
  [ ] Không còn tham số guest PC
  [ ] Không còn Remill Memory token
  [ ] Arguments được infer đúng type và calling convention
  [ ] Return registers được chuyển thành LLVM return value
  [ ] Multi-register return được chuyển thành struct hoặc sret đúng ABI
  [ ] Tất cả callsite được rewrite sang signature mới

  Ví dụ cuối:

  define i32 @calculate(i32 %x, ptr %buffer)


  ———

  ## 3. Không còn Remill runtime

  Toàn module không còn:

  __remill_function_call
  __remill_function_return
  __remill_jump
  __remill_missing_block
  __remill_error
  __remill_sync_hyper_call
  __remill_async_hyper_call
  __remill_atomic_begin
  __remill_atomic_end
  __remill_barrier_*
  __remill_delay_slot_*
  __remill_fpu_*

  Yêu cầu:

  [ ] Direct guest targets thành direct LLVM calls/branches
  [ ] Return thành ret
  [ ] Barrier thành LLVM fence/atomic operation nếu cần
  [ ] Hypercall thành native syscall/libc call nếu đó là semantics gốc
  [ ] Xóa definition, declaration và metadata Remill

  LLVM intrinsic như llvm.ctpop, llvm.memcpy, llvm.bswap vẫn là native và được phép giữ.

  ———

  ## 4. Không còn McSema artifacts

  Toàn module không còn:

  __mcsema_*
  main_wrapper
  start_wrapper
  callback_*_wrapper
  ext_ADDR_*
  *.native và lifted duplicate cùng tồn tại

  Yêu cầu:

  [ ] Không còn __mcsema_attach_call
  [ ] Không còn __mcsema_early_init
  [ ] Không còn callback trampoline do McSema sinh
  [ ] Không còn wrapper chuyển State ABI
  [ ] Không còn lifted function cũ sau khi native clone hoàn tất
  [ ] Không còn !remill.* metadata

  Tên .native có thể rename lại thành tên canonical sau khi xóa hàm lifted cũ.

  ———


  ## 5. Không còn guest control-flow model

  [ ] Không còn dispatch theo guest PC
  [ ] Không còn store/load RIP để điều khiển CFG
  [ ] Không còn switch ánh xạ PC sang sub_ADDR
  [ ] Không còn indirect jump do lifter tạo
  [ ] Không còn missing-block fallback
  [ ] Function call và return có LLVM CFG bình thường

  Indirect call hoặc switch của chương trình gốc vẫn được phép giữ. Chỉ cấm loại sinh ra để mô phỏng PC.

  ———

  ## 6. Không còn guest memory model

  Toàn module không còn:

  __translate_guest_pointer
  guest_memory
  memory token
  guest address map

  Yêu cầu:

  [ ] Stack address thành alloca/GEP
  [ ] Global address thành global/GEP
  [ ] Heap address là native pointer trả về từ malloc/new
  [ ] Function address thành LLVM function pointer
  [ ] Không còn inttoptr từ guest virtual address cố định
  [ ] Không còn address-space translation trên normal path

  ptrtoint và inttoptr không tự động là non-native. Chúng chỉ được giữ nếu thực sự thuộc semantics gốc, không phải do lifter mô phỏng địa chỉ.


  ———

  ## 7. Không còn segment/image backing blob

  Toàn module không còn:

  @seg_*
  @data_ADDR
  @*_LOAD_*
  raw ELF header
  nguyên .text/.rodata/.data dưới dạng byte blob

  Yêu cầu:

  [ ] String thành LLVM string global
  [ ] Scalar thành typed global
  [ ] Array thành typed array
  [ ] Struct thành typed object nếu đủ evidence
  [ ] Pointer table chứa LLVM pointers
  [ ] Jump table thành switch/blockaddress/table native
  [ ] BSS thành zeroinitializer global
  [ ] Relocation thành pointer/reference thực
  [ ] Init/fini array thành llvm.global_ctors hoặc llvm.global_dtors
  [ ] Xóa tất cả @data_ADDR aliases
  [ ] GlobalDCE xóa toàn bộ segment backing storage

  Byte array vẫn được phép nếu nó thực sự là object của chương trình, ví dụ compressed data hoặc lookup table. Không được giữ nguyên ELF load segment.

  ———

  ## 8. Stack hoàn toàn native

  [ ] Không còn guest RSP/RBP arithmetic
  [ ] Không còn guest stack global
  [ ] Không còn @__lifter_guest_stack
  [ ] Local scalar thành SSA hoặc alloca
  [ ] Local array thành alloca array
  [ ] Escaped stack object có lifetime đúng
  [ ] Stack arguments được rewrite sang function arguments
  [ ] Dynamic alloca được xử lý đúng
  [ ] Alignment và lifetime đúng

  Không được khởi tạo fake RSP vào một buffer 8 MB.


  ———

  ## 9. External calls hoàn toàn native

  [ ] Không còn ext_ADDR_name wrapper
  [ ] Call trực tiếp printf/scanf/malloc/free/exit/...
  [ ] Fixed arguments đúng type
  [ ] Varargs đúng integer/FP promotion
  [ ] Return type đúng width và signedness
  [ ] noreturn đúng
  [ ] Callback có đúng native signature
  [ ] Calling convention đúng target ABI
  [ ] Không còn truyền State hoặc Memory vào external call

  External declarations như printf, malloc, free là native và được phép giữ.

  ———

  ## 10. Entrypoint hoàn toàn native

  [ ] Chỉ còn một entrypoint thực
  [ ] main dùng default C calling convention
  [ ] main nhận argc/argv hoặc argc/argv/envp hợp lệ
  [ ] Không còn inline-asm trampoline
  [ ] Không còn main_wrapper/start_wrapper
  [ ] Không còn fake guest stack initialization
  [ ] Constructor/destructor dùng LLVM-native mechanism

  Native cleanup chuẩn hoá entrypoint của pipeline này về `main(i32, ptr)`;
  nếu một target thực sự cần `envp`, entrypoint `main(i32, ptr, ptr)` cũng
  hợp lệ nhưng phải là ABI native trực tiếp, không phải hidden State arg.

  ———

  ## 11. Không còn undefined lifted semantics

  [ ] Không còn explicit undef
  [ ] Không còn explicit poison trong recovered application code
  [ ] Không còn poison đi vào branch
  [ ] Không còn poison làm memory address
  [ ] Không còn poison truyền vào noundef argument
  [ ] Không còn arbitrary null thay cho function/global chưa resolve
  [ ] Không còn unreachable được dùng để che missing semantics

  Không được sửa bằng regex kiểu thay mọi unknown pointer thành null. Mỗi value phải được recover, chứng minh dead hoặc báo unresolved.

  ——

    ———

  ## 12. Không còn duplicated/dead lifted code

  [ ] Không còn cả sub_x và sub_x.native
  [ ] Không còn unused wrappers
  [ ] Không còn dead Remill runtime
  [ ] Không còn dead McSema globals
  [ ] Không còn dead segment blobs
  [ ] Không còn unused register aliases
  [ ] Không còn lifter-only metadata
  [ ] Không còn function chỉ phục vụ dispatcher đã loại

  Sau khi rewrite hoàn tất mới chạy:

  GlobalDCE
  ADCE
  DeadArgElim
  StripDeadPrototypes

  ———

  # Checklist deobfuscation riêng

  OLLVM code vẫn có thể là native nhưng còn obfuscated. Nếu muốn output vừa native vừa sạch, cần thêm:

  [ ] Không còn FLA dispatcher loop
  [ ] Không còn dispatcher state variable
  [ ] Không còn switch state machine do FLA tạo
  [ ] Không còn opaque predicate
  [ ] Không còn bogus block/edge
  [ ] Không còn clone block do BCF
  [ ] Không còn InstSub/MBA expression có thể canonicalize
  [ ] Không còn dead path sau opaque predicate
  [ ] Loop và branch đã về CFG tự nhiên

  Thứ tự hợp lý:

  InstSub/MBA normalization
  BCF opaque-predicate elimination
  FLA dispatcher reconstruction
  ADCE
  SimplifyCFG
  InstCombine
  LoopSimplify

  ———

  # Những construct vẫn được coi là native

  Không được xóa mù các construct sau:

  %struct.* thông thường
  LLVM switch
  Indirect call thật
  Function pointer thật
  llvm.* intrinsics
  LLVM atomic/fence
  Native TLS
  Native inline asm thực sự cần thiết
  Typed byte array của chương trình
  External libc declarations

  Phải phân biệt construct của chương trình gốc với construct do McSema/Remill sinh ra.

  # Tiêu chuẩn cuối cùng dạng ngắn

  ZERO State
  ZERO guest PC
  ZERO guest Memory
  ZERO Remill
  ZERO McSema
  ZERO lifted ABI
  ZERO guest stack
  ZERO guest address translation
  ZERO segment blob
  ZERO data_ADDR alias
  ZERO external wrapper
  ZERO lifted/native duplicate
  ZERO unresolved indirect target do lifter
  ZERO poison/undef ảnh hưởng semantics
  ZERO OLLVM dispatcher/opaque predicate/MBA nếu yêu cầu deobfuscate

  Chỉ khi toàn bộ danh sách này đạt, module mới có thể gọi là fully native, runtime-free, deobfuscated LLVM IR

  # Implementation gates

  Pipeline production chạy cleanup LLVM trước pass cuối:

  ```text
  ... simplifycfg,gvn,dce,globaldce,brighten-native-cleanup-pass
  ```

  `brighten-native-cleanup-pass` có hai chế độ. Chế độ mặc định chỉ dọn các
  artifact đã chứng minh là dead và in báo cáo toàn module. Chế độ chứng nhận
  dùng `-brighten-native-strict`; nếu còn State, lifted ABI, Remill/McSema,
  guest address artifact, segment/data alias, metadata, hoặc undef/poison thì
  `opt` thất bại. Python driver bật chế độ này bằng:

  ```bash
  BRIGHTEN_NATIVE_STRICT=1 python3 -m llvm_pass.britening_ir -i input.bc -o output.bc
  ```

  Không được dùng textual regex hậu kỳ để thay pointer bằng `null`, xóa hàm
  có inline asm, hoặc chèn fake guest stack/entrypoint. Mọi rewrite native
  phải được thực hiện bởi LLVM IR pass và phải giữ được verifier/semantic
  evidence tương ứng.
