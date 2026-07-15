@__mcsema_reg_state = global [4096 x i8] zeroinitializer

declare ptr @state_clobber(ptr, i64, ptr)

define ptr @sub_stale_after_call(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rax = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  store i64 11, ptr %rax, align 8
  %next = call ptr @state_clobber(ptr %state, i64 %pc, ptr %memory)
  ret ptr %next
}

define ptr @sub_different_paths(ptr %state, i64 %pc, ptr %memory, i1 %cond) {
entry:
  br i1 %cond, label %left, label %right
left:
  %rax.left = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  store i64 1, ptr %rax.left, align 8
  br label %join
right:
  %rax.right = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  store i64 2, ptr %rax.right, align 8
  br label %join
join:
  br label %ret.block
ret.block:
  ret ptr %memory
}

define ptr @sub_safe_return(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rax = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  store i64 37, ptr %rax, align 8
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_stale_after_call
; CHECK-NOT: [ "brighten_return_rax"
; CHECK: ret ptr %next
; CHECK-LABEL: define ptr @sub_different_paths
; CHECK-NOT: [ "brighten_return_rax"
; CHECK: ret ptr %memory
; CHECK-LABEL: define ptr @sub_safe_return
; CHECK: call void @llvm.sideeffect() [ "brighten_return_rax"(i64 37) ]
; CHECK: ret ptr %memory

