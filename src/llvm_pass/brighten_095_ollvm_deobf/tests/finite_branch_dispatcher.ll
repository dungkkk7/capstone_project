; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,sroa,instcombine,simplifycfg,dce,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['proof_engine']=='finite_branch_state_induction']; assert p and all(x['result']=='proved' and x['old_hash'] and x['new_hash'] and x['proof_query_hash'] for x in p)"

@trace = internal global i32 0

define i32 @finite_branch_dispatcher() {
; CHECK-LABEL: @finite_branch_dispatcher(
; CHECK-NOT: decision.left
; CHECK-NOT: decision.right
; CHECK-NOT: icmp slt i32 %state
entry:
  br label %outer

outer:
  %outer.state = phi i32 [ 10, %entry ], [ %transition, %latch ]
  br label %dispatch

dispatch:
  %state = phi i32 [ %outer.state, %outer ], [ 10, %retry ]
  %left.half = icmp slt i32 %state, 30
  br i1 %left.half, label %decision.left, label %decision.right

decision.left:
  %is.10 = icmp eq i32 %state, 10
  br i1 %is.10, label %case.10, label %case.20

decision.right:
  %is.30 = icmp eq i32 %state, 30
  br i1 %is.30, label %case.30, label %decision.last

decision.last:
  %is.40 = icmp eq i32 %state, 40
  br i1 %is.40, label %exit, label %retry

retry:
  br label %dispatch

case.10:
  store volatile i32 10, ptr @trace
  br label %latch

case.20:
  store volatile i32 20, ptr @trace
  br label %latch

case.30:
  store volatile i32 30, ptr @trace
  br label %latch

latch:
  %transition = phi i32 [ 20, %case.10 ], [ 30, %case.20 ],
                        [ 40, %case.30 ]
  br label %outer

exit:
  %result = load volatile i32, ptr @trace
  ret i32 %result
}

define i32 @main() {
  %result = call i32 @finite_branch_dispatcher()
  %ok = icmp eq i32 %result, 30
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
