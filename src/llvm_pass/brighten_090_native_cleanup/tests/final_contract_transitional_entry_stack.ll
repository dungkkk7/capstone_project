; A transitional entry stack may exist only before final native cleanup.  The
; final contract must reject it rather than silently accepting a giant frame.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %entry_guest_stack = alloca [65536 x i8], align 16, !brighten.entry_guest_stack.transitional !0
  ret i32 0
}

!0 = !{!"seeded-guest-rsp-entry-boundary"}
