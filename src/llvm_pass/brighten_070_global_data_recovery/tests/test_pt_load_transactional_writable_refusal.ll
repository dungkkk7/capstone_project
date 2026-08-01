; RUN: opt -load-pass-plugin %builddir/BrightenGlobalDataRecoveryPass.so -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s
;
; A dynamic carrier and an address identity observation in an authoritative
; writable region make partial objectization unsound.  Keep one source owner;
; do not create dyn_bytes/scalar/array siblings.

@seg_3000__data = internal global [4096 x i8] zeroinitializer, align 16
@data_3000 = alias ptr, getelementptr ([4096 x i8], ptr @seg_3000__data, i64 0, i64 0)

; CHECK: @seg_3000__data = internal global
; CHECK: @native_elf_mapped_page_tail = internal global
; CHECK-NOT: @dyn_bytes_
; CHECK-NOT: @g_scalar_
; CHECK-NOT: @g_arr_
; CHECK-LABEL: define i8 @uncovered_dynamic
; CHECK: getelementptr i8, ptr @data_3000, i64 %idx
define i8 @uncovered_dynamic(i64 %idx, i8 %v, ptr %other) {
entry:
  %same = icmp eq ptr @data_3000, %other
  %p = getelementptr i8, ptr @data_3000, i64 %idx
  store i8 %v, ptr %p, align 1
  %r = load i8, ptr %p, align 1
  ret i8 %r
}

!brighten.elf.pt_loads = !{!0}
!0 = !{i64 12288, i64 32, i64 32, i64 6, i64 4096, i64 12288, i64 16384}
