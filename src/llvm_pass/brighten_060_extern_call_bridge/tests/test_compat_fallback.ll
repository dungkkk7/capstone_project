; Test: FIX #2 — CompatFallback should work with declaration-only __translate_guest_pointer

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]

; Declaration only — should be accepted in compat mode
declare ptr @__translate_guest_pointer(i64, i1)

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @puts(ptr)

; In NativeStrict this would be skipped (guest address).
; In CompatFallback it should use __translate_guest_pointer.
; Since the pass defaults to NativeStrict, this will be preserved.
; But the test verifies the declaration is properly accepted.
define ptr @sub_compat1(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  %guest = inttoptr i64 12345 to ptr
  store ptr %guest, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @puts to i64), ptr %mem)
  ret ptr %ret
}
