#!/usr/bin/env python3
"""Verify that a public LLVM entrypoint survives finalization.

The check uses LLVM's parser and symbol-table reader instead of textual regular
expressions.  Exit codes are fail-closed:

* 0: contract satisfied;
* 2: contract disproved (missing or non-public symbol);
* 3: inconclusive because required LLVM tooling could not run.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Sequence


@dataclass(frozen=True)
class EntrypointResult:
    decision: str
    symbol: str
    artifact: str
    artifact_kind: str
    public_definitions: list[str]
    command: list[str]
    materialization_command: list[str]
    returncode: int | None
    summary: str
    stderr: str = ""


def _find_tool(names: Sequence[str]) -> str | None:
    for name in names:
        path = shutil.which(name)
        if path:
            return path
    return None


def parse_posix_nm(output: str) -> set[str]:
    """Return externally visible defined symbols from POSIX llvm-nm output."""
    symbols: set[str] = set()
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line or line.endswith(":"):
            continue
        fields = line.split()
        if len(fields) < 2:
            continue
        name, symbol_type = fields[0], fields[1]
        if symbol_type.upper() == "U":
            continue
        symbols.add(name)
    return symbols


def _materialize_bitcode(
    artifact: Path, workdir: Path, timeout: float
) -> tuple[Path | None, list[str], str]:
    if artifact.suffix == ".bc":
        return artifact, [], ""

    bitcode = workdir / "entrypoint-input.bc"
    llvm_as = _find_tool(("llvm-as-21", "llvm-as"))
    opt = _find_tool(("opt-21", "opt"))
    if llvm_as is not None:
        command = [llvm_as, str(artifact), "-o", str(bitcode)]
    elif opt is not None:
        # The bundle already requires opt.  This fallback prevents llvm-as from
        # becoming an accidental additional availability requirement.
        command = [opt, "-passes=verify", str(artifact), "-o", str(bitcode)]
    else:
        return None, [], "llvm-as-21/llvm-as and opt-21/opt not found"

    try:
        completed = subprocess.run(
            command, capture_output=True, text=True, timeout=timeout
        )
    except subprocess.TimeoutExpired as exc:
        return None, command, (exc.stderr or "") + "\nmaterialization timed out"
    except OSError as exc:
        return None, command, str(exc)
    if completed.returncode != 0 or not bitcode.is_file():
        return None, command, completed.stderr or "LLVM materialization failed"
    return bitcode, command, completed.stderr or ""


def inspect_entrypoint(
    artifact: Path | str, symbol: str = "main", timeout: float = 60.0
) -> EntrypointResult:
    path = Path(artifact).resolve()
    if not path.is_file():
        return EntrypointResult(
            decision="fail",
            symbol=symbol,
            artifact=str(path),
            artifact_kind="missing",
            public_definitions=[],
            command=[],
            materialization_command=[],
            returncode=None,
            summary="artifact does not exist",
        )

    llvm_nm = _find_tool(("llvm-nm-21", "llvm-nm"))
    if llvm_nm is None:
        return EntrypointResult(
            decision="inconclusive",
            symbol=symbol,
            artifact=str(path),
            artifact_kind=path.suffix.lstrip(".") or "unknown",
            public_definitions=[],
            command=[],
            materialization_command=[],
            returncode=None,
            summary="llvm-nm-21/llvm-nm not found",
        )

    with tempfile.TemporaryDirectory(prefix="brighten-entrypoint-") as temp_name:
        bitcode, materialization_command, materialization_error = (
            _materialize_bitcode(path, Path(temp_name), timeout)
        )
        if bitcode is None:
            return EntrypointResult(
                decision="inconclusive",
                symbol=symbol,
                artifact=str(path),
                artifact_kind=path.suffix.lstrip(".") or "unknown",
                public_definitions=[],
                command=[],
                materialization_command=materialization_command,
                returncode=None,
                summary="could not materialize LLVM bitcode",
                stderr=materialization_error,
            )

        command = [
            llvm_nm,
            "--defined-only",
            "--extern-only",
            "--format=posix",
            str(bitcode),
        ]
        try:
            completed = subprocess.run(
                command, capture_output=True, text=True, timeout=timeout
            )
        except subprocess.TimeoutExpired as exc:
            return EntrypointResult(
                decision="inconclusive",
                symbol=symbol,
                artifact=str(path),
                artifact_kind=path.suffix.lstrip(".") or "unknown",
                public_definitions=[],
                command=command,
                materialization_command=materialization_command,
                returncode=None,
                summary="llvm-nm inspection timed out",
                stderr=exc.stderr or "",
            )
        except OSError as exc:
            return EntrypointResult(
                decision="inconclusive",
                symbol=symbol,
                artifact=str(path),
                artifact_kind=path.suffix.lstrip(".") or "unknown",
                public_definitions=[],
                command=command,
                materialization_command=materialization_command,
                returncode=None,
                summary="llvm-nm could not be executed",
                stderr=str(exc),
            )
        if completed.returncode != 0:
            return EntrypointResult(
                decision="inconclusive",
                symbol=symbol,
                artifact=str(path),
                artifact_kind=path.suffix.lstrip(".") or "unknown",
                public_definitions=[],
                command=command,
                materialization_command=materialization_command,
                returncode=completed.returncode,
                summary="llvm-nm could not inspect the module",
                stderr=completed.stderr or "",
            )

        definitions = sorted(parse_posix_nm(completed.stdout or ""))
        present = symbol in definitions
        return EntrypointResult(
            decision="pass" if present else "fail",
            symbol=symbol,
            artifact=str(path),
            artifact_kind=path.suffix.lstrip(".") or "unknown",
            public_definitions=definitions,
            command=command,
            materialization_command=materialization_command,
            returncode=completed.returncode,
            summary=(
                f"public definition @{symbol} is present"
                if present
                else f"public definition @{symbol} is missing"
            ),
            stderr=(
                materialization_error + "\n" + (completed.stderr or "")
            ).strip(),
        )


def _atomic_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except Exception:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify that an LLVM module exports a defined entrypoint."
    )
    parser.add_argument("artifact", help="LLVM assembly (.ll) or bitcode (.bc)")
    parser.add_argument("--symbol", default="main", help="required public symbol")
    parser.add_argument("--report", help="optional JSON evidence path")
    parser.add_argument(
        "--timeout", type=float, default=60.0, help="per-tool timeout in seconds"
    )
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")

    result = inspect_entrypoint(args.artifact, args.symbol, args.timeout)
    payload = asdict(result)
    if args.report:
        _atomic_json(Path(args.report), payload)
    print(json.dumps(payload, sort_keys=True))
    if result.decision == "pass":
        return 0
    if result.decision == "fail":
        return 2
    return 3


if __name__ == "__main__":
    raise SystemExit(main())
