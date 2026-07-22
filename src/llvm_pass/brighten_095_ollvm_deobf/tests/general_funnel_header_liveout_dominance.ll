; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine'] in ('complete_general_funnel_ssa_plumbing','complete_ssa_transition_and_plumbing_set')]; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and (('llvm_header_phi_and_liveout_demotion' in p[0]['dependencies']) or ('exact_latch_header_clone' in p[0]['dependencies'])); assert not [x for x in d['proofs'] if x['result']!='proved']"

@sink_observer = internal global i32 0

; The switch header owns both a PHI and the %header.sign/%header.not.sign
; instruction chain.  Those values feed a case body and the returning sink
; plumbing.  The sink is cloned before the next header round, so cloning
; without reg2mem leaves clones using obsolete header definitions after the
; dispatcher is bypassed.
;
; case.pre gives case.10 a second, non-lookup predecessor.  Recovery may use
; either the general funnel engine or the complete SSA-plumbing engine now
; that exact case-to-case forwarding is supported; both must demote/clone the
; header live-outs and the lli checks below guard the same dominance contract.
define i32 @general_funnel_header_liveout() {
; CHECK-LABEL: @general_funnel_header_liveout(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header
; CHECK-NOT: dispatch.outer
; CHECK-NOT: dispatch.sink
; CHECK: ret i32
entry:
  br label %dispatch.outer

dispatch.outer:
  %state = phi i32 [ 11, %entry ], [ %state.sink, %dispatch.sink ]
  %acc = phi i32 [ 1, %entry ], [ %acc.sink, %dispatch.sink ]
  br label %dispatch.header

dispatch.header:
  %header.epoch = phi i32 [ 0, %dispatch.outer ], [ 1, %dispatch.header ]
  %header.sign = lshr i32 %state, 31
  %header.not.sign.base = xor i32 %header.sign, 1
  %header.not.sign = add i32 %header.not.sign.base, %header.epoch
  %header.take.join = icmp eq i32 %header.epoch, 0
  switch i32 %state, label %dispatch.header [
    i32 10, label %case.10
    i32 11, label %case.pre
    i32 15, label %dispatch.sink
    i32 20, label %case.20
    i32 30, label %case.join
    i32 40, label %exit
  ]

case.pre:
  br label %case.10

case.10:
  %acc.10.base = add i32 %acc, 2
  %acc.10.bias = sub i32 %header.not.sign, 1
  %acc.10 = add i32 %acc.10.base, %acc.10.bias
  br label %dispatch.sink

case.20:
  %acc.20 = add i32 %acc, 3
  %next.20 = select i1 %header.take.join, i32 30, i32 40
  br label %dispatch.sink

case.join:
  %joined = phi i32 [ %acc, %dispatch.header ]
  %acc.30 = add i32 %joined, 4
  br label %dispatch.sink

dispatch.sink:
  %state.sink = phi i32 [ 20, %dispatch.header ],
                          [ 15, %case.10 ],
                          [ %next.20, %case.20 ],
                          [ 40, %case.join ]
  %acc.sink = phi i32 [ %acc, %dispatch.header ],
                        [ %acc.10, %case.10 ],
                        [ %acc.20, %case.20 ],
                        [ %acc.30, %case.join ]
  %sink.mix = xor i32 %state.sink, %header.sign
  %sink.mix.next = add i32 %sink.mix, %header.not.sign
  store volatile i32 %sink.mix.next, ptr @sink_observer
  br label %dispatch.outer

exit:
  ret i32 %acc
}

define i32 @main() {
  %result = call i32 @general_funnel_header_liveout()
  %ok = icmp eq i32 %result, 10
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
