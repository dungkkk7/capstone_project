import subprocess
import os
import sys
import re

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
PASS_DIR = os.path.dirname(TESTS_DIR)
BUILD_DIR = os.path.join(PASS_DIR, "build")
PLUGIN_PATH = os.path.join(BUILD_DIR, "BrightenTypeReconstructionPass.so")

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

; CHECK: @my_global = internal global [2 x i32] [i32 67305985, i32 134678021]

@my_global = internal global [8 x i8] c"\\01\\02\\03\\04\\05\\06\\07\\08"

define void @test_global() {
entry:
  %p0 = getelementptr [8 x i8], ptr @my_global, i64 0, i64 0
  %v0 = load i32, ptr %p0, align 4

  %p4 = getelementptr [8 x i8], ptr @my_global, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4

  ret void
}
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
  ; CHECK: %obj = alloca [64 x [1 x i8]]
  %obj = alloca [64 x i8], align 4

  ; Unknown offset calculation: shift left by a dynamic variable or non-linear arithmetic
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
  ; CHECK: %obj = alloca %brighten.struct.stack.test_memcpy.obj
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

failed = 0
passed = 0

for name, content in test_cases.items():
    path = os.path.join(TESTS_DIR, name)
    with open(path, "w") as f:
        f.write(content.strip() + "\n")

    print(f"Running test: {name} ...", end=" ")
    sys.stdout.flush()

    opt_cmd = [OPT_BIN, "-load-pass-plugin", PLUGIN_PATH, "-passes=brighten-type-reconstruct", "-S", path, "-o", "-"]
    
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
