; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and any(x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region' and set(['closed_default_linked_lookup_ring','exact_forwarded_state_family','ordered_lookup_resolution','complete_external_edge_coverage','exact_phi_and_plumbing_translation']).issubset(x['dependencies']) for x in d['proofs'])"

define i32 @default_guard_partitioned() {
; CHECK-LABEL: @default_guard_partitioned(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header:
; CHECK: ret i32
entry:
  br label %dispatch.header

dispatch.header:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %next.acc, %latch ]
  switch i32 %state, label %default.guard [
    i32 1, label %case.1
    i32 2, label %case.2
    i32 3, label %case.3
    i32 4, label %case.4
  ]

default.guard:
  %terminal.acc = add i32 %acc, 1
  %is.terminal = icmp eq i32 %state, 5
  br i1 %is.terminal, label %exit, label %dispatch.shard

dispatch.shard:
  switch i32 %state, label %latch [
    i32 6, label %case.6
    i32 7, label %case.7
    i32 8, label %case.8
    i32 9, label %case.9
  ]

case.1:
  %acc.1 = add i32 %acc, 1
  br label %latch
case.2:
  %acc.2 = add i32 %acc, 1
  br label %latch
case.3:
  %acc.3 = add i32 %acc, 1
  br label %latch
case.4:
  %acc.4 = add i32 %acc, 1
  br label %latch
case.6:
  %acc.6 = add i32 %acc, 1
  br label %latch
case.7:
  %acc.7 = add i32 %acc, 1
  br label %latch
case.8:
  %acc.8 = add i32 %acc, 1
  br label %latch
case.9:
  %acc.9 = add i32 %acc, 1
  br label %latch

latch:
  %next.state = phi i32 [ %state, %dispatch.shard ],
                         [ 6, %case.1 ], [ 7, %case.2 ],
                         [ 8, %case.3 ], [ 9, %case.4 ],
                         [ 2, %case.6 ], [ 3, %case.7 ],
                         [ 4, %case.8 ], [ 5, %case.9 ]
  %next.acc = phi i32 [ %acc, %dispatch.shard ],
                       [ %acc.1, %case.1 ], [ %acc.2, %case.2 ],
                       [ %acc.3, %case.3 ], [ %acc.4, %case.4 ],
                       [ %acc.6, %case.6 ], [ %acc.7, %case.7 ],
                       [ %acc.8, %case.8 ], [ %acc.9, %case.9 ]
  br label %dispatch.header

exit:
  ret i32 %terminal.acc
}

define i32 @main() {
  %result = call i32 @default_guard_partitioned()
  %bad = icmp ne i32 %result, 9
  %status = zext i1 %bad to i32
  ret i32 %status
}
