; A guest-range dispatch can be created before callback/native-pointer
; provenance is exposed by inlining.  The recovery cleanup must recover the
; ordinary native base+index access instead of retaining one select per ELF
; object; the final pass only verifies the resulting IR.

@dyn_bytes_405068 = internal global [64 x i8] zeroinitializer,
  !brighten.guest.range !0

define i32 @callback(ptr %base, i64 %index) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  %scaled = shl i64 %index, 2
  %address = add i64 %base.bits, %scaled
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4214888
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_405068, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %fallback
  %value = load i32, ptr %native.data.pointer.select, align 4
  ret i32 %value
}

define i32 @callback_exact(ptr %base) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  %delta = add i64 %base.bits, -4214888
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_405068, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %base
  %value = load i32, ptr %native.data.pointer.select, align 4
  ret i32 %value
}

define i32 @frame_loaded_native(ptr %base, i64 %index) {
entry:
  ; Native entry normalization uses frame_storage rather than native_frame.
  %frame_storage = alloca [8 x i8], align 8
  %base.bits = ptrtoint ptr %base to i64
  store i64 %base.bits, ptr %frame_storage, align 8
  %reloaded.bits = load i64, ptr %frame_storage, align 8
  %scaled = shl i64 %index, 2
  %address = add i64 %reloaded.bits, %scaled
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4214888
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_405068, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %fallback
  %value = load i32, ptr %native.data.pointer.select, align 4
  ret i32 %value
}

define i32 @frame_loaded_guest(i64 %guest_address) {
entry:
  %native_frame = alloca [8 x i8], align 8
  store i64 %guest_address, ptr %native_frame, align 8
  %reloaded.bits = load i64, ptr %native_frame, align 8
  %fallback = inttoptr i64 %reloaded.bits to ptr
  %delta = add i64 %reloaded.bits, -4214888
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_405068, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %fallback
  %value = load i32, ptr %native.data.pointer.select, align 4
  ret i32 %value
}

define i32 @dynamic_frame_loaded_native(
    ptr %base, i64 %index, i64 %slot_offset, i1 %keep) {
entry:
  %native_frame = alloca [32 x i8], align 8
  %slot = getelementptr i8, ptr %native_frame, i64 %slot_offset
  %base.bits = ptrtoint ptr %base to i64
  %nullable.bits = select i1 %keep, i64 %base.bits, i64 0
  store i64 %nullable.bits, ptr %slot, align 8
  %reloaded.bits = load i64, ptr %slot, align 8
  %scaled = shl i64 %index, 2
  %address = add i64 %reloaded.bits, %scaled
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4214888
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_405068, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %fallback
  %value = load i32, ptr %native.data.pointer.select, align 4
  ret i32 %value
}

define i32 @native_affine_roundtrip(ptr %base, i64 %index) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  %scaled = shl i64 %index, 2
  %address = add i64 %base.bits, %scaled
  %pointer = inttoptr i64 %address to ptr
  %value = load i32, ptr %pointer, align 4
  ret i32 %value
}

define i32 @native_affine_nuw_roundtrip(ptr %base, i64 %index) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  %scaled = shl i64 %index, 2
  %address = add nuw i64 %base.bits, %scaled
  %pointer = inttoptr i64 %address to ptr
  %value = load i32, ptr %pointer, align 4
  ret i32 %value
}

define ptr @native_affine_nsw_refused(ptr %base, i64 %offset) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  %address = add nsw i64 %base.bits, %offset
  %pointer = inttoptr i64 %address to ptr
  ret ptr %pointer
}

define ptr @nullable_native_roundtrip(ptr %base, i1 %present) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  br i1 %present, label %nonnull, label %null

nonnull:
  br label %merge

null:
  br label %merge

merge:
  %bits = phi i64 [ %base.bits, %nonnull ], [ 0, %null ]
  %pointer = inttoptr i64 %bits to ptr
  ret ptr %pointer
}

define i64 @local_frame_affine_phi(i1 %choose) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %frame_top = getelementptr i8, ptr %frame_storage, i64 4080
  %frame_top.bits = ptrtoint ptr %frame_top to i64
  %left.bits = add i64 %frame_top.bits, -16
  %right.bits = sub i64 %frame_top.bits, 32
  br i1 %choose, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %address = phi i64 [ %left.bits, %left ], [ %right.bits, %right ]
  %pointer = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4214888
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_405068, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %pointer
  %value = load i64, ptr %native.data.pointer.select, align 8
  ret i64 %value
}

define ptr @mixed_guest_native_phi_refused(ptr %base, i64 %guest, i1 %choose) {
entry:
  %base.bits = ptrtoint ptr %base to i64
  %native.bits = add i64 %base.bits, 8
  br i1 %choose, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %address = phi i64 [ %native.bits, %left ], [ %guest, %right ]
  %pointer = inttoptr i64 %address to ptr
  ret ptr %pointer
}

