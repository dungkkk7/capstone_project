; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-heap-proven-resolver-collapse,verify -verify-each -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@image = internal global [16 x i8] zeroinitializer, !brighten.guest.range !0
@zero_image = internal global [16 x i8] zeroinitializer, !brighten.guest.range !2

declare noalias ptr @malloc(i64) allocsize(0) allockind("alloc,uninitialized")
declare noalias ptr @calloc(i64, i64) allocsize(0,1) allockind("alloc,zeroed")
declare ptr @unknown_alloc(i64)
declare void @sink(ptr)
declare void @free(ptr)
declare i64 @strlen(ptr captures(none))
declare void @free_nocapture(ptr captures(none))
@partial_overlap = internal global [16 x i8] zeroinitializer, !brighten.guest.range !1

define void @positive_malloc_bounded(i64 %index) {
entry:
  %heap = call noalias dereferenceable_or_null(40) ptr @malloc(i64 40)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  %base = ptrtoint ptr %heap to i64
  %address = add nuw i64 %base, %index
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4096
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %address
  %resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  store volatile i8 1, ptr %resolver, align 1
  ; CHECK-LABEL: define void @positive_malloc_bounded
  ; CHECK: %brighten.heap.index = sub i64 %address, %base
  ; CHECK: %brighten.heap.gep = getelementptr i8, ptr %heap, i64 %brighten.heap.index
  ; CHECK-NOT: %resolver = select
  br label %done
done:
  ret void
}

; A missing non-null proof may select a static arm for null; retain resolver.
define void @reject_null_path() {
entry:
  %heap = call noalias ptr @malloc(i64 40)
  %base = ptrtoint ptr %heap to i64
  %fallback = inttoptr i64 %base to ptr
  %delta = add i64 %base, 0
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr @zero_image, i64 %base
  %resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  ; CHECK-LABEL: define void @reject_null_path
  ; CHECK: %resolver = select
  ret void
}

; Observable integer comparison/tagging rejects the provenance rewrite.
define void @reject_ptrtoint_compare_and_tag() {
entry:
  %heap = call noalias ptr @malloc(i64 40)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  %base = ptrtoint ptr %heap to i64
  %tag = xor i64 %base, 1
  %observed = icmp eq i64 %base, 7
  %fallback = inttoptr i64 %base to ptr
  %delta = add i64 %base, -4096
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %base
  %resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  ; CHECK-LABEL: define void @reject_ptrtoint_compare_and_tag
  ; CHECK: %tag = xor i64 %base, 1
  ; CHECK: %resolver = select
  br i1 %observed, label %done, label %done
done:
  ret void
}

define void @positive_calloc(i64 %index) {
entry:
  %heap = call noalias dereferenceable_or_null(40) ptr @calloc(i64 10, i64 4)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  %base = ptrtoint ptr %heap to i64
  %address = add i64 %base, %index
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4096
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %address
  %resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  ; CHECK-LABEL: define void @positive_calloc
  ; CHECK: brighten.heap.gep = getelementptr i8, ptr %heap
  store i8 0, ptr %resolver
  br label %done
done:
  ret void
}

; Exact post-040 shape: the local pointer slot is the only serialization
; boundary.  The i64 sidecar drives range checks, while the fallback preserves
; the loaded host pointer identity for strlen/free.
define void @positive_post_040_pointer_slot(i64 %index) {
entry:
  %slot = alloca ptr, align 8
  %heap = call noalias ptr @calloc(i64 16, i64 1)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  store ptr %heap, ptr %slot, align 8
  %slot.load = load ptr, ptr %slot, align 8
  %slot.bits = ptrtoint ptr %slot.load to i64
  %delta = add i64 %slot.bits, -4096
  %in.image = icmp ult i64 %delta, 16
  %dynamic = getelementptr i8, ptr @image, i64 %slot.bits
  %candidate = getelementptr i8, ptr %dynamic, i64 -4096
  %resolver = select i1 %in.image, ptr %candidate, ptr %slot.load
  %len = call i64 @strlen(ptr %resolver)
  call void @free_nocapture(ptr %resolver)
  ; CHECK-LABEL: define void @positive_post_040_pointer_slot
  ; CHECK: %slot = alloca ptr, align 8
  ; CHECK: store ptr %heap, ptr %slot, align 8
  ; CHECK-NOT: %slot.load = load ptr, ptr %slot, align 8
  ; CHECK: %len = call i64 @strlen(ptr %heap)
  ; CHECK: call void @free_nocapture(ptr %heap)
  ; CHECK-NOT: %resolver = select
  br label %done
done:
  ret void
}

define void @reject_post_040_slot_volatile_atomic_phi_and_callback(i1 %choose) {
entry:
  %slot = alloca ptr, align 8
  %heap = call noalias ptr @calloc(i64 16, i64 1)
  %other = call noalias ptr @calloc(i64 16, i64 1)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  store volatile ptr %heap, ptr %slot, align 8
  %bad.load = load atomic ptr, ptr %slot unordered, align 8
  %mixed = select i1 %choose, ptr %bad.load, ptr %other
  %bits = ptrtoint ptr %mixed to i64
  %delta = add i64 %bits, -4096
  %in.image = icmp ult i64 %delta, 16
  %dynamic = getelementptr i8, ptr @image, i64 %bits
  %candidate = getelementptr i8, ptr %dynamic, i64 -4096
  %resolver = select i1 %in.image, ptr %candidate, ptr %mixed
  ; CHECK-LABEL: define void @reject_post_040_slot_volatile_atomic_phi_and_callback
  ; CHECK: %resolver = select
  call void @sink(ptr %resolver)
  br label %done
done:
  ret void
}

