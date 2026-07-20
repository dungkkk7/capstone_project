; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,brighten-ollvm-deobf-pass,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and any(x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region' and set(['closed_default_linked_lookup_ring','exact_forwarded_state_family','ordered_lookup_resolution','complete_external_edge_coverage','exact_phi_and_plumbing_translation']).issubset(x['dependencies']) for x in d['proofs'])"

define i32 @nested_shared_switch(i1 %repeat) {
; CHECK-LABEL: @nested_shared_switch(
; CHECK-NOT: switch i32
; CHECK-NOT: dispatch.header:
entry:
  br label %outer

outer:
  %outer.state = phi i32 [ 1, %entry ], [ %outer.next, %outer.latch ]
  br label %dispatch.header

dispatch.header:
  %state = phi i32 [ %outer.state, %outer ], [ %inner.next, %inner.latch ]
  %header.next = select i1 %repeat, i32 1, i32 4
  switch i32 %state, label %inner.latch [
    i32 1, label %inner.case
    i32 2, label %outer.source
    i32 3, label %outer.latch
    i32 4, label %exit
  ]

inner.case:
  br label %inner.latch

inner.latch:
  %inner.next = phi i32 [ %state, %dispatch.header ], [ 2, %inner.case ]
  br label %dispatch.header

outer.source:
  %source.next = select i1 %repeat, i32 1, i32 4
  br label %outer.latch

outer.latch:
  %outer.next = phi i32 [ %header.next, %dispatch.header ],
                          [ %source.next, %outer.source ]
  br label %outer

exit:
  ret i32 0
}

define i32 @main() {
  %result = call i32 @nested_shared_switch(i1 false)
  ret i32 %result
}
