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

define i32 @local_frame_select() {
entry:
  %frame_storage = alloca [256 x i8], align 16
  %local.frame.slot = getelementptr i8, ptr %frame_storage, i64 112
  %local.frame.address = ptrtoint ptr %local.frame.slot to i64
  %local.in.guest.range = icmp ult i64 %local.frame.address, 16
  %local.guest.offset = and i64 %local.frame.address, 15
  %local.guest.pointer = getelementptr i8, ptr @g_scalar_0, i64 %local.guest.offset
  %native.data.pointer.select.local = select i1 %local.in.guest.range, ptr %local.guest.pointer, ptr %local.frame.slot
  store i32 9, ptr %native.data.pointer.select.local, align 4
  %value = load i32, ptr %local.frame.slot, align 4
  ret i32 %value
}

; A runtime RSP/RBP delta prevents constant-offset folding but does not erase
; the underlying global-frame provenance.
define i32 @dynamic_global_frame_select(i64 %offset) {
entry:
  %frame.top = getelementptr i8, ptr @frame_storage_backing.main, i64 128
  %dynamic.frame.slot = getelementptr i8, ptr %frame.top, i64 %offset
  %dynamic.frame.address = ptrtoint ptr %dynamic.frame.slot to i64
  %dynamic.in.guest.range = icmp ult i64 %dynamic.frame.address, 16
  %dynamic.guest.offset = and i64 %dynamic.frame.address, 15
  %dynamic.guest.pointer = getelementptr i8, ptr @g_scalar_0, i64 %dynamic.guest.offset
  %native.data.pointer.select.dynamic = select i1 %dynamic.in.guest.range, ptr %dynamic.guest.pointer, ptr %dynamic.frame.slot
  store i32 13, ptr %native.data.pointer.select.dynamic, align 1
  %value = load i32, ptr %dynamic.frame.slot, align 1
  ret i32 %value
}

; Cloned/recovered functions receive the native frame as an argument instead
; of referring to the original backing object directly.  That provenance is
; just as strong and must not be hidden behind the guest-data mapper.
define i32 @argument_frame_select(ptr %frame_base, i64 %offset) {
entry:
  %argument.frame.slot = getelementptr i8, ptr %frame_base, i64 %offset
  %argument.frame.address = ptrtoint ptr %argument.frame.slot to i64
  %argument.in.guest.range = icmp ult i64 %argument.frame.address, 16
  %argument.guest.offset = and i64 %argument.frame.address, 15
  %argument.guest.pointer = getelementptr i8, ptr @g_scalar_0, i64 %argument.guest.offset
  %native.data.pointer.select.argument = select i1 %argument.in.guest.range, ptr %argument.guest.pointer, ptr %argument.frame.slot
  store i32 11, ptr %native.data.pointer.select.argument, align 4
  %value = load i32, ptr %argument.frame.slot, align 4
  ret i32 %value
}
