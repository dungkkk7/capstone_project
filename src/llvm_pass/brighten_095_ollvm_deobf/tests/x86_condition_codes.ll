; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='x86_flag_recovery']; assert d['metrics']['flag_cones_recovered']==6 and len(p)==6 and all(x['proof_engine']=='z3_bv_equivalence_unsat' for x in p)"

define i1 @cc_ae(i8 %a, i8 %b) {
; CHECK-LABEL: @cc_ae(
; CHECK-NEXT: [[P:%.*]] = icmp uge i8 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %cf = icmp ult i8 %a, %b
  %ae = xor i1 %cf, true
  ret i1 %ae
}

define i1 @cc_a(i8 %a, i8 %b) {
; CHECK-LABEL: @cc_a(
; CHECK-NEXT: [[P:%.*]] = icmp ugt i8 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %cf = icmp ult i8 %a, %b
  %zf = icmp eq i8 %a, %b
  %be = or i1 %cf, %zf
  %a.cc = xor i1 %be, true
  ret i1 %a.cc
}

define i1 @cc_ge(i16 %a, i16 %b) {
; CHECK-LABEL: @cc_ge(
; CHECK-NEXT: [[P:%.*]] = icmp sge i16 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  ; SF xor OF has already been recovered to the equivalent signed-less flag.
  %l = icmp slt i16 %a, %b
  %ge = xor i1 %l, true
  ret i1 %ge
}

define i1 @cc_le(i16 %a, i16 %b) {
; CHECK-LABEL: @cc_le(
; CHECK-NEXT: [[P:%.*]] = icmp sle i16 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %l = icmp slt i16 %a, %b
  %zf = icmp eq i16 %a, %b
  %le = or i1 %l, %zf
  ret i1 %le
}

define i1 @cc_g(i16 %a, i16 %b) {
; CHECK-LABEL: @cc_g(
; CHECK-NEXT: [[P:%.*]] = icmp sgt i16 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %l = icmp slt i16 %a, %b
  %zf = icmp eq i16 %a, %b
  %le = or i1 %l, %zf
  %g = xor i1 %le, true
  ret i1 %g
}

define i1 @cc_ne_sub(i32 %a, i32 %b) {
; CHECK-LABEL: @cc_ne_sub(
; CHECK-NEXT: [[P:%.*]] = icmp ne i32 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %result = sub i32 %a, %b
  %nz = icmp ne i32 %result, 0
  ret i1 %nz
}

define i32 @main() {
  %ae.t = call i1 @cc_ae(i8 9, i8 9)
  %ae.f0 = call i1 @cc_ae(i8 8, i8 9)
  %ae.f = xor i1 %ae.f0, true
  %a.t = call i1 @cc_a(i8 9, i8 8)
  %a.f0 = call i1 @cc_a(i8 9, i8 9)
  %a.f = xor i1 %a.f0, true
  %ge.t = call i1 @cc_ge(i16 -2, i16 -2)
  %ge.f0 = call i1 @cc_ge(i16 -3, i16 -2)
  %ge.f = xor i1 %ge.f0, true
  %le.t = call i1 @cc_le(i16 -3, i16 -2)
  %le.f0 = call i1 @cc_le(i16 4, i16 -2)
  %le.f = xor i1 %le.f0, true
  %g.t = call i1 @cc_g(i16 4, i16 -2)
  %g.f0 = call i1 @cc_g(i16 -2, i16 -2)
  %g.f = xor i1 %g.f0, true
  %ne.t = call i1 @cc_ne_sub(i32 4, i32 -2)
  %ne.f0 = call i1 @cc_ne_sub(i32 4, i32 4)
  %ne.f = xor i1 %ne.f0, true
  %x0 = and i1 %ae.t, %ae.f
  %x1 = and i1 %a.t, %a.f
  %x2 = and i1 %ge.t, %ge.f
  %x3 = and i1 %le.t, %le.f
  %x4 = and i1 %g.t, %g.f
  %x5 = and i1 %ne.t, %ne.f
  %y0 = and i1 %x0, %x1
  %y1 = and i1 %x2, %x3
  %y2 = and i1 %x4, %x5
  %z0 = and i1 %y0, %y1
  %ok = and i1 %z0, %y2
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
