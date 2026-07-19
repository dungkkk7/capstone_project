; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='opaque_edge' and x['proof_engine']=='z3_bitvector_with_dominating_constraints_unsat']; assert d['metrics']['path_constrained_opaque_edges']==3 and len(p)==3 and {x['function'] for x in p}=={'dominated_true','dominated_false','assumed_true'}; assert all(x['old_hash'] and x['new_hash'] and x['proof_query_hash'] and 'dominating_path_constraints_sat' in x['dependencies'] and any(y.startswith('path_constraint_count=') for y in x['dependencies']) for x in p); assert not [x for x in d['proofs'] if x['function'] in ('merge_unknown','freeze_relation_unknown','inconsistent_assumptions') and x['kind']=='opaque_edge']"

declare void @llvm.assume(i1)

define i32 @dominated_true(i32 %x) {
; CHECK-LABEL: @dominated_true(
entry:
  %entry.guard = icmp ult i32 %x, 10
  br i1 %entry.guard, label %guarded, label %other
guarded:
  %implied = icmp ult i32 %x, 20
; CHECK: %implied = icmp ult i32 %x, 20
; CHECK-NEXT: br label %good
  br i1 %implied, label %good, label %bad
good:
  ret i32 1
bad:
  ret i32 2
other:
  ret i32 3
}

define i32 @dominated_false(i32 %x) {
; CHECK-LABEL: @dominated_false(
entry:
  %entry.guard = icmp uge i32 %x, 10
  br i1 %entry.guard, label %guarded, label %other
guarded:
  %implied.false = icmp ult i32 %x, 5
; CHECK: %implied.false = icmp ult i32 %x, 5
; CHECK-NEXT: br label %good
  br i1 %implied.false, label %bad, label %good
good:
  ret i32 1
bad:
  ret i32 2
other:
  ret i32 3
}

define i32 @assumed_true(i32 %x) {
; CHECK-LABEL: @assumed_true(
entry:
  %bounded = icmp ult i32 %x, 100
  call void @llvm.assume(i1 %bounded)
  %implied = icmp ult i32 %x, 200
; CHECK: %implied = icmp ult i32 %x, 200
; CHECK-NEXT: br label %good
  br i1 %implied, label %good, label %bad
good:
  ret i32 1
bad:
  ret i32 2
}

define i32 @merge_unknown(i32 %x) {
; CHECK-LABEL: @merge_unknown(
entry:
  %entry.guard = icmp ult i32 %x, 10
  br i1 %entry.guard, label %left, label %right
left:
  br label %merge
right:
  br label %merge
merge:
  %unknown = icmp ult i32 %x, 20
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @freeze_relation_unknown(i32 %x) {
; CHECK-LABEL: @freeze_relation_unknown(
entry:
  %frozen = freeze i32 %x
  %unknown = icmp eq i32 %frozen, %x
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @inconsistent_assumptions(i32 %x) {
; CHECK-LABEL: @inconsistent_assumptions(
entry:
  %low = icmp ult i32 %x, 10
  %high = icmp uge i32 %x, 10
  call void @llvm.assume(i1 %low)
  call void @llvm.assume(i1 %high)
  %unknown = icmp eq i32 %x, 7
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @main() {
  %a = call i32 @dominated_true(i32 5)
  %a.ok = icmp eq i32 %a, 1
  %b = call i32 @dominated_false(i32 12)
  %b.ok = icmp eq i32 %b, 1
  %c = call i32 @assumed_true(i32 50)
  %c.ok = icmp eq i32 %c, 1
  %d = call i32 @merge_unknown(i32 7)
  %d.ok = icmp eq i32 %d, 1
  %e = call i32 @freeze_relation_unknown(i32 42)
  %e.ok = icmp eq i32 %e, 1
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %abcd = and i1 %ab, %cd
  %ok = and i1 %abcd, %e.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
