; RUN: opt -load-pass-plugin %builddir/BrightenGlobalDataRecoveryPass.so -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s
;
; A PT_LOAD logical interval and its page tail are distinct backing regions.
; The data_1010 carrier still physically points into seg_1000, but its guest
; address is owned by the tail, not by the aggregate's synthetic overhang.

@seg_1000__data = internal global [32 x i8] zeroinitializer, align 16
@data_1010 = alias ptr, getelementptr ([32 x i8], ptr @seg_1000__data, i64 0, i64 16)

; CHECK: @native_elf_mapped_page_tail = internal global [16 x i8] zeroinitializer, align 1, !brighten.guest.range ![[TAIL:[0-9]+]]
; CHECK-NOT: @g_scalar_
; CHECK-NOT: @dyn_bytes_

; This direct tail alias is intentionally retained as a guest-address
; carrier.  A later dynamic resolver must therefore see only the tail range
; for 0x1010, never the source aggregate's physical [0x1000,0x1020).
; The fixed write/read pair is rewritten transactionally to the one mapped
; tail owner.  No use may remain on the physical seg_1000 overhang.
; CHECK-LABEL: define i32 @tail_store_load
; CHECK: store i32 %v, ptr @native_elf_mapped_page_tail
; CHECK: %r = load i32, ptr @native_elf_mapped_page_tail
define i32 @tail_store_load(i32 %v) {
entry:
  store i32 %v, ptr @data_1010, align 4
  %r = load i32, ptr @data_1010, align 4
  ret i32 %r
}

; CHECK: ![[TAIL]] = !{i64 4112, i64 4128}

!brighten.elf.pt_loads = !{!0}
!0 = !{i64 4096, i64 0, i64 16, i64 6, i64 16, i64 4096, i64 4128}
