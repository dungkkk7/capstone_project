; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-ollvm-deobf-pass,verify' -ollvm-deobf-report=%t.json -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0; assert not [p for p in d['proofs'] if p['result']!='proved']"

; CHECK-LABEL: define i32 @local_load_transition(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.latch

define i32 @local_load_transition(i1 %choose) {
entry:
  %state.slot = alloca i32, align 4
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %dispatch.latch ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %dispatch.latch ]
  switch i32 %state, label %dispatch.latch [
    i32 10, label %a
    i32 20, label %b
    i32 30, label %c
    i32 40, label %d
    i32 50, label %exit
  ]

a:
  store i32 20, ptr %state.slot, align 4
  %a.next = load i32, ptr %state.slot, align 4
  br label %dispatch.latch

b:
  %b.next = select i1 %choose, i32 30, i32 40
  br label %dispatch.latch

c:
  br label %dispatch.latch

d:
  br label %dispatch.latch

dispatch.latch:
  %next = phi i32 [ %state, %dispatch ], [ %a.next, %a ],
      [ %b.next, %b ], [ 50, %c ], [ 50, %d ]
  %acc.next = phi i32 [ %acc, %dispatch ], [ 1, %a ],
      [ 2, %b ], [ 3, %c ], [ 4, %d ]
  br label %dispatch

exit:
  ret i32 %acc
}
