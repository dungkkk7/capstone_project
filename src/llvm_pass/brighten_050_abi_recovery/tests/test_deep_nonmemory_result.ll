; Exceeding the memory-token proof budget must preserve a call whose result
; eventually becomes an ordinary integer value.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

define ptr @sub_target(ptr %state, i64 %pc, ptr %memory) {
entry:
  %r = select i1 false, ptr %memory, ptr null
  ret ptr %r
}

; CHECK-LABEL: define internal void @sub_caller.native
; CHECK: call ptr @sub_target
define ptr @sub_caller(ptr %state, i64 %pc, ptr %memory) {
entry:
  %r = call ptr @sub_target(ptr %state, i64 %pc, ptr %memory)
  %s01 = select i1 true, ptr %r, ptr %r
  %s02 = select i1 true, ptr %s01, ptr %s01
  %s03 = select i1 true, ptr %s02, ptr %s02
  %s04 = select i1 true, ptr %s03, ptr %s03
  %s05 = select i1 true, ptr %s04, ptr %s04
  %s06 = select i1 true, ptr %s05, ptr %s05
  %s07 = select i1 true, ptr %s06, ptr %s06
  %s08 = select i1 true, ptr %s07, ptr %s07
  %s09 = select i1 true, ptr %s08, ptr %s08
  %s10 = select i1 true, ptr %s09, ptr %s09
  %s11 = select i1 true, ptr %s10, ptr %s10
  %s12 = select i1 true, ptr %s11, ptr %s11
  %s13 = select i1 true, ptr %s12, ptr %s12
  %s14 = select i1 true, ptr %s13, ptr %s13
  %s15 = select i1 true, ptr %s14, ptr %s14
  %s16 = select i1 true, ptr %s15, ptr %s15
  %s17 = select i1 true, ptr %s16, ptr %s16
  %s18 = select i1 true, ptr %s17, ptr %s17
  %i = ptrtoint ptr %s18 to i64
  %out = inttoptr i64 %i to ptr
  ret ptr %out
}
