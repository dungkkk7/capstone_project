; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

%struct.Inner = type { i32, [80 x i8], i32, i64, i64 }
%struct.Outer = type { i32, [80 x i8], [30 x i8], [4 x %struct.Inner] }

declare ptr @strcpy(ptr, ptr)

define void @recover_nested_inner_fields(ptr %outer, i64 %idx, ptr %src) {
entry:
  %items = getelementptr %struct.Outer, ptr %outer, i32 0, i32 3
  %.base.off = mul nsw i64 %idx, 104
  %item.base = getelementptr i8, ptr %items, i64 %.base.off
  %name.ptr = getelementptr i8, ptr %item.base, i64 4
  %qty.ptr = getelementptr i8, ptr %item.base, i64 84
  %unit.ptr = getelementptr i8, ptr %item.base, i64 88
  %copy = call ptr @strcpy(ptr %name.ptr, ptr %src)
  store i32 7, ptr %qty.ptr, align 4
  store i64 11, ptr %unit.ptr, align 8
  ret void
}

; CHECK-LABEL: define void @recover_nested_inner_fields
; CHECK: %items = getelementptr %struct.Outer, ptr %outer, i32 0, i32 3
; CHECK: %item.base = getelementptr i8, ptr %items, i64 %.base.off
; CHECK: %[[NAME:[^ ]+]] = getelementptr {{.*}}%struct.Inner, ptr %item.base, i32 0, i32 1
; CHECK: %[[QTY:[^ ]+]] = getelementptr {{.*}}%struct.Inner, ptr %item.base, i32 0, i32 2
; CHECK: %[[UNIT:[^ ]+]] = getelementptr {{.*}}%struct.Inner, ptr %item.base, i32 0, i32 3
; CHECK: call ptr @strcpy(ptr %[[NAME]], ptr %src)
; CHECK: store i32 7, ptr %[[QTY]], align 4
; CHECK: store i64 11, ptr %[[UNIT]], align 8
; CHECK-NOT: getelementptr {{.*}}%struct.Outer, ptr %item.base, i32 0, i32 2
