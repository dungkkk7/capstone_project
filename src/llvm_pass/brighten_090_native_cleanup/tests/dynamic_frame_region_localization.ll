; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-native-cleanup-post-souper-pass,verify' -S %s | FileCheck-21 %s
;
; Two branch arms initialize the same logical callee-local slot.  Neither
; store individually dominates the merged read, but the slot is must-written
; on every path.  The dynamic frame roots use only the structural
; logical-address-minus-anchor form emitted by State SSA.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %frame_top = getelementptr inbounds i8, ptr %frame_storage, i64 2096896
  %anchor = ptrtoint ptr %frame_top to i64
  %logical = add i64 %anchor, -64
  %delta.a = sub i64 %logical, %anchor
  %root.a = getelementptr i8, ptr %frame_top, i64 %delta.a
  %slot.a = getelementptr i8, ptr %root.a, i64 -8
  %condition = icmp ne i32 %argc, 0
  br i1 %condition, label %left, label %right

left:
  store i32 7, ptr %slot.a, align 4
  br label %merge

right:
  %delta.b = sub i64 %logical, %anchor
  %root.b = getelementptr i8, ptr %frame_top, i64 %delta.b
  %slot.b = getelementptr i8, ptr %root.b, i64 -8
  store i32 9, ptr %slot.b, align 4
  br label %merge

merge:
  %value = load i32, ptr %slot.a, align 4
  %dead.logical = add i64 %logical, -256
  %dead.delta = sub i64 %dead.logical, %anchor
  %dead.root = getelementptr i8, ptr %frame_top, i64 %dead.delta
  store i64 4660, ptr %dead.root, align 1
  ret i32 %value
}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: frame_storage
; CHECK-NOT: dead.root
; CHECK: ret i32
