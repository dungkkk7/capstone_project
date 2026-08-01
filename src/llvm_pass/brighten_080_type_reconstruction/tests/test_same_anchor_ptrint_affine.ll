target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@frame = internal global [64 x i8] zeroinitializer, align 16
@other = internal global [64 x i8] zeroinitializer, align 16
@observed_anchor_bits = internal global i64 0, align 8

define void @positive_instruction_forms() {
entry:
  %a = ptrtoint ptr @frame to i64
  %b = ptrtoint ptr @frame to i64
  %plus = add i64 %a, -8
  %negative = sub i64 %plus, %b
  %p.negative = getelementptr i8, ptr @frame, i64 %negative
  ; CHECK-LABEL: define void @positive_instruction_forms()
  ; CHECK: %p.negative = getelementptr i8, ptr @frame, i64 -8
  store volatile i8 1, ptr %p.negative, align 1

  %cancel = sub i64 %a, %b
  %positive = add i64 12, %cancel
  %p.positive = getelementptr i8, ptr @frame, i64 %positive
  ; CHECK: %p.positive = getelementptr i8, ptr @frame, i64 12
  store atomic i8 2, ptr %p.positive unordered, align 1
  ret void
}

define void @positive_constexpr_and_phi(i1 %choose) {
entry:
  br i1 %choose, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %p = phi ptr [ getelementptr (i8, ptr @frame, i64 sub (i64 add (i64 ptrtoint (ptr @frame to i64), i64 -4), i64 ptrtoint (ptr @frame to i64))), %left ], [ getelementptr (i8, ptr @frame, i64 add (i64 5, i64 sub (i64 ptrtoint (ptr @frame to i64), i64 ptrtoint (ptr @frame to i64)))), %right ]
  ; CHECK-LABEL: define void @positive_constexpr_and_phi
  ; CHECK: left:
  ; CHECK: brighten.address.gep = getelementptr i8, ptr @frame, i64 -4
  ; CHECK: right:
  ; CHECK: brighten.address.gep{{[0-9]*}} = getelementptr i8, ptr @frame, i64 5
  ; CHECK: %p = phi ptr [ %brighten.address.gep, %left ], [ %brighten.address.gep{{[0-9]*}}, %right ]
  store i8 3, ptr %p, align 1
  ret void
}

; Late cleanup can leave semantically identical static anchors with different
; GEP flags.  The 080 static-anchor canonical representation may unify them
; only after proving the inbounds form is non-poison within @frame.
define void @positive_static_anchor_flag_mismatch() {
entry:
  store i8 9, ptr getelementptr (i8, ptr getelementptr inbounds nuw (i8, ptr @frame, i64 32), i64 sub (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @frame, i64 32) to i64), i64 -7), i64 ptrtoint (ptr getelementptr (i8, ptr @frame, i64 32) to i64))), align 1
  ; CHECK-LABEL: define void @positive_static_anchor_flag_mismatch()
  ; CHECK: brighten.address.gep = getelementptr i8, ptr getelementptr inbounds nuw (i8, ptr @frame, i64 32), i64 -7
  ret void
}

; The reusable matcher accepts only unflagged modular affine operations.  The
; final index must be constant, while the nested GEP itself remains a pointer
; operation (080 does not collapse a resolver or invent inbounds).
define void @positive_modular_affine_and_nested_gep() {
entry:
  %nested = getelementptr i8, ptr @frame, i64 16
  %a = ptrtoint ptr %nested to i64
  %b = ptrtoint ptr %nested to i64
  %twice.a = shl i64 %a, 1
  %twice.b = mul i64 %b, 2
  %cancel = sub i64 %twice.a, %twice.b
  %not.a = xor i64 %a, -1
  %restore = add i64 %not.a, %b
  %zero = add i64 %restore, 1
  %frozen = freeze i64 %zero
  %offset = add i64 %cancel, %frozen
  %p = getelementptr i8, ptr %nested, i64 %offset
  ; CHECK-LABEL: define void @positive_modular_affine_and_nested_gep()
  ; CHECK: %nested = getelementptr i8, ptr @frame, i64 16
  ; CHECK: %p = getelementptr i8, ptr %nested, i64 0
  store i8 4, ptr %p, align 1
  ret void
}

; An independently observed ptrtoint is not evidence that this separate GEP
; index observes its integer bits.  Preserve the store exactly, canonicalize
; only the root cancellation, and leave the shared ptrtoint alive.
define void @positive_shared_ptrtoint_integer_observation() {
entry:
  %anchor = ptrtoint ptr @frame to i64
  store i64 %anchor, ptr @observed_anchor_bits, align 8
  %again = ptrtoint ptr @frame to i64
  %with.offset = add i64 %anchor, 24
  %offset = sub i64 %with.offset, %again
  %p = getelementptr i8, ptr @frame, i64 %offset
  ; CHECK-LABEL: define void @positive_shared_ptrtoint_integer_observation()
  ; CHECK: %anchor = ptrtoint ptr @frame to i64
  ; CHECK-NEXT: store i64 %anchor, ptr @observed_anchor_bits, align 8
  ; CHECK: %p = getelementptr i8, ptr @frame, i64 24
  store i8 5, ptr %p, align 1
  ret void
}

