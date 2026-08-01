; Every object below has the exact synthetic-created and single-invocation
; metadata.  Each must still be refused for one independent proof failure.
@ptrint_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !0
@dynamic_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !2
@escape_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !4
@call_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !6
@qsort_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !8
@recursive_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !10
@address_taken_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !12
@volatile_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !14
@atomic_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !16
@lifetime_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !18
@overlap_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !20
@scanf_backing = internal global [64 x i8] zeroinitializer, !brighten.stack.synthetic.created !22
@rbp_backing = internal global [4096 x i8] zeroinitializer, !brighten.stack.synthetic.created !24
@escaped = global ptr null
@callback_slot = global ptr @address_taken_owner
@shared_state = internal global [4096 x i8] zeroinitializer
@format = private constant [3 x i8] c"%d\00"

declare void @unknown(ptr)
declare void @qsort(ptr, i64, i64, ptr)
declare i32 @scanf(ptr, ...)
declare i32 @cmp(ptr, ptr)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

define i32 @ptrint_owner() !brighten.entry_single_invocation !27 {
entry:
  %p = ptrtoint ptr @ptrint_backing to i64
  %q = add i64 %p, 4
  %slot = inttoptr i64 %q to ptr
  store i32 1, ptr %slot
  ret i32 0
}

define i32 @dynamic_owner(i1 %cond) !brighten.entry_single_invocation !27 {
entry:
  %a = getelementptr inbounds i8, ptr @dynamic_backing, i64 4
  %b = getelementptr inbounds i8, ptr @dynamic_backing, i64 8
  %slot = select i1 %cond, ptr %a, ptr %b
  store i32 1, ptr %slot
  ret i32 0
}

define i32 @escape_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @escape_backing, i64 4
  store ptr %slot, ptr @escaped
  ret i32 0
}

define i32 @call_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @call_backing, i64 4
  call void @unknown(ptr %slot)
  ret i32 0
}

define i32 @qsort_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @qsort_backing, i64 4
  call void @qsort(ptr %slot, i64 1, i64 4, ptr @cmp)
  ret i32 0
}

define i32 @recursive_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @recursive_backing, i64 4
  store i32 1, ptr %slot
  %r = call i32 @recursive_owner()
  ret i32 %r
}

define i32 @address_taken_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @address_taken_backing, i64 4
  store i32 1, ptr %slot
  ret i32 0
}

define i32 @volatile_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @volatile_backing, i64 4
  store volatile i32 1, ptr %slot
  ret i32 0
}

define i32 @atomic_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @atomic_backing, i64 4
  store atomic i32 1, ptr %slot monotonic, align 4
  ret i32 0
}

define i32 @lifetime_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @lifetime_backing, i64 4
  call void @llvm.lifetime.start.p0(i64 4, ptr %slot)
  store i32 1, ptr %slot
  ret i32 0
}

define i32 @overlap_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @overlap_backing, i64 4
  store i32 1, ptr %slot
  %part = getelementptr inbounds i8, ptr %slot, i64 2
  %value = load i16, ptr %part
  ret i32 0
}

define i32 @scanf_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @scanf_backing, i64 4
  %result = call i32 (ptr, ...) @scanf(ptr @format, ptr %slot), !brighten.scanf.destination !26
  %value = load i32, ptr %slot
  ret i32 %value
}

define i32 @rbp_owner() !brighten.entry_single_invocation !27 {
entry:
  %slot = getelementptr inbounds i8, ptr @rbp_backing, i64 16
  store i64 1, ptr %slot
  %rbp = getelementptr inbounds i8, ptr @shared_state, i64 2328
  store i64 2, ptr %rbp
  ret i32 0
}

!0 = !{ptr @ptrint_owner, i32 1}
!1 = !{ptr @ptrint_backing, i32 1}
!2 = !{ptr @dynamic_owner, i32 1}
!3 = !{ptr @dynamic_backing, i32 1}
!4 = !{ptr @escape_owner, i32 1}
!5 = !{ptr @escape_backing, i32 1}
!6 = !{ptr @call_owner, i32 1}
!7 = !{ptr @call_backing, i32 1}
!8 = !{ptr @qsort_owner, i32 1}
!9 = !{ptr @qsort_backing, i32 1}
!10 = !{ptr @recursive_owner, i32 1}
!11 = !{ptr @recursive_backing, i32 1}
!12 = !{ptr @address_taken_owner, i32 1}
!13 = !{ptr @address_taken_backing, i32 1}
!14 = !{ptr @volatile_owner, i32 1}
!15 = !{ptr @volatile_backing, i32 1}
!16 = !{ptr @atomic_owner, i32 1}
!17 = !{ptr @atomic_backing, i32 1}
!18 = !{ptr @lifetime_owner, i32 1}
!19 = !{ptr @lifetime_backing, i32 1}
!20 = !{ptr @overlap_owner, i32 1}
!21 = !{ptr @overlap_backing, i32 1}
!22 = !{ptr @scanf_owner, i32 1}
!23 = !{ptr @scanf_backing, i32 1}
!24 = !{ptr @rbp_owner, i32 1}
!25 = !{ptr @rbp_backing, i32 1}
!26 = !{i32 1, i32 1, i64 4, i1 true}
!27 = !{!"v1", !"attach_direct_unique"}
