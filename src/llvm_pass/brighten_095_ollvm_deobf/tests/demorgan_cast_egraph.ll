; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['proof_engine'] in ('demorgan_z3_unsat','bitwise_cast_factor_z3_unsat','mask_factor_z3_unsat')]; assert len(p)==7 and all(x['kind']=='bv_egraph_rewrite' and x['result']=='proved' and x['old_hash'] and x['new_hash'] and x['proof_query_hash'] and x['dependencies']==['cost_reducing_pure_integer_dag','identical_poison_support'] for x in p)"

define i32 @demorgan_and(i32 %x, i32 %y) {
; CHECK-LABEL: @demorgan_and(
; CHECK: [[INNER:%.*]] = or i32 %x, %y
; CHECK-NEXT: [[R:%.*]] = xor i32 [[INNER]], -1
; CHECK-NEXT: ret i32 [[R]]
  %nx = xor i32 %x, -1
  %ny = xor i32 -1, %y
  %r = and i32 %nx, %ny
  ret i32 %r
}

define i32 @demorgan_or(i32 %x, i32 %y) {
; CHECK-LABEL: @demorgan_or(
; CHECK: [[INNER:%.*]] = and i32 %x, %y
; CHECK-NEXT: [[R:%.*]] = xor i32 [[INNER]], -1
; CHECK-NEXT: ret i32 [[R]]
  %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %r = or i32 %nx, %ny
  ret i32 %r
}

define i32 @factor_zext(i8 %x, i8 %y) {
; CHECK-LABEL: @factor_zext(
; CHECK: [[INNER:%.*]] = xor i8 %x, %y
; CHECK-NEXT: [[R:%.*]] = zext i8 [[INNER]] to i32
; CHECK-NEXT: ret i32 [[R]]
  %zx = zext i8 %x to i32
  %zy = zext i8 %y to i32
  %r = xor i32 %zx, %zy
  ret i32 %r
}

define i32 @factor_sext(i8 %x, i8 %y) {
; CHECK-LABEL: @factor_sext(
; CHECK: [[INNER:%.*]] = and i8 %x, %y
; CHECK-NEXT: [[R:%.*]] = sext i8 [[INNER]] to i32
; CHECK-NEXT: ret i32 [[R]]
  %sx = sext i8 %x to i32
  %sy = sext i8 %y to i32
  %r = and i32 %sx, %sy
  ret i32 %r
}

define i32 @mixed_cast_retained(i8 %x, i8 %y) {
; CHECK-LABEL: @mixed_cast_retained(
; CHECK: %zx = zext i8 %x to i32
; CHECK-NEXT: %sy = sext i8 %y to i32
; CHECK-NEXT: %r = xor i32 %zx, %sy
  %zx = zext i8 %x to i32
  %sy = sext i8 %y to i32
  %r = xor i32 %zx, %sy
  ret i32 %r
}

define i32 @shared_cast_retained(i8 %x, i8 %y) {
; CHECK-LABEL: @shared_cast_retained(
; CHECK: %zx = zext i8 %x to i32
; CHECK-NEXT: %zy = zext i8 %y to i32
; CHECK-NEXT: %r = or i32 %zx, %zy
; CHECK-NEXT: %keep = add i32 %r, %zx
  %zx = zext i8 %x to i32
  %zy = zext i8 %y to i32
  %r = or i32 %zx, %zy
  %keep = add i32 %r, %zx
  ret i32 %keep
}

define i32 @factor_and_mask_or(i32 %x, i32 %y) {
; CHECK-LABEL: @factor_and_mask_or(
; CHECK: [[INNER:%.*]] = or i32 %x, %y
; CHECK-NEXT: [[R:%.*]] = and i32 [[INNER]], 16711935
  %xm = and i32 %x, 16711935
  %ym = and i32 %y, 16711935
  %r = or i32 %xm, %ym
  ret i32 %r
}

define i32 @factor_and_mask_xor(i32 %x, i32 %y) {
; CHECK-LABEL: @factor_and_mask_xor(
; CHECK: [[INNER:%.*]] = xor i32 %x, %y
; CHECK-NEXT: [[R:%.*]] = and i32 [[INNER]], 16711935
  %xm = and i32 %x, 16711935
  %ym = and i32 %y, 16711935
  %r = xor i32 %xm, %ym
  ret i32 %r
}

define i32 @factor_or_mask_and(i32 %x, i32 %y) {
; CHECK-LABEL: @factor_or_mask_and(
; CHECK: [[INNER:%.*]] = and i32 %x, %y
; CHECK-NEXT: [[R:%.*]] = or i32 [[INNER]], 16711935
  %xm = or i32 %x, 16711935
  %ym = or i32 %y, 16711935
  %r = and i32 %xm, %ym
  ret i32 %r
}

define i32 @different_masks_retained(i32 %x, i32 %y) {
; CHECK-LABEL: @different_masks_retained(
; CHECK: %xm = and i32 %x, 255
; CHECK-NEXT: %ym = and i32 %y, 65280
; CHECK-NEXT: %r = or i32 %xm, %ym
  %xm = and i32 %x, 255
  %ym = and i32 %y, 65280
  %r = or i32 %xm, %ym
  ret i32 %r
}

define i32 @main() {
  %a = call i32 @demorgan_and(i32 305419896, i32 -2023406815)
  %a.ok = icmp eq i32 %a, 1753917574
  %b = call i32 @demorgan_or(i32 305419896, i32 -2023406815)
  %b.ok = icmp eq i32 %b, -35930657
  %c = call i32 @factor_zext(i8 -91, i8 60)
  %c.ok = icmp eq i32 %c, 153
  %d = call i32 @factor_sext(i8 -91, i8 60)
  %d.ok = icmp eq i32 %d, 36
  %e = call i32 @factor_and_mask_or(i32 305419896, i32 -2023406815)
  %e.ok = icmp eq i32 %e, 7667833
  %f = call i32 @factor_and_mask_xor(i32 305419896, i32 -2023406815)
  %f.ok = icmp eq i32 %f, 5308505
  %g = call i32 @factor_or_mask_and(i32 305419896, i32 -2023406815)
  %g.ok = icmp eq i32 %g, 50283263
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %ef = and i1 %e.ok, %f.ok
  %efg = and i1 %ef, %g.ok
  %abcd = and i1 %ab, %cd
  %ok = and i1 %abcd, %efg
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
