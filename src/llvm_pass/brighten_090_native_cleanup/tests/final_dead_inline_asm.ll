target triple = "x86_64-pc-linux-gnu-elf"

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %fs = call i64 asm "movq %fs:0, $0", "=r"()
  ret i32 0
}
