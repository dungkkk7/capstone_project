; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

@blob = internal global [32 x i8] zeroinitializer, align 1

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @test_gep() {
entry:
  %base = getelementptr i8, ptr @blob, i64 0
  %base_i = ptrtoint ptr %base to i64
  %addr = add i64 %base_i, 7
  %p = call ptr @__translate_guest_pointer(i64 %addr, i1 false)
  ret ptr %p
}

; CHECK-LABEL: define ptr @test_gep() {
; CHECK-NOT: call ptr @__translate_guest_pointer
; CHECK: %[[BASE:.*]] = getelementptr i8, ptr @blob, i64 0
; CHECK: %[[REC:.*]] = getelementptr i8, ptr %[[BASE]], i64 7
; CHECK: ret ptr %[[REC]]
