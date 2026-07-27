; A conservatively preserved segment acquires brighten.guest.range only when
; its final data_<addr> alias is removed.  All whitelisted libc pointer
; arguments must be revisited after that point, not only scanf destinations.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_2000__data = global [64 x i8] zeroinitializer, align 1
@data_2008 = alias i8, getelementptr inbounds (
    [64 x i8], ptr @seg_2000__data, i64 0, i64 8)

declare i32 @strcmp(ptr, ptr)
declare i32 @puts(ptr)

define i32 @compare_guest_strings(i64 %guest_address) {
entry:
  %native.address.fallback = inttoptr i64 %guest_address to ptr
  %result = call i32 @strcmp(
      ptr %native.address.fallback, ptr %native.address.fallback)
  ret i32 %result
}

define ptr @keep_data_alias_live() {
entry:
  ret ptr @data_2008
}

define i32 @puts_selected_guest_string(i1 %condition) {
entry:
  %guest_address = select i1 %condition, i64 8199, i64 8203
  %native.integer.pointer = inttoptr i64 %guest_address to ptr
  %result = call i32 @puts(ptr %native.integer.pointer)
  ret i32 %result
}

; CHECK: @native_residual_2000__data = global [64 x i8] zeroinitializer
; CHECK-SAME: !brighten.guest.range
; CHECK-LABEL: define i32 @compare_guest_strings
; CHECK: getelementptr i8, ptr @native_residual_2000__data
; CHECK: call i32 @strcmp(ptr %native.data.pointer.select
; CHECK-NOT: call i32 @strcmp(ptr %native.address.fallback
; CHECK-LABEL: define i32 @puts_selected_guest_string
; CHECK: getelementptr i8, ptr @native_residual_2000__data
; CHECK: call i32 @puts(ptr %native.data.pointer.select
; CHECK-NOT: call i32 @puts(ptr %native.integer.pointer
