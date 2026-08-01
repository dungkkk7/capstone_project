; RBP is callee-saved and remains the caller's frame anchor after a recovered
; helper call. Native State-SSA must carry it across the call explicitly;
; otherwise post-call RBP-relative locals can be rebased on transient RSP.

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

define internal i64 @callee.native() {
entry:
  %rbp.slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2328
  %rbp = load i64, ptr %rbp.slot, align 8
  ; Model a lifted epilogue restore whose synthetic stack load is not a
  ; trustworthy replacement for the proven incoming callee-saved value.
  store i64 0, ptr %rbp.slot, align 8
  ret i64 %rbp
}

define internal i64 @caller.native() {
entry:
  %rbp.slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2328
  store i64 4096, ptr %rbp.slot, align 8
  %ignored = call i64 @callee.native()
  %preserved = load i64, ptr %rbp.slot, align 8
  ret i64 %preserved
}

define i32 @main() {
entry:
  %result = call i64 @caller.native()
  %ret = trunc i64 %result to i32
  ret i32 %ret
}
