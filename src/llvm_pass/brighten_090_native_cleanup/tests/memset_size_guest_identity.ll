; A scalar size can numerically fall inside a broad guest BSS mapping.  McSema
; then spells the integer as ptrtoint(data_<value>), but it remains a byte
; count at memset's third argument and must not be rebased to a host pointer.

@segment = internal global [32 x i8] zeroinitializer
@data_f426b0 = alias i8, ptr @segment
@dst = internal global [32 x i8] zeroinitializer

declare ptr @memset(ptr, i32, i64)

define void @clear() {
entry:
  call ptr @memset(ptr @dst, i32 0,
                   i64 ptrtoint (ptr @data_f426b0 to i64))
  ret void
}

; CHECK-LABEL: define void @clear()
; CHECK: call ptr @memset(ptr @dst, i32 0, i64 16000688)
; CHECK-NOT: ptrtoint (ptr @data_f426b0 to i64)