define i64 @local_frame_relative_affine_phi(i1 %choose) {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %frame_top = getelementptr i8, ptr %frame_storage, i64 4080
  %frame_top.bits = ptrtoint ptr %frame_top to i64
  %left.bits = add i64 %frame_top.bits, -16
  %right.bits = sub i64 %frame_top.bits, 32
  br i1 %choose, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %absolute = phi i64 [ %left.bits, %left ], [ %right.bits, %right ]
  %adjusted = add i64 %absolute, -8
  %relative = sub i64 %adjusted, %frame_top.bits
  ret i64 %relative
}

!0 = !{i64 4214888, i64 4214952}

; CHECK-LABEL: define i32 @callback(
; CHECK: %native.affine.pointer = getelementptr i8, ptr %base, i64 %scaled
; CHECK: %value = load i32, ptr %native.affine.pointer
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @callback_exact(
; CHECK: %value = load i32, ptr %base
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @frame_loaded_native(
; CHECK-NOT: %reloaded.bits = load
; CHECK: %native.affine.pointer = getelementptr i8, ptr %base, i64 %scaled
; CHECK: %value = load i32, ptr %native.affine.pointer
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @frame_loaded_guest(
; CHECK: %native.data.pointer.select = select
; CHECK: %value = load i32, ptr %native.data.pointer.select
; CHECK-LABEL: define i32 @dynamic_frame_loaded_native(
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %value = load i32, ptr %fallback
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @native_affine_roundtrip(
; CHECK: %native.affine.pointer = getelementptr i8, ptr %base, i64 %scaled
; CHECK: %value = load i32, ptr %native.affine.pointer
; CHECK-NOT: inttoptr
; CHECK-LABEL: define i32 @native_affine_nuw_roundtrip(
; CHECK: %native.affine.pointer = getelementptr nuw i8, ptr %base, i64 %scaled
; CHECK: %value = load i32, ptr %native.affine.pointer
; CHECK-NOT: inttoptr
; CHECK-LABEL: define ptr @native_affine_nsw_refused(
; CHECK: %address = add nsw i64 %base.bits, %offset
; CHECK: %pointer = inttoptr i64 %address to ptr
; CHECK: ret ptr %pointer
; CHECK-LABEL: define ptr @nullable_native_roundtrip(
; CHECK: %native.pointer.phi = phi ptr [ %base, %nonnull ], [ null, %null ]
; CHECK: ret ptr %native.pointer.phi
; CHECK-NOT: inttoptr
; CHECK-LABEL: define i64 @local_frame_affine_phi(
; CHECK: left:
; CHECK: %native.pointer.phi.edge = getelementptr i8, ptr %frame_top, i64 -16
; CHECK: right:
; CHECK: %native.pointer.phi.edge1 = getelementptr i8, ptr %frame_top, i64 -32
; CHECK: merge:
; CHECK: %native.pointer.phi = phi ptr [ %native.pointer.phi.edge, %left ], [ %native.pointer.phi.edge1, %right ]
; CHECK: %value = load i64, ptr %native.pointer.phi
; CHECK-NOT: native.data.pointer.select
; CHECK-NOT: inttoptr
; CHECK-LABEL: define ptr @mixed_guest_native_phi_refused(
; CHECK: %address = phi i64 [ %native.bits, %left ], [ %guest, %right ]
; CHECK: %pointer = inttoptr i64 %address to ptr
; CHECK: ret ptr %pointer
; CHECK-LABEL: define i64 @local_frame_relative_affine_phi(
; CHECK: %native.frame.relative = phi i64 [ -24, %left ], [ -40, %right ]
; CHECK: ret i64 %native.frame.relative
; CHECK-NOT: %relative = sub

; The post-frame boundary consumes the finite, disjoint local-frame pointer
; PHI into real typed slots. The ordinary cleanup checks above intentionally
; retain the earlier affine spelling so ownership of the two stages remains
; visible.
; POST-FRAME-LABEL: define i64 @local_frame_affine_phi(
; POST-FRAME-NOT: alloca [4096 x i8]
; POST-FRAME-DAG: %native.slot.4064 = alloca i64, align 8
; POST-FRAME-DAG: %native.slot.4048 = alloca i64, align 8
; POST-FRAME: %native.slot.pointer = phi ptr [ %native.slot.4064, %left ], [ %native.slot.4048, %right ]
; POST-FRAME: %value = load i64, ptr %native.slot.pointer, align 8
; POST-FRAME-LABEL: define ptr @mixed_guest_native_phi_refused(
; POST-FRAME: %pointer = inttoptr i64 %address to ptr
