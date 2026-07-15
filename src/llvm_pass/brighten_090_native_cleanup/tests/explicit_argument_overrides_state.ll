; A recovered explicit register argument and the canonical State snapshot may
; both describe the same register.  The explicit ABI value is authoritative at
; function entry and must be seeded after the synthetic state_in stores.

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

define internal i64 @worker.native(i64 %arg_RSI) {
entry:
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  %rsi = load i64, ptr %rsi.ptr, align 8
  %result = add i64 %rsi, %arg_RSI
  ret i64 %result
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %result = call i64 @worker.native(i64 7)
  %ret = trunc i64 %result to i32
  ret i32 %ret
}
