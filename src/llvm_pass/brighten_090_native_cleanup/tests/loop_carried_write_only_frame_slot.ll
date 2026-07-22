; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-native-cleanup-post-souper-pass,verify' -S %s | FileCheck-21 %s
;
; A loop-carried recovered RSP can remain dynamic after CFG recovery.  The
; decreasing recurrence is nevertheless bounded above, so its store-only
; call-frame slot cannot alias the fixed entry-frame slot.  A positive cycle
; has no finite upper bound and must remain fail-closed.

define i32 @decreasing_rsp(i1 %again) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %frame_top = getelementptr inbounds i8, ptr %frame_storage, i64 2096896
  %anchor = ptrtoint ptr %frame_top to i64
  %initial = add i64 %anchor, -256
  %fixed = getelementptr i8, ptr %frame_top, i64 -64
  store i32 17, ptr %fixed, align 4
  br label %loop

loop:
  %rsp = phi i64 [ %initial, %entry ], [ %next, %loop ]
  %delta = sub i64 %rsp, %anchor
  %dynamic = getelementptr i8, ptr %frame_top, i64 %delta
  store i64 99, ptr %dynamic, align 1
  %next = add i64 %rsp, -16
  br i1 %again, label %loop, label %exit

exit:
  %value = load i32, ptr %fixed, align 4
  ret i32 %value
}

define i32 @increasing_rsp_may_alias(i1 %again) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %frame_top = getelementptr inbounds i8, ptr %frame_storage, i64 2096896
  %anchor = ptrtoint ptr %frame_top to i64
  %initial = add i64 %anchor, -256
  %fixed = getelementptr i8, ptr %frame_top, i64 -64
  store i32 23, ptr %fixed, align 4
  br label %loop

loop:
  %rsp = phi i64 [ %initial, %entry ], [ %next, %loop ]
  %delta = sub i64 %rsp, %anchor
  %dynamic = getelementptr i8, ptr %frame_top, i64 %delta
  store i64 101, ptr %dynamic, align 1
  %next = add i64 %rsp, 16
  br i1 %again, label %loop, label %exit

exit:
  %value = load i32, ptr %fixed, align 4
  ret i32 %value
}

; CHECK-LABEL: define i32 @decreasing_rsp(
; CHECK-NOT: frame_storage
; CHECK-NOT: store i64 99
; CHECK: ret i32
;
; CHECK-LABEL: define i32 @increasing_rsp_may_alias(
; CHECK: %frame_storage = alloca [2097152 x i8]
; CHECK: store i64 101
; CHECK: ret i32