define void @reject_nsw_nuw() {
entry:
  %a = ptrtoint ptr @frame to i64
  %b = ptrtoint ptr @frame to i64
  %nsw = add nsw i64 %a, -8
  %bad = sub i64 %nsw, %b
  %p = getelementptr i8, ptr @frame, i64 %bad
  ; CHECK-LABEL: define void @reject_nsw_nuw()
  ; CHECK: %nsw = add nsw i64 %a, -8
  ; CHECK: %p = getelementptr i8, ptr @frame, i64 %bad
  store i8 0, ptr %p, align 1
  %nuw = add nuw i64 %a, 6
  %bad.nuw = sub i64 %nuw, %b
  %p.nuw = getelementptr i8, ptr @frame, i64 %bad.nuw
  ; CHECK: %nuw = add nuw i64 %a, 6
  ; CHECK: %p.nuw = getelementptr i8, ptr @frame, i64 %bad.nuw
  store i8 0, ptr %p.nuw, align 1
  ret void
}

define void @reject_different_base_trunc_and_observed() {
entry:
  %a = ptrtoint ptr @frame to i64
  %b = ptrtoint ptr @other to i64
  %different = sub i64 %a, %b
  %p.different = getelementptr i8, ptr @frame, i64 %different
  ; CHECK-LABEL: define void @reject_different_base_trunc_and_observed()
  ; CHECK: %p.different = getelementptr i8, ptr @frame, i64 %different
  store i8 0, ptr %p.different, align 1

  %same = ptrtoint ptr @frame to i64
  %truncated = trunc i64 %same to i32
  %extended = zext i32 %truncated to i64
  %bad.trunc = sub i64 %extended, %same
  %p.trunc = getelementptr i8, ptr @frame, i64 %bad.trunc
  ; CHECK: %p.trunc = getelementptr i8, ptr @frame, i64 %bad.trunc
  store i8 0, ptr %p.trunc, align 1

  %plus = add i64 %same, 9
  %observed = sub i64 %plus, %same
  %address.observed = icmp eq i64 %observed, 9
  %p.observed = getelementptr i8, ptr @frame, i64 %observed
  ; CHECK: %address.observed = icmp eq i64 %observed, 9
  ; CHECK: %p.observed = getelementptr i8, ptr @frame, i64 %observed
  br i1 %address.observed, label %done, label %done
done:
  ret void
}

; Reject operations whose flags add poison, even though the corresponding
; mathematical integer expression would cancel.  Reject address-space mixing
; too: it is not a same-root pointer proof.
@frame_as1 = internal addrspace(1) global [64 x i8] zeroinitializer, align 16
define void @reject_flagged_and_address_space() {
entry:
  %a = ptrtoint ptr @frame to i64
  %b = ptrtoint ptr @frame to i64
  %shift = shl nuw i64 %a, 1
  %twice = mul i64 %b, 2
  %bad = sub i64 %shift, %twice
  %p = getelementptr i8, ptr @frame, i64 %bad
  ; CHECK-LABEL: define void @reject_flagged_and_address_space()
  ; CHECK: %shift = shl nuw i64 %a, 1
  ; CHECK: %p = getelementptr i8, ptr @frame, i64 %bad
  store i8 0, ptr %p, align 1

  %as1 = ptrtoint ptr addrspace(1) @frame_as1 to i64
  %mixed = sub i64 %a, %as1
  %p.mixed = getelementptr i8, ptr @frame, i64 %mixed
  ; CHECK: %p.mixed = getelementptr i8, ptr @frame, i64 %mixed
  store i8 0, ptr %p.mixed, align 1
  ret void
}

; This is the lifecycle boundary: 080 may expose a constant GEP, but only 040
; decides whether the fully proven backing is eligible for a local frame.
@lifecycle_backing = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.synthetic.created !0

define i32 @lifecycle_to_post_state_frame() !brighten.entry_single_invocation !1 {
entry:
  %a = ptrtoint ptr @lifecycle_backing to i64
  %b = ptrtoint ptr @lifecycle_backing to i64
  %with.offset = add i64 %a, 32
  %offset = sub i64 %with.offset, %b
  %slot = getelementptr inbounds i8, ptr @lifecycle_backing, i64 %offset
  store i32 7, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ; LIFECYCLE-LABEL: define i32 @lifecycle_to_post_state_frame()
  ; LIFECYCLE: %native_frame = alloca [4 x i8], align 16
  ; LIFECYCLE: getelementptr [4 x i8], ptr %native_frame, i64 0, i64 0
  ; LIFECYCLE-NOT: @lifecycle_backing
  ret i32 %value
}

!0 = !{ptr @lifecycle_to_post_state_frame, i32 1}
!1 = !{!"v1", !"attach_direct_unique"}
