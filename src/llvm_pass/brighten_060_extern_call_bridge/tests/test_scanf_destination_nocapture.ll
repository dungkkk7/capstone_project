; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge,verify -S < %s | FileCheck %s

; Exact direct scanf-family formats prove only that destination pointers are
; not retained.  They remain writable and no memory-effect attribute is added.

target triple = "x86_64-unknown-linux-gnu"

@.scan = private constant [9 x i8] c"%d %% %s\00"
@.sscan = private constant [5 x i8] c"%d%d\00"
@.fscan = private constant [3 x i8] c"%s\00"

declare i32 @scanf(ptr, ...)
declare i32 @sscanf(ptr, ptr, ...)
declare i32 @fscanf(ptr, ptr, ...)

; CHECK-LABEL: define i32 @heap_scan
; CHECK: call i32 (ptr, ...) @scanf(ptr @.scan, ptr captures(none) %heap, ptr captures(none) %buf)
define i32 @heap_scan(ptr %heap, ptr %buf) {
  %r = call i32 (ptr, ...) @scanf(ptr @.scan, ptr %heap, ptr %buf)
  ret i32 %r
}

; CHECK-LABEL: define i32 @two_destinations
; CHECK: call i32 (ptr, ptr, ...) @sscanf(ptr %input, ptr @.sscan, ptr captures(none) %a, ptr captures(none) %b)
define i32 @two_destinations(ptr %input, ptr %a, ptr %b) {
  %r = call i32 (ptr, ptr, ...) @sscanf(ptr %input, ptr @.sscan, ptr %a, ptr %b)
  ret i32 %r
}

; CHECK-LABEL: define i32 @file_string
; CHECK: call i32 (ptr, ptr, ...) @fscanf(ptr %file, ptr @.fscan, ptr captures(none) %buffer)
define i32 @file_string(ptr %file, ptr %buffer) {
  %r = call i32 (ptr, ptr, ...) @fscanf(ptr %file, ptr @.fscan, ptr %buffer)
  ret i32 %r
}
