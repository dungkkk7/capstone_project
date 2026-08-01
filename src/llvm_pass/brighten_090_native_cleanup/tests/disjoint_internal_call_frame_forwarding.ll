target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

declare ptr @fgets(ptr, i32, ptr)
declare i32 @vsscanf(ptr, ptr, ptr)
define internal void @consume_address(i64 %bits) noinline {
entry:
  ret void
}

@scanf_format = private constant [5 x i8] c"%d%d\00"

define internal void @nested_disjoint(ptr %base) noinline {
entry:
  %slot = getelementptr i8, ptr %base, i64 48
  store i32 17, ptr %slot, align 4
  ret void
}

define internal void @write_disjoint(ptr %base) noinline {
entry:
  %slot = getelementptr i8, ptr %base, i64 40
  store i32 11, ptr %slot, align 4
  call void @nested_disjoint(ptr %base)
  ret void
}

define internal void @write_overlap(ptr %base) noinline {
entry:
  %slot = getelementptr i8, ptr %base, i64 8
  store i64 99, ptr %slot, align 8
  ret void
}

define internal void @write_negative_disjoint(ptr %base) noinline {
entry:
  %slot = getelementptr i8, ptr %base, i64 -32
  store i64 19, ptr %slot, align 8
  ret void
}

define internal void @write_negative_overlap(ptr %base) noinline {
entry:
  %slot = getelementptr i8, ptr %base, i64 -8
  store i64 91, ptr %slot, align 8
  ret void
}

define internal { i64 } @write_negative_and_return_stack(ptr %base) noinline {
entry:
  %other = getelementptr i8, ptr %base, i64 -32
  store i64 23, ptr %other, align 8
  %bits = ptrtoint ptr %base to i64
  %next = add i64 %bits, 8
  %result = insertvalue { i64 } zeroinitializer, i64 %next, 0
  ret { i64 } %result
}

define internal void @integer_address_escape(ptr %base) noinline {
entry:
  %bits = ptrtoint ptr %base to i64
  call void @consume_address(i64 %bits)
  ret void
}

define internal i64 @proven_disjoint() noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 8
  store i64 42, ptr %slot, align 8
  call void @write_disjoint(ptr %frame_storage)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define internal i64 @overlap_refused() noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 8
  store i64 7, ptr %slot, align 8
  call void @write_overlap(ptr %frame_storage)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define internal i64 @negative_disjoint() noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %base = getelementptr i8, ptr %frame_storage, i64 2048
  %slot = getelementptr i8, ptr %base, i64 -8
  store i64 51, ptr %slot, align 8
  call void @write_negative_disjoint(ptr %base)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define internal i64 @negative_overlap_refused() noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %base = getelementptr i8, ptr %frame_storage, i64 2048
  %slot = getelementptr i8, ptr %base, i64 -8
  store i64 52, ptr %slot, align 8
  call void @write_negative_overlap(ptr %base)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define internal i64 @negative_return_disjoint() noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %base = getelementptr i8, ptr %frame_storage, i64 2048
  %slot = getelementptr i8, ptr %base, i64 -8
  store i64 53, ptr %slot, align 8
  %returned = call { i64 } @write_negative_and_return_stack(ptr %base)
  %next = extractvalue { i64 } %returned, 0
  %used = icmp ne i64 %next, 0
  %value = load i64, ptr %slot, align 8
  %kept = select i1 %used, i64 %value, i64 0
  ret i64 %kept
}

