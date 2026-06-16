; CHECK: define {{.*}} @caller
; CHECK: call {{.*}} @sub_401000(
; CHECK-NOT: call {{.*}} @__remill_function_call(

%struct.State = type { i64 }
%struct.Memory = type opaque

declare %struct.Memory* @__remill_function_call(%struct.State*, i64, %struct.Memory*)

define internal %struct.Memory* @sub_401000(%struct.State* %s, i64 %pc, %struct.Memory* %m) {
entry:
  ret %struct.Memory* %m
}

define %struct.Memory* @caller(%struct.State* %s, %struct.Memory* %m) {
entry:
  %r = call %struct.Memory* @__remill_function_call(%struct.State* %s, i64 4198400, %struct.Memory* %m)
  ret %struct.Memory* %r
}
