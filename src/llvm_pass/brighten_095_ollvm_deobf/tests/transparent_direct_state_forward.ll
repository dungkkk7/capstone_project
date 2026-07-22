; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: jq -e '.metrics.dispatchers_unresolved == 0 and ([.proofs[] | select(.proof_engine == "complete_cyclic_state_family_region" and .result == "proved")] | length == 1)' %t.json >/dev/null

; Loop canonicalization may insert an empty block between lookup shards.  The
; empty block forwards the preceding shard's state directly into the next
; shard PHI instead of defining a redundant local PHI.

define i32 @transparent_direct_state_forward() {
entry:
  br label %lookup.a

lookup.a:
  %state.a = phi i32 [ 1, %entry ], [ %next, %latch ], [ %state.b, %lookup.b ]
  switch i32 %state.a, label %transparent [
    i32 1, label %case.one
    i32 4, label %case.four
    i32 5, label %case.five
    i32 6, label %case.six
  ]

transparent:
  br label %lookup.b

lookup.b:
  %state.b = phi i32 [ %state.a, %transparent ]
  switch i32 %state.b, label %lookup.a [
    i32 2, label %case.two
    i32 3, label %exit
    i32 7, label %exit.seven
    i32 8, label %exit.eight
  ]

case.one:
  br label %latch

case.two:
  br label %latch

case.four:
  br label %latch

case.five:
  br label %latch

case.six:
  br label %latch

latch:
  %next = phi i32 [ 2, %case.one ], [ 3, %case.two ],
                  [ 3, %case.four ], [ 3, %case.five ], [ 3, %case.six ]
  br label %lookup.a

exit:
  ret i32 7

exit.seven:
  ret i32 7

exit.eight:
  ret i32 7
}

; CHECK-LABEL: define i32 @transparent_direct_state_forward()
; CHECK-NOT: switch i32
; CHECK: ret i32 7
