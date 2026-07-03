#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLVM_BIN_DIR="${LLVM_BIN_DIR:-/home/dungbv/WorkSpace/lifter/third_party/lifting-bits-downloads/vcpkg_ubuntu-20.04_llvm-11_amd64/installed/x64-linux-rel/tools/llvm}"
OPT_BIN="${OPT_BIN:-$LLVM_BIN_DIR/opt}"
FILECHECK_BIN="${FILECHECK_BIN:-$LLVM_BIN_DIR/FileCheck}"
PLUGIN="${PLUGIN:-$ROOT/build/RefineSemanticPass.so}"

if [[ ! -x "$OPT_BIN" ]]; then
  echo "ERROR: opt not found at $OPT_BIN" >&2
  exit 1
fi
if [[ ! -x "$FILECHECK_BIN" ]]; then
  echo "ERROR: FileCheck not found at $FILECHECK_BIN" >&2
  exit 1
fi
if [[ ! -f "$PLUGIN" ]]; then
  echo "ERROR: plugin not found at $PLUGIN" >&2
  exit 1
fi

run_one() {
  local test_file="$1"
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=refine-semantic-pass,verify -S "$test_file" -o - \
    | "$FILECHECK_BIN" "$test_file"
}

run_one "$ROOT/tests/ub_flags.ll"
run_one "$ROOT/tests/ub_flags_constexpr.ll"
run_one "$ROOT/tests/ub_attrs.ll"
run_one "$ROOT/tests/grow_mcsema_stack.ll"
run_one "$ROOT/tests/remill_x87_sqrtl_wrapper.ll"
run_one "$ROOT/tests/mcsema_x87_pseudo_double_load.ll"
run_one "$ROOT/tests/remill_call_resolve.ll"
run_one "$ROOT/tests/remill_entry_dispatcher.ll"
run_one "$ROOT/tests/remill_missing_main.ll"
run_one "$ROOT/tests/remill_missing_main_owner_fallback.ll"
run_one "$ROOT/tests/remill_missing_main_auto_sub.ll"
run_one "$ROOT/tests/remill_call_unresolved.ll"
run_one "$ROOT/tests/remill_control_helper_definitions.ll"
run_one "$ROOT/tests/remill_unused_helper_prune.ll"
run_one "$ROOT/tests/remill_vararg_fp_printf.ll"
run_one "$ROOT/tests/mcsema_raw_indirect_call_stack.ll"
run_one "$ROOT/tests/recover_noreturn_fallthrough.ll"
run_one "$ROOT/tests/recover_noreturn_duplicate_switch_edge.ll"
run_one "$ROOT/tests/recover_noreturn_phi_incoming_dominance.ll"
run_one "$ROOT/tests/normalize_jump_table_targets.ll"
run_one "$ROOT/tests/raw_indirect_call_guard.ll"
run_one "$ROOT/tests/raw_indirect_call_no_dispatcher.ll"
run_one "$ROOT/tests/mcsema_flag_load_forward.ll"
run_one "$ROOT/tests/mcsema_dead_flag_stores.ll"
run_one "$ROOT/tests/mcsema_dead_rip_stores.ll"
run_one "$ROOT/tests/mcsema_state_load_forward.ll"
run_one "$ROOT/tests/mcsema_guest_stack_forward.ll"
run_one "$ROOT/tests/mcsema_unused_state_stores.ll"
run_one "$ROOT/tests/mcsema_ext_wrapper_inline_attrs.ll"

echo "All refine_semantic_pass tests passed."
