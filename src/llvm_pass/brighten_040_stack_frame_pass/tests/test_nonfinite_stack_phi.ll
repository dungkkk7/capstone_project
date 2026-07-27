; Undef-backed dispatcher PHIs and monotonically moving cyclic RSP values do
; not establish a finite frame.  Preserve their guest-memory accesses.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare ptr @__translate_guest_pointer(i64, i1)

define ptr @sub_7000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state_2312 = alloca i64, align 8, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.initial = load i64, ptr %rsp.ptr, align 8
  store i64 %rsp.initial, ptr %state_2312, align 8
  %frame = sub i64 %rsp.initial, 32
  br label %dispatcher

dispatcher:
  %unresolved.rsp = phi i64 [ %frame, %entry ], [ undef, %backedge ]
  store i64 %unresolved.rsp, ptr %state_2312, align 8
  %addr = sub i64 %unresolved.rsp, 8
  %ptr = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
  store i64 7, ptr %ptr, align 8
  %value = load i64, ptr %ptr, align 8
  %done = icmp eq i64 %pc, 0
  br i1 %done, label %exit, label %backedge

backedge:
  br label %dispatcher

exit:
  ret ptr %memory
}

define ptr @sub_7100(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state_2312 = alloca i64, align 8, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.initial = load i64, ptr %rsp.ptr, align 8
  store i64 %rsp.initial, ptr %state_2312, align 8
  %frame = sub i64 %rsp.initial, 32
  br label %loop

loop:
  %moving.rsp = phi i64 [ %frame, %entry ], [ %next.rsp, %loop ]
  store i64 %moving.rsp, ptr %state_2312, align 8
  %addr = sub i64 %moving.rsp, 8
  %ptr = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
  store i64 9, ptr %ptr, align 8
  %value = load i64, ptr %ptr, align 8
  %next.rsp = sub i64 %moving.rsp, 16
  %again = icmp ne i64 %value, %pc
  br i1 %again, label %loop, label %exit

exit:
  ret ptr %memory
}

!0 = !{i64 2312}
