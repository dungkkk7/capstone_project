; A lifted-origin block label is not itself a dispatcher or a guest ABI
; artifact.  Strict mode must judge the CFG structure, not a non-semantic
; basic-block name.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %inst_401000

inst_401000:
  ret i32 0
}
