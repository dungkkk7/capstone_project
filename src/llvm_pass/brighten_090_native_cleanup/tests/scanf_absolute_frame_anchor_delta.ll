; O3 can leave a direct scanf destination as an absolute frame carrier:
;   inttoptr(ptrtoint(frame_top) - 16)
; The rollback scanf cleanup must preserve the -16 delta instead of rebasing
; against an unrelated entry-block RSP store and collapsing the destination to
; frame_top.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16
@fmt = internal constant [3 x i8] c"%d\00", align 1

declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %call = call i32 (ptr, ...) @scanf(
      ptr @fmt,
      ptr inttoptr (i64 add (
          i64 ptrtoint (
              ptr getelementptr (i8, ptr @frame_storage_backing.main,
                                 i64 16711680) to i64),
          i64 -16) to ptr))
  ret i32 %call
}
