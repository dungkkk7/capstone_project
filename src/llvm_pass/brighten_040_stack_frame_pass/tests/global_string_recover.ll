; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@seg_rodata = internal constant [13 x i8] c"xxhello\00tail\00"

declare i32 @puts(ptr)

define i32 @use_recovered_string() {
entry:
  %p = getelementptr [13 x i8], ptr @seg_rodata, i64 0, i64 2
  %r = call i32 @puts(ptr %p)
  ret i32 %r
}

; CHECK: @.str.recovered = private unnamed_addr constant [6 x i8] c"hello\00"
; CHECK-LABEL: define i32 @use_recovered_string
; CHECK: call i32 @puts(ptr @.str.recovered)
; CHECK-NOT: @seg_rodata
