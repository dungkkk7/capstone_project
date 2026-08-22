; CHECK: define {{.*}} @caller
; CHECK: call {{.*}} @__lifter_refine_noop_call(
; CHECK-NOT: call {{.*}} @__remill_function_call(

%struct.State = type { i64 }
%struct.Memory = type opaque

declare %struct.Memory* @__remill_function_call(%struct.State*, i64, %struct.Memory*)

define %struct.Memory* @caller(%struct.State* %s, %struct.Memory* %m) {
entry:
  %r = call %struct.Memory* @__remill_function_call(%struct.State* %s, i64 12345, %struct.Memory* %m)
  ret %struct.Memory* %r
}
