; RUN: opt -passes=brighten-region-ssa-unflatten-pass,simplifycfg,verify -S %s | FileCheck %s
; The 1 -> 2 transition is proven and carries %value through the latch.
; The argument-dependent fallback remains routed through the dispatcher.

@trace = internal global i32 0

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %value = phi i32 [ 2, %entry ], [ %next.value, %latch ]
  store i32 %state, ptr @trace
  br label %hub

hub:
  switch i32 %state, label %fallback [
    i32 1, label %case.one
    i32 2, label %case.two
  ]

case.one:
  %incremented = add i32 %value, 1
  br label %latch

case.two:
  ret i32 %value

fallback:
  %dynamic = add i32 %argc, 1
  br label %latch

latch:
  %next.state = phi i32 [ 2, %case.one ], [ %dynamic, %fallback ]
  %next.value = phi i32 [ %incremented, %case.one ], [ %value, %fallback ]
  store i32 %next.state, ptr @trace
  br label %header
}

; CHECK: case.one:
; CHECK: br label %region.thread
; CHECK: region.thread:
; CHECK: store i32 2, ptr @trace
; CHECK: br label %case.two
; CHECK: fallback:
; CHECK: br label %latch

