; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='opaque_edge']; assert d['metrics']['opaque_edges_pruned']==5 and len(p)==5 and all(x['proof_engine']=='z3_bitvector_unsat' and x['result']=='proved' for x in p)"

declare i32 @llvm.bswap.i32(i32)
declare i32 @llvm.bitreverse.i32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)
declare i32 @llvm.fshr.i32(i32, i32, i32)

define i32 @opaque_bswap(i32 %x) {
; CHECK-LABEL: @opaque_bswap(
; CHECK-NOT: br i1
; CHECK: ret i32 7
  %a = call i32 @llvm.bswap.i32(i32 %x)
  %b = call i32 @llvm.bswap.i32(i32 %a)
  %same = icmp eq i32 %b, %x
  br i1 %same, label %good, label %bad
good:
  ret i32 7
bad:
  ret i32 99
}

define i32 @opaque_bitreverse(i32 %x) {
; CHECK-LABEL: @opaque_bitreverse(
; CHECK-NOT: br i1
; CHECK: ret i32 7
  %a = call i32 @llvm.bitreverse.i32(i32 %x)
  %b = call i32 @llvm.bitreverse.i32(i32 %a)
  %same = icmp eq i32 %b, %x
  br i1 %same, label %good, label %bad
good:
  ret i32 7
bad:
  ret i32 99
}

define i32 @opaque_bswap_byte_order(i32 %x) {
; CHECK-LABEL: @opaque_bswap_byte_order(
; CHECK-NOT: br i1
; CHECK: ret i32 7
  %reversed = call i32 @llvm.bswap.i32(i32 %x)
  %low = and i32 %reversed, 255
  %high.shift = lshr i32 %x, 24
  %high = and i32 %high.shift, 255
  %same = icmp eq i32 %low, %high
  br i1 %same, label %good, label %bad
good:
  ret i32 7
bad:
  ret i32 99
}

define i32 @opaque_bitreverse_bit_order(i32 %x) {
; CHECK-LABEL: @opaque_bitreverse_bit_order(
; CHECK-NOT: br i1
; CHECK: ret i32 7
  %reversed = call i32 @llvm.bitreverse.i32(i32 %x)
  %low = and i32 %reversed, 1
  %high = lshr i32 %x, 31
  %same = icmp eq i32 %low, %high
  br i1 %same, label %good, label %bad
good:
  ret i32 7
bad:
  ret i32 99
}

define i32 @opaque_symbolic_rotate(i32 %x, i32 %amount) {
; CHECK-LABEL: @opaque_symbolic_rotate(
; CHECK-NOT: br i1
; CHECK: ret i32 7
  %left = call i32 @llvm.fshl.i32(i32 %x, i32 %x, i32 %amount)
  %roundtrip = call i32 @llvm.fshr.i32(i32 %left, i32 %left, i32 %amount)
  %same = icmp eq i32 %roundtrip, %x
  br i1 %same, label %good, label %bad
good:
  ret i32 7
bad:
  ret i32 99
}

define i32 @main() {
  %a = call i32 @opaque_bswap(i32 -19088744)
  %b = call i32 @opaque_bitreverse(i32 305419896)
  %c = call i32 @opaque_symbolic_rotate(i32 -889275714, i32 77)
  %d = call i32 @opaque_bswap_byte_order(i32 -19088744)
  %e = call i32 @opaque_bitreverse_bit_order(i32 305419896)
  %a.ok = icmp eq i32 %a, 7
  %b.ok = icmp eq i32 %b, 7
  %c.ok = icmp eq i32 %c, 7
  %d.ok = icmp eq i32 %d, 7
  %e.ok = icmp eq i32 %e, 7
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %cde = and i1 %cd, %e.ok
  %ok = and i1 %ab, %cde
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
