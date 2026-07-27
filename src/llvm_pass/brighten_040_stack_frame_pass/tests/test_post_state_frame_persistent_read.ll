; A zeroinitialized internal global is process-lifetime state.  The first load
; may observe a previous invocation (or recursive activation), so this is not
; equivalent to a fresh local frame with an entry reset.
@backing = internal global [16 x i8] zeroinitializer, align 8,
  !brighten.stack.ensured !0

define i32 @accumulate() {
entry:
  %slot = getelementptr i8, ptr @backing, i64 4
  %old = load i32, ptr %slot, align 4
  %next = add i32 %old, 1
  store i32 %next, ptr %slot, align 4
  ret i32 %next
}

define i32 @run_twice() {
entry:
  %first = call i32 @accumulate()
  %second = call i32 @accumulate()
  %sum = add i32 %first, %second
  ret i32 %sum
}

!0 = !{}
