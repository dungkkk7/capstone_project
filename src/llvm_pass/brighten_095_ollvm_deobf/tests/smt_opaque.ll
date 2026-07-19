; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,simplifycfg,dce -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='opaque_edge']; assert len(p)==2 and all(x['proof_engine']=='z3_bitvector_unsat' for x in p)"

define i32 @smt_true(i32 %x) {
; CHECK-LABEL: @smt_true
; CHECK: ret i32 7
  %notx = xor i32 %x, -1
  %negx = sub i32 0, %x
  %rhs = sub i32 %negx, 1
  %same = icmp eq i32 %notx, %rhs
  br i1 %same, label %real, label %bogus
real:
  ret i32 7
bogus:
  ret i32 99
}

define i32 @smt_false(i16 %x, i16 %y) {
; CHECK-LABEL: @smt_false
; CHECK: ret i32 22
  %sum = add i16 %x, %y
  %carry.parts = xor i16 %x, %y
  %carry = and i16 %x, %y
  %twice = shl i16 %carry, 1
  %reconstructed = add i16 %carry.parts, %twice
  %different = icmp ne i16 %sum, %reconstructed
  br i1 %different, label %bogus, label %real
bogus:
  ret i32 11
real:
  ret i32 22
}
