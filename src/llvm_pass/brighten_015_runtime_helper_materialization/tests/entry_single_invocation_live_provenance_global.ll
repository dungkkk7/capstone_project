@target_slot = global ptr null
@attach_slot = global ptr @__mcsema_attach_call
@live_provenance = internal global ptr @main_wrapper
declare void @__mcsema_attach_call()

define i32 @main() naked {
entry:
  call void asm sideeffect "pushq $0;pushq $$0x1000;jmpq *$1;", "*m,*m"(ptr elementtype(ptr) @target_slot, ptr elementtype(ptr) @attach_slot)
  ret i32 0
}

define internal void @main_wrapper() { ret void }

; CHECK-NOT: !brighten.entry_single_invocation
