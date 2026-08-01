; The final pass must report these generated recovery artifacts without
; rewriting any of them.
target triple = "x86_64-pc-linux-gnu"

@dyn_bytes_401000 = internal global [64 x i8] zeroinitializer
@native_register_storage = internal global [256 x i8] zeroinitializer

declare ptr @__brighten_native_data_pointer(i64)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %native_frame = alloca [32 x i8], align 8
  %state.slot = getelementptr i8, ptr %native_frame, i64 4
  br label %dispatch

dispatch:
  %state = phi i32 [ -1938475621, %entry ], [ 827364911, %case.zero ], [ %next, %default.backedge ]
  switch i32 %state, label %default.edge [
    i32 -1938475621, label %case.zero
    i32 827364911, label %done
  ]

default.edge:
  %next = load i32, ptr %state.slot, align 4
  br label %default.backedge

default.backedge:
  br label %dispatch

case.zero:
  %guest.address = zext i32 %argc to i64
  %native.address.fallback = inttoptr i64 %guest.address to ptr
  %delta = add i64 %guest.address, -4198400
  %in.range = icmp ult i64 %delta, 64
  %mapped = getelementptr i8, ptr @dyn_bytes_401000, i64 %delta
  %native.data.pointer.select = select i1 %in.range, ptr %mapped, ptr %native.address.fallback
  store i8 0, ptr %native.data.pointer.select
  br label %dispatch

done:
  ret i32 0
}
