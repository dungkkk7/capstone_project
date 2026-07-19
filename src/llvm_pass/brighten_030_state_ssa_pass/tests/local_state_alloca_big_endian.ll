; Big-endian interval extraction must address the high bits first.
target datalayout = "E-p:64:64"

%struct.State = type { [16 x i8] }

define i16 @promote_big_endian_overlap() {
entry:
  %state = alloca %struct.State, align 4
  store %struct.State zeroinitializer, ptr %state, align 4
  %wide = getelementptr i8, ptr %state, i64 0
  %middle = getelementptr i8, ptr %state, i64 1
  store i32 287454020, ptr %wide, align 4
  store i8 -86, ptr %middle, align 1
  %value = load i16, ptr %wide, align 2
  ret i16 %value
}

; CHECK-LABEL: define i16 @promote_big_endian_overlap()
; CHECK-NOT: alloca %struct.State
; CHECK-NOT: getelementptr i8
; CHECK: ret i16 4522
