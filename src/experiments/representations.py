from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any, Dict

from binary_lifting.lifting import (
    MCSEMA_DISASS_MAIN,
    MCSEMA_LIFT,
    REMILL_BIN,
    lift_binary,
)

from .enums import MethodId
from .models import RepresentationArtifact, SampleIdentity
from .storage import (
    atomic_write_json,
    sha256_file,
    stable_json_sha256,
)


class RepresentationError(RuntimeError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def _tool_version(command: list[str]) -> str:
    try:
        process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        text = (process.stdout or process.stderr or "").strip().splitlines()
        return text[0][:500] if text else f"exit={process.returncode}"
    except Exception as exc:
        return f"unavailable: {exc}"


def _safe_tool_hash(path: str | Path) -> str:
    target = Path(path)
    return sha256_file(target) if target.is_file() else "missing"


class RawLiftService:
    """Experiment-local, provenance-checked raw lifting cache."""

    VERSION = "raw-lift-v2"

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.project_root = Path(config["_project_root"])
        self.cache_root = self.project_root / "result" / ".lifting_cache_v2"

    def _cache_key(self, sample: SampleIdentity) -> tuple[str, Dict[str, Any]]:
        paths = self.config["paths"]
        llvm_dis = paths["llvm_dis"]
        payload = {
            "builder_version": self.VERSION,
            "original_elf_sha256": sample.original_elf_sha256,
            "architecture": sample.architecture,
            "os": "linux",
            "entrypoint": "main",
            "mcsema_lift_path": str(Path(MCSEMA_LIFT).resolve()),
            "mcsema_lift_sha256": _safe_tool_hash(MCSEMA_LIFT),
            "mcsema_disass_sha256": _safe_tool_hash(MCSEMA_DISASS_MAIN),
            "disassembler_path": paths["ida_disassembler"],
            "disassembler_sha256": _safe_tool_hash(
                paths["ida_disassembler"]
            ),
            "remill_lift_sha256": _safe_tool_hash(
                Path(REMILL_BIN) / "remill-lift-10.0"
            ),
            "llvm_dis_path": llvm_dis,
            "llvm_dis_version": _tool_version([llvm_dis, "--version"]),
        }
        return stable_json_sha256(payload), payload

    def build(self, sample: SampleIdentity, output_dir: str | Path) -> Dict[str, Any]:
        output = Path(output_dir)
        output.mkdir(parents=True, exist_ok=True)
        raw_bc = output / "raw.bc"
        raw_ll = output / "raw.ll"
        raw_cfg = output / "raw.cfg"
        cache_key, provenance = self._cache_key(sample)
        cache_dir = self.cache_root / cache_key
        cache_manifest = cache_dir / "manifest.json"

        # Prefer a complete, provenance-checked artifact already materialized
        # in this run. This is the safest resume path after an interrupted
        # preparation: it avoids relifting even when the global cache entry was
        # not written before the interruption.
        local_manifest_path = output / "raw_lift_manifest.json"
        if self.config["p0"].get("use_lifting_cache", True) and local_manifest_path.is_file():
            try:
                local = json.loads(local_manifest_path.read_text(encoding="utf-8"))
                local_bc = Path(str(local.get("raw_bc_path") or raw_bc))
                local_ll = Path(str(local.get("raw_ll_path") or raw_ll))
                if not local_bc.is_absolute():
                    local_bc = output / local_bc
                if not local_ll.is_absolute():
                    local_ll = output / local_ll
                if (
                    local.get("original_elf_sha256") == sample.original_elf_sha256
                    and local.get("cache_key") == cache_key
                    and local_bc.is_file()
                    and local_ll.is_file()
                    and sha256_file(local_bc) == local.get("raw_bc_sha256")
                    and sha256_file(local_ll) == local.get("raw_ll_sha256")
                ):
                    print(
                        f"[cache] raw-lift RUN HIT sample={sample.sample_id} "
                        f"key={cache_key[:12]}",
                        flush=True,
                    )
                    if local_bc != raw_bc:
                        shutil.copy2(local_bc, raw_bc)
                    if local_ll != raw_ll:
                        shutil.copy2(local_ll, raw_ll)
                    local_cfg = Path(str(local.get("raw_cfg_path") or ""))
                    if local_cfg and not local_cfg.is_absolute():
                        local_cfg = output / local_cfg
                    result = dict(local)
                    result.update({
                        "raw_bc_path": str(raw_bc),
                        "raw_ll_path": str(raw_ll),
                        "raw_cfg_path": str(raw_cfg) if raw_cfg.exists() else None,
                        "cache_hit": True,
                        "cache_key": cache_key,
                    })
                    atomic_write_json(local_manifest_path, result)
                    return result
            except (OSError, ValueError, TypeError):
                pass

        if (
            self.config["p0"].get("use_lifting_cache", True)
            and cache_manifest.is_file()
        ):
            try:
                manifest = json.loads(cache_manifest.read_text(encoding="utf-8"))
                cached_bc = cache_dir / "raw.bc"
                cached_ll = cache_dir / "raw.ll"
                cached_cfg = cache_dir / "raw.cfg"
                if (
                    cached_bc.is_file()
                    and cached_ll.is_file()
                    and sha256_file(cached_bc) == manifest["raw_bc_sha256"]
                    and sha256_file(cached_ll) == manifest["raw_ll_sha256"]
                ):
                    print(
                        f"[cache] raw-lift HIT sample={sample.sample_id} "
                        f"key={cache_key[:12]}",
                        flush=True,
                    )
                    shutil.copy2(cached_bc, raw_bc)
                    shutil.copy2(cached_ll, raw_ll)
                    if cached_cfg.is_file():
                        shutil.copy2(cached_cfg, raw_cfg)
                    result = dict(manifest)
                    result.update(
                        {
                            "raw_bc_path": str(raw_bc),
                            "raw_ll_path": str(raw_ll),
                            "raw_cfg_path": str(raw_cfg) if raw_cfg.exists() else None,
                            "cache_hit": True,
                            "cache_key": cache_key,
                        }
                    )
                    atomic_write_json(output / "raw_lift_manifest.json", result)
                    return result
            except (OSError, ValueError, KeyError):
                pass

        print(
            f"[cache] raw-lift MISS sample={sample.sample_id} "
            f"key={cache_key[:12]} -> running McSema",
            flush=True,
        )
        started = time.perf_counter()
        ok = lift_binary(
            binary_path=sample.original_elf_path,
            disassembler=self.config["paths"]["ida_disassembler"],
            output=str(raw_bc),
            arch=sample.architecture,
            os_name="linux",
            entrypoint="main",
            use_cache=False,
            force_relift=True,
        )
        duration_ms = int((time.perf_counter() - started) * 1000)
        # lift_binary derives raw.ll/raw.cfg from the output BC stem.
        if not ok:
            raise RepresentationError("RAW_LIFT_FAILED", "McSema raw lift failed")
        if not raw_bc.is_file():
            raise RepresentationError(
                "RAW_BC_MISSING", "McSema reported success without raw.bc"
            )
        if not raw_ll.is_file():
            raise RepresentationError(
                "RAW_LL_MISSING", "llvm-dis did not produce raw.ll"
            )

        manifest = {
            **provenance,
            "cache_key": cache_key,
            "cache_hit": False,
            "raw_bc_path": str(raw_bc),
            "raw_ll_path": str(raw_ll),
            "raw_cfg_path": str(raw_cfg) if raw_cfg.exists() else None,
            "raw_bc_sha256": sha256_file(raw_bc),
            "raw_ll_sha256": sha256_file(raw_ll),
            "duration_ms": duration_ms,
            "pass_pipeline": [],
            "optimization_level": "none",
            "command_trace": [
                "mcsema-disass --entrypoint main",
                "mcsema-lift-10.0",
                f"{self.config['paths']['llvm_dis']} raw.bc -o raw.ll",
            ],
        }
        atomic_write_json(output / "raw_lift_manifest.json", manifest)
        if self.config["p0"].get("use_lifting_cache", True):
            cache_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(raw_bc, cache_dir / "raw.bc")
            shutil.copy2(raw_ll, cache_dir / "raw.ll")
            if raw_cfg.is_file():
                shutil.copy2(raw_cfg, cache_dir / "raw.cfg")
            cache_payload = dict(manifest)
            cache_payload["raw_bc_path"] = "raw.bc"
            cache_payload["raw_ll_path"] = "raw.ll"
            cache_payload["raw_cfg_path"] = "raw.cfg" if raw_cfg.exists() else None
            atomic_write_json(cache_manifest, cache_payload)
        return manifest


class A0Builder:
    VERSION = "a0-raw-ir-v1"

    def __init__(self, config: Dict[str, Any], lift_service: RawLiftService):
        self.config = config
        self.lift_service = lift_service

    def build(
        self,
        sample: SampleIdentity,
        common_dir: str | Path,
        output_dir: str | Path,
    ) -> RepresentationArtifact:
        common_raw = Path(common_dir) / "raw_lift"
        lift = self.lift_service.build(sample, common_raw)
        output = Path(output_dir)
        output.mkdir(parents=True, exist_ok=True)
        raw_bc = output / "raw.bc"
        raw_ll = output / "raw.ll"
        shutil.copy2(lift["raw_bc_path"], raw_bc)
        shutil.copy2(lift["raw_ll_path"], raw_ll)
        trace = "\n".join(lift.get("command_trace") or [])
        forbidden = [
            token
            for token in (" opt ", "brighten", "ghidra", "default<o")
            if token in f" {trace.lower()} "
        ]
        if forbidden:
            raise RepresentationError(
                "A0_FORBIDDEN_PASS_EXECUTED",
                f"A0 command trace is contaminated: {forbidden}",
            )
        text = raw_ll.read_text(encoding="utf-8", errors="replace")
        artifact = RepresentationArtifact(
            method=MethodId.A0,
            primary_path=str(raw_ll),
            primary_sha256=sha256_file(raw_ll),
            byte_count=raw_ll.stat().st_size,
            token_count=max(1, (len(text.encode("utf-8")) + 2) // 3),
            builder_version=self.VERSION,
            attachment_paths=[str(raw_ll)],
            attachment_sha256=[sha256_file(raw_ll)],
            tool_versions={
                "llvm_dis": lift.get("llvm_dis_version", "unknown"),
                "mcsema": lift.get("mcsema_lift_sha256", "unknown"),
            },
            provenance={
                "source_kind": "raw_mcsema_ir",
                "source_sha256": sample.original_elf_sha256,
                "raw_bc_sha256": sha256_file(raw_bc),
                "pass_pipeline": [],
                "optimization_level": "none",
                "raw_lift_cache_key": lift["cache_key"],
            },
            evidence_byte_count=raw_ll.stat().st_size,
            evidence_token_count=max(
                1, (len(text.encode("utf-8")) + 2) // 3
            ),
        )
        atomic_write_json(output / "representation_manifest.json", artifact.to_dict())
        return artifact


class B0Builder:
    VERSION = "b0-ghidra-original-v1"

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.project_root = Path(config["_project_root"])
        self.cache_root = self.project_root / "result" / ".b0_cache_v1"
        self.script = (
            Path(__file__).resolve().parent
            / "ghidra"
            / "ExportProgramDecomp.java"
        )

    def build(
        self,
        sample: SampleIdentity,
        output_dir: str | Path,
    ) -> RepresentationArtifact:
        target = Path(sample.original_elf_path).resolve()
        if not target.is_file():
            raise RepresentationError("B0_ELF_NOT_FOUND", f"Missing ELF: {target}")
        if sha256_file(target) != sample.original_elf_sha256:
            raise RepresentationError(
                "B0_ELF_HASH_MISMATCH", "Original ELF changed after enrolment"
            )
        if "_brightened" in target.name or "_ref.bin" in target.name:
            raise RepresentationError(
                "B0_WRONG_DECOMPILE_TARGET", f"Forbidden B0 target: {target}"
            )
        ghidra = Path(self.config["paths"]["ghidra_headless"])
        if not ghidra.is_file():
            raise RepresentationError(
                "B0_GHIDRA_NOT_FOUND", f"Missing analyzeHeadless: {ghidra}"
            )
        output = Path(output_dir)
        output.mkdir(parents=True, exist_ok=True)
        pseudo = output / "ghidra_original_program.c"
        cache_payload = {
            "builder_version": self.VERSION,
            "source_sha256": sample.original_elf_sha256,
            "ghidra_path": str(ghidra.resolve()),
            "ghidra_version": _tool_version([str(ghidra), "-version"]),
            "script_sha256": sha256_file(self.script),
            "export_config": self.config["representation"]["b0"],
            "runtime_filter_rules": [
                "external-memory-block bodies become prototypes",
                "thunk bodies become prototypes",
                "global data limited to .rodata/.data/.bss/.got/.got.plt",
            ],
        }
        cache_key = stable_json_sha256(cache_payload)
        cache_dir = self.cache_root / cache_key
        cache_manifest_path = cache_dir / "manifest.json"
        cached_pseudo = cache_dir / "ghidra_original_program.c"
        if (
            self.config["representation"]["b0"].get("use_cache", True)
            and cache_manifest_path.is_file()
            and cached_pseudo.is_file()
        ):
            try:
                cached_manifest = json.loads(
                    cache_manifest_path.read_text(encoding="utf-8")
                )
                if (
                    cached_manifest.get("source_sha256")
                    == sample.original_elf_sha256
                    and cached_manifest.get("representation_sha256")
                    == sha256_file(cached_pseudo)
                ):
                    print(
                        f"[cache] B0-pseudocode HIT sample={sample.sample_id} "
                        f"key={cache_key[:12]}",
                        flush=True,
                    )
                    shutil.copy2(cached_pseudo, pseudo)
                    text = pseudo.read_text(encoding="utf-8", errors="replace")
                    artifact = RepresentationArtifact(
                        method=MethodId.B0,
                        primary_path=str(pseudo),
                        primary_sha256=sha256_file(pseudo),
                        byte_count=pseudo.stat().st_size,
                        token_count=max(
                            1, (len(text.encode("utf-8")) + 2) // 3
                        ),
                        builder_version=self.VERSION,
                        attachment_paths=[str(pseudo)],
                        attachment_sha256=[sha256_file(pseudo)],
                        tool_versions={
                            "ghidra": cache_payload["ghidra_version"]
                        },
                        provenance={
                            **cached_manifest,
                            "cache_hit": True,
                            "cache_key": cache_key,
                            "source_path": str(target),
                        },
                        evidence_byte_count=pseudo.stat().st_size,
                        evidence_token_count=max(
                            1, (len(text.encode("utf-8")) + 2) // 3
                        ),
                    )
                    atomic_write_json(
                        output / "representation_manifest.json",
                        artifact.to_dict(),
                    )
                    return artifact
            except (OSError, ValueError, KeyError):
                pass
        print(
            f"[cache] B0-pseudocode MISS sample={sample.sample_id} "
            f"key={cache_key[:12]} -> running Ghidra",
            flush=True,
        )
        stdout_log = output / "ghidra_stdout.log"
        stderr_log = output / "ghidra_stderr.log"
        started = time.perf_counter()
        with tempfile.TemporaryDirectory(
            prefix="b0_ghidra_", dir=str(output)
        ) as project_dir:
            command = [
                str(ghidra),
                project_dir,
                "b0_project",
                "-import",
                str(target),
                "-overwrite",
                "-scriptPath",
                str(self.script.parent),
                "-postScript",
                self.script.name,
                str(pseudo),
                "-deleteProject",
            ]
            try:
                process = subprocess.run(
                    command,
                    capture_output=True,
                    text=True,
                    timeout=float(
                        self.config["representation"]["b0"]["ghidra_timeout_sec"]
                    ),
                    check=False,
                )
            except subprocess.TimeoutExpired as exc:
                raise RepresentationError(
                    "B0_GHIDRA_FAILED", f"Ghidra timed out: {exc}"
                ) from exc
        stdout_log.write_text(process.stdout or "", encoding="utf-8")
        stderr_log.write_text(process.stderr or "", encoding="utf-8")
        if process.returncode != 0 or not pseudo.is_file() or not pseudo.stat().st_size:
            raise RepresentationError(
                "B0_GHIDRA_FAILED",
                f"Ghidra exit={process.returncode}; see {stderr_log}",
            )
        text = pseudo.read_text(encoding="utf-8", errors="replace")
        if "// Function:" not in text:
            raise RepresentationError(
                "B0_NO_PROGRAM_PSEUDOCODE", "Ghidra export contains no function"
            )
        failed = text.count("GHIDRA_DECOMPILE_FAILED")
        artifact = RepresentationArtifact(
            method=MethodId.B0,
            primary_path=str(pseudo),
            primary_sha256=sha256_file(pseudo),
            byte_count=pseudo.stat().st_size,
            token_count=max(1, (len(text.encode("utf-8")) + 2) // 3),
            builder_version=self.VERSION,
            attachment_paths=[str(pseudo)],
            attachment_sha256=[sha256_file(pseudo)],
            tool_versions={
                "ghidra": _tool_version([str(ghidra), "-version"]),
            },
            provenance={
                "source_kind": "original_obfuscated_elf",
                "source_path": str(target),
                "source_sha256": sample.original_elf_sha256,
                "script_sha256": sha256_file(self.script),
                "function_count": text.count("// Function:"),
                "failed_decompilations": failed,
                "command": command,
                "duration_ms": int((time.perf_counter() - started) * 1000),
                "cache_hit": False,
                "cache_key": cache_key,
            },
            evidence_byte_count=pseudo.stat().st_size,
            evidence_token_count=max(
                1, (len(text.encode("utf-8")) + 2) // 3
            ),
        )
        atomic_write_json(output / "representation_manifest.json", artifact.to_dict())
        if self.config["representation"]["b0"].get("use_cache", True):
            cache_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(pseudo, cached_pseudo)
            atomic_write_json(
                cache_manifest_path,
                {
                    **cache_payload,
                    "cache_key": cache_key,
                    "representation_sha256": artifact.primary_sha256,
                    "function_count": artifact.provenance["function_count"],
                    "failed_decompilations": failed,
                },
            )
        return artifact
