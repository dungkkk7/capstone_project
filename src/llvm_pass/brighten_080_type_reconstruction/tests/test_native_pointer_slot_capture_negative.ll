target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@saved_slot = internal global ptr null

; CHECK-LABEL: define i32 @captured_by_call()
; CHECK: call void @capture_slot(ptr %slot)
; CHECK: call void @hidden_clobber()
; CHECK: %native.address.fallback.call_capture = inttoptr i64 %saved.bits to ptr
; CHECK-LABEL: define i32 @captured_by_global()
; CHECK: store ptr %slot, ptr @saved_slot
; CHECK: call void @hidden_clobber()
; CHECK: %native.address.fallback.global_capture = inttoptr i64 %saved.bits to ptr

declare noalias ptr @malloc(i64) #0
declare void @capture_slot(ptr)
declare void @hidden_clobber()

define i32 @captured_by_call() {
entry:
  %slot = alloca i64, align 8
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  call void @capture_slot(ptr %slot)
  store i64 %bits, ptr %slot, align 8
  call void @hidden_clobber()
  %saved.bits = load i64, ptr %slot, align 8
  %native.address.fallback.call_capture = inttoptr i64 %saved.bits to ptr
  %value = load i32, ptr %native.address.fallback.call_capture, align 4
  ret i32 %value
}

define i32 @captured_by_global() {
entry:
  %slot = alloca i64, align 8
  %mem = call noalias ptr @malloc(i64 4)
  %bits = ptrtoint ptr %mem to i64
  store ptr %slot, ptr @saved_slot, align 8
  store i64 %bits, ptr %slot, align 8
  call void @hidden_clobber()
  %saved.bits = load i64, ptr %slot, align 8
  %native.address.fallback.global_capture = inttoptr i64 %saved.bits to ptr
  %value = load i32, ptr %native.address.fallback.global_capture, align 4
  ret i32 %value
}

attributes #0 = { allocsize(0) allockind("alloc,uninitialized") }
