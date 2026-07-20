; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0"

; The unmatched switch destination is a stateful initialization body, not a
; comparison shard.  It must execute once for the constant seed before the
; ordinary state cases are reconstructed.
define i32 @single_switch_default_body() {
; CHECK-LABEL: @single_switch_default_body(
; CHECK-NOT: switch
; CHECK: ret i32
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 99, %entry ], [ %next, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %next.acc, %latch ]
  switch i32 %state, label %initialize [
    i32 1, label %case.1
    i32 2, label %case.2
    i32 3, label %case.3
    i32 4, label %case.4
  ]

initialize:
  %acc.init = add i32 %acc, 10
  br label %latch
case.1:
  %acc.1 = add i32 %acc, 1
  br label %latch
case.2:
  %acc.2 = add i32 %acc, 2
  br label %latch
case.3:
  %acc.3 = add i32 %acc, 3
  br label %latch
case.4:
  %acc.4 = add i32 %acc, 4
  br label %latch

latch:
  %next = phi i32 [ 1, %initialize ], [ 2, %case.1 ],
                  [ 3, %case.2 ], [ 4, %case.3 ], [ 5, %case.4 ]
  %next.acc = phi i32 [ %acc.init, %initialize ], [ %acc.1, %case.1 ],
                      [ %acc.2, %case.2 ], [ %acc.3, %case.3 ],
                      [ %acc.4, %case.4 ]
  %done = icmp eq i32 %next, 5
  br i1 %done, label %exit, label %dispatch

exit:
  ret i32 %next.acc
}

define i32 @main() {
  %value = call i32 @single_switch_default_body()
  %bad = icmp ne i32 %value, 20
  %status = zext i1 %bad to i32
  ret i32 %status
}
