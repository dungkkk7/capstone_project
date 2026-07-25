; Constant offsets alone do not prove that a large lifted frame is an
; independent function-local object.  Keep it in guest storage until an
; interprocedural object-separation proof is available.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_5000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state_2312 = alloca i64, align 8, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.initial = load i64, ptr %rsp.ptr, align 8
  store i64 %rsp.initial, ptr %state_2312, align 8
  %rsp = load i64, ptr %state_2312, align 8

  %addr.1 = sub i64 %rsp, 8
  %ptr.1 = call ptr @__translate_guest_pointer(i64 %addr.1, i1 true)
  store i64 1, ptr %ptr.1, align 8
  %value.1 = load i64, ptr %ptr.1, align 8

  %addr.2 = sub i64 %rsp, 16
  %ptr.2 = call ptr @__translate_guest_pointer(i64 %addr.2, i1 true)
  store i64 2, ptr %ptr.2, align 8
  %value.2 = load i64, ptr %ptr.2, align 8

  %addr.3 = sub i64 %rsp, 24
  %ptr.3 = call ptr @__translate_guest_pointer(i64 %addr.3, i1 true)
  store i64 3, ptr %ptr.3, align 8
  %value.3 = load i64, ptr %ptr.3, align 8

  %addr.4 = sub i64 %rsp, 32
  %ptr.4 = call ptr @__translate_guest_pointer(i64 %addr.4, i1 true)
  store i64 4, ptr %ptr.4, align 8
  %value.4 = load i64, ptr %ptr.4, align 8

  %addr.5 = sub i64 %rsp, 40
  %ptr.5 = call ptr @__translate_guest_pointer(i64 %addr.5, i1 true)
  store i64 5, ptr %ptr.5, align 8
  %value.5 = load i64, ptr %ptr.5, align 8

  %sum.1 = add i64 %value.1, %value.2
  %sum.2 = add i64 %value.3, %value.4
  %sum.3 = add i64 %sum.1, %sum.2
  %sum.4 = add i64 %sum.3, %value.5
  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %sum.4, ptr %rax.ptr, align 8
  ret ptr %memory
}

!0 = !{i64 2312}
