; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-global-data-pass -S %s | FileCheck-21 %s

@seg_data = internal global [8 x i8] c"mutable\00"

declare i32 @puts(ptr)

define i32 @keep_mutable() {
entry:
  %p = getelementptr [8 x i8], ptr @seg_data, i64 0, i64 0
  %r = call i32 @puts(ptr %p)
  ret i32 %r
}

; CHECK-LABEL: define i32 @keep_mutable
; CHECK: %p = getelementptr [8 x i8], ptr @seg_data, i64 0, i64 0
; CHECK-NOT: @.str.recovered
