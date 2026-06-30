; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

define i32 @main() {
entry:
  %pc = call i64 asm sideeffect "pushq $$0x401000", "=r"()
  %ret = trunc i64 %pc to i32
  ret i32 %ret
}

; CHECK-NOT: define i32 @main()
; CHECK-LABEL: define i32 @old_main()
; CHECK-NOT: asm
; CHECK: ret i32
