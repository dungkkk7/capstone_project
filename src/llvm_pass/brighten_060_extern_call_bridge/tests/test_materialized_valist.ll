; RUN: opt -load-pass-plugin %plugin -passes=brighten-extern-call-bridge -S %s | FileCheck %s
;
; A previous native cleanup stage may have materialized a SysV va_list for a
; lifted printf bridge.  Pass 060 owns external ABI recovery, so a later 060
; sweep should turn the explicit save-area representation back into a direct
; native variadic call.

@.fmt = private constant [4 x i8] c"%ld\00"
@.scan8 = private constant [25 x i8] c"%lf%lf%lf%lf%lf%lf%lf%lf\00"
@.scan6 = private constant [19 x i8] c"%lf%lf%lf%lf%lf%lf\00"
@.scan1 = private constant [4 x i8] c"%lf\00"
@.scan_int = private constant [3 x i8] c"%d\00"
@.scan_string = private constant [3 x i8] c"%s\00"
@.unrelated = private constant [3 x i8] c"%d\00"
@frame_storage_backing.test = internal global [256 x i8] zeroinitializer
@guest_scan_destinations = internal global [48 x i8] zeroinitializer,
  !brighten.guest.range !0

declare i32 @vprintf(ptr, ptr)
declare i32 @vscanf(ptr, ptr)
declare i32 @scanf(ptr, ...)
declare ptr @malloc(i64)

; vscanf register-save slots can contain literal guest addresses.  They must
; be rebased through the unique guest object before becoming scanf arguments;
; emitting raw inttoptr would crash libc on a native host.
define i32 @materialized_vscanf_guest_constants() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %overflow.slots = alloca [8 x i8], align 8
  %s1 = getelementptr i8, ptr %save, i64 8
  %s2 = getelementptr i8, ptr %save, i64 16
  %s3 = getelementptr i8, ptr %save, i64 24
  %s4 = getelementptr i8, ptr %save, i64 32
  %s5 = getelementptr i8, ptr %save, i64 40
  store i64 24576, ptr %s1, align 8
  store i64 24584, ptr %s2, align 8
  store i64 24592, ptr %s3, align 8
  store i64 24600, ptr %s4, align 8
  store i64 24608, ptr %s5, align 8
  store i64 24616, ptr %overflow.slots, align 8
  store i32 8, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr %overflow.slots, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan6, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_vscanf_guest_constants
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan6, ptr {{.*guest_scan_destinations}}
; CHECK-NOT: inttoptr (i64 24576 to ptr)
; CHECK-NOT: call i32 @vscanf

; A recovered range dispatch can mix native global arms with a raw fallback
; whose integer is affine from ptrtoint(malloc).  Every arm is a native host
; pointer, so preserving it through the save area must not block vscanf
; dematerialization.
define i32 @materialized_vscanf_affine_heap_dispatch(i64 %index, i1 %mapped) {
entry:
  %heap = call ptr @malloc(i64 40)
  %heap.int = ptrtoint ptr %heap to i64
  %scaled = shl i64 %index, 2
  %address = add i64 %heap.int, %scaled
  %fallback = inttoptr i64 %address to ptr
  %destination = select i1 %mapped, ptr @guest_scan_destinations, ptr %fallback
  %destination.int = ptrtoint ptr %destination to i64
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %save, i64 8
  store i64 %destination.int, ptr %slot, align 8
  store i32 8, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan_int, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_vscanf_affine_heap_dispatch
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan_int, ptr {{.*}})
; CHECK-NOT: call i32 @vscanf

; A guest string destination has input-dependent extent.  It is still safe to
; lower when the first writable byte maps to exactly one recovered guest
; object: the native call preserves any original overrun behaviour rather than
; dereferencing the guest integer directly.
define i32 @materialized_vscanf_guest_string_offset() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %save, i64 8
  store i64 24583, ptr %slot, align 8
  store i32 8, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan_string, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_vscanf_guest_string_offset
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan_string, ptr {{.*guest_scan_destinations}}
; CHECK-NOT: call i32 @vscanf

