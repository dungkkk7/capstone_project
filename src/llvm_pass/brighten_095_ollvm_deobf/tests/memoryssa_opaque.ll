; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='opaque_edge' and x['proof_engine'].startswith('z3_memoryssa')]; assert len(p)==4 and d['metrics']['memoryssa_constrained_opaque_edges']==4 and d['metrics']['path_constrained_opaque_edges']==1 and d['metrics']['memoryssa_reaching_loads']>=5 and d['metrics']['memoryssa_phis_resolved']>=1 and d['metrics']['memoryssa_barriers']>=4; assert all('memoryssa_exact_reaching_store' in x['dependencies'] and any(y.startswith('memoryssa_load_count=') for y in x['dependencies']) for x in p); assert not [x for x in d['proofs'] if x['function'] in ('memoryphi_different_unknown','call_clobber_unknown','volatile_unknown','atomic_unknown') and x['kind']=='opaque_edge']"

define i32 @same_store(i32 %x) {
; CHECK-LABEL: @same_store(
entry:
  %p = alloca i32
  store i32 %x, ptr %p
  %a = load i32, ptr %p
  %b = load i32, ptr %p
  %eq = icmp eq i32 %a, %b
; CHECK: br label %yes
  br i1 %eq, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @distinct_allocas(i32 %x, i32 %y) {
; CHECK-LABEL: @distinct_allocas(
entry:
  %p = alloca i32
  %q = alloca i32
  store i32 %x, ptr %p
  store i32 %y, ptr %q
  %a = load i32, ptr %p
  %eq = icmp eq i32 %a, %x
; CHECK: br label %yes
  br i1 %eq, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @memory_and_path(i32 %x) {
; CHECK-LABEL: @memory_and_path(
entry:
  %p = alloca i32
  store i32 %x, ptr %p
  %guard = icmp ult i32 %x, 10
  br i1 %guard, label %bounded, label %other
bounded:
  %loaded = load i32, ptr %p
  %implied = icmp ult i32 %loaded, 20
; CHECK: br label %yes
  br i1 %implied, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
other:
  ret i32 2
}

define i32 @memoryphi_same(i1 %choose, i32 %x) {
; CHECK-LABEL: @memoryphi_same(
entry:
  %p = alloca i32
  br i1 %choose, label %left, label %right
left:
  store i32 %x, ptr %p
  br label %merge
right:
  store i32 %x, ptr %p
  br label %merge
merge:
  %loaded = load i32, ptr %p
  %eq = icmp eq i32 %loaded, %x
; CHECK: br label %yes
  br i1 %eq, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @memoryphi_different_unknown(i1 %choose, i32 %x, i32 %y) {
; CHECK-LABEL: @memoryphi_different_unknown(
entry:
  %p = alloca i32
  br i1 %choose, label %left, label %right
left:
  store i32 %x, ptr %p
  br label %merge
right:
  store i32 %y, ptr %p
  br label %merge
merge:
  %loaded = load i32, ptr %p
  %unknown = icmp eq i32 %loaded, %x
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define internal void @clobber(ptr %p) {
  store i32 7, ptr %p
  ret void
}

define i32 @call_clobber_unknown(i32 %x) {
; CHECK-LABEL: @call_clobber_unknown(
entry:
  %p = alloca i32
  store i32 %x, ptr %p
  call void @clobber(ptr %p)
  %loaded = load i32, ptr %p
  %unknown = icmp eq i32 %loaded, %x
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @volatile_unknown(i32 %x) {
; CHECK-LABEL: @volatile_unknown(
entry:
  %p = alloca i32
  store volatile i32 %x, ptr %p
  %a = load volatile i32, ptr %p
  %b = load volatile i32, ptr %p
  %unknown = icmp eq i32 %a, %b
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @atomic_unknown(i32 %x) {
; CHECK-LABEL: @atomic_unknown(
entry:
  %p = alloca i32
  store atomic i32 %x, ptr %p monotonic, align 4
  %a = load atomic i32, ptr %p monotonic, align 4
  %b = load atomic i32, ptr %p monotonic, align 4
  %unknown = icmp eq i32 %a, %b
; CHECK: br i1 %unknown, label %yes, label %no
  br i1 %unknown, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @main() {
  %a = call i32 @same_store(i32 123)
  %a.ok = icmp eq i32 %a, 1
  %b = call i32 @distinct_allocas(i32 77, i32 88)
  %b.ok = icmp eq i32 %b, 1
  %c = call i32 @memory_and_path(i32 5)
  %c.ok = icmp eq i32 %c, 1
  %d = call i32 @memoryphi_same(i1 false, i32 99)
  %d.ok = icmp eq i32 %d, 1
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %ok = and i1 %ab, %cd
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
