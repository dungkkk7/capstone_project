#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Conservative LLVM optimization for recovered IR.

This module verifies that optimized IR remains valid and can be compiled to an
object file. It deliberately does not claim that a per-function recovered
module is a standalone executable: such a module can lack `main`, binary
segments, dynamic-call implementations, and rev.ng runtime helpers.
"""

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from typing import Optional, Sequence

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
REVNG_DIR = os.path.join(PROJECT_ROOT, "dependency", "revng")


class Color:
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    GRAY = "\033[90m"
    END = "\033[0m"


def _find_tool(names: Sequence[str]) -> Optional[str]:
    revng = shutil.which("revng")
    directories: list[str] = []
    if revng:
        base = os.path.dirname(os.path.realpath(revng))
        directories.extend(
            [
                base,
                os.path.join(base, "root", "lib64", "llvm", "llvm", "bin"),
                os.path.abspath(
                    os.path.join(base, "..", "root", "lib64", "llvm", "llvm", "bin")
                ),
            ]
        )
    directories.extend(
        [
            os.path.join(REVNG_DIR, "bin"),
            os.path.join(REVNG_DIR, "root", "lib64", "llvm", "llvm", "bin"),
        ]
    )
    for directory in directories:
        for name in names:
            candidate = os.path.join(directory, name)
            if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
                return candidate
    for name in names:
        candidate = shutil.which(name)
        if candidate:
            return candidate
    return None


def _run(cmd: Sequence[str], label: str) -> bool:
    print(f"\n{Color.BLUE}[*] {label}{Color.END}")
    print(f"{Color.GRAY}    $ {' '.join(shlex.quote(str(x)) for x in cmd)}{Color.END}")
    try:
        result = subprocess.run(list(cmd), capture_output=True, text=True, check=False)
    except Exception as exc:
        print(f"{Color.RED}[✗] {exc}{Color.END}")
        return False
    if result.returncode == 0:
        print(f"{Color.GREEN}[✓] Hoàn tất.{Color.END}")
        return True
    print(f"{Color.RED}[✗] code={result.returncode}{Color.END}")
    if result.stdout.strip():
        print(f"{Color.GRAY}{result.stdout.strip()[:3000]}{Color.END}")
    if result.stderr.strip():
        print(f"{Color.RED}{result.stderr.strip()[:5000]}{Color.END}")
    return False


def _to_bc(input_path: str, work_dir: str) -> Optional[str]:
    if input_path.lower().endswith(".bc"):
        return input_path
    if not input_path.lower().endswith(".ll"):
        return None

    llvm_as = _find_tool(["llvm-as", "llvm-as-21", "llvm-as-20", "llvm-as-19", "llvm-as-18"])
    temp_bc = os.path.join(work_dir, ".brighten_input.bc")
    if llvm_as:
        return temp_bc if _run([llvm_as, input_path, "-o", temp_bc], "Assemble .ll → .bc") else None

    clang = _find_tool(["clang", "clang-21", "clang-20", "clang-19", "clang-18"])
    if not clang:
        return None
    return (
        temp_bc
        if _run(
            [clang, "-c", "-emit-llvm", input_path, "-o", temp_bc],
            "Assemble .ll → .bc (clang fallback)",
        )
        else None
    )


def compile_ir_to_object(input_ir: str, output_object: str) -> bool:
    """Compile LLVM IR to an object file, without requiring an entry point."""
    clang = _find_tool(["clang", "clang-21", "clang-20", "clang-19", "clang-18"])
    if not clang:
        print(f"{Color.RED}[✗] Không tìm thấy clang.{Color.END}")
        return False
    input_ir = os.path.abspath(input_ir)
    output_object = os.path.abspath(output_object)
    os.makedirs(os.path.dirname(output_object), exist_ok=True)
    return _run([clang, "-c", input_ir, "-o", output_object], "LLVM IR → object file")


def brighten_ir(
    input_path: str,
    output_path: Optional[str] = None,
    binary_path: Optional[str] = None,
    model_path: Optional[str] = None,
    *,
    opt_level: str = "O1",
) -> bool:
    """Optimize recovered LLVM IR and emit `.bc`, `.ll`, and a verify object.

    `binary_path` and `model_path` are accepted only for compatibility with old
    call sites. rev.ng processing must happen in `binary_lifting.lifting`.
    """
    del binary_path, model_path
    input_path = os.path.abspath(input_path)
    if not os.path.isfile(input_path):
        print(f"{Color.RED}[✗] Không tồn tại: {input_path}{Color.END}")
        return False

    if output_path is None:
        base, _ = os.path.splitext(input_path)
        output_path = base + ".brightened.bc"
    output_path = os.path.abspath(output_path)
    output_dir = os.path.dirname(output_path)
    os.makedirs(output_dir, exist_ok=True)

    if output_path.lower().endswith(".ll"):
        out_ll = output_path
        out_bc = os.path.splitext(output_path)[0] + ".bc"
    elif output_path.lower().endswith(".bc"):
        out_bc = output_path
        out_ll = os.path.splitext(output_path)[0] + ".ll"
    else:
        print(f"{Color.RED}[✗] Output phải là .bc hoặc .ll.{Color.END}")
        return False

    working_bc = _to_bc(input_path, output_dir)
    if not working_bc:
        print(f"{Color.RED}[✗] Không chuyển input thành bitcode được.{Color.END}")
        return False

    opt = _find_tool(["opt", "opt-21", "opt-20", "opt-19", "opt-18"])
    llvm_dis = _find_tool(["llvm-dis", "llvm-dis-21", "llvm-dis-20", "llvm-dis-19", "llvm-dis-18"])
    clang = _find_tool(["clang", "clang-21", "clang-20", "clang-19", "clang-18"])
    if not clang:
        print(f"{Color.RED}[✗] Thiếu clang.{Color.END}")
        return False

    if opt:
        level = opt_level.upper().lstrip("-")
        if level not in {"O0", "O1", "O2", "O3", "OS", "OZ"}:
            level = "O1"
        pipeline = f"default<{level}>"
        if not _run(
            [opt, f"-passes={pipeline}", working_bc, "-o", out_bc],
            f"LLVM opt {pipeline}",
        ):
            return False
    else:
        shutil.copy2(working_bc, out_bc)
        print(f"{Color.YELLOW}[!] Không có opt; giữ nguyên bitcode.{Color.END}")

    if llvm_dis:
        dis_ok = _run([llvm_dis, out_bc, "-o", out_ll], "Bitcode → readable LLVM IR")
    else:
        dis_ok = _run(
            [clang, "-S", "-emit-llvm", out_bc, "-o", out_ll],
            "Bitcode → readable LLVM IR (clang fallback)",
        )
    if not dis_ok:
        return False

    verify_obj = os.path.splitext(out_bc)[0] + ".verify.o"
    if not compile_ir_to_object(out_bc, verify_obj):
        return False

    print(f"{Color.GREEN}[✓] Brightened BC: {out_bc}{Color.END}")
    print(f"{Color.GREEN}[✓] Brightened LL: {out_ll}{Color.END}")
    print(f"{Color.GREEN}[✓] Verify object: {verify_obj}{Color.END}")
    print(
        f"{Color.YELLOW}[!] Đây là object-recompilable IR, không phải standalone executable IR."
        f"{Color.END}"
    )
    return True


def compile_ir_to_executable(
    input_ir: str,
    output_executable: str,
    extra_link_flags: Optional[Sequence[str]] = None,
) -> bool:
    """Legacy helper.

    This function is intentionally conservative: it tries to link only when
    requested explicitly, and failure does not imply invalid LLVM IR. A module
    emitted from rev.ng decompiled functions commonly lacks `main` and runtime
    helper implementations.
    """
    clang = _find_tool(["clang", "clang-21", "clang-20", "clang-19", "clang-18"])
    if not clang:
        print(f"{Color.RED}[✗] Không tìm thấy clang.{Color.END}")
        return False
    input_ir = os.path.abspath(input_ir)
    output_executable = os.path.abspath(output_executable)
    os.makedirs(os.path.dirname(output_executable), exist_ok=True)
    flags = list(extra_link_flags or ["-lm", "-ldl", "-lpthread"])
    ok = _run(
        [clang, input_ir, "-o", output_executable, *flags],
        "Thử link LLVM IR thành executable",
    )
    if ok:
        os.chmod(output_executable, os.stat(output_executable).st_mode | 0o111)
    else:
        print(
            f"{Color.YELLOW}[!] Link thất bại có thể do thiếu main/runtime helpers; "
            "hãy dùng executable từ revng recompile-isolated để test semantics."
            f"{Color.END}"
        )
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description="Conservative LLVM IR brightening")
    parser.add_argument("-i", "--input", required=True)
    parser.add_argument("-o", "--output")
    parser.add_argument("--opt-level", default="O1", choices=["O0", "O1", "O2", "O3", "Os", "Oz"])
    parser.add_argument("--link-exe", help="Legacy/optional: thử link standalone executable")
    args = parser.parse_args()

    if not brighten_ir(args.input, args.output, opt_level=args.opt_level):
        return 1
    if args.link_exe:
        bc = args.output or os.path.splitext(args.input)[0] + ".brightened.bc"
        if bc.endswith(".ll"):
            bc = os.path.splitext(bc)[0] + ".bc"
        if not compile_ir_to_executable(bc, args.link_exe):
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
