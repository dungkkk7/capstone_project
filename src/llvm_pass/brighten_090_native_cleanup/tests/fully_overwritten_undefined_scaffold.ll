; Every undefined element is overwritten before the aggregate/vector escapes.
; Cleanup may concretize only the unobservable construction scaffold.
target triple = "x86_64-pc-linux-gnu"

define { i64, i8 } @build_struct(i64 %x, i8 %flag) {
entry:
  %base = freeze { i64, i8 } poison
  %with.x = insertvalue { i64, i8 } %base, i64 %x, 0
  %complete = insertvalue { i64, i8 } %with.x, i8 %flag, 1
  ret { i64, i8 } %complete
}

define <2 x i32> @build_vector(i32 %x, i32 %y) {
entry:
  %base = freeze <2 x i32> <i32 17, i32 poison>
  %complete = insertelement <2 x i32> %base, i32 %y, i32 1
  ret <2 x i32> %complete
}

define double @dead_shuffle_lane(<2 x double> %input) {
entry:
  %shift = shufflevector <2 x double> %input, <2 x double> poison,
                           <2 x i32> <i32 1, i32 poison>
  %product = fmul <2 x double> %shift, %input
  %observed = extractelement <2 x double> %product, i32 0
  ret double %observed
}
