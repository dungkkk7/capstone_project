target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; The helper observes only rsp-relative addresses.  The common frame base
; cancels from every memory pointer, so the real ABI is one native activation
; pointer plus the remaining source/state arguments.
define internal i32 @native_helper(ptr nonnull %frame_base,
                                   i64 %state_in_2312,
                                   i64 %state_in_2328,
                                   i32 %value) {
entry:
  %anchor = ptrtoint ptr %frame_base to i64
  %address = add i64 %state_in_2312, -4
  %delta = sub i64 %address, %anchor
  %slot = getelementptr i8, ptr %frame_base, i64 %delta
  store i32 %value, ptr %slot, align 4
  %loaded = load i32, ptr %slot, align 4
  ret i32 %loaded
}

; The first aggregate result is the post-call stack pointer.  Once the input
; ABI is native, callers should derive this exact field from their actual
; pointer rather than losing provenance through an opaque i64 extract.
define internal { i64, i32 } @returning_native_helper(
    ptr nonnull %frame_base, i64 %state_in_2312, i32 %value) {
entry:
  %next_stack = add i64 %state_in_2312, 8
  %result0 = insertvalue { i64, i32 } zeroinitializer, i64 %next_stack, 0
  %result1 = insertvalue { i64, i32 } %result0, i32 %value, 1
  ret { i64, i32 } %result1
}

; External linkage preserves a source-visible compatibility adapter while the
; module body and all internal calls use the native-stack implementation.
define i32 @exported_native_helper(ptr nonnull %frame_base,
                                   i64 %state_in_2312,
                                   i32 %value) {
entry:
  %anchor = ptrtoint ptr %frame_base to i64
  %address = add i64 %state_in_2312, -8
  %delta = sub i64 %address, %anchor
  %slot = getelementptr i8, ptr %frame_base, i64 %delta
  store i32 %value, ptr %slot, align 4
  %loaded = load i32, ptr %slot, align 4
  ret i32 %loaded
}

; A direct access to the common base is not translation invariant.  It must
; retain the original ABI instead of being accepted by name or shape alone.
define internal i8 @absolute_base_refused(ptr nonnull %frame_base,
                                          i64 %state_in_2312) {
entry:
  %value = load i8, ptr %frame_base, align 1
  ret i8 %value
}

define i32 @main() {
entry:
  %frame = alloca [64 x i8], align 16
  %base = getelementptr inbounds [64 x i8], ptr %frame, i64 0, i64 0
  %top = getelementptr inbounds [64 x i8], ptr %frame, i64 0, i64 48
  %top.integer = ptrtoint ptr %top to i64
  store i8 7, ptr %base, align 16
  %result = call i32 @native_helper(ptr nonnull %base,
                                    i64 %top.integer, i64 0, i32 42)
  %returned = call { i64, i32 } @returning_native_helper(
      ptr nonnull %base, i64 %top.integer, i32 44)
  %returned.stack = extractvalue { i64, i32 } %returned, 0
  %returned.value = extractvalue { i64, i32 } %returned, 1
  %expected.stack = add i64 %top.integer, 8
  %returned.stack.ok = icmp eq i64 %returned.stack, %expected.stack
  %returned.value.ok = icmp eq i32 %returned.value, 44
  %returned.ok = and i1 %returned.stack.ok, %returned.value.ok
  %exported = call i32 @exported_native_helper(ptr nonnull %base,
                                               i64 %top.integer, i32 43)
  %kept = call i8 @absolute_base_refused(ptr nonnull %base,
                                         i64 %top.integer)
  %kept.ok = icmp eq i8 %kept, 7
  %result.ok = icmp eq i32 %result, 42
  %exported.ok = icmp eq i32 %exported, 43
  %ordinary.helpers.ok = and i1 %result.ok, %exported.ok
  %helpers.ok = and i1 %ordinary.helpers.ok, %returned.ok
  %ok = and i1 %kept.ok, %helpers.ok
  %failed = xor i1 %ok, true
  %status = zext i1 %failed to i32
  ret i32 %status
}

; CHECK-LABEL: define i32 @exported_native_helper(ptr nonnull %frame_base,
; CHECK-SAME: i64 %state_in_2312, i32 %value) #[[ADAPTER:[0-9]+]]
; CHECK: %native.stack.pointer = getelementptr i8, ptr %frame_base, i64 %native.stack.delta
; CHECK: call i32 @exported_native_helper.native_stack(ptr %native.stack.pointer,
; CHECK: ret i32

; CHECK-LABEL: define internal i8 @absolute_base_refused(ptr nonnull %frame_base,
; CHECK-SAME: i64 %state_in_2312)
; CHECK: %value = load i8, ptr %frame_base

; CHECK-LABEL: define i32 @main()
; CHECK: %native.stack.pointer = getelementptr i8, ptr %base, i64 %native.stack.delta
; CHECK: call i32 @native_helper(ptr %native.stack.pointer,
; CHECK: call { i64, i32 } @returning_native_helper(ptr %native.stack.pointer{{[0-9]*}},
; CHECK: %native.stack.return.pointer = getelementptr i8, ptr %native.stack.pointer{{[0-9]*}}, i64 8
; CHECK: %native.stack.return.integer = ptrtoint ptr %native.stack.return.pointer to i64
; CHECK-NOT: extractvalue { i64, i32 } %returned, 0
; CHECK: %native.stack.pointer{{[0-9]*}} = getelementptr i8, ptr %base, i64 %native.stack.delta{{[0-9]*}}
; CHECK: call i32 @exported_native_helper.native_stack(ptr %native.stack.pointer{{[0-9]*}},

; CHECK-LABEL: define internal i32 @native_helper(ptr nonnull %stack_pointer,
; CHECK-SAME: i64 %state_in_2328, i32 %value)
; CHECK-NOT: frame_base
; CHECK: native.stack.entry:
; CHECK: %native.stack.address = ptrtoint ptr %stack_pointer to i64
; CHECK: store i32 %value
; CHECK: ret i32

; CHECK-LABEL: define internal { i64, i32 } @returning_native_helper(ptr nonnull %stack_pointer,
; CHECK-SAME: i32 %value)
; CHECK: %native.stack.address = ptrtoint ptr %stack_pointer to i64
; CHECK: %next_stack = add i64 %native.stack.address, 8
; CHECK: ret { i64, i32 }

; CHECK-LABEL: define internal i32 @exported_native_helper.native_stack(ptr nonnull %stack_pointer,
; CHECK-SAME: i32 %value)
; CHECK-NOT: frame_base
; CHECK: native.stack.entry:
; CHECK: store i32 %value
; CHECK: ret i32

; CHECK: attributes #[[ADAPTER]] = {
; CHECK-SAME: "brighten.external.guest_stack.adapter"="v1"
