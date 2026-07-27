; RUN: opt -load-pass-plugin %builddir/BrightenGlobalDataRecoveryPass.so -passes=brighten-guest-pointer-resolver-canonicalize,verify -S < %s | FileCheck %s
;
; The late 070 owner only rewrites a constant address with one proven object.
; Dynamic, overlapping, and overflow-sensitive resolvers are preserved exactly.

@unique = internal global [16 x i8] zeroinitializer, !brighten.guest.range !0
@left = internal global [16 x i8] zeroinitializer, !brighten.guest.range !1
@right = internal global [16 x i8] zeroinitializer, !brighten.guest.range !2
@overlap_left = internal global [16 x i8] zeroinitializer, !brighten.guest.range !4
@overlap_right = internal global [16 x i8] zeroinitializer, !brighten.guest.range !5
@edge = internal global [16 x i8] zeroinitializer, !brighten.guest.range !3
@after = internal global [16 x i8] zeroinitializer, !brighten.guest.range !6
@wide_metadata = internal global [16 x i8] zeroinitializer, !brighten.guest.range !7
@noninteger_metadata = internal global [16 x i8] zeroinitializer, !brighten.guest.range !8
@short_metadata = internal global [16 x i8] zeroinitializer, !brighten.guest.range !9

; CHECK-LABEL: define ptr @positive_unique()
; CHECK: ret ptr getelementptr (i8, ptr @unique, i64 4)
; CHECK-NOT: native.data.pointer.select
; CHECK-NOT: brighten.guest.pointer.resolver
define ptr @positive_unique() {
entry:
  %fallback = inttoptr i64 4100 to ptr
  %in.lo = icmp uge i64 4100, 4096
  %in.hi = icmp ult i64 4100, 4112
  %in = and i1 %in.lo, %in.hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @unique, i64 -4096), i64 4100
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; CHECK-LABEL: define i8 @unresolved_fallback(i64 %address)
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %mapped = getelementptr i8, ptr getelementptr (i8, ptr @left, i64 -8192), i64 %address
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
; CHECK: %value = load i8, ptr %result
; CHECK-NOT: brighten.guest.pointer.resolver
define i8 @unresolved_fallback(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %in.lo = icmp uge i64 %address, 8192
  %in.hi = icmp ult i64 %address, 8208
  %in = and i1 %in.lo, %in.hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @left, i64 -8192), i64 %address
  %result = select i1 %in, ptr %mapped, ptr %fallback
  %value = load i8, ptr %result
  ret i8 %value
}

; CHECK-LABEL: define i8 @overlapping_negative(i64 %address)
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %inner = select i1 %r.in, ptr %r.ptr, ptr %fallback
; CHECK: %result = select i1 %l.in, ptr %l.ptr, ptr %inner
; CHECK-NOT: native.data.unique.gep
; CHECK-NOT: brighten.guest.pointer.resolver
define i8 @overlapping_negative(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %r.lo = icmp uge i64 %address, 12296
  %r.hi = icmp ult i64 %address, 12312
  %r.in = and i1 %r.lo, %r.hi
  %r.ptr = getelementptr i8, ptr getelementptr (i8, ptr @overlap_right, i64 -12296), i64 %address
  %inner = select i1 %r.in, ptr %r.ptr, ptr %fallback
  %l.lo = icmp uge i64 %address, 12288
  %l.hi = icmp ult i64 %address, 12304
  %l.in = and i1 %l.lo, %l.hi
  %l.ptr = getelementptr i8, ptr getelementptr (i8, ptr @overlap_left, i64 -12288), i64 %address
  %result = select i1 %l.in, ptr %l.ptr, ptr %inner
  %value = load i8, ptr %result
  ret i8 %value
}

; CHECK-LABEL: define ptr @boundary_overflow_negative(i64 %address)
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
; CHECK-NOT: native.data.unique.gep
define ptr @boundary_overflow_negative(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %lo = icmp uge i64 %address, 18446744073709551600
  %hi = icmp ult i64 %address, 18446744073709551615
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @edge, i64 16), i64 %address
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; CHECK-LABEL: define i64 @identity_observed_negative(i64 %address)
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
; CHECK: ptrtoint ptr %result to i64
define i64 @identity_observed_negative(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %lo = icmp uge i64 %address, 8192
  %hi = icmp ult i64 %address, 8208
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @left, i64 -8192), i64 %address
  %result = select i1 %in, ptr %mapped, ptr %fallback
  %bits = ptrtoint ptr %result to i64
  ret i64 %bits
}

