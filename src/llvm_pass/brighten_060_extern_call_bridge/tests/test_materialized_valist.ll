; RUN: opt -load-pass-plugin %plugin -passes=brighten-extern-call-bridge -S %s | FileCheck %s
;
; A previous native cleanup stage may have materialized a SysV va_list for a
; lifted printf bridge.  Pass 060 owns external ABI recovery, so a later 060
; sweep should turn the explicit save-area representation back into a direct
; native variadic call.

@.fmt = private constant [4 x i8] c"%ld\00"
@.float_fmt = private constant [7 x i8] c"%.9lf\0A\00"
@.file_scan = private constant [3 x i8] c"%d\00"
@.scan8 = private constant [25 x i8] c"%lf%lf%lf%lf%lf%lf%lf%lf\00"
@.scan6 = private constant [19 x i8] c"%lf%lf%lf%lf%lf%lf\00"
@.unrelated = private constant [3 x i8] c"%d\00"
@frame_storage_backing.test = internal global [256 x i8] zeroinitializer

declare i32 @vprintf(ptr, ptr)
declare i32 @vscanf(ptr, ptr)
declare i64 @vfscanf(ptr, ptr, ptr)

define i32 @materialized_printf(i64 %x) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %save, i64 8
  store i64 %x, ptr %slot, align 8
  store i32 8, ptr %va, align 8
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vprintf(ptr @.fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_printf
; CHECK: call i32 (ptr, ...) @printf(ptr @.fmt, i64 %x)
; CHECK-NOT: call i32 @vprintf

define i64 @materialized_file_scanf(ptr %stream, ptr %destination) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %gp.slot = getelementptr i8, ptr %save, i64 8
  store ptr %destination, ptr %gp.slot, align 8
  store i32 8, ptr %va, align 8
  %fp.offset = getelementptr i8, ptr %va, i64 4
  store i32 48, ptr %fp.offset, align 4
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr null, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i64 @vfscanf(ptr %stream, ptr @.file_scan, ptr %va)
  ret i64 %ret
}

; CHECK-LABEL: define i64 @materialized_file_scanf
; CHECK: %native.vararg.direct = call i32 (ptr, ptr, ...) @fscanf(ptr %stream, ptr @.file_scan, ptr %destination)
; CHECK: %{{.*}} = zext i32 %native.vararg.direct to i64
; CHECK-NOT: call i64 @vfscanf

define i32 @materialized_printf_double(i64 %double.bits) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %fp.slot = getelementptr i8, ptr %save, i64 48
  store i64 %double.bits, ptr %fp.slot, align 8
  store i32 8, ptr %va, align 8
  %fp.offset = getelementptr i8, ptr %va, i64 4
  store i32 48, ptr %fp.offset, align 4
  %overflow = getelementptr i8, ptr %va, i64 8
  store ptr poison, ptr %overflow, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vprintf(ptr @.float_fmt, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_printf_double
; CHECK: %{{.*}} = bitcast i64 %double.bits to double
; CHECK: call i32 (ptr, ...) @printf(ptr @.float_fmt, double %{{.*}})
; CHECK-NOT: call i32 @vprintf

define i32 @materialized_scanf_overflow(ptr %a, ptr %b, ptr %c, ptr %d,
                                        ptr %e, i64 %rsp) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %anchor = getelementptr i8, ptr @frame_storage_backing.test, i64 128
  %overflow.slots = getelementptr i8, ptr %anchor, i64 %rsp
  store i64 -24, ptr %overflow.slots, align 8
  %overflow.1 = getelementptr i8, ptr %overflow.slots, i64 8
  store i64 -16, ptr %overflow.1, align 8
  %overflow.2 = getelementptr i8, ptr %overflow.slots, i64 16
  store i64 -8, ptr %overflow.2, align 8
  %s1 = getelementptr i8, ptr %save, i64 8
  %s2 = getelementptr i8, ptr %save, i64 16
  %s3 = getelementptr i8, ptr %save, i64 24
  %s4 = getelementptr i8, ptr %save, i64 32
  %s5 = getelementptr i8, ptr %save, i64 40
  store ptr %a, ptr %s1, align 8
  store ptr %b, ptr %s2, align 8
  store ptr %c, ptr %s3, align 8
  store ptr %d, ptr %s4, align 8
  store ptr %e, ptr %s5, align 8
  store i32 8, ptr %va, align 8
  %overflow.field = getelementptr i8, ptr %va, i64 8
  store ptr %overflow.slots, ptr %overflow.field, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  ; Pass 070's native data range chain keeps the original pointer on the false
  ; edge while true edges can reference unrelated recovered strings.
  %is.guest = icmp eq i64 ptrtoint (ptr @.scan8 to i64), 4210701
  %native.data.pointer.select.test = select i1 %is.guest, ptr @.unrelated, ptr @.scan8
  %ret = call i32 @vscanf(ptr %native.data.pointer.select.test, ptr %va)
  ret i32 %ret
}

