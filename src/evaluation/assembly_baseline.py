"""Deterministic program-level assembly export for B2.

LLM4Decompile-End disassembles binaries with ``objdump -d``, removes the raw
machine-code byte column and comments, and wraps the remaining AT&T assembly
in a fixed source-recovery template.  Its released demo extracts one function.
Our evaluation unit is a complete command-line program, so this exporter keeps
all non-empty function blocks from the original ELF while applying the same
instruction cleaning rule.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path


DEFAULT_OBJDUMP = shutil.which("objdump") or "/usr/bin/objdump"
BUILDER_VERSION = "llm4decompile-objdump-program-v1"
FUNCTION_HEADER_RE = re.compile(
    r"^\s*[0-9a-fA-F]+\s+<(?P<name>[^>]+)>:\s*$"
)


class AssemblyBaselineError(RuntimeError):
    pass


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _version(executable: Path) -> str:
    process = subprocess.run(
        [str(executable), "--version"],
        capture_output=True,
        text=True,
        timeout=20,
        check=False,
    )
    lines = (process.stdout or process.stderr or "").splitlines()
    return lines[0][:500] if lines else f"exit={process.returncode}"


def clean_objdump_program(raw_objdump: str) -> str:
    """Apply the released LLM4Decompile assembly cleaning rule program-wide."""
    functions: list[list[str]] = []
    current: list[str] | None = None
    for line in raw_objdump.splitlines():
        header = FUNCTION_HEADER_RE.match(line)
        if header:
            if current:
                functions.append(current)
            current = [f"<{header.group('name')}>"]
            # The official prompt format includes a colon after the name.
            current[0] += ":"
            continue
        if current is None:
            continue
        columns = line.split("\t")
        if len(columns) < 3:
            continue
        instruction = "\t".join(columns[2:]).split("#", 1)[0].strip()
        if instruction:
            current.append(instruction)
    if current:
        functions.append(current)
    return "\n\n".join("\n".join(block) for block in functions).strip() + "\n"


def export_program_assembly(
    original_obfuscated_elf: str | os.PathLike[str],
    output_dir: str | os.PathLike[str],
    *,
    objdump: str | os.PathLike[str] = DEFAULT_OBJDUMP,
    timeout_seconds: float = 120,
) -> Path:
    """Disassemble the original ELF and persist an auditable representation."""
    target = Path(original_obfuscated_elf).resolve()
    if not target.is_file():
        raise AssemblyBaselineError(f"Assembly input ELF does not exist: {target}")
    if target.read_bytes()[:4] != b"\x7fELF":
        raise AssemblyBaselineError(f"Assembly input is not ELF: {target}")
    forbidden = ("_brightened", "_final", "_ref.bin", "recovered")
    if any(token in target.name.lower() for token in forbidden):
        raise AssemblyBaselineError(
            f"B2 must disassemble the original obfuscated ELF: {target.name}"
        )

    executable = Path(objdump).resolve()
    if not executable.is_file():
        raise AssemblyBaselineError(f"objdump not found: {executable}")

    output = Path(output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    raw_path = output / "objdump_raw.txt"
    stderr_path = output / "objdump_stderr.log"
    assembly_path = output / "objdump_original_program.s"
    command = [str(executable), "-d", str(target)]
    started = time.perf_counter()
    try:
        process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise AssemblyBaselineError(
            f"objdump timed out after {timeout_seconds}s"
        ) from exc

    raw_path.write_text(process.stdout or "", encoding="utf-8")
    stderr_path.write_text(process.stderr or "", encoding="utf-8")
    if process.returncode != 0:
        raise AssemblyBaselineError(
            f"objdump failed with exit={process.returncode}; see {stderr_path}"
        )
    assembly = clean_objdump_program(process.stdout or "")
    # The evaluation corpus contains stripped ELF files.  Their entry code is
    # emitted as `<.text>` rather than `<main>`, so requiring a symbol named
    # main rejects valid program-level assembly before the model sees it.
    has_function_block = any(
        line.startswith("<") and line.endswith(":")
        for line in assembly.splitlines()
    )
    if not has_function_block:
        raise AssemblyBaselineError("Program assembly contains no disassembled text block")
    assembly_path.write_text(assembly, encoding="utf-8")

    manifest = {
        "builder_version": BUILDER_VERSION,
        "source_kind": "original_obfuscated_elf",
        "source_path": str(target),
        "source_sha256": _sha256(target),
        "representation_path": str(assembly_path),
        "representation_sha256": _sha256(assembly_path),
        "raw_objdump_path": str(raw_path),
        "raw_objdump_sha256": _sha256(raw_path),
        "objdump_path": str(executable),
        "objdump_version": _version(executable),
        "command": command,
        "function_count": sum(line.startswith("<") and line.endswith(":") for line in assembly.splitlines()),
        "instruction_count": sum(bool(line) and not line.startswith("<") for line in assembly.splitlines()),
        "cleaning_policy": (
            "LLM4Decompile released objdump cleaner: remove address/machine-byte "
            "columns and # comments; program-level extension keeps every function"
        ),
        "paper": "https://arxiv.org/abs/2403.05286v3",
        "official_implementation": "https://github.com/albertan017/LLM4Decompile",
        "duration_seconds": time.perf_counter() - started,
        "forbidden_upstream_artifacts": list(forbidden),
    }
    temporary = output / "representation_manifest.json.tmp"
    temporary.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    os.replace(temporary, output / "representation_manifest.json")
    return assembly_path
