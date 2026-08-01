; RUN: opt -load-pass-plugin ../build/BrightenNativeCleanupPass.so \
; RUN:   -passes='brighten-native-cleanup-pass,verify' -S %s | FileCheck %s

; The lifted stack GEP below contains a pointer-to-integer round trip whose
; base is subtracted from itself.  The pass may fold that identity, but it
; must not invent a host address or treat the integer as an arbitrary pointer.

@frame_storage_backing.main = internal global [64 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  %base = getelementptr inbounds i8, ptr @frame_storage_backing.main, i64 32
  %base.bits = ptrtoint ptr %base to i64
  %shifted = add i64 %base.bits, -8
  %offset = sub i64 %shifted, %base.bits
  %slot = getelementptr i8, ptr %base, i64 %offset
  store i32 7, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK: @frame_storage_backing.main
; CHECK-LABEL: define i32 @main()
; CHECK-NOT: inttoptr
; CHECK: %base.bits = ptrtoint ptr %base to i64
; CHECK: %slot = getelementptr i8, ptr %base, i64 %offset
; CHECK: store i32 7
; CHECK: load i32
