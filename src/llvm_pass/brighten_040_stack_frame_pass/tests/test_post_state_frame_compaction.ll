; A producer binds this exact synthetic backing to one owner invocation.
@backing = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !0

define i32 @worker() !brighten.entry_single_invocation !1 {
entry:
  %slot = getelementptr inbounds i8, ptr @backing, i64 32
  store i32 7, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

!0 = !{ptr @worker, i32 1}
!1 = !{!"v1", !"attach_direct_unique"}
