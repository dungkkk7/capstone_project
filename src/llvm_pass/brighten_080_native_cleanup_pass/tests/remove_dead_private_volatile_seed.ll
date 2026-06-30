; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

@0 = private global i32 0
@keep_seed = private global i32 0

define void @drop_dead_seed() {
entry:
  %0 = load volatile i32, ptr @0, align 4
  ret void
}

define i32 @keep_used_seed() {
entry:
  %0 = load volatile i32, ptr @keep_seed, align 4
  ret i32 %0
}

; CHECK-NOT: @0 = private global i32 0
; CHECK: @keep_seed = private global i32 0
; CHECK-LABEL: define void @drop_dead_seed()
; CHECK-NOT: load volatile i32, ptr @0
; CHECK: ret void
; CHECK-LABEL: define i32 @keep_used_seed()
; CHECK: load volatile i32, ptr @keep_seed, align 4
; CHECK: ret i32
