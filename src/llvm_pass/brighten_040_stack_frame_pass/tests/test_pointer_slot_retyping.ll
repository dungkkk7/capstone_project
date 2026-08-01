; RUN: opt -load-pass-plugin %llvmshlibdir/BrightenStackFramePass%shlibext -passes=brighten-post-state-frame-pass -verify-each -S %s | FileCheck %s

declare ptr @calloc(i64, i64)
declare i64 @strlen(ptr)
declare void @free(ptr)
declare void @print_i64(i64)

@good = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !0
@observed = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !0
@tagged = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !0
@overlap = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !0
@volatile_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !0
@atomic_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !0
@recursive_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !2
@repeat_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !4
@conditional_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !5
@callback_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !6
@resolver_slot = internal global [128 x i8] zeroinitializer, align 16, !brighten.stack.synthetic.created !7
@resolver_bytes = internal global [256 x i8] zeroinitializer, align 16

declare void @reentrant_callback(ptr)

; Test3: calloc -> exact synthetic frame slot -> null resolver -> strlen/free.
; CHECK-LABEL: define i32 @main()
; CHECK: %native.pointer.slot = alloca ptr, align 8
; CHECK: store ptr %p, ptr %native.pointer.slot, align 8
; CHECK: %native.pointer.slot.load = load ptr, ptr %native.pointer.slot, align 8
; CHECK: icmp eq ptr %native.pointer.slot.load, null
; CHECK: call i64 @strlen(ptr
; CHECK: call void @free(ptr
; CHECK-NOT: ptrtoint ptr %p to i64
define i32 @main() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 16, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @good, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  %raw = load i64, ptr %slot, align 8
  %fallback = inttoptr i64 %raw to ptr
  %isnull = icmp eq i64 %raw, 0
  %resolved = select i1 %isnull, ptr null, ptr %fallback
  %n = call i64 @strlen(ptr %resolved)
  call void @free(ptr %resolved)
  ret i32 0
}

; Integer observation must retain the original slot representation.
; CHECK-LABEL: define void @integer_observed()
; CHECK: store i64 %bits, ptr %slot, align 8
define void @integer_observed() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @observed, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  %raw = load i64, ptr %slot, align 8
  call void @print_i64(i64 %raw)
  ret void
}

; nsw/tag arithmetic is address-observable and is not a ptr slot.
; CHECK-LABEL: define void @tagged_value()
; CHECK: add nsw i64 %bits, 1
define void @tagged_value() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @tagged, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  %tag = add nsw i64 %bits, 1
  store i64 %tag, ptr %slot, align 8
  ret void
}

; Mixed-width overlap makes byte representation observable.
; CHECK-LABEL: define void @overlapping_access()
; CHECK: store i64 %bits, ptr %slot, align 8
define void @overlapping_access() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @overlap, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  %partial = getelementptr inbounds [128 x i8], ptr @overlap, i64 0, i64 60
  store i32 0, ptr %partial, align 4
  ret void
}

; Volatile and atomic accesses are never moved to an alloca.
; CHECK-LABEL: define void @volatile_access()
; CHECK: store volatile i64 %bits, ptr %slot, align 8
define void @volatile_access() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @volatile_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store volatile i64 %bits, ptr %slot, align 8
  ret void
}

; CHECK-LABEL: define void @atomic_access()
; CHECK: store atomic i64 %bits, ptr %slot monotonic, align 8
define void @atomic_access() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @atomic_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store atomic i64 %bits, ptr %slot monotonic, align 8
  ret void
}

; Recursive owners cannot use the single-invocation capability.
; CHECK-LABEL: define void @recursive_access()
; CHECK: store i64 %bits, ptr %slot, align 8
define void @recursive_access() !brighten.entry_single_invocation !1 {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @recursive_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  %raw = load i64, ptr %slot, align 8
  %again = inttoptr i64 %raw to ptr
  call void @free(ptr %again)
  call void @recursive_access()
  ret void
}

; This owner has no single-invocation capability, but each invocation stores
; before it loads and the slot address stays local.  Two sequential calls are
; therefore safe: no persistent global byte can be observed.
; CHECK-LABEL: define void @repeat_owner()
; CHECK: native.pointer.slot{{[0-9]*}} = alloca ptr, align 8
; CHECK: store ptr %p, ptr %native.pointer.slot{{[0-9]*}}, align 8
define void @repeat_owner() {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @repeat_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  %raw = load i64, ptr %slot, align 8
  %again = inttoptr i64 %raw to ptr
  call void @free(ptr %again)
  ret void
}

define void @repeat_driver() {
entry:
  call void @repeat_owner()
  call void @repeat_owner()
  ret void
}

; Store only on one predecessor: the load can observe the old global byte.
; CHECK-LABEL: define void @conditional_store(i1 %take_store)
; CHECK: store i64 %bits, ptr %slot, align 8
define void @conditional_store(i1 %take_store) {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @conditional_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  br i1 %take_store, label %stored, label %join
stored:
  store i64 %bits, ptr %slot, align 8
  br label %join
join:
  %raw = load i64, ptr %slot, align 8
  %again = inttoptr i64 %raw to ptr
  call void @free(ptr %again)
  ret void
}

; Passing the slot address to a callback is an address escape/reentrancy risk.
; CHECK-LABEL: define void @callback_access()
; CHECK: call void @reentrant_callback(ptr %slot)
define void @callback_access() {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @callback_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  call void @reentrant_callback(ptr %slot)
  %raw = load i64, ptr %slot, align 8
  %again = inttoptr i64 %raw to ptr
  call void @free(ptr %again)
  ret void
}

; Pointer storage is recovered, but the canonical range resolver retains a
; single ptrtoint sidecar until the resolver owner proves its arms impossible.
; CHECK-LABEL: define void @resolver_slot_positive()
; CHECK: native.pointer.slot{{[0-9]*}} = alloca ptr, align 8
; CHECK: native.pointer.slot.bits{{[0-9]*}} = ptrtoint ptr %native.pointer.slot.load{{[0-9]*}} to i64
; CHECK: native.data.pointer.select = select i1 %in.range, ptr %candidate, ptr %native.pointer.slot.load
define void @resolver_slot_positive() {
entry:
  %p = call ptr @calloc(i64 8, i64 1)
  %slot = getelementptr inbounds [128 x i8], ptr @resolver_slot, i64 0, i64 56
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr %slot, align 8
  %raw = load i64, ptr %slot, align 8
  %fallback = inttoptr i64 %raw to ptr
  %delta = add i64 %raw, -1024
  %in.range = icmp ult i64 %delta, 256
  %candidate = getelementptr i8, ptr @resolver_bytes, i64 %raw
  %native.data.pointer.select = select i1 %in.range, ptr %candidate, ptr %fallback
  %n = call i64 @strlen(ptr %native.data.pointer.select)
  call void @free(ptr %native.data.pointer.select)
  ret void
}

!0 = !{ptr @main, i32 1}
!1 = !{!"v1", !"attach_direct_unique"}
!2 = !{ptr @recursive_access, i32 1}
!4 = !{ptr @repeat_owner, i32 1}
!5 = !{ptr @conditional_store, i32 1}
!6 = !{ptr @callback_access, i32 1}
!7 = !{ptr @resolver_slot_positive, i32 1}
