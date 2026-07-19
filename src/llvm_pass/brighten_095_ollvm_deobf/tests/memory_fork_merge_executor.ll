; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_transition' and x['proof_engine']=='memory_join_finite_set_z3_unsat']; assert len(p)==1 and p[0]['proof_query_hash'] and p[0]['dependencies']==['bounded_acyclic_fork_merge_enumeration','exhaustive_transition_set_smt_membership','exact_header_plumbing_clone']"

@frame_storage_backing.fork_merge = internal global i32 10

define i32 @fork_merge_dispatch(i1 %choose) {
entry:
  store i32 10, ptr @frame_storage_backing.fork_merge, align 4
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %entry ], [ %reloaded, %join ]
  switch i32 %state, label %default [
    i32 10, label %case10
    i32 20, label %case20
    i32 30, label %case30
    i32 40, label %case40
    i32 50, label %case50
  ]

case10:
  br i1 %choose, label %left, label %right

left:
  store i32 20, ptr @frame_storage_backing.fork_merge, align 4
  br label %merge

right:
  store i32 30, ptr @frame_storage_backing.fork_merge, align 4
  br label %merge

merge:
; CHECK-LABEL: merge:
; CHECK: [[MERGED:%.*]] = phi i32
; CHECK: [[COND:%.*]] = icmp eq i32 [[MERGED]], {{20|30}}
; CHECK: br i1 [[COND]]
  br label %join

case20:
  ret i32 20

case30:
  ret i32 30

case40:
  store i32 10, ptr @frame_storage_backing.fork_merge, align 4
  br label %join

case50:
  store i32 10, ptr @frame_storage_backing.fork_merge, align 4
  br label %join

join:
  %reloaded = load i32, ptr @frame_storage_backing.fork_merge, align 4
  br label %dispatch

default:
  ret i32 99
}

define i32 @main() {
  %a = call i32 @fork_merge_dispatch(i1 true)
  %b = call i32 @fork_merge_dispatch(i1 false)
  %a.ok = icmp eq i32 %a, 20
  %b.ok = icmp eq i32 %b, 30
  %ok = and i1 %a.ok, %b.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
