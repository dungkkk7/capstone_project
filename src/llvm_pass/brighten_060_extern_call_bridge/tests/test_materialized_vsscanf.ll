; RUN: opt -load-pass-plugin %plugin -passes=brighten-extern-call-bridge -verify-each -S %s | FileCheck %s
;
; vsscanf recovery is deliberately narrower than the existing vscanf path.
; The literal destination addresses below are guest coordinates, not host
; pointers: lower only when one guest-range object contains the full write.

@.input = private constant [5 x i8] c"2 50\00"
@.fmt = private constant [5 x i8] c"%d%d\00"
@guest.dest = internal global [8 x i8] zeroinitializer, !brighten.guest.range !0

declare i32 @vsscanf(ptr, ptr, ptr)

define i32 @vsscanf_guest_destinations() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  store i64 4096, ptr %slot0, align 8
  store i64 4100, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_guest_destinations
; CHECK: @sscanf{{.*}}@guest{{.}}dest
; CHECK-NOT: call i32 @vsscanf

; Dynamic guest coordinates remain in the materialized call.
define i32 @vsscanf_dynamic_destination(i64 %address) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  store i64 %address, ptr %slot0, align 8
  store i64 4100, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_dynamic_destination
; CHECK: call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
; CHECK-NOT: @sscanf

; Out-of-range and volatile setup both preserve the original call.
define i32 @vsscanf_out_of_range() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  store i64 4101, ptr %slot0, align 8
  store i64 4100, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_out_of_range
; CHECK: call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
; CHECK-NOT: @sscanf

define i32 @vsscanf_volatile_slot() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  store volatile i64 4096, ptr %slot0, align 8
  store i64 4100, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_volatile_slot
; CHECK: call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
; CHECK-NOT: @sscanf

define i32 @vsscanf_atomic_slot() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  store atomic i64 4096, ptr %slot0 seq_cst, align 8
  store i64 4100, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_atomic_slot
; CHECK: call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
; CHECK-NOT: @sscanf

; An extra unconsumed save slot is not a scanf destination and must not become
; a third native argument.
define i32 @vsscanf_unconsumed_slot() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  %slot2 = getelementptr i8, ptr %save, i64 32
  store i64 4096, ptr %slot0, align 8
  store i64 4100, ptr %slot1, align 8
  store i64 3735928559, ptr %slot2, align 8
  store i32 16, ptr %va, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_unconsumed_slot
; CHECK: @sscanf{{.*}}@guest{{.}}dest
; CHECK: ret i32

; Offset-defining GEPs are commonly hoisted to entry while the va_list stores
; and the call are in a later native block.  The matcher must follow that
; structural form without relying on instruction locality of the GEP itself.
define i32 @vsscanf_entry_geps_later_call() {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot0 = getelementptr i8, ptr %save, i64 16
  %slot1 = getelementptr i8, ptr %save, i64 24
  %overflow = getelementptr i8, ptr %va, i64 8
  %save.field = getelementptr i8, ptr %va, i64 16
  br label %later

later:
  store i64 4096, ptr %slot0, align 8
  store i64 4100, ptr %slot1, align 8
  store i32 16, ptr %va, align 8
  store ptr null, ptr %overflow, align 8
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vsscanf(ptr @.input, ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @vsscanf_entry_geps_later_call
; CHECK: @sscanf{{.*}}@guest{{.}}dest
; CHECK-NOT: call i32 @vsscanf
; CHECK-NOT: 3735928559

!0 = !{i64 4096, i64 4104}
