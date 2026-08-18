"""Runtime helpers and candidate-producing actions for certification."""

from __future__ import annotations

import contextlib
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Callable, Sequence

SCRIPT_DIR = Path(__file__).resolve().parent
SRC_ROOT = SCRIPT_DIR.parent
PROJECT_ROOT = SRC_ROOT.parent
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from llvm_pass.certification import (
    ActionResult,
    CertificationPolicy,
    Decision,
    PROTOCOL_VERSION,
    atomic_copy,
    sha256_file,
)

_SEED_SUFFIXES = {".seed", ".txt", ".in", ".input"}

def _find_tool(names: Sequence[str]) -> str | None:
    for name in names:
        path = shutil.which(name)
        if path:
            return path
    return None


def _tool_version(tool: str | None) -> str | None:
    if tool is None:
        return None
    try:
        completed = subprocess.run(
            [tool, "--version"], capture_output=True, text=True, timeout=10
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    text = (completed.stdout or completed.stderr or "").strip()
    return text.splitlines()[0] if text else None


def _run_logged(
    command: Sequence[str],
    *,
    stdout_path: Path,
    stderr_path: Path,
    timeout: float,
) -> subprocess.CompletedProcess[str] | None:
    stdout_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        completed = subprocess.run(
            list(command), capture_output=True, text=True, timeout=timeout
        )
    except subprocess.TimeoutExpired as exc:
        stdout_path.write_text(exc.stdout or "", encoding="utf-8")
        stderr_path.write_text(
            (exc.stderr or "") + f"\ncommand timed out after {timeout}s\n",
            encoding="utf-8",
        )
        return None
    except OSError as exc:
        stdout_path.write_text("", encoding="utf-8")
        stderr_path.write_text(f"{exc}\n", encoding="utf-8")
        return None
    stdout_path.write_text(completed.stdout or "", encoding="utf-8")
    stderr_path.write_text(completed.stderr or "", encoding="utf-8")
    return completed


def _git_snapshot(project_root: Path) -> dict[str, Any]:
    def run(*args: str) -> str | None:
        try:
            completed = subprocess.run(
                ["git", "-C", str(project_root), *args],
                capture_output=True,
                text=True,
                timeout=10,
            )
        except (OSError, subprocess.TimeoutExpired):
            return None
        if completed.returncode != 0:
            return None
        return (completed.stdout or "").strip()

    status = run("status", "--porcelain=v1")
    return {
        "commit": run("rev-parse", "HEAD"),
        "branch": run("rev-parse", "--abbrev-ref", "HEAD"),
        "dirty": bool(status) if status is not None else None,
        "status": status.splitlines() if status else [],
    }


def _brightening_snapshot() -> dict[str, Any]:
    try:
        from llvm_pass import britening_ir
    except Exception as exc:
        return {"available": False, "error": f"{type(exc).__name__}: {exc}"}

    plugins: list[dict[str, Any]] = []
    for relative in getattr(britening_ir, "PLUGINS", []):
        path = (SCRIPT_DIR / relative).resolve()
        plugins.append(
            {
                "relative_path": relative,
                "path": str(path),
                "exists": path.is_file(),
                "sha256": sha256_file(path),
            }
        )
    return {
        "available": True,
        "selected_optimization_level": os.environ.get("BRIGHTEN_OPT_LEVEL", "O3"),
        "pass_pipeline": getattr(britening_ir, "PASS_PIPELINE", None),
        "plugins": plugins,
    }


def _environment_snapshot() -> dict[str, str]:
    prefixes = ("BRIGHTEN_", "DELIFT_")
    exact = {
        "OPT_BIN",
        "CLANG_BIN",
        "NM_BIN",
        "DEOBF_PLUGIN",
        "NATIVE_CLEANUP_PLUGIN",
        "MCSEMA_RUNTIME_LIB",
    }
    return {
        key: value
        for key, value in sorted(os.environ.items())
        if key.startswith(prefixes) or key in exact
    }


def _load_protocol(path: Path) -> tuple[CertificationPolicy, dict[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError("certification protocol must be a JSON object")
    if payload.get("protocol_version") != PROTOCOL_VERSION:
        raise ValueError(
            "protocol version mismatch: "
            f"expected {PROTOCOL_VERSION!r}, got {payload.get('protocol_version')!r}"
        )
    policy = CertificationPolicy.from_mapping(payload)
    return policy, payload


def _load_domain_contract(path: Path | None) -> dict[str, Any] | None:
    if path is None:
        return None
    with path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError("domain contract must be a JSON object")
    return payload


def _seed_paths(seed_files: Sequence[Path], seed_dir: Path | None) -> list[Path]:
    paths: list[Path] = []
    for path in seed_files:
        if not path.is_file():
            raise FileNotFoundError(f"seed file does not exist: {path}")
        paths.append(path.resolve())
    if seed_dir is not None:
        if not seed_dir.is_dir():
            raise FileNotFoundError(f"seed directory does not exist: {seed_dir}")
        paths.extend(
            path.resolve()
            for path in sorted(seed_dir.iterdir())
            if path.is_file() and path.suffix.lower() in _SEED_SUFFIXES
        )
    # Stable path order plus exact-path deduplication.
    return list(dict.fromkeys(paths))


def _read_seed_payloads(
    seed_files: Sequence[Path], seed_dir: Path | None
) -> tuple[list[bytes], list[str]]:
    """Read and content-deduplicate the exact seed corpus."""

    payloads: list[bytes] = []
    sources: list[str] = []
    seen: set[bytes] = set()
    for path in _seed_paths(seed_files, seed_dir):
        payload = path.read_bytes() or b"0"
        if payload in seen:
            continue
        seen.add(payload)
        payloads.append(payload)
        sources.append(str(path))
    return payloads, sources


def _seed_manifest(seed_files: Sequence[Path], seed_dir: Path | None) -> list[dict[str, Any]]:
    return [
        {"path": str(path), "sha256": sha256_file(path), "size": path.stat().st_size}
        for path in _seed_paths(seed_files, seed_dir)
    ]


def _corpus_sha256(payloads: Sequence[bytes]) -> str:
    """Hash an ordered byte corpus without concatenation ambiguity."""

    digest = hashlib.sha256()
    for payload in payloads:
        digest.update(len(payload).to_bytes(8, byteorder="big", signed=False))
        digest.update(payload)
    return digest.hexdigest()


def make_brighten_action(reference: Path | None) -> Callable:
    def action(input_path: Path, candidate_path: Path, stage_dir: Path) -> ActionResult:
        from llvm_pass.britening_ir import brighten_ir

        output_bc = stage_dir / "brightened.bc"
        output_ll = output_bc.with_suffix(".ll")
        stdout_path = stage_dir / "action.stdout.log"
        stderr_path = stage_dir / "action.stderr.log"
        for path in (output_bc, output_ll):
            try:
                path.unlink()
            except FileNotFoundError:
                pass

        command = [
            "python-call",
            "llvm_pass.britening_ir.brighten_ir",
            str(input_path),
            str(output_bc),
            str(reference) if reference else "",
        ]
        started = time.monotonic()
        with stdout_path.open("w", encoding="utf-8") as stdout_handle, stderr_path.open(
            "w", encoding="utf-8"
        ) as stderr_handle, contextlib.redirect_stdout(stdout_handle), contextlib.redirect_stderr(
            stderr_handle
        ):
            success = brighten_ir(
                str(input_path),
                str(output_bc),
                binary_path=str(reference) if reference else None,
            )

        if not success or not output_ll.is_file():
            return ActionResult(
                decision=Decision.FAIL,
                summary="main brightening pipeline did not produce LLVM assembly",
                command=command,
                stdout_path=str(stdout_path),
                stderr_path=str(stderr_path),
                metrics={"duration_ms": int((time.monotonic() - started) * 1000)},
            )

        atomic_copy(output_ll, candidate_path)
        return ActionResult(
            decision=Decision.PASS,
            summary="main brightening pipeline produced a fresh candidate",
            command=command,
            stdout_path=str(stdout_path),
            stderr_path=str(stderr_path),
            metrics={
                "duration_ms": int((time.monotonic() - started) * 1000),
                "bitcode": str(output_bc),
                "bitcode_sha256": sha256_file(output_bc),
            },
        )

    return action


def make_finalize_action(final_prefix: Path) -> Callable:
    def action(input_path: Path, candidate_path: Path, stage_dir: Path) -> ActionResult:
        from llvm_pass.britening_ir import finalize_ir

        stdout_path = stage_dir / "action.stdout.log"
        stderr_path = stage_dir / "action.stderr.log"
        for suffix in (
            ".ll",
            ".o",
            ".bin",
            "_delift_bundle.log",
            ".entrypoint-before-native.json",
            ".entrypoint-final.json",
        ):
            try:
                Path(f"{final_prefix}{suffix}").unlink()
            except FileNotFoundError:
                pass

        command = [
            "python-call",
            "llvm_pass.britening_ir.finalize_ir",
            str(input_path),
            str(final_prefix),
        ]
        started = time.monotonic()
        with stdout_path.open("w", encoding="utf-8") as stdout_handle, stderr_path.open(
            "w", encoding="utf-8"
        ) as stderr_handle, contextlib.redirect_stdout(stdout_handle), contextlib.redirect_stderr(
            stderr_handle
        ):
            output_ll, status, bundle_log = finalize_ir(
                str(input_path), str(final_prefix)
            )

        if output_ll is None or not Path(output_ll).is_file():
            return ActionResult(
                decision=Decision.FAIL,
                summary=f"delift bundle rejected candidate: {status}",
                command=command,
                stdout_path=str(stdout_path),
                stderr_path=str(stderr_path),
                metrics={
                    "duration_ms": int((time.monotonic() - started) * 1000),
                    "bundle_status": status,
                    "bundle_log": str(bundle_log),
                },
            )

        atomic_copy(output_ll, candidate_path)
        return ActionResult(
            decision=Decision.PASS,
            summary="delift bundle produced a fresh final candidate",
            command=command,
            stdout_path=str(stdout_path),
            stderr_path=str(stderr_path),
            metrics={
                "duration_ms": int((time.monotonic() - started) * 1000),
                "bundle_status": status,
                "bundle_log": str(bundle_log),
                "bundle_binary": str(final_prefix.with_suffix(".bin")),
            },
        )

    return action

