; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

define ptr @sub_401000(ptr %state, i64 %pc, ptr %memory) noinline optnone {
entry:
  ret ptr %memory
}

define i64 @sub_401000_native(i64 %a, ptr %memory) noinline optnone {
entry:
  ret i64 %a
}

; CHECK: ; Function Attrs: alwaysinline
; CHECK: define internal ptr @sub_401000(ptr %state, i64 %pc, ptr %memory) #0 {
; CHECK: define internal i64 @sub_401000_native(i64 %a, ptr %memory)
; CHECK-NOT: noinline
; CHECK-NOT: optnone
