; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

@seg_1000__init_1b = internal constant [65536 x i8] zeroinitializer
@seg_2000__data = internal global [32 x i8] zeroinitializer
@data_2008 = internal alias i8, getelementptr inbounds ([32 x i8], ptr @seg_2000__data, i64 0, i64 8)
; CHECK: @seg_3000__ptrs = internal global { ptr, ptr } { ptr inttoptr (i64 8200 to ptr), ptr inttoptr (i64 20480 to ptr) }
@seg_3000__ptrs = internal global { ptr, ptr } { ptr @data_2008, ptr @puts }

declare i32 @puts(ptr)
declare ptr @__remill_function_call(ptr, i64, ptr)

define internal ptr @ext_5000_puts(ptr %state, i64 %pc, ptr %memory) {
  ret ptr %memory
}

; CHECK-LABEL: @__remill_function_call
; CHECK: i64 20480, label %case_ext_5000_puts

define i32 @guest_immediate_i32(i32 %x) {
; CHECK-LABEL: @guest_immediate_i32
; CHECK: xor i32 %x, 21930
entry:
  %r = xor i32 %x, ptrtoint (ptr getelementptr inbounds (i8, ptr @seg_1000__init_1b, i64 17834) to i32)
  ret i32 %r
}

define i64 @guest_immediate_expr() {
; CHECK-LABEL: @guest_immediate_expr
; CHECK: ret i64 4503
entry:
  ret i64 add (i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @seg_1000__init_1b, i64 381) to i64), i64 26)
}

define i8 @guest_load_keeps_native_pointer() {
; CHECK-LABEL: @guest_load_keeps_native_pointer
; CHECK: load i8, ptr {{getelementptr|@data_2008}}
entry:
  %v = load i8, ptr @data_2008
  ret i8 %v
}
