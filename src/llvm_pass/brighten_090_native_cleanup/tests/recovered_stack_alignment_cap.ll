; RUN: opt-21 -load-pass-plugin=%plugin -brighten-native-state-ssa \
; RUN:   -passes='brighten-native-cleanup-pass,verify' -S %s | FileCheck-21 %s

; A recovered RSP is an integer guest value.  A byte offset from it does not
; inherit the backing object's alignment, so stale lifted alignments must not
; survive stack-address lowering.

define void @worker(ptr %native_stack, i64 %dynamic_offset, i64 %value) {
entry:
  %slot = getelementptr i8, ptr %native_stack, i64 %dynamic_offset
  store i64 %value, ptr %slot, align 16
  %loaded = load i64, ptr %slot, align 16
  call void @consume(i64 %loaded)
  ret void
}

declare void @consume(i64)

; CHECK-LABEL: define void @worker(
; CHECK: store i64 %value, ptr %slot, align 1
; CHECK: load i64, ptr %slot, align 1
