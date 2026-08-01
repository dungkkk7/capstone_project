; RUN: opt-21 -load-pass-plugin=%plugin \
; RUN:   -passes='brighten-native-cleanup-post-frame-pass,verify' -S %s | FileCheck-21 %s

; A finite pointer PHI selects two disjoint eight-byte locals.  Neither store
; dominates the merge load, so ordinary forwarding cannot erase the memory;
; the frame splitter must recover two typed objects instead.
define i64 @finite_disjoint_slots(i1 %choose, i64 %value) {
entry:
  %frame_storage = alloca [8192 x i8], align 16
  %left = getelementptr i8, ptr %frame_storage, i64 4096
  %right = getelementptr i8, ptr %frame_storage, i64 4128
  br i1 %choose, label %left.path, label %right.path

left.path:
  store i64 %value, ptr %left, align 8
  br label %merge

right.path:
  store i64 %value, ptr %right, align 8
  br label %merge

merge:
  %slot = phi ptr [ %left, %left.path ], [ %right, %right.path ]
  %result = load i64, ptr %slot, align 8
  ret i64 %result
}

; CHECK-LABEL: define i64 @finite_disjoint_slots(
; CHECK-NOT: alloca [8192 x i8]
; CHECK-DAG: %native.slot.4096 = alloca i64, align 8
; CHECK-DAG: %native.slot.4128 = alloca i64, align 8
; CHECK: %native.slot.pointer = phi ptr [ %native.slot.4096, %left.path ], [ %native.slot.4128, %right.path ]
; CHECK: %result = load i64, ptr %native.slot.pointer, align 8

; These accesses overlap without naming the same byte interval.  Splitting
; them would change aliasing and must therefore refuse the complete frame.
define i64 @partial_overlap_refused(i64 %value) {
entry:
  %frame_storage = alloca [8192 x i8], align 16
  %wide = getelementptr i8, ptr %frame_storage, i64 4096
  %overlap = getelementptr i8, ptr %frame_storage, i64 4100
  store i64 %value, ptr %wide, align 8
  %result = load i64, ptr %overlap, align 4
  ret i64 %result
}

; CHECK-LABEL: define i64 @partial_overlap_refused(
; CHECK: %frame_storage = alloca [8192 x i8], align 16
; CHECK: store i64 %value, ptr %wide, align 8
; CHECK: %result = load i64, ptr %overlap, align 4

; An unbounded index has no finite storage partition proof.
define i64 @unbounded_index_refused(i1 %choose, i64 %index, i64 %value) {
entry:
  %frame_storage = alloca [8192 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 %index
  br i1 %choose, label %left, label %right

left:
  store i64 %value, ptr %slot, align 1
  br label %merge

right:
  store i64 0, ptr %slot, align 1
  br label %merge

merge:
  %result = load i64, ptr %slot, align 1
  ret i64 %result
}

; CHECK-LABEL: define i64 @unbounded_index_refused(
; CHECK: %frame_storage = alloca [8192 x i8], align 16
; CHECK: %slot = getelementptr i8, ptr %frame_storage, i64 %index

declare void @observe(ptr)

; A frame address that escapes to a call remains one object.
define void @escaped_frame_refused() {
entry:
  %frame_storage = alloca [8192 x i8], align 16
  call void @observe(ptr %frame_storage)
  ret void
}

; CHECK-LABEL: define void @escaped_frame_refused(
; CHECK: %frame_storage = alloca [8192 x i8], align 16
; CHECK: call void @observe(ptr %frame_storage)
