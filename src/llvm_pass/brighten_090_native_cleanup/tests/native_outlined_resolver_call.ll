target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@native_residual_data = internal global [16 x i8] c"\07\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00"
@native_residual_rodata = internal constant [8 x i8] zeroinitializer

; Exact generated guest-or-native boundary.  The post-frame consumer may
; bypass it only when the call's guest-address operand has native pointer
; provenance and can be reconstructed without changing poison semantics.
define internal ptr @__brighten_resolve_recovered_address(i64 %guest_address) {
entry:
  %native.address.fallback = inttoptr i64 %guest_address to ptr
  %native.data.offset = add i64 %guest_address, -4096
  %native.data.in.range = icmp ult i64 %native.data.offset, 16
  %native.data.dynamic.ptr = getelementptr i8, ptr @native_residual_data, i64 %native.data.offset
  %native.data.pointer.select = select i1 %native.data.in.range, ptr %native.data.dynamic.ptr, ptr %native.address.fallback
  %native.data.offset1 = add i64 %guest_address, -8192
  %native.data.in.range2 = icmp ult i64 %native.data.offset1, 8
  %native.data.dynamic.ptr3 = getelementptr i8, ptr @native_residual_rodata, i64 %native.data.offset1
  %native.data.pointer.select4 = select i1 %native.data.in.range2, ptr %native.data.dynamic.ptr3, ptr %native.data.pointer.select
  ret ptr %native.data.pointer.select4
}

define internal i32 @native_direct(ptr %slot) {
entry:
  %address = ptrtoint ptr %slot to i64
  %resolved = call ptr @__brighten_resolve_recovered_address(i64 %address)
  %value = load i32, ptr %resolved, align 4
  ret i32 %value
}

define internal i32 @native_affine(ptr %base) {
entry:
  %anchor = ptrtoint ptr %base to i64
  %address = add i64 %anchor, 4
  %resolved = call ptr @__brighten_resolve_recovered_address(i64 %address)
  %value = load i32, ptr %resolved, align 4
  ret i32 %value
}

; A guest constant has no native provenance and must retain the exact range
; mapping instead of becoming inttoptr(4096).
define internal i8 @guest_constant_refused() {
entry:
  %resolved = call ptr @__brighten_resolve_recovered_address(i64 4096)
  %value = load i8, ptr %resolved, align 1
  ret i8 %value
}

; Reassociating an nsw address computation into GEP would weaken its poison
; contract, so this native-looking call is deliberately refused.
define internal i32 @poison_flagged_refused(ptr %base) {
entry:
  %anchor = ptrtoint ptr %base to i64
  %address = add nsw i64 %anchor, 4
  %resolved = call ptr @__brighten_resolve_recovered_address(i64 %address)
  %value = load i32, ptr %resolved, align 4
  ret i32 %value
}

define i32 @main() {
entry:
  %storage = alloca [16 x i8], align 8
  %base = getelementptr inbounds [16 x i8], ptr %storage, i64 0, i64 0
  %slot = getelementptr inbounds [16 x i8], ptr %storage, i64 0, i64 4
  store i32 42, ptr %slot, align 4
  %direct = call i32 @native_direct(ptr %slot)
  %affine = call i32 @native_affine(ptr %base)
  %flagged = call i32 @poison_flagged_refused(ptr %base)
  %guest = call i8 @guest_constant_refused()
  %direct.ok = icmp eq i32 %direct, 42
  %affine.ok = icmp eq i32 %affine, 42
  %flagged.ok = icmp eq i32 %flagged, 42
  %guest.ok = icmp eq i8 %guest, 7
  %native.ok = and i1 %direct.ok, %affine.ok
  %all.native.ok = and i1 %native.ok, %flagged.ok
  %ok = and i1 %all.native.ok, %guest.ok
  %failed = xor i1 %ok, true
  %status = zext i1 %failed to i32
  ret i32 %status
}

; CHECK-LABEL: define internal i32 @native_direct(ptr %slot)
; CHECK-NOT: call ptr @__brighten_resolve_recovered_address
; CHECK: %value = load i32, ptr %slot

; CHECK-LABEL: define internal i32 @native_affine(ptr %base)
; CHECK: %native.outlined.resolver.pointer = getelementptr i8, ptr %base, i64 4
; CHECK-NOT: call ptr @__brighten_resolve_recovered_address
; CHECK: %value = load i32, ptr %native.outlined.resolver.pointer

; CHECK-LABEL: define internal i8 @guest_constant_refused()
; CHECK: call ptr @__brighten_resolve_recovered_address(i64 4096)

; CHECK-LABEL: define internal i32 @poison_flagged_refused(ptr %base)
; CHECK: %address = add nsw i64 %anchor, 4
; CHECK: call ptr @__brighten_resolve_recovered_address(i64 %address)
