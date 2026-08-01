target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@backing = internal global [128 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !0
@image = internal global [256 x i8] zeroinitializer, align 16,
  !brighten.guest.range !1
@scan = private constant [3 x i8] c"%s\00"

declare noalias ptr @calloc(i64, i64) allocsize(0,1) allockind("alloc,zeroed")
declare i32 @scanf(ptr, ...)
declare i64 @strlen(ptr captures(none))
declare void @free(ptr captures(none))

define void @lifecycle_owner() !brighten.entry_single_invocation !2 {
entry:
  %heap = call noalias ptr @calloc(i64 16, i64 1)
  %nonnull = icmp ne ptr %heap, null
  br i1 %nonnull, label %use, label %done
use:
  ; 060 is the only producer of this proof.  The serialized checkpoint must
  ; retain it so 080 may admit the direct destination call without a name
  ; heuristic or a vararg exception.
  %scan.result = call i32 (ptr, ...) @scanf(ptr @scan, ptr %heap)
  %slot = getelementptr inbounds [128 x i8], ptr @backing, i64 0, i64 56
  %bits = ptrtoint ptr %heap to i64
  store i64 %bits, ptr %slot, align 8
  %raw = load i64, ptr %slot, align 8
  %fallback = inttoptr i64 %raw to ptr
  %delta = add i64 %raw, -1024
  %in.range = icmp ult i64 %delta, 256
  %dynamic = getelementptr i8, ptr @image, i64 %raw
  %candidate = getelementptr i8, ptr %dynamic, i64 -1024
  %resolver = select i1 %in.range, ptr %candidate, ptr %fallback
  %n = call i64 @strlen(ptr %resolver)
  call void @free(ptr %resolver)
  ; CHECK-LABEL: define void @lifecycle_owner()
  ; CHECK: %native.pointer.slot = alloca ptr, align 8
  ; CHECK: call i32 (ptr, ...) @scanf(ptr @scan, ptr captures(none) %heap)
  ; CHECK: store ptr %heap, ptr %native.pointer.slot, align 8
  ; CHECK: %n = call i64 @strlen(ptr %heap)
  ; CHECK: call void @free(ptr %heap)
  ; CHECK-NOT: %resolver = select
  ; CHECK-NOT: @backing
  br label %done
done:
  ret void
}

!0 = !{ptr @lifecycle_owner, i32 1}
!1 = !{i64 1024, i64 1280}
!2 = !{!"v1", !"attach_direct_unique"}
