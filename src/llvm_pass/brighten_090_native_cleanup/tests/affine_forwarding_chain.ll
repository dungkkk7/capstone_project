; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-native-cleanup-post-souper-pass,verify' -S %s | FileCheck-21 %s
;
; The replacement for %result is itself a load scheduled earlier in the same
; forwarding batch.  The pass must track that RAUW chain instead of retaining
; a raw pointer to the erased intermediate load.

@scanf.format = private constant [4 x i8] c"%ld\00"

declare i32 @scanf(ptr, ...)

define internal i64 @worker(ptr %frame_base) {
entry:
  %slot.a = getelementptr i8, ptr %frame_base, i64 -8
  %slot.b = getelementptr i8, ptr %frame_base, i64 -16
  store i64 7, ptr %slot.a, align 8
  %intermediate = load i64, ptr %slot.a, align 8
  store i64 %intermediate, ptr %slot.b, align 8
  %result = load i64, ptr %slot.b, align 8
  ret i64 %result
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %frame = alloca [32 x i8], align 16
  %top = getelementptr inbounds i8, ptr %frame, i64 32
  %value = call i64 @worker(ptr %top)
  %result = trunc i64 %value to i32
  ret i32 %result
}

define i64 @forward_across_isolated_scanf() {
entry:
  %shadow = alloca i64, align 1
  %frame_storage = alloca [2097152 x i8], align 16
  %frame_top = getelementptr inbounds i8, ptr %frame_storage, i64 2096896
  %anchor = ptrtoint ptr %frame_top to i64
  %logical = add i64 %anchor, -72
  %address.slot = getelementptr inbounds i8, ptr %frame_storage, i64 2096864
  %value.slot = getelementptr inbounds i8, ptr %frame_storage, i64 2096824
  store i64 %logical, ptr %address.slot, align 8
  store i64 0, ptr %value.slot, align 8
  %old = load i64, ptr %value.slot, align 8
  store i64 %old, ptr %shadow, align 1
  %scanned = call i32 (ptr, ...) @scanf(ptr @scanf.format, ptr %shadow)
  %written = load volatile i64, ptr %shadow, align 1
  store i64 %written, ptr %value.slot, align 1
  %reloaded.address = load i64, ptr %address.slot, align 8
  %dynamic.delta = sub i64 %reloaded.address, %anchor
  %dynamic.pointer = getelementptr i8, ptr %frame_top, i64 %dynamic.delta
  %value = load i64, ptr %dynamic.pointer, align 8
  ret i64 %value
}

; CHECK-LABEL: define internal i64 @worker(
; CHECK-NOT: load i64
; CHECK: ret i64 7
; CHECK-LABEL: define i64 @forward_across_isolated_scanf(
; CHECK-NOT: alloca [2097152 x i8]
; CHECK-NOT: %dynamic.pointer
; CHECK: load volatile i64, ptr %shadow
; CHECK: ret i64
