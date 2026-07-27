; A bounded activation slot is written before its only read on every path.
; CHECK: @frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer
; CHECK-NOT: %native_stack = alloca
; CHECK: call void @llvm.memset.p0.i64
; CHECK: load i32

target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define internal i64 @worker.native(i64 %arg_RDI) {
entry:
  %rsp.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2312
  %rsp = load i64, ptr %rsp.ptr, align 8
  %result = add i64 %rsp, %arg_RDI
  ret i64 %result
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %native_stack = alloca [1048576 x i8], align 16
  %base = getelementptr inbounds [1048576 x i8], ptr %native_stack, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %base, i8 0, i64 1048576, i1 false)
  %slot = getelementptr inbounds i8, ptr %base, i64 64
  store i32 42, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  %native.call = call i64 @worker.native(i64 0)
  %native = trunc i64 %native.call to i32
  %result = add i32 %native, %value
  ret i32 %result
}
