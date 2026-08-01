@__mcsema_reg_state = internal global [4096 x i8] zeroinitializer

define internal i32 @worker.native(ptr %state, i64 %state_in_2312) {
entry:
  %slot = inttoptr i64 %state_in_2312 to ptr
  store i32 7, ptr %slot, align 4
  ret i32 7
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %a = call i32 @worker.native(ptr @__mcsema_reg_state, i64 0)
  %b = call i32 @worker.native(ptr @__mcsema_reg_state, i64 0)
  %sum = add i32 %a, %b
  ret i32 %sum
}
