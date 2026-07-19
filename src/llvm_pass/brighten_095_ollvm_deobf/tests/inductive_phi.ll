; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['proof_engine']=='z3_inductive_constant_phi_unsat']; assert len(p)==1 and p[0]['result']=='proved' and 'inductive_seed_from_non_backedge_constant' in p[0]['dependencies'] and 'all_backedge_recurrences_preserve_seed' in p[0]['dependencies'] and 'inductive_phi_count=1' in p[0]['dependencies']; assert d['metrics']['inductive_phi_opaque_edges']==1"

define i32 @proved_inductive_phi(i32 %limit) {
; CHECK-LABEL: @proved_inductive_phi(
; CHECK: header:
; CHECK: br label %body
; CHECK-NOT: br i1 %stable
entry:
  br label %header

header:
  %state = phi i32 [ 42, %entry ], [ %next, %latch ]
  %index = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %stable = icmp eq i32 %state, 42
  br i1 %stable, label %body, label %dead

body:
  %done = icmp uge i32 %index, %limit
  br i1 %done, label %exit, label %latch

latch:
  %is.seed = icmp eq i32 %state, 42
  %next = select i1 %is.seed, i32 42, i32 99
  %inc = add i32 %index, 1
  br label %header

exit:
  ret i32 7

dead:
  ret i32 99
}

define i32 @unproved_changing_phi(i32 %limit) {
; CHECK-LABEL: @unproved_changing_phi(
; CHECK: %stable = icmp eq i32 %state, 42
; CHECK-NEXT: br i1 %stable, label %body, label %changed
entry:
  br label %header

header:
  %state = phi i32 [ 42, %entry ], [ %next, %latch ]
  %index = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %stable = icmp eq i32 %state, 42
  br i1 %stable, label %body, label %changed

body:
  %done = icmp uge i32 %index, %limit
  br i1 %done, label %exit, label %latch

latch:
  %is.seed = icmp eq i32 %state, 42
  %next = select i1 %is.seed, i32 43, i32 99
  %inc = add i32 %index, 1
  br label %header

exit:
  ret i32 7

changed:
  ret i32 9
}

define i32 @main() {
  %a = call i32 @proved_inductive_phi(i32 3)
  %a.ok = icmp eq i32 %a, 7
  %b = call i32 @unproved_changing_phi(i32 3)
  %b.ok = icmp eq i32 %b, 9
  %ok = and i1 %a.ok, %b.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
