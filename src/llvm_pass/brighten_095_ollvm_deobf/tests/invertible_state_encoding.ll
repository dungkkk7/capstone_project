; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,simplifycfg,adce,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['metrics']['dispatchers_recovered']==2; assert d['metrics']['dispatchers_unresolved']==0"

declare i32 @llvm.fshl.i32(i32, i32, i32)
declare i32 @llvm.bswap.i32(i32)

define i32 @rotate_dispatcher() {
; CHECK-LABEL: @rotate_dispatcher
; CHECK-NOT: switch
entry: br label %dispatch
dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %latch ]
  %key = call i32 @llvm.fshl.i32(i32 %state, i32 %state, i32 7)
  switch i32 %key, label %bad [
    i32 1280, label %a
    i32 2560, label %b
    i32 3840, label %c
    i32 5120, label %d
  ]
a: br label %latch
b: br label %latch
c: br label %latch
d: br label %latch
latch:
  %next = phi i32 [ 20, %a ], [ 30, %b ], [ 40, %c ], [ 10, %d ]
  br label %dispatch
bad: ret i32 99
}

define i32 @bswap_dispatcher() {
; CHECK-LABEL: @bswap_dispatcher
; CHECK-NOT: switch
entry: br label %dispatch
dispatch:
  %state = phi i32 [ 1, %entry ], [ %next, %latch ]
  %key = call i32 @llvm.bswap.i32(i32 %state)
  switch i32 %key, label %bad [
    i32 16777216, label %a
    i32 33554432, label %b
    i32 50331648, label %c
    i32 67108864, label %d
  ]
a: br label %latch
b: br label %latch
c: br label %latch
d: br label %latch
latch:
  %next = phi i32 [ 2, %a ], [ 3, %b ], [ 4, %c ], [ 1, %d ]
  br label %dispatch
bad: ret i32 99
}
