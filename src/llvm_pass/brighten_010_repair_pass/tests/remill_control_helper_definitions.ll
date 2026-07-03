declare ptr @__remill_async_hyper_call(ptr, i64, ptr)
declare ptr @__remill_function_return(ptr, i64, ptr)

define ptr @uses_async(ptr %state, i64 %pc, ptr %mem) {
entry:
  %out = call ptr @__remill_async_hyper_call(ptr %state, i64 %pc, ptr %mem)
  ret ptr %out
}

; CHECK: define ptr @__remill_async_hyper_call(ptr %0, i64 %1, ptr %2)
; CHECK-NEXT: entry:
; CHECK-NEXT: ret ptr %2
; CHECK-NOT: define ptr @__remill_function_return
