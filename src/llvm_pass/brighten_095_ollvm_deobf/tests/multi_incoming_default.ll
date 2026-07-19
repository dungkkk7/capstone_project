; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='multi_incoming_ssa_default_induction']; assert len(p)==1 and p[0]['result']=='proved' and p[0]['dependencies']==['external_seed_exists','exhaustive_known_state_induction','default_only_header_predecessor','exact_header_plumbing_clone'] and p[0]['proof_query_hash']; assert d['metrics']['dispatchers_recovered']==1 and d['metrics']['dispatchers_unresolved']==0"

define i32 @recover_default_identity() {
; CHECK-LABEL: @recover_default_identity(
; CHECK-NOT: switch i32
; CHECK-NOT: dispatch:
; CHECK: case0:
; CHECK: store i32 1, ptr %log
; CHECK-NEXT: br label %case1
; CHECK: case1:
; CHECK: store i32 2, ptr %log
; CHECK-NEXT: br label %exit
entry:
  %state.slot = alloca i32, align 4
  %log = alloca i32, align 4
  store i32 0, ptr %state.slot, align 4
  store i32 0, ptr %log, align 4
  br label %case0

dispatch:
  %state = phi i32 [ 1, %case0 ], [ 2, %case1 ], [ 4, %case3 ],
                   [ 2, %case4 ], [ %default.state, %default ]
  store i32 %state, ptr %log, align 4
  switch i32 %state, label %default [
    i32 1, label %case1
    i32 2, label %exit
    i32 3, label %case3
    i32 4, label %case4
  ]

case0:
  store i32 1, ptr %state.slot, align 4
  br label %dispatch

case1:
  store i32 2, ptr %state.slot, align 4
  br label %dispatch

case3:
  store i32 4, ptr %state.slot, align 4
  br label %dispatch

case4:
  store i32 2, ptr %state.slot, align 4
  br label %dispatch

default:
  %default.state = load i32, ptr %state.slot, align 4
  br label %dispatch

exit:
  %result = load i32, ptr %log, align 4
  ret i32 %result
}

define i32 @retain_externally_seeded_default(i1 %choose) {
; CHECK-LABEL: @retain_externally_seeded_default(
; CHECK: switch i32 %state
entry:
  br i1 %choose, label %case0, label %default
dispatch:
  %state = phi i32 [ 1, %case0 ], [ 5, %default ]
  switch i32 %state, label %default [
    i32 1, label %exit1
    i32 2, label %exit2
    i32 3, label %exit3
    i32 4, label %exit4
  ]
case0:
  br label %dispatch
default:
  br label %dispatch
exit1:
  ret i32 1
exit2:
  ret i32 2
exit3:
  ret i32 3
exit4:
  ret i32 0
}

define i32 @main() {
  %value = call i32 @recover_default_identity()
  %ok = icmp eq i32 %value, 2
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
