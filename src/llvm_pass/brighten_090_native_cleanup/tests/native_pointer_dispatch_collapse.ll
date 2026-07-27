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
  %native_frame = alloca [8 x i8], align 8
  %base.bits = ptrtoint ptr %base to i64
  store i64 %base.bits, ptr %native_frame, align 8
  %reloaded.bits = load i64, ptr %native_frame, align 8
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

!0 = !{i64 4214888, i64 4214952}

; CHECK-LABEL: define i32 @callback(
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %value = load i32, ptr %fallback
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @callback_exact(
; CHECK: %value = load i32, ptr %base
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @frame_loaded_native(
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %value = load i32, ptr %fallback
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i32 @frame_loaded_guest(
; CHECK: %native.data.pointer.select = select
; CHECK: %value = load i32, ptr %native.data.pointer.select
; CHECK-LABEL: define i32 @dynamic_frame_loaded_native(
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %value = load i32, ptr %fallback
; CHECK-NOT: native.data.pointer.select
