; Repeated generated guest-or-native resolver trees are outlined only when
; each unsigned bound and native GEP proves the same affine address.  The
; second function deliberately disagrees by one byte and must remain inline.

@native_residual_data = internal global [16 x i8] zeroinitializer
@native_residual_rodata = internal constant [8 x i8] zeroinitializer

define i8 @exact_resolver(i64 %address) {
entry:
  %native.address.fallback = inttoptr i64 %address to ptr
  %data.offset = add i64 %address, -4096
  %data.in.range = icmp ult i64 %data.offset, 16
  %data.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_data, i64 -4096), i64 %address
  %native.data.pointer.select = select i1 %data.in.range, ptr %data.pointer, ptr %native.address.fallback
  %rodata.offset = add i64 %address, -8192
  %rodata.in.range = icmp ult i64 %rodata.offset, 8
  %rodata.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_rodata, i64 -8192), i64 %address
  %native.data.pointer.select.outer = select i1 %rodata.in.range, ptr %rodata.pointer, ptr %native.data.pointer.select
  %value = load i8, ptr %native.data.pointer.select.outer
  ret i8 %value
}

define i8 @mismatched_resolver(i64 %address) {
entry:
  %native.address.fallback = inttoptr i64 %address to ptr
  %data.offset.wrong = add i64 %address, -4095
  %data.in.range = icmp ult i64 %data.offset.wrong, 16
  %data.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_data, i64 -4096), i64 %address
  %native.data.pointer.select = select i1 %data.in.range, ptr %data.pointer, ptr %native.address.fallback
  %rodata.offset = add i64 %address, -8192
  %rodata.in.range = icmp ult i64 %rodata.offset, 8
  %rodata.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_rodata, i64 -8192), i64 %address
  %native.data.pointer.select.outer = select i1 %rodata.in.range, ptr %rodata.pointer, ptr %native.data.pointer.select
  %value = load i8, ptr %native.data.pointer.select.outer
  ret i8 %value
}

define i8 @phi_resolver(i1 %choose, i64 %address) {
entry:
  br i1 %choose, label %left, label %right

left:
  %left.fallback = inttoptr i64 %address to ptr
  %left.data.offset = add i64 %address, -4096
  %left.rodata.offset = add i64 %address, -8192
  br label %merge

right:
  %right.fallback = inttoptr i64 %address to ptr
  %right.data.offset = sub i64 %address, 4096
  %right.rodata.offset = sub i64 %address, 8192
  br label %merge

merge:
  %fallback = phi ptr [ %left.fallback, %left ], [ %right.fallback, %right ]
  %data.offset = phi i64 [ %left.data.offset, %left ], [ %right.data.offset, %right ]
  %rodata.offset = phi i64 [ %left.rodata.offset, %left ], [ %right.rodata.offset, %right ]
  %data.in.range = icmp ult i64 %data.offset, 16
  %data.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_data, i64 -4096), i64 %address
  %native.data.pointer.select = select i1 %data.in.range, ptr %data.pointer, ptr %fallback
  %rodata.in.range = icmp ult i64 %rodata.offset, 8
  %rodata.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_rodata, i64 -8192), i64 %address
  %native.data.pointer.select.outer = select i1 %rodata.in.range, ptr %rodata.pointer, ptr %native.data.pointer.select
  %value = load i8, ptr %native.data.pointer.select.outer
  ret i8 %value
}

define i8 @poison_flagged_resolver(i64 %address) {
entry:
  %native.address.fallback = inttoptr i64 %address to ptr
  %data.offset = add nsw i64 %address, -4096
  %data.in.range = icmp ult i64 %data.offset, 16
  %data.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_data, i64 -4096), i64 %address
  %native.data.pointer.select = select i1 %data.in.range, ptr %data.pointer, ptr %native.address.fallback
  %rodata.offset = add i64 %address, -8192
  %rodata.in.range = icmp ult i64 %rodata.offset, 8
  %rodata.pointer = getelementptr i8, ptr getelementptr (i8, ptr @native_residual_rodata, i64 -8192), i64 %address
  %native.data.pointer.select.outer = select i1 %rodata.in.range, ptr %rodata.pointer, ptr %native.data.pointer.select
  %value = load i8, ptr %native.data.pointer.select.outer
  ret i8 %value
}

