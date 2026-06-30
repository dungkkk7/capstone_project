; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

%struct.Segment = type { i32, i32, i32 }

define i32 @recover_struct_field_from_phi_base(ptr %base, i64 %idx, i1 %cond) {
entry:
  %elt = getelementptr %struct.Segment, ptr %base, i64 %idx
  br i1 %cond, label %lhs, label %rhs

lhs:
  br label %join

rhs:
  br label %join

join:
  %p0 = phi ptr [ %elt, %lhs ], [ undef, %rhs ]
  %field.ptr = getelementptr i8, ptr %p0, i64 8
  %val = load i32, ptr %field.ptr, align 4
  ret i32 %val
}

; CHECK-LABEL: define i32 @recover_struct_field_from_phi_base
; CHECK: %[[FIELD:[^ ]+]] = getelementptr {{.*}}%struct.Segment, ptr %p0, i32 0, i32 2
; CHECK: load i32, ptr %[[FIELD]], align 4
; CHECK-NOT: getelementptr i8, ptr %p0, i64 8
