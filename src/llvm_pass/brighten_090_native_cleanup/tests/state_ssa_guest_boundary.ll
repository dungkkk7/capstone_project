target triple = "x86_64-pc-linux-gnu"

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
@boundary_sink = external global i64

; STATE-PIN-LABEL: define internal {{.*}} @sub_boundary(
; STATE-PIN-SAME: #[[PINNED:[0-9]+]]
; STATE-PIN: attributes #[[PINNED]] = { noinline "brighten.preserve.guest.boundary"="v1" }
; STATE-PLAIN-LABEL: define internal {{.*}} @sub_unpinned(
; STATE-PLAIN-SAME: {
; STATE-DEFAULT-LABEL: define internal {{.*}} @sub_boundary(
; STATE-DEFAULT-SAME: {

; O3-LABEL: define{{.*}}i32 @main(
; O3: call{{.*}}@sub_boundary
; O3-LABEL: define internal {{.*}} @sub_boundary(
; O3-SAME: #[[O3_PINNED:[0-9]+]]
; O3: attributes #[[O3_PINNED]] = { {{.*}}noinline{{.*}}"brighten.preserve.guest.boundary"="v1"{{.*}} }

define internal i64 @sub_boundary.native(ptr %state, i64 %arg_RDI) noinline "brighten.preserve.guest.boundary"="v1" {
entry:
  %slot = getelementptr i8, ptr %state, i64 2216
  %old = load i64, ptr %slot
  %next = add i64 %old, %arg_RDI
  store i64 %next, ptr %slot
  store volatile i64 %next, ptr @boundary_sink, align 8
  ret i64 %next
}

define internal i64 @sub_unpinned.native(ptr %state, i64 %arg_RDI) {
entry:
  %slot = getelementptr i8, ptr %state, i64 2224
  %old = load i64, ptr %slot
  %next = add i64 %old, %arg_RDI
  store i64 %next, ptr %slot
  ret i64 %next
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %state = alloca [3376 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %state, i8 0, i64 3376, i1 false)
  %ret = call i64 @sub_boundary.native(ptr %state, i64 7)
  %plain = call i64 @sub_unpinned.native(ptr %state, i64 3)
  %sum = add i64 %ret, %plain
  %out = trunc i64 %sum to i32
  ret i32 %out
}