; A dynamic compare bound is not a guest range proof.  In particular, this
; must refuse rather than dereference a null ConstantInt while matching.
; CHECK-LABEL: define ptr @dynamic_bound_negative
; CHECK: %fallback = inttoptr i64 %address to ptr
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
define ptr @dynamic_bound_negative(i64 %address, i64 %dynamic.begin) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %lo = icmp uge i64 %address, %dynamic.begin
  %hi = icmp ult i64 %address, 4112
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @unique, i64 -4096), i64 %address
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; A constant address covered by two ranges has no unique object proof.
; CHECK-LABEL: define ptr @constant_overlap_negative
; CHECK: %result = select i1 %l.in, ptr %l.ptr, ptr %inner
define ptr @constant_overlap_negative() {
entry:
  %fallback = inttoptr i64 12298 to ptr
  %r.lo = icmp uge i64 12298, 12296
  %r.hi = icmp ult i64 12298, 12312
  %r.in = and i1 %r.lo, %r.hi
  %r.ptr = getelementptr i8, ptr getelementptr (i8, ptr @overlap_right, i64 -12296), i64 12298
  %inner = select i1 %r.in, ptr %r.ptr, ptr %fallback
  %l.lo = icmp uge i64 12298, 12288
  %l.hi = icmp ult i64 12298, 12304
  %l.in = and i1 %l.lo, %l.hi
  %l.ptr = getelementptr i8, ptr getelementptr (i8, ptr @overlap_left, i64 -12288), i64 12298
  %result = select i1 %l.in, ptr %l.ptr, ptr %inner
  ret ptr %result
}

; Half-open boundaries and gaps require the raw fallback even for constants.
; CHECK-LABEL: define ptr @begin_minus_one_negative
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
define ptr @begin_minus_one_negative() {
entry:
  %fallback = inttoptr i64 4095 to ptr
  %lo = icmp uge i64 4095, 4096
  %hi = icmp ult i64 4095, 4112
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @unique, i64 -4096), i64 4095
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; CHECK-LABEL: define ptr @end_negative
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
define ptr @end_negative() {
entry:
  %fallback = inttoptr i64 4112 to ptr
  %lo = icmp uge i64 4112, 4096
  %hi = icmp ult i64 4112, 4112
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @unique, i64 -4096), i64 4112
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; CHECK-LABEL: define ptr @gap_negative
; CHECK: %result = select i1 %after.in, ptr %after.ptr, ptr %inner
define ptr @gap_negative() {
entry:
  %fallback = inttoptr i64 4120 to ptr
  %unique.lo = icmp uge i64 4120, 4096
  %unique.hi = icmp ult i64 4120, 4112
  %unique.in = and i1 %unique.lo, %unique.hi
  %unique.ptr = getelementptr i8, ptr getelementptr (i8, ptr @unique, i64 -4096), i64 4120
  %inner = select i1 %unique.in, ptr %unique.ptr, ptr %fallback
  %after.lo = icmp uge i64 4120, 4128
  %after.hi = icmp ult i64 4120, 4144
  %after.in = and i1 %after.lo, %after.hi
  %after.ptr = getelementptr i8, ptr getelementptr (i8, ptr @after, i64 -4128), i64 4120
  %result = select i1 %after.in, ptr %after.ptr, ptr %inner
  ret ptr %result
}

; Bad metadata is no object proof: i128, non-integer, and malformed arity
; must all preserve the resolver rather than asserting or truncating.
; CHECK-LABEL: define ptr @wide_metadata_negative
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
define ptr @wide_metadata_negative() {
entry:
  %fallback = inttoptr i64 16388 to ptr
  %lo = icmp uge i64 16388, 16384
  %hi = icmp ult i64 16388, 16400
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @wide_metadata, i64 -16384), i64 16388
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; CHECK-LABEL: define ptr @noninteger_metadata_negative
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
define ptr @noninteger_metadata_negative() {
entry:
  %fallback = inttoptr i64 20484 to ptr
  %lo = icmp uge i64 20484, 20480
  %hi = icmp ult i64 20484, 20496
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @noninteger_metadata, i64 -20480), i64 20484
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

; CHECK-LABEL: define ptr @short_metadata_negative
; CHECK: %result = select i1 %in, ptr %mapped, ptr %fallback
define ptr @short_metadata_negative() {
entry:
  %fallback = inttoptr i64 24580 to ptr
  %lo = icmp uge i64 24580, 24576
  %hi = icmp ult i64 24580, 24592
  %in = and i1 %lo, %hi
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @short_metadata, i64 -24576), i64 24580
  %result = select i1 %in, ptr %mapped, ptr %fallback
  ret ptr %result
}

!0 = !{i64 4096, i64 4112}
!1 = !{i64 8192, i64 8208}
!2 = !{i64 12296, i64 12312}
!3 = !{i64 18446744073709551600, i64 18446744073709551615}
!4 = !{i64 12288, i64 12304}
!5 = !{i64 12296, i64 12312}
!6 = !{i64 4128, i64 4144}
!7 = !{i128 16384, i128 16400}
!8 = !{!"not-an-integer", i64 20496}
!9 = !{i64 24576}
