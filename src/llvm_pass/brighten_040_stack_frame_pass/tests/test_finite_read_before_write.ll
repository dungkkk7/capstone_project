; A finite affine frame does not establish initialization order.  State 0 can
; read the flag before state 1 writes it, so the incoming guest byte must remain
; observable even though another feasible path contains a covering write.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_6100(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state_2312 = alloca i64, align 8, !brighten.state.offset !0
  %flag.result = alloca i8, align 1
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.initial = load i64, ptr %rsp.ptr, align 8
  store i64 %rsp.initial, ptr %state_2312, align 8
  %frame.rsp = sub i64 %rsp.initial, 48
  store i64 %frame.rsp, ptr %state_2312, align 8

  %addr.1 = sub i64 %rsp.initial, 8
  %ptr.1 = call ptr @__translate_guest_pointer(i64 %addr.1, i1 true)
  store i64 11, ptr %ptr.1, align 8
  %value.1 = load i64, ptr %ptr.1, align 8

  %addr.2 = sub i64 %rsp.initial, 16
  %ptr.2 = call ptr @__translate_guest_pointer(i64 %addr.2, i1 true)
  store i64 22, ptr %ptr.2, align 8
  %value.2 = load i64, ptr %ptr.2, align 8

  %addr.3 = sub i64 %rsp.initial, 24
  %ptr.3 = call ptr @__translate_guest_pointer(i64 %addr.3, i1 true)
  store i64 33, ptr %ptr.3, align 8
  %value.3 = load i64, ptr %ptr.3, align 8

  %addr.4 = sub i64 %rsp.initial, 32
  %ptr.4 = call ptr @__translate_guest_pointer(i64 %addr.4, i1 true)
  store i64 44, ptr %ptr.4, align 8
  %value.4 = load i64, ptr %ptr.4, align 8

  %flag.addr = sub i64 %rsp.initial, 33
  %flag.ptr = call ptr @__translate_guest_pointer(i64 %flag.addr, i1 true)
  %dispatch.addr = sub i64 %rsp.initial, 40
  %dispatch.ptr = call ptr @__translate_guest_pointer(i64 %dispatch.addr, i1 true)
  %start = trunc i64 %pc to i32
  %initial.state = and i32 %start, 1
  store i32 %initial.state, ptr %dispatch.ptr, align 4
  br label %dispatcher

dispatcher:
  %state.code = load i32, ptr %dispatch.ptr, align 4
  switch i32 %state.code, label %exit [
    i32 0, label %read.flag
    i32 1, label %write.flag
  ]

write.flag:
  store i8 1, ptr %flag.ptr, align 1
  store i32 0, ptr %dispatch.ptr, align 4
  br label %dispatcher

read.flag:
  %flag = load i8, ptr %flag.ptr, align 1
  store i8 %flag, ptr %flag.result, align 1
  store i32 2, ptr %dispatch.ptr, align 4
  br label %dispatcher

exit:
  %return.rsp = add i64 %rsp.initial, 8
  store i64 %return.rsp, ptr %state_2312, align 8
  %final.flag = load i8, ptr %flag.result, align 1
  %flag.ext = zext i8 %final.flag to i64
  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %flag.ext, ptr %rax.ptr, align 8
  ret ptr %memory
}

!0 = !{i64 2312}
