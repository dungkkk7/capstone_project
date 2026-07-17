@g_arr_0 = internal global [4 x i8] zeroinitializer, align 1

define i8 @main(i64 %index) {
entry:
  %address = getelementptr i8, ptr @g_arr_0, i64 %index
  %value = load i8, ptr %address, align 1
  ret i8 %value
}
