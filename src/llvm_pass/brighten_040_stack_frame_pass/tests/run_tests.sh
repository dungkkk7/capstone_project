#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenStackFramePass.so"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
[[ -x "$OPT" && -f "$PLUGIN" ]]

# Positive: 030-certified RSP slot + constant affine local address + dominating
# initialization.  040 must replace the translated guest pointer with a local
# alloca without changing the value flow.
cat >"$WORK/positive.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
declare ptr @__translate_guest_pointer(i64, i1)
define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rsp.slot = alloca i64, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.init = load i64, ptr %rsp.ptr
  store i64 %rsp.init, ptr %rsp.slot
  %rsp = load i64, ptr %rsp.slot
  %addr = sub i64 %rsp, 16
  %guest = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
  store i64 42, ptr %guest
  %v = load i64, ptr %guest
  %rax = getelementptr i8, ptr %state, i64 2216
  store i64 %v, ptr %rax
  ret ptr %memory
}
!0 = !{i64 2312}
EOF
"$OPT" -load-pass-plugin="$PLUGIN" -passes='brighten-stack-frame-pass,verify' \
  -S "$WORK/positive.ll" -o "$WORK/positive.out.ll"
grep -q 'native_local_frame = alloca' "$WORK/positive.out.ll"
! grep -q '__translate_guest_pointer(i64 %addr' "$WORK/positive.out.ll"
grep -q 'store i64 42, ptr %frame_ptr' "$WORK/positive.out.ll"

# Refusal: a load before any dominating store can observe caller/persistent
# guest memory and therefore is not a local frame proof.
cat >"$WORK/read-first.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
declare ptr @__translate_guest_pointer(i64, i1)
define ptr @sub_2000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rsp.slot = alloca i64, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.init = load i64, ptr %rsp.ptr
  store i64 %rsp.init, ptr %rsp.slot
  %rsp = load i64, ptr %rsp.slot
  %addr = sub i64 %rsp, 8
  %guest = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
  %old = load i64, ptr %guest
  store i64 7, ptr %guest
  ret ptr %memory
}
!0 = !{i64 2312}
EOF
"$OPT" -load-pass-plugin="$PLUGIN" -passes='brighten-stack-frame-pass,verify' \
  -S "$WORK/read-first.ll" -o "$WORK/read-first.out.ll"
! grep -q 'native_local_frame' "$WORK/read-first.out.ll"
grep -q '__translate_guest_pointer' "$WORK/read-first.out.ll"

# Refusal: dynamic RSP-relative offset is not an object boundary proof.
cat >"$WORK/dynamic.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
declare ptr @__translate_guest_pointer(i64, i1)
define ptr @sub_3000(ptr %state, i64 %pc, ptr %memory, i64 %idx) {
entry:
  %rsp.slot = alloca i64, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.init = load i64, ptr %rsp.ptr
  store i64 %rsp.init, ptr %rsp.slot
  %rsp = load i64, ptr %rsp.slot
  %addr = sub i64 %rsp, %idx
  %guest = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
  store i64 7, ptr %guest
  ret ptr %memory
}
!0 = !{i64 2312}
EOF
"$OPT" -load-pass-plugin="$PLUGIN" -passes='brighten-stack-frame-pass,verify' \
  -S "$WORK/dynamic.ll" -o "$WORK/dynamic.out.ll"
! grep -q 'native_local_frame' "$WORK/dynamic.out.ll"

# Refusal: pointer escapes to an unknown call.  040 must not localize storage
# whose lifetime/alias behavior crosses an unmodelled boundary.
cat >"$WORK/escape.ll" <<'EOF'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
declare ptr @__translate_guest_pointer(i64, i1)
declare void @unknown(ptr)
define ptr @sub_4000(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rsp.slot = alloca i64, !brighten.state.offset !0
  %rsp.ptr = getelementptr i8, ptr %state, i64 2312
  %rsp.init = load i64, ptr %rsp.ptr
  store i64 %rsp.init, ptr %rsp.slot
  %rsp = load i64, ptr %rsp.slot
  %addr = sub i64 %rsp, 32
  %guest = call ptr @__translate_guest_pointer(i64 %addr, i1 true)
  store i64 1, ptr %guest
  call void @unknown(ptr %guest)
  ret ptr %memory
}
!0 = !{i64 2312}
EOF
"$OPT" -load-pass-plugin="$PLUGIN" -passes='brighten-stack-frame-pass,verify' \
  -S "$WORK/escape.ll" -o "$WORK/escape.out.ll"
! grep -q 'native_local_frame' "$WORK/escape.out.ll"

echo '040 affine stack-provenance tests: PASS'
