; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: jq -e '[.proofs[] | select(.proof_engine == "complete_ssa_transition_and_plumbing_set" and .result == "proved")] | length == 1' %t.json >/dev/null

; The initial equality is peeled into the state header.  A later switch shard
; computes a value consumed by a case-entry PHI, so that shard body must be
; cloned together with the header plumbing on each direct transition.

define i32 @peeled_lookup_owner_phi() {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ %latch.state, %latch ]
  %carry = phi i32 [ 0, %entry ], [ %latch.carry, %latch ]
  %is.initial = icmp eq i32 %state, 1
  br i1 %is.initial, label %initial.case, label %shard

shard:
  %owner.carry = phi i32 [ %carry, %header ], [ %owner.next, %mirror ]
  %owner.next = add i32 %owner.carry, 0
  %is.low = icmp ult i32 %state, 4
  %case.bit = zext i1 %is.low to i32
  %case.value = add i32 %case.bit, %owner.next
  switch i32 %state, label %mirror [
    i32 2, label %case.two
    i32 3, label %case.three
    i32 4, label %exit.four
    i32 5, label %exit.five
    i32 6, label %case.six
  ]

mirror:
  switch i32 %state, label %shard [
    i32 2, label %case.two
  ]

initial.case:
  br label %latch

case.two:
  %from.lookup.owner = phi i32 [ %case.value, %shard ], [ 0, %mirror ]
  br label %latch

case.three:
  br label %latch

case.six:
  br label %latch

latch:
  %latch.state = phi i32 [ 2, %initial.case ], [ 4, %case.two ],
                                [ 5, %case.three ], [ 4, %case.six ]
  %latch.carry = phi i32 [ 0, %initial.case ],
                                [ %from.lookup.owner, %case.two ],
                                [ 0, %case.three ], [ 0, %case.six ]
  br label %header

exit.four:
  ret i32 %carry

exit.five:
  ret i32 %carry
}

; CHECK-LABEL: define i32 @peeled_lookup_owner_phi()
; CHECK-NOT: br label %header{{$}}
; CHECK-NOT: switch i32 %state
; CHECK: ret i32
