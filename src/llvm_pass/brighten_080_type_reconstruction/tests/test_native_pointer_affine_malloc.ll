target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK-LABEL: define i32 @sum_malloc_array()
; CHECK: %brighten.native.index = sdiv exact i64 %scaled, 4
; CHECK: %brighten.native.gep = getelementptr i32, ptr %mem, i64 %brighten.native.index
; CHECK: %value = load i32, ptr %brighten.native.gep, align 4
; CHECK-NOT: inttoptr
; CHECK-NOT: native.address.fallback

declare noalias ptr @malloc(i64) #0

define i32 @sum_malloc_array() {
entry:
  %mem = call noalias ptr @malloc(i64 40)
  %bits = ptrtoint ptr %mem to i64
  %is.null = icmp eq ptr %mem, null
  br i1 %is.null, label %exit, label %loop

loop:
  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i32 [ 0, %entry ], [ %new.sum, %loop ]
  %scaled = shl nuw nsw i64 %index, 2
  %address = add nuw i64 %bits, %scaled
  %native.address.fallback = inttoptr i64 %address to ptr
  %value = load i32, ptr %native.address.fallback, align 4
  %new.sum = add i32 %sum, %value
  %next = add nuw nsw i64 %index, 1
  %done = icmp eq i64 %next, 10
  br i1 %done, label %exit, label %loop

exit:
  %result = phi i32 [ 0, %entry ], [ %new.sum, %loop ]
  ret i32 %result
}

attributes #0 = { allocsize(0) allockind("alloc,uninitialized") }
