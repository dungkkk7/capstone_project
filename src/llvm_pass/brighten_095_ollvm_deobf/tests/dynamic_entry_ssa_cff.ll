; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and any(x['kind']=='cff_dispatcher' and 'dynamic_entry_exact_switch_retained' in x['dependencies'] for x in d['proofs'])"

define i32 @dynamic_entry(i32 %initial) {
; CHECK-LABEL: @dynamic_entry(
; CHECK: switch i32
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ %initial, %entry ], [ %state.next, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %latch ]
  switch i32 %state, label %latch [
    i32 1, label %case.1
    i32 2, label %case.2
    i32 3, label %case.3
    i32 4, label %case.4
    i32 5, label %exit
  ]

case.1:
  %a1 = add i32 %acc, 1
  br label %latch
case.2:
  %a2 = add i32 %acc, 2
  br label %latch
case.3:
  %a3 = add i32 %acc, 3
  br label %latch
case.4:
  %a4 = add i32 %acc, 4
  br label %latch

latch:
  %state.next = phi i32 [ %state, %dispatch ], [ 2, %case.1 ],
                          [ 3, %case.2 ], [ 4, %case.3 ], [ 5, %case.4 ]
  %acc.next = phi i32 [ %acc, %dispatch ], [ %a1, %case.1 ],
                        [ %a2, %case.2 ], [ %a3, %case.3 ], [ %a4, %case.4 ]
  br label %dispatch

exit:
  ret i32 %acc
}

define i32 @main() {
  %result = call i32 @dynamic_entry(i32 1)
  %bad = icmp ne i32 %result, 10
  %status = zext i1 %bad to i32
  ret i32 %status
}
