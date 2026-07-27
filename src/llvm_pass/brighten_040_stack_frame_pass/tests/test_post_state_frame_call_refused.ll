; Neither nocapture alone nor an unannotated vararg destination proves that
; changing global pointer identity to a local alloca preserves call semantics.
@nocapture_backing = internal global [16 x i8] zeroinitializer, align 8,
  !brighten.stack.ensured !0
@unknown_backing = internal global [16 x i8] zeroinitializer, align 8,
  !brighten.stack.ensured !0

declare void @may_observe_identity(ptr nocapture)
declare i32 @unknown_vararg(...)

define void @nocapture_only() {
entry:
  %slot = getelementptr i8, ptr @nocapture_backing, i64 4
  store i32 7, ptr %slot, align 4
  call void @may_observe_identity(ptr %slot)
  ret void
}

define i32 @unknown_vararg_call() {
entry:
  %slot = getelementptr i8, ptr @unknown_backing, i64 4
  store i32 7, ptr %slot, align 4
  %r = call i32 (...) @unknown_vararg(ptr %slot)
  ret i32 %r
}

!0 = !{}
