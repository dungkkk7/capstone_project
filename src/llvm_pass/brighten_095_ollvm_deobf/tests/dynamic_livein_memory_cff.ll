; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and any(x['kind']=='cff_state_promotion' and 'dynamic_live_in_seeded_on_all_loop_entries' in x['dependencies'] for x in d['proofs'])"

; The state cell is supplied by the caller.  MemorySSA therefore exposes a
; LiveOnEntry definition in addition to the stores on the dispatcher cycle.
; Promotion must seed the shadow SSA cell on the external entry edge; rejecting
; LiveOnEntry makes recovery depend on an incidental initializing store.
define i32 @dynamic_memory_entry(ptr %frame_base) {
; CHECK-LABEL: @dynamic_memory_entry(
; CHECK: %deobf.dispatch.state.livein = load i32, ptr %frame_base
; CHECK-NOT: dispatch:
entry:
  br label %dispatch

dispatch:
  %state = load i32, ptr %frame_base, align 4
  switch i32 %state, label %bad [
    i32 1, label %case.1
    i32 2, label %case.2
    i32 3, label %case.3
    i32 4, label %case.4
    i32 5, label %exit
  ]

case.1:
  store i32 2, ptr %frame_base, align 4
  br label %dispatch

case.2:
  store i32 3, ptr %frame_base, align 4
  br label %dispatch

case.3:
  store i32 4, ptr %frame_base, align 4
  br label %dispatch

case.4:
  store i32 5, ptr %frame_base, align 4
  br label %dispatch

exit:
  ret i32 0

bad:
  ret i32 1
}

define i32 @main() {
entry:
  %state.slot = alloca i32, align 4
  store i32 1, ptr %state.slot, align 4
  %result = call i32 @dynamic_memory_entry(ptr %state.slot)
  ret i32 %result
}
