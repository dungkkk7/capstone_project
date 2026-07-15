; The stack pass and native State lowering expose an OLLVM dispatcher as an
; SSA state machine.  The production pipeline must run LLVM's DFA threading
; after that lowering so this lifted control-flow artifact does not survive.
define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %state

state:
  %dispatch.state = phi i32 [ 11, %entry ], [ 29, %body ]
  br label %dispatch

dispatch:
  switch i32 %dispatch.state, label %dispatch [
    i32 11, label %body
    i32 29, label %exit
  ]

body:
  br label %state

exit:
  ret i32 7
}
