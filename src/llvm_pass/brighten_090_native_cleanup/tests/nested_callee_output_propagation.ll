; A caller that does not otherwise touch RDX still needs a local SSA slot for
; the RDX output returned by its transformed callee.  Missing this transitive
; slot used to abort the entire native-State rewrite and leave nested guest
; frames sharing one fixed global backing array.

target triple = "x86_64-pc-linux-gnu"

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define internal void @sub_callee.native(ptr %state) {
entry:
  %rdx = getelementptr i8, ptr %state, i64 2264
  store i64 42, ptr %rdx, align 8
  ret void
}

define internal i64 @sub_caller.native(ptr %state) {
entry:
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp = load i64, ptr %rsp.ptr, align 8
  call void @sub_callee.native(ptr %state)
  ret i64 %rsp
}

define i32 @main() {
entry:
  %state = alloca [3376 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 3376, i1 false)
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  store i64 4096, ptr %rsp.ptr, align 8
  %result = call i64 @sub_caller.native(ptr %state)
  %exit = trunc i64 %result to i32
  ret i32 %exit
}

