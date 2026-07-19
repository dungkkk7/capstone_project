; RUN: opt -load-pass-plugin %plugin -passes='brighten-state-ssa-pass,brighten-state-ssa-pass,verify' -S %s | FileCheck %s

%struct.State = type { [64 x i8] }

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define void @observe(ptr %p) {
  ret void
}

define i64 @promote_non_escaping() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %slot = getelementptr i8, ptr %state, i64 16
  store i64 7, ptr %slot, align 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @promote_non_escaping()
; CHECK-NOT: alloca %struct.State
; CHECK-NOT: getelementptr i8
; CHECK: ret i64 7

define i64 @reject_escape() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  call void @observe(ptr %state)
  %slot = getelementptr i8, ptr %state, i64 16
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @reject_escape()
; CHECK: %state = alloca %struct.State
; CHECK: call void @observe(ptr %state)

define i64 @promote_overlap() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %wide = getelementptr i8, ptr %state, i64 8
  %narrow = getelementptr i8, ptr %state, i64 12
  store i64 9, ptr %wide, align 8
  store i32 3, ptr %narrow, align 4
  %value = load i64, ptr %wide, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @promote_overlap()
; CHECK-NOT: alloca %struct.State
; CHECK-NOT: getelementptr i8
; CHECK: ret i64 12884901897

define i64 @promote_partial_alias() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %rax = getelementptr i8, ptr %state, i64 0
  %ah = getelementptr i8, ptr %state, i64 1
  store i64 1234605616436508552, ptr %rax, align 8
  store i8 -86, ptr %ah, align 1
  %ax = load i16, ptr %rax, align 2
  %result = zext i16 %ax to i64
  ret i64 %result
}

; CHECK-LABEL: define i64 @promote_partial_alias()
; CHECK-NOT: alloca %struct.State
; CHECK-NOT: getelementptr i8
; CHECK: ret i64 43656

define i8 @reject_padded_i1_overlap() {
entry:
  %state = alloca %struct.State, align 8
  store %struct.State zeroinitializer, ptr %state, align 8
  %byte = getelementptr i8, ptr %state, i64 0
  store i1 true, ptr %byte, align 1
  %value = load i8, ptr %byte, align 1
  ret i8 %value
}

; CHECK-LABEL: define i8 @reject_padded_i1_overlap()
; CHECK: %state = alloca %struct.State
; CHECK: store i1 true, ptr %byte

define i64 @reject_short_zero_memset() {
entry:
  %state = alloca %struct.State, align 8
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 4, i1 false)
  %slot = getelementptr i8, ptr %state, i64 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @reject_short_zero_memset()
; CHECK: %state = alloca %struct.State
; CHECK: call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 4, i1 false)

define i64 @reject_volatile_zero_memset() {
entry:
  %state = alloca %struct.State, align 8
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 64, i1 true)
  %slot = getelementptr i8, ptr %state, i64 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; CHECK-LABEL: define i64 @reject_volatile_zero_memset()
; CHECK: %state = alloca %struct.State
; CHECK: call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 64, i1 true)

define i32 @main() {
  %a = call i64 @promote_non_escaping()
  %a.ok = icmp eq i64 %a, 7
  %b = call i64 @promote_overlap()
  %b.ok = icmp eq i64 %b, 12884901897
  %c = call i64 @promote_partial_alias()
  %c.ok = icmp eq i64 %c, 43656
  %ab = and i1 %a.ok, %b.ok
  %ok = and i1 %ab, %c.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
