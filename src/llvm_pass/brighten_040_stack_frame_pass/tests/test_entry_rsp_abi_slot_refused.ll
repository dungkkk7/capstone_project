; The first word below entry RSP is an ABI spill/control slot.  It may look
; locally initialized, but moving it to an alloca splits its State-visible
; boundary from the recovered frame.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_1008(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp = load i64, ptr %rsp.ptr, align 8
  br label %body

body:
  %rbp.ptr = getelementptr i8, ptr %state, i64 2328
  %rbp = load i64, ptr %rbp.ptr, align 8
  %abi.addr = sub i64 %rsp, 8
  %abi.ptr = call ptr @__translate_guest_pointer(i64 %abi.addr, i1 true)
  store i64 %rbp, ptr %abi.ptr, align 8
  %value = load i64, ptr %abi.ptr, align 8
  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %value, ptr %rax.ptr, align 8
  ret ptr %memory
}
