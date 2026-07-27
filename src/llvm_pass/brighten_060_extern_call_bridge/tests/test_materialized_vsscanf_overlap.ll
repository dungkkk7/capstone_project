; RUN: opt -load-pass-plugin %plugin -passes=brighten-extern-call-bridge -verify-each -S %s | FileCheck %s

@.input = private constant [5 x i8] c"2 50\00"
@.fmt = private constant [5 x i8] c"%d%d\00"
@guest.a = internal global [8 x i8] zeroinitializer, !brighten.guest.range !0
@guest.b = internal global [8 x i8] zeroinitializer, !brighten.guest.range !1
declare i32 @vsscanf(ptr, ptr, ptr)

define i32 @vsscanf_overlapping_guest_ranges() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  ; 0x5004 belongs to both ranges; the second destination belongs only to b.
  store i64 20484, ptr %slot0, align 8
  store i64 20488, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_overlapping_guest_ranges
; CHECK: call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
; CHECK-NOT: @sscanf

!0 = !{i64 20480, i64 20488}
!1 = !{i64 20484, i64 20492}
