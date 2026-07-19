; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x.get('proof_engine')=='z3_bv_tuple_equivalence_unsat']; assert d['metrics']['flag_cones_recovered']==9 and len(p)==9"

define i8 @wide_add_flags(i32 %a, i32 %b) {
; CHECK-LABEL: @wide_add_flags(
; CHECK: [[SUM:%.*]] = add i32 %a, %b
; CHECK: trunc i32 [[SUM]] to i8
; CHECK: call i8 @llvm.ctpop.i8
  %sum = add i32 %a, %b
  %zf = icmp eq i32 %sum, 0
  %sf.shift = lshr i32 %sum, 31
  %sf = trunc i32 %sf.shift to i1
  %byte = trunc i32 %sum to i8
  %p4 = lshr i8 %byte, 4
  %px4 = xor i8 %byte, %p4
  %p2 = lshr i8 %px4, 2
  %px2 = xor i8 %px4, %p2
  %p1 = lshr i8 %px2, 1
  %px1 = xor i8 %px2, %p1
  %odd = trunc i8 %px1 to i1
  %pf = xor i1 %odd, true
  %zf8 = zext i1 %zf to i8
  %sf8 = zext i1 %sf to i8
  %pf8 = zext i1 %pf to i8
  %sf.bit = shl i8 %sf8, 1
  %pf.bit = shl i8 %pf8, 2
  %m = or i8 %zf8, %sf.bit
  %flags = or i8 %m, %pf.bit
  ret i8 %flags
}

define i8 @wide_sub_flags(i32 %a, i32 %b) {
; CHECK-LABEL: @wide_sub_flags(
; CHECK: [[DIFF:%.*]] = sub i32 %a, %b
; CHECK: trunc i32 [[DIFF]] to i8
; CHECK: call i8 @llvm.ctpop.i8
  %diff = sub i32 %a, %b
  %zf = icmp eq i32 %diff, 0
  %sf.shift = lshr i32 %diff, 31
  %sf = trunc i32 %sf.shift to i1
  %byte = trunc i32 %diff to i8
  %p4 = lshr i8 %byte, 4
  %px4 = xor i8 %byte, %p4
  %p2 = lshr i8 %px4, 2
  %px2 = xor i8 %px4, %p2
  %p1 = lshr i8 %px2, 1
  %px1 = xor i8 %px2, %p1
  %odd = trunc i8 %px1 to i1
  %pf = xor i1 %odd, true
  %zf8 = zext i1 %zf to i8
  %sf8 = zext i1 %sf to i8
  %pf8 = zext i1 %pf to i8
  %sf.bit = shl i8 %sf8, 1
  %pf.bit = shl i8 %pf8, 2
  %m = or i8 %zf8, %sf.bit
  %flags = or i8 %m, %pf.bit
  ret i8 %flags
}

define i8 @wide_test_flags(i32 %a, i32 %b) {
; CHECK-LABEL: @wide_test_flags(
; CHECK: [[RESULT:%.*]] = and i32 %a, %b
; CHECK: trunc i32 [[RESULT]] to i8
; CHECK: call i8 @llvm.ctpop.i8
  %result = and i32 %a, %b
  %zf = icmp eq i32 %result, 0
  %sf.shift = lshr i32 %result, 31
  %sf = trunc i32 %sf.shift to i1
  %byte = trunc i32 %result to i8
  %p4 = lshr i8 %byte, 4
  %px4 = xor i8 %byte, %p4
  %p2 = lshr i8 %px4, 2
  %px2 = xor i8 %px4, %p2
  %p1 = lshr i8 %px2, 1
  %px1 = xor i8 %px2, %p1
  %odd = trunc i8 %px1 to i1
  %pf = xor i1 %odd, true
  %zf8 = zext i1 %zf to i8
  %sf8 = zext i1 %sf to i8
  %pf8 = zext i1 %pf to i8
  %sf.bit = shl i8 %sf8, 1
  %pf.bit = shl i8 %pf8, 2
  %m = or i8 %zf8, %sf.bit
  %flags = or i8 %m, %pf.bit
  ret i8 %flags
}

define i32 @main() {
  %a = call i8 @wide_add_flags(i32 -2147483392, i32 0)
  %s = call i8 @wide_sub_flags(i32 -2147483392, i32 0)
  %t = call i8 @wide_test_flags(i32 -2147483392, i32 -1)
  %as = add i8 %a, %s
  %all = add i8 %as, %t
  %ok = icmp eq i8 %all, 18
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