define i32 @materialized_printf(i64 %x) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %save, i64 8
  store i64 %x, ptr %slot, align 8
  store i32 8, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vprintf(ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_printf
; CHECK: call i32 (ptr, ...) @printf(ptr @.fmt, i64 %x)
; CHECK-NOT: call i32 @vprintf

define i32 @materialized_scanf_overflow(ptr %a, ptr %b, ptr %c, ptr %d,
                                        ptr %e, i64 %rsp) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %anchor = getelementptr i8, ptr @frame_storage_backing.test, i64 128
  %overflow.slots = getelementptr i8, ptr %anchor, i64 %rsp
  store i64 -24, ptr %overflow.slots, align 8
  %overflow.1 = getelementptr i8, ptr %overflow.slots, i64 8
  store i64 -16, ptr %overflow.1, align 8
  %overflow.2 = getelementptr i8, ptr %overflow.slots, i64 16
  store i64 -8, ptr %overflow.2, align 8
  %s1 = getelementptr i8, ptr %save, i64 8
  %s2 = getelementptr i8, ptr %save, i64 16
  %s3 = getelementptr i8, ptr %save, i64 24
  %s4 = getelementptr i8, ptr %save, i64 32
  %s5 = getelementptr i8, ptr %save, i64 40
  store ptr %a, ptr %s1, align 8
  store ptr %b, ptr %s2, align 8
  store ptr %c, ptr %s3, align 8
  store ptr %d, ptr %s4, align 8
  store ptr %e, ptr %s5, align 8
  store i32 8, ptr %va, align 8
  %overflow.field = getelementptr i8, ptr %va, i64 8
  store ptr %overflow.slots, ptr %overflow.field, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  ; Pass 070's native data range chain keeps the original pointer on the false
  ; edge while true edges can reference unrelated recovered strings.
  %is.guest = icmp eq i64 ptrtoint (ptr @.scan8 to i64), 4210701
  %native.data.pointer.select.test = select i1 %is.guest, ptr @.unrelated, ptr @.scan8
  %ret = call i32 @vscanf(ptr %native.data.pointer.select.test, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_scanf_overflow
; CHECK: %native.overflow.frame.ptr = getelementptr i8, ptr %anchor, i64 -24
; CHECK: getelementptr i8, ptr %anchor, i64 -16
; CHECK: getelementptr i8, ptr %anchor, i64 -8
; CHECK: call i32 (ptr, ...) @scanf(ptr %native.data.pointer.select.test, ptr captures(none) %a, ptr captures(none) %b, ptr captures(none) %c, ptr captures(none) %d, ptr captures(none) %e, ptr captures(none) %native.overflow.frame.ptr{{[0-9]*}}, ptr captures(none) %native.overflow.frame.ptr{{[0-9]*}}, ptr captures(none) %native.overflow.frame.ptr{{[0-9]*}})
; CHECK-NOT: call i32 @vscanf

; A concrete recovered backing initializes RSP/RBP with ptrtoint(frame_top).
; Affine stack coordinates based on that State value are therefore native
; absolute addresses already; adding frame_top again would double the address.
define internal i32 @materialized_scanf_absolute(ptr %frame_base, ptr %a,
                                                 ptr %b, ptr %c, ptr %d,
                                                 ptr %e,
                                                 i64 %state_in_2328) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %absolute = add i64 %state_in_2328, -24
  store i64 %absolute, ptr %frame_base, align 8
  %s1 = getelementptr i8, ptr %save, i64 8
  %s2 = getelementptr i8, ptr %save, i64 16
  %s3 = getelementptr i8, ptr %save, i64 24
  %s4 = getelementptr i8, ptr %save, i64 32
  %s5 = getelementptr i8, ptr %save, i64 40
  store ptr %a, ptr %s1, align 8
  store ptr %b, ptr %s2, align 8
  store ptr %c, ptr %s3, align 8
  store ptr %d, ptr %s4, align 8
  store ptr %e, ptr %s5, align 8
  store i32 8, ptr %va, align 8
  %overflow.field = getelementptr i8, ptr %va, i64 8
  store ptr %frame_base, ptr %overflow.field, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan6, ptr %va)
  ret i32 %ret
}

; Model primary cleanup outlining the recovered function and passing its
; proven recovered frame top as an explicit argument.
define i32 @materialized_scanf_absolute_driver(ptr %a, ptr %b, ptr %c, ptr %d,
                                               ptr %e, i64 %state_in_2328) {
entry:
  %anchor = getelementptr i8, ptr @frame_storage_backing.test, i64 128
  %ret = call i32 @materialized_scanf_absolute(ptr %anchor, ptr %a, ptr %b,
                                               ptr %c, ptr %d, ptr %e,
                                               i64 %state_in_2328)
  ret i32 %ret
}

; CHECK-LABEL: define internal i32 @materialized_scanf_absolute
; CHECK: %native.overflow.absolute.ptr = inttoptr i64 %absolute to ptr
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan6, ptr captures(none) %a, ptr captures(none) %b, ptr captures(none) %c, ptr captures(none) %d, ptr captures(none) %e, ptr captures(none) %native.overflow.absolute.ptr)
; CHECK-NOT: native.overflow.frame.ptr
; CHECK-NOT: call i32 @vscanf

