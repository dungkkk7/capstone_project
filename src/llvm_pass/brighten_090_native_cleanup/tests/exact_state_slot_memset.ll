; An exact zero memset of an already typed State slot is a whole-slot store and
; may cross the native State-SSA boundary as an explicit zero output.

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1 immarg)

define internal i128 @worker.native() {
entry:
  %slot = getelementptr i8, ptr @__mcsema_reg_state, i64 16
  %old = load i128, ptr %slot, align 16
  call void @llvm.memset.p0.i64(ptr %slot, i8 0, i64 16, i1 false)
  ret i128 %old
}

define i32 @main() {
entry:
  %value = call i128 @worker.native()
  %result = trunc i128 %value to i32
  ret i32 %result
}
