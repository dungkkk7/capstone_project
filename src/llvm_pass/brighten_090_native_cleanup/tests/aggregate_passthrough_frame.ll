; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-native-cleanup-post-souper-pass,verify' -S %s | FileCheck-21 %s
;
; Recovered ABI tuples frequently return RBP/RSP fields unchanged.  Forward
; the direct field through calls and aggregate PHIs so equivalent frame roots
; use one SSA value and can be compacted normally.

define internal { i64 } @passthrough(i64 %state) {
entry:
  %result = insertvalue { i64 } poison, i64 %state, 0
  ret { i64 } %result
}

define i32 @main(i1 %choose) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %frame_top = getelementptr inbounds i8, ptr %frame_storage, i64 2096896
  %anchor = ptrtoint ptr %frame_top to i64
  %state = add i64 %anchor, -32
  br i1 %choose, label %left, label %right

left:
  %left.result = call { i64 } @passthrough(i64 %state)
  br label %merge

right:
  %right.result = call { i64 } @passthrough(i64 %state)
  br label %merge

merge:
  %aggregate = phi { i64 } [ %left.result, %left ], [ %right.result, %right ]
  %returned.state = extractvalue { i64 } %aggregate, 0
  %delta = sub i64 %returned.state, %anchor
  %slot = getelementptr i8, ptr %frame_top, i64 %delta
  store i32 47, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: alloca [2097152 x i8]
; CHECK-NOT: extractvalue
; CHECK: %native_frame.compact = alloca
; CHECK: ret i32

