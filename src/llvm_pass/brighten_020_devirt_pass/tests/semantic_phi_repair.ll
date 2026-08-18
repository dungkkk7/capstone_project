; When several proven states target one case, the old hub PHI incoming must be
; expanded to the new predecessor edges.  Constant values are available on all
; such edges, so this rewrite is exact.

define i32 @phi_repair(i1 %choose) {
entry:
  br i1 %choose, label %left, label %right

left:
  br label %hub

right:
  br label %hub

hub:
  %state = phi i32 [ 1, %left ], [ 2, %right ]
  switch i32 %state, label %fallback [
    i32 1, label %case
    i32 2, label %case
  ]

case:
  %value = phi i32 [ 7, %hub ]
  ret i32 %value

fallback:
  ret i32 0
}

; CHECK-LABEL: define i32 @phi_repair(
; CHECK: left:
; CHECK: br label %case
; CHECK: right:
; CHECK: br label %case
; CHECK: case:
; CHECK: %value = phi i32 [ 7, %left ], [ 7, %right ]
; CHECK-NOT: hub:
; CHECK-NOT: switch i32
