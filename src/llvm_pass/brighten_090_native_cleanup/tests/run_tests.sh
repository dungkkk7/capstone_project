#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenNativeCleanupPass.so"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
[[ -x "$OPT" && -f "$PLUGIN" ]]

cat >"$WORK/native.ll" <<'EOF'
define i32 @main() {
entry:
  ret i32 0
}
EOF
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$WORK/native.ll" -o "$WORK/native.out.ll"

cat >"$WORK/dead-residual.ll" <<'EOF'
@RAX_2216 = internal global i64 0
declare ptr @__remill_jump(ptr, i64, ptr)
define internal ptr @sub_401000(ptr %state, i64 %pc, ptr %mem) {
entry:
  ret ptr %mem
}
define i32 @main() {
entry:
  ret i32 0
}
EOF
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$WORK/dead-residual.ll" -o "$WORK/dead.out.ll"
if grep -Eq '__remill_|RAX_2216|define internal ptr @sub_401000' "$WORK/dead.out.ll"; then
  echo 'FAIL: 090 did not delete dead lifted residuals' >&2
  exit 1
fi

cat >"$WORK/live-residual.ll" <<'EOF'
declare ptr @__remill_jump(ptr, i64, ptr)
define i32 @main() {
entry:
  %m = call ptr @__remill_jump(ptr null, i64 4198400, ptr null)
  %ok = icmp ne ptr %m, null
  %r = zext i1 %ok to i32
  ret i32 %r
}
EOF
# Non-strict cleanup may not invent semantics for a live dispatcher.
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$WORK/live-residual.ll" -o "$WORK/live.out.ll"
grep -q '__remill_jump' "$WORK/live.out.ll"
# The final clean contract must reject exactly that residual.
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes='brighten-native-cleanup-final-pass,verify' -disable-output \
    "$WORK/live-residual.ll" >"$WORK/strict.stdout" 2>"$WORK/strict.stderr"; then
  echo 'FAIL: 090 strict mode accepted live lifted semantics' >&2
  exit 1
fi
grep -q 'strict clean contract failed' "$WORK/strict.stderr"

echo '090 narrow native cleanup tests: PASS'
