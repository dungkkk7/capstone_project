; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

%seg_type = type <{ [3536 x i8], ptr }>

@seg_9dd0__init_array_10 = internal global %seg_type <{ [3536 x i8] zeroinitializer, ptr inttoptr (i64 4464 to ptr) }>

declare ptr @__remill_function_call(ptr, i64, ptr)

define internal ptr @sub_1170(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @caller(ptr %state, ptr %memory) {
entry:
  %target = load i64, ptr getelementptr inbounds nuw (i8, ptr @seg_9dd0__init_array_10, i64 3536), align 8
  %out = call ptr @__remill_function_call(ptr %state, i64 %target, ptr %memory)
  ret ptr %out
}

; CHECK-LABEL: define ptr @caller(ptr %state, ptr %memory) {
; CHECK-NOT: call ptr @__remill_function_call
; CHECK: %target = load i64, ptr getelementptr inbounds nuw (i8, ptr @seg_9dd0__init_array_10, i64 3536), align 8
; CHECK: call ptr @sub_1170(ptr %state, i64 4464, ptr %memory)
; CHECK: ret ptr
