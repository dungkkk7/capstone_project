; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: jq -e '[.proofs[] | select(.proof_engine == "complete_ssa_transition_and_plumbing_set" and .result == "proved")] | length == 1' %t.json >/dev/null

; A loop-rotated outer recurrence may compute its next dispatcher state and
; live values directly in the outer sink.  The inner latch likewise may feed
; a header PHI through a pure expression rather than a direct latch PHI.

define i32 @nested_direct_outer_sink(i1 %outer.choose) {
entry:
  br label %outer

outer:
  %outer.state = phi i32 [ 10, %entry ], [ %outer.next, %outer.sink ]
  %outer.carry = phi i32 [ 0, %entry ], [ %outer.carry.next, %outer.sink ]
  br label %header

header:
  %state = phi i32 [ %outer.state, %outer ], [ %latch.state, %latch ]
  %carry = phi i32 [ %outer.carry, %outer ], [ %carry.next, %latch ]
  switch i32 %state, label %trap [
    i32 10, label %outer.sink
    i32 20, label %case.a
    i32 30, label %case.b
    i32 40, label %case.c
    i32 50, label %result.true
    i32 60, label %result.false
  ]

outer.sink:
  %outer.carry.next = add i32 %carry, 2
  %outer.next = select i1 %outer.choose, i32 20, i32 30
  br label %outer

case.a:
  br label %latch

case.b:
  br label %latch

case.c:
  br label %latch

latch:
  %latch.state = phi i32 [ 50, %case.a ], [ 60, %case.b ],
                                [ 50, %case.c ]
  %carry.next = add i32 %carry, 1
  br label %header

result.true:
  ret i32 %carry

result.false:
  ret i32 %carry

trap:
  br label %trap
}

; CHECK-LABEL: define i32 @nested_direct_outer_sink(
; CHECK-NOT: switch i32
; CHECK-NOT: br label %outer{{$}}
; CHECK-NOT: br label %header{{$}}
; CHECK: ret i32
