#!/usr/bin/env python3
"""Differentially validate the deobfuscation plugin on LLVM bitcode or IR."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


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
        return status, stdout.read(1 << 20), stderr.read(1 << 20)


def semantic_ir_hash(llvm_dis, path):
    path = Path(path)
    if path.suffix == ".ll":
        text_ir = path.read_text(encoding="utf-8")
    else:
        result = subprocess.run(
            [llvm_dis, str(path), "-o", "-"], capture_output=True, text=True,
            check=True,
        )
        text_ir = result.stdout
    canonical = "\n".join(
        line for line in text_ir.splitlines()
        if not line.startswith("; ModuleID = ")
    )
    return hashlib.sha256(canonical.encode()).hexdigest()


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

    source_report = json.loads(Path(args.payload_report).read_text())
    payloads = [base64.b64decode(item) for item in source_report["tested_payloads"]]
    result = {
        "schema": "ollvm-deobf-differential-v1",
        "input": str(Path(args.input_bc).resolve()),
        "payloads": len(payloads),
        "before_after_matches": 0,
        "original_after_matches": 0,
        "mismatches": [],
        "fixed_point_rounds": 0,
        "fixed_point_converged": False,
    }

    with tempfile.TemporaryDirectory() as directory:
        directory = Path(directory)
        after_bc = directory / "after.bc"
        before_bin = directory / "before.bin"
        after_bin = directory / "after.bin"
        current = Path(args.input_bc)
        for round_index in range(1, args.max_rounds + 1):
            candidate = directory / f"round-{round_index}.bc"
            before_hash = semantic_ir_hash(llvm_dis, current)
            subprocess.run(
                [
                    opt,
                    "-load-pass-plugin", args.plugin,
                    "-passes=brighten-ollvm-deobf-pass,jump-threading,"
                    "simplifycfg,adce,verify",
                    str(current),
                    "-o", str(candidate),
                ],
                check=True,
            )
            result["fixed_point_rounds"] = round_index
            if semantic_ir_hash(llvm_dis, candidate) == before_hash:
                result["fixed_point_converged"] = True
                shutil.copy2(candidate, after_bc)
                break
            current = candidate
        if not result["fixed_point_converged"]:
            raise SystemExit("fixed_point_cap_reached")
        subprocess.run([clang, args.input_bc, "-O2", "-o", before_bin], check=True)
        subprocess.run([clang, after_bc, "-O2", "-o", after_bin], check=True)

        for index, payload in enumerate(payloads):
            before = run_bounded(before_bin, payload, args.timeout)
            after = run_bounded(after_bin, payload, args.timeout)
            if before == after:
                result["before_after_matches"] += 1
            else:
                result["mismatches"].append({
                    "index": index,
                    "payload_b64": base64.b64encode(payload).decode(),
                    "oracle": "before_after",
                    "before_status": before[0],
                    "after_status": after[0],
                })
            if args.original_elf:
                original = run_bounded(args.original_elf, payload, args.timeout)
                if original == after:
                    result["original_after_matches"] += 1
                else:
                    result["mismatches"].append({
                        "index": index,
                        "payload_b64": base64.b64encode(payload).decode(),
                        "oracle": "original_after",
                        "original_status": original[0],
                        "after_status": after[0],
                    })

    result["status"] = "pass" if not result["mismatches"] else "mismatch"
    encoded = json.dumps(result, indent=2) + "\n"
    if args.report:
        Path(args.report).write_text(encoded)
    print(encoded, end="")
    raise SystemExit(0 if result["status"] == "pass" else 1)


if __name__ == "__main__":
    main()
