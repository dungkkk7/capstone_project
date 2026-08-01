; The lifted x86 TLS read has a direct target-independent LLVM intrinsic.
;
; CHECK-LABEL: define i32 @main(
; CHECK: %native.thread.pointer = call ptr @llvm.thread.pointer.p0()
; CHECK: %native.thread.pointer.bits = ptrtoint ptr %native.thread.pointer to i64
; CHECK-NOT: asm

target triple = "x86_64-pc-linux-gnu"

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %tls = call i64 asm "movq %fs:0, $0", "=r"()
  %present = icmp ne i64 %tls, 0
  %result = zext i1 %present to i32
  ret i32 %result
}

; CHECK-LABEL: define i32 @unused_tls_read(
; CHECK-NOT: asm
; CHECK-NOT: llvm.thread.pointer
; CHECK: ret i32 7
define i32 @unused_tls_read() {
entry:
  %tls = call i64 asm "movq %fs:0, $0", "=r"()
  ret i32 7
}
