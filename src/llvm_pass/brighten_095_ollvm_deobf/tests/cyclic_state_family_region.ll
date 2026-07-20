; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and any(x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region' for x in d['proofs'])"

; One state machine is deliberately split into three default-linked switch
; shards.  The state enters shard B dynamically, returns through a many-way
; PHI funnel to shard A, and is forwarded through shard C back to A.  State 5
; appears in B and C: ordered lookup, rather than global key uniqueness,
; determines the original behavior.
define i32 @cyclic_state_family(i1 %choose_first) {
; CHECK-LABEL: @cyclic_state_family(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.a:
; CHECK-NOT: dispatch.b:
; CHECK-NOT: dispatch.c:
; CHECK: ret i32
entry:
  %seed = select i1 %choose_first, i32 1, i32 5
  br label %dispatch.b

funnel:
  %next = phi i32 [ 5, %case.1 ], [ 6, %case.2 ],
                  [ 7, %case.3 ], [ 8, %case.4 ],
                  [ 9, %case.5 ], [ 10, %case.6 ],
                  [ 11, %case.7 ], [ 12, %case.8 ],
                  [ 2, %case.9 ], [ 3, %case.10 ],
                  [ 4, %case.11 ]
  %next.acc = phi i32 [ %a1, %case.1 ], [ %a2, %case.2 ],
                      [ %a3, %case.3 ], [ %a4, %case.4 ],
                      [ %a5, %case.5 ], [ %a6, %case.6 ],
                      [ %a7, %case.7 ], [ %a8, %case.8 ],
                      [ %a9, %case.9 ], [ %a10, %case.10 ],
                      [ %a11, %case.11 ]
  br label %dispatch.a

dispatch.a:
  %state.a = phi i32 [ %next, %funnel ], [ %state.b, %terminal.guard ]
  %acc.a = phi i32 [ %next.acc, %funnel ], [ %acc.b, %terminal.guard ]
  switch i32 %state.a, label %dispatch.b [
    i32 1, label %case.1
    i32 2, label %case.2
    i32 3, label %case.3
    i32 4, label %case.4
  ]

dispatch.b:
  %state.b = phi i32 [ %seed, %entry ], [ %state.a, %dispatch.a ]
  %acc.b = phi i32 [ 0, %entry ], [ %acc.a, %dispatch.a ]
  switch i32 %state.b, label %dispatch.c [
    i32 5, label %case.5
    i32 6, label %case.6
    i32 7, label %case.7
    i32 8, label %case.8
  ]

dispatch.c:
  switch i32 %state.b, label %terminal.guard [
    i32 5, label %case.5
    i32 9, label %case.9
    i32 10, label %case.10
    i32 11, label %case.11
  ]

terminal.guard:
  %is.terminal = icmp eq i32 %state.b, 12
  br i1 %is.terminal, label %exit, label %dispatch.a

case.1:
  %a1 = add i32 %acc.a, 1
  br label %funnel
case.2:
  %a2 = add i32 %acc.a, 1
  br label %funnel
case.3:
  %a3 = add i32 %acc.a, 1
  br label %funnel
case.4:
  %a4 = add i32 %acc.a, 1
  br label %funnel
case.5:
  %a5 = add i32 %acc.b, 1
  br label %funnel
case.6:
  %a6 = add i32 %acc.b, 1
  br label %funnel
case.7:
  %a7 = add i32 %acc.b, 1
  br label %funnel
case.8:
  %a8 = add i32 %acc.b, 1
  br label %funnel
case.9:
  %a9 = add i32 %acc.b, 1
  br label %funnel
case.10:
  %a10 = add i32 %acc.b, 1
  br label %funnel
case.11:
  %a11 = add i32 %acc.b, 1
  br label %funnel

exit:
  ret i32 %acc.b
}

define i32 @main() {
  %first = call i32 @cyclic_state_family(i1 true)
  %second = call i32 @cyclic_state_family(i1 false)
  %bad.first = icmp ne i32 %first, 11
  %bad.second = icmp ne i32 %second, 10
  %bad = or i1 %bad.first, %bad.second
  %status = zext i1 %bad to i32
  ret i32 %status
}