define void @reject_unknown_capture_free_and_partial_overlap() {
entry:
  %unknown = call ptr @unknown_alloc(i64 40)
  %u.base = ptrtoint ptr %unknown to i64
  %u.fallback = inttoptr i64 %u.base to ptr
  %u.delta = add i64 %u.base, -4096
  %u.in = icmp ult i64 %u.delta, 16
  %u.map = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %u.base
  %u.resolver = select i1 %u.in, ptr %u.map, ptr %u.fallback
  ; CHECK-LABEL: define void @reject_unknown_capture_free_and_partial_overlap
  ; CHECK: %u.resolver = select
  %heap = call noalias ptr @malloc(i64 40)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  %base = ptrtoint ptr %heap to i64
  %fallback = inttoptr i64 %base to ptr
  %d0 = add i64 %base, -4096
  %c0 = icmp ult i64 %d0, 16
  %m0 = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %base
  %s0 = select i1 %c0, ptr %m0, ptr %fallback
  %d1 = add i64 %base, -4104
  %c1 = icmp ult i64 %d1, 16
  %m1 = getelementptr i8, ptr getelementptr (i8, ptr @partial_overlap, i64 -4104), i64 %base
  %overlap = select i1 %c1, ptr %m1, ptr %s0
  ; CHECK: %overlap = select
  call void @sink(ptr %heap)
  call void @free(ptr %heap)
  store i8 0, ptr %overlap
  br label %done
done:
  ret void
}

; A fixed i64 slot may serialize exactly one allocation pointer.  Keep the
; integer sidecar and resolver arithmetic intact, but recover the fallback
; object chosen by the resolver.
define void @positive_serialized_i64_slot(i64 %index) {
entry:
  %slot = alloca i64, align 8
  %heap = call noalias ptr @calloc(i64 16, i64 1)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  %bits = ptrtoint ptr %heap to i64
  store i64 %bits, ptr %slot, align 8
  %slot.bits = load i64, ptr %slot, align 8
  %address = add i64 %index, %slot.bits
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4096
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %address
  %resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  store volatile i8 1, ptr %resolver, align 1
  ; CHECK-LABEL: define void @positive_serialized_i64_slot
  ; CHECK: %slot.bits = load i64, ptr %slot, align 8
  ; CHECK: %brighten.heap.index = sub i64 %address, %slot.bits
  ; CHECK: %brighten.heap.gep = getelementptr i8, ptr %heap, i64 %brighten.heap.index
  ; CHECK-NOT: %resolver = select
  br label %done
done:
  ret void
}

; Equivalent serialized loads merged at a phi retain one allocation root.
define void @positive_serialized_i64_slot_same_origin_phi(i1 %choose, i64 %index) {
entry:
  %slot = alloca i64, align 8
  %heap = call noalias ptr @malloc(i64 16)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %stored, label %done
stored:
  %bits = ptrtoint ptr %heap to i64
  store i64 %bits, ptr %slot, align 8
  br i1 %choose, label %left, label %right
left:
  %left.bits = load i64, ptr %slot, align 8
  br label %merge
right:
  %right.bits = load i64, ptr %slot, align 8
  br label %merge
merge:
  %merged.bits = phi i64 [ %left.bits, %left ], [ %right.bits, %right ]
  %address = add i64 %merged.bits, %index
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4096
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %address
  %resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  store volatile i8 1, ptr %resolver, align 1
  ; CHECK-LABEL: define void @positive_serialized_i64_slot_same_origin_phi
  ; CHECK: %brighten.heap.gep = getelementptr i8, ptr %heap
  ; CHECK-NOT: %resolver = select
  br label %done
done:
  ret void
}

define void @reject_serialized_i64_mixed_trunc_observed_and_atomic(i1 %choose) {
entry:
  %slot = alloca i64, align 8
  %heap = call noalias ptr @malloc(i64 16)
  %other = call noalias ptr @malloc(i64 16)
  %heap.bits = ptrtoint ptr %heap to i64
  %other.bits = ptrtoint ptr %other to i64
  store i64 %heap.bits, ptr %slot, align 8
  %first = load i64, ptr %slot, align 8
  %mixed = select i1 %choose, i64 %first, i64 %other.bits
  %address = add i64 %mixed, 0
  %fallback = inttoptr i64 %address to ptr
  %delta = add i64 %address, -4096
  %in.image = icmp ult i64 %delta, 16
  %mapped = getelementptr i8, ptr getelementptr (i8, ptr @image, i64 -4096), i64 %address
  %mixed.resolver = select i1 %in.image, ptr %mapped, ptr %fallback
  ; CHECK-LABEL: define void @reject_serialized_i64_mixed_trunc_observed_and_atomic
  ; CHECK: %mixed.resolver = select
  %truncated = trunc i64 %first to i32
  %observed = icmp ult i64 %first, 7
  store atomic i64 %heap.bits, ptr %slot unordered, align 8
  %atomic = load atomic i64, ptr %slot unordered, align 8
  %sink.bits = add i64 %atomic, 0
  br i1 %observed, label %done, label %done
done:
  ret void
}

!0 = !{i64 4096, i64 4112}
!1 = !{i64 4104, i64 4120}
!2 = !{i64 0, i64 16}
