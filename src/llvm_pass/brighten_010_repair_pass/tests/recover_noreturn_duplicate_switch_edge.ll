; CHECK-LABEL: define ptr @sub_1000
; CHECK: switch i64 %target, label %fallback [
; CHECK: i64 8192, label %inst_done
; CHECK: i64 4101, label %inst_done
; CHECK-LABEL: inst_done:
; CHECK: phi i64 [ 7, %entry ], [ 42, %inst_1000 ], [ 7, %entry ]

@slot_dup = global i64 0

declare ptr @ext_2000___assert_fail(ptr, i64, ptr)

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory, i64 %target) {
entry:
  switch i64 %target, label %fallback [
    i64 4096, label %inst_1000
    i64 8192, label %inst_done
  ]

inst_1000:
  store i64 4101, ptr @slot_dup
  %m1 = call ptr @ext_2000___assert_fail(ptr %state, i64 undef, ptr %memory)
  br label %inst_done

inst_done:
  %x = phi i64 [ 7, %entry ], [ 42, %inst_1000 ]
  ret ptr %memory

fallback:
  ret ptr %memory
}
