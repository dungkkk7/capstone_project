; A single-use recovered boundary whose concrete frame is owned by its caller
; can be inlined without changing ABI-visible sharing.  Normal scalar cleanup
; then removes the synthetic frame completely.
;
; CHECK-LABEL: define i32 @main(
; CHECK-NOT: call i32 @local_boundary
; CHECK-NOT: alloca
; CHECK: ret i32 %x
; CHECK-NOT: define internal i32 @local_boundary

define i32 @main(i32 %x, ptr %argv) {
entry:
  %frame = alloca [64 x i8], align 16
  %top = getelementptr i8, ptr %frame, i64 64
  %result = call i32 @local_boundary(ptr %top, i32 %x)
  ret i32 %result
}

define internal i32 @local_boundary(ptr %frame_base, i32 %value) #0 {
entry:
  %slot = getelementptr i8, ptr %frame_base, i64 -4
  store i32 %value, ptr %slot, align 4
  %result = load i32, ptr %slot, align 4
  ret i32 %result
}

; The capability attribute alone is insufficient: a pointer supplied by the
; caller's ABI is not a caller-owned activation frame, so this boundary stays.
;
; CHECK-LABEL: define i32 @argument_driver(
; CHECK: call {{.*}}i32 @argument_boundary(ptr %external, i32 %x)
; CHECK-LABEL: define internal{{.*}}i32 @argument_boundary(

define i32 @argument_driver(ptr %external, i32 %x) {
entry:
  %result = call i32 @argument_boundary(ptr %external, i32 %x)
  ret i32 %result
}

define internal i32 @argument_boundary(ptr %frame_base, i32 %value) #0 {
entry:
  %slot = getelementptr i8, ptr %frame_base, i64 -4
  store i32 %value, ptr %slot, align 4
  %result = load i32, ptr %slot, align 4
  ret i32 %result
}

; Absolute integer stack pointers may be merged before they are made relative
; to the same caller-local top.  The exact anchor cancels on every PHI edge.
;
; CHECK-LABEL: define i32 @affine_boundary_phi(
; CHECK-NOT: ptrtoint
; CHECK-NOT: alloca
; CHECK: ret i32 %value

define i32 @affine_boundary_phi(i1 %choose, i32 %value) {
entry:
  %frame = alloca [64 x i8], align 16
  %top = getelementptr i8, ptr %frame, i64 64
  %anchor = ptrtoint ptr %top to i64
  %left.absolute = add i64 %anchor, -16
  %right.absolute = add i64 %anchor, -24
  br i1 %choose, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %absolute = phi i64 [ %left.absolute, %left ],
                      [ %right.absolute, %right ]
  %relative = sub i64 %absolute, %anchor
  %slot = getelementptr i8, ptr %top, i64 %relative
  store i32 %value, ptr %slot, align 4
  %result = load i32, ptr %slot, align 4
  ret i32 %result
}

attributes #0 = { noinline "brighten.preserve.guest.boundary"="v1" }
