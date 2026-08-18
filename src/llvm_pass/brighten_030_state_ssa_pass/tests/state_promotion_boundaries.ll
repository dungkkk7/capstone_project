; Stack-register allocas retain machine-readable provenance for pass 040;
; overlapping State accesses cannot be split into incoherent allocas, and
; native pointers are not State.

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define internal void @native_helper(ptr %p) {
entry:
  store i8 7, ptr %p
  ret void
}

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory, ptr %buffer) {
entry:
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp = load i64, ptr %rsp.ptr, align 8
  store i64 %rsp, ptr %rsp.ptr, align 8
  %rbp.ptr = getelementptr i8, ptr %state, i64 2328
  %rbp = load i64, ptr %rbp.ptr, align 8
  store i64 %rbp, ptr %rbp.ptr, align 8

  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  store i64 42, ptr %rax.ptr, align 8
  %rax = load i64, ptr %rax.ptr, align 8

  %xmm0.ptr = getelementptr i8, ptr %state, i64 16
  store i64 0, ptr %xmm0.ptr, align 8

  %wide.ptr = getelementptr i8, ptr %state, i64 2200
  store i64 %rax, ptr %wide.ptr, align 8
  %overlap.ptr = getelementptr i8, ptr %state, i64 2204
  store i32 9, ptr %overlap.ptr, align 4

  call void @native_helper(ptr %buffer)
  ret ptr %memory
}

define i64 @ordinary_native(ptr %buffer) {
entry:
  %far = getelementptr i8, ptr %buffer, i64 2216
  %value = load i64, ptr %far, align 8
  ret i64 %value
}

define ptr @__remill_function_call(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rsp = getelementptr i8, ptr %state, i64 2312
  store i64 4096, ptr %rsp, align 8
  %value = load i64, ptr %rsp, align 8
  ret ptr %memory
}

; Canonical register families use one shared cell per full architectural
; register. XMM aliases therefore occupy one i128 cell even when the observed
; access is only the low i64 half. Cell creation order is intentionally not an
; invariant, so the four independent declarations are checked as a DAG.
; CHECK-DAG: %state_cell_2216 = alloca i64{{.*}}!brighten.state.offset
; CHECK-DAG: %state_cell_16 = alloca i128{{.*}}!brighten.state.offset
; CHECK-DAG: %state_cell_2312 = alloca i64{{.*}}!brighten.state.offset
; CHECK-DAG: %state_cell_2328 = alloca i64{{.*}}!brighten.state.offset
; CHECK-NOT: %state_cell_2200 = alloca
; CHECK-NOT: %state_cell_2204 = alloca
; CHECK: call void @native_helper(ptr %buffer)
; CHECK-NOT: getelementptr i8, ptr %buffer, i64 2216
; CHECK-LABEL: define i64 @ordinary_native
; CHECK: %far = getelementptr i8, ptr %buffer, i64 2216
; CHECK-LABEL: define ptr @__remill_function_call
; CHECK: %state_cell_2312 = alloca i64{{.*}}!brighten.state.offset
