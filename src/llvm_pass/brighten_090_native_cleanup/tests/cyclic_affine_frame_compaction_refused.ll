target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

@frame_storage_backing.main = internal global [1024 x i8] zeroinitializer, align 16

define void @main() {
entry:
  store i32 0, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %dispatch

hub:
  %sp.next = phi i64 [ %sp.dec, %enter ], [ %sp, %body ], [ %sp, %nested ]
  %next = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %dispatch

dispatch:
  %control = phi i32 [ 0, %entry ], [ %next, %hub ]
  %sp = phi i64 [ add (i64 ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960) to i64), i64 -32), %entry ], [ %sp.next, %hub ]
  switch i32 %control, label %nested [
    i32 0, label %enter
  ]

nested:
  switch i32 %control, label %hub [
    i32 1, label %body
  ]

enter:
  %sp.dec = add i64 %sp, -64
  %enter.delta = sub i64 %sp.dec, ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960) to i64)
  %enter.slot = getelementptr i8, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 960), i64 %enter.delta
  store i32 7, ptr %enter.slot, align 4
  store i32 1, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %hub

body:
  store i32 0, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 900), align 4
  br label %hub
}
