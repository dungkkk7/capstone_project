; A direct libc scanf("%d", int *) call can be represented by a typed
; call-through boundary.  The wrapper still delegates all parsing, EOF,
; errno, locale and memory effects to libc.

@fmt = private constant [6 x i8] c"xx\00%d\00"
@fmt_ld = private constant [4 x i8] c"%ld\00"
@fmt_n = private constant [3 x i8] c"%n\00"
@fmt_suppressed = private constant [4 x i8] c"%*d\00"
@fmt_multiple = private constant [5 x i8] c"%d%d\00"

declare i32 @scanf(ptr, ...)

; CHECK-LABEL: define i32 @positive(ptr %dst)
; CHECK: call i32 @__brighten_scanf_i32_1(ptr getelementptr inbounds (i8, ptr @fmt, i64 3), ptr %dst), !brighten.scanf.destination ![[CONTRACT:[0-9]+]]
; CHECK-LABEL: define i32 @dynamic(ptr %format, ptr %dst)
; CHECK: call i32 (ptr, ...) @scanf(ptr %format, ptr %dst){{$}}
; CHECK-LABEL: define i32 @long(ptr %dst)
; CHECK: call i32 (ptr, ...) @scanf(ptr @fmt_ld, ptr %dst){{$}}
; CHECK-LABEL: define i32 @count(ptr %dst)
; CHECK: call i32 (ptr, ...) @scanf(ptr @fmt_n, ptr %dst){{$}}
; CHECK-LABEL: define i32 @suppressed(ptr %dst)
; CHECK: call i32 (ptr, ...) @scanf(ptr @fmt_suppressed, ptr %dst){{$}}
; CHECK-LABEL: define i32 @multiple(ptr %a, ptr %b)
; CHECK: call i32 (ptr, ...) @scanf(ptr @fmt_multiple, ptr %a, ptr %b){{$}}
; CHECK-LABEL: define i32 @missing()
; CHECK: call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 3)){{$}}
; CHECK-LABEL: define i32 @extra(ptr %a, ptr %b)
; CHECK: call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 3), ptr %a, ptr %b){{$}}
; CHECK-LABEL: define internal i32 @__brighten_scanf_i32_1(ptr %{{.*}}, ptr %{{.*}})
; CHECK-NOT: nocapture
; CHECK-NOT: readonly
; CHECK-NOT: writeonly
; CHECK-NOT: argmemonly
; CHECK: call i32 (ptr, ...) @scanf(ptr %{{.*}}, ptr %{{.*}}), !brighten.scanf.destination ![[WRAPPER_CONTRACT:[0-9]+]]
; CHECK: ![[CONTRACT]] = !{i32 1, i32 1, i64 4, i1 true}

; O3-LABEL: define{{.*}}i32 @positive(ptr %dst)
; O3: @scanf(ptr{{.*}}@fmt{{.*}}, ptr %dst), !brighten.scanf.destination ![[O3_CONTRACT:[0-9]+]]
; O3-LABEL: define{{.*}}i32 @dynamic(
; O3-NOT: !brighten.scanf.destination
; O3-LABEL: define{{.*}}i32 @long(
; O3: ![[O3_CONTRACT]] = !{i32 1, i32 1, i64 4, i1 true}

define i32 @positive(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 3), ptr %dst)
  ret i32 %r
}

define i32 @dynamic(ptr %format, ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr %format, ptr %dst)
  ret i32 %r
}

define i32 @long(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @fmt_ld, ptr %dst)
  ret i32 %r
}

define i32 @count(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @fmt_n, ptr %dst)
  ret i32 %r
}

define i32 @suppressed(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @fmt_suppressed, ptr %dst)
  ret i32 %r
}

define i32 @multiple(ptr %a, ptr %b) {
  %r = call i32 (ptr, ...) @scanf(ptr @fmt_multiple, ptr %a, ptr %b)
  ret i32 %r
}

define i32 @missing() {
  %r = call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 3))
  ret i32 %r
}

define i32 @extra(ptr %a, ptr %b) {
  %r = call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 3), ptr %a, ptr %b)
  ret i32 %r
}
