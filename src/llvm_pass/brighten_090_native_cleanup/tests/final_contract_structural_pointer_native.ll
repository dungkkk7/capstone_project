; Native pointer selection and typed address arithmetic are not guest-address
; range dispatch or integerized mapper reconstruction.
target triple = "x86_64-pc-linux-gnu"

declare ptr @malloc(i64)
declare void @free(ptr)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %left = call ptr @malloc(i64 32)
  %right = call ptr @malloc(i64 32)
  %choose.left = icmp sgt i32 %argc, 1
  %chosen = select i1 %choose.left, ptr %left, ptr %right
  %element = getelementptr i32, ptr %chosen, i64 3
  store i32 %argc, ptr %element, align 4
  %value = load i32, ptr %element, align 4
  call void @free(ptr %right)
  call void @free(ptr %left)
  ret i32 %value
}
