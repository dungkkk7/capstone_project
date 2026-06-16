; CHECK-LABEL: define ptr @sub_1000
; CHECK-LABEL: fallback:
; CHECK-NOT: call i64 %fp
; CHECK: call ptr @__lifter_refine_resolve_indirect_call
; CHECK: ret ptr
; CHECK-LABEL: define internal ptr @__lifter_refine_resolve_indirect_call
; CHECK: call ptr @__lifter_refine_dispatch_sub_2000

@RAX = global i64 0
@RSP = global i64 0

define ptr @__lifter_refine_dispatch_sub_2000(ptr %state, i64 %pc, ptr %memory) #0 {
inst_1234:
  ret ptr %memory
}

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory, i64 %target) {
entry:
  switch i64 %target, label %fallback [
    i64 22136, label %inst_5678
    i64 39612, label %inst_9abc
  ]

inst_5678:
  ret ptr %memory

inst_9abc:
  ret ptr %memory

fallback:
  %fp = inttoptr i64 %target to ptr
  %r = call i64 %fp(i64 1, i64 2)
  store i64 %r, ptr @RAX
  store i64 8, ptr @RSP
  ret ptr %memory
}

attributes #0 = { "lifter.refine.remill_entry_dispatcher" }
