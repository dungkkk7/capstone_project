; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,simplifycfg,dce -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['metrics']['opaque_edges_pruned']==2; assert d['metrics']['flags_sanitized']==3"

@frame_storage_backing.test = internal global [8 x i8] zeroinitializer

define i32 @lifted(i32 %x) {
; CHECK-LABEL: @lifted
; CHECK: %a = add i32 %x, 1
; CHECK: %q = lshr i32 %a, 1
; CHECK: %p = getelementptr i8, ptr @frame_storage_backing.test, i64 1
  %a = add nsw i32 %x, 1
  %q = lshr exact i32 %a, 1
  %p = getelementptr inbounds i8, ptr @frame_storage_backing.test, i64 1
  %v = load i8, ptr %p
  %z = zext i8 %v to i32
  %r = add i32 %q, %z
  ret i32 %r
}

define i32 @opaque_true(i32 %x) {
; CHECK-LABEL: @opaque_true
; CHECK: ret i32 7
  %xm1 = add i32 %x, -1
  %prod = mul i32 %x, %xm1
  %bit = and i32 %prod, 1
  %even = icmp eq i32 %bit, 0
  br i1 %even, label %real, label %bogus
real:
  ret i32 7
bogus:
  ret i32 99
}

define i32 @opaque_or(i32 %x, i1 %unknown) {
; CHECK-LABEL: @opaque_or
; CHECK: ret i32 11
  %xm1 = sub i32 %x, 1
  %prod = mul i32 %xm1, %x
  %bit = and i32 %prod, 1
  %even = icmp eq i32 %bit, 0
  %cond = or i1 %unknown, %even
  br i1 %cond, label %real, label %bogus
real:
  ret i32 11
bogus:
  ret i32 22
}

; nsw means the parity expression can become poison in LLVM semantics.  The
; theorem prover must leave it alone unless lifted provenance sanitizes it.
define i32 @opaque_poison_guard(i32 %x) {
; CHECK-LABEL: @opaque_poison_guard
; CHECK: %xm1 = sub nsw i32 %x, 1
; CHECK: select i1 %even
  %xm1 = sub nsw i32 %x, 1
  %prod = mul i32 %x, %xm1
  %bit = and i32 %prod, 1
  %even = icmp eq i32 %bit, 0
  br i1 %even, label %a, label %b
a:
  ret i32 1
b:
  ret i32 2
}
