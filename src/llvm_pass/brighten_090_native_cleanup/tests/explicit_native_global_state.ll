; ABI recovery may remove the hidden State argument before late State-SSA.
; Preserve every explicit ABI argument while converting canonical State-global
; accesses into explicit native slot inputs.

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

define internal i64 @worker.native(i64 %arg_RDI) {
entry:
  %rsp.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2312
  %rsp = load i64, ptr %rsp.ptr, align 8
  %result = add i64 %rsp, %arg_RDI
  ret i64 %result
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %result = call i64 @worker.native(i64 5)
  %ret = trunc i64 %result to i32
  ret i32 %ret
}
