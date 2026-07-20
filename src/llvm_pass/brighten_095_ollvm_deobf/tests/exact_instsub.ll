; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,simplifycfg,dce -S %s -o - | FileCheck-21 %s
; RUN: lli-21 %s
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind'] in ('bv_canonicalize','instsub_rewrite')]; assert p and all(x['result']=='proved' and x['proof_engine'] in ('z3_bv_equivalence_unsat','llvm_instruction_simplify') and x['old_hash'] and x['new_hash'] and x['proof_query_hash'] and x['dependencies'] for x in p); assert not [x for x in d['proofs'] if x['kind']=='rewrite_candidate']"

define i8 @carry_i8(i8 %x, i8 %y) {
; CHECK-LABEL: @carry_i8
; CHECK: %r.deobf = add i8 %x, %y
; CHECK: ret i8 %r.deobf
  %a = xor i8 %x, %y
  %b = and i8 %x, %y
  %c = mul i8 %b, 2
  %r = add i8 %a, %c
  ret i8 %r
}

define i16 @or_i16(i16 %x, i16 %y) {
; CHECK-LABEL: @or_i16
; CHECK: %r.deobf = or i16 %x, %y
  %a = and i16 %x, %y
  %b = xor i16 %x, %y
  %r = or i16 %a, %b
  ret i16 %r
}

define i32 @xor_i32(i32 %x, i32 %y) {
; CHECK-LABEL: @xor_i32
; CHECK: %r.deobf = xor i32 %x, %y
  %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %a = and i32 %nx, %y
  %b = and i32 %x, %ny
  %r = or i32 %a, %b
  ret i32 %r
}

define i64 @cancel_i64(i64 %x) {
; CHECK-LABEL: @cancel_i64
; CHECK-NEXT: entry:
; CHECK-NEXT: ret i64 %x
entry:
  %a = add i64 %x, 9223372036854775807
  %r = sub i64 %a, 9223372036854775807
  ret i64 %r
}

define i8 @neutral_i8(i8 %x) {
; CHECK-LABEL: @neutral_i8
; CHECK-NEXT: entry:
; CHECK-NEXT: ret i8 %x
entry:
  %a = add i8 0, %x
  %b = xor i8 %a, 0
  %c = and i8 %b, -1
  %r = or i8 %c, 0
  ret i8 %r
}

define i16 @double_not_i16(i16 %x) {
; CHECK-LABEL: @double_not_i16
; CHECK-NEXT: entry:
; CHECK-NEXT: ret i16 %x
entry:
  %a = xor i16 %x, -1
  %r = xor i16 %a, -1
  ret i16 %r
}

define i32 @masked_i32(i32 %x) {
; CHECK-LABEL: @masked_i32
; CHECK: [[MASK_XOR:%.*]] = xor i32 %x, 305419896
; CHECK-NEXT: [[MASK_ADD:%.*]] = add i32 %x, [[MASK_XOR]]
; CHECK-NEXT: ret i32 [[MASK_ADD]]
  %a = and i32 %x, -305419897
  %b = or i32 %x, 305419896
  %r = add i32 %a, %b
  ret i32 %r
}

define i64 @carry_shl_commuted_i64(i64 %x, i64 %y) {
; CHECK-LABEL: @carry_shl_commuted_i64
; CHECK: %r.deobf = add i64 %x, %y
  %a = and i64 %x, %y
  %carry = shl i64 %a, 1
  %sum.no.carry = xor i64 %x, %y
  %r = add i64 %carry, %sum.no.carry
  ret i64 %r
}

; Refuse a machine-algebra rewrite when the original carries LLVM poison facts.
define i32 @preserve_nsw(i32 %x, i32 %y) {
; CHECK-LABEL: @preserve_nsw
; CHECK: %a = add nsw i32 %x, %y
  %a = add nsw i32 %x, %y
  %b = or i32 %x, %y
  %r = sub i32 %a, %b
  ret i32 %r
}

define i32 @main() {
  %a = call i8 @neutral_i8(i8 -91)
  %a.ok = icmp eq i8 %a, -91
  %b = call i16 @double_not_i16(i16 -12345)
  %b.ok = icmp eq i16 %b, -12345
  %c = call i32 @masked_i32(i32 270544960)
  %c.ok = icmp eq i32 %c, 305436280
  %d = call i64 @carry_shl_commuted_i64(i64 -5, i64 17)
  %d.ok = icmp eq i64 %d, 12
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %ok = and i1 %ab, %cd
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
