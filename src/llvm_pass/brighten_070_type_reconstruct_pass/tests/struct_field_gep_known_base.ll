; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

%struct.Process = type { i32, i32, i32 }

define i32 @recover_struct_field_from_known_base(ptr %base, i64 %idx) {
entry:
  %elt = getelementptr %struct.Process, ptr %base, i64 %idx
  %field.ptr = getelementptr i8, ptr %elt, i64 8
  %val = load i32, ptr %field.ptr, align 4
  ret i32 %val
}

; CHECK-LABEL: define i32 @recover_struct_field_from_known_base
; CHECK: %elt = getelementptr %struct.Process, ptr %base, i64 %idx
; CHECK: %[[FIELD:[^ ]+]] = getelementptr {{.*}}%struct.Process, ptr %elt, i32 0, i32 2
; CHECK: load i32, ptr %[[FIELD]], align 4
; CHECK-NOT: getelementptr i8, ptr %elt, i64 8
