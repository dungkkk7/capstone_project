; A recovered CALL decrements RSP before entering the callee; RET restores it
; by eight.  RSP must therefore be a native State-SSA output.  The pointer
; view of the same State slot must carry the stored bits, not the slot address.

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer
@RSP_pointer_view = internal alias ptr, getelementptr inbounds
    ([3376 x i8], ptr @__mcsema_reg_state, i32 0, i32 2312)

define internal i64 @callee.native() {
entry:
  %rsp.slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2312
  %rsp = load i64, ptr %rsp.slot, align 8
  %after.ret = add i64 %rsp, 8
  store i64 %after.ret, ptr %rsp.slot, align 8
  ret i64 %after.ret
}

define internal i64 @caller.native() {
entry:
  %rsp.slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2312
  %rsp = load i64, ptr %rsp.slot, align 8
  %after.push = sub i64 %rsp, 8
  store i64 %after.push, ptr %rsp.slot, align 8
  %ignored = call i64 @callee.native()
  %restored.pointer = load ptr, ptr @RSP_pointer_view, align 8
  %restored = ptrtoint ptr %restored.pointer to i64
  ret i64 %restored
}

define i32 @main() {
entry:
  %result = call i64 @caller.native()
  %ret = trunc i64 %result to i32
  ret i32 %ret
}
