; A recovered entry frame used to remain global because its top address was
; stored into externally-visible native_register_storage.  The register file
; is synthetic and becomes dead after native ABI recovery; internalizing it
; lets O3 remove that escape before final frame compaction.

%State = type [3376 x i8]

@__mcsema_reg_state = global %State zeroinitializer
@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16

define i32 @main() {
entry:
  store i64 ptrtoint (
      ptr getelementptr inbounds (
          i8, ptr @frame_storage_backing.main, i64 16711680) to i64),
      ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2312), align 8
  store i32 7, ptr getelementptr inbounds (
      i8, ptr @frame_storage_backing.main, i64 16711672), align 4
  %value = load i32, ptr getelementptr inbounds (
      i8, ptr @frame_storage_backing.main, i64 16711672), align 4
  ret i32 %value
}

; CHECK-NOT: @native_register_storage
; CHECK-NOT: @frame_storage_backing.main
; CHECK-LABEL: define {{.*}}i32 @main()
; CHECK: ret i32 7
