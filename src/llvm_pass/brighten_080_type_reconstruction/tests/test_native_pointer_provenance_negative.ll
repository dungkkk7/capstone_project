target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK-LABEL: define i32 @mixed_guest_native
; CHECK: %mixed = phi i64 [ %bits, %native ], [ 4096, %guest ]
; CHECK: %native.address.fallback.mixed = inttoptr i64 %mixed to ptr
; CHECK-LABEL: define i32 @possibly_wrapping
; CHECK: %address = add i64 %bits, %offset
; CHECK: %native.address.fallback.wrap = inttoptr i64 %address to ptr

declare noalias ptr @malloc(i64) #0

define i32 @mixed_guest_native(i1 %choose.native) {
entry:
  %mem = call noalias ptr @malloc(i64 16)
  %bits = ptrtoint ptr %mem to i64
  br i1 %choose.native, label %native, label %guest

native:
  br label %join

guest:
  br label %join

join:
  %mixed = phi i64 [ %bits, %native ], [ 4096, %guest ]
  %native.address.fallback.mixed = inttoptr i64 %mixed to ptr
  %value = load i32, ptr %native.address.fallback.mixed, align 4
  ret i32 %value
}

define i32 @possibly_wrapping(i64 %offset) {
entry:
  %mem = call noalias ptr @malloc(i64 16)
  %bits = ptrtoint ptr %mem to i64
  %is.null = icmp eq ptr %mem, null
  br i1 %is.null, label %exit, label %body

body:
  %address = add i64 %bits, %offset
  %native.address.fallback.wrap = inttoptr i64 %address to ptr
  %value = load i32, ptr %native.address.fallback.wrap, align 4
  br label %exit

exit:
  %result = phi i32 [ 0, %entry ], [ %value, %body ]
  ret i32 %result
}

attributes #0 = { allocsize(0) allockind("alloc,uninitialized") }
