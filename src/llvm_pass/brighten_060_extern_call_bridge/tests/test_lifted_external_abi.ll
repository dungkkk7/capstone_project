; RUN: opt -load-pass-plugin %plugin -passes=brighten-extern-call-bridge -S %s | FileCheck %s

declare i64 @strlen.lifted_abi(i64)
declare i64 @strncmp.lifted_abi(i64, i64, i64)
declare i64 @fgets.lifted_abi(i64, i64, i64)
declare i64 @vprintf.lifted_abi(ptr, ptr)
declare i64 @vscanf.lifted_abi(ptr, ptr)

declare i64 @strlen(ptr)
declare i32 @strncmp(ptr, ptr, i64)
declare ptr @fgets(ptr, i32, ptr)
declare i32 @vprintf(ptr, ptr)
declare i32 @vscanf(ptr, ptr)

define i64 @late_external_abi(ptr %a, ptr %b, ptr %stream) {
entry:
  %ai = ptrtoint ptr %a to i64
  %bi = ptrtoint ptr %b to i64
  %si = ptrtoint ptr %stream to i64
  %n = call i64 @strlen.lifted_abi(i64 %ai)
  %cmp = call i64 @strncmp.lifted_abi(i64 %ai, i64 %bi, i64 %n)
  %line = call i64 @fgets.lifted_abi(i64 %ai, i64 32, i64 %si)
  %keep = xor i64 %cmp, %line
  ret i64 %keep
}

define i64 @late_valist_external_abi(ptr %fmt, ptr %ap) {
entry:
  %printed = call i64 @vprintf.lifted_abi(ptr %fmt, ptr %ap)
  %scanned = call i64 @vscanf.lifted_abi(ptr %fmt, ptr %ap)
  %sum = add i64 %printed, %scanned
  ret i64 %sum
}

; CHECK-LABEL: define i64 @late_external_abi
; CHECK: call i64 @strlen(ptr %a)
; CHECK: call i32 @strncmp(ptr %a, ptr %b, i64
; CHECK: call ptr @fgets(ptr %a, i32 32, ptr %stream)
; CHECK-NOT: call i64 @{{.*}}.lifted_abi
; CHECK-LABEL: define i64 @late_valist_external_abi
; CHECK: call i32 @vprintf(ptr %fmt, ptr %ap)
; CHECK: call i32 @vscanf(ptr %fmt, ptr %ap)
; CHECK-NOT: call i64 @{{.*}}.lifted_abi
