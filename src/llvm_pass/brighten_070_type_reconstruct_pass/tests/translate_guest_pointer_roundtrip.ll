; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

@.str = private unnamed_addr constant [6 x i8] c"hello\00", align 1

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @test() {
entry:
  %p = call ptr @__translate_guest_pointer(i64 ptrtoint (ptr @.str to i64), i1 true)
  ret ptr %p
}

; CHECK-LABEL: define ptr @test() {
; CHECK-NOT: call ptr @__translate_guest_pointer
; CHECK: ret ptr @.str
