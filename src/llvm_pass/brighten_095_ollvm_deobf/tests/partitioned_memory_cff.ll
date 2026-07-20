; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_state_promotion' and x['proof_engine']=='exact_memory_join_to_latch_phi']; q=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_partitioned_ssa_transition_set']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and p[0]['dependencies']==['complete_predecessor_coverage','exact_reaching_state_stores','default_self_edge_state_passthrough'] and len(q)==1 and q[0]['dependencies']==['unique_union_of_switch_case_tables','complete_returning_case_coverage','all_initial_and_next_states_resolved','direct_edges_match_z3_proved_state_selects']; assert not [x for x in d['proofs'] if x['result']!='proved']"

@frame_storage.state = internal global i32 0

define i32 @partitioned_dispatcher() {
; CHECK-LABEL: @partitioned_dispatcher(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header
; CHECK-NOT: dispatch.shard
; CHECK-NOT: dispatch.join
; CHECK: ret i32 0
entry:
  store i32 10, ptr @frame_storage.state
  br label %dispatch.header

dispatch.header:
  %state = phi i32 [ 10, %entry ], [ %reloaded, %dispatch.backedge ]
  switch i32 %state, label %dispatch.shard [
    i32 10, label %case.10
    i32 15, label %case.15
    i32 11, label %exit
    i32 12, label %exit
  ]

case.10:
  store i32 20, ptr @frame_storage.state
  br label %dispatch.join

case.15:
  store i32 30, ptr @frame_storage.state
  br label %dispatch.join

dispatch.shard:
  switch i32 %state, label %dispatch.join [
    i32 20, label %case.20
    i32 25, label %case.25
    i32 21, label %exit
    i32 22, label %exit
  ]

case.20:
  store i32 30, ptr @frame_storage.state
  br label %dispatch.join

case.25:
  store i32 40, ptr @frame_storage.state
  br label %dispatch.join

dispatch.join:
  switch i32 %state, label %dispatch.backedge [
    i32 30, label %exit
    i32 40, label %exit
    i32 31, label %exit
    i32 41, label %exit
  ]

exit:
  ret i32 0

dispatch.backedge:
  %reloaded = load i32, ptr @frame_storage.state
  br label %dispatch.header
}

define i32 @main() {
  %result = call i32 @partitioned_dispatcher()
  ret i32 %result
}
