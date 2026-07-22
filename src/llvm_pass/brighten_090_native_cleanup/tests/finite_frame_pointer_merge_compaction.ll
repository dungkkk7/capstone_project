; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-native-cleanup-post-souper-pass,verify' -S %s | FileCheck-21 %s
;
; Fixed frame addresses may merge before a load/store.  Rebase the complete
; pointer graph so the control-dependent slot choice is preserved.  A merge
; containing any non-frame arm is an escape and must remain fail-closed.

define i32 @finite_frame_merge(i1 %choose) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %left.slot = getelementptr inbounds i8, ptr %frame_storage, i64 2096800
  %right.slot = getelementptr inbounds i8, ptr %frame_storage, i64 2096816
  br i1 %choose, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %slot = phi ptr [ %left.slot, %left ], [ %right.slot, %right ]
  store i32 41, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

define i32 @mixed_frame_merge(i1 %choose, ptr %external) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %frame.slot = getelementptr inbounds i8, ptr %frame_storage, i64 2096800
  br i1 %choose, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %slot = phi ptr [ %frame.slot, %left ], [ %external, %right ]
  store i32 43, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK-LABEL: define i32 @finite_frame_merge(
; CHECK-NOT: alloca [2097152 x i8]
; CHECK: %native_frame.compact = alloca
; CHECK: %slot = phi ptr [ %native.frame.root
; CHECK: ret i32
;
; CHECK-LABEL: define i32 @mixed_frame_merge(
; CHECK: %frame_storage = alloca [2097152 x i8]
; CHECK: %slot = phi ptr [ %frame.slot, %left ], [ %external, %right ]
; CHECK: ret i32
