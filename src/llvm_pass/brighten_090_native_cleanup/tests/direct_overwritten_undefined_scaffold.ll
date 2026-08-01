; Direct insertvalue/insertelement chains are defined once every undefined
; top-level field or lane has been overwritten.
;
; CHECK-LABEL: define { i32, i32 } @build_pair(
; CHECK: insertvalue { i32, i32 } zeroinitializer, i32 %a, 0
; CHECK-NOT: poison
; CHECK-LABEL: define <2 x double> @build_vector(
; CHECK: insertelement <2 x double> zeroinitializer, double %a, i64 0
; CHECK-NOT: poison

define { i32, i32 } @build_pair(i32 %a, i32 %b) {
entry:
  %first = insertvalue { i32, i32 } poison, i32 %a, 0
  %second = insertvalue { i32, i32 } %first, i32 %b, 1
  ret { i32, i32 } %second
}

define <2 x double> @build_vector(double %a) {
entry:
  %value = insertelement <2 x double> <double poison, double 0.000000e+00>,
      double %a, i64 0
  ret <2 x double> %value
}
