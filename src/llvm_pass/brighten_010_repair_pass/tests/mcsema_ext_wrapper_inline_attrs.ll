define internal ptr @ext_1000_malloc(ptr %state, i64 %pc, ptr %memory) noinline {
entry:
  ret ptr %memory
}

define internal ptr @sub_2000(ptr %state, i64 %pc, ptr %memory) noinline {
entry:
  %next = call ptr @ext_1000_malloc(ptr %state, i64 %pc, ptr %memory)
  ret ptr %next
}

; CHECK-LABEL: define internal ptr @ext_1000_malloc
; CHECK-SAME: #[[EXT_ATTR:[0-9]+]]
; CHECK-LABEL: define internal ptr @sub_2000
; CHECK-SAME: #[[SUB_ATTR:[0-9]+]]
; CHECK: attributes #[[EXT_ATTR]] = { alwaysinline
; CHECK: attributes #[[SUB_ATTR]] = { noinline
