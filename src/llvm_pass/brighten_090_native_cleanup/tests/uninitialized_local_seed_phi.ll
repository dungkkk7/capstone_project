; An explicit undef PHI is observable LLVM underdefinition.  The cleanup must
; not move it into implicit memory state: doing so changes undef use topology
; and can change concrete native behaviour after later CFG rewrites.

define i32 @uninitialized_seed(i1 %again, i32 %previous) {
entry:
  %destination = alloca i32, align 4
  br label %header

backedge:
  br label %header

header:
  %seed = phi i32 [ undef, %entry ], [ %previous, %backedge ]
  store i32 %seed, ptr %destination, align 4
  br i1 %again, label %backedge, label %exit

exit:
  %value = load i32, ptr %destination, align 4
  ret i32 %value
}

define i32 @poison_seed_refused(i1 %again, i32 %previous) {
entry:
  %destination = alloca i32, align 4
  br label %header

backedge:
  br label %header

header:
  %seed = phi i32 [ poison, %entry ], [ %previous, %backedge ]
  store i32 %seed, ptr %destination, align 4
  br i1 %again, label %backedge, label %exit

exit:
  %value = load i32, ptr %destination, align 4
  ret i32 %value
}

; CHECK-LABEL: define i32 @uninitialized_seed(
; CHECK: header:
; CHECK: %seed = phi i32 [ undef, %entry ], [ %previous, %backedge ]
; CHECK: store i32 %seed, ptr %destination, align 4
; CHECK-LABEL: define i32 @poison_seed_refused(
; CHECK: %seed = phi i32 [ poison, %entry ], [ %previous, %backedge ]
; CHECK: store i32 %seed, ptr %destination, align 4
