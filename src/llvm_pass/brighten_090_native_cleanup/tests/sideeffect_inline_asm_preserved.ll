target triple = "x86_64-pc-linux-gnu-elf"

define i32 @main() {
entry:
  call void asm sideeffect "nop", ""()
  ret i32 0
}
