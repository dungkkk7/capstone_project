#!/usr/bin/env python3
"""Differentially validate the deobfuscation plugin on LLVM bitcode or IR.

The report binds every execution result to content hashes of the exact IR,
plugin, compiler, and generated executables.  This prevents a stale or shared
temporary binary from being reported as the transformation under test.
"""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


MAX_CAPTURE = 1 << 20


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def file_sha256(path):
    hasher = hashlib.sha256()
    with Path(path).open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def file_manifest(path, *, semantic_hash=None):
    path = Path(path).resolve()
    item = {
        "path": str(path),
        "size": path.stat().st_size,
        "sha256": file_sha256(path),
    }
    if semantic_hash is not None:
        item["semantic_ir_sha256"] = semantic_hash
    return item


def tool_identity(path):
    resolved = Path(path).resolve()
    completed = subprocess.run(
        [str(resolved), "--version"],
        capture_output=True,
        text=True,
        check=False,
    )
    version = (completed.stdout or completed.stderr).strip()
    return {
        "path": str(resolved),
        "sha256": file_sha256(resolved),
        "version": version[:8192],
        "version_returncode": completed.returncode,
    }


def run_bounded(binary, payload, timeout):
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        process = subprocess.Popen(
            [str(binary)], stdin=subprocess.PIPE, stdout=stdout, stderr=stderr
        )
        try:
            process.communicate(payload, timeout=timeout)
            status = {"kind": "exit", "code": process.returncode}
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()
            status = {"kind": "timeout", "code": None}
        stdout.seek(0)
        stderr.seek(0)
        return status, stdout.read(MAX_CAPTURE), stderr.read(MAX_CAPTURE)


def stream_manifest(data):
    return {
        "size": len(data),
        "sha256": sha256_bytes(data),
        "base64": base64.b64encode(data).decode("ascii"),
        "utf8": data.decode("utf-8", errors="replace"),
    }


def execution_manifest(execution):
    status, stdout, stderr = execution
    return {
        "status": status,
        "stdout": stream_manifest(stdout),
        "stderr": stream_manifest(stderr),
    }


def semantic_ir_hash(llvm_dis, path):
    path = Path(path)
    if path.suffix == ".ll":
        text_ir = path.read_text(encoding="utf-8")
    else:
        result = subprocess.run(
            [llvm_dis, str(path), "-o", "-"],
            capture_output=True,
            text=True,
            check=True,
        )
        text_ir = result.stdout
    canonical = "\n".join(
        line for line in text_ir.splitlines()
        if not line.startswith("; ModuleID = ")
    )
    return hashlib.sha256(canonical.encode()).hexdigest()


