; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll

define i128 @neutral_i128(i128 %x) {
; CHECK-LABEL: @neutral_i128(
; CHECK-NEXT: ret i128 %x
  %merged = or i128 %x, 0
  ret i128 %merged
}
