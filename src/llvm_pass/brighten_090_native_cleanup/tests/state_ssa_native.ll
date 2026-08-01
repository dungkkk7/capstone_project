; State-pointer ABI fixture: strict mode must accept only after the
; explicit State-slot ABI lowering is enabled.
target triple = "x86_64-pc-linux-gnu"

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define internal i64 @sub_100.native(ptr %state, i64 %arg_RDI) {
entry:
  %slot = getelementptr i8, ptr %state, i64 2216
  %old = load i64, ptr %slot
  %next = add i64 %old, %arg_RDI
  store i64 %next, ptr %slot
  ret i64 %next
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %state = alloca [3376 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 3376, i1 false)
  %ret = call i64 @sub_100.native(ptr %state, i64 7)
  %out = trunc i64 %ret to i32
  ret i32 %out
}
