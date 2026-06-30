; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

define i32 @foo(i32 %x) {
entry:
  call void asm sideeffect "", ""()
  ret i32 %x
}

; CHECK-LABEL: define i32 @foo(i32 %x) {
; CHECK-NOT: asm sideeffect
; CHECK: ret i32 %x
