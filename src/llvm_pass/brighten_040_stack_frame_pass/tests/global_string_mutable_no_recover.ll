; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@seg_data = internal global [6 x i8] c"edit\00\00"

declare i32 @puts(ptr)

define i32 @use_mutable_data() {
entry:
  %p = getelementptr [6 x i8], ptr @seg_data, i64 0, i64 0
  store i8 88, ptr %p, align 1
  %r = call i32 @puts(ptr %p)
  ret i32 %r
}

; CHECK-NOT: @.str.recovered
; CHECK: @seg_data = internal global [6 x i8] c"edit\00\00"
; CHECK-LABEL: define i32 @use_mutable_data
; CHECK: store i8 88, ptr %p
; CHECK: call i32 @puts(ptr %p)
