; A guest GOT/segment slot may be updated through __translate_guest_pointer,
; which is invisible in the LLVM use-list of the backing global.  Its zero
; initializer is therefore not proof that a later indirect PC is zero.

%segment = type { [8 x i8], i64 }

@guest_segment = internal global %segment zeroinitializer
@guest_pc = internal alias i8, getelementptr inbounds (%segment, ptr @guest_segment, i32 0, i32 1)

declare ptr @__remill_jump(ptr, i64, ptr)

define ptr @sub_dynamic_jump(ptr %state, i64 %pc, ptr %memory) {
entry:
  %target = load i64, ptr @guest_pc, align 8
  %next = call ptr @__remill_jump(ptr %state, i64 %target, ptr %memory)
  ret ptr %next
}

; CHECK-LABEL: define ptr @sub_dynamic_jump
; CHECK: %target = load i64, ptr @guest_pc
; CHECK: %next = call ptr @__remill_jump(ptr %state, i64 %target, ptr %memory)
; CHECK: ret ptr %next
