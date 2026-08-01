; A recovered global pointer may be carried through McSema-style integer
; pointer slots as ptrtoint(native_object).  Re-dispatching that host address
; as a guest address can corrupt libc arguments, e.g. puts("OK") receiving a
; bogus pointer.  The cleanup pass must collapse the round-trip back to the
; native global GEP.

@str_cand_404010 = internal constant [16 x i8] c"%d\00%c\00%s\0A\00OK\00NA\00",
  align 1

declare i32 @puts(ptr)

define i32 @main() {
entry:
  %ok = getelementptr i8, ptr @str_cand_404010, i64 10
  %addr = ptrtoint ptr %ok to i64
  %ptr = inttoptr i64 %addr to ptr
  %call = call i32 @puts(ptr %ptr)
  ret i32 0
}
