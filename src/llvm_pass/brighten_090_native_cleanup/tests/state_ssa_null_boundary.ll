; ABI recovery may leave null in the obsolete hidden State argument while the
; canonical State global still owns the entry values.  Native State lowering
; must use that global, never form GEP(null, state_offset).
target triple = "x86_64-pc-linux-gnu"

@__mcsema_reg_state = global [3376 x i8] zeroinitializer, align 16

; Lifted callback exports can survive with external linkage even after their
; dispatch table is gone.  An unreferenced generated callback must not keep
; the otherwise function-local State object alive.
define void @callback_sub_100() {
entry:
  %slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  store i64 99, ptr %slot, align 8
  ret void
}

define internal i64 @sub_200.native(ptr %state) {
entry:
  %slot = getelementptr i8, ptr %state, i64 2216
  %old = load i64, ptr %slot, align 8
  %next = add i64 %old, 7
  store i64 %next, ptr %slot, align 8
  ret i64 %next
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %ret = call i64 @sub_200.native(ptr null)
  %out = trunc i64 %ret to i32
  ret i32 %out
}
