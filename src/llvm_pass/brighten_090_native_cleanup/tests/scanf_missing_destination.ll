@format = private unnamed_addr constant [15 x i8] c"%d %d %d %d %d\00"

declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  %c = alloca i32, align 4
  %r = call i32 (ptr, ...) @scanf(ptr @format, ptr %a, ptr %b, ptr %c)
  ret i32 %r
}