define internal i64 @integer_escape_refused() noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %base = getelementptr i8, ptr %frame_storage, i64 2048
  %slot = getelementptr i8, ptr %base, i64 -8
  store i64 54, ptr %slot, align 8
  call void @integer_address_escape(ptr %base)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @bounded_fgets_disjoint(ptr %stream) noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 8
  %buffer = getelementptr i8, ptr %frame_storage, i64 128
  store i64 123, ptr %slot, align 8
  call ptr @fgets(ptr %buffer, i32 20, ptr %stream)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @bounded_fgets_overlap(ptr %stream) noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %slot = getelementptr i8, ptr %frame_storage, i64 8
  store i64 123, ptr %slot, align 8
  call ptr @fgets(ptr %frame_storage, i32 20, ptr %stream)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @bounded_vsscanf_disjoint(ptr %input) noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %reg_save_area = alloca [48 x i8], align 16
  %va_list = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %frame_storage, i64 8
  %first_destination = getelementptr i8, ptr %frame_storage, i64 128
  %second_destination = getelementptr i8, ptr %frame_storage, i64 136
  %first_save = getelementptr i8, ptr %reg_save_area, i64 16
  %second_save = getelementptr i8, ptr %reg_save_area, i64 24
  %save_area_field = getelementptr i8, ptr %va_list, i64 16
  store ptr %first_destination, ptr %first_save, align 8
  store ptr %second_destination, ptr %second_save, align 8
  store ptr %reg_save_area, ptr %save_area_field, align 8
  store i64 321, ptr %slot, align 8
  call i32 @vsscanf(ptr %input, ptr @scanf_format, ptr %va_list)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i64 @bounded_vsscanf_overlap(ptr %input) noinline {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %reg_save_area = alloca [48 x i8], align 16
  %va_list = alloca [24 x i8], align 8
  %slot = getelementptr i8, ptr %frame_storage, i64 8
  %second_destination = getelementptr i8, ptr %frame_storage, i64 136
  %first_save = getelementptr i8, ptr %reg_save_area, i64 16
  %second_save = getelementptr i8, ptr %reg_save_area, i64 24
  %save_area_field = getelementptr i8, ptr %va_list, i64 16
  store ptr %slot, ptr %first_save, align 8
  store ptr %second_destination, ptr %second_save, align 8
  store ptr %reg_save_area, ptr %save_area_field, align 8
  store i64 321, ptr %slot, align 8
  call i32 @vsscanf(ptr %input, ptr @scanf_format, ptr %va_list)
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

define i32 @main() {
entry:
  %left = call i64 @proven_disjoint()
  %right = call i64 @overlap_refused()
  %negative = call i64 @negative_disjoint()
  %negative_overlap = call i64 @negative_overlap_refused()
  %negative_return = call i64 @negative_return_disjoint()
  %left.ok = icmp eq i64 %left, 42
  %right.ok = icmp eq i64 %right, 99
  %negative.ok = icmp eq i64 %negative, 51
  %negative_overlap.ok = icmp eq i64 %negative_overlap, 91
  %negative_return.ok = icmp eq i64 %negative_return, 53
  %positive.ok = and i1 %left.ok, %right.ok
  %negative.direct.ok = and i1 %negative.ok, %negative_overlap.ok
  %negative.all.ok = and i1 %negative.direct.ok, %negative_return.ok
  %ok = and i1 %positive.ok, %negative.all.ok
  %failed = xor i1 %ok, true
  %status = zext i1 %failed to i32
  ret i32 %status
}

; CHECK-LABEL: define internal i64 @proven_disjoint()
; CHECK-NOT: load i64
; CHECK: ret i64 42

; CHECK-LABEL: define internal i64 @overlap_refused()
; CHECK: call void @write_overlap
; CHECK: %value = load i64
; CHECK: ret i64 %value

; CHECK-LABEL: define internal i64 @negative_disjoint()
; CHECK-NOT: load i64
; CHECK: ret i64 51

; CHECK-LABEL: define internal i64 @negative_overlap_refused()
; CHECK: call void @write_negative_overlap
; CHECK: %value = load i64
; CHECK: ret i64 %value

; CHECK-LABEL: define internal i64 @negative_return_disjoint()
; CHECK: call { i64 } @write_negative_and_return_stack
; CHECK-NOT: load i64
; CHECK: select i1 %used, i64 53, i64 0

; CHECK-LABEL: define internal i64 @integer_escape_refused()
; CHECK: call void @integer_address_escape
; CHECK: %value = load i64
; CHECK: ret i64 %value

; CHECK-LABEL: define i64 @bounded_fgets_disjoint(ptr %stream)
; CHECK-NOT: load i64
; CHECK: ret i64 123

; CHECK-LABEL: define i64 @bounded_fgets_overlap(ptr %stream)
; CHECK: call ptr @fgets
; CHECK: %value = load i64
; CHECK: ret i64 %value

; CHECK-LABEL: define i64 @bounded_vsscanf_disjoint(ptr %input)
; CHECK: call i32 @vsscanf
; CHECK-NOT: load i64
; CHECK: ret i64 321

; CHECK-LABEL: define i64 @bounded_vsscanf_overlap(ptr %input)
; CHECK: call i32 @vsscanf
; CHECK: %value = load i64
; CHECK: ret i64 %value
