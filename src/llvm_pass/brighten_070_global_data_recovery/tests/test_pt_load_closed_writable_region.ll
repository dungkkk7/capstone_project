; RUN: opt -load-pass-plugin %builddir/BrightenGlobalDataRecoveryPass.so -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s
;
; All live accesses in the logical writable region are fixed and covered by
; one scalar candidate.  Experimental PT_LOAD mode may split this source only
; after every access is rewritten.

@seg_2000__data = internal global [4096 x i8] zeroinitializer, align 16
@data_2004 = alias ptr, getelementptr ([4096 x i8], ptr @seg_2000__data, i64 0, i64 4)

; CHECK: @g_scalar_0 = internal global i32 0
; CHECK-NOT: @dyn_bytes_
; CHECK-LABEL: define i32 @closed_scalar
; CHECK: store i32 %v, ptr @g_scalar_0
; CHECK: %r = load i32, ptr @g_scalar_0
define i32 @closed_scalar(i32 %v) {
entry:
  store i32 %v, ptr @data_2004, align 4
  %r = load i32, ptr @data_2004, align 4
  ret i32 %r
}

!brighten.elf.pt_loads = !{!0}
!0 = !{i64 8192, i64 32, i64 32, i64 6, i64 4096, i64 8192, i64 12288}
