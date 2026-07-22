; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and any(x['kind']=='cff_state_promotion' and x['proof_engine']=='memoryssa_exact_cell_mem2reg' and 'no_live_on_entry_or_unknown_clobber' in x['dependencies'] for x in d['proofs'])"

@nested.inner.state = internal global i32 0

define i32 @nested_inner_load_dispatch() {
; CHECK-LABEL: @nested_inner_load_dispatch(
; CHECK-NOT: switch i32
; CHECK-NOT: dispatch:
; CHECK: ret i32 7
entry:
  store i32 1, ptr @nested.inner.state
  br label %loop.header

loop.header:
  br label %dispatch

dispatch:
  %state = load i32, ptr @nested.inner.state
  switch i32 %state, label %loop.latch [
    i32 1, label %case.one
    i32 2, label %exit
    i32 3, label %case.three
    i32 4, label %case.four
  ]

case.one:
  store i32 2, ptr @nested.inner.state
  br label %loop.latch

case.three:
  store i32 2, ptr @nested.inner.state
  br label %loop.latch

case.four:
  store i32 2, ptr @nested.inner.state
  br label %loop.latch

loop.latch:
  br label %loop.header

exit:
  ret i32 7
}

define i32 @main() {
  ret i32 0
}
