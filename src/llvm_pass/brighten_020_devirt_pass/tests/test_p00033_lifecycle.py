#!/usr/bin/env python3
"""Differential gate for the frozen p00033 region-SSA regression payload.

The production lifecycle produces the candidate binary; this test compares it
with the original ELF without depending on symbols, IR names, or pass order.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


PAYLOAD = (
    b"2\n"
    b"3 1 4 2 5 6 7 8 9 10\n"
    b"10 9 8 7 6 5 4 3 2 1\n"
)


def run(binary: Path) -> tuple[int, bytes, bytes]:
    result = subprocess.run(
        [str(binary)], input=PAYLOAD, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, check=False, timeout=10,
    )
    return result.returncode, result.stdout, result.stderr


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    args = parser.parse_args()

    for binary in (args.candidate, args.reference):
        if not binary.is_file():
            raise SystemExit(f"missing binary: {binary}")

    candidate = run(args.candidate)
    reference = run(args.reference)
    if candidate != reference:
        raise SystemExit(
            "p00033 differential mismatch: "
            f"candidate={candidate!r} reference={reference!r}"
        )
    print("p00033 lifecycle differential: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
