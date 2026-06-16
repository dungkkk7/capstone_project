; CHECK-LABEL: define ptr @sub_48b6_test
; CHECK: %target = add i64 25276, %rel
; CHECK: switch i64 %target, label %fallback [
; CHECK: i64 19247, label %inst_4b2f
; CHECK: %delta = sub i64 20804, %target
; CHECK: switch i64 %delta64, label %miss [
; CHECK: i64 1557, label %inst_4b2f
; CHECK-NOT: ptrtoint (ptr @data_62bc to i64)
; CHECK-NOT: ptrtoint (ptr @data_5144 to i64)

@data_62bc = global [16 x i8] zeroinitializer
@data_5144 = global [1 x i8] zeroinitializer

define ptr @sub_48b6_test(ptr %state, i64 %pc, ptr %memory, i64 %idx) {
entry:
  %idx32 = trunc i64 %idx to i32
  %off = mul i32 %idx32, 4
  %slot = getelementptr i8, ptr @data_62bc, i32 %off
  %rel32 = load i32, ptr %slot, align 4
  %rel = sext i32 %rel32 to i64
  %target = add i64 ptrtoint (ptr @data_62bc to i64), %rel
  switch i64 %target, label %fallback [
    i64 19247, label %inst_4b2f
    i64 20466, label %inst_4ff2
  ]

fallback:
  %delta = sub i64 ptrtoint (ptr @data_5144 to i64), %target
  %delta32 = trunc i64 %delta to i32
  %delta64 = zext i32 %delta32 to i64
  switch i64 %delta64, label %miss [
    i64 1557, label %inst_4b2f
    i64 338, label %inst_4ff2
  ]

inst_4b2f:
  ret ptr %memory

inst_4ff2:
  ret ptr %memory

miss:
  ret ptr %memory
}
