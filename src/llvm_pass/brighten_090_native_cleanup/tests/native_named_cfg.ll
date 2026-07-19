; Recovered block names are diagnostic labels, not evidence of flattening.
; This ordinary branch diamond must satisfy the strict native contract even
; though every body block retains its lifted address name.

define i32 @main(i32 %argc, ptr %argv) {
inst_1000:
  %test = icmp eq i32 %argc, 1
  br i1 %test, label %inst_1010, label %inst_1020

inst_1010:
  br label %inst_1030

inst_1020:
  br label %inst_1030

inst_1030:
  %result = phi i32 [ 7, %inst_1010 ], [ 9, %inst_1020 ]
  ret i32 %result
}
