import subprocess
import os
import sys
import re
import tempfile

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
PASS_DIR = os.path.dirname(TESTS_DIR)
BUILD_DIR = os.path.join(PASS_DIR, "build")
PLUGIN_PATH = os.path.join(BUILD_DIR, "BrightenTypeReconstructionPass.so")
POST_STATE_PLUGIN = os.path.join(
    os.path.dirname(PASS_DIR), "brighten_040_stack_frame_pass", "build",
    "BrightenStackFramePass.so")
EXTERN_BRIDGE_PLUGIN = os.path.join(
    os.path.dirname(PASS_DIR), "brighten_060_extern_call_bridge", "build",
    "BrightenExternCallBridgePass.so")
NATIVE_CLEANUP_PLUGIN = os.path.join(
    os.path.dirname(PASS_DIR), "brighten_090_native_cleanup", "build",
    "BrightenNativeCleanupPass.so")

OPT_BIN = "opt-21"
FILECHECK_BIN = "FileCheck-21"

test_cases = {}

# 5. Struct containing array
test_cases["test_struct_containing_array.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_struct_arr.obj = type { double, [2 x i32] }

define void @test_struct_arr() {
entry:
  %obj = alloca [16 x i8], align 8

  %p0 = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store double 2.5, ptr %p0, align 8

  %p8 = getelementptr [16 x i8], ptr %obj, i64 0, i64 8
  store i32 12, ptr %p8, align 4

  %p12 = getelementptr [16 x i8], ptr %obj, i64 0, i64 12
  store i32 34, ptr %p12, align 4

  ret void
}
"""

# 6. Array of structs
test_cases["test_array_of_structs.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_arr_structs.obj.elem = type { i32, [4 x i8], double }

define void @test_arr_structs(i64 %idx) {
entry:
  %obj = alloca [48 x i8], align 8
  %off = shl i64 %idx, 4

  %p0 = getelementptr [48 x i8], ptr %obj, i64 0, i64 %off
  store i32 100, ptr %p0, align 4

  %off8 = add i64 %off, 8
  %p8 = getelementptr [48 x i8], ptr %obj, i64 0, i64 %off8
  store double 2.5, ptr %p8, align 8

  ret void
}
"""

# 7. Nested struct / Flat equivalent
test_cases["test_nested_struct.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_nested.obj = type { i32, [4 x i8], i64, i32, [4 x i8] }

define void @test_nested() {
entry:
  %obj = alloca [24 x i8], align 8

  %p0 = getelementptr [24 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p0, align 4

  %p8 = getelementptr [24 x i8], ptr %obj, i64 0, i64 8
  store i64 200, ptr %p8, align 8

  %p16 = getelementptr [24 x i8], ptr %obj, i64 0, i64 16
  store i32 300, ptr %p16, align 4

  ret void
}
"""

# 8. Tail padding
test_cases["test_tail_padding.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_tail_pad.obj = type { i32, [12 x i8] }

define void @test_tail_pad() {
entry:
  %obj = alloca [16 x i8], align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 4
  ret void
}
"""

# 9. Partial reconstruction
test_cases["test_partial_reconstruction.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_partial.obj = type { i32, [12 x i8] }

define void @test_partial() {
entry:
  %obj = alloca [16 x i8], align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 4
  ret void
}
"""

# 10. Global constant byte array reconstruction & 11. LE target
test_cases["test_global_constant_byte_array.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @my_global = internal global [2 x i32] [i32 67305985, i32 134678021], !brighten.guest.range ![[RANGE:[0-9]+]]
; CHECK: ![[RANGE]] = !{i64 4096, i64 4104}

@my_global = internal global [8 x i8] c"\\01\\02\\03\\04\\05\\06\\07\\08",
  !brighten.guest.range !0

define void @test_global() {
entry:
  %p0 = getelementptr [8 x i8], ptr @my_global, i64 0, i64 0
  %v0 = load i32, ptr %p0, align 4

  %p4 = getelementptr [8 x i8], ptr @my_global, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4

  ret void
}

!0 = !{i64 4096, i64 4104}
"""

# 13. Externally visible global (overlay-only, do not change storage type)
test_cases["test_externally_visible_global.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @my_ext_global = global [8 x i8]

@my_ext_global = global [8 x i8] c"\\01\\02\\03\\04\\05\\06\\07\\08"

define void @test_ext_global() {
entry:
  ; CHECK: getelementptr (%brighten.struct.global.my_ext_global, ptr @my_ext_global, i32 0, i32 1)
  %p4 = getelementptr [8 x i8], ptr @my_ext_global, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4
  ret void
}
"""

# 14. Pointer field & 15. Float field
test_cases["test_pointer_float_fields.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_ptr_flt.obj = type { float, [4 x i8], ptr }

define void @test_ptr_flt(ptr %arg) {
entry:
  %obj = alloca [16 x i8], align 8

  %p0 = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store float 1.5, ptr %p0, align 4

  %p8 = getelementptr [16 x i8], ptr %obj, i64 0, i64 8
  store ptr %arg, ptr %p8, align 8

  ret void
}
"""

# 16. Conflict: integer and float same interval
test_cases["test_conflict_int_float.ll"] = """
; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -brighten-type-mode=conservative -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_conflict() {
entry:
  ; CHECK: %obj = alloca [8 x i8]
  %obj = alloca [8 x i8], align 4

  %p0 = getelementptr [8 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p0, align 4

  ; Store float at the exact same offset -> conflict!
  store float 2.5, ptr %p0, align 4

  ret void
}
"""

# 17. Overlapping fields
test_cases["test_overlapping_fields.ll"] = """
; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -brighten-type-mode=conservative -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_overlap() {
entry:
  ; CHECK: %obj = alloca [8 x i8]
  %obj = alloca [8 x i8], align 4

  %p0 = getelementptr [8 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p0, align 4

  ; Overlapping access at offset 2 of size 4
  %p2 = getelementptr [8 x i8], ptr %obj, i64 0, i64 2
  store i32 200, ptr %p2, align 4

  ret void
}
"""

# 18. Unknown dynamic offset
test_cases["test_unknown_dynamic_offset.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_unknown_dyn(i64 %idx) {
entry:
  ; CHECK: %obj = alloca [64 x i8]
  ; CHECK-NOT: brighten.gep
  %obj = alloca [64 x i8], align 4

  ; Non-affine offset: the shift amount is itself dynamic.
  %shift = shl i64 %idx, %idx
  %p = getelementptr [64 x i8], ptr %obj, i64 0, i64 %shift
  store i32 100, ptr %p, align 4

  ret void
}
"""

# 19. Escaped alloca
test_cases["test_escaped_alloca.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @unknown_external_call(ptr)

define void @test_escape() {
entry:
  ; CHECK: %obj = alloca [16 x i8]
  %obj = alloca [16 x i8], align 8

  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 4

  ; Pass pointer to unknown function -> escaped!
  call void @unknown_external_call(ptr %obj)

  ret void
}
"""

# 20. Volatile load/store
test_cases["test_volatile_load_store.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_volatile() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_volatile.obj
  %obj = alloca [16 x i8], align 8

  ; CHECK: store volatile i32 100
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store volatile i32 100, ptr %p, align 4

  ret void
}
"""

# 21. Atomic load/store
test_cases["test_atomic_load_store.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_atomic() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_atomic.obj
  %obj = alloca [16 x i8], align 8

  ; CHECK: store atomic i32 100, ptr {{%brighten.gep.*}} release, align 4
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store atomic i32 100, ptr %p release, align 4

  ret void
}
"""

# 22. memcpy/memset
test_cases["test_memcpy_memset.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define void @test_memcpy(ptr %src) {
entry:
  ; CHECK: %obj = alloca [16 x i8]
  ; CHECK-NOT: %brighten.struct.stack.test_memcpy.obj
  %obj = alloca [16 x i8], align 8

  ; CHECK: call void @llvm.memcpy
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  call void @llvm.memcpy.p0.p0.i64(ptr %p, ptr %src, i64 16, i1 false)

  ret void
}
"""

# 23. Misaligned access
test_cases["test_misaligned_access.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_misaligned() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_misaligned.obj
  %obj = alloca [16 x i8], align 8

  ; CHECK: store i32 100, ptr {{%brighten.gep.*}}, align 1
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 1

  ret void
}
"""

# 24. Address space
test_cases["test_address_space.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_addrspace() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_addrspace.obj, align 8, addrspace(3)
  %obj = alloca [16 x i8], align 8, addrspace(3)

  ; CHECK: store i32 100
  %p = getelementptr [16 x i8], ptr addrspace(3) %obj, i64 0, i64 0
  store i32 100, ptr addrspace(3) %p, align 4

  ret void
}
"""

# 27. Idempotence & 28. Determinism
test_cases["test_idempotence.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_idempotent.obj = type { i32, [12 x i8] }

define void @test_idempotent() {
entry:
  %obj = alloca [16 x i8], align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 4
  ret void
}
"""

# 29. Negative no-change
test_cases["test_negative_no_change.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_no_evidence() {
entry:
  ; CHECK: %obj = alloca [16 x i8]
  %obj = alloca [16 x i8], align 8
  ret void
}
"""

# 30. An outer alloca count is part of the allocation semantics.  The current
# reconstruction plan models one object only, so multi/dynamic counts must be
# preserved instead of being silently shrunk to one inferred object.
test_cases["test_alloca_array_count.ll"] = """
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @dynamic_count(i64 %count) {
entry:
  ; CHECK: %obj = alloca [16 x i8], i64 %count, align 8
  ; CHECK-NOT: brighten.stack
  %obj = alloca [16 x i8], i64 %count, align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 1, i64 0
  store i32 42, ptr %p, align 4
  ret void
}

define void @constant_multi_count() {
entry:
  ; CHECK: %obj = alloca [16 x i8], i64 3, align 8
  %obj = alloca [16 x i8], i64 3, align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 2, i64 0
  store i32 7, ptr %p, align 4
  ret void
}
"""

# 31. Initializer reconstruction must not truncate integers wider than 64 bits.
test_cases["test_wide_integer_initializer.ll"] = r"""
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.global.wide = type { i128 }
; CHECK: @wide = internal global %brighten.struct.global.wide { i128 21345817372864405881847059188222722561 }
@wide = internal global [16 x i8] c"\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10"

define i128 @read_wide() {
entry:
  %p = getelementptr [16 x i8], ptr @wide, i64 0, i64 0
  %v = load i128, ptr %p, align 16
  ret i128 %v
}
"""

# 32. Byte snapshots follow the module DataLayout, not host endianness.
test_cases["test_big_endian_initializer.ll"] = r"""
target datalayout = "E-m:e-p:64:64-i64:64-n32:64-S128"
target triple = "powerpc64-unknown-linux-gnu"

; CHECK: @big = internal global [2 x i32] [i32 16909060, i32 84281096]
@big = internal global [8 x i8] c"\01\02\03\04\05\06\07\08"

define i32 @read_big() {
entry:
  %p0 = getelementptr [8 x i8], ptr @big, i64 0, i64 0
  %v0 = load i32, ptr %p0, align 4
  %p4 = getelementptr [8 x i8], ptr @big, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4
  %sum = add i32 %v0, %v4
  ret i32 %sum
}
"""

# 33. A non-zero raw pointer bit-pattern without relocation provenance is not
# null.  Reject retyping rather than inventing a null pointer initializer.
test_cases["test_unresolved_pointer_initializer.ll"] = r"""
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @raw_pointer = internal global [8 x i8] c"\01\00\00\00\00\00\00\00"
; CHECK-NOT: brighten.struct.global.raw_pointer
@raw_pointer = internal global [8 x i8] c"\01\00\00\00\00\00\00\00"

define ptr @read_raw_pointer() {
entry:
  %p = getelementptr [8 x i8], ptr @raw_pointer, i64 0, i64 0
  %v = load ptr, ptr %p, align 8
  ret ptr %v
}
"""

# 34. An externally_initialized global may be modified before this module's
# code observes it.  Its initializer is not a complete runtime byte fact, so
# do not rebuild/retype storage from it; overlay-only GEP cleanup is still OK.
test_cases["test_externally_initialized_global.ll"] = r"""
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @late_init = internal externally_initialized global [8 x i8] c"\01\02\03\04\05\06\07\08"
; CHECK-NOT: @late_init = internal externally_initialized global [2 x i32]
@late_init = internal externally_initialized global [8 x i8] c"\01\02\03\04\05\06\07\08"

define i32 @read_late_init() {
entry:
  ; CHECK: getelementptr (%brighten.struct.global.late_init, ptr @late_init, i32 0, i32 1)
  %p4 = getelementptr [8 x i8], ptr @late_init, i64 0, i64 4
  %v = load i32, ptr %p4, align 4
  ret i32 %v
}
"""

# Pointer provenance recovery uses standalone fixtures because these cases are
# easier to audit as complete late-IR snippets than as embedded Python strings.
for extra_test in (
    "test_native_pointer_affine_malloc.ll",
    "test_native_pointer_slot_roundtrip.ll",
    "test_native_pointer_provenance_negative.ll",
    "test_native_pointer_slot_capture_negative.ll",
    "test_native_pointer_direct_safety_negative.ll",
    "test_same_anchor_ptrint_affine.ll",
    "test_heap_proven_resolver_collapse.ll",
    "test_heap_proven_resolver_lifecycle.ll",
):
    with open(os.path.join(TESTS_DIR, extra_test), "r") as extra_file:
        test_cases[extra_test] = extra_file.read()

failed = 0
passed = 0

for name, content in test_cases.items():
    path = os.path.join(TESTS_DIR, name)
    with open(path, "w") as f:
        f.write(content.strip() + "\n")

    print(f"Running test: {name} ...", end=" ")
    sys.stdout.flush()

    pipeline = "brighten-type-reconstruct"
    if name == "test_same_anchor_ptrint_affine.ll":
        pipeline = "brighten-address-canonicalize,verify"
    if name == "test_heap_proven_resolver_collapse.ll":
        pipeline = "brighten-heap-proven-resolver-collapse,verify"
    if name == "test_heap_proven_resolver_lifecycle.ll":
        pipeline = (
            "brighten-extern-call-bridge,"
            "brighten-post-state-frame-pass,"
            "brighten-heap-proven-resolver-collapse,verify"
        )
    opt_cmd = [OPT_BIN, "-load-pass-plugin", PLUGIN_PATH, f"-passes={pipeline}", "-verify-each", "-S", path, "-o", "-"]

    lifecycle = name == "test_same_anchor_ptrint_affine.ll"
    if lifecycle:
        opt_cmd[3:3] = ["-load-pass-plugin", POST_STATE_PLUGIN]
        # The ordinary checks validate 080 in isolation.  A second lifecycle
        # run below proves 040 only consumes the safe canonical GEP.
    if name == "test_heap_proven_resolver_lifecycle.ll":
        opt_cmd[3:3] = [
            "-load-pass-plugin", EXTERN_BRIDGE_PLUGIN,
            "-load-pass-plugin", POST_STATE_PLUGIN,
        ]
    if "brighten-type-mode=conservative" in content:
        opt_cmd.append("-brighten-type-mode=conservative")

    try:
        opt_proc = subprocess.Popen(opt_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = opt_proc.communicate()
        if opt_proc.returncode != 0:
            print("FAIL (opt crash)")
            print(err.decode())
            failed += 1
            continue

        fc_proc = subprocess.Popen([FILECHECK_BIN, path], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        fc_out, fc_err = fc_proc.communicate(input=out)

        if fc_proc.returncode == 0:
            print("PASS")
            passed += 1
        else:
            print("FAIL (FileCheck mismatch)")
            print(fc_err.decode())
            failed += 1

        if name == "test_heap_proven_resolver_lifecycle.ll":
            # The real pipeline serializes after 060 before final 040/080.
            # Prove that the per-call captures(none) fact is not merely an
            # in-memory analysis artifact and that 080 consumes the persisted
            # proof only after 040 has recovered the pointer slot.
            with tempfile.TemporaryDirectory(
                    prefix="brighten-060-040-080-") as temp_dir:
                checkpoint = os.path.join(temp_dir, "after_060.bc")
                stage_060 = subprocess.Popen(
                    [OPT_BIN, "-load-pass-plugin", EXTERN_BRIDGE_PLUGIN,
                     "-passes=brighten-extern-call-bridge,verify",
                     path, "-o", checkpoint],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                _, stage_060_err = stage_060.communicate()
                stage_040_080 = subprocess.Popen(
                    [OPT_BIN, "-load-pass-plugin", PLUGIN_PATH,
                     "-load-pass-plugin", POST_STATE_PLUGIN,
                     "-passes=brighten-post-state-frame-pass,"
                     "brighten-heap-proven-resolver-collapse,verify",
                     "-verify-each", "-S", checkpoint, "-o", "-"],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stage_out, stage_err = stage_040_080.communicate()
                stage_fc = subprocess.Popen(
                    [FILECHECK_BIN, path], stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                _, stage_fc_err = stage_fc.communicate(input=stage_out)
                if (stage_060.returncode == 0
                        and stage_040_080.returncode == 0
                        and stage_fc.returncode == 0):
                    print("  lifecycle 060->serialized->040->080: PASS")
                    passed += 1
                else:
                    print("  lifecycle 060->serialized->040->080: FAIL")
                    print(stage_060_err.decode() or stage_err.decode()
                          or stage_fc_err.decode())
                    failed += 1

        if lifecycle:
            lifecycle_cmd = [
                OPT_BIN, "-load-pass-plugin", PLUGIN_PATH,
                "-load-pass-plugin", POST_STATE_PLUGIN,
                "-passes=brighten-address-canonicalize,brighten-post-state-frame-pass,verify",
                "-verify-each", "-S", path, "-o", "-",
            ]
            lifecycle_proc = subprocess.Popen(
                lifecycle_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            lifecycle_out, lifecycle_err = lifecycle_proc.communicate()
            lifecycle_fc = subprocess.Popen(
                [FILECHECK_BIN, "--check-prefix=LIFECYCLE", path],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE)
            _, lifecycle_fc_err = lifecycle_fc.communicate(input=lifecycle_out)
            if lifecycle_proc.returncode == 0 and lifecycle_fc.returncode == 0:
                print("  lifecycle 080->040: PASS")
                passed += 1
            else:
                print("  lifecycle 080->040: FAIL")
                print(lifecycle_err.decode() or lifecycle_fc_err.decode())
                failed += 1

            # Production deliberately serializes immediately after the last
            # 090/state/region producer and before this late 080 rule.  This
            # is not an optimization: ConstantExpr uniquing at that lifecycle
            # boundary is required before exact/proven static anchors can be
            # compared.  Keep the 040 consumer in this regression so a future
            # pipeline reorder cannot make 040 depend on unsafe ptrtoint math.
            with tempfile.TemporaryDirectory(
                    prefix="brighten-late-090-080-") as temp_dir:
                checkpoint = os.path.join(temp_dir, "post_090.bc")
                stage_090_cmd = [
                    OPT_BIN, "-load-pass-plugin", NATIVE_CLEANUP_PLUGIN,
                    "-passes=brighten-native-cleanup-pass,verify",
                    "-verify-each", path, "-o", checkpoint,
                ]
                stage_090 = subprocess.Popen(
                    stage_090_cmd, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE)
                _, stage_090_err = stage_090.communicate()
                stage_080_cmd = [
                    OPT_BIN, "-load-pass-plugin", PLUGIN_PATH,
                    "-load-pass-plugin", POST_STATE_PLUGIN,
                    "-passes=brighten-address-canonicalize,"
                    "brighten-post-state-frame-pass,verify",
                    "-verify-each", "-S", checkpoint, "-o", "-",
                ]
                stage_080 = subprocess.Popen(
                    stage_080_cmd, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE)
                stage_080_out, stage_080_err = stage_080.communicate()
                stage_fc = subprocess.Popen(
                    [FILECHECK_BIN, "--check-prefix=LIFECYCLE", path],
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE)
                _, stage_fc_err = stage_fc.communicate(input=stage_080_out)
                if (stage_090.returncode == 0 and stage_080.returncode == 0
                        and stage_fc.returncode == 0):
                    print("  lifecycle 090->checkpoint->080->040: PASS")
                    passed += 1
                else:
                    print("  lifecycle 090->checkpoint->080->040: FAIL")
                    print((stage_090_err.decode() or stage_080_err.decode()
                           or stage_fc_err.decode()))
                    failed += 1
    except Exception as e:
        print(f"FAIL (Exception: {e})")
        failed += 1

print("Running special idempotence and determinism tests...")
idemp_path = os.path.join(TESTS_DIR, "test_idempotence.ll")
try:
    opt_1 = subprocess.check_output([OPT_BIN, "-load-pass-plugin", PLUGIN_PATH, "-passes=brighten-type-reconstruct", "-S", idemp_path]).decode()
    temp_path = os.path.join(TESTS_DIR, "temp_idemp.ll")
    with open(temp_path, "w") as f:
        f.write(opt_1)
    
    opt_2 = subprocess.check_output([OPT_BIN, "-load-pass-plugin", PLUGIN_PATH, "-passes=brighten-type-reconstruct", "-S", temp_path]).decode()
    
    opt_1_clean = re.sub(r"; ModuleID = .*\n", "", opt_1)
    opt_2_clean = re.sub(r"; ModuleID = .*\n", "", opt_2)

    if opt_1_clean == opt_2_clean:
        print("Idempotence/Determinism: PASS")
        passed += 2
    else:
        print("Idempotence/Determinism: FAIL")
        failed += 2

    if os.path.exists(temp_path):
        os.remove(temp_path)
except Exception as e:
    print(f"Idempotence/Determinism error: {e}")
    failed += 2

print(f"\nTest Summary: {passed} passed, {failed} failed")
if failed > 0:
    sys.exit(1)
else:
    sys.exit(0)
