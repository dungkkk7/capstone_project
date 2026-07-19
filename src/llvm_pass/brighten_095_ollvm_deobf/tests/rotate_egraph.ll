; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='bv_egraph_rewrite' and x['proof_engine']=='rotate_idiom_z3_unsat']; assert len(p)==2 and all(x['old_hash'] and x['new_hash'] and x['proof_query_hash'] and x['dependencies']==['constant_shift_counts_in_range','identical_poison_support'] for x in p)"

define i8 @rotl8(i8 %x) {
; CHECK-LABEL: @rotl8(
; CHECK: [[R:%.*]] = call i8 @llvm.fshl.i8(i8 %x, i8 %x, i8 3)
; CHECK-NEXT: ret i8 [[R]]
  %left = shl i8 %x, 3
  %right = lshr i8 %x, 5
  %r = or i8 %left, %right
  ret i8 %r
}

define i32 @rotl32_commuted(i32 %x) {
; CHECK-LABEL: @rotl32_commuted(
; CHECK: [[R:%.*]] = call i32 @llvm.fshl.i32(i32 %x, i32 %x, i32 13)
; CHECK-NEXT: ret i32 [[R]]
  %left = shl i32 %x, 13
  %right = lshr i32 %x, 19
  %r = or i32 %right, %left
  ret i32 %r
}

define i8 @not_a_rotate(i8 %x) {
; CHECK-LABEL: @not_a_rotate(
; CHECK: %left = shl i8 %x, 2
; CHECK-NEXT: %right = lshr i8 %x, 5
; CHECK-NEXT: %r = or i8 %left, %right
  %left = shl i8 %x, 2
  %right = lshr i8 %x, 5
  %r = or i8 %left, %right
  ret i8 %r
}

define i8 @poison_shift_retained(i8 %x) {
; CHECK-LABEL: @poison_shift_retained(
; CHECK: %left = shl nuw i8 %x, 3
; CHECK-NEXT: %right = lshr i8 %x, 5
; CHECK-NEXT: %r = or i8 %left, %right
  %left = shl nuw i8 %x, 3
  %right = lshr i8 %x, 5
  %r = or i8 %left, %right
  ret i8 %r
}

define i32 @main() {
  %a = call i8 @rotl8(i8 -91)
  %a.ok = icmp eq i8 %a, 45
  %b = call i32 @rotl32_commuted(i32 305419896)
  %b.ok = icmp eq i32 %b, -1966144954
  %ok = and i1 %a.ok, %b.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
