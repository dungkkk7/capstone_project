; A store from one predecessor does not define a local pointer on every path.
; The bridge must preserve the lifted call instead of choosing a BFS branch.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

@__mcsema_reg_state = external global [3072 x i8]
@.msg = private constant [2 x i8] c"x\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @puts(ptr)

; CHECK-LABEL: define ptr @sub_branch_local
; CHECK: call ptr @__remill_function_call
; CHECK-NOT: call i32 @puts
define ptr @sub_branch_local(ptr %state, i64 %pc, ptr %mem, i1 %cond) {
entry:
  %slot = alloca ptr, align 8
  br i1 %cond, label %set, label %unset
set:
  store ptr @.msg, ptr %slot, align 8
  br label %join
unset:
  br label %join
join:
  %arg = load ptr, ptr %slot, align 8
  %rdi = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr %arg, ptr %rdi, align 8
  %r = call ptr @__remill_function_call(ptr %state, i64 ptrtoint (ptr @puts to i64), ptr %mem)
  ret ptr %r
}
