; CHECK-NOT: noalias
; CHECK-NOT: nonnull
; CHECK-NOT: noundef
; CHECK-NOT: dereferenceable

%struct.State = type { i64 }
%struct.Memory = type opaque

define internal noalias nonnull ptr @sub_1000(ptr noalias nonnull align 1 %s, i64 noundef %pc, ptr noalias nonnull align 1 %m) {
entry:
  ret ptr %m
}

define ptr @caller(ptr %s, ptr %m) {
entry:
  %r = call noalias nonnull ptr @sub_1000(ptr noalias nonnull align 1 %s, i64 noundef 4096, ptr noalias nonnull align 1 %m)
  ret ptr %r
}
