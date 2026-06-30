#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import base64
import os
import shutil
import subprocess
import sys
import time

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(line_buffering=True)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
DEFAULT_REVNG_ROOT = os.path.join(PROJECT_ROOT, "dependency/revng/root")


class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'


def revng_root():
    return os.path.abspath(os.environ.get("REVNG_ROOT", DEFAULT_REVNG_ROOT))


def revng_python(root):
    candidate = os.path.join(root, "bin", "python3.14")
    return candidate if os.path.exists(candidate) else sys.executable


def revng2_cmd(root):
    return [revng_python(root), os.path.join(root, "bin", "revng2")]


def run_command(cmd, step_name, cwd=None, capture_output=False):
    """Thực thi lệnh hệ thống và stream log theo thời gian thực."""
    print(f"{Color.BLUE}{Color.BOLD}    -> Bat dau: {step_name}...{Color.END}")
    print(f"{Color.GRAY}      Lenh: {' '.join(cmd)}{Color.END}")

    start_time = time.time()
    output = []

    try:
        process = subprocess.Popen(
            cmd,
            cwd=cwd,
            env=os.environ,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=not capture_output,
            bufsize=1 if not capture_output else -1,
        )

        if capture_output:
            stdout, _ = process.communicate()
            if stdout:
                output.append(stdout)
        else:
            for line in process.stdout:
                stripped = line.strip()
                if stripped:
                    elapsed = int(time.time() - start_time)
                    print(f"{Color.GRAY}      [{elapsed}s] {stripped}{Color.END}")
            process.wait()

        elapsed_total = int(time.time() - start_time)
        if process.returncode == 0:
            print(f"{Color.GREEN}      [OK] Hoan thanh: {step_name} (Tong thoi gian: {elapsed_total}s){Color.END}")
            if capture_output:
                return True, b"".join(output)
            return True

        print(f"{Color.RED}      [FAIL] That bai tai: {step_name} (Ma loi: {process.returncode}, Tong thoi gian: {elapsed_total}s){Color.END}")
        if capture_output and output:
            print(output[0].decode(errors="replace") if isinstance(output[0], bytes) else output[0])
        if capture_output:
            return False, b"".join(output)
        return False
    except Exception as exc:
        print(f"{Color.RED}      [FAIL] Loi thuc thi he thong: {exc}{Color.END}")
        if capture_output:
            return False, b""
        return False


def default_output_for(binary_path):
    binary_abs = os.path.abspath(binary_path)
    result_root = os.path.join(PROJECT_ROOT, "result")

    data_obfuscated_root = os.path.join(PROJECT_ROOT, "data/obfuscated")
    data_clean_root = os.path.join(PROJECT_ROOT, "data/clean_src")

    rel_path = None
    if binary_abs.startswith(data_obfuscated_root):
        rel_path = os.path.relpath(binary_abs, data_obfuscated_root)
    elif binary_abs.startswith(data_clean_root):
        rel_path = os.path.relpath(binary_abs, data_clean_root)
    elif binary_abs.startswith(PROJECT_ROOT):
        rel_path = os.path.relpath(binary_abs, PROJECT_ROOT)

    base_name = os.path.splitext(os.path.basename(binary_path))[0]
    if rel_path:
        output_dir = os.path.join(result_root, os.path.dirname(rel_path))
    else:
        output_dir = result_root

    os.makedirs(output_dir, exist_ok=True)
    return os.path.join(output_dir, f"{base_name}.bc")


def decode_revng_artifact(artifact_output, output_bc):
    text = artifact_output.decode("utf-8", errors="replace").strip()
    if not text:
        print(f"{Color.RED}[FAIL] revng khong tra ve artifact nao.{Color.END}")
        return False

    payloads = []
    for line in text.splitlines():
        if not line.strip():
            continue
        if ":" not in line:
            print(f"{Color.YELLOW}[!] Bo qua dong artifact khong dung dinh dang: {line[:80]}{Color.END}")
            continue
        _, payload = line.split(":", 1)
        payloads.append(payload.strip())

    if not payloads:
        print(f"{Color.RED}[FAIL] Khong tim thay payload base64 trong output cua revng.{Color.END}")
        return False
    if len(payloads) > 1:
        print(f"{Color.YELLOW}[!] revng tra ve {len(payloads)} artifact, chi ghi artifact dau tien vao {output_bc}.{Color.END}")

    try:
        decoded = base64.b64decode(payloads[0], validate=True)
    except Exception as exc:
        print(f"{Color.RED}[FAIL] Khong decode duoc artifact revng: {exc}{Color.END}")
        return False

    os.makedirs(os.path.dirname(os.path.abspath(output_bc)), exist_ok=True)
    with open(output_bc, "wb") as f:
        f.write(decoded)
    return True


