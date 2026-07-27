; RUN: opt -load-pass-plugin %builddir/BrightenGlobalDataRecoveryPass.so -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s
;
; No !brighten.elf.pt_loads metadata means the production-default path.  The
; dynamic writable carrier with observed address identity must retain one
; source backing object; it may not acquire a mapped tail or an independently
; materialized writable subobject.

@seg_1000__data = internal global [32 x i8] zeroinitializer, align 16
@data_1010 = alias ptr, getelementptr ([32 x i8], ptr @seg_1000__data, i64 0, i64 16)

; CHECK-NOT: @native_elf_mapped_page_tail
; CHECK-NOT: @g_scalar_
; CHECK-NOT: @g_arr_
; CHECK-NOT: @dyn_bytes_
; CHECK-LABEL: define i8 @dynamic_writable_carrier
; CHECK: getelementptr i8, ptr @{{(data_1010|seg_1000__data|native_residual_1000__data)}}, i64 %idx
define i8 @dynamic_writable_carrier(i64 %idx, i8 %value, ptr %other) {
entry:
  ; This is a program-visible address comparison, so extracting the prefix
  ; would create duplicate storage unless every identity use were rewritten.
  %same = icmp eq ptr @data_1010, %other
  %p = getelementptr i8, ptr @data_1010, i64 %idx
  store i8 %value, ptr %p, align 1
  %r = load i8, ptr %p, align 1
  ret i8 %r
}
