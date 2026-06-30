; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@seg_rodata = internal constant [12 x i8] c"xxworld\00pad\00"

declare i32 @puts(ptr)

define i32 @use_constexpr_string() {
entry:
  %r = call i32 @puts(ptr getelementptr ([12 x i8], ptr @seg_rodata, i64 0, i64 2))
  ret i32 %r
}

; CHECK: @.str.recovered = private unnamed_addr constant [6 x i8] c"world\00"
; CHECK-LABEL: define i32 @use_constexpr_string
; CHECK: call i32 @puts(ptr @.str.recovered)
; CHECK-NOT: @seg_rodata
