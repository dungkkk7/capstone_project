@positive = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !0
@cross = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !2
@other = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !4
@recursive = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !6
@observed = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !8
@volatile_cell = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !10
@unknown_init = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !12
@nonzero_root = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !14
@dynamic_root = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !16

define i32 @positive_owner(i1 %which, i32 %v) {
entry:
  %root = getelementptr [64 x i8], ptr @positive, i64 0, i64 0
  %left = getelementptr inbounds i8, ptr %root, i64 4
  %right = getelementptr inbounds i8, ptr %root, i64 8
  br i1 %which, label %a, label %b
a:
  br label %join
b:
  br label %join
join:
  %slot = phi ptr [ %left, %a ], [ %right, %b ]
  store i32 %v, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

define void @cross_owner(i1 %which) {
entry:
  %root = getelementptr inbounds [64 x i8], ptr @cross, i64 0, i64 0
  %local = getelementptr inbounds i8, ptr %root, i64 4
  %foreign = getelementptr inbounds [64 x i8], ptr @other, i64 0, i64 4
  %slot = select i1 %which, ptr %local, ptr %foreign
  store i32 1, ptr %slot, align 4
  ret void
}

define void @other_owner() {
entry:
  %root = getelementptr inbounds [64 x i8], ptr @other, i64 0, i64 0
  store i8 0, ptr %root, align 1
  ret void
}

define void @recursive_owner() {
entry:
  %root = getelementptr inbounds [64 x i8], ptr @recursive, i64 0, i64 0
  store i8 1, ptr %root, align 1
  call void @recursive_owner()
  ret void
}

define void @observed_owner() {
entry:
  %root = getelementptr inbounds [64 x i8], ptr @observed, i64 0, i64 0
  %bits = ptrtoint ptr %root to i64
  store i64 %bits, ptr %root, align 8
  ret void
}

define void @volatile_owner() {
entry:
  %root = getelementptr inbounds [64 x i8], ptr @volatile_cell, i64 0, i64 0
  store volatile i32 1, ptr %root, align 4
  %value = load volatile i32, ptr %root, align 4
  ret void
}

define i32 @unknown_init_owner() {
entry:
  %root = getelementptr inbounds [64 x i8], ptr @unknown_init, i64 0, i64 0
  %value = load i32, ptr %root, align 4
  store i32 1, ptr %root, align 4
  ret i32 %value
}

define i32 @nonzero_root_owner() {
entry:
  %root = getelementptr i8, ptr @nonzero_root, i64 1
  store i32 1, ptr %root, align 1
  %value = load i32, ptr %root, align 1
  ret i32 %value
}

define i32 @dynamic_root_owner(i64 %index) {
entry:
  %root = getelementptr i8, ptr @dynamic_root, i64 %index
  store i32 1, ptr %root, align 1
  %value = load i32, ptr %root, align 1
  ret i32 %value
}

!0 = !{ptr @positive_owner, i32 1}
!2 = !{ptr @cross_owner, i32 1}
!4 = !{ptr @other_owner, i32 1}
!6 = !{ptr @recursive_owner, i32 1}
!8 = !{ptr @observed_owner, i32 1}
!10 = !{ptr @volatile_owner, i32 1}
!12 = !{ptr @unknown_init_owner, i32 1}
!14 = !{ptr @nonzero_root_owner, i32 1}
!16 = !{ptr @dynamic_root_owner, i32 1}
