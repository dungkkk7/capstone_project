@__mcsema_reg_state = internal global [4096 x i8] zeroinitializer

declare void @retain_entry_address(ptr)

define internal i32 @worker.native(ptr %state, i64 %state_in_2312) {
entry:
  %slot = inttoptr i64 %state_in_2312 to ptr
  store i32 7, ptr %slot, align 4
  ret i32 7
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  call void @retain_entry_address(ptr @main)
  %value = call i32 @worker.native(ptr @__mcsema_reg_state, i64 0)
  ret i32 %value
}
