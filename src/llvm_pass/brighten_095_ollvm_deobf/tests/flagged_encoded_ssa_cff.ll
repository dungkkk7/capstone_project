; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,sroa,instcombine,simplifycfg,dce,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['metrics']['dispatchers_recovered']==1 and not [p for p in d['proofs'] if p['result']!='proved']"

; Concrete dispatcher states do not overflow this flagged encoding.  State
; evaluation must validate the flags for each APInt input rather than reject
; every flagged expression before looking at its operands.

define i32 @flagged_encoded_dispatcher() {
; CHECK-LABEL: @flagged_encoded_dispatcher(
; CHECK-NOT: switch
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %latch ]
  %acc = phi i32 [ 1, %entry ], [ %acc.next, %latch ]
  %encoded = add nuw nsw i32 %state, 1
  switch i32 %encoded, label %fallback [
    i32 11, label %case10
    i32 21, label %case20
    i32 31, label %case30
    i32 41, label %case40
    i32 51, label %exit
  ]

case10:
  %acc10 = add i32 %acc, 3
  br label %latch

case20:
  %acc20 = mul i32 %acc, 5
  br label %latch

case30:
  %acc30 = xor i32 %acc, 7
  br label %latch

case40:
  %acc40 = sub i32 %acc, 2
  br label %latch

fallback:
  br label %latch

latch:
  %next = phi i32 [ 20, %case10 ], [ 30, %case20 ], [ 40, %case30 ],
                  [ 50, %case40 ], [ 50, %fallback ]
  %acc.next = phi i32 [ %acc10, %case10 ], [ %acc20, %case20 ],
                      [ %acc30, %case30 ], [ %acc40, %case40 ],
                      [ %acc, %fallback ]
  br label %dispatch

exit:
  ret i32 %acc
}

define i32 @main() {
  %result = call i32 @flagged_encoded_dispatcher()
  %ok = icmp eq i32 %result, 17
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
