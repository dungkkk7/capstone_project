target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1 immarg)

define internal void @mutate(ptr %state) {
entry:
  %partial = getelementptr i8, ptr %state, i64 102
  store i16 -21829, ptr %partial, align 1
  ret void
}

define ptr @sub_overlap(ptr %state, i64 %pc, ptr %memory) {
entry:
  %wide = getelementptr i8, ptr %state, i64 100
  store i64 1234605616436508552, ptr %wide, align 1
  %direct.partial = getelementptr i8, ptr %state, i64 102
  store i16 -13091, ptr %direct.partial, align 1
  call void @mutate(ptr %state)
  %merged = load i64, ptr %wide, align 1
  %result = getelementptr i8, ptr %state, i64 108
  store i64 %merged, ptr %result, align 1
  ret ptr %memory
}

define i32 @main() {
entry:
  %state = alloca [256 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 256, i1 false)
  %memory = call ptr @sub_overlap(ptr %state, i64 0, ptr null)
  %result.ptr = getelementptr i8, ptr %state, i64 108
  %result = load i64, ptr %result.ptr, align 1
  %ok = icmp eq i64 %result, 1234605617868142472
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}

; CHECK-LABEL: define ptr @sub_overlap
; CHECK: %state_100 = alloca i64
; CHECK: or i64 {{.*}}, 3437035520
; CHECK: call void @mutate(ptr %state)
; CHECK: load i64, ptr {{.*}}, align 1
