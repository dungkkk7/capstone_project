; An entry stack whose address escapes to integer guest arithmetic has no
; proven finite access range.  Moving it to a global can mask faults beyond
; the original host-stack mapping, even when the LLVM array sizes match.
target triple = "x86_64-pc-linux-gnu"

@recovered_data = internal global [16 x i8] zeroinitializer,
    !brighten.guest.range !0

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define internal i8 @worker.native(ptr %state) {
entry:
  %rsp.slot = getelementptr i8, ptr %state, i64 2312
  %rsp = load i64, ptr %rsp.slot, align 8
  %address = add i64 %rsp, -1
  %pointer = inttoptr i64 %address to ptr
  %value = load volatile i8, ptr %pointer, align 1
  ret i8 %value
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %state = alloca [3376 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 3376, i1 false)
  %native_stack_storage = alloca [2097152 x i8], align 16
  %native_stack_top = getelementptr i8, ptr %native_stack_storage, i64 2096896
  %native_stack_integer = ptrtoint ptr %native_stack_top to i64
  %rsp.slot = getelementptr i8, ptr %state, i64 2312
  store i64 %native_stack_integer, ptr %rsp.slot, align 8
  %value = call i8 @worker.native(ptr %state)
  %result = zext i8 %value to i32
  ret i32 %result
}

!0 = !{i64 4194304, i64 4194320}
