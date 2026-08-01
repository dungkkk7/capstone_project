; A recovered stack slot can remain a constant-expression GEP after O3.
; It is still a single, proven dispatcher-state location and must be promoted
; just like an instruction GEP.
;
; CHECK-LABEL: define i32 @main(
; CHECK: %native.dispatch.state = phi i32
; CHECK: switch i32 %native.dispatch.state

@frame_storage_backing.main = internal global [256 x i8] zeroinitializer,
    align 16

define i32 @main() {
entry:
  store i32 11,
      ptr getelementptr inbounds ([256 x i8],
                                  ptr @frame_storage_backing.main,
                                  i64 0, i64 240),
      align 4
  br label %dispatch

dispatch:
  %state = load i32,
      ptr getelementptr inbounds ([256 x i8],
                                  ptr @frame_storage_backing.main,
                                  i64 0, i64 240),
      align 4
  switch i32 %state, label %done [
    i32 11, label %case.first
    i32 22, label %case.second
  ]

case.first:
  store i32 22,
      ptr getelementptr inbounds ([256 x i8],
                                  ptr @frame_storage_backing.main,
                                  i64 0, i64 240),
      align 4
  br label %latch

case.second:
  store i32 11,
      ptr getelementptr inbounds ([256 x i8],
                                  ptr @frame_storage_backing.main,
                                  i64 0, i64 240),
      align 4
  br label %latch

latch:
  br label %dispatch

done:
  ret i32 0
}
