; A live residual segment with a fully known initializer is still required by
; dynamic indexing.  Preserve the exact bytes and uses, but replace the
; lifter-specific identified aggregate with ordinary native byte storage.

target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

%seg_text_type = type <{ i16, [2 x i8] }>
%seg_reloc_type = type <{ [2 x i8], ptr }>

@native_residual_text = internal global %seg_text_type <{ i16 513, [2 x i8] c"\03\04" }>, align 16
@native_residual_reloc = internal global %seg_reloc_type <{ [2 x i8] c"AB", ptr @hook }>, align 8

declare void @hook()

define i8 @read_residual(i64 %index) {
entry:
  %ptr = getelementptr i8, ptr @native_residual_text, i64 %index
  %value = load i8, ptr %ptr, align 1
  ret i8 %value
}

define ptr @read_relocation() {
entry:
  %ptr = getelementptr i8, ptr @native_residual_reloc, i64 2
  %value = load ptr, ptr %ptr, align 8
  ret ptr %value
}

; CHECK-NOT: %seg_text_type
; CHECK-NOT: %seg_reloc_type
; CHECK: @native_residual_text = internal global [4 x i8] c"\01\02\03\04", align 16
; CHECK: @native_residual_reloc = internal global <{ [2 x i8], ptr }> <{ [2 x i8] c"AB", ptr @hook }>, align 8
; CHECK: getelementptr i8, ptr @native_residual_text, i64 %index
; CHECK: getelementptr i8, ptr @native_residual_reloc, i64 2
