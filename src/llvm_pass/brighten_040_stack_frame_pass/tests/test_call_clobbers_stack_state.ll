; A lifted callee returns its updated RSP/RBP through architectural State.
; Stack recovery must not reuse the caller's pre-call affine stack expression
; for accesses derived from a post-call register reload.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define internal ptr @sub_callee(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @sub_caller(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.before = load i64, ptr %rsp.ptr, align 8
  %before.addr = sub i64 %rsp.before, 8
  %before.ptr = call ptr @__translate_guest_pointer(i64 %before.addr, i1 true)
  store i64 1, ptr %before.ptr, align 8

  %next.memory = call ptr @sub_callee(ptr %state, i64 %pc, ptr %memory)

  %rsp.after = load i64, ptr %rsp.ptr, align 8
  %after.addr = sub i64 %rsp.after, 8
  %after.ptr = call ptr @__translate_guest_pointer(i64 %after.addr, i1 true)
  store i64 2, ptr %after.ptr, align 8
  ret ptr %next.memory
}
