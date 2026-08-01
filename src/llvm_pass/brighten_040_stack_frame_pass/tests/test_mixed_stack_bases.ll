; Two unresolved base identities may alias the same physical guest frame.
; Preserve both until their affine relationship is proven.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_4000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state_2312 = alloca i64, align 8, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.initial = load i64, ptr %rsp.ptr, align 8
  store i64 %rsp.initial, ptr %state_2312, align 8
  %rsp = load i64, ptr %state_2312, align 8
  %local.addr = sub i64 %rsp, 16
  %local.ptr = call ptr @__translate_guest_pointer(i64 %local.addr, i1 true)
  store i64 42, ptr %local.ptr, align 8
  %local = load i64, ptr %local.ptr, align 8

  store i64 %pc, ptr %state_2312, align 8
  %other.rsp = load i64, ptr %state_2312, align 8
  %other.addr = sub i64 %other.rsp, 32
  %other.ptr = call ptr @__translate_guest_pointer(i64 %other.addr, i1 true)
  store i64 %local, ptr %other.ptr, align 8
  ret ptr %memory
}

!0 = !{i64 2312}
