; The native boundary seeds RSP from frame_top while the incoming RBP slot is
; still zero.  Late stack lowering must subtract the RSP seed, never whichever
; RSP/RBP load happens to appear first in the entry block.

%struct.State = type { [3000 x i8] }

@__mcsema_reg_state = internal global %struct.State zeroinitializer, align 16

define i32 @main() {
entry:
  %frame_storage = alloca [4096 x i8], align 16
  %frame_top = getelementptr inbounds i8, ptr %frame_storage, i64 4000
  %native.boundary.rsp = ptrtoint ptr %frame_top to i64
  %rbp.slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2328
  %entry.rbp = load i64, ptr %rbp.slot, align 8
  %rsp.slot = getelementptr i8, ptr @__mcsema_reg_state, i64 2312
  store i64 %native.boundary.rsp, ptr %rsp.slot, align 8
  %state_2312 = load i64, ptr %rsp.slot, align 8
  %address = add i64 %state_2312, -32
  %pointer = inttoptr i64 %address to ptr
  store i32 7, ptr %pointer, align 4
  %result = load i32, ptr %pointer, align 4
  ret i32 %result
}
