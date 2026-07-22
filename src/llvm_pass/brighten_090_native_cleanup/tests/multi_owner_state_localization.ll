; Independent host ABI roots must not share McSema's synthetic register file.
; The entrypoint and callback have separate native activations, and the State
; address neither escapes nor crosses a direct call between them.  Localize a
; zero-initialized State per root so O3 can promote its slots and erase the
; identified State type.
;
; CHECK-NOT: __mcsema_reg_state
; CHECK-NOT: struct.State
; CHECK-NOT: native_state_storage
; CHECK-LABEL: define{{.*}}i32 @main()
; CHECK: ret i32 7
; CHECK-LABEL: define internal{{.*}}i32 @compare.native_callback(ptr
; CHECK: ret i32 3

%struct.State = type { [32 x i8] }

@__mcsema_reg_state = global %struct.State zeroinitializer

declare void @invoke(ptr)

define i32 @main() {
entry:
  store i32 7, ptr @__mcsema_reg_state, align 4
  call void @invoke(ptr @compare.native_callback)
  %result = load i32, ptr @__mcsema_reg_state, align 4
  ret i32 %result
}

define internal i32 @compare.native_callback(ptr %lhs, ptr %rhs) {
entry:
  %slot = getelementptr i8, ptr @__mcsema_reg_state, i64 8
  store i32 3, ptr %slot, align 4
  %result = load i32, ptr %slot, align 4
  ret i32 %result
}
