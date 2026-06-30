; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

define i64 @sub_401000_add_native(i64 %0, i64 %1, ptr %2) {
entry:
  %sum = add i64 %0, %1
  ret i64 %sum
}

define i64 @caller() {
entry:
  %0 = call i64 @sub_401000_add_native(i64 1, i64 2, ptr poison)
  ret i64 %0
}

; CHECK-LABEL: define internal i64 @sub_401000_add_native(i64 %0, i64 %1, ptr %2) {
