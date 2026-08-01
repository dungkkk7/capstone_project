; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]

declare ptr @ext_406050_pow(ptr, i64, ptr)
declare void @consume.native(ptr %memory)

; A recovered native callee carries the Remill memory token in arg0 rather
; than arg2. The external result may therefore feed both the dispatcher PHI
; and a .native call without becoming program data.
;
; CHECK-LABEL: define ptr @native_memory_loop
; CHECK: %pow.ret = call double @pow(double 2.000000e+00, double 3.000000e+00)
; CHECK: store double %pow.ret, ptr %xmm0.ptr
; CHECK: call void @consume.native(ptr %memory)
; CHECK-NOT: call ptr @ext_406050_pow
define ptr @native_memory_loop(ptr %state, ptr %initial_memory, i1 %again) {
entry:
  br label %loop

loop:
  %memory = phi ptr [ %initial_memory, %entry ], [ %external_memory, %loop ]
  %xmm0 = getelementptr i8, ptr @__mcsema_reg_state, i64 16
  store double 2.000000e+00, ptr %xmm0, align 8
  %xmm1 = getelementptr i8, ptr @__mcsema_reg_state, i64 80
  store double 3.000000e+00, ptr %xmm1, align 8
  %external_memory = call ptr @ext_406050_pow(
      ptr %state, i64 0, ptr %memory)
  call void @consume.native(ptr %external_memory)
  br i1 %again, label %loop, label %exit

exit:
  ret ptr %external_memory
}
