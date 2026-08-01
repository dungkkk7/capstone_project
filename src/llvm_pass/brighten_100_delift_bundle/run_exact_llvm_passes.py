#!/usr/bin/env python3
"""Run the small cleanup pipeline through the installed LLVM command line."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess


def llvm_tool(name: str) -> str:
    for candidate in (f"{name}-21", name):
        path = shutil.which(candidate)
        if path:
            return path
    raise SystemExit(f"{name}-21/{name} not found")


def count_ir(text: str):
    functions = list(re.finditer(r"^define\b.*\{$", text, re.M))
    blocks = len(re.findall(r"^[A-Za-z$._][A-Za-z0-9$._-]*:\s*$", text, re.M))
    instructions = 0
    for line in text.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith((";", "define ", "declare ", "}", "!")) and not stripped.endswith(":"):
            instructions += 1
    return blocks, instructions


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    opt = llvm_tool("opt")
    input_text = args.input.read_text()
    before = count_ir(input_text)
    subprocess.run(
        [
            opt,
            "-S",
            "-passes=sccp,instcombine<no-verify-fixpoint>,dce,simplifycfg,verify",
            str(args.input),
            "-o",
            str(args.output),
        ],
        check=True,
    )
    after = count_ir(args.output.read_text())
    print(f"before: blocks={before[0]}, instructions={before[1]}")
    print(f"after:  blocks={after[0]}, instructions={after[1]}")


if __name__ == "__main__":
    main()
