; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-type-reconstruct-pass -S %s | FileCheck-21 %s

define void @recover_gep(ptr %base) {
entry:
  %addr = ptrtoint ptr %base to i64
  %off = add i64 %addr, 24
  %slot = inttoptr i64 %off to ptr
  store i64 7, ptr %slot, align 8
  ret void
}

; CHECK-LABEL: define void @recover_gep
; CHECK: %addr = ptrtoint ptr %base to i64
; CHECK: %ptr.recover = getelementptr i8, ptr %base, i64 24
; CHECK: store i64 7, ptr %ptr.recover, align 8
; CHECK-NOT: inttoptr i64 %off to ptr
