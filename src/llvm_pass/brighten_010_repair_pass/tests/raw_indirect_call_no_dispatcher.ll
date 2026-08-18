; CHECK-LABEL: define ptr @sub_1000
; CHECK-LABEL: fallback:
; CHECK-NOT: call i64 %fp
; CHECK: ret ptr %memory

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
  ret ptr %memory
}
