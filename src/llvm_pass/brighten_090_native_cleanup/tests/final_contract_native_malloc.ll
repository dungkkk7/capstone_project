; Direct native heap pointers and typed GEPs satisfy the final contract.
target triple = "x86_64-pc-linux-gnu"

declare ptr @malloc(i64)
declare void @free(ptr)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %storage = call ptr @malloc(i64 16)
  %element = getelementptr i32, ptr %storage, i64 2
  store i32 %argc, ptr %element, align 4
  %value = load i32, ptr %element, align 4
  call void @free(ptr %storage)
  ret i32 %value
}