; Native cleanup can leave register-save values as affine integers based on a
; ptrtoint of the recovered frame top.  They are native pointers exactly when
; the base shares the proven frame backing and the complete scanf destination
; remains within that backing object.
define i32 @materialized_scanf_affine_frame(ptr %c, ptr %d, ptr %e) {
entry:
  %frame = alloca [256 x i8], align 16
  %top = getelementptr i8, ptr %frame, i64 128
  %top.int = ptrtoint ptr %top to i64
  %dest1 = add i64 %top.int, -32
  %dest2 = add i64 %top.int, -24
  %dest6 = add i64 %top.int, -8
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %s1 = getelementptr i8, ptr %save, i64 8
  %s2 = getelementptr i8, ptr %save, i64 16
  %s3 = getelementptr i8, ptr %save, i64 24
  %s4 = getelementptr i8, ptr %save, i64 32
  %s5 = getelementptr i8, ptr %save, i64 40
  store i64 %dest1, ptr %s1, align 8
  store i64 %dest2, ptr %s2, align 8
  store ptr %c, ptr %s3, align 8
  store ptr %d, ptr %s4, align 8
  store ptr %e, ptr %s5, align 8
  %overflow.slots = getelementptr i8, ptr %frame, i64 64
  store i64 %dest6, ptr %overflow.slots, align 8
  store i32 8, ptr %va, align 8
  %overflow.field = getelementptr i8, ptr %va, i64 8
  store ptr %overflow.slots, ptr %overflow.field, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan6, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_scanf_affine_frame
; CHECK: %native.frame.affine.ptr = getelementptr i8, ptr %top, i64 -32
; CHECK: %native.frame.affine.ptr{{[0-9]+}} = getelementptr i8, ptr %top, i64 -24
; CHECK: %native.frame.affine.ptr{{[0-9]+}} = getelementptr i8, ptr %top, i64 -8
; CHECK: call void @llvm.memcpy{{.*}}(ptr align 8 %native.scanf.destination, ptr align 1 %native.frame.affine.ptr, i64 8, i1 false)
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan6, ptr captures(none) %native.scanf.destination, ptr captures(none) %native.scanf.destination{{[0-9]+}}, ptr captures(none) %c, ptr captures(none) %d, ptr captures(none) %e, ptr captures(none) %native.scanf.destination{{[0-9]+}})
; CHECK: call void @llvm.memcpy{{.*}}(ptr align 1 %native.frame.affine.ptr, ptr align 8 %native.scanf.destination, i64 8, i1 false)
; CHECK-NOT: call i32 @vscanf

; The same syntax is not enough when the destination would fall outside the
; recovered frame.  Keep the va_list call intact rather than inventing a host
; pointer.
define i32 @materialized_scanf_affine_out_of_bounds() {
entry:
  %frame = alloca [32 x i8], align 16
  %top = getelementptr i8, ptr %frame, i64 4
  %top.int = ptrtoint ptr %top to i64
  %bad.dest = add i64 %top.int, -8
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %save, i64 8
  store i64 %bad.dest, ptr %slot, align 8
  store i32 8, ptr %va, align 8
  %overflow.slots = getelementptr i8, ptr %frame, i64 16
  %overflow.field = getelementptr i8, ptr %va, i64 8
  store ptr %overflow.slots, ptr %overflow.field, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan1, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_scanf_affine_out_of_bounds
; CHECK: call i32 @vscanf(ptr @.scan1, ptr %va)

; An earlier bridge sweep may already have produced direct scanf while its
; destination was still an integer-shaped frame address.  A later sweep must
; revisit that call after native cleanup exposes the caller-local alloca.
define i32 @direct_scanf_affine_frame() {
entry:
  %frame_storage = alloca [64 x i8], align 16
  %top = getelementptr i8, ptr %frame_storage, i64 32
  %top.int = ptrtoint ptr %top to i64
  %dest.int = add i64 %top.int, -8
  %dest = inttoptr i64 %dest.int to ptr
  %ret = call i32 (ptr, ...) @scanf(ptr @.scan1, ptr %dest)
  %value = load double, ptr %dest, align 8
  %present = fcmp one double %value, 0.0
  %result = zext i1 %present to i32
  ret i32 %result
}

; CHECK-LABEL: define i32 @direct_scanf_affine_frame
; CHECK: %native.scanf.frame.ptr = getelementptr i8, ptr %top, i64 -8
; CHECK: call void @llvm.memcpy{{.*}}(ptr align 8 %native.scanf.destination{{[0-9]*}}, ptr align 1 %native.scanf.frame.ptr, i64 8, i1 false)
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan1, ptr captures(none) %native.scanf.destination{{[0-9]*}})
; CHECK: call void @llvm.memcpy{{.*}}(ptr align 1 %native.scanf.frame.ptr, ptr align 8 %native.scanf.destination{{[0-9]*}}, i64 8, i1 false)

!0 = !{i64 24576, i64 24624}

define i32 @materialized_vscanf_unknown_constant() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %save, i64 8
  store i64 3735928559, ptr %slot, align 8
  store i32 8, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan6, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_vscanf_unknown_constant
; CHECK: call i32 @vscanf(ptr @.scan6, ptr %va)
