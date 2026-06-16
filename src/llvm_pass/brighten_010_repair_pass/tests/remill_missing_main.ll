; RUN: opt -load-pass-plugin %PLUGIN -passes=refine-semantic-pass,verify -S %s -o - | FileCheck %s
; CHECK: define {{.*}}x86_64_sysvcc i32 @main(
; CHECK: call ptr @__mcsema_init_reg_state()
; CHECK: call ptr @__lifter_refine_dispatch_sub_1200(
; CHECK-SAME: i64 4660

%r64 = type { i64 }
%r64w = type { %r64 }
%r32 = type { i32 }
%r32w = type { %r32 }
%regs = type { %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r64w, %r32w }
%struct.State = type { i8, i8, i8, i8, i8, i8, %regs }
%struct.Memory = type { i8 }

@data_1234 = internal global i8 0
@__mcsema_reg_state = global %struct.State zeroinitializer

declare ptr @__remill_function_call(ptr, i64, ptr)

define ptr @__mcsema_init_reg_state() {
entry:
  ret ptr @__mcsema_reg_state
}

define internal ptr @sub_1000_start(ptr %state, i64 %pc, ptr %memory) {
inst_1000:
  %callee = inttoptr i64 1 to ptr
  %ret = call i64 %callee(i64 ptrtoint (ptr @data_1234 to i64), i64 1, i64 2, i64 0, i64 0, i64 0, i64 0, i64 0)
  ret ptr %memory
}

define internal ptr @sub_1200(ptr %state, i64 %pc, ptr %memory) {
inst_1200:
  br label %inst_1234

inst_1234:
  ret ptr %memory
}

