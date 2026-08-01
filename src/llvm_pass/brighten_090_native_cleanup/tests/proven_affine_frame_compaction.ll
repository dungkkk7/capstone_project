target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

@frame_storage_backing.main = internal global [1024 x i8] zeroinitializer, align 16
@dyn_bytes_1000 = internal global [64 x i8] zeroinitializer, align 1,
  !brighten.guest.range !0
@llvm.used = appending global [1 x ptr] [ptr @dyn_bytes_1000],
  section "llvm.metadata"

define i32 @main() {
entry:
  store i64 0, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 880), align 16
  %result = call i32 @worker()
  ret i32 %result
}

define internal i32 @worker() {
entry:
  %frame.address = ptrtoint ptr getelementptr (
      i8, ptr @frame_storage_backing.main, i64 928) to i64
  store i64 %frame.address,
      ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 880),
      align 8
  %frame.address.copy = load i64,
      ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 880),
      align 8
  store i64 %frame.address.copy,
      ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 888),
      align 8
  %frame.address.reload = load i64,
      ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 888),
      align 8
  %frame.pointer = inttoptr i64 %frame.address.reload to ptr
  store i8 0, ptr %frame.pointer, align 1
  store i32 0, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %dispatch

hub:
  %sp.next = phi i64 [ %sp.dec, %enter ], [ %sp, %nested ]
  %next = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %dispatch

dispatch:
  %control = phi i32 [ 0, %entry ], [ %next, %hub ]
  %sp = phi i64 [ add (i64 ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960) to i64), i64 -32), %entry ], [ %sp.next, %hub ]
  switch i32 %control, label %nested [
    i32 0, label %enter
    i32 3, label %exit
    i32 4, label %exit
  ]

nested:
  switch i32 %control, label %hub [
    i32 1, label %body
    i32 2, label %exit
  ]

enter:
  %sp.dec = add i64 %sp, -64
  %enter.delta = sub i64 %sp.dec, ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960) to i64)
  %enter.slot = getelementptr i8, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960), i64 %enter.delta
  store i32 7, ptr %enter.slot, align 4
  store i32 1, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %hub

body:
  %body.delta = sub i64 %sp, ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960) to i64)
  %body.slot = getelementptr i8, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960), i64 %body.delta
  %value = load i32, ptr %body.slot, align 4
  ret i32 %value

exit:
  ret i32 99
}

; The final pass initially cannot match the store and load below because the
; load slot is expressed through a ptrtoint cancellation. Compaction of the
; proven affine frame above triggers one post-compaction InstCombine sweep;
; both addresses then become exact native-frame slots and the generated
; guest-range dispatch can be removed safely.
define i32 @post_frame_dispatch(ptr %base) {
entry:
  %native_frame = alloca [16 x i8], align 8
  %store.slot = getelementptr i8, ptr %native_frame, i64 8
  %base.bits = ptrtoint ptr %base to i64
  store i64 %base.bits, ptr %store.slot, align 8
  %anchor.bits = ptrtoint ptr %native_frame to i64
  %slot.bits = add i64 %anchor.bits, 8
  %slot.offset = sub i64 %slot.bits, %anchor.bits
  %load.slot = getelementptr i8, ptr %native_frame, i64 %slot.offset
  %loaded.bits = load i64, ptr %load.slot, align 8
  %fallback = inttoptr i64 %loaded.bits to ptr
  %guest.offset = add i64 %loaded.bits, -4096
  %in.range = icmp ult i64 %guest.offset, 64
  %guest.pointer = getelementptr i8, ptr @dyn_bytes_1000,
      i64 %guest.offset
  %native.data.pointer.select = select i1 %in.range, ptr %guest.pointer,
      ptr %fallback
  %value = load i32, ptr %native.data.pointer.select, align 4
  ret i32 %value
}

!0 = !{i64 4096, i64 4160}
