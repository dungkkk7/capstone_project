; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

declare i32 @setjmp(ptr) returns_twice

define i32 @plain(i32 %x) #0 {
entry:
  ret i32 %x
}

define i32 @has_setjmp(ptr %env) #0 {
entry:
  %r = call i32 @setjmp(ptr %env)
  ret i32 %r
}

attributes #0 = { noinline optnone }

; CHECK-LABEL: define i32 @plain(i32 %x) {
; CHECK-LABEL: define i32 @has_setjmp(ptr %env) #{{[0-9]+}} {
; CHECK: attributes #{{[0-9]+}} = { noinline optnone{{.*}} }
