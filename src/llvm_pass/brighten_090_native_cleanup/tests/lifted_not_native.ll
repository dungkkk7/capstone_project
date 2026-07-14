; The strict verifier must reject live lifted state and ABI artifacts.
target triple = "x86_64-pc-linux-gnu"

%struct.State = type { i64 }
@__mcsema_reg_state = internal global %struct.State zeroinitializer

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %field = getelementptr %struct.State, ptr @__mcsema_reg_state, i32 0, i32 0
  %value = load i64, ptr %field, align 8
  ret ptr %memory
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %memory = call ptr @sub_1000(ptr @__mcsema_reg_state, i64 4096, ptr null)
  ret i32 0
}