; CHECK-LABEL: define i32 @materialized_scanf_overflow
; CHECK: %native.overflow.frame.ptr = getelementptr i8, ptr %anchor, i64 -24
; CHECK: getelementptr i8, ptr %anchor, i64 -16
; CHECK: getelementptr i8, ptr %anchor, i64 -8
; CHECK: call i32 (ptr, ...) @scanf(ptr %native.data.pointer.select.test, ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %native.overflow.frame.ptr{{[0-9]*}}, ptr %native.overflow.frame.ptr{{[0-9]*}}, ptr %native.overflow.frame.ptr{{[0-9]*}})
; CHECK-NOT: call i32 @vscanf

; A concrete recovered backing initializes RSP/RBP with ptrtoint(frame_top).
; Affine stack coordinates based on that State value are therefore native
; absolute addresses already; adding frame_top again would double the address.
define internal i32 @materialized_scanf_absolute(ptr %frame_base, ptr %a,
                                                 ptr %b, ptr %c, ptr %d,
                                                 ptr %e,
                                                 i64 %state_in_2328) {
entry:
  %save = alloca [176 x i8], align 16
  %va = alloca [24 x i8], align 8
  %absolute = add i64 %state_in_2328, -24
  store i64 %absolute, ptr %frame_base, align 8
  %s1 = getelementptr i8, ptr %save, i64 8
  %s2 = getelementptr i8, ptr %save, i64 16
  %s3 = getelementptr i8, ptr %save, i64 24
  %s4 = getelementptr i8, ptr %save, i64 32
  %s5 = getelementptr i8, ptr %save, i64 40
  store ptr %a, ptr %s1, align 8
  store ptr %b, ptr %s2, align 8
  store ptr %c, ptr %s3, align 8
  store ptr %d, ptr %s4, align 8
  store ptr %e, ptr %s5, align 8
  store i32 8, ptr %va, align 8
  %overflow.field = getelementptr i8, ptr %va, i64 8
  store ptr %frame_base, ptr %overflow.field, align 8
  %save.field = getelementptr i8, ptr %va, i64 16
  store ptr %save, ptr %save.field, align 8
  %ret = call i32 @vscanf(ptr @.scan6, ptr %va)
  ret i32 %ret
}

; Model primary cleanup outlining the recovered function and passing its
; proven recovered frame top as an explicit argument.
define i32 @materialized_scanf_absolute_driver(ptr %a, ptr %b, ptr %c, ptr %d,
                                               ptr %e, i64 %state_in_2328) {
entry:
  %anchor = getelementptr i8, ptr @frame_storage_backing.test, i64 128
  %ret = call i32 @materialized_scanf_absolute(ptr %anchor, ptr %a, ptr %b,
                                               ptr %c, ptr %d, ptr %e,
                                               i64 %state_in_2328)
  ret i32 %ret
}

; CHECK-LABEL: define internal i32 @materialized_scanf_absolute
; CHECK: %native.overflow.absolute.ptr = inttoptr i64 %absolute to ptr
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan6, ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %native.overflow.absolute.ptr)
; CHECK-NOT: native.overflow.frame.ptr
; CHECK-NOT: call i32 @vscanf
