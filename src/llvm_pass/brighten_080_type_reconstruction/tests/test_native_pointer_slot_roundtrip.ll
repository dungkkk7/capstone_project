target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK-LABEL: define void @store_malloc_element(i3 %input)
; CHECK: %saved.bits = load i64, ptr %slot, align 8
; CHECK: %brighten.native.index = sdiv exact i64 %scaled, 4
; CHECK: %brighten.native.gep = getelementptr i32, ptr %mem, i64 %brighten.native.index
; CHECK: store i32 17, ptr %brighten.native.gep, align 4
; CHECK-NOT: inttoptr
; CHECK-NOT: native.address.fallback

declare noalias ptr @malloc(i64) #0

define void @store_malloc_element(i3 %input) {
entry:
  %slot = alloca i64, align 8
  %mem = call noalias ptr @malloc(i64 32)
  %bits = ptrtoint ptr %mem to i64
  store i64 %bits, ptr %slot, align 8
  %is.null = icmp eq ptr %mem, null
  br i1 %is.null, label %exit, label %body

body:
  %saved.bits = load i64, ptr %slot, align 8
  %bounded = zext i3 %input to i64
  %scaled = shl nuw nsw i64 %bounded, 2
  %address = add nuw i64 %saved.bits, %scaled
  %native.address.fallback = inttoptr i64 %address to ptr
  store i32 17, ptr %native.address.fallback, align 4
  br label %exit

exit:
  ret void
}

attributes #0 = { allocsize(0) allockind("alloc,uninitialized") }
