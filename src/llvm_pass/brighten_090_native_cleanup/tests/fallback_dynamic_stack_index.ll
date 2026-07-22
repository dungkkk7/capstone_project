; A partially recovered function can expose RSP as an integer argument before
; it has an explicit frame_base/native_stack pointer.  The fallback stack
; lowering must preserve the runtime index in rsp + constant + index.

define void @worker(i64 %state_in_2312, i64 %index) {
entry:
  %scaled = mul i64 %index, 4
  %base = add i64 %state_in_2312, -480
  %address = add i64 %base, %scaled
  %pointer = inttoptr i64 %address to ptr
  store i32 0, ptr %pointer, align 4
  ret void
}

; CHECK-LABEL: define void @worker
; CHECK: %frame.base = inttoptr i64 %state_in_2312 to ptr
; CHECK: %frame.gep = getelementptr i8, ptr %frame.base, i64 -480
; CHECK: %frame.dynamic.gep = getelementptr i8, ptr %frame.gep, i64 %scaled
; CHECK: store i32 0, ptr %frame.dynamic.gep
