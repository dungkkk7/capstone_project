; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass,verify -S %s -o - | FileCheck-21 %s

define internal void @callback_sub_401020() {
entry:
  ret void
}

define void @caller(ptr %slot) {
entry:
  call void @callback_sub_401020()
  store i64 ptrtoint (ptr @callback_sub_401020 to i64), ptr %slot, align 8
  ret void
}

; CHECK-LABEL: define internal void @callback_sub_401020
; CHECK-LABEL: define void @caller
; CHECK: call void @callback_sub_401020()
; CHECK: store i64 4198432, ptr %slot
