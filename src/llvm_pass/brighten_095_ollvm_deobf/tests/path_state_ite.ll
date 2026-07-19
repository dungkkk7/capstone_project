; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['proof_engine']=='z3_path_state_ite_unsat']; assert len(p)==2 and all(x['result']=='proved' and 'path_state_ite_count=1' in x['dependencies'] for x in p); assert any('exact_two_arm_diamond_phi_ite' in x['dependencies'] for x in p) and any('exact_multi_arm_switch_funnel_phi_ite' in x['dependencies'] for x in p); assert d['metrics']['path_state_ite_opaque_edges']==2"

define i32 @proved_diamond(i32 %x, i1 %choose) {
; CHECK-LABEL: @proved_diamond(
; CHECK: merge:
; CHECK: br label %live
; CHECK-NOT: br i1 %always
entry:
  br i1 %choose, label %left, label %right

left:
  %lv = add i32 %x, 1
  br label %merge

right:
  %rv = sub i32 %x, -1
  br label %merge

merge:
  %joined = phi i32 [ %lv, %left ], [ %rv, %right ]
  %expected = add i32 %x, 1
  %always = icmp eq i32 %joined, %expected
  br i1 %always, label %live, label %dead

live:
  ret i32 7

dead:
  ret i32 99
}

define i32 @unproved_diamond(i32 %x, i1 %choose) {
; CHECK-LABEL: @unproved_diamond(
; CHECK: %maybe = icmp eq i32 %joined, %expected
; CHECK-NEXT: br i1 %maybe, label %live, label %dead
entry:
  br i1 %choose, label %left, label %right

left:
  %lv = add i32 %x, 1
  br label %merge

right:
  %rv = add i32 %x, 2
  br label %merge

merge:
  %joined = phi i32 [ %lv, %left ], [ %rv, %right ]
  %expected = add i32 %x, 1
  %maybe = icmp eq i32 %joined, %expected
  br i1 %maybe, label %live, label %dead

live:
  ret i32 7

dead:
  ret i32 9
}

define i32 @proved_switch_funnel(i32 %x, i8 %key) {
; CHECK-LABEL: @proved_switch_funnel(
; CHECK: merge:
; CHECK: br label %live
; CHECK-NOT: br i1 %always
entry:
  switch i8 %key, label %default [
    i8 1, label %one
    i8 2, label %two
  ]

one:
  %v1 = add i32 %x, 1
  br label %merge

two:
  %v2 = sub i32 %x, -1
  br label %merge

default:
  %vd = add i32 1, %x
  br label %merge

merge:
  %joined = phi i32 [ %v1, %one ], [ %v2, %two ], [ %vd, %default ]
  %expected = add i32 %x, 1
  %always = icmp eq i32 %joined, %expected
  br i1 %always, label %live, label %dead

live:
  ret i32 11

dead:
  ret i32 99
}

define i32 @unproved_switch_funnel(i32 %x, i8 %key) {
; CHECK-LABEL: @unproved_switch_funnel(
; CHECK: %maybe = icmp eq i32 %joined, %expected
; CHECK-NEXT: br i1 %maybe, label %live, label %dead
entry:
  switch i8 %key, label %default [
    i8 1, label %one
    i8 2, label %two
  ]

one:
  %v1 = add i32 %x, 1
  br label %merge

two:
  %v2 = add i32 %x, 2
  br label %merge

default:
  %vd = add i32 %x, 1
  br label %merge

merge:
  %joined = phi i32 [ %v1, %one ], [ %v2, %two ], [ %vd, %default ]
  %expected = add i32 %x, 1
  %maybe = icmp eq i32 %joined, %expected
  br i1 %maybe, label %live, label %dead

live:
  ret i32 11

dead:
  ret i32 13
}

define i32 @main() {
  %a = call i32 @proved_diamond(i32 41, i1 false)
  %a.ok = icmp eq i32 %a, 7
  %b = call i32 @unproved_diamond(i32 41, i1 true)
  %b.ok = icmp eq i32 %b, 7
  %c = call i32 @proved_switch_funnel(i32 41, i8 2)
  %c.ok = icmp eq i32 %c, 11
  %d = call i32 @unproved_switch_funnel(i32 41, i8 1)
  %d.ok = icmp eq i32 %d, 11
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %ok = and i1 %ab, %cd
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
