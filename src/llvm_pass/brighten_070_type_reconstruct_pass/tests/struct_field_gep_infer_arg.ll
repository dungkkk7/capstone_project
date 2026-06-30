; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

%struct.SegmentList = type { ptr, i32, i32 }
@segment_list_anchor = external global %struct.SegmentList

define void @recover_struct_field_from_arg(ptr %list, ptr %data) {
entry:
  store ptr %data, ptr %list, align 8
  %count.ptr = getelementptr i8, ptr %list, i64 8
  store i32 7, ptr %count.ptr, align 4
  %cap.ptr = getelementptr i8, ptr %list, i64 12
  store i32 64, ptr %cap.ptr, align 4
  ret void
}

; CHECK-LABEL: define void @recover_struct_field_from_arg
; CHECK: %[[FIELD0:[^ ]+]] = getelementptr {{.*}}%struct.SegmentList, ptr %list, i32 0, i32 0
; CHECK: store ptr %data, ptr %[[FIELD0]], align 8
; CHECK: %[[COUNT:[^ ]+]] = getelementptr {{.*}}%struct.SegmentList, ptr %list, i32 0, i32 1
; CHECK: store i32 7, ptr %[[COUNT]], align 4
; CHECK: %[[CAP:[^ ]+]] = getelementptr {{.*}}%struct.SegmentList, ptr %list, i32 0, i32 2
; CHECK: store i32 64, ptr %[[CAP]], align 4
; CHECK-NOT: getelementptr i8, ptr %list, i64 8
; CHECK-NOT: getelementptr i8, ptr %list, i64 12
