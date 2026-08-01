; llvm.memset has defined memory-only semantics and a nocapture destination.
; The destination must be rewritten with the same transaction as load/stores.
@backing = internal global [16777216 x i8] zeroinitializer, align 8,
  !brighten.stack.synthetic.created !0

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @worker() !brighten.entry_single_invocation !1 {
entry:
  %slot = getelementptr inbounds i8, ptr @backing, i64 8
  store i32 7, ptr %slot, align 4
  call void @llvm.memset.p0.i64(ptr align 4 %slot, i8 0, i64 4, i1 false)
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

!0 = !{ptr @worker, i32 1}
!1 = !{!"v1", !"attach_direct_unique"}
