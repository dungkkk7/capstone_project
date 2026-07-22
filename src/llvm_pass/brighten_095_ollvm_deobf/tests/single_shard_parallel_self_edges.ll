; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: jq -e '.metrics.dispatchers_unresolved == 0 and ([.proofs[] | select(.proof_engine == "complete_cyclic_state_family_region" and .result == "proved")] | length == 1)' %t.json >/dev/null

; Two switch cases re-enter the same dispatcher block.  LLVM requires parallel
; edges from one predecessor to carry identical PHI values, but each edge still
; has a distinct PHI occurrence that recovery must account for structurally.

define i32 @main() {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ 4, %case.one ],
                   [ 2, %header ], [ 2, %header ]
  %carry = phi i32 [ 0, %entry ], [ 7, %case.one ],
                   [ 11, %header ], [ 11, %header ]
  switch i32 %state, label %unknown [
    i32 1, label %case.one
    i32 2, label %exit.two
    i32 3, label %exit.two
    i32 4, label %header
    i32 5, label %header
  ]

case.one:
  br label %header

unknown:
  br label %unknown

exit.two:
  %ok = icmp eq i32 %carry, 11
  %result = select i1 %ok, i32 0, i32 1
  ret i32 %result

}

; CHECK-LABEL: define i32 @main()
; CHECK-NOT: switch i32
; CHECK-NOT: unknown:
; CHECK: ret i32
