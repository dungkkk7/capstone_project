; Remill dispatchers are not public entry points.  Internal linkage lets the
; normal global DCE remove this unreachable dispatcher/lifted SCC before it
; can keep shared State artificially live in subsequent recovery passes.

define internal void @work.native() {
entry:
  ret void
}

define ptr @__remill_jump(ptr %state, i64 %pc, ptr %memory) {
entry:
  %next = call ptr @sub_dead(ptr %state, i64 %pc, ptr %memory)
  ret ptr %next
}

define internal ptr @sub_dead(ptr %state, i64 %pc, ptr %memory) {
entry:
  %next = call ptr @__remill_jump(ptr %state, i64 %pc, ptr %memory)
  ret ptr %next
}

; CHECK-NOT: define {{.*}}@__remill_jump
; CHECK-NOT: define {{.*}}@sub_dead
