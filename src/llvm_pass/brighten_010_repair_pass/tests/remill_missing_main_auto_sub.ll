; RUN: opt -load-pass-plugin %PLUGIN -passes=refine-semantic-pass,verify -S %s -o - | FileCheck %s
; CHECK: define {{.*}}x86_64_sysvcc i32 @main(
; CHECK: call ptr @sub_31a9_auto_sub_31a9(
; CHECK-SAME: i64 12713

%r64 = type { i64 }
%r64w = type { %r64 }
%r32 = type { i32 }
%r32w = type { %r32 }
%regs = type { %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r32w }
%struct.State = type { i8, i8, i8, i8, i8, i8, %regs }
%struct.Memory = type { i8 }

@__mcsema_reg_state = global %struct.State zeroinitializer

declare ptr @auto_sub_31a9(ptr, i64, ptr)

define ptr @__mcsema_init_reg_state() {
entry:
  ret ptr @__mcsema_reg_state
}

define internal ptr @sub_1130_start(ptr %state, i64 %pc, ptr %memory) {
inst_1130:
  %callee = inttoptr i64 1 to ptr
  %ret = call i64 %callee(i64 ptrtoint (ptr @auto_sub_31a9 to i64), i64 1, i64 2, i64 0, i64 0, i64 0, i64 0, i64 0)
  ret ptr %memory
}

define internal ptr @sub_31a9_auto_sub_31a9(ptr %state, i64 %pc, ptr %memory) {
inst_31a9:
  ret ptr %memory
}
