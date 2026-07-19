; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,brighten-ollvm-deobf-pass,sroa,instcombine,simplifycfg,dce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_state_promotion' and x['proof_engine']=='exact_memory_join_to_latch_phi']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and p[0]['dependencies']==['complete_predecessor_coverage','exact_reaching_state_stores','default_self_edge_state_passthrough']; assert not [x for x in d['proofs'] if x['result']!='proved']"

@outer.state = internal global i32 0
@trace = internal global i32 0

define i32 @nested_memory_plumbing(i1 %repeat) {
; CHECK-LABEL: @nested_memory_plumbing(
; CHECK-NOT: switch
; CHECK-NOT: outer.header
; CHECK-NOT: nested.header
; CHECK: ret i32
entry:
  store i32 10, ptr @outer.state
  br label %outer.header

outer.header:
  %outer.state.value = phi i32 [ 10, %entry ], [ %outer.loaded, %outer.latch ]
  %outer.acc = phi i32 [ 1, %entry ], [ %outer.acc.next, %outer.latch ]
  switch i32 %outer.state.value, label %outer.latch [
    i32 10, label %outer.case.10
    i32 20, label %nested.entry
    i32 30, label %outer.exit
    i32 40, label %outer.case.40
  ]

outer.case.10:
  %outer.acc.10 = add i32 %outer.acc, 2
  store i32 20, ptr @outer.state
  br label %outer.latch

outer.case.40:
  br i1 %repeat, label %nested.entry, label %outer.case.40.done

outer.case.40.done:
  %outer.acc.40 = add i32 %outer.acc, 4
  store i32 30, ptr @outer.state
  br label %outer.latch

nested.entry:
  br label %nested.header

nested.header:
  %nested.state = phi i32 [ 100, %nested.entry ], [ %nested.state.next, %nested.latch ]
  %nested.acc = phi i32 [ %outer.acc, %nested.entry ], [ %nested.acc.next, %nested.latch ]
  store i32 %nested.acc, ptr @trace
  switch i32 %nested.state, label %nested.default [
    i32 100, label %nested.case.100
    i32 200, label %nested.exit
    i32 300, label %nested.case.300
    i32 400, label %nested.case.400
  ]

nested.case.100:
  %nested.acc.100 = add i32 %nested.acc, 3
  br label %nested.latch

nested.case.300:
  %nested.acc.300 = add i32 %nested.acc, 30
  br label %nested.latch

nested.case.400:
  %nested.acc.400 = add i32 %nested.acc, 40
  br label %nested.latch

nested.default:
  br label %nested.latch

nested.latch:
  %nested.state.next = phi i32 [ 200, %nested.case.100 ],
                                 [ 400, %nested.case.300 ],
                                 [ 200, %nested.case.400 ],
                                 [ 100, %nested.default ]
  %nested.acc.next = phi i32 [ %nested.acc.100, %nested.case.100 ],
                               [ %nested.acc.300, %nested.case.300 ],
                               [ %nested.acc.400, %nested.case.400 ],
                               [ %nested.acc, %nested.default ]
  br label %nested.header

nested.exit:
  %nested.last = load i32, ptr @trace
  %nested.result = add i32 %nested.acc, %nested.last
  store i32 40, ptr @outer.state
  br label %outer.latch

outer.latch:
  %outer.acc.next = phi i32 [ %outer.acc.10, %outer.case.10 ],
                              [ %nested.result, %nested.exit ],
                              [ %outer.acc.40, %outer.case.40.done ],
                              [ %outer.acc, %outer.header ]
  %outer.loaded = load i32, ptr @outer.state
  br label %outer.header

outer.exit:
  ret i32 %outer.acc
}

define i32 @main() {
  %result = call i32 @nested_memory_plumbing(i1 false)
  %ok = icmp eq i32 %result, 16
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
