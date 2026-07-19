; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['metrics']['dispatchers_recovered']==1; assert d['metrics']['dispatchers_unresolved']==1"

declare void @effect(i32)

define void @proved_dispatcher(i1 %cond) {
; CHECK-LABEL: @proved_dispatcher
; CHECK-NOT: switch
entry:
  br label %dispatch
dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %latch ]
  %encoded.mul = mul i32 %state, 3
  %encoded = add i32 %encoded.mul, 5
  switch i32 %encoded, label %default [
    i32 35, label %case0
    i32 65, label %case1
    i32 95, label %case2
    i32 125, label %case3
  ]
case0:
; CHECK: case0:
; CHECK-NEXT: call void @effect(i32 0)
; CHECK-NEXT: br label %case1
  call void @effect(i32 0)
  br label %latch
case1:
; CHECK: case1:
; CHECK-NEXT: call void @effect(i32 1)
; CHECK-NEXT: %choice = select i1 %cond, i32 30, i32 40
; CHECK-NEXT: br i1 %cond, label %case2, label %case3
  call void @effect(i32 1)
  %choice = select i1 %cond, i32 30, i32 40
  br label %latch
case2:
  call void @effect(i32 2)
  br label %latch
case3:
  call void @effect(i32 3)
  br label %latch
latch:
  %next = phi i32 [ 20, %case0 ], [ %choice, %case1 ],
                  [ 10, %case2 ], [ 10, %case3 ]
  br label %dispatch
default:
  unreachable
}

; A state escaping the finite case map must remain as a residual dispatcher.
define void @unresolved_dispatcher() {
; CHECK-LABEL: @unresolved_dispatcher
; CHECK: switch i32
entry:
  br label %dispatch
dispatch:
  %state = phi i32 [ 1, %entry ], [ %next, %latch ]
  switch i32 %state, label %default [
    i32 1, label %a
    i32 2, label %b
    i32 3, label %c
    i32 4, label %d
  ]
a: br label %latch
b: br label %latch
c: br label %latch
d: br label %latch
latch:
  %next = phi i32 [ 2, %a ], [ 3, %b ], [ 4, %c ], [ 99, %d ]
  br label %dispatch
default:
  unreachable
}
