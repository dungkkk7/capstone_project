; Lane one remains observable and undefined. Cleanup must diagnose it rather
; than select an arbitrary value.
target triple = "x86_64-pc-linux-gnu"

define <2 x i32> @partial(i32 %x) {
entry:
  %base = freeze <2 x i32> poison
  %partial = insertelement <2 x i32> %base, i32 %x, i32 0
  ret <2 x i32> %partial
}

define double @observed_shuffle_lane(<2 x double> %input) {
entry:
  %shift = shufflevector <2 x double> %input, <2 x double> poison,
                           <2 x i32> <i32 1, i32 poison>
  %observed = extractelement <2 x double> %shift, i32 1
  ret double %observed
}
