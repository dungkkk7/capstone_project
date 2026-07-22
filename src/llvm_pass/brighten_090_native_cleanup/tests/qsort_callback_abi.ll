%State = type [2400 x i8]

@__mcsema_reg_state = thread_local global %State zeroinitializer

declare x86_64_sysvcc i64 @qsort(i64, i64, i64, i64)

define internal void @callback_sub_test() {
entry:
  store i32 7, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2216)
  ret void
}

define i32 @main() {
entry:
  %result = call x86_64_sysvcc i64 @qsort(
      i64 0, i64 0, i64 16,
      i64 ptrtoint (ptr @callback_sub_test to i64))
  %result.again = call x86_64_sysvcc i64 @qsort(
      i64 0, i64 0, i64 16,
      i64 ptrtoint (ptr @callback_sub_test to i64))
  ret i32 0
}
