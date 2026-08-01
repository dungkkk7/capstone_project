; Final strict cleanup must not certify explicit undef/poison merely because
; it is immediately frozen. The arbitrary fixed value is refined to zero.
target triple = "x86_64-pc-linux-gnu"

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %defined = freeze i32 poison
  ret i32 %defined
}
