; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

define i64 @ptr_roundtrip(ptr %p) {
entry:
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %j = ptrtoint ptr %q to i64
  ret i64 %j
}

; CHECK-LABEL: define i64 @ptr_roundtrip
; CHECK: %i = ptrtoint ptr %p to i64
; CHECK: ret i64 %i
; CHECK-NOT: inttoptr
