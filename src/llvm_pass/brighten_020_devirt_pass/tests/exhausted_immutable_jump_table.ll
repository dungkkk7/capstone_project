; A defined load from this immutable table can produce only the three listed
; PCs.  The chained switches consume all three, so their final default is the
; invalid/OOB path and must not retain the Remill dispatcher SCC.
;
; CHECK-LABEL: define ptr @worker(
; CHECK-NOT: call ptr @__remill_jump
; CHECK: devirt.invalid.table.target:
; CHECK-NEXT: unreachable

@targets = private constant [3 x i64] [i64 4096, i64 8192, i64 12288]

declare ptr @__remill_jump(ptr, i64, ptr)

define ptr @worker(ptr %state, ptr %memory, i64 %index) {
entry:
  %scaled = shl i64 %index, 3
  %slot = getelementptr i8, ptr @targets, i64 %scaled
  %pc = load i64, ptr %slot, align 8
  switch i64 %pc, label %second [
    i64 4096, label %done
    i64 8192, label %done
  ]

second:
  %low = trunc i64 %pc to i32
  switch i32 %low, label %fallback [
    i32 12288, label %done
  ]

fallback:
  %ignored = call ptr @__remill_jump(ptr %state, i64 %pc, ptr %memory)
  br label %done

done:
  ret ptr %memory
}
