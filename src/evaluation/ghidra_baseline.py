"""Build and validate B0's Ghidra-only representation."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path


DEFAULT_GHIDRA_HEADLESS = "/opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless"
BUILDER_VERSION = "b0-ghidra-original-program-v1"


class GhidraBaselineError(RuntimeError):
    pass


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _version(executable: Path) -> str:
    process = subprocess.run(
        [str(executable), "-version"],
        capture_output=True,
        text=True,
        timeout=20,
        check=False,
    )
    lines = (process.stdout or process.stderr or "").splitlines()
    return lines[0][:500] if lines else f"exit={process.returncode}"


def export_program_pseudocode(
    original_obfuscated_elf: str | os.PathLike[str],
    output_dir: str | os.PathLike[str],
    *,
    ghidra_headless: str | os.PathLike[str] = DEFAULT_GHIDRA_HEADLESS,
    timeout_seconds: float = 600,
) -> Path:
    """Decompile the original ELF and persist an auditable B0 manifest."""

    target = Path(original_obfuscated_elf).resolve()
    if not target.is_file():
        raise GhidraBaselineError(f"B0 input ELF does not exist: {target}")
    if target.read_bytes()[:4] != b"\x7fELF":
        raise GhidraBaselineError(f"B0 input is not an ELF binary: {target}")
    forbidden = ("_brightened", "_final", "_ref.bin", "recovered")
    if any(token in target.name.lower() for token in forbidden):
        raise GhidraBaselineError(
            f"B0 must decompile the original obfuscated ELF, got: {target.name}"
        )

    ghidra = Path(ghidra_headless).resolve()
    if not ghidra.is_file():
        raise GhidraBaselineError(f"Ghidra analyzeHeadless not found: {ghidra}")

    script = Path(__file__).resolve().parent / "ghidra" / "ExportProgramDecomp.java"
    output = Path(output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    pseudocode = output / "ghidra_original_program.c"
    stdout_log = output / "ghidra_stdout.log"
    stderr_log = output / "ghidra_stderr.log"

    started = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="b0-ghidra-", dir=output) as project:
        command = [
            str(ghidra),
            project,
            "b0_project",
            "-import",
            str(target),
            "-overwrite",
            "-scriptPath",
            str(script.parent),
            "-postScript",
            script.name,
            str(pseudocode),
            "-deleteProject",
        ]
        try:
            process = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=timeout_seconds,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise GhidraBaselineError(f"Ghidra timed out after {timeout_seconds}s") from exc

    stdout_log.write_text(process.stdout or "", encoding="utf-8")
    stderr_log.write_text(process.stderr or "", encoding="utf-8")
    if process.returncode != 0 or not pseudocode.is_file() or not pseudocode.stat().st_size:
        raise GhidraBaselineError(
            f"Ghidra failed with exit={process.returncode}; see {stderr_log}"
        )
    text = pseudocode.read_text(encoding="utf-8", errors="replace")
    if "// Function:" not in text:
        raise GhidraBaselineError("Ghidra export contains no program function")

    manifest = {
        "builder_version": BUILDER_VERSION,
        "source_kind": "original_obfuscated_elf",
        "source_path": str(target),
        "source_sha256": _sha256(target),
        "representation_path": str(pseudocode),
        "representation_sha256": _sha256(pseudocode),
        "script_sha256": _sha256(script),
        "ghidra_path": str(ghidra),
        "ghidra_version": _version(ghidra),
        "function_count": text.count("// Function:"),
        "failed_decompilations": text.count("GHIDRA_DECOMPILE_FAILED"),
        "duration_seconds": time.perf_counter() - started,
        "command": command,
        "forbidden_upstream_artifacts": list(forbidden),
    }
    temporary = output / "representation_manifest.json.tmp"
    temporary.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    os.replace(temporary, output / "representation_manifest.json")
    return pseudocode
