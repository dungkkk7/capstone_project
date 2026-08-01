; After O3, a variadic pointer save-slot can be promoted into a select tree
; that was originally built from native.vararg.address = ptrtoint(native ptr).
; The final cleanup sweep must not keep treating that host pointer integer as
; a guest address for libc pointer arguments.

@str_cand_404010 = internal constant [16 x i8] c"%d\00%c\00%s\0A\00OK\00NA\00",
  align 1
@native.recovered.oob.scratch = internal global [1048576 x i8] zeroinitializer,
  align 1

declare i32 @puts(ptr)

define i32 @main() {
entry:
  %ok = getelementptr i8, ptr @str_cand_404010, i64 10
  %native.vararg.address = ptrtoint ptr %ok to i64
  %scratch.offset = and i64 %native.vararg.address, 1048568
  %scratch = getelementptr inbounds [1048576 x i8],
      ptr @native.recovered.oob.scratch, i64 0, i64 %scratch.offset
  %in.native.range = icmp ugt ptr %ok, inttoptr (i64 4210703 to ptr)
  %fallback = select i1 %in.native.range, ptr %scratch, ptr %ok
  %guest.rebased = getelementptr i8,
      ptr getelementptr (i8, ptr @str_cand_404010, i64 -4210704),
      i64 %native.vararg.address
  %arg = select i1 false, ptr %guest.rebased, ptr %fallback
  %call = call i32 @puts(ptr %arg)
  ret i32 0
}
