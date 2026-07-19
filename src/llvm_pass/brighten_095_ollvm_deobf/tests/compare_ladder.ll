; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['metrics']['compare_ladders_recovered']==1; assert d['metrics']['dispatchers_unresolved']==0; assert sum(x['kind']=='compare_ladder' and x['result']=='proved' for x in d['proofs'])==1"

define i32 @ladder(i32 %key) {
; CHECK-LABEL: @ladder
; CHECK: l0:
; CHECK: switch i32 %key, label %miss [
; CHECK: i32 11, label %hit1
; CHECK: i32 22, label %hit2
; CHECK: i32 33, label %hit3
; CHECK: i32 44, label %hit4
; CHECK-NOT: l1:
; CHECK-NOT: l2:
; CHECK-NOT: l3:
entry:
  br label %l0
l0:
  %c0 = icmp eq i32 %key, 11
  br i1 %c0, label %hit1, label %l1
l1:
  %c1 = icmp ne i32 %key, 22
  br i1 %c1, label %l2, label %hit2
l2:
  %c2 = icmp eq i32 33, %key
  br i1 %c2, label %hit3, label %l3
l3:
  %c3 = icmp eq i32 %key, 44
  br i1 %c3, label %hit4, label %miss
hit1:
  ret i32 1
hit2:
  ret i32 2
hit3:
  ret i32 3
hit4:
  ret i32 4
miss:
  ret i32 9
}

define void @effect(i32 %value) noinline {
  ret void
}

define i32 @side_effect_ladder(i32 %key) {
; CHECK-LABEL: @side_effect_ladder
; CHECK: s1:
; CHECK-NEXT: call void @effect(i32 22)
; CHECK-NEXT: %s1.c = icmp eq i32 %key, 22
; CHECK-NEXT: br i1 %s1.c
entry: br label %s0
s0:
  %s0.c = icmp eq i32 %key, 11
  br i1 %s0.c, label %hit, label %s1
s1:
  call void @effect(i32 22)
  %s1.c = icmp eq i32 %key, 22
  br i1 %s1.c, label %hit, label %s2
s2:
  %s2.c = icmp eq i32 %key, 33
  br i1 %s2.c, label %hit, label %s3
s3:
  %s3.c = icmp eq i32 %key, 44
  br i1 %s3.c, label %hit, label %miss
hit: ret i32 1
miss: ret i32 0
}

define i32 @main() {
  %a = call i32 @ladder(i32 11)
  %b = call i32 @ladder(i32 22)
  %c = call i32 @ladder(i32 33)
  %d = call i32 @ladder(i32 44)
  %e = call i32 @ladder(i32 55)
  %a.ok = icmp eq i32 %a, 1
  %b.ok = icmp eq i32 %b, 2
  %c.ok = icmp eq i32 %c, 3
  %d.ok = icmp eq i32 %d, 4
  %e.ok = icmp eq i32 %e, 9
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %abcd = and i1 %ab, %cd
  %ok = and i1 %abcd, %e.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
