; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@seg_rodata = internal constant [5 x i8] c"hello"

declare i32 @puts(ptr)

define i32 @use_non_string_data() {
entry:
  %p = getelementptr [5 x i8], ptr @seg_rodata, i64 0, i64 0
  %r = call i32 @puts(ptr %p)
  ret i32 %r
}

; CHECK-NOT: @.str.recovered
; CHECK: @seg_rodata = internal constant [5 x i8] c"hello"
; CHECK-LABEL: define i32 @use_non_string_data
; CHECK: %p = getelementptr [5 x i8], ptr @seg_rodata, i64 0, i64 0
; CHECK: call i32 @puts(ptr %p)
