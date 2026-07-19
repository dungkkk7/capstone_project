; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,sroa,instcombine,simplifycfg,dce,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind'] in ('cff_dispatcher','cff_transition') and x['proof_engine'] in ('complete_ssa_transition_and_plumbing_set','ssa_phi_demotion_exact_plumbing')]; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_recovered']==1 and len(p)==4 and all(x['old_hash'] and x['new_hash'] and x['proof_query_hash'] and x['dependencies']==['llvm_phi_demotion','exact_latch_header_clone'] for x in p); assert not [x for x in d['proofs'] if x['result']!='proved']"

@trace = internal global i32 0

define i32 @plumbing(i1 %take_long_path) {
; CHECK-LABEL: @plumbing(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header
; CHECK: ret i32
entry:
  br label %dispatch.header

dispatch.header:
  %state = phi i32 [ 10, %entry ], [ %state.next, %latch ]
  %acc = phi i32 [ 5, %entry ], [ %acc.next, %latch ]
  store i32 %acc, ptr @trace
  switch i32 %state, label %default [
    i32 10, label %case.10
    i32 20, label %case.20
    i32 30, label %case.30
    i32 40, label %exit
  ]

case.10:
  %acc.10 = add i32 %acc, 1
  br label %latch

case.20:
  %acc.20 = mul i32 %acc, 2
  %selected = select i1 %take_long_path, i32 30, i32 40
  br i1 false, label %trap, label %case.20.cont

trap:
  unreachable

case.20.cont:
  br label %latch

case.30:
  %acc.30 = add i32 %acc, 3
  br label %latch

default:
  br label %latch

latch:
  %state.next = phi i32 [ 20, %case.10 ], [ %selected, %case.20.cont ],
                          [ 40, %case.30 ], [ 10, %default ]
  %acc.next = phi i32 [ %acc.10, %case.10 ], [ %acc.20, %case.20.cont ],
                        [ %acc.30, %case.30 ], [ %acc, %default ]
  br label %dispatch.header

exit:
  %last_trace = load i32, ptr @trace
  %result = add i32 %acc, %last_trace
  ret i32 %result
}

define i32 @main() {
  %long = call i32 @plumbing(i1 true)
  %long.ok = icmp eq i32 %long, 30
  %short = call i32 @plumbing(i1 false)
  %short.ok = icmp eq i32 %short, 24
  %ok = and i1 %long.ok, %short.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
