; CHECK-LABEL: define ptr @sub_1000
; CHECK: switch i64 %target, label %fallback [
; CHECK: i64 8192, label %inst_done
; CHECK: i64 4101, label %inst_done
; CHECK-LABEL: inst_done:
; CHECK: phi ptr [ %m0, %dispatch ], [ %bad, %inst_1000 ], [ %m0, %dispatch ]
; CHECK-NOT: [ %bad, %dispatch ]

@slot_phi_dom = global i64 0

declare ptr @make_memory(ptr, i64, ptr)
declare ptr @ext_side_effect(ptr, i64, ptr)
declare ptr @ext_exit(ptr, i64, ptr)

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory, i64 %target) {
entry:
  %m0 = call ptr @make_memory(ptr %state, i64 undef, ptr %memory)
  br label %dispatch

dispatch:
  switch i64 %target, label %fallback [
    i64 4096, label %inst_1000
    i64 8192, label %inst_done
  ]

inst_1000:
  %bad = call ptr @ext_side_effect(ptr %state, i64 undef, ptr %m0)
  store i64 4101, ptr @slot_phi_dom
  %after_exit = call ptr @ext_exit(ptr %state, i64 undef, ptr %bad)
  br label %inst_done

inst_done:
  %p = phi ptr [ %m0, %dispatch ], [ %bad, %inst_1000 ]
  ret ptr %p

fallback:
  ret ptr %memory
}
