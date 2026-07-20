; CHECK-NOT: !llvm.dbg.cu
; CHECK-NOT: !DICompileUnit
; CHECK-NOT: !DIFile
; CHECK-NOT: !ollvm.deobf
; CHECK-NOT: !brighten.stack.ensured
; CHECK-NOT: !brighten.return_candidate
; CHECK: call i32 @source(), !range ![[RANGE:[0-9]+]]
; CHECK: ![[RANGE]] = !{i32 0, i32 2}

@storage = internal global i32 0, !brighten.stack.ensured !6

declare i32 @source()

define i32 @main() {
entry:
  %value = call i32 @source(), !range !7, !brighten.return_candidate !8
  ret i32 %value
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}
!llvm.ident = !{!4}
!ollvm.deobf.profile = !{!5}
!ollvm.deobf.inventory = !{!5}
!ollvm.deobf.proofs = !{!5}
!brighten.globals.preserved = !{!6}
!brighten.late.stack.lowered = !{!6}

!0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "metadata cleanup test", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "fixture.c", directory: "/tmp")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 7, !"Dwarf Version", i32 5}
!4 = !{!"transient compiler identity"}
!5 = !{!"proof data already persisted as JSON"}
!6 = !{i1 true}
!7 = !{i32 0, i32 2}
!8 = !{!"candidate:i32"}
