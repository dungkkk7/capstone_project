@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@target_slot = global ptr null
@attach_slot = global ptr @__mcsema_attach_call

declare void @__mcsema_attach_call()

define i32 @main(i32 %argc, ptr %argv, ptr %envp) naked {
entry:
  call void asm sideeffect "pushq $0;pushq $$0x1000;jmpq *$1;", "*m,*m"(ptr elementtype(ptr) @target_slot, ptr elementtype(ptr) @attach_slot)
  ret i32 0
}

define internal ptr @main_wrapper(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

; CHECK-NOT: native_stack
; CHECK-NOT: 8388608
; CHECK-LABEL: define i32 @main
; CHECK: call ptr @main_wrapper
