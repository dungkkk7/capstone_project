; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x.get('proof_engine')=='z3_cyclic_predicate_induction_unsat']; assert len(p)==1 and p[0]['function']=='even_recurrence' and p[0]['result']=='proved' and p[0]['dependencies']==['fixed_width_bitvector_semantics','all_external_seeds_establish_predicate','all_backedge_recurrences_preserve_predicate_by_z3_induction','inductive_phi_count=1']"

define i32 @even_recurrence() {
; CHECK-LABEL: @even_recurrence(
entry:
  br label %header
header:
  %state = phi i8 [ 0, %entry ], [ %next, %latch ]
  %i = phi i8 [ 0, %entry ], [ %inc, %latch ]
  %low = and i8 %state, 1
  %even = icmp eq i8 %low, 0
; CHECK: br label %body
  br i1 %even, label %body, label %dead
body:
  %done = icmp eq i8 %i, 10
  br i1 %done, label %exit, label %latch
latch:
  %next = add i8 %state, 2
  %inc = add i8 %i, 1
  br label %header
exit:
  ret i32 7
dead:
  ret i32 99
}

define i32 @non_invariant_recurrence() {
; CHECK-LABEL: @non_invariant_recurrence(
entry:
  br label %header
header:
  %state = phi i8 [ 0, %entry ], [ %next, %latch ]
  %low = and i8 %state, 1
  %even = icmp eq i8 %low, 0
; CHECK: br i1 %even, label %latch, label %dead
  br i1 %even, label %latch, label %dead
latch:
  %next = add i8 %state, 1
  br label %header
dead:
  ret i32 99
}

define i32 @main() {
  %a = call i32 @even_recurrence()
  %b = call i32 @non_invariant_recurrence()
  %a.ok = icmp eq i32 %a, 7
  %b.ok = icmp eq i32 %b, 99
  %ok = and i1 %a.ok, %b.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
