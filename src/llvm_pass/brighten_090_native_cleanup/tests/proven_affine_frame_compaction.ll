target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

@frame_storage_backing.main = internal global [1024 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  store i64 0, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 880), align 16
  %result = call i32 @worker()
  ret i32 %result
}

define internal i32 @worker() {
entry:
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
