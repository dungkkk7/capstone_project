; A recovered explicit register argument and the canonical State snapshot may
; both describe the same register.  The explicit ABI value is authoritative at
; function entry and must be seeded after the synthetic state_in stores.

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer
@g_arr_2 = internal global [100 x [4 x i8]] zeroinitializer, align 8, !brighten.guest.range !0

define internal i64 @worker.native(i64 %arg_RSI) {
entry:
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  %rsi = load i64, ptr %rsi.ptr, align 8
  %result = add i64 %rsi, %arg_RSI
  %guest.offset = shl i64 %arg_RSI, 4
  %guest.addr = add i64 %guest.offset, 4096
  %guest.ptr = inttoptr i64 %guest.addr to ptr
  %guest.value = load i64, ptr %guest.ptr, align 8
  %combined = add i64 %result, %guest.value
  ret i64 %combined
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %result = call i64 @worker.native(i64 7)
  %ret = trunc i64 %result to i32
  ret i32 %ret
}

define i64 @read_native_recovered_field(i64 %index) {
entry:
  %scaled = shl i64 %index, 4
  %base = ptrtoint ptr @g_arr_2 to i64
  %record = add i64 %base, %scaled
  %field = add i64 %record, 8
  %field.ptr = inttoptr i64 %field to ptr
  %value = load i64, ptr %field.ptr, align 8
  ret i64 %value
}

define i64 @read_nested_recovered_field(i64 %index) {
entry:
  %record = getelementptr i8, ptr getelementptr (i8, ptr @g_arr_2, i64 32), i64 %index
  %field = getelementptr i8, ptr %record, i64 8
  %value = load i64, ptr %field, align 8
  ret i64 %value
}

; A real native global carrier must survive even though the dynamic guest
; rewrite disables the broad ABI-argument heuristic.
; CHECK-LABEL: define i64 @read_native_recovered_field(
; CHECK: %[[FALLBACK:[A-Za-z0-9._]+]] = inttoptr i64 %field to ptr
; CHECK: %[[MAPPED:[A-Za-z0-9._]+]] = getelementptr i8, ptr @g_arr_2
; CHECK: %[[SELECTED:[A-Za-z0-9._]+]] = select i1 {{.*}}, ptr %[[MAPPED]], ptr %[[FALLBACK]]
; CHECK: load i64, ptr %[[SELECTED]]

; A nested native GEP represents guest_begin + recovered-object offset +
; dynamic index.  Byte-field rematerialization must retain both constants.
; CHECK-LABEL: define i64 @read_nested_recovered_field(
; CHECK: %[[GUEST:[A-Za-z0-9._]+]] = add i64 %index, 4128
; CHECK: %[[FIELD:[A-Za-z0-9._]+]] = add i64 %[[GUEST]], 8
; CHECK: getelementptr i8, ptr @g_arr_2
; CHECK: load i64, ptr %native.data.pointer.select

; The recovered base proves that arg_RSI is an array index here, not native
; pointer provenance.  Out-of-range indices still retain the raw fallback.
; CHECK-LABEL: define internal i64 @worker(
; CHECK-NOT: native.integer.pointer
; CHECK: getelementptr i8, ptr @g_arr_2
; CHECK: load i64, ptr %native.data.pointer.select

!0 = !{i64 4096, i64 4496}
