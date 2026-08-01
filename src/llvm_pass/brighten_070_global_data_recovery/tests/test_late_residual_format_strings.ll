; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-late-residual-format-string-recovery,verify -S < %s | FileCheck %s

@residual = internal constant <{ [9 x i8], [1 x i8], [4 x i8] }>
  <{ [9 x i8] c"xx%s\00%d%d", [1 x i8] zeroinitializer, [4 x i8] c"%d\0A\00" }>,
  !brighten.guest.range !0

declare i32 @printf(ptr, ...)
declare i32 @sscanf(ptr, ptr, ...)

define i32 @positive(ptr %input) {
  %a = call i32 (ptr, ...) @printf(ptr getelementptr (<{ [9 x i8], [1 x i8], [4 x i8] }>, ptr @residual, i64 0, i32 0, i64 2))
  %b = call i32 (ptr, ...) @printf(ptr getelementptr (<{ [9 x i8], [1 x i8], [4 x i8] }>, ptr @residual, i64 0, i32 0, i64 2))
  %c = call i32 (ptr, ptr, ...) @sscanf(ptr %input, ptr getelementptr (<{ [9 x i8], [1 x i8], [4 x i8] }>, ptr @residual, i64 0, i32 0, i64 5), ptr null, ptr null)
  %d = call i32 (ptr, ...) @printf(ptr getelementptr (<{ [9 x i8], [1 x i8], [4 x i8] }>, ptr @residual, i64 0, i32 2, i64 0))
  ret i32 %d
}

; CHECK-DAG: @.late.residual.str.0 = private constant [3 x i8] c"%s\00"
; CHECK-DAG: @.late.residual.str.1 = private constant [5 x i8] c"%d%d\00"
; CHECK-DAG: @.late.residual.str.2 = private constant [4 x i8] c"%d\0A\00"
; CHECK-DAG: @residual = internal constant
; CHECK: call i32 (ptr, ...) @printf(ptr @.late.residual.str.0)
; CHECK: call i32 (ptr, ...) @printf(ptr @.late.residual.str.0)
; CHECK: call i32 (ptr, ptr, ...) @sscanf(ptr %input, ptr @.late.residual.str.1, ptr null, ptr null)
; CHECK: call i32 (ptr, ...) @printf(ptr @.late.residual.str.2)

!0 = !{i64 4096, i64 4110}
