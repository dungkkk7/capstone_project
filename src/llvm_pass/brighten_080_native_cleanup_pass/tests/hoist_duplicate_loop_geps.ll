; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

%struct.SegmentList = type { ptr, i32, i32 }

define void @hoist_duplicate_loop_geps(ptr %base, i1 %pick_lhs, i1 %again) {
entry:
  br label %hdr

hdr:
  br i1 %pick_lhs, label %lhs, label %rhs

lhs:
  %lhs.gep = getelementptr %struct.SegmentList, ptr %base, i32 0, i32 1
  store i32 1, ptr %lhs.gep, align 4
  br label %latch

rhs:
  %rhs.gep = getelementptr %struct.SegmentList, ptr %base, i32 0, i32 1
  store i32 2, ptr %rhs.gep, align 4
  br label %latch

latch:
  br i1 %again, label %hdr, label %exit

exit:
  ret void
}

; CHECK-LABEL: define void @hoist_duplicate_loop_geps
; CHECK: entry:
; CHECK: %[[GEP:[^ ]+]] = getelementptr {{.*}}%struct.SegmentList, ptr %base, i32 0, i32 1
; CHECK: br label %hdr
; CHECK: lhs:
; CHECK-NOT: getelementptr
; CHECK: store i32 1, ptr %[[GEP]], align 4
; CHECK: rhs:
; CHECK-NOT: getelementptr
; CHECK: store i32 2, ptr %[[GEP]], align 4
