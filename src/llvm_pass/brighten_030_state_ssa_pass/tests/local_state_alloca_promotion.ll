; RUN: opt -load-pass-plugin %plugin -passes='brighten-state-ssa-pass,brighten-state-ssa-pass,verify' -S %s | FileCheck %s

%struct.State = type { [64 x i8] }

declare void @observe(ptr)

define i64 @promote_non_escaping() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %slot = getelementptr i8, ptr %state, i64 16
  store i64 7, ptr %slot, align 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @promote_non_escaping()
; CHECK-NOT: alloca %struct.State
; CHECK-NOT: getelementptr i8
; CHECK: ret i64 7

define i64 @reject_escape() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  call void @observe(ptr %state)
  %slot = getelementptr i8, ptr %state, i64 16
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @reject_escape()
; CHECK: %state = alloca %struct.State
; CHECK: call void @observe(ptr %state)

define i64 @reject_overlap() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %wide = getelementptr i8, ptr %state, i64 8
  %narrow = getelementptr i8, ptr %state, i64 12
  store i64 9, ptr %wide, align 8
  store i32 3, ptr %narrow, align 4
  %value = load i64, ptr %wide, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @reject_overlap()
; CHECK: %state = alloca %struct.State
; CHECK: store i64 9
; CHECK: store i32 3