def compile_ir(clang, input_path, output_path):
    command = [clang, str(input_path), "-O2", "-o", str(output_path), "-lm"]
    subprocess.run(command, check=True)
    return command


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-bc", required=True)
    parser.add_argument("--plugin", required=True)
    parser.add_argument("--payload-report", required=True)
    parser.add_argument("--original-elf")
    parser.add_argument("--timeout", type=float, default=0.5)
    parser.add_argument("--max-rounds", type=int, default=8)
    parser.add_argument("--report")
    args = parser.parse_args()

    opt = shutil.which("opt-21")
    clang = shutil.which("clang-21")
    llvm_dis = shutil.which("llvm-dis-21")
    if not opt or not clang or not llvm_dis:
        raise SystemExit("opt-21, clang-21, and llvm-dis-21 are required")

    input_bc = Path(args.input_bc).resolve()
    plugin = Path(args.plugin).resolve()
    payload_report = Path(args.payload_report).resolve()
    original_elf = Path(args.original_elf).resolve() if args.original_elf else None
    source_report = json.loads(payload_report.read_text(encoding="utf-8"))
    payloads = [base64.b64decode(item) for item in source_report["tested_payloads"]]

    input_semantic_hash = semantic_ir_hash(llvm_dis, input_bc)
    result = {
        "schema": "ollvm-deobf-differential-v2",
        "input": str(input_bc),
        "payloads": len(payloads),
        "before_after_matches": 0,
        "original_after_matches": 0,
        "mismatches": [],
        "fixed_point_rounds": 0,
        "fixed_point_converged": False,
        "tools": {
            "opt": tool_identity(opt),
            "clang": tool_identity(clang),
            "llvm_dis": tool_identity(llvm_dis),
        },
        "artifacts": {
            "input_ir": file_manifest(input_bc, semantic_hash=input_semantic_hash),
            "plugin": file_manifest(plugin),
            "payload_report": file_manifest(payload_report),
        },
        "commands": {"fixed_point": [], "compile": []},
    }
    if original_elf:
        result["artifacts"]["original_elf"] = file_manifest(original_elf)

    with tempfile.TemporaryDirectory(prefix="ollvm-deobf-differential-") as temp:
        directory = Path(temp)
        after_bc = directory / "after.bc"
        current = input_bc
        for round_index in range(1, args.max_rounds + 1):
            candidate = directory / f"round-{round_index}.bc"
            before_hash = semantic_ir_hash(llvm_dis, current)
            command = [
                opt,
                "-load-pass-plugin", str(plugin),
                "-passes=brighten-ollvm-deobf-pass,jump-threading,"
                "simplifycfg,adce,verify",
                str(current),
                "-o", str(candidate),
            ]
            subprocess.run(command, check=True)
            result["commands"]["fixed_point"].append(command)
            result["fixed_point_rounds"] = round_index
            if semantic_ir_hash(llvm_dis, candidate) == before_hash:
                result["fixed_point_converged"] = True
                shutil.copy2(candidate, after_bc)
                break
            current = candidate
        if not result["fixed_point_converged"]:
            raise SystemExit("fixed_point_cap_reached")

        after_semantic_hash = semantic_ir_hash(llvm_dis, after_bc)
        result["artifacts"]["after_ir"] = file_manifest(
            after_bc, semantic_hash=after_semantic_hash
        )

        # Use content-addressed executable names even inside the private temp
        # directory.  A report can therefore prove which exact IR generated
        # the process that was executed.
        before_bin = directory / f"before-{input_semantic_hash[:16]}.bin"
        after_bin = directory / f"after-{after_semantic_hash[:16]}.bin"
        result["commands"]["compile"].append(
            compile_ir(clang, input_bc, before_bin)
        )
        result["commands"]["compile"].append(
            compile_ir(clang, after_bc, after_bin)
        )
        result["artifacts"]["before_executable"] = file_manifest(before_bin)
        result["artifacts"]["after_executable"] = file_manifest(after_bin)
        result["execution_binding"] = {
            "before_semantic_ir_sha256": input_semantic_hash,
            "before_executable_sha256": result["artifacts"]["before_executable"]["sha256"],
            "after_semantic_ir_sha256": after_semantic_hash,
            "after_executable_sha256": result["artifacts"]["after_executable"]["sha256"],
            "plugin_sha256": result["artifacts"]["plugin"]["sha256"],
            "clang_sha256": result["tools"]["clang"]["sha256"],
        }

        for index, payload in enumerate(payloads):
            before = run_bounded(before_bin, payload, args.timeout)
            after = run_bounded(after_bin, payload, args.timeout)
            if before == after:
                result["before_after_matches"] += 1
            else:
                result["mismatches"].append({
                    "index": index,
                    "payload_b64": base64.b64encode(payload).decode("ascii"),
                    "oracle": "before_after",
                    # Keep legacy status fields while adding complete captured
                    # streams and their hashes for reproducibility.
                    "before_status": before[0],
                    "after_status": after[0],
                    "before": execution_manifest(before),
                    "after": execution_manifest(after),
                    "execution_binding": result["execution_binding"],
                })
            if original_elf:
                original = run_bounded(original_elf, payload, args.timeout)
                if original == after:
                    result["original_after_matches"] += 1
                else:
                    result["mismatches"].append({
                        "index": index,
                        "payload_b64": base64.b64encode(payload).decode("ascii"),
                        "oracle": "original_after",
                        "original_status": original[0],
                        "after_status": after[0],
                        "original": execution_manifest(original),
                        "after": execution_manifest(after),
                        "execution_binding": result["execution_binding"],
                    })

    result["status"] = "pass" if not result["mismatches"] else "mismatch"
    encoded = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.report:
        Path(args.report).write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    raise SystemExit(0 if result["status"] == "pass" else 1)


if __name__ == "__main__":
    main()
