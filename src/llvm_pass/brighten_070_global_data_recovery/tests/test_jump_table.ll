; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: jump table recovery from rodata segment

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Jump table in rodata with 3 entries pointing to sub_1000, sub_2000, sub_3000
; LE 64-bit addresses: 0x001000, 0x002000, 0x003000
@seg_403000__rodata = global [24 x i8] c"\00\10\00\00\00\00\00\00\00\20\00\00\00\00\00\00\00\30\00\00\00\00\00\00"

declare ptr @__remill_jump(ptr, i64, ptr)

define ptr @sub_1000(ptr %state, i64 %pc, ptr %mem) {
  ret ptr %mem
}

define ptr @sub_2000(ptr %state, i64 %pc, ptr %mem) {
  ret ptr %mem
}

define ptr @sub_3000(ptr %state, i64 %pc, ptr %mem) {
  ret ptr %mem
}

; CHECK-LABEL: define ptr @test_switch
; The pass should recognize the jump table pattern
define ptr @test_switch(ptr %state, i64 %pc, ptr %mem, i64 %idx) {
entry:
  %addr_ptr = getelementptr [24 x i8], ptr @seg_403000__rodata, i64 0, i64 %idx
  %target = load i64, ptr %addr_ptr
  %ret = call ptr @__remill_jump(ptr %state, i64 %target, ptr %mem)
  ret ptr %ret
}
