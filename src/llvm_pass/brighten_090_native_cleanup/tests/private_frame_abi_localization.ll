; A recovered callee whose negative-offset frame never escapes and whose
; reads are covered by local writes can own a native alloca. Its synthetic
; frame_base parameter must disappear from both definition and call sites.
;
; A scanf destination is intentionally different: failed conversion keeps
; old frame bytes, so moving it to a fresh alloca would lose cross-call state.
;
; CHECK-LABEL: define internal i32 @scanf_worker(ptr %frame_base, i64 %state_in_2312)
; CHECK: call i32 (ptr, ...) @scanf
;
; CHECK-LABEL: define internal i32 @address_worker(ptr %frame_base, i64 %state_in_2312)
; CHECK: store i64 %local.address
;
; CHECK-LABEL: define i32 @main()
; CHECK: call i32 @safe_worker(i64 %rsp)
; CHECK: call i32 @finite_stack_worker(i64 %rsp, i1 true)
; CHECK: call i32 @scanf_worker(ptr %frame.top, i64 %rsp)
; CHECK: call i32 @initialized_scanf_worker(i64 %rsp)
; CHECK: call i32 @address_worker(ptr %frame.top, i64 %rsp)
; CHECK: call i32 @recursive_worker(i64 %rsp, i32 3)
; CHECK: call fastcc i32 @closed_fast_worker(i64 %rsp)
;
; CHECK-LABEL: define internal i32 @safe_worker(i64 %state_in_2312)
; CHECK: %native.local.frame = alloca [8 x i8], align 16
; CHECK-NOT: %frame_base
; CHECK: ret i32
;
; A bounded partial writer is private only when the invocation first defines
; all bytes that the failed/partial call may preserve.
; CHECK-LABEL: define internal i32 @initialized_scanf_worker(i64 %state_in_2312)
; CHECK: %native.local.frame = alloca [4 x i8], align 16
; CHECK-NOT: %frame_base
; CHECK: call i32 (ptr, ...) @scanf
;
; A finite select/PHI family of stack offsets and multiple equivalent
; ptrtoint anchors are still one private frame, not an ABI escape.
; CHECK-LABEL: define internal i32 @finite_stack_worker(i64 %state_in_2312, i1 %choose.deep)
; CHECK: %native.local.frame = alloca
; CHECK-NOT: %frame_base
; CHECK-NOT: inttoptr
; CHECK: ret i32 5
;
; Direct recursion receives a fresh proven-private frame per invocation. Both
; the external edge and the self edge must use the contracted ABI.
; CHECK-LABEL: define internal i32 @recursive_worker(i64 %state_in_2312, i32 %depth)
; CHECK: %native.local.frame = alloca [4 x i8], align 16
; CHECK-NOT: %frame_base
; CHECK: call i32 @recursive_worker(i64 %next.rsp, i32 %next.depth)
; CHECK-NOT: call i32 @recursive_worker(ptr
; CHECK: ret i32
;
; Recovered fastcc functions are module-private ABI even when lifting left
; external linkage spelling. dso_local plus direct calls and no address-taken
; use make signature contraction closed-world; ordinary C ABI is not covered.
; CHECK-LABEL: define dso_local fastcc i32 @closed_fast_worker(i64 %state_in_2312)
; CHECK: %native.local.frame = alloca [4 x i8], align 16
; CHECK-NOT: %frame_base
; CHECK: ret i32

@fmt = private constant [3 x i8] c"%d\00"

declare i32 @scanf(ptr, ...)

define internal i32 @safe_worker(ptr %frame_base, i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %frame.delta = sub i64 %state_in_2312, %frame.anchor
  %frame.root = getelementptr i8, ptr %frame_base, i64 %frame.delta
  %slot = getelementptr i8, ptr %frame.root, i64 -4
  store i32 7, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  %second.address = add i64 %state_in_2312, -8
  %second.delta = sub i64 %second.address, %frame.anchor
  %second.root = getelementptr i8, ptr %frame_base, i64 %second.delta
  store i32 11, ptr %second.root, align 4
  %second.value = load i32, ptr %second.root, align 4
  %sum = add i32 %value, %second.value
  ret i32 %sum
}

define internal i32 @scanf_worker(ptr %frame_base, i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %frame.delta = sub i64 %state_in_2312, %frame.anchor
  %frame.root = getelementptr i8, ptr %frame_base, i64 %frame.delta
  %slot = getelementptr i8, ptr %frame.root, i64 -4
  %converted = call i32 (ptr, ...) @scanf(ptr @fmt, ptr %slot)
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

define internal i32 @initialized_scanf_worker(ptr %frame_base,
                                               i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %frame.delta = sub i64 %state_in_2312, %frame.anchor
  %frame.root = getelementptr i8, ptr %frame_base, i64 %frame.delta
  %slot = getelementptr i8, ptr %frame.root, i64 -4
  store i32 0, ptr %slot, align 4
  %converted = call i32 (ptr, ...) @scanf(ptr @fmt, ptr %slot)
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; Although its memory accesses are bounded and write-before-read, this callee
; stores an RSP-derived address. Localizing only its backing would leave that
; integer pointing at the caller frame rather than the new alloca.
define internal i32 @address_worker(ptr %frame_base, i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %frame.delta = sub i64 %state_in_2312, %frame.anchor
  %frame.root = getelementptr i8, ptr %frame_base, i64 %frame.delta
  %slot = getelementptr i8, ptr %frame.root, i64 -8
  %local.address = add i64 %state_in_2312, -4
  store i64 %local.address, ptr %slot, align 8
  %saved = load volatile i64, ptr %slot, align 8
  %is.nonzero = icmp ne i64 %saved, 0
  %result = zext i1 %is.nonzero to i32
  ret i32 %result
}

define internal i32 @finite_stack_worker(ptr %frame_base,
                                         i64 %state_in_2312,
                                         i1 %choose.deep) {
entry:
  %anchor.a = ptrtoint ptr %frame_base to i64
  %slot.a.address = add i64 %state_in_2312, -32
  %slot.a.delta = sub i64 %slot.a.address, %anchor.a
  %slot.a = getelementptr i8, ptr %frame_base, i64 %slot.a.delta
  %anchor.b = ptrtoint ptr %frame_base to i64
  %slot.b.address = add i64 %state_in_2312, -24
  %slot.b.delta = sub i64 %slot.b.address, %anchor.b
  %slot.b = getelementptr i8, ptr %frame_base, i64 %slot.b.delta
  %shallow = add i64 %state_in_2312, -56
  %deep = add i64 %state_in_2312, -88
  %active = select i1 %choose.deep, i64 %deep, i64 %shallow
  %out.a = add i64 %active, -16
  %out.b = add i64 %active, -32
  store i64 %out.a, ptr %slot.a, align 1
  store i64 %out.b, ptr %slot.b, align 1
  %saved.a = load i64, ptr %slot.a, align 1
  %raw.a = inttoptr i64 %saved.a to ptr
  store i32 5, ptr %raw.a, align 1
  %saved.b = load i64, ptr %slot.b, align 1
  %raw.b = inttoptr i64 %saved.b to ptr
  store i32 7, ptr %raw.b, align 1
  ret i32 5
}

define internal i32 @recursive_worker(ptr %frame_base,
                                      i64 %state_in_2312,
                                      i32 %depth) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %frame.delta = sub i64 %state_in_2312, %frame.anchor
  %frame.root = getelementptr i8, ptr %frame_base, i64 %frame.delta
  %slot = getelementptr i8, ptr %frame.root, i64 -4
  store i32 %depth, ptr %slot, align 4
  %done = icmp eq i32 %depth, 0
  br i1 %done, label %exit, label %recurse

recurse:
  %next.depth = sub i32 %depth, 1
  %next.rsp = sub i64 %state_in_2312, 16
  %nested = call i32 @recursive_worker(ptr %frame_base, i64 %next.rsp,
                                      i32 %next.depth)
  br label %exit

exit:
  %result = load i32, ptr %slot, align 4
  ret i32 %result
}

define dso_local fastcc i32 @closed_fast_worker(ptr %frame_base,
                                                 i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %frame.delta = sub i64 %state_in_2312, %frame.anchor
  %frame.root = getelementptr i8, ptr %frame_base, i64 %frame.delta
  %slot = getelementptr i8, ptr %frame.root, i64 -4
  store i32 29, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

define i32 @main() {
entry:
  %storage = alloca [64 x i8], align 16
  %frame.top = getelementptr inbounds [64 x i8], ptr %storage, i64 0, i64 64
  %rsp = ptrtoint ptr %frame.top to i64
  %a = call i32 @safe_worker(ptr %frame.top, i64 %rsp)
  %dynamic = call i32 @finite_stack_worker(ptr %frame.top, i64 %rsp,
                                           i1 true)
  %b = call i32 @scanf_worker(ptr %frame.top, i64 %rsp)
  %d = call i32 @initialized_scanf_worker(ptr %frame.top, i64 %rsp)
  %c = call i32 @address_worker(ptr %frame.top, i64 %rsp)
  %recursive = call i32 @recursive_worker(ptr %frame.top, i64 %rsp, i32 3)
  %closed.fast = call fastcc i32 @closed_fast_worker(ptr %frame.top, i64 %rsp)
  %sum.ad = add i32 %a, %dynamic
  %sum.ab = add i32 %sum.ad, %b
  %sum.abc = add i32 %sum.ab, %c
  %sum.abcd = add i32 %sum.abc, %d
  %sum.recursive = add i32 %sum.abcd, %recursive
  %sum = add i32 %sum.recursive, %closed.fast
  ret i32 %sum
}
