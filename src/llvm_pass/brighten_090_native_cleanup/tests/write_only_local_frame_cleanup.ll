; The post-frame boundary may remove a synthetic byte frame only after every
; real read has a source-level SSA proof.  Mirrored counters, exact aliases,
; finite disjoint addresses, and exact conditional stores are positive cases;
; unbounded clobbers and observable addresses are conservative refusals.

define i32 @mirrored_counter(i32 %limit) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 128
  store i32 0, ptr %slot, align 4
  br label %loop

loop:
  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
  %saved = load i32, ptr %slot, align 4
  %next = add i32 %saved, 1
  store i32 %next, ptr %slot, align 4
  %again = icmp slt i32 %next, %limit
  br i1 %again, label %loop, label %exit

exit:
  ret i32 %next
}

define i32 @exact_aliasing_counter(i32 %limit, i32 %replacement) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 128
  store i32 0, ptr %slot, align 4
  br label %loop

loop:
  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
  %alias = getelementptr i8, ptr %frame_storage, i64 128
  store i32 %replacement, ptr %alias, align 4
  %saved = load i32, ptr %slot, align 4
  %next = add i32 %saved, 1
  store i32 %next, ptr %slot, align 4
  %again = icmp slt i32 %next, %limit
  br i1 %again, label %loop, label %exit

exit:
  ret i32 %next
}

define i64 @observable_frame_address() {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %bits = ptrtoint ptr %frame_storage to i64
  ret i64 %bits
}

define i64 @dominating_scalar_store(i64 %old) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 256
  store i64 %old, ptr %slot, align 8
  store i64 3, ptr %slot, align 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @conditional_exact_slot(i1 %take) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 256
  store i64 3, ptr %slot, align 8
  br i1 %take, label %clobber, label %merge

clobber:
  store i64 4, ptr %slot, align 8
  br label %merge

merge:
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @dynamic_clobber_refused(i64 %offset) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 256
  store i64 3, ptr %slot, align 8
  %dynamic = getelementptr i8, ptr %frame_storage, i64 %offset
  store i64 4, ptr %dynamic, align 1
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @finite_disjoint_dynamic_store(i1 %choose) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 256
  %left = getelementptr i8, ptr %frame_storage, i64 64
  %right = getelementptr i8, ptr %frame_storage, i64 128
  %dynamic = select i1 %choose, ptr %left, ptr %right
  store i64 3, ptr %slot, align 8
  store i64 4, ptr %dynamic, align 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @atomic_pointer_integer_store_observed(ptr %pointer) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 256
  %bits = ptrtoint ptr %pointer to i64
  store i64 %bits, ptr %slot, align 8
  %old = atomicrmw add ptr %slot, i64 1 seq_cst, align 8
  ret i64 %old
}

; CHECK-LABEL: define i32 @mirrored_counter(
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: store
; CHECK: %next = add i32 %index, 1
; CHECK: ret i32 %next
; CHECK-LABEL: define i32 @exact_aliasing_counter(
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: store
; CHECK: %next = add i32 %replacement, 1
; CHECK-LABEL: define i64 @observable_frame_address(
; CHECK: %frame_storage = alloca [4096 x i8]
; CHECK: %bits = ptrtoint ptr %frame_storage to i64
; CHECK: ret i64 %bits
; CHECK-LABEL: define i64 @dominating_scalar_store(
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: store
; CHECK: ret i64 3
; CHECK-LABEL: define i64 @conditional_exact_slot(
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: store
; CHECK: %native.slot.256.0 = phi i64 [ 4, %clobber ], [ 3, %entry ]
; CHECK: ret i64 %native.slot.256.0
; CHECK-LABEL: define i64 @dynamic_clobber_refused(
; CHECK: %frame_storage = alloca [4096 x i8]
; CHECK: store i64 4, ptr %dynamic
; CHECK: %value = load i64, ptr %slot
; CHECK-LABEL: define i64 @finite_disjoint_dynamic_store(
; CHECK-NOT: load
; CHECK: ret i64 3
; CHECK-LABEL: define i64 @atomic_pointer_integer_store_observed(
; CHECK: %bits = ptrtoint ptr %pointer to i64
; CHECK: store i64 %bits, ptr %slot
; CHECK: %old = atomicrmw add ptr %slot, i64 1 seq_cst
