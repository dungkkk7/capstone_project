; Safe negative offsets and preserved positive offsets share one guest base.
; The pass must not split that physical object without an alias proof.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_3000(ptr %state, i64 %pc, ptr %memory) {
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

  %shared.addr = add i64 %rsp, 8
  %shared.ptr = call ptr @__translate_guest_pointer(i64 %shared.addr, i1 true)
  store i64 %local, ptr %shared.ptr, align 8
  ret ptr %memory
}

!0 = !{i64 2312}
