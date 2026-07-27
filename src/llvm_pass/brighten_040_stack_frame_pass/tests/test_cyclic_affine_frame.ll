; A memory-carried flattened dispatcher hides the local byte initialization
; from LLVM dominance.  The RSP/RBP transition and complete frame boundary are
; nevertheless finite and invariant around the cycle.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_6000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state_2312 = alloca i64, align 8, !brighten.state.offset !0
  %state_2328 = alloca i64, align 8, !brighten.state.offset !1
  %flag.result = alloca i8, align 1
  %unrelated.undef = freeze i64 undef
  %unrelated.poison = freeze i64 poison
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rbp.ptr = getelementptr i8, ptr %state, i64 2328
  %rsp.initial = load i64, ptr %rsp.ptr, align 8
  %rbp.initial = load i64, ptr %rbp.ptr, align 8
  store i64 %rsp.initial, ptr %state_2312, align 8
  store i64 %rbp.initial, ptr %state_2328, align 8

  %frame.rbp = sub i64 %rsp.initial, 8
  %frame.rsp = sub i64 %rsp.initial, 48
  store i64 %frame.rbp, ptr %state_2328, align 8
  store i64 %frame.rsp, ptr %state_2312, align 8

  %saved.ptr = call ptr @__translate_guest_pointer(i64 %frame.rbp, i1 true)
  store i64 %rbp.initial, ptr %saved.ptr, align 8

  %addr.1 = sub i64 %frame.rbp, 8
  %ptr.1 = call ptr @__translate_guest_pointer(i64 %addr.1, i1 true)
  store i64 11, ptr %ptr.1, align 8
  %value.1 = load i64, ptr %ptr.1, align 8

  %addr.2 = sub i64 %frame.rbp, 16
  %ptr.2 = call ptr @__translate_guest_pointer(i64 %addr.2, i1 true)
  store i64 22, ptr %ptr.2, align 8
  %value.2 = load i64, ptr %ptr.2, align 8

  %addr.3 = sub i64 %frame.rbp, 24
  %ptr.3 = call ptr @__translate_guest_pointer(i64 %addr.3, i1 true)
  store i64 33, ptr %ptr.3, align 8
  %value.3 = load i64, ptr %ptr.3, align 8

  %flag.addr = sub i64 %frame.rbp, 33
  %flag.ptr = call ptr @__translate_guest_pointer(i64 %flag.addr, i1 true)
  %dispatch.addr = sub i64 %frame.rbp, 32
  %dispatch.ptr = call ptr @__translate_guest_pointer(i64 %dispatch.addr, i1 true)
  store i32 0, ptr %dispatch.ptr, align 4
  br label %dispatcher

dispatcher:
  %state.code = load i32, ptr %dispatch.ptr, align 4
  switch i32 %state.code, label %exit [
    i32 0, label %write.flag
    i32 1, label %read.flag
  ]

write.flag:
  store i8 1, ptr %flag.ptr, align 1
  store i32 1, ptr %dispatch.ptr, align 4
  br label %dispatcher

read.flag:
  %flag = load i8, ptr %flag.ptr, align 1
  store i8 %flag, ptr %flag.result, align 1
  store i32 2, ptr %dispatch.ptr, align 4
  br label %dispatcher

exit:
  %saved.rbp = load i64, ptr %saved.ptr, align 8
  store i64 %saved.rbp, ptr %state_2328, align 8
  %return.rsp = add i64 %rsp.initial, 8
  store i64 %return.rsp, ptr %state_2312, align 8
  %sum.1 = add i64 %value.1, %value.2
  %sum.2 = add i64 %sum.1, %value.3
  %final.flag = load i8, ptr %flag.result, align 1
  %flag.ext = zext i8 %final.flag to i64
  %result = add i64 %sum.2, %flag.ext
  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %result, ptr %rax.ptr, align 8
  ret ptr %memory
}

!0 = !{i64 2312}
!1 = !{i64 2328}
