; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

%seg_type = type <{ [3536 x i8], ptr }>

@seg_9dd0__init_array_10 = internal global %seg_type <{ [3536 x i8] zeroinitializer, ptr inttoptr (i64 4464 to ptr) }>

define ptr @__remill_function_call(ptr %state, i64 %pc, ptr %memory) {
entry:
  %is_target = icmp eq i64 %pc, 4464
  br i1 %is_target, label %case_sub_1170, label %common.ret

common.ret:
  %result = phi ptr [ %memory, %entry ], [ %call, %case_sub_1170 ]
  ret ptr %result

case_sub_1170:
  %call = call ptr @sub_1170(ptr %memory)
  br label %common.ret
}

define internal ptr @sub_1170(ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @caller(ptr %state, ptr %memory) {
entry:
  %target = load i64, ptr getelementptr inbounds nuw (i8, ptr @seg_9dd0__init_array_10, i64 3536), align 8
  %out = call ptr @__remill_function_call(ptr poison, i64 %target, ptr %memory)
  ret ptr %out
}

; CHECK-LABEL: define ptr @caller(ptr %state, ptr %memory) {
; CHECK-NOT: call ptr @__remill_function_call
; CHECK: %target = load i64, ptr getelementptr inbounds nuw (i8, ptr @seg_9dd0__init_array_10, i64 3536), align 8
; CHECK: call ptr @sub_1170(ptr %memory)
; CHECK: ret ptr %{{.*}}
