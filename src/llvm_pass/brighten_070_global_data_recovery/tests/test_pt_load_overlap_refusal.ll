; RUN: opt -load-pass-plugin %builddir/BrightenGlobalDataRecoveryPass.so -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s
;
; Overlapping mapped PT_LOAD descriptors have no authoritative owner.  The
; pass must not materialize a mapped-page tail or choose one segment by order.

@seg_1000__data = internal global [32 x i8] zeroinitializer
@seg_1010__data = internal global [32 x i8] zeroinitializer

; CHECK-NOT: native_elf_mapped_page_tail
define void @no_owner() {
entry:
  ret void
}

!brighten.elf.pt_loads = !{!0, !1}
!0 = !{i64 4096, i64 0, i64 16, i64 6, i64 16, i64 4096, i64 4128}
!1 = !{i64 4112, i64 0, i64 16, i64 6, i64 16, i64 4112, i64 4144}