def lift_binary(binary_path, output=None, keep_project=False):
    if not os.path.exists(binary_path):
        print(f"{Color.RED}[FAIL] Loi: Khong tim thay file binary tai '{binary_path}'{Color.END}")
        return False

    root = revng_root()
    revng2 = os.path.join(root, "bin", "revng2")
    if not os.path.exists(revng2):
        print(f"{Color.RED}[FAIL] Khong tim thay revng2 tai '{revng2}'. Dat REVNG_ROOT hoac cap nhat dependency/revng/root.{Color.END}")
        return False

    output_bc = output or default_output_for(binary_path)
    output_dir = os.path.dirname(os.path.abspath(output_bc))
    base_name = os.path.splitext(os.path.basename(output_bc))[0]
    project_dir = os.path.join(output_dir, f"{base_name}.revng-project")
    binary_abs = os.path.abspath(binary_path)

    if os.path.exists(project_dir):
        shutil.rmtree(project_dir)
    os.makedirs(project_dir, exist_ok=True)

    print(f"{Color.BLUE}{Color.BOLD}" + "=" * 60 + f"{Color.END}")
    print(f"{Color.BLUE}[*] Dang xu ly: {binary_path}{Color.END}")
    print(f"{Color.BLUE}[*] revng root: {root}{Color.END}")
    print(f"{Color.BLUE}[*] Thu muc dau ra ket qua: {output_dir}{Color.END}")
    print(f"{Color.BLUE}[*] Thu muc project revng: {project_dir}{Color.END}")
    print(f"{Color.BLUE}{Color.BOLD}" + "=" * 60 + f"{Color.END}")

    init_cmd = revng2_cmd(root) + ["-C", project_dir, "project", "init", binary_abs]
    if not run_command(init_cmd, "Buoc 1: Khoi tao revng project va model"):
        return False

    artifact_cmd = revng2_cmd(root) + ["-C", project_dir, "project", "artifact", "lift"]
    ok, artifact_output = run_command(
        artifact_cmd,
        "Buoc 2: Lift binary bang revng",
        capture_output=True,
    )
    if not ok:
        return False

    if not decode_revng_artifact(artifact_output, output_bc):
        return False
    print(f"{Color.GREEN}      [OK] Da ghi LLVM bitcode: {output_bc}{Color.END}")

    output_ll = f"{os.path.splitext(output_bc)[0]}.ll"
    llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
    if llvm_dis:
        if not run_command([llvm_dis, output_bc, "-o", output_ll], "Buoc 3: Chuyen bitcode sang LLVM IR (.ll)"):
            return False
        print(f"{Color.GREEN}[OK] Hoan tat! File LLVM IR san sang tai: {output_ll}{Color.END}")
    else:
        print(f"{Color.YELLOW}[!] Khong tim thay llvm-dis. Bitcode da san sang tai: {output_bc}{Color.END}")

    if not keep_project:
        shutil.rmtree(project_dir, ignore_errors=True)

    return True


def main():
    parser = argparse.ArgumentParser(description="revng binary lifter")
    parser.add_argument("-b", "--binary", required=True, help="Duong dan toi file binary can lift")
    parser.add_argument("-o", "--output", help="File .bc dau ra (mac dinh: result/[binary].bc)")
    parser.add_argument("--keep-project", action="store_true", help="Giu lai thu muc revng project trung gian")

    args = parser.parse_args()
    if not lift_binary(binary_path=args.binary, output=args.output, keep_project=args.keep_project):
        sys.exit(1)


if __name__ == "__main__":
    main()
