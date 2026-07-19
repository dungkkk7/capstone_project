; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='bv_egraph_rewrite']; assert d['metrics']['egraph_rewrites'] >= 2 and d['metrics']['poison_support_rejects'] >= 1; assert len(p) >= 2 and all(x['result']=='proved' and x['proof_engine']=='affine_saturation_z3_unsat' and x['old_hash'] and x['new_hash'] and x['proof_query_hash'] and x['dependencies']==['pure_integer_dag','llvm_poison_flags_absent'] for x in p); assert not [x for x in d['proofs'] if x['kind']=='bv_egraph_candidate']"

define i32 @collapse_one(i32 %x) {
; CHECK-LABEL: @collapse_one(
; CHECK: [[R:%.*]] = add i32 %x, 9
; CHECK-NEXT: ret i32 [[R]]
  %a = mul i32 %x, 3
  %b = mul i32 %x, 5
  %c = add i32 %a, %b
  %d = mul i32 %x, 7
  %e = sub i32 %c, %d
  %r = add i32 %e, 9
  ret i32 %r
}

define i32 @collapse_two(i32 %x, i32 %y) {
; CHECK-LABEL: @collapse_two(
; CHECK: [[R:%.*]] = add i32 %x, %y
; CHECK-NEXT: ret i32 [[R]]
  %x9 = mul i32 %x, 9
  %x8 = mul i32 %x, 8
  %dx = sub i32 %x9, %x8
  %y5 = mul i32 %y, 5
  %y4 = mul i32 %y, 4
  %dy = sub i32 %y5, %y4
  %r = add i32 %dx, %dy
  ret i32 %r
}

; x may be poison.  Replacing the result with a non-poison constant would not
; preserve LLVM semantics even though the mathematical BV expression is zero.
define i32 @poison_sensitive_cancel(i32 %x) {
; CHECK-LABEL: @poison_sensitive_cancel(
; CHECK: %scaled = mul i32 %x, 3
; CHECK-NEXT: %r = sub i32 %scaled, %scaled
; CHECK-NEXT: ret i32 %r
  %scaled = mul i32 %x, 3
  %r = sub i32 %scaled, %scaled
  ret i32 %r
}

define i32 @main() {
  %a = call i32 @collapse_one(i32 2147483644)
  %a.ok = icmp eq i32 %a, -2147483643
  %b = call i32 @collapse_two(i32 2147483647, i32 17)
  %b.ok = icmp eq i32 %b, -2147483632
  %c = call i32 @poison_sensitive_cancel(i32 123)
  %c.ok = icmp eq i32 %c, 0
  %ab = and i1 %a.ok, %b.ok
  %ok = and i1 %ab, %c.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
