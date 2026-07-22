; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: jq -e '[.proofs[] | select(.proof_engine == "complete_ssa_transition_and_plumbing_set" and .result == "proved")] | length == 1' %t.json >/dev/null

; Several explicit cases and the unmatched default share one transition PHI.
; Explicit arms are evaluated at their decoded SSA state.  The unbounded
; default arm is accepted only because its next state is independently finite.

define i32 @shared_case_tail_default() {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ %latch.state, %latch ]
  %carry = phi i32 [ 0, %entry ], [ %latch.carry, %latch ]
  switch i32 %state, label %default.case [
    i32 1, label %case.a
    i32 2, label %case.b
    i32 3, label %case.c
    i32 4, label %exit.four
    i32 5, label %exit.five
    i32 6, label %case.d
  ]

case.a:
  %from.a = xor i32 %state, 3
  br label %mid.a

mid.a:
  br label %shared

case.b:
  br label %shared

default.case:
  br label %mid.default

mid.default:
  br label %shared

shared:
  %shared.next = phi i32 [ %from.a, %mid.a ], [ 4, %case.b ],
                                [ 5, %mid.default ]
  br label %latch

case.c:
  br label %latch

case.d:
  br label %latch

latch:
  %latch.state = phi i32 [ %shared.next, %shared ], [ 4, %case.c ],
                                [ 5, %case.d ]
  %latch.carry = phi i32 [ 1, %shared ], [ 2, %case.c ], [ 3, %case.d ]
  br label %header

exit.four:
  ret i32 %carry

exit.five:
  ret i32 %carry
}

; CHECK-LABEL: define i32 @shared_case_tail_default()
; CHECK-NOT: br label %header{{$}}
; CHECK: switch i32 %shared.next
; CHECK: ret i32
; CHECK: ret i32