define i8 @poison_flagged_affine_resolver(i64 %root) {
entry:
  %address = add nsw i64 %root, 1008
  %native.address.fallback = inttoptr i64 %address to ptr
  %data.offset = add nsw i64 %root, 8
  %data.in.range = icmp ult i64 %data.offset, 16
  %data.pointer = getelementptr i8, ptr getelementptr inbounds nuw (i8, ptr @native_residual_data, i64 8), i64 %root
  %native.data.pointer.select = select i1 %data.in.range, ptr %data.pointer, ptr %native.address.fallback
  %rodata.offset = add nsw i64 %root, 4
  %rodata.in.range = icmp ult i64 %rodata.offset, 8
  %rodata.pointer = getelementptr i8, ptr getelementptr inbounds nuw (i8, ptr @native_residual_rodata, i64 4), i64 %root
  %native.data.pointer.select.outer = select i1 %rodata.in.range, ptr %rodata.pointer, ptr %native.data.pointer.select
  %value = load i8, ptr %native.data.pointer.select.outer
  ret i8 %value
}

; CHECK-LABEL: define i8 @exact_resolver(
; CHECK: %native.address.resolved = call ptr @__brighten_resolve_recovered_address(i64 %address)
; CHECK: %value = load i8, ptr %native.address.resolved
; CHECK-NOT: native.data.pointer.select
; CHECK-LABEL: define i8 @mismatched_resolver(
; CHECK: %data.offset.wrong = add i64 %address, -4095
; CHECK: %native.data.pointer.select.outer = select
; CHECK-LABEL: define i8 @phi_resolver(
; CHECK: merge:
; CHECK-NEXT: %native.address.resolved = call ptr @__brighten_resolve_recovered_address(i64 %address)
; CHECK-NEXT: %value = load i8, ptr %native.address.resolved
; CHECK-LABEL: define i8 @poison_flagged_resolver(
; CHECK: %native.address.resolved = call ptr @__brighten_resolve_recovered_address.1(i64 %address)
; CHECK-LABEL: define i8 @poison_flagged_affine_resolver(
; CHECK: %address = add nsw i64 %root, 1008
; CHECK-NEXT: %native.address.resolved = call ptr @__brighten_resolve_recovered_address.2(i64 %root, i64 %address)
; CHECK-LABEL: define internal ptr @__brighten_resolve_recovered_address(i64 %guest_address)
; CHECK: %native.data.offset = add i64 %guest_address, -4096
; CHECK: %native.data.offset1 = add i64 %guest_address, -8192
; CHECK: ret ptr %native.data.pointer.select4
; CHECK-LABEL: define internal ptr @__brighten_resolve_recovered_address.1(i64 %guest_address)
; CHECK: %native.data.offset = add nsw i64 %guest_address, -4096
; CHECK: %native.data.offset1 = add i64 %guest_address, -8192
; CHECK: ret ptr %native.data.pointer.select4
; CHECK-LABEL: define internal ptr @__brighten_resolve_recovered_address.2(i64 %affine_root, i64 %guest_address)
; CHECK: %native.data.offset = add nsw i64 %affine_root, 8
; CHECK: %native.data.dynamic.ptr = getelementptr i8, ptr getelementptr inbounds nuw (i8, ptr @native_residual_data, i64 8), i64 %affine_root
; CHECK: %native.data.offset1 = add nsw i64 %affine_root, 4
; CHECK: %native.data.dynamic.ptr3 = getelementptr i8, ptr getelementptr inbounds nuw (i8, ptr @native_residual_rodata, i64 4), i64 %affine_root
; CHECK: ret ptr %native.data.pointer.select4
