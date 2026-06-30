; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

%struct.Segment = type { i32, i32, i32 }

define i32 @recover_field_zero_load(ptr %base, i64 %idx) {
entry:
  %elt = getelementptr %struct.Segment, ptr %base, i64 %idx
  %val = load i32, ptr %elt, align 4
  ret i32 %val
}

define void @recover_field_zero_store(ptr %base, i64 %idx, i32 %v) {
entry:
  %elt = getelementptr %struct.Segment, ptr %base, i64 %idx
  store i32 %v, ptr %elt, align 4
  ret void
}

; CHECK-LABEL: define i32 @recover_field_zero_load
; CHECK: %elt = getelementptr %struct.Segment, ptr %base, i64 %idx
; CHECK: %[[FIELD:[^ ]+]] = getelementptr {{.*}}%struct.Segment, ptr %elt, i32 0, i32 0
; CHECK: load i32, ptr %[[FIELD]], align 4

; CHECK-LABEL: define void @recover_field_zero_store
; CHECK: %elt = getelementptr %struct.Segment, ptr %base, i64 %idx
; CHECK: %[[FIELD2:[^ ]+]] = getelementptr {{.*}}%struct.Segment, ptr %elt, i32 0, i32 0
; CHECK: store i32 %v, ptr %[[FIELD2]], align 4
