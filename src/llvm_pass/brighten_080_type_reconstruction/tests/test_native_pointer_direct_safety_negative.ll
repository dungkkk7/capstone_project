target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Direct native-pointer recovery must refuse every case below.  The source
; provenance is unique and offsets are in bounds, so each CHECK exercises one
; specific missing proof rather than range/object ambiguity.

; CHECK-LABEL: define i32 @volatile_access()
; CHECK: %native.address.fallback.volatile = inttoptr i64 %address to ptr
; CHECK: load volatile i32, ptr %native.address.fallback.volatile, align 4
define i32 @volatile_access() {
entry:
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  %address = add nuw i64 %bits, 0
  %native.address.fallback.volatile = inttoptr i64 %address to ptr
  %value = load volatile i32, ptr %native.address.fallback.volatile, align 4
  ret i32 %value
}

; CHECK-LABEL: define void @atomic_access()
; CHECK: %native.address.fallback.atomic = inttoptr i64 %address to ptr
; CHECK: store atomic i32 7, ptr %native.address.fallback.atomic release, align 4
define void @atomic_access() {
entry:
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  %address = add nuw i64 %bits, 0
  %native.address.fallback.atomic = inttoptr i64 %address to ptr
  store atomic i32 7, ptr %native.address.fallback.atomic release, align 4
  ret void
}

; CHECK-LABEL: define i32 @captured_root()
; CHECK: call void @capture(ptr %mem)
; CHECK: %native.address.fallback.capture = inttoptr i64 %address to ptr
define i32 @captured_root() {
entry:
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  call void @capture(ptr %mem)
  %address = add nuw i64 %bits, 0
  %native.address.fallback.capture = inttoptr i64 %address to ptr
  %value = load i32, ptr %native.address.fallback.capture, align 4
  ret i32 %value
}

; CHECK-LABEL: define i1 @integer_address_observed()
; CHECK: %bits.observed = icmp eq i64 %bits, 0
; CHECK: %native.address.fallback.observed = inttoptr i64 %address to ptr
define i1 @integer_address_observed() {
entry:
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  %bits.observed = icmp eq i64 %bits, 0
  %address = add nuw i64 %bits, 0
  %native.address.fallback.observed = inttoptr i64 %address to ptr
  %value = load i32, ptr %native.address.fallback.observed, align 4
  %nonzero = icmp ne i32 %value, 0
  %result = xor i1 %bits.observed, %nonzero
  ret i1 %result
}

; CHECK-LABEL: define i1 @pointer_address_compared()
; CHECK: %native.address.fallback.pointer_cmp = inttoptr i64 %address to ptr
; CHECK: %same = icmp eq ptr %native.address.fallback.pointer_cmp, %mem
define i1 @pointer_address_compared() {
entry:
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  %address = add nuw i64 %bits, 0
  %native.address.fallback.pointer_cmp = inttoptr i64 %address to ptr
  %same = icmp eq ptr %native.address.fallback.pointer_cmp, %mem
  ret i1 %same
}

; CHECK-LABEL: define i32 @tagged_address()
; CHECK: %tagged = or i64 %bits, 1
; CHECK: %native.address.fallback.tagged = inttoptr i64 %tagged to ptr
define i32 @tagged_address() {
entry:
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  %tagged = or i64 %bits, 1
  %native.address.fallback.tagged = inttoptr i64 %tagged to ptr
  %value = load i32, ptr %native.address.fallback.tagged, align 1
  ret i32 %value
}

declare noalias ptr @malloc(i64) #0
declare void @capture(ptr)

attributes #0 = { allocsize(0) allockind("alloc,uninitialized") }
