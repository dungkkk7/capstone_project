; A generated guest-data range mapper can survive until stack provenance is
; recovered on its fallback arm.  Once that arm is an exact frame pointer the
; synthetic data alternatives must not hide the frame store from State/CFF
; analysis.

@frame_storage_backing.main = internal global [256 x i8] zeroinitializer, align 16
@g_scalar_0 = internal global [16 x i8] zeroinitializer, align 4

declare void @observe(ptr)

define i32 @main() {
entry:
  %frame.slot = getelementptr i8, ptr @frame_storage_backing.main, i64 112
  %frame.address = ptrtoint ptr %frame.slot to i64
  %in.guest.range = icmp ult i64 %frame.address, 16
  %guest.offset = and i64 %frame.address, 15
  %guest.pointer = getelementptr i8, ptr @g_scalar_0, i64 %guest.offset
  %native.data.pointer.select = select i1 %in.guest.range, ptr %guest.pointer, ptr %frame.slot
  store i32 7, ptr %native.data.pointer.select, align 4
  %value = load i32, ptr %frame.slot, align 4
  call void @observe(ptr %frame.slot)
  ret i32 %value
}
