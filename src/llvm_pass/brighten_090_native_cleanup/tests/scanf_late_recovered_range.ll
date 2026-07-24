; A scanf destination dispatch can be created before a residual data segment
; acquires its final brighten.guest.range.  A later cleanup sweep must rebuild
; the generated dispatch so a valid address in that segment does not escape as
; a raw guest virtual address.

@fmt = internal constant [3 x i8] c"%s\00", align 1
@g_arr_0 = internal global [16 x i8] zeroinitializer, align 1,
  !brighten.guest.range !0
@dyn_bytes_2000 = internal global [64 x i8] zeroinitializer, align 1,
  !brighten.guest.range !1

declare i32 @scanf(ptr, ...)

define i32 @main(i64 %guest_address) {
entry:
  %early.at_or_after = icmp uge i64 %guest_address, 4096
  %early.before_end = icmp ult i64 %guest_address, 4112
  %early.in_range = and i1 %early.at_or_after, %early.before_end
  %early.offset = sub i64 %guest_address, 4096
  %early.pointer = getelementptr i8, ptr @g_arr_0, i64 %early.offset
  %native.address.fallback = inttoptr i64 %guest_address to ptr
  %native.data.pointer.select = select i1 %early.in_range,
      ptr %early.pointer, ptr %native.address.fallback
  %result = call i32 (ptr, ...) @scanf(
      ptr @fmt, ptr %native.data.pointer.select)
  ret i32 %result
}

; CHECK: getelementptr i8, ptr @native_data_2000__byte_backing
; CHECK: native.data.pointer.select
; CHECK: call i32 (ptr, ...) @scanf

!0 = !{i64 4096, i64 4112}
!1 = !{i64 8192, i64 8256}
