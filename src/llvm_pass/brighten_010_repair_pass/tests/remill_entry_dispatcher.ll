; CHECK-LABEL: define ptr @caller
; CHECK: call ptr @__lifter_refine_dispatch_sub_1000(ptr %s, i64 4660, ptr %m)
; CHECK: call ptr @sub_1000(ptr %s, i64 undef, ptr %m)
; CHECK-LABEL: define dso_local ptr @__lifter_refine_dispatch_sub_1000
; CHECK: refine.remill.dispatch:
; CHECK: switch i64 %pc, label %inst_1000 [
; CHECK: i64 4660, label %inst_1234
; CHECK: %x = phi i64 [ 7, %middle ], [ %pc, %refine.remill.dispatch ]
; CHECK: %p = phi ptr [ %m, %middle ], [ %m, %refine.remill.dispatch ]
; CHECK: %base.refine.entry = phi i64 [ %pc, %refine.remill.dispatch ], [ %base, %middle ]
; CHECK: %y = add i64 %base.refine.entry, 2
; CHECK-NOT: call {{.*}} @__remill_function_call(

%struct.State = type { i64 }
%struct.Memory = type opaque

declare %struct.Memory* @__remill_function_call(%struct.State*, i64, %struct.Memory*)

define internal %struct.Memory* @sub_1000(%struct.State* %s, i64 %pc, %struct.Memory* %m) {
inst_1000:
  br label %middle

middle:
  %base = add i64 %pc, 1
  br label %inst_1234

inst_1234:
  %x = phi i64 [ 7, %middle ]
  %p = phi %struct.Memory* [ %m, %middle ]
  %y = add i64 %base, 2
  ret %struct.Memory* %p
}

define %struct.Memory* @caller(%struct.State* %s, %struct.Memory* %m) {
entry:
  %r = call %struct.Memory* @__remill_function_call(%struct.State* %s, i64 4660, %struct.Memory* %m)
  %direct = call %struct.Memory* @sub_1000(%struct.State* %s, i64 undef, %struct.Memory* %m)
  ret %struct.Memory* %r
}
