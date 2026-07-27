; Fixed i32 cells are localized independently of their synthetic byte backing.
; No global or function name is part of the proof; metadata only binds the
; synthetic object to its owner.

@basic = internal global [128 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !0
@large = internal global [16777216 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !2
@zeroed = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !4
@recursive = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !6
@persistent = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !8
@overlap = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !10
@callback = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !12
@volatile_cell = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !14
@atomic_cell = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !16
@byte_cell = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !18
@half_cell = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !20
@wide_cell = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !22
@mixed_width = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !24
@adjacent_byte = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !26

declare void @capture(ptr)

; CHECK-LABEL: define i32 @basic_owner
; CHECK: %native.scalar.slot = alloca i32, align 4
; CHECK: store i32 %x, ptr %native.scalar.slot, align 4
; CHECK: load i32, ptr %native.scalar.slot, align 4
define i32 @basic_owner(i32 %x) {
entry:
  %slot = getelementptr inbounds i8, ptr @basic, i64 20
  store i32 %x, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK-LABEL: define i8 @byte_owner
; CHECK: %native.scalar.slot = alloca i8, align 1
define i8 @byte_owner(i8 %x) {
entry:
  %slot = getelementptr inbounds i8, ptr @byte_cell, i64 7
  store i8 %x, ptr %slot, align 1
  %value = load i8, ptr %slot, align 1
  ret i8 %value
}

; CHECK-LABEL: define i16 @half_owner
; CHECK: %native.scalar.slot = alloca i16, align 2
define i16 @half_owner(i16 %x) {
entry:
  %slot = getelementptr inbounds i8, ptr @half_cell, i64 10
  store i16 %x, ptr %slot, align 2
  %value = load i16, ptr %slot, align 2
  ret i16 %value
}

; CHECK-LABEL: define i64 @wide_owner
; CHECK: %native.scalar.slot = alloca i64, align 8
define i64 @wide_owner(i64 %x) {
entry:
  %slot = getelementptr inbounds i8, ptr @wide_cell, i64 16
  store i64 %x, ptr %slot, align 8
  %value = load i64, ptr %slot, align 8
  ret i64 %value
}

; Exact type/width is the boundary.  A mixed-width access refuses atomically.
; CHECK-LABEL: define void @mixed_width_owner
; CHECK: store i16 1, ptr %slot, align 2
define void @mixed_width_owner() {
entry:
  %slot = getelementptr inbounds i8, ptr @mixed_width, i64 8
  store i16 1, ptr %slot, align 2
  %wide = load i32, ptr %slot, align 2
  ret void
}

; A neighboring byte is a distinct exact cell, not an overlap.  The candidate
; at offset 7 localizes while the independent byte keeps the backing live.
; CHECK-LABEL: define i8 @adjacent_byte_owner
; CHECK: %native.scalar.slot = alloca i8, align 1
; CHECK: store i8 99, ptr %neighbor, align 1
define i8 @adjacent_byte_owner(i8 %x) {
entry:
  %slot = getelementptr inbounds i8, ptr @adjacent_byte, i64 7
  %neighbor = getelementptr inbounds i8, ptr @adjacent_byte, i64 8
  store i8 %x, ptr %slot, align 1
  store i8 99, ptr %neighbor, align 1
  %value = load i8, ptr %slot, align 1
  ret i8 %value
}

; The same exact proof must work at a large static backing offset.
; CHECK-LABEL: define i32 @large_owner
; CHECK: %native.scalar.slot = alloca i32, align 4
; CHECK: load i32, ptr %native.scalar.slot, align 4
define i32 @large_owner(i32 %x) {
entry:
  %slot = getelementptr inbounds i8, ptr @large, i64 16711596
  store i32 %x, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; Read-before-write keeps the source global's zero semantics only with the
; producer's exact single-invocation capability.
; CHECK-LABEL: define i32 @zero_owner
; CHECK: %native.scalar.slot = alloca i32, align 4
; CHECK-NEXT: store i32 0, ptr %native.scalar.slot, align 4
; CHECK: load i32, ptr %native.scalar.slot, align 4
define i32 @zero_owner() !brighten.entry_single_invocation !5 {
entry:
  %slot = getelementptr inbounds i8, ptr @zeroed, i64 12
  %before = load i32, ptr %slot, align 4
  store i32 9, ptr %slot, align 4
  ret i32 %before
}

; CHECK-LABEL: define void @recursive_owner
; CHECK: store i32 1, ptr %slot, align 4
define void @recursive_owner() {
entry:
  %slot = getelementptr inbounds i8, ptr @recursive, i64 8
  store i32 1, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  call void @recursive_owner()
  ret void
}

; A non-dominating load may observe a prior invocation's global value.
; CHECK-LABEL: define i32 @persistent_owner
; CHECK: load i32, ptr %slot, align 4
define i32 @persistent_owner(i1 %take) {
entry:
  %slot = getelementptr inbounds i8, ptr @persistent, i64 8
  br i1 %take, label %store, label %join
store:
  store i32 1, ptr %slot, align 4
  br label %join
join:
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK-LABEL: define void @overlap_owner
; CHECK: store i32 1, ptr %slot, align 4
define void @overlap_owner() {
entry:
  %slot = getelementptr inbounds i8, ptr @overlap, i64 8
  store i32 1, ptr %slot, align 4
  %partial = getelementptr inbounds i8, ptr @overlap, i64 10
  store i16 2, ptr %partial, align 2
  %value = load i32, ptr %slot, align 4
  ret void
}

; CHECK-LABEL: define void @callback_owner
; CHECK: call void @capture(ptr %slot)
define void @callback_owner() {
entry:
  %slot = getelementptr inbounds i8, ptr @callback, i64 8
  store i32 1, ptr %slot, align 4
  call void @capture(ptr %slot)
  %value = load i32, ptr %slot, align 4
  ret void
}

; CHECK-LABEL: define void @volatile_owner
; CHECK: store volatile i32 1, ptr %slot, align 4
define void @volatile_owner() {
entry:
  %slot = getelementptr inbounds i8, ptr @volatile_cell, i64 8
  store volatile i32 1, ptr %slot, align 4
  %value = load volatile i32, ptr %slot, align 4
  ret void
}

; CHECK-LABEL: define void @atomic_owner
; CHECK: store atomic i32 1, ptr %slot monotonic, align 4
define void @atomic_owner() {
entry:
  %slot = getelementptr inbounds i8, ptr @atomic_cell, i64 8
  store atomic i32 1, ptr %slot monotonic, align 4
  %value = load atomic i32, ptr %slot monotonic, align 4
  ret void
}

!0 = !{ptr @basic_owner, i32 1}
!2 = !{ptr @large_owner, i32 1}
!4 = !{ptr @zero_owner, i32 1}
!5 = !{!"v1", !"attach_direct_unique"}
!6 = !{ptr @recursive_owner, i32 1}
!8 = !{ptr @persistent_owner, i32 1}
!10 = !{ptr @overlap_owner, i32 1}
!12 = !{ptr @callback_owner, i32 1}
!14 = !{ptr @volatile_owner, i32 1}
!16 = !{ptr @atomic_owner, i32 1}
!18 = !{ptr @byte_owner, i32 1}
!20 = !{ptr @half_owner, i32 1}
!22 = !{ptr @wide_owner, i32 1}
!24 = !{ptr @mixed_width_owner, i32 1}
!26 = !{ptr @adjacent_byte_owner, i32 1}
