; A late optimizer may reassociate an already recovered stack GEP into an
; integer RSP expression. The post-Souper cleanup must restore frame
; provenance without rewriting unrelated dynamic integer pointers.
;
; CHECK-LABEL: define i64 @late_stack_pointer(
; CHECK: %native.stack.gep = getelementptr i8, ptr getelementptr (i8, ptr @frame_storage_backing.late_stack_pointer, i64 16711680), i64 %native.stack.delta
; CHECK: store i8 7, ptr %native.stack.gep
; CHECK-NOT: inttoptr i64 %stack.address
;
; CHECK-LABEL: define ptr @unrelated_pointer(
; CHECK: %raw = inttoptr i64 %address to ptr
;
; Adjacent stack-carrier slots do not alias.  The later store to slot B must
; not hide the exact reaching definition of slot A.
; CHECK-LABEL: define void @adjacent_reaching_stack_store(
; CHECK-NOT: %loaded.stack = load
; CHECK: %native.stack.gep = getelementptr i8, ptr %frame_base, i64 %native.stack.delta
; CHECK: store i8 9, ptr %native.stack.gep
; CHECK-NOT: inttoptr i64 %loaded.stack
;
; CHECK-LABEL: define void @loop_carried_stack_pointer(
; CHECK-NOT: inttoptr i64 %rsp.loop
; CHECK: store i8 3, ptr %native.stack.gep
;
; CHECK-LABEL: define void @cross_block_stack_spill(
; CHECK-NOT: inttoptr i64 %loaded.stack
; CHECK: store i8 6, ptr %native.stack.gep
;
; CHECK-LABEL: define ptr @mixed_cross_block_spill(
; CHECK: %raw = inttoptr i64 %loaded to ptr
;
; CHECK-LABEL: define ptr @rootless_integer_cycle(
; CHECK: %raw = inttoptr i64 %integer.loop to ptr
;
; The native result tuple is ordered by the recovered live-out set, so RSP
; provenance must follow the callee's return construction instead of a fixed
; aggregate index.  This also covers a PHI which merges complete call tuples.
; CHECK-LABEL: define void @returned_stack_pointer(
; CHECK-NOT: inttoptr i64 %returned.rsp
; CHECK: store i8 4, ptr %native.stack.gep
;
; CHECK-LABEL: define void @merged_returned_stack_pointer(
; CHECK-NOT: inttoptr i64 %merged.rsp
; CHECK: store i8 5, ptr %native.stack.gep
;
; CHECK-LABEL: define void @nested_returned_stack_pointer(
; CHECK-NOT: inttoptr i64 %nested.rsp
; CHECK: store i8 8, ptr %native.stack.gep
;
; CHECK-LABEL: define void @recursive_returned_stack_pointer(
; CHECK-NOT: inttoptr i64 %recursive.rsp
; CHECK: store i8 10, ptr %native.stack.gep
;
; A tuple position alone is not proof.  However, when the selected field is
; structurally proven to pass the caller's recovered RSP through the callee's
; return insertvalue chain, that value retains stack provenance.  A genuine
; state ABI still does not make an unrelated caller operand a stack address.
; CHECK-LABEL: define ptr @uncontracted_tuple_field(
; CHECK-NOT: inttoptr i64 %field to ptr
; CHECK: %native.stack.gep = getelementptr i8, ptr %frame_base, i64 %native.stack.delta
; CHECK: ret ptr %native.stack.gep
;
; CHECK-LABEL: define ptr @nonstack_state_call_operand(
; CHECK: %raw = inttoptr i64 %field to ptr
;
; CHECK-LABEL: define ptr @nested_nonstack_state_call_operand(
; CHECK: %raw = inttoptr i64 %field to ptr
;
; CHECK-LABEL: define ptr @rootless_recursive_result(
; CHECK: %raw = inttoptr i64 %field to ptr

@frame_storage_backing.late_stack_pointer = internal global
  [16777216 x i8] zeroinitializer, align 16

define i64 @late_stack_pointer(i64 %state_in_2312) {
entry:
  %stack.address = add i64 %state_in_2312, -32
  %raw = inttoptr i64 %stack.address to ptr
  store i8 7, ptr %raw, align 1
  ret i64 %stack.address
}

define ptr @unrelated_pointer(i64 %address) {
entry:
  %raw = inttoptr i64 %address to ptr
  ret ptr %raw
}

define void @adjacent_reaching_stack_store(ptr %frame_base,
                                           i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %slot.a.address = add i64 %state_in_2312, -32
  %slot.a.delta = sub i64 %slot.a.address, %frame.anchor
  %slot.a = getelementptr i8, ptr %frame_base, i64 %slot.a.delta
  %slot.b.address = add i64 %state_in_2312, -24
  %slot.b.delta = sub i64 %slot.b.address, %frame.anchor
  %slot.b = getelementptr i8, ptr %frame_base, i64 %slot.b.delta
  store i64 %slot.a.address, ptr %slot.a, align 1
  store i64 %slot.b.address, ptr %slot.b, align 1
  %loaded.stack = load i64, ptr %slot.a, align 1
  %raw.stack = inttoptr i64 %loaded.stack to ptr
  store i8 9, ptr %raw.stack, align 1
  ret void
}

define void @loop_carried_stack_pointer(ptr %frame_base,
                                        i64 %state_in_2312,
                                        i1 %again) {
entry:
  br label %loop

loop:
  %rsp.loop = phi i64 [ %state_in_2312, %entry ], [ %rsp.next, %body ]
  %raw = inttoptr i64 %rsp.loop to ptr
  store i8 3, ptr %raw, align 1
  br i1 %again, label %body, label %exit

body:
  %rsp.next = add i64 %rsp.loop, -16
  br label %loop

exit:
  ret void
}

define void @cross_block_stack_spill(ptr %frame_base,
                                     i64 %state_in_2312,
                                     i1 %again) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %slot.address = add i64 %state_in_2312, -48
  %slot.delta = sub i64 %slot.address, %frame.anchor
  %slot = getelementptr i8, ptr %frame_base, i64 %slot.delta
  %adjacent = getelementptr i8, ptr %slot, i64 8
  store i64 %slot.address, ptr %slot, align 1
  br label %loop

loop:
  br i1 %again, label %body, label %exit

body:
  store i64 0, ptr %adjacent, align 1
  br label %loop

exit:
  %loaded.stack = load i64, ptr %slot, align 1
  %raw = inttoptr i64 %loaded.stack to ptr
  store i8 6, ptr %raw, align 1
  ret void
}

define ptr @mixed_cross_block_spill(ptr %frame_base,
                                    i64 %state_in_2312,
                                    i64 %address,
                                    i1 %condition) {
entry:
  %frame.anchor = ptrtoint ptr %frame_base to i64
  %slot.address = add i64 %state_in_2312, -64
  %slot.delta = sub i64 %slot.address, %frame.anchor
  %slot = getelementptr i8, ptr %frame_base, i64 %slot.delta
  br i1 %condition, label %stack, label %other

stack:
  store i64 %slot.address, ptr %slot, align 1
  br label %merge

other:
  store i64 %address, ptr %slot, align 1
  br label %merge

merge:
  %loaded = load i64, ptr %slot, align 1
  %raw = inttoptr i64 %loaded to ptr
  ret ptr %raw
}

define ptr @rootless_integer_cycle(ptr %frame_base, i1 %again) {
entry:
  br label %loop

loop:
  %integer.loop = phi i64 [ 0, %entry ], [ %integer.next, %body ]
  %raw = inttoptr i64 %integer.loop to ptr
  br i1 %again, label %body, label %exit

body:
  %integer.next = add i64 %integer.loop, 1
  br label %loop

exit:
  ret ptr %raw
}

define internal { i64, i64, i64 } @advance_stack_state(
    i64 %ordinary, i64 %state_in_2312) noinline {
entry:
  %next.rsp = add i64 %state_in_2312, -16
  %r0 = insertvalue { i64, i64, i64 } zeroinitializer, i64 %ordinary, 0
  %r1 = insertvalue { i64, i64, i64 } %r0, i64 %next.rsp, 1
  %r2 = insertvalue { i64, i64, i64 } %r1, i64 99, 2
  ret { i64, i64, i64 } %r2
}

define internal { i64, i64, i64 } @uncontracted_result(
    i64 %ordinary, i64 %address) noinline {
entry:
  %r0 = insertvalue { i64, i64, i64 } zeroinitializer, i64 %ordinary, 0
  %r1 = insertvalue { i64, i64, i64 } %r0, i64 %address, 1
  %r2 = insertvalue { i64, i64, i64 } %r1, i64 99, 2
  ret { i64, i64, i64 } %r2
}

define internal { i64, i64, i64, i64 } @forward_stack_state(
    i64 %state_in_2312) noinline {
entry:
  %inner = call { i64, i64, i64 } @advance_stack_state(
      i64 11, i64 %state_in_2312)
  %inner.rsp = extractvalue { i64, i64, i64 } %inner, 1
  %r0 = insertvalue { i64, i64, i64, i64 } zeroinitializer,
                    i64 10, 0
  %r1 = insertvalue { i64, i64, i64, i64 } %r0, i64 20, 1
  %r2 = insertvalue { i64, i64, i64, i64 } %r1, i64 %inner.rsp, 2
  %r3 = insertvalue { i64, i64, i64, i64 } %r2, i64 30, 3
  ret { i64, i64, i64, i64 } %r3
}

define internal { i64, i64 } @recursive_stack_state(
    i64 %state_in_2312, i1 %recurse) noinline {
entry:
  br i1 %recurse, label %step, label %base

base:
  %base.rsp = add i64 %state_in_2312, -8
  %base.r0 = insertvalue { i64, i64 } zeroinitializer, i64 1, 0
  %base.r1 = insertvalue { i64, i64 } %base.r0, i64 %base.rsp, 1
  ret { i64, i64 } %base.r1

step:
  %next.rsp = add i64 %state_in_2312, -16
  %inner = call { i64, i64 } @recursive_stack_state(
      i64 %next.rsp, i1 false)
  %inner.rsp = extractvalue { i64, i64 } %inner, 1
  %step.r0 = insertvalue { i64, i64 } zeroinitializer, i64 2, 0
  %step.r1 = insertvalue { i64, i64 } %step.r0, i64 %inner.rsp, 1
  ret { i64, i64 } %step.r1
}

define internal { i64 } @rootless_recursive_state(
    i64 %state_in_2312) noinline {
entry:
  %inner = call { i64 } @rootless_recursive_state(i64 %state_in_2312)
  %inner.field = extractvalue { i64 } %inner, 0
  %result = insertvalue { i64 } zeroinitializer, i64 %inner.field, 0
  ret { i64 } %result
}

define void @returned_stack_pointer(ptr %frame_base, i64 %state_in_2312) {
entry:
  %result = call { i64, i64, i64 } @advance_stack_state(
      i64 7, i64 %state_in_2312)
  %returned.rsp = extractvalue { i64, i64, i64 } %result, 1
  %raw = inttoptr i64 %returned.rsp to ptr
  store i8 4, ptr %raw, align 1
  ret void
}

define void @merged_returned_stack_pointer(ptr %frame_base,
                                            i64 %state_in_2312,
                                            i1 %condition) {
entry:
  br i1 %condition, label %left, label %right

left:
  %left.result = call { i64, i64, i64 } @advance_stack_state(
      i64 1, i64 %state_in_2312)
  br label %merge

right:
  %right.result = call { i64, i64, i64 } @advance_stack_state(
      i64 2, i64 %state_in_2312)
  br label %merge

merge:
  %result = phi { i64, i64, i64 } [ %left.result, %left ],
                                      [ %right.result, %right ]
  %merged.rsp = extractvalue { i64, i64, i64 } %result, 1
  %raw = inttoptr i64 %merged.rsp to ptr
  store i8 5, ptr %raw, align 1
  ret void
}

define void @nested_returned_stack_pointer(ptr %frame_base,
                                            i64 %state_in_2312) {
entry:
  %result = call { i64, i64, i64, i64 } @forward_stack_state(
      i64 %state_in_2312)
  %nested.rsp = extractvalue { i64, i64, i64, i64 } %result, 2
  %raw = inttoptr i64 %nested.rsp to ptr
  store i8 8, ptr %raw, align 1
  ret void
}

define void @recursive_returned_stack_pointer(ptr %frame_base,
                                               i64 %state_in_2312,
                                               i1 %recurse) {
entry:
  %result = call { i64, i64 } @recursive_stack_state(
      i64 %state_in_2312, i1 %recurse)
  %recursive.rsp = extractvalue { i64, i64 } %result, 1
  %raw = inttoptr i64 %recursive.rsp to ptr
  store i8 10, ptr %raw, align 1
  ret void
}

define ptr @uncontracted_tuple_field(ptr %frame_base,
                                     i64 %state_in_2312) {
entry:
  %result = call { i64, i64, i64 } @uncontracted_result(
      i64 7, i64 %state_in_2312)
  %field = extractvalue { i64, i64, i64 } %result, 1
  %raw = inttoptr i64 %field to ptr
  ret ptr %raw
}

define ptr @nonstack_state_call_operand(ptr %frame_base, i64 %address) {
entry:
  %result = call { i64, i64, i64 } @advance_stack_state(
      i64 7, i64 %address)
  %field = extractvalue { i64, i64, i64 } %result, 1
  %raw = inttoptr i64 %field to ptr
  ret ptr %raw
}

define ptr @nested_nonstack_state_call_operand(ptr %frame_base,
                                               i64 %address) {
entry:
  %result = call { i64, i64, i64, i64 } @forward_stack_state(i64 %address)
  %field = extractvalue { i64, i64, i64, i64 } %result, 2
  %raw = inttoptr i64 %field to ptr
  ret ptr %raw
}

define ptr @rootless_recursive_result(ptr %frame_base) {
entry:
  %result = call { i64 } @rootless_recursive_state(i64 0)
  %field = extractvalue { i64 } %result, 0
  %raw = inttoptr i64 %field to ptr
  ret ptr %raw
}
