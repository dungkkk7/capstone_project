; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-ollvm-deobf-pass,simplifycfg,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; CHECK-LABEL: define i32 @terminal_latch_dispatcher(
; CHECK-NOT: switch i32
; CHECK-NOT: ret i32 poison
; CHECK: ret i32 %

define i32 @terminal_latch_dispatcher(i1 %choose) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %next.acc, %latch ]
  switch i32 %state, label %default [
    i32 10, label %case.a
    i32 20, label %case.b
    i32 30, label %case.c
    i32 40, label %case.d
  ]

case.a:
  %a.state = select i1 %choose, i32 20, i32 30
  br label %latch

case.b:
  br label %latch

case.c:
  br label %latch

case.d:
  br label %latch

default:
  br label %latch

latch:
  %next = phi i32 [ %a.state, %case.a ], [ 40, %case.b ],
                        [ 40, %case.c ], [ 99, %case.d ], [ %state, %default ]
  %next.acc = phi i32 [ 1, %case.a ], [ 2, %case.b ],
                            [ 3, %case.c ], [ 4, %case.d ], [ %acc, %default ]
  %done = icmp eq i32 %next, 99
  br i1 %done, label %exit, label %dispatch

exit:
  ret i32 %next.acc
}
