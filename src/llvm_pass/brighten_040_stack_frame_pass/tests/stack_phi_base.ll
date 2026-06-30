; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@RSP_0_i = alias i64, ptr @__mcsema_reg_state

define i32 @stack_phi_base(i1 %cond) {
entry:
  %rsp = load i64, ptr @RSP_0_i, align 8
  %base0 = sub i64 %rsp, 32
  br i1 %cond, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %sp = phi i64 [ %base0, %left ], [ %base0, %right ]
  %slot = add i64 %sp, 8
  %ptr = inttoptr i64 %slot to ptr
  store i32 7, ptr %ptr, align 4
  ret i32 0
}

; CHECK-LABEL: define i32 @stack_phi_base
; CHECK: %stack_frame = alloca
; CHECK: %frame_ptr = getelementptr
; CHECK: store i32 7, ptr %frame_ptr
; CHECK-NOT: inttoptr
