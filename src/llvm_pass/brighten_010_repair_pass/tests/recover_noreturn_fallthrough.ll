; CHECK-LABEL: define ptr @sub_1000
; CHECK: switch i64 %target, label %fallback [
; CHECK: i64 4096, label %inst_1000
; CHECK: i64 4101, label %[[SPLIT:[^ ]+]]
; CHECK: [[SPLIT]]:
; CHECK: phi ptr [ %m1, %inst_1000 ], [ %memory, %entry ]
; CHECK: call ptr @ext_puts

@slot = global i64 0

declare ptr @ext_2000___assert_fail(ptr, i64, ptr)
declare ptr @ext_puts(ptr, i64, ptr)

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory, i64 %target) {
entry:
  switch i64 %target, label %fallback [
    i64 4096, label %inst_1000
    i64 8192, label %inst_2000
  ]

inst_1000:
  %ret_pc = add i64 %target, 5
  store i64 %ret_pc, ptr @slot
  %m1 = call ptr @ext_2000___assert_fail(ptr %state, i64 undef, ptr %memory)
  %m2 = call ptr @ext_puts(ptr %state, i64 undef, ptr %m1)
  ret ptr %m2

inst_2000:
  ret ptr %memory

fallback:
  ret ptr %memory
}
