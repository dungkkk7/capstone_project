
"""LLM-assisted recovery of C source from brightened LLVM IR.

This module deliberately has no side effects on import.  The normal pipeline does
not import or call it unless the ``llm-recovery`` command mode is selected.

The default client is Vertex AI Gemini, as documented in ``LLM_api.md``.  The
client is imported lazily so normal lifting/brightening/fuzzing still works on
machines where the optional ``google-genai`` package is not installed.
"""

from __future__ import annotations

import codecs
import base64
import datetime as dt
import email.utils
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Mapping, Optional, Sequence

# Load prompts and model config from configs/prompts_config.py
try:
    import sys as _sys
    _cfg_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
    if _cfg_dir not in _sys.path:
        _sys.path.insert(0, _cfg_dir)
    import configs.prompts_config as _prompts_cfg
except Exception:
    _prompts_cfg = None  # type: ignore


P0_PROMPT_POLICY_VERSION = "p0-dual-evidence-consensus-repair-v4"


class RecoveryError(RuntimeError):
    """Raised when the LLM recovery backend cannot produce a usable result."""


class LLMContextOverflowError(RecoveryError):
    """The complete request cannot fit in the selected model context window."""


class LLMRateLimitError(RecoveryError):
    """Provider rejected an attempt because its request/token quota is exhausted."""

    def __init__(
        self,
        message: str,
        *,
        retry_after_seconds: Optional[float] = None,
        status_code: Optional[int] = None,
    ):
        super().__init__(message)
        self.retry_after_seconds = retry_after_seconds
        self.status_code = status_code


class LLMTransientError(RecoveryError):
    """A provider-side cancellation or temporary availability failure."""

    def __init__(
        self,
        message: str,
        *,
        status_code: Optional[int] = None,
    ):
        super().__init__(message)
        self.status_code = status_code


class LLMEmptyResponseError(RecoveryError):
    """Provider completed a generation but returned no usable text."""


@dataclass
class RecoveryConfig:
    """Runtime knobs for the recovery and validation loop."""

    model: str = field(default_factory=lambda: os.environ.get(
        "LLM_RECOVERY_MODEL",
        getattr(_prompts_cfg, "MODEL", "gemini-2.5-flash") if _prompts_cfg else "gemini-2.5-flash"
    ))
    project: Optional[str] = field(
        default_factory=lambda: os.environ.get("VERTEX_PROJECT")
        or os.environ.get("GOOGLE_CLOUD_PROJECT")
        or os.environ.get("GCLOUD_PROJECT")
    )
    # Gemini 3.5 Flash PayGo is exposed through global and multi-region
    # endpoints, not the legacy us-central1 regional endpoint.
    location: str = field(default_factory=lambda: os.environ.get("VERTEX_LOCATION", "global"))
    max_iterations: int = 5
    fuzz_iterations: int = field(
        default_factory=lambda: int(os.environ.get(
            "LLM_RECOVERY_FUZZ_ITERS",
            str(getattr(_prompts_cfg, "FUZZ_ITERATIONS", 1000))
        ))
    )
    fuzz_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_FUZZ_TIMEOUT", "0.1"))
    )
    # Source evidence is not text-truncated. Oversized dual evidence is scheduled
    # across pseudocode/IR rounds; one still-oversized source fails locally.
    max_ir_chars: Optional[int] = None
    temperature: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_TEMPERATURE", "0.05"))
    )
    top_p: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_TOP_P", "0.9"))
    )
    api_key: Optional[str] = field(
        default_factory=lambda: _optional_env("GEMINI_API_KEY")
        or _optional_env("GOOGLE_API_KEY")
        or (getattr(_prompts_cfg, "API_KEY", None) if _prompts_cfg else None)
    )
    # The experiment protocol permits exactly one candidate per provider
    # response.  Keep this explicit instead of relying on provider defaults.
    candidate_count: int = 1
    # Gemini 2.5 Pro uses thinkingLevel rather than the older numeric
    # thinkingBudget. HIGH is the maximum documented effort level.
    thinking_level: Optional[str] = field(
        # HIGH can consume nearly the entire 65,535 output-token budget as
        # hidden thoughts, leaving only a few thousand tokens for C source.
        default_factory=lambda: _optional_env(
            "LLM_RECOVERY_THINKING_LEVEL", None
        )
    )
    llm_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_TIMEOUT", "900"))
    )
    use_file_api: bool = field(
        default_factory=lambda: _text(os.environ.get("LLM_RECOVERY_USE_FILE_API", "1")).lower()
        not in {"", "0", "false", "no", "off"}
    )
    # In pseudocode mode, LLVM2C output is the default model evidence. The
    # cleaned LLVM IR remains local unless this switch is explicitly enabled.
    attach_clean_ir: bool = False
    # Direct-IR flows must distinguish Raw IR from Clean IR in the prompt and
    # persisted evidence manifest. This does not alter the IR content.
    ir_representation: str = "clean"
    file_api_inline_max_bytes: Optional[int] = None
    request_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_REQUEST_TIMEOUT", "900"))
    )
    # Freeze the requested output budget from the experiment configuration.
    # This is independent of the recovery-loop bound in ``max_iterations``.
    max_output_tokens: Optional[int] = field(
        default_factory=lambda: int(
            os.environ.get(
                "LLM_RECOVERY_MAX_OUTPUT_TOKENS",
                str(getattr(_prompts_cfg, "MAX_OUTPUT_TOKENS", 8192))
                if _prompts_cfg
                else "8192",
            )
        )
    )
    context_window_tokens: Optional[int] = None
    context_safety_margin_tokens: int = 1024
    pseudo_backend: str = field(
        default_factory=lambda: _text(
            os.environ.get("LLM_RECOVERY_PSEUDO_BACKEND", "")
        ).lower().strip()
    )
    require_json: bool = field(
        default_factory=lambda: _text(os.environ.get("LLM_RECOVERY_REQUIRE_JSON", "0")).lower()
        not in {"", "0", "false", "no", "off"}
    )


@dataclass
class RecoveryResult:
    success: bool
    source_path: Optional[str]
    iterations: int
    compile_error: Optional[str] = None
    fuzz_report: Optional[Dict[str, Any]] = None


@dataclass
class RecoveryInput:
    """One CSV row.  ``ir_path`` may be absent when the row points to an ELF."""

    ir_path: Optional[str]
    original_binary_path: Optional[str]
    metadata: Dict[str, str] = field(default_factory=dict)


def _text(value: Any) -> str:
    return "" if value is None else str(value).strip()


def _optional_env(name: str, default: Optional[str] = None) -> Optional[str]:
    value = os.environ.get(name)
    if value is None:
        value = default
    text = _text(value)
    if text.lower() in {"", "0", "false", "no", "off", "none", "null"}:
        return None
    return text


def _resolve_path(value: str, base_dir: Path, fallback_dir: Optional[Path] = None) -> Optional[str]:
    value = _text(value)
    if not value:
        return None
    path = Path(value).expanduser()
    if not path.is_absolute():
        candidates = [base_dir / path]
        if fallback_dir is not None:
            candidates.append(fallback_dir / path)
        path = next((candidate for candidate in candidates if candidate.exists()), candidates[0])
    return str(path.resolve())


def _looks_like_llvm_type(token: str) -> bool:
    t = token.strip()
    if not t:
        return False
    if t in {"i1", "i8", "i16", "i32", "i64", "float", "double", "void", "ptr"}:
        return True
    if t.endswith("*") and (t[:-1] in {"i1", "i8", "i16", "i32", "i64", "float", "double", "void", "ptr"}):
        return True
    return bool(re.fullmatch(r"i\d+", t))


def _strip_llvm_type_prefix(text: str) -> str:
    token = _text(text)
    if not token:
        return token
    if token.startswith("%") or token.startswith("@"):
        return token
    if " " not in token:
        return token
    first, rest = token.split(None, 1)
    if _looks_like_llvm_type(first):
        return rest.strip()
    if first == "ptr":
        return rest.strip()
    return token


def _find_ida_binary(preferred: Optional[str] = None) -> Optional[str]:
    for candidate in _ida_binary_candidates(preferred):
        if os.path.isabs(candidate):
            if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
                return candidate
        else:
            found = shutil.which(candidate)
            if found:
                return found
    return None


def _ida_binary_candidates(preferred: Optional[str] = None) -> List[str]:
    candidates: List[str] = []
    if preferred:
        candidates.append(preferred)
    candidates.extend(
        [
            "/opt/ida-pro-9.3/idat",
            "/opt/ida-pro-9.3/ida64",
            "/opt/ida-pro-9.3/idat64",
            "/opt/ida-pro-9.3/idal64",
        ]
    )
    candidates.extend(
        [
            "/opt/idapro/idat",
            "/opt/idapro/ida64",
            "/usr/bin/idat",
            "/usr/bin/ida64",
            "idat",
            "ida64",
            "idal64",
        ]
    )
    unique = []
    for candidate in candidates:
        if not candidate or candidate in unique:
            continue
        unique.append(candidate)
    return unique


def _is_ida_pseudo_valid(pseudo: str) -> bool:
    pseudo_text = _text(pseudo)
    if not pseudo_text:
        return False
    if "/* No functions discovered by IDA */" in pseudo_text:
        return False
    if "/* HEX-RAYS unavailable in this IDA runtime */" in pseudo_text:
        return False
    if "/* IDA script error:" in pseudo_text:
        return False
    # Any non-empty Hex-Rays export from the validated binary is usable seed
    # context. The model decides how to reconstruct logic from that export.
    return bool(pseudo_text.strip())



def _decompiler_function_blocks(pseudo: str) -> tuple[str, List[tuple[str, str]]]:
    """Split a decompiler text export into a preamble and function blocks."""
    text = _text(pseudo).replace("\r\n", "\n")
    matches = list(re.finditer(r"(?m)^// Function:\s*([^\n]+)\s*$", text))
    if not matches:
        return text, []

    preamble = text[: matches[0].start()].strip()
    blocks: List[tuple[str, str]] = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        name = match.group(1).strip()
        blocks.append((name, text[match.start() : end].strip()))
    return preamble, blocks


def _looks_like_import_thunk(name: str, block: str) -> bool:
    """Recognize decompiler-generated PLT/import wrappers without trusting names alone."""
    lowered = block.lower()
    normalized_name = re.sub(r"[^a-z0-9_]", "_", name.lower())
    markers = (
        "halt_baddata",
        "bad instruction - truncating control flow",
        "control flow encountered bad instruction data",
        f"ptr_{normalized_name}_",
    )
    if any(marker in lowered for marker in markers):
        return True
    # Typical tiny PLT wrapper: one indirect call through PTR_* and a return.
    if "(*(code *)ptr_" in lowered and len(block.splitlines()) <= 18:
        return True
    return False


def _focus_decompiler_pseudocode(pseudo: str) -> str:
    """Keep semantic functions while removing deterministic runtime noise.

    This is intentionally conservative: unknown/custom helpers are retained.  Only
    well-known runtime functions and blocks that structurally look like import thunks
    are removed.  If filtering accidentally loses the entry point, the raw input is
    returned unchanged.
    """
    raw = _text(pseudo).replace("\r\n", "\n")
    preamble, blocks = _decompiler_function_blocks(raw)
    if not blocks:
        return raw + ("\n" if raw and not raw.endswith("\n") else "")

    runtime_noise = {
        "_init",
        ".init_proc",
        "_fini",
        "_start",
        "processentry",
        "deregister_tm_clones",
        "register_tm_clones",
        "__do_global_dtors_aux",
        "frame_dummy",
        "__gmon_start__",
        "__libc_start_main",
        "__cxa_finalize",
        "_itm_deregistertmclonetable",
        "_itm_registertmclonetable",
        "fun_00101020",
        "sub_1020",
    }

    kept: List[str] = []
    removed: List[str] = []
    seen_exact_blocks: set[str] = set()
    for name, block in blocks:
        normalized = name.strip().lower()
        block_key = re.sub(r"\s+", " ", block).strip()
        if block_key in seen_exact_blocks:
            removed.append(name)
            continue
        seen_exact_blocks.add(block_key)

        if normalized in runtime_noise:
            removed.append(name)
            continue
        if _looks_like_import_thunk(name, block):
            removed.append(name)
            continue

        # Remove standalone decompiler warning comments but retain the code itself.
        cleaned = re.sub(
            r"(?ms)^\s*/\* WARNING:.*?\*/\s*\n?",
            "",
            block,
        ).strip()
        if cleaned:
            kept.append(cleaned)

    focused_parts: List[str] = []
    include_lines = [
        line.strip()
        for line in preamble.splitlines()
        if line.strip().startswith("#include")
    ]
    if include_lines:
        focused_parts.append("\n".join(dict.fromkeys(include_lines)))
    focused_parts.append(
        "/* Deterministically focused decompiler evidence. Import thunks and CRT startup "
        "boilerplate were removed; unknown/custom functions were retained. */"
    )
    focused_parts.extend(kept)
    focused = "\n\n".join(part for part in focused_parts if part).strip()
    focused = re.sub(r"\n{4,}", "\n\n\n", focused)

    has_entry = bool(re.search(r"(?m)^// Function:\s*(?:main|native_entry_impl)\s*$", focused))
    if not has_entry:
        return raw + ("\n" if raw and not raw.endswith("\n") else "")
    return focused + "\n"


def _focus_ida_pseudocode(pseudo: str) -> str:
    """Backward-compatible alias; the same conservative cleanup works for IDA exports."""
    return _focus_decompiler_pseudocode(pseudo)


def _summarize_pseudocode_evidence(pseudo: str) -> str:
    """Create a literal, non-semantic inventory to orient the model before reconstruction."""
    text = _text(pseudo)
    _, blocks = _decompiler_function_blocks(text)
    function_names = [name for name, _ in blocks]

    call_names = sorted(
        {
            match.group(1)
            for match in re.finditer(
                r"\b(scanf|__isoc99_scanf|sscanf|printf|fprintf|puts|putchar|"
                r"malloc|calloc|realloc|free|qsort|strlen|strcmp|strncmp|memcpy|memset|"
                r"pow|trunc|hypot|sqrt|abort|exit)\s*\(",
                text,
            )
        }
    )
    string_literals = []
    for match in re.finditer(r'"(?:\\.|[^"\\])*"', text):
        literal = match.group(0)
        if literal not in string_literals:
            string_literals.append(literal)
        if len(string_literals) >= 20:
            break

    format_calls = []
    for match in re.finditer(
        r"\b(scanf|__isoc99_scanf|sscanf|printf|fprintf|puts)\s*\(([^\n;]{0,240})",
        text,
    ):
        item = f"{match.group(1)}({match.group(2).strip()}"
        if item not in format_calls:
            format_calls.append(item)
        if len(format_calls) >= 16:
            break

    counts = {
        "function_blocks": len(blocks),
        "frame_storage_refs": len(re.findall(r"frame_storage_backing_", text)),
        "brighten_pointer_calls": len(re.findall(r"\b__brighten_native_data_pointer\s*\(", text)),
        "dispatcher_labels": len(re.findall(r"(?m)^\s*LAB_[A-Za-z0-9_]+:\s*$", text)),
        "hex_constants": len(re.findall(r"\b0x[0-9a-fA-F]{6,}\b", text)),
    }

    lines = [
        "This inventory is mechanically extracted. It is orientation evidence, not an inferred algorithm:",
        "- function blocks: " + (", ".join(function_names[:40]) or "none detected"),
        "- observed library/API calls: " + (", ".join(call_names) or "none detected"),
        "- observed string literals: " + (", ".join(string_literals) or "none detected"),
        "- representative I/O call text: " + (" | ".join(format_calls) or "none detected"),
        "- artifact counts: " + ", ".join(f"{key}={value}" for key, value in counts.items()),
    ]
    return "\n".join(lines)


def _ensure_ida_d810_stub() -> Optional[str]:
    """Create a lightweight local `d810` package to avoid IDA startup import failure."""
    stub_root = os.path.join(tempfile.gettempdir(), "codex_ida_d810_stub")
    marker = os.path.join(stub_root, ".ready")
    if os.path.exists(marker):
        return stub_root

    try:
        package_root = os.path.join(stub_root, "d810")
        os.makedirs(package_root, exist_ok=True)
        os.makedirs(os.path.join(package_root, "_vendor"), exist_ok=True)
        os.makedirs(os.path.join(package_root, "core"), exist_ok=True)

        files = {
            os.path.join(package_root, "__init__.py"): '__version__ = "0.0.0"\n',
            os.path.join(package_root, "manager.py"): "class D810State:\n    pass\n",
            os.path.join(package_root, "_vendor", "__init__.py"): "# namespace package\n",
            os.path.join(package_root, "_vendor", "ida_reloader.py"): (
                "import contextlib\n"
                "\n"
                "def reload_package(*args, **kwargs):\n"
                "    return None\n"
                "\n"
                "class ReloadablePluginBase:\n"
                "    def __init__(self, *args, **kwargs):\n"
                "        pass\n"
                "\n"
                "    def init(self):\n"
                "        import idaapi\n"
                "        return idaapi.PLUGIN_SKIP\n"
                "\n"
                "    def late_init(self):\n"
                "        pass\n"
                "\n"
                "    def run(self, args):\n"
                "        pass\n"
                "\n"
                "    def term(self):\n"
                "        pass\n"
                "\n"
                "    @contextlib.contextmanager\n"
                "    def plugin_setup_reload(self):\n"
                "        yield\n"
            ),
            os.path.join(package_root, "core", "__init__.py"): "# namespace package\n",
            os.path.join(package_root, "core", "typing.py"): "def override(func):\n    return func\n",
        }
        for path, content in files.items():
            with open(path, "w", encoding="utf-8") as file_handle:
                file_handle.write(content)
        with open(marker, "w", encoding="utf-8") as marker_handle:
            marker_handle.write("ready")
        return stub_root
    except OSError:
        return None


def _decompile_binary_with_ida(binary_path: str, output_path: str, ida_binary: str, timeout: float) -> Optional[str]:
    """Run IDA in headless mode and extract decompiled pseudo C to `output_path`."""
    ida_binary = _text(ida_binary)
    binary_path = _text(binary_path)
    if not ida_binary:
        return None
    if not binary_path:
        return None
    if not os.path.isabs(binary_path):
        binary_path = os.path.abspath(binary_path)
    if not os.path.isfile(ida_binary) and not shutil.which(ida_binary):
        return None
    if not os.path.isfile(binary_path):
        return None
    if not os.path.exists(binary_path):
        return None
    output_dir = os.path.dirname(output_path)
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.abspath(output_path)
    if os.path.exists(output_path):
        try:
            os.remove(output_path)
        except OSError:
            pass

    script_content = f"""
import os

OUTPUT_PATH = {output_path!r}


def _main():
    def write_line(text):
        with open(OUTPUT_PATH, \"a\", encoding=\"utf-8\") as out:
            out.write(text + \"\\n\")

    write_line(\"#include <stdint.h>\\n#include <stdio.h>\\n#include <stdbool.h>\\n\")
    try:
        import ida_auto
        import ida_funcs
        import ida_hexrays
        import idautils

        try:
            ida_auto.auto_wait()
        except Exception:
            pass

        if not ida_hexrays.init_hexrays_plugin():
            write_line(\"/* HEX-RAYS unavailable in this IDA runtime */\")
            return

        funcs = list(idautils.Functions())
        if not funcs:
            write_line(\"/* No functions discovered by IDA */\")
            return

        for ea in funcs:
            try:
                cfunc = ida_hexrays.decompile(ea)
                code = str(cfunc)
            except Exception:
                continue
            name = ida_funcs.get_func_name(ea) or hex(ea)
            write_line("// Function: %s" % name)
            write_line(code)
            write_line("")

    except Exception:
        write_line("/* IDA script error */")


_main()
"""

    script_fd, script_path = tempfile.mkstemp(suffix=".py", prefix="ida_decompile_")
    log_fd, log_path = tempfile.mkstemp(suffix=".log", prefix="ida_decompile_")
    try:
        with os.fdopen(script_fd, "w", encoding="utf-8") as script_file:
            script_file.write(script_content)
    except Exception:
        os.close(script_fd)
        os.close(log_fd)
        return None

    env = os.environ.copy()
    stub_root = _ensure_ida_d810_stub()
    if stub_root:
        existing_pythonpath = env.get("PYTHONPATH", "")
        env["PYTHONPATH"] = os.pathsep.join([stub_root, existing_pythonpath]).strip(os.pathsep)

    ida_db_path = os.path.splitext(output_path)[0] + ".idb"

    def remove_ida_database_artifacts() -> None:
        db_base = os.path.splitext(output_path)[0]
        for suffix in (".i64", ".idb", ".id0", ".id1", ".id2", ".nam", ".til"):
            try:
                os.remove(db_base + suffix)
            except OSError:
                pass

    # Use Hex-Rays' official batch exporter. `ALL` exports every non-library,
    # non-trivial function and preserves the decompiler's complete output;
    # the old custom `idautils.Functions() + decompile(ea)` script missed
    # helper/data context and produced an incomplete recovery input.
    export_details = []
    for export_target in ("ALL", "native_entry_impl", "main"):
        remove_ida_database_artifacts()
        try:
            os.remove(output_path)
        except OSError:
            pass
        export_log_fd, export_log_path = tempfile.mkstemp(
            suffix=".log", prefix="ida_hexrays_export_"
        )
        os.close(export_log_fd)
        try:
            process = subprocess.run(
                [
                    ida_binary,
                    f"-o{ida_db_path}",
                    f"-Ohexrays:-nosave:{output_path}:{export_target}",
                    "-A",
                    f"-L{export_log_path}",
                    binary_path,
                ],
                capture_output=True,
                text=True,
                timeout=timeout,
                check=False,
                env=env,
            )
        except KeyboardInterrupt:
            raise
        except subprocess.TimeoutExpired as exc:
            export_details.append(f"{export_target}: timeout: {exc}")
            continue
        except Exception as exc:
            export_details.append(f"{export_target}: invocation failed: {exc}")
            continue
        finally:
            try:
                os.remove(export_log_path)
            except OSError:
                pass

        if os.path.isfile(output_path) and os.path.getsize(output_path):
            with open(output_path, "r", encoding="utf-8", errors="replace") as handle:
                out_text = handle.read()
            if out_text.strip():
                # Do not accept the tiny startup wrapper when Hex-Rays only
                # decompiled `main`; continue to the full export/fallback.
                main_thunk = re.search(
                    r"\bmain\s*\([^)]*\)\s*\{[^{}]*\bnative_entry_impl\s*\(",
                    out_text,
                    re.DOTALL,
                )
                native_body = re.search(
                    r"\bnative_entry_impl\s*\([^;]*\)\s*\{", out_text,
                    re.DOTALL,
                )
                if export_target == "main" and main_thunk and not native_body:
                    export_details.append("main: forwarding thunk only")
                    continue
                try:
                    os.remove(script_path)
                except OSError:
                    pass
                try:
                    os.close(log_fd)
                except OSError:
                    pass
                remove_ida_database_artifacts()
                return out_text.strip() + "\n"

        details = (process.stderr or process.stdout or "No stderr/stdout detail").strip()
        if process.returncode:
            details = f"IDA exited with code {process.returncode}: {details}"
        export_details.append(f"{export_target}: {details}")

    # If the official exporter cannot handle this database, continue to the
    # existing script path below so one problematic function does not disable
    # recovery entirely.
    remove_ida_database_artifacts()

    try:
        process = subprocess.run(
            [
                ida_binary,
                f"-o{ida_db_path}",
                "-A",
                f"-S{script_path}",
                f"-L{log_path}",
                binary_path,
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
            env=env,
        )
    except KeyboardInterrupt:
        raise
    except subprocess.TimeoutExpired as exc:
        raise RecoveryError(f"IDA decompile command timed out after {timeout}s: {exc}") from exc
    except Exception as exc:
        raise RecoveryError(f"Failed to invoke IDA: {exc}") from exc
    finally:
        try:
            os.remove(script_path)
        except OSError:
            pass
        try:
            os.close(log_fd)
        except OSError:
            pass

    if not os.path.isfile(output_path):
        stderr = (process.stderr or "").strip()
        stdout = (process.stdout or "").strip()
        details = stderr or stdout
        if not details:
            details = "No stderr/stdout detail"
        if os.path.isfile(log_path):
            try:
                log_text = Path(log_path).read_text(encoding="utf-8", errors="replace").strip()
                if log_text:
                    details = f"{details} | ida_log={log_text[:2000]}"
            except OSError:
                pass
            try:
                os.remove(log_path)
            except OSError:
                pass
        if process.returncode != 0:
            details = f"IDA exited with code {process.returncode}: {details}"
        raise RecoveryError(f"IDA decompile command did not produce output file: {output_path}. {details}")
    with open(output_path, "r", encoding="utf-8", errors="replace") as handle:
        out_text = handle.read()
    if os.path.isfile(log_path):
        try:
            os.remove(log_path)
        except OSError:
            pass
    if not out_text.strip():
        return None
    if "/* No functions discovered by IDA */" in out_text:
        return out_text.strip() + "\n"
    if "/* HEX-RAYS unavailable in this IDA runtime */" in out_text:
        raise RecoveryError("HEX-RAYS unavailable in this IDA runtime")
    if "/* IDA script error:" in out_text:
        raise RecoveryError("IDA script encountered an internal error while decompiling.")
    return out_text.strip() + "\n"


def read_recovery_csv(csv_path: str, project_root: str) -> List[RecoveryInput]:
    """Read both the current one-column CSV and explicit IR/binary columns.

    Supported headers include ``ir_path``/``llvm_ir``/``brightened_ir`` and
    ``binary_path``/``binary``.  With no header, the first column is treated as
    an IR file when it ends in ``.ll``/``.bc``; otherwise it is treated as the
    original binary.  A second column, when present, is used as the other path.
    """

    import csv

    path = Path(csv_path).expanduser().resolve()
    if not path.is_file():
        raise FileNotFoundError(f"Recovery input CSV not found: {path}")

    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = [row for row in csv.reader(handle) if any(_text(cell) for cell in row)]
    if not rows:
        return []

    aliases = {
        "ir": {"ir", "ir_path", "llvm_ir", "llvm_ir_path", "brightened_ir", "brightened_ir_path"},
        "binary": {"binary", "binary_path", "original_binary", "original_binary_path", "file", "path"},
    }
    header = [_text(cell).lower() for cell in rows[0]]
    has_header = any(cell in aliases["ir"] | aliases["binary"] for cell in header)
    if has_header:
        ir_index = next((i for i, cell in enumerate(header) if cell in aliases["ir"]), None)
        binary_index = next((i for i, cell in enumerate(header) if cell in aliases["binary"]), None)
        data_rows = rows[1:]
    else:
        ir_index = binary_index = None
        data_rows = rows

    inputs: List[RecoveryInput] = []
    for row in data_rows:
        if has_header:
            ir_value = row[ir_index] if ir_index is not None and ir_index < len(row) else ""
            binary_value = row[binary_index] if binary_index is not None and binary_index < len(row) else ""
        else:
            first = _text(row[0]) if row else ""
            second = _text(row[1]) if len(row) > 1 else ""
            if first.lower().endswith((".ll", ".bc")):
                ir_value, binary_value = first, second
            else:
                ir_value, binary_value = second, first

        root = Path(project_root).expanduser().resolve()
        ir_path = _resolve_path(ir_value, root, path.parent)
        binary_path = _resolve_path(binary_value, root, path.parent)
        if ir_path and not Path(ir_path).exists() and "define" in ir_value:
            # Inline IR is accepted for small unit tests; keep it in metadata.
            metadata = {"inline_ir": ir_value}
            ir_path = None
        else:
            metadata = {}
        if ir_path is None and binary_path is None and not metadata:
            continue
        inputs.append(RecoveryInput(ir_path, binary_path, metadata))
    return inputs



def build_system_prompt(
    attach_clean_ir: bool = False,
    *,
    evidence_mode: Optional[str] = None,
) -> str:
    selected_mode = _text(evidence_mode).lower() or (
        "dual" if attach_clean_ir else "single"
    )
    if selected_mode == "dual":
        mode_evidence = (
            "LLVM2C pseudocode and final cleaned/delifted LLVM IR are "
            "supplied as two representations. Treat both as first-class evidence "
            "and cross-check them before reconstructing source."
        )
    elif selected_mode == "pseudocode":
        mode_evidence = (
            "This request carries LLVM2C pseudocode generated from cleaned LLVM "
            "IR. No LLVM IR is supplied in this flow; do not invent absent IR."
        )
    elif selected_mode == "ghidra_pseudocode":
        mode_evidence = (
            "This request carries program-level Ghidra pseudocode exported from "
            "the original obfuscated ELF. No LLVM IR, source, tests or oracle are "
            "supplied; reconstruct only from that pseudocode and explicit "
            "validation feedback."
        )
    elif selected_mode == "assembly":
        mode_evidence = (
            "This request carries program-level AT&T assembly produced by the "
            "paper-derived objdump cleaner from the original obfuscated ELF. "
            "No pseudocode, LLVM IR, source, tests or oracle are supplied; "
            "reconstruct only from instructions, symbols, control/data flow "
            "and explicit validation feedback."
        )
    elif selected_mode == "llvm_ir":
        mode_evidence = (
            "This request carries LLVM IR evidence directly. It does not carry "
            "pseudocode; reconstruct and repair from exact IR semantics."
        )
    elif selected_mode == "raw_ir":
        mode_evidence = (
            "This request carries raw, non-deobfuscated LLVM IR directly. It "
            "does not carry Clean LLVM IR or pseudocode; reconstruct and repair "
            "from the supplied raw IR only."
        )
    else:
        mode_evidence = (
            "ONLY the complete model-input artifact declared in the user message "
            "is supplied. Do not assume hidden IR, executable bytes, source, or tests."
        )
    # Read from configs/prompts_config.py if available, else use built-in default
    if _prompts_cfg and hasattr(_prompts_cfg, "SYSTEM_PROMPT"):
        return _prompts_cfg.SYSTEM_PROMPT.replace("{MODE_EVIDENCE}", mode_evidence)
    # Built-in fallback (identical to configs/prompts_config.py content)
    return r"""You are a senior reverse engineer and C11 compiler engineer.
Recover exactly one standalone C11 translation unit whose observable behavior
matches the supplied artifact. Semantic fidelity is more important than
similarity to the unknown source or cosmetic cleanliness.

Evidence boundary:
- {MODE_EVIDENCE}

Final source requirements:
- Emit one complete standard C11 translation unit.
- Preserve exact parsing, output bytes/newlines, stderr, exit codes.
- The returned C must be independently compilable.

Mandatory response:
- Return the complete raw C11 source only.
- Do not return JSON, markdown fences, analysis, prose or patches.
""".replace("{MODE_EVIDENCE}", mode_evidence)

def _clip_ir(ir_text: str, max_chars: Optional[int] = None) -> str:
    if not max_chars or max_chars <= 0 or len(ir_text) <= max_chars:
        return ir_text
    head = max_chars * 3 // 4
    tail = max_chars - head
    return (
        ir_text[:head]
        + "\n\n; [IR truncated by adapter: omitted middle section]\n\n"
        + ir_text[-tail:]
    )



def _build_synthetic_icl_example(use_pseudo: bool) -> str:
    """Return one fixed, non-dataset semantic demonstration for the initial prompt."""
    if use_pseudo:
        return r"""<IN_CONTEXT_DEMO type="synthetic_llvm2c_pseudocode_to_c">
This demonstration is synthetic and is not evidence about the current case.

<DEMO_INPUT>
undefined8 main(void)
{
  int iVar1;
  long lVar2;
  int local_count;
  void *local_buf;

  local_buf = malloc(0x10);
  if (local_buf == (void *)0x0) return 3;
  local_count = 0;
  do {
    lVar2 = (long)local_count * 4 + (long)local_buf;
    scanf("%d",__brighten_native_data_pointer(lVar2));
    iVar1 = local_count + 1;
    local_count = iVar1;
  } while (iVar1 < 4);
  qsort(local_buf,4,4,compare_callback);
  local_count = 0;
  while (local_count < 4) {
    printf("%d\n",*(int *)((long)local_buf + (long)local_count * 4));
    local_count = local_count + 1;
  }
  free(local_buf);
  return 0;
}

int compare_callback(undefined8 a,undefined8 b)
{
  return *(int *)a - *(int *)b;
}
</DEMO_INPUT>

<DEMO_RECOVERED_C>
#include <stdio.h>
#include <stdlib.h>

static int compare_ints(const void *left, const void *right) {
    const int a = *(const int *)left;
    const int b = *(const int *)right;
    return a - b;
}

int main(void) {
    int *values = malloc(4 * sizeof(*values));
    if (values == NULL) return 3;

    for (int i = 0; i < 4; ++i) {
        scanf("%d", &values[i]);
    }
    qsort(values, 4, sizeof(*values), compare_ints);
    for (int i = 0; i < 4; ++i) {
        printf("%d\n", values[i]);
    }
    free(values);
    return 0;
}
</DEMO_RECOVERED_C>

The normalization is justified by complete def-use and call evidence. Do not copy its constants,
names, sizes, strings, or algorithm into the current case.
</IN_CONTEXT_DEMO>"""
    return r"""<IN_CONTEXT_DEMO type="synthetic_llvm_to_c">
This demonstration is synthetic and is not evidence about the current case.

<DEMO_INPUT>
@.demo_fmt = private unnamed_addr constant [4 x i8] c"%d\0A\00"
define i32 @main() {
entry:
  %value = add i32 7, 5
  call i32 (ptr, ...) @printf(ptr @.demo_fmt, i32 %value)
  ret i32 0
}
</DEMO_INPUT>

<DEMO_RECOVERED_C>
#include <stdio.h>

int main(void) {
    printf("%d\n", 12);
    return 0;
}
</DEMO_RECOVERED_C>

Do not copy its constants, strings, or logic into the current case.
</IN_CONTEXT_DEMO>"""
def build_initial_prompt(
    ir_text: str,
    metadata: Mapping[str, str],
    max_ir_chars: Optional[int] = None,
    use_pseudo: bool = False,
    seed_attached_file: bool = False,
    attached_evidence_label: str = (
        "COMPLETE MODEL INPUT ARTIFACT ATTACHED IN THIS REQUEST"
    ),
    dual_ir_text: Optional[str] = None,
    ir_representation: str = "clean",
) -> str:
    context_lines = []
    for key, value in metadata.items():
        if not _text(value):
            continue
        lowered = key.lower()
        if any(
            token in lowered
            for token in ("path", "file", "binary", "input_ir", "output")
        ):
            continue
        context_lines.append(f"- {key}: {value}")
    context = "\n".join(context_lines)

    if use_pseudo and dual_ir_text is not None:
        if seed_attached_file:
            pseudo_evidence = (
                "/* COMPLETE LLVM2C PSEUDOCODE ATTACHED IN THIS REQUEST */"
            )
            clean_ir_evidence = (
                "/* COMPLETE CLEANED LLVM IR ATTACHED IN THIS REQUEST */"
            )
        else:
            pseudo_evidence = ir_text
            clean_ir_evidence = _clip_ir(dual_ir_text, max_ir_chars)
        if _prompts_cfg and hasattr(
            _prompts_cfg,
            "PROMPT_CLEAN_IR_AND_PSEUDOCODE",
        ):
            return (
                _prompts_cfg.PROMPT_CLEAN_IR_AND_PSEUDOCODE.replace(
                    "{CLEAN_PSEUDOCODE}",
                    pseudo_evidence,
                ).replace(
                    "{CLEAN_IR}",
                    clean_ir_evidence,
                )
            )
        return f"""Recover one behavior-preserving standalone C11 program from
the following two representations of the same cleaned program.

<MODEL_INPUT_ARTIFACT type="LLVM2C transpiled pseudocode">
{pseudo_evidence}
</MODEL_INPUT_ARTIFACT>

<MODEL_INPUT_ARTIFACT type="cleaned LLVM IR">
{clean_ir_evidence}
</MODEL_INPUT_ARTIFACT>

Cross-check both representations and return the complete raw C11 source only.
"""

    raw_ir = not use_pseudo and _text(ir_representation).lower() == "raw"
    artifact_label = (
        "LLVM2C-transpiled C pseudocode"
        if use_pseudo
        else "raw non-deobfuscated LLVM IR"
        if raw_ir
        else "brightened LLVM IR"
    )
    evidence = (
        f"/* {attached_evidence_label} */"
        if seed_attached_file
        else (
            ir_text
            if use_pseudo
            else _clip_ir(ir_text, max_ir_chars)
        )
    )
    inventory = (
        _summarize_pseudocode_evidence(ir_text)
        if use_pseudo
        else "LLVM mode: reconstruct from exact IR control/data flow and calls."
    )
    mode_rules = (
        r"""- Start at the executable entry path and recover the reachable
  custom-function call graph; ignore disconnected runtime/transpiler noise.
- Trust literal format strings and imported ABIs over guessed transpiler types.
- Map frame storage and translated addresses from complete def-use evidence.
- Trace every dispatcher transition before collapsing flattened control flow.
- Infer loop bounds from initialization, update and exit together.
- Preserve callback direction, integer wraparound, signed comparisons and
  division/remainder semantics.
- Prefer faithful lower-level C with `goto` over an unsupported high-level rewrite."""
        if use_pseudo
        else
        r"""- Reconstruct widths, signedness, memory objects, calls and control
  flow from LLVM semantics; do not transliterate SSA line by line.
- Do not invent source-level abstractions that are not proved by the IR."""
    )

    # Read prompt from configs/prompts_config.py if available
    if _prompts_cfg:
        if use_pseudo and hasattr(_prompts_cfg, "PROMPT_CLEAN_PSEUDOCODE"):
            return _prompts_cfg.PROMPT_CLEAN_PSEUDOCODE.replace("{CLEAN_PSEUDOCODE}", evidence)
        elif raw_ir and hasattr(_prompts_cfg, "PROMPT_RAW_IR"):
            return _prompts_cfg.PROMPT_RAW_IR.replace("{RAW_IR}", evidence)
        elif not use_pseudo and hasattr(_prompts_cfg, "PROMPT_CLEAN_IR"):
            return _prompts_cfg.PROMPT_CLEAN_IR.replace("{CLEAN_IR}", evidence)

    # Built-in fallback
    return f"""Recover one behavior-preserving standalone C11 program from the
supplied artifact. Use no facts absent from the artifact or explicit validation
feedback.

<MECHANICAL_EVIDENCE_INVENTORY>
{inventory}
</MECHANICAL_EVIDENCE_INVENTORY>

<MODEL_INPUT_ARTIFACT type="{artifact_label}">
{evidence}
</MODEL_INPUT_ARTIFACT>

Return the complete raw C11 translation unit only.
"""


def _llvm_type_to_c_type(type_text: str) -> str:
    t = _text(type_text).strip()
    if not t:
        return "void"
    if t == "void":
        return "void"
    if t == "i1":
        return "bool"
    if t == "i8":
        return "uint8_t"
    if t == "i16":
        return "uint16_t"
    if t == "i32":
        return "uint32_t"
    if t == "i64":
        return "uint64_t"
    if t.startswith("i1*"):
        return "bool *"
    if t.startswith("i8*") or t.endswith("*") and t.startswith("i8"):
        return "char *"
    if t.startswith("i16*"):
        return "uint16_t *"
    if t.startswith("i32*"):
        return "uint32_t *"
    if t.startswith("i64*"):
        return "uint64_t *"
    if t.startswith("float"):
        return "float"
    if t.startswith("double"):
        return "double"
    if "..." in t:
        return "..."
    return "void *"


def _parse_llvm_args(arg_text: str) -> List[str]:
    args = []
    raw = [item.strip() for item in _split_llvm_operands(arg_text) if item.strip()]
    for idx, arg in enumerate(raw):
        if arg == "...":
            args.append("...")
            continue
        if arg in {"", "void"}:
            continue
        parts = re.split(r"\s+", arg.strip(), maxsplit=1)
        if len(parts) == 1:
            args.append(f"/* arg {idx} */ {_llvm_type_to_c_type(parts[0])} arg_{idx}")
            continue
        ctype = _llvm_type_to_c_type(parts[0])
        name = parts[1].strip()
        name = name[1:] if name.startswith("%") else name
        if not name:
            name = f"arg_{idx}"
        args.append(f"{ctype} {name}")
    if not args:
        return ["void"]
    return args


def _extract_function_signature(line: str) -> Optional[tuple[str, str, List[str]]]:
    # Returns: (return_type, function_name, args)
    stripped = line.strip()
    if not stripped.startswith("define"):
        return None

    # remove "define" and any function attributes before return type
    body = stripped[len("define"):].strip()
    m = re.match(
        r"(?P<ret>[\w\.\*% \[\]]+)\s+@(?P<name>[a-zA-Z0-9_.$-]+)\s*\((?P<args>.*?)\)\s*(?:#[0-9]+\s*)?\{",
        body,
        re.S,
    )
    if not m:
        return None
    ret = _llvm_type_to_c_type(m.group("ret").split()[-1])
    name = m.group("name")
    args = _parse_llvm_args(m.group("args"))
    return ret, name, args


def _split_llvm_operands(text: str) -> List[str]:
    parts: List[str] = []
    cur: List[str] = []
    depth = 0
    in_string = False
    escape = False
    for ch in text:
        if in_string:
            cur.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
            cur.append(ch)
            continue
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth = max(0, depth - 1)
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
        elif ch == "," and depth == 0:
            parts.append("".join(cur).strip())
            cur = []
            continue
        cur.append(ch)
    tail = "".join(cur).strip()
    if tail:
        parts.append(tail)
    return parts


def _trim_metadata_suffix(line: str) -> str:
    line = re.sub(r"\s+![a-zA-Z0-9_.$-]+\s*(\d+)?", "", line)
    line = line.split(";")[0].rstrip()
    return line.strip()


def _sanitize_ident(name: str, prefix: str = "v_") -> str:
    if not name:
        return name
    if name.startswith("%"):
        name = name[1:]
    elif name.startswith("@"):
        name = name[1:]
    name = re.sub(r"[^A-Za-z0-9_]", "_", name)
    if re.match(r"^[0-9]", name):
        name = prefix + name
    if not name:
        return prefix + "tmp"
    return name


def _emit_value(tok: str) -> str:
    tok = _strip_llvm_type_prefix(_text(tok))
    if not tok:
        return "0"
    if tok.startswith("%") or tok.startswith("@"):
        return _sanitize_ident(tok)
    if tok == "null":
        return "NULL"
    if tok in {"true", "false"}:
        return "1" if tok == "true" else "0"
    if re.fullmatch(r"-?\d+", tok):
        return tok
    return tok


def _emit_cast_expr(source_type: str, value: str, target_type: str) -> str:
    if source_type == target_type:
        return value
    ctype = _llvm_type_to_c_type(target_type)
    if ctype == "void *":
        return value
    return f"({ctype})({value})"


def _translate_llvm_instruction(line: str) -> List[str]:
    s = _trim_metadata_suffix(line)
    if not s:
        return []
    m = re.match(r"^\s*;.*$", s)
    if m:
        return []

    # label
    if s.endswith(":"):
        return [f"{_sanitize_ident(s[:-1], 'bb_')}:"]  # no braces, keep CFG

    m = re.match(r"\s*(%\w[\w\.\-]*)\s*=\s*(.+)$", s)
    assign_var = None
    body = s
    if m:
        assign_var = _sanitize_ident(m.group(1))
        body = m.group(2).strip()

    if body.startswith("ret "):
        rest = body[4:].strip()
        if rest == "void":
            return ["return;"]
        return [f"return {_emit_value(rest)};"]

    if body.startswith("br "):
        rest = body[3:].strip()
        mcond = re.match(r"i1\s+([^,]+),\s*label\s+%([A-Za-z0-9_.$-]+),\s*label\s+%([A-Za-z0-9_.$-]+)", rest)
        if mcond:
            cond = _emit_value(mcond.group(1))
            t = _sanitize_ident(mcond.group(2), "bb_")
            f = _sanitize_ident(mcond.group(3), "bb_")
            return [f"if ({cond}) goto {t}; else goto {f};"]
        mbr = re.match(r"label\s+%([A-Za-z0-9_.$-]+)", rest)
        if mbr:
            return [f"goto {_sanitize_ident(mbr.group(1), 'bb_')};"]
        return ["/* branch */"]

    if body.startswith("store "):
        rest = body[6:].strip()
        parts = _split_llvm_operands(rest)
        if len(parts) >= 2:
            val = _emit_value(parts[0].split(None, 1)[-1]) if " " in parts[0] else _emit_value(parts[0])
            dst = _emit_value(parts[1].split(None, 1)[-1]) if " " in parts[1] else _emit_value(parts[1])
            return [f"*({dst}) = {val};"]
        return ["/* store */"]

    if body.startswith("load "):
        if not assign_var:
            return [f"/* load without destination */"]
        rest = body[5:].strip()
        parts = _split_llvm_operands(rest)
        if len(parts) >= 2:
            type_token = parts[0]
            ptr_token = parts[1].split(",")[0].strip()
            ptr = _emit_value(ptr_token.split()[-1] if " " in ptr_token else ptr_token)
            ctype = _llvm_type_to_c_type(type_token)
            return [f"{ctype} {assign_var} = *({ctype}*)({ptr});"]
        return [f"/* load */ {assign_var};"]

    if body.startswith("alloca "):
        if not assign_var:
            return ["/* alloca */"]
        rest = body[7:].strip()
        alloc_type = rest.split(",")[0].strip()
        ctype = _llvm_type_to_c_type(alloc_type)
        return [f"{ctype}* {assign_var} = NULL;"]

    if body.startswith("bitcast ") or body.startswith("inttoptr ") or body.startswith("ptrtoint ") or body.startswith("trunc ") or body.startswith("zext ") or body.startswith("sext "):
        parts = body.split(None, 1)
        if len(parts) != 2:
            return ["/* cast */"]
        opcode = parts[0]
        rest = parts[1].strip()
        bits = [p.strip() for p in _split_llvm_operands(rest) if p.strip()]
        if len(bits) >= 2:
            src = bits[0]
            if opcode in {"trunc", "zext", "sext", "bitcast"} and " to " in rest:
                tokens = rest.split(" to ")
                expr = _emit_value(tokens[0].split()[-1].strip())
                dst_type = tokens[1] if len(tokens) > 1 else src
                if assign_var:
                    return [
                        f"{_llvm_type_to_c_type(_emit_value(dst_type) if dst_type else 'void')} "
                        f"{assign_var} = {_emit_cast_expr(src, expr, dst_type)};"
                    ]
                return [f"/* {src} -> {dst_type} */"]
            if opcode in {"ptrtoint", "inttoptr"} and " to " in rest:
                lhs, rhs = [x.strip() for x in rest.split(" to ", 1)]
                lhs_v = lhs.split()[-1]
                target_t = rhs
                expr = _emit_value(lhs_v)
                if not assign_var:
                    return [f"/* {lhs} -> {target_t} */"]
                return [
                    f"{_llvm_type_to_c_type(target_t)} {assign_var} = "
                    f"{_emit_cast_expr(lhs, expr, target_t)};"
                ]
        return ["/* cast */"]

    if body.startswith("call "):
        call_body = body[5:].strip()
        if "@" not in call_body:
            return [f"/* call */"]
        lpar = call_body.rfind("(")
        at = call_body.rfind("@", 0, lpar if lpar != -1 else len(call_body))
        if lpar <= 0 or at == -1:
            return ["/* call */"]
        callee = _sanitize_ident(call_body[at + 1 : lpar].strip(), "fn_")
        arg_text = call_body[lpar + 1 :]
        if arg_text.endswith(")"):
            arg_text = arg_text[:-1]
        args = [
            _emit_value(arg_part.strip().split(None, 1)[-1] if " " in arg_part.strip() else arg_part.strip())
            for arg_part in _split_llvm_operands(arg_text)
            if _text(arg_part).strip()
        ]
        rhs = f"{callee}({', '.join(args)})"
        if assign_var:
            return [f"auto {assign_var} = {rhs};"]
        return [f"{rhs};"]

    m = re.match(r"(?:(icmp|fadd|fsub|fmul|fdiv|add|sub|mul|udiv|sdiv|urem|srem|shl|ashr|lshr|and|or|xor|fcmp))\s+(.*)$", body)
    if m:
        opcode = m.group(1)
        op_tail = m.group(2).strip()
        operands = [p.strip() for p in _split_llvm_operands(op_tail) if p.strip()]
        if len(operands) >= 3:
            lhs_type = operands[0]
            src1 = _emit_value(operands[1])
            src2 = _emit_value(operands[2])
            ctype = _llvm_type_to_c_type(lhs_type)
            op_text = "/* op */"
            if opcode in {"fadd", "fsub", "fmul", "fdiv"}:
                ops = {"fadd": "+", "fsub": "-", "fmul": "*", "fdiv": "/"}[opcode]
            elif opcode in {"add", "sub", "mul", "udiv", "sdiv", "urem", "srem"}:
                ops = {"add": "+", "sub": "-", "mul": "*", "udiv": "/", "sdiv": "/", "urem": "%", "srem": "%"}[opcode]
            elif opcode == "shl":
                ops = "<<"
            elif opcode in {"ashr", "lshr"}:
                ops = ">>"
            elif opcode in {"and", "or", "xor"}:
                ops = {"and": "&", "or": "|", "xor": "^"}[opcode]
            elif opcode == "icmp":
                pred = _text(operands[1]).split()[0] if len(operands) > 1 else ""
                pred_map = {
                    "eq": "==",
                    "ne": "!=",
                    "sgt": ">",
                    "sge": ">=",
                    "slt": "<",
                    "sle": "<=",
                    "ugt": ">",
                    "uge": ">=",
                    "ult": "<",
                    "ule": "<=",
                }
                if len(operands) >= 4:
                    left = _emit_value(operands[2])
                    right = _emit_value(operands[3])
                    cmp = pred_map.get(pred, "==")
                    if assign_var:
                        return [f"bool {assign_var} = ({left} {cmp} {right});"]
                    return [f"{left} {cmp} {right};"]
                ops = "=="
            else:
                ops = "+"
            if assign_var:
                return [f"{ctype} {assign_var} = {src1} {ops} {src2};"]
            return [f"{src1} {ops} {src2};"]
        if len(operands) >= 2 and opcode in {"icmp"}:
            # fallback
            cmp_type = operands[0] if len(operands) > 2 else "bool"
            src1 = _emit_value(operands[1] if len(operands) > 1 else "0")
            src2 = _emit_value(operands[2] if len(operands) > 2 else "0")
            return [f"bool {assign_var} = ({src1} == {src2});"] if assign_var else [f"/* cmp */"]
        return ["/* expr */"]

    if body.startswith("phi "):
        # SSA form merge not trivial; keep as semantic hint for LLM
        if assign_var:
            return [f"/* phi {assign_var} */"]
        return ["/* phi */"]

    if body.startswith("switch "):
        return ["/* switch */"]

    # default: keep instruction as a pseudo-comment line to avoid dropping signal.
    return [f"/* {s} */"]


def convert_ir_to_pseudocode(ir_text: str, max_chars: int = 120_000) -> str:
    """Deterministic LLVM-IR -> C-like pseudo code seed (no LLM).

    This intentionally keeps a structured control-flow skeleton but avoids raw LLVM
    textual noise so LLMs can recover a C-style skeleton better.
    """
    body = _clip_ir(_text(ir_text), max_chars)
    lines = body.splitlines()
    pseudo = [
        "#include <stdbool.h>",
        "#include <stdint.h>",
        "#include <stdio.h>",
        "",
        "/* LLVM IR -> C-like pseudo source (seed for recovery). */",
        "/* Generated by deterministic IR structural translator. */",
    ]

    in_function = False
    for raw_line in lines:
        line = raw_line.strip()
        if not line:
            continue
        if not in_function and line.startswith("define "):
            parsed = _extract_function_signature(line)
            if not parsed:
                pseudo.append(f"/* unsupported function header: {line} */")
                continue
            ret, name, args = parsed
            if name in {"main", "entry"}:
                name = "main"
            proto = f"{ret} {name}({', '.join(args)})"
            pseudo.extend(["", proto + " {", "    "])
            in_function = True
            continue

        if in_function and line == "}":
            if pseudo and pseudo[-1] != "":
                pseudo.append("")
            pseudo.append("}")
            pseudo.append("")
            in_function = False
            continue

        if not in_function:
            continue

        body_lines = _translate_llvm_instruction(line)
        for body_line in body_lines:
            if body_line == "":
                pseudo.append("")
                continue
            pseudo.append(f"    {body_line}")

    if in_function:
        pseudo.append("}")

    if not in_function and len(pseudo) <= 6:
        pseudo.append("/* No function body parsed from IR. */")

    return "\n".join(pseudo).strip() + "\n"

def build_repair_prompt(
    ir_text: str,
    candidate: str,
    feedback: str,
    max_ir_chars: Optional[int] = None,
    source_label: str = "brightened LLVM IR",
    evidence_attached: bool = False,
    attached_evidence_label: str = (
        "COMPLETE MODEL INPUT ARTIFACT ATTACHED IN THIS REQUEST"
    ),
    *,
    max_candidate_chars: Optional[int] = 160_000,
    max_feedback_chars: Optional[int] = 48_000,
) -> str:
    evidence = (
        f"/* {attached_evidence_label} */"
        if evidence_attached
        else _clip_ir(ir_text, max_ir_chars)
    )
    bounded_candidate = _clip_ir(
        candidate,
        max_candidate_chars,
    )
    bounded_feedback = _clip_ir(
        feedback,
        max_feedback_chars,
    )
    localization_hints = _candidate_localization_hints(
        bounded_candidate,
        bounded_feedback,
    )
    normalized_source_label = source_label.lower()
    is_pseudocode = "pseudo" in normalized_source_label
    is_ghidra = "ghidra" in normalized_source_label
    is_assembly = "assembly" in normalized_source_label
    is_dual = is_pseudocode and "llvm ir" in normalized_source_label
    inventory = (
        _summarize_pseudocode_evidence(ir_text)
        if is_pseudocode
        else "LLVM mode."
    )
    mode_rule = (
        r"""For this Ghidra pseudocode repair, re-derive behavior from literal
calls, decompiler data flow, loop transitions and explicit validation feedback.
Resolve decompiler types/import thunks into standard C11, but do not invent
source facts, tests or oracle values absent from the supplied evidence."""
        if is_ghidra
        else
        r"""For this assembly repair, re-derive behavior from literal
instructions, call targets, register/stack data flow and branch transitions.
Treat addresses and compiler/obfuscator scaffolding as low-level evidence, not
as source-level names. Do not invent source facts, tests or oracle values absent
from the supplied assembly and validation feedback."""
        if is_assembly
        else
        r"""For this LLVM2C pseudocode repair, re-derive behavior from literal
call sites, def-use, loop transitions and memory accesses. Do not reintroduce
`frame_storage_backing_*`, `__brighten_native_data_pointer`, import thunks,
dispatcher constants or guessed source logic."""
        if is_pseudocode
        else
        "For this LLVM repair, re-derive behavior from exact IR control/data flow."
    )

    # Read repair prompt from configs/prompts_config.py if available
    if _prompts_cfg and hasattr(_prompts_cfg, "REPAIR_PROMPT"):
        if is_dual:
            repair_rule = getattr(
                _prompts_cfg,
                "REPAIR_RULE_CLEAN_IR_AND_PSEUDOCODE",
                mode_rule,
            )
        elif is_ghidra:
            repair_rule = getattr(
                _prompts_cfg,
                "REPAIR_RULE_GHIDRA",
                mode_rule,
            )
        elif is_assembly:
            repair_rule = getattr(
                _prompts_cfg,
                "REPAIR_RULE_ASSEMBLY",
                mode_rule,
            )
        elif is_pseudocode:
            repair_rule = getattr(
                _prompts_cfg,
                "REPAIR_RULE_PSEUDOCODE",
                mode_rule,
            )
        else:
            repair_rule = getattr(
                _prompts_cfg,
                "REPAIR_RULE_IR",
                mode_rule,
            )
        return (
            _prompts_cfg.REPAIR_PROMPT
            .replace("{FEEDBACK}", bounded_feedback)
            .replace("{PREVIOUS_CANDIDATE}", bounded_candidate or "/* EMPTY CANDIDATE: regenerate from evidence. */")
            .replace("{EVIDENCE}", evidence)
            .replace("{SOURCE_LABEL}", source_label)
            .replace("{MODE_RULE}", repair_rule)
        )
    # Built-in fallback
    return f"""Repair or regenerate the recovered C11 program using validation
feedback and the original evidence. Feedback reports an observed failure; it
does not authorize invented behavior.

<VALIDATION_FEEDBACK>
{bounded_feedback}
</VALIDATION_FEEDBACK>

<PREVIOUS_CANDIDATE>
{bounded_candidate or "/* EMPTY CANDIDATE: regenerate from evidence. */"}
</PREVIOUS_CANDIDATE>

<MODEL_INPUT_ARTIFACT type="{source_label}">
{evidence}
</MODEL_INPUT_ARTIFACT>

Repair protocol:
1. Classify the failure type.
2. Trace backward from the failed observable to the earliest causal divergence.
3. Repair the semantic rule, not one symptom.
4. {mode_rule}
5. Return the whole corrected C11 translation unit only.
"""


def _extract_json_payload(response_text: str) -> Optional[str]:
    """Extract the first complete, parseable JSON object from model output.

    Markdown fences are stripped before balanced scanning. The old non-greedy
    fence regex stopped at the first C closing brace inside the JSON string.
    """
    text = _text(response_text)
    if not text:
        return None

    fenced = re.fullmatch(
        r"```(?:json)?\s*(.*?)\s*```",
        text,
        flags=re.IGNORECASE | re.DOTALL,
    )
    if fenced:
        text = fenced.group(1).strip()

    for start, start_ch in enumerate(text):
        if start_ch != "{":
            continue
        depth = 0
        in_string = False
        escape = False
        for idx in range(start, len(text)):
            ch = text[idx]
            if in_string:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_string = False
                continue

            if ch == '"':
                in_string = True
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth < 0:
                    break
                if depth == 0:
                    candidate = text[start : idx + 1].strip()
                    for strict in (True, False):
                        try:
                            json.loads(candidate, strict=strict)
                            return candidate
                        except (json.JSONDecodeError, TypeError, ValueError):
                            pass
                    break
    return None


def _decode_json_escaped_string(value: str) -> str:
    if not value:
        return ""
    if value.endswith("\\") and len(value) % 2 == 1:
        value = value[:-1]
    try:
        return codecs.decode(value, "unicode_escape")
    except Exception:
        # Fallback to a conservative replacement when escape decoding fails.
        replacements = {
            "\\n": "\n",
            "\\r": "\r",
            "\\t": "\t",
            '\\"': '"',
            "\\'": "'",
            "\\\\": "\\",
        }
        decoded = value
        for src, dst in replacements.items():
            decoded = decoded.replace(src, dst)
        return decoded


def _extract_partial_json_source(response_text: str) -> Optional[str]:
    """Try to recover source text from an incomplete JSON output."""
    text = _text(response_text)
    if not text:
        return None
    match = re.search(r'"source"\s*:\s*"', text, re.IGNORECASE)
    if not match:
        return None
    src = match.end()
    data = text[src:]
    out = []
    escaped = False
    for ch in data:
        if escaped:
            out.append(f"\\{ch}")
            escaped = False
            continue
        if ch == "\\":
            escaped = True
            continue
        if ch == '"':
            break
        if ch == "\n":
            # If generator emits actual newlines in-place, include them and keep reading.
            out.append("\n")
            continue
        out.append(ch)
    if not out:
        return None
    return _decode_json_escaped_string("".join(out))


def _extract_source_from_json(
    response_text: str,
    field_names: tuple[str, ...] = ("source", "code", "c_source"),
) -> Optional[str]:
    payload = _extract_json_payload(response_text)
    if not payload:
        return None
    try:
        decoded = json.loads(payload)
    except (json.JSONDecodeError, TypeError, ValueError):
        try:
            decoded = json.loads(payload, strict=False)
        except (json.JSONDecodeError, TypeError, ValueError):
            return None

    if isinstance(decoded, dict):
        source = None
        for field in field_names:
            source = decoded.get(field)
            if source is not None:
                break
        if source is None:
            return None
        return _text(source)
    if isinstance(decoded, str):
        return _text(decoded)
    return None


def extract_c_source(response_text: str, require_json: bool = True) -> str:
    """Extract and validate one complete C translation unit."""

    text = _text(response_text)
    json_source = _extract_source_from_json(text)
    if json_source is not None:
        source = _sanitize_recovered_candidate(json_source)
        _validate_recovered_candidate(source)
        return source + ("\n" if not source.endswith("\n") else "")

    partial_json = _extract_partial_json_source(text)
    if partial_json is not None:
        raise RecoveryError(
            "LLM output includes an incomplete JSON source string; partial source is rejected."
        )

    if require_json:
        raise RecoveryError("LLM output was not strict JSON (missing/invalid `source` field).")

    marked = re.search(r"BEGIN_C_SOURCE\s*(.*?)\s*END_C_SOURCE", text, re.IGNORECASE | re.DOTALL)
    if marked:
        source = marked.group(1).strip()
    else:
        start = re.search(r"BEGIN_C_SOURCE\s*(.*)", text, re.IGNORECASE | re.DOTALL)
        if start:
            raise RecoveryError("LLM output is incomplete: missing END_C_SOURCE delimiter.")
        start = re.search(r"```(?:c|cpp)?\s*(.*?)```", text, re.IGNORECASE | re.DOTALL)
        source = start.group(1).strip() if start else text

    source = re.sub(r"\buint64(?!_t)\b", "uint64_t", source)
    source = _sanitize_recovered_candidate(source)
    _validate_recovered_candidate(source)
    return source + ("\n" if not source.endswith("\n") else "")


def _extract_partial_response(response_text: str) -> Optional[str]:
    """Return partial source from JSON or fallback delimiter format."""
    text = _text(response_text)
    json_source = _extract_source_from_json(text)
    if json_source is not None:
        return json_source
    partial_json = _extract_partial_json_source(text)
    if partial_json is not None:
        return partial_json
    start = re.search(r"BEGIN_C_SOURCE\s*(.*)", text, re.IGNORECASE | re.DOTALL)
    if start:
        return start.group(1).strip()
    if re.search(r"\bint\s+main\s*\(", text):
        return text
    return None


def _strip_comments_for_scan(text: str) -> str:
    """Remove line and block comments to improve syntax tail heuristics."""
    def replacer(match: re.Match[str]) -> str:
        # preserve line length roughly to avoid shifting logic relying on indices
        token = match.group(0)
        if token.startswith("//"):
            return "\n"
        return "".join(" " for _ in token)

    text = re.sub(r"/\*.*?\*/", lambda m: " " * len(m.group(0)), text, flags=re.DOTALL)
    text = re.sub(r"//[^\n]*", replacer, text)
    return text


def _syntax_balance(text: str) -> tuple[int, int, int]:
    """Return rough (brace, paren, bracket) balance while ignoring comment regions."""
    cleaned = _strip_comments_for_scan(text)
    brace = paren = bracket = 0
    for ch in cleaned:
        if ch == "{":
            brace += 1
        elif ch == "}":
            brace -= 1
        elif ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
    return brace, paren, bracket


def _trim_incomplete_tail(source: str) -> str:
    """Drop a truncated suffix so clang can get meaningful feedback."""
    lines = _text(source).splitlines()
    if not lines:
        return source
    for cutoff in range(len(lines), 0, -1):
        candidate = "\n".join(lines[:cutoff]).strip()
        if not candidate:
            continue
        brace, paren, bracket = _syntax_balance(candidate)
        if brace != 0 or paren != 0 or bracket != 0:
            continue
        tail = candidate.rstrip()
        if tail.endswith((";", "}", "]")):
            return candidate + "\n"
        if tail.endswith("*/"):
            # comment-only suffix can continue; try one more line above.
            continue
    # As a fallback, remove one obvious partially emitted token at the end and retry.
    trimmed = _text(source).rstrip()
    if trimmed.endswith(("uint64", "uint32", "uint16", "uint8", "int", "long", "short", "char", "void", "}")):
        trimmed = trimmed.rsplit("\n", 1)[0] if "\n" in trimmed else ""
    return trimmed + "\n" if trimmed else ""


def _sanitize_recovered_candidate(candidate: str) -> str:
    """Normalize and lightly clean a recovered C candidate before compile/repair."""
    source = _text(candidate)
    source = source.replace("\r\n", "\n")
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    source = re.sub(r"//[^\n]*[Pp]laceholder[^\n]*", "", source)
    source = re.sub(r"\buint8(?!_t)\b", "uint8_t", source)
    source = re.sub(r"\buint16(?!_t)\b", "uint16_t", source)
    source = re.sub(r"\buint64(?!_t)\b", "uint64_t", source)
    source = re.sub(r"\buint32(?!_t)\b", "uint32_t", source)
    source = re.sub(r"\bint64(?!_t)\b", "int64_t", source)
    source = re.sub(r"\bint32(?!_t)\b", "int32_t", source)
    source = re.sub(r"\n{3,}", "\n\n", source)
    return source + ("\n" if source and not source.endswith("\n") else "")


def _validate_recovered_candidate(source: str) -> None:
    """Reject incomplete or placeholder-heavy output before compile/fuzzing."""
    text = _text(source).strip()
    if not text:
        raise RecoveryError("LLM response produced an empty C translation unit.")

    brace, paren, bracket = _syntax_balance(text)
    if (brace, paren, bracket) != (0, 0, 0):
        raise RecoveryError(
            "LLM response is incomplete: unbalanced C syntax "
            f"(braces={brace}, parens={paren}, brackets={bracket})."
        )

    if not re.search(r"\bint\s+main\s*\(", text):
        raise RecoveryError("LLM response is incomplete: missing a real int main(...) definition.")

    lowered = text.lower()
    placeholder_markers = (
        "dummy_format_string",
        "placeholder",
        "actual content and size are not provided",
        "values are not provided",
        "reasonable guesses",
    )
    found = next((marker for marker in placeholder_markers if marker in lowered), None)
    if found:
        raise RecoveryError(
            f"LLM response contains unsupported placeholder content: {found}."
        )
    placeholder_identifier = re.search(
        r"\bdummy_(?:buffer|data|implementation|function|result)\b",
        lowered,
    )
    if placeholder_identifier:
        raise RecoveryError(
            "LLM response contains unsupported placeholder content: "
            f"{placeholder_identifier.group(0)}."
        )

    forbidden_patterns = (
        (r"\bundefined(?:1|2|4|8|16)\b", "decompiler undefined-width type"),
        (r"\bprocessEntry\b", "decompiler processEntry type"),
        (r"\bframe_storage_backing_[A-Za-z0-9_]*", "lifted frame storage"),
        (r"\b__brighten_native_data_pointer\b", "lifted pointer translator"),
        (r"\bhalt_baddata\b", "decompiler bad-data stub"),
        (r"\bCONCAT\d+\b", "decompiler CONCAT helper"),
        (r"\bPTR_[A-Za-z0-9_]+", "import-thunk pointer"),
        (r"\._\d+_\d+_", "decompiler synthetic field selector"),
        (r"\(code\s*\*\)", "decompiler code-pointer type"),
    )
    for pattern, description in forbidden_patterns:
        if re.search(pattern, text):
            raise RecoveryError(
                f"LLM response still contains unsupported decompiler artifact: {description}."
            )


def _load_adc_credentials() -> Dict[str, Any]:
    """Load Google Cloud ADC credentials used for manual Vertex AI REST authentication."""
    adc_env = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if adc_env:
        adc_path = Path(adc_env)
    else:
        adc_path = Path.home() / ".config" / "gcloud" / "application_default_credentials.json"

    if not adc_path.exists():
        raise RecoveryError(
            "Google ADC file not found. Set GOOGLE_APPLICATION_CREDENTIALS or run "
            "'gcloud auth application-default login'."
        )

    with open(adc_path, "r", encoding="utf-8") as fp:
        return json.load(fp)


def _request_access_token_via_refresh(credentials: Mapping[str, Any]) -> str:
    """Exchange a refresh token for a Google OAuth access token."""
    if credentials.get("type") != "authorized_user":
        raise RecoveryError(
            "Current ADC is not authorized_user. Recreate a user credential for REST fallback."
        )

    required = ("client_id", "client_secret", "refresh_token")
    missing = [key for key in required if not credentials.get(key)]
    if missing:
        raise RecoveryError(
            "OAuth credentials missing in ADC: " + ", ".join(missing)
        )

    try:
        import requests
    except ImportError as exc:
        raise RecoveryError("Python package 'requests' is required for Vertex REST.") from exc

    response = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "client_id": credentials["client_id"],
            "client_secret": credentials["client_secret"],
            "refresh_token": credentials["refresh_token"],
            "grant_type": "refresh_token",
        },
        timeout=30,
    )
    if response.status_code != 200:
        try:
            detail = response.text[:500]
        except Exception:
            detail = ""
        raise RecoveryError(f"Failed to refresh token: HTTP {response.status_code} {detail}")

    payload = response.json()
    token = _text(payload.get("access_token"))
    if not token:
        raise RecoveryError(f"Token refresh response missing access_token: {payload}")
    return token


def _vertex_api_base_url(location: str) -> str:
    """Return the Vertex API hostname for global, multi-region, or regional routing."""
    normalized = _text(location).lower()
    if normalized == "global":
        return "https://aiplatform.googleapis.com"
    if normalized in {"us", "eu"}:
        return f"https://aiplatform.{normalized}.rep.googleapis.com"
    return f"https://{normalized}-aiplatform.googleapis.com"


def _retry_after_seconds(value: Any, detail: str = "") -> Optional[float]:
    raw = _text(value).strip()
    if raw:
        try:
            return max(0.0, float(raw))
        except ValueError:
            try:
                retry_at = email.utils.parsedate_to_datetime(raw)
                if retry_at.tzinfo is None:
                    retry_at = retry_at.replace(tzinfo=dt.timezone.utc)
                return max(
                    0.0,
                    (
                        retry_at
                        - dt.datetime.now(dt.timezone.utc)
                    ).total_seconds(),
                )
            except (TypeError, ValueError, OverflowError):
                pass
    patterns = (
        r'"retryDelay"\s*:\s*"(?P<seconds>\d+(?:\.\d+)?)s"',
        r"retry\s+(?:after|in)\s+(?P<seconds>\d+(?:\.\d+)?)\s*s",
    )
    for pattern in patterns:
        match = re.search(pattern, detail, flags=re.IGNORECASE)
        if match:
            return max(0.0, float(match.group("seconds")))
    return None


def _is_rate_limit_detail(value: Any) -> bool:
    detail = _text(value).lower()
    return any(
        marker in detail
        for marker in (
            "resource_exhausted",
            "resourceexhausted",
            "rate limit",
            "ratelimit",
            "quota exceeded",
            "too many requests",
            "http 429",
            "statuscode.429",
        )
    )


def _is_context_overflow_detail(value: Any) -> bool:
    detail = _text(value).lower()
    return any(
        marker in detail
        for marker in (
            "input token count exceeds",
            "maximum number of tokens allowed",
            "context length exceeded",
            "context window",
            "request too large for the model",
            "too many input tokens",
        )
    )


def _vertex_inline_mime_type(path: Path) -> str:
    """Return a Gemini-supported inline MIME type or reject opaque binaries."""
    suffix = path.suffix.lower()
    if suffix in {".c", ".h", ".ll", ".txt", ".md", ".csv"}:
        return "text/plain"
    if suffix == ".json":
        return "application/json"
    if suffix == ".pdf":
        return "application/pdf"
    image_types = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
    }
    if suffix in image_types:
        return image_types[suffix]
    raise RecoveryError(
        f"Unsupported Gemini inline attachment type '{suffix or '<none>'}': {path}. "
        "Raw executables and application/octet-stream are not accepted."
    )


def _recovery_response_schema() -> Dict[str, Any]:
    """Schema-enforce the one-field recovery response at the provider boundary."""
    return {
        "type": "OBJECT",
        "properties": {
            "source": {
                "type": "STRING",
                "description": (
                    "One complete standalone compilable C11 translation unit. "
                    "Code only; no markdown fences, prose, patch, or JSON wrapper inside this string."
                ),
            }
        },
        "required": ["source"],
        "propertyOrdering": ["source"],
    }


def _vertex_generation_config(config: RecoveryConfig) -> Dict[str, Any]:
    generation_config: Dict[str, Any] = {
        "temperature": config.temperature,
        "topP": config.top_p,
        "candidateCount": config.candidate_count,
    }
    if config.max_output_tokens:
        generation_config["maxOutputTokens"] = config.max_output_tokens
    if config.require_json:
        generation_config["responseMimeType"] = "application/json"
        generation_config["responseSchema"] = _recovery_response_schema()
    thinking_level = _text(config.thinking_level).upper()
    if thinking_level and ("pro" in _text(config.model).lower() or os.environ.get("LLM_RECOVERY_THINKING_LEVEL")):
        allowed = {"MINIMAL", "LOW", "MEDIUM", "HIGH"}
        if thinking_level in allowed:
            generation_config["thinkingConfig"] = {"thinkingLevel": thinking_level}
    return generation_config


class VertexGemini:
    """Lazy Vertex AI Gemini client using ADC, as described in LLM_api.md."""

    def __init__(self, config: RecoveryConfig):
        self.config = config
        self._client = None
        self.last_response_meta: Dict[str, Any] = {}

    def _client_or_create(self):
        if self._client is not None:
            return self._client
        try:
            from google import genai
        except ImportError as exc:
            return None
        kwargs: Dict[str, Any] = {}
        if self.config.api_key:
            kwargs["api_key"] = self.config.api_key
        else:
            kwargs["vertexai"] = True
            kwargs["location"] = self.config.location
            if self.config.project:
                kwargs["project"] = self.config.project
        try:
            self._client = genai.Client(**kwargs)
        except Exception as exc:
            raise RecoveryError(f"Could not initialize Gemini client: {exc}") from exc
        return self._client

    def _generate_rest(
        self,
        prompt: str,
        attachment_path: Optional[str] = None,
        attachment_paths: Optional[Sequence[str]] = None,
        system_instruction: Optional[str] = None,
    ) -> str:
        """Call Gemini generateContent through REST with API Key or ADC credentials."""
        try:
            import requests
        except ImportError as exc:
            raise RecoveryError("Python package 'requests' is required.") from exc

        adc_credentials = None
        try:
            adc_credentials = _load_adc_credentials()
        except Exception:
            adc_credentials = None

        use_openai_format = False
        if self.config.api_key:
            base_url = os.environ.get("GEMINI_API_BASE_URL") or getattr(_prompts_cfg, "API_BASE_URL", "https://generativelanguage.googleapis.com/v1beta")
            use_openai_format = "v1" in base_url and "googleapis.com" not in base_url
            if use_openai_format:
                url = f"{base_url}/chat/completions"
                headers = {
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {self.config.api_key}"
                }
            else:
                url = f"{base_url}/models/{self.config.model}:generateContent?key={self.config.api_key}"
                headers = {"Content-Type": "application/json"}
        else:
            credentials = adc_credentials or _load_adc_credentials()
            access_token = _request_access_token_via_refresh(credentials)
            project = self.config.project or _text(credentials.get("quota_project_id"))
            if not project:
                raise RecoveryError(
                    "Could not determine Vertex AI project. Set VERTEX_PROJECT or GOOGLE_CLOUD_PROJECT."
                )
            url = (
                f"{_vertex_api_base_url(self.config.location)}/"
                f"v1/projects/{project}/locations/{self.config.location}/"
                f"publishers/google/models/{self.config.model}:generateContent"
            )
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            }
            quota_project = self.config.project or _text(credentials.get("quota_project_id"))
            if quota_project:
                headers["x-goog-user-project"] = quota_project

        paths: List[str] = []
        if attachment_path:
            paths.append(_text(attachment_path))
        if attachment_paths:
            paths.extend(_text(path) for path in attachment_paths)
        paths = list(dict.fromkeys(path for path in paths if path))

        if use_openai_format:
            content_parts = []
            for path in paths:
                attachment = Path(path)
                if attachment.is_file():
                    try:
                        file_text = attachment.read_text(encoding="utf-8", errors="replace")
                        content_parts.append(f"=== File: {attachment.name} ===\n{file_text}\n")
                    except Exception:
                        pass
            content_parts.append(prompt)
            full_prompt = "\n".join(content_parts)
            
            messages = []
            if _text(system_instruction):
                messages.append({"role": "system", "content": str(system_instruction)})
            messages.append({"role": "user", "content": full_prompt})
            
            payload = {
                "model": self.config.model,
                "messages": messages,
                "temperature": self.config.temperature or 0.1,
                "max_tokens": self.config.max_output_tokens or 8192,
                "stream": False,
            }
        else:
            file_parts = []
            for path in paths:
                attachment = Path(path)
                if not attachment.is_file():
                    raise RecoveryError(f"File attachment không tồn tại: {path}")
                file_size = attachment.stat().st_size
                if (
                    self.config.file_api_inline_max_bytes
                    and file_size > self.config.file_api_inline_max_bytes
                ):
                    raise RecoveryError(
                        f"File attachment quá lớn cho inlineData ({file_size} bytes > {self.config.file_api_inline_max_bytes})."
                    )
                raw = attachment.read_bytes()
                mime_type = _vertex_inline_mime_type(attachment)
                file_parts.append(
                    {
                        "inlineData": {
                            "mimeType": mime_type,
                            "data": base64.b64encode(raw).decode("ascii"),
                        }
                    }
                )
            parts = file_parts + [{"text": prompt}]
            generation_config = _vertex_generation_config(self.config)
            payload = {
                "contents": [
                    {
                        "role": "user",
                        "parts": parts,
                    }
                ],
                "generationConfig": generation_config,
            }
            if _text(system_instruction):
                payload["systemInstruction"] = {
                    "parts": [{"text": str(system_instruction)}]
                }

        try:
            timeout = self.config.request_timeout
            timeout_tuple = (30, None) if timeout <= 0 else (30, timeout)
            response = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=timeout_tuple,
            )
        except Exception as exc:
            if "timed out" in str(exc).lower():
                if self.config.request_timeout <= 0:
                    raise RecoveryError("Vertex REST request failed or was interrupted while waiting for response.") from exc
                raise RecoveryError(f"Vertex REST request timed out after {self.config.request_timeout}s") from exc
            raise RecoveryError(f"Vertex REST request failed: {exc}") from exc
        if response.status_code != 200:
            try:
                detail = response.text[:500]
            except Exception:
                detail = ""
            if response.status_code == 429 or _is_rate_limit_detail(detail):
                raise LLMRateLimitError(
                    f"Vertex REST rate limited: HTTP {response.status_code}: {detail}",
                    retry_after_seconds=_retry_after_seconds(
                        response.headers.get("Retry-After"), detail
                    ),
                    status_code=response.status_code,
                )
            if _is_context_overflow_detail(detail):
                raise LLMContextOverflowError(
                    f"Vertex REST context overflow: HTTP "
                    f"{response.status_code}: {detail}"
                )
            if response.status_code in {408, 409, 429, 499, 500, 502, 503, 504}:
                raise LLMTransientError(
                    f"Vertex REST transient rate-limit/failure: HTTP {response.status_code}: {detail}",
                    status_code=response.status_code,
                )
            raise RecoveryError(f"Vertex REST failed: HTTP {response.status_code}: {detail}")

        try:
            data = response.json()
        except Exception as json_err:
            raise RecoveryError(f"Failed to parse response JSON. HTTP Status: {response.status_code}. Raw Body: {response.text[:1000]}") from json_err
        if use_openai_format:
            choices = data.get("choices") or []
            if not choices:
                self.last_response_meta = {
                    "finish_reason": "EMPTY",
                    "finish_message": "missing choices in OpenAI response",
                    "usage_metadata": data.get("usage") or {},
                }
                raise LLMEmptyResponseError("OpenAI REST returned empty payload: missing choices.")
            first_choice = choices[0]
            self.last_response_meta = {
                "model_version": data.get("model", self.config.model),
                "finish_reason": _text(first_choice.get("finish_reason", "STOP")).upper(),
                "finish_message": "OpenAI completions",
                "usage_metadata": data.get("usage") or {},
            }
            result = first_choice.get("message", {}).get("content", "").strip()
            return result

        usage = data.get("usageMetadata") or {}
        candidates = data.get("candidates") or []
        if not candidates:
            self.last_response_meta = {
                "model_version": _text(data.get("modelVersion")),
                "finish_reason": "EMPTY",
                "finish_message": "missing candidates",
                "usage_metadata": usage,
            }
            raise LLMEmptyResponseError(
                "Vertex REST returned empty payload: missing candidates."
            )

        first_candidate = candidates[0]
        self.last_response_meta = {
            "model_version": _text(data.get("modelVersion")),
            "finish_reason": _text(first_candidate.get("finishReason")).upper(),
            "finish_message": _text(first_candidate.get("finishMessage")),
            "usage_metadata": usage,
        }
        content = first_candidate.get("content", {})
        parts = content.get("parts") or []
        texts: List[str] = []
        for part in parts:
            if isinstance(part, Mapping):
                piece = part.get("text")
                if piece is None:
                    continue
                texts.append(str(piece))
        result = "".join(texts).strip()
        if not result:
            raise LLMEmptyResponseError("Vertex REST returned empty response")
        return result

    def generate(
        self,
        prompt: str,
        attachment_path: Optional[str] = None,
        attachment_paths: Optional[Sequence[str]] = None,
        system_instruction: Optional[str] = None,
    ) -> str:
        paths = list(attachment_paths or [])
        if attachment_path:
            paths.insert(0, attachment_path)
        use_file_api = (
            self.config.use_file_api
            and bool([path for path in paths if _text(path)])
        )
        if use_file_api:
            return self._generate_rest(
                prompt,
                attachment_paths=paths,
                system_instruction=system_instruction,
            )

        client = self._client_or_create()
        if client is None:
            return self._generate_rest(
                prompt,
                attachment_path=None,
                system_instruction=system_instruction,
            )
        try:
            from google.genai import types

            _vertex_generation_config(self.config)
            generation_kwargs = {
                "temperature": self.config.temperature,
                "top_p": self.config.top_p,
                "candidate_count": self.config.candidate_count,
            }
            if _text(system_instruction):
                generation_kwargs["system_instruction"] = str(system_instruction)
            if self.config.max_output_tokens:
                generation_kwargs["max_output_tokens"] = self.config.max_output_tokens
            if self.config.require_json:
                generation_kwargs["response_mime_type"] = "application/json"
                generation_kwargs["response_schema"] = _recovery_response_schema()
            if self.config.thinking_level:
                generation_kwargs["thinking_config"] = types.ThinkingConfig(
                    thinking_level=_text(self.config.thinking_level).upper()
                )
            generation_config = types.GenerateContentConfig(**generation_kwargs)
            response = client.models.generate_content(
                model=self.config.model,
                contents=prompt,
                config=generation_config,
            )
        except Exception as exc:
            if isinstance(exc, LLMContextOverflowError):
                raise
            if isinstance(exc, LLMRateLimitError):
                raise
            if _is_context_overflow_detail(exc):
                raise LLMContextOverflowError(
                    f"Vertex Gemini context overflow: {exc}"
                ) from exc
            if _is_rate_limit_detail(exc):
                raise LLMRateLimitError(
                    f"Vertex Gemini rate limited: {exc}",
                    retry_after_seconds=_retry_after_seconds(None, str(exc)),
                    status_code=429,
                ) from exc
            detail = str(exc)
            if any(
                marker in detail.lower()
                for marker in (
                    "http 408",
                    "http 409",
                    "http 499",
                    "http 500",
                    "http 502",
                    "http 503",
                    "http 504",
                    "cancelled",
                    "canceled",
                    "temporarily unavailable",
                )
            ):
                raise LLMTransientError(
                    f"Vertex Gemini transient failure: {detail}"
                ) from exc
            raise RecoveryError(f"Vertex Gemini request failed: {exc}") from exc
        candidates = getattr(response, "candidates", None) or []
        first_candidate = candidates[0] if candidates else None
        finish_value = getattr(first_candidate, "finish_reason", None)
        finish_reason = getattr(finish_value, "name", None) or _text(finish_value)
        usage_object = getattr(response, "usage_metadata", None)
        usage = {}
        for field_name in (
            "prompt_token_count",
            "candidates_token_count",
            "total_token_count",
            "thoughts_token_count",
        ):
            value = getattr(usage_object, field_name, None) if usage_object else None
            if value is not None:
                usage[field_name] = value
        self.last_response_meta = {
            "model_version": _text(getattr(response, "model_version", "")),
            "finish_reason": _text(finish_reason).upper().split(".")[-1],
            "finish_message": _text(getattr(first_candidate, "finish_message", "")),
            "usage_metadata": usage,
        }
        result = _text(getattr(response, "text", ""))
        if not result:
            raise LLMEmptyResponseError(
                "Vertex Gemini returned an empty response"
            )
        return result


def _run_compile_check(source_path: str, output_dir: str) -> tuple[bool, Optional[str]]:
    from fuzzing_equi_check.fuzzing import find_clang

    compiler = find_clang()
    output_bin = os.path.join(output_dir, "recovered_compile_check.bin")
    command = [
        compiler,
        "-std=c11",
        "-O0",
        "-Wall",
        "-Wextra",
        "-Werror=format",
        "-Werror=implicit-function-declaration",
        "-Werror=incompatible-pointer-types",
        "-Werror=int-conversion",
        "-Wno-unused-parameter",
        "-Wno-unused-variable",
        "-Wno-unused-function",
        source_path,
        "-lm",
        "-o",
        output_bin,
    ]
    process = subprocess.run(command, capture_output=True, text=True)
    if process.returncode == 0:
        return True, None
    return False, (process.stderr or process.stdout or "compiler returned a non-zero exit code").strip()


def _diagnostic_text(value: Any, limit: int = 4000) -> str:
    text = _text(value)
    if len(text) <= limit:
        return text
    return text[:limit] + f"\n...[truncated {len(text) - limit} chars]"


def _failure_class(sample: Mapping[str, Any]) -> str:
    left = sample.get("prog1") or {}
    right = sample.get("prog2") or {}
    if left.get("status") != right.get("status"):
        return "asymmetric_execution_status"
    if left.get("returncode") != right.get("returncode"):
        return "exit_status"
    if left.get("stdout") != right.get("stdout"):
        return "stdout_value_or_format"
    if left.get("stderr") != right.get("stderr"):
        return "stderr_value_or_format"
    return "behavioral_mismatch"


def _compact_fuzz_round(
    iteration: int, report: Mapping[str, Any]
) -> str:
    examples = report.get("mismatch_examples") or []
    first = examples[0] if examples else {}
    left = first.get("prog1") or {}
    right = first.get("prog2") or {}
    return (
        f"round={iteration}: matches={report.get('matches', 0)}, "
        f"mismatches={report.get('mismatches', 0)}, "
        f"inconclusive={report.get('inconclusive', 0)}, "
        f"class={_failure_class(first) if first else 'none'}, "
        f"input={_diagnostic_text(first.get('stdin', ''), 300)!r}, "
        f"candidate_stdout={_diagnostic_text(left.get('stdout', ''), 200)!r}, "
        f"reference_stdout={_diagnostic_text(right.get('stdout', ''), 200)!r}"
    )


def _format_execution_side(
    label: str, side: Mapping[str, Any]
) -> list[str]:
    return [
        (
            f"{label}: status={side.get('status')}, "
            f"returncode={side.get('returncode')}, "
            f"signal={side.get('signal')}, "
            f"elapsed_ms={side.get('elapsed_ms')}"
        ),
        (
            f"{label}.stdout[{side.get('stdout_byte_length', len(_text(side.get('stdout'))))} bytes]="
            f"{_diagnostic_text(side.get('stdout', ''), 4000)!r}"
        ),
        (
            f"{label}.stderr[{side.get('stderr_byte_length', len(_text(side.get('stderr'))))} bytes]="
            f"{_diagnostic_text(side.get('stderr', ''), 2000)!r}"
        ),
    ]


def _format_fuzz_feedback(
    report: Mapping[str, Any],
    prior_history: Optional[Sequence[str]] = None,
) -> str:
    lines = [
        "DIFFERENTIAL DIAGNOSIS: semantic equivalence is not confirmed.",
        (
            f"summary: total={report.get('total_runs', 0)}, "
            f"confirmed={report.get('confirmed_runs', 0)}, "
            f"matches={report.get('matches', 0)}, "
            f"mismatches={report.get('mismatches', 0)}, "
            f"inconclusive={report.get('inconclusive', 0)}, "
            f"equivalence_ratio={report.get('equivalence_ratio', 0.0):.2f}%"
        ),
    ]
    if report.get("early_stopped"):
        lines.append(
            "early_stop: "
            + _diagnostic_text(report.get("early_stop_reason"), 1000)
        )
    examples = report.get("mismatch_examples") or []
    for sample in examples[:7]:
        left = sample.get("prog1", {})
        right = sample.get("prog2", {})
        lines.extend(
            [
                "",
                (
                    f"COUNTEREXAMPLE #{sample.get('index', '?')} "
                    f"class={_failure_class(sample)} "
                    f"reason={sample.get('reason', 'unspecified')}"
                ),
                (
                    f"stdin_text[{sample.get('stdin_byte_length', len(_text(sample.get('stdin'))))} bytes]="
                    f"{_diagnostic_text(sample.get('stdin', ''), 8000)!r}"
                ),
                (
                    "stdin_base64="
                    + _diagnostic_text(sample.get("stdin_base64"), 12000)
                ),
                (
                    "stdin_hex="
                    + _diagnostic_text(sample.get("stdin_hex"), 12000)
                ),
                *_format_execution_side("candidate", left),
                *_format_execution_side("reference", right),
            ]
        )
        for diff in sample.get("output_diffs") or []:
            lines.append(
                "byte_diff: stream={stream}, first_offset={offset}, "
                "candidate_byte=0x{left}, reference_byte=0x{right}, "
                "candidate_length={left_len}, reference_length={right_len}, "
                "candidate_window_hex={left_window}, "
                "reference_window_hex={right_window}".format(
                    stream=diff.get("stream"),
                    offset=diff.get("first_differing_byte"),
                    left=diff.get("recovered_byte_hex") or "EOF",
                    right=diff.get("reference_byte_hex") or "EOF",
                    left_len=diff.get("recovered_length"),
                    right_len=diff.get("reference_length"),
                    left_window=diff.get("recovered_window_hex"),
                    right_window=diff.get("reference_window_hex"),
                )
            )
    if prior_history:
        lines.extend(
            [
                "",
                "PRIOR ROUND HISTORY (use it to detect persistence/regression):",
                *[f"- {item}" for item in list(prior_history)[-4:]],
            ]
        )
    lines.extend(
        [
            "",
            "REQUIRED ROOT-CAUSE WORK:",
            "1. Reproduce each counterexample through the previous candidate.",
            "2. Identify the earliest divergent read, predicate, arithmetic "
            "operation, memory access, call argument, or termination decision.",
            "3. Map that operation to both attached pseudocode and cleaned IR.",
            "4. Repair the general semantic rule; do not special-case the input.",
            "5. Recheck prior-round counterexamples to avoid regression.",
        ]
    )
    return "\n".join(lines)


def _candidate_localization_hints(
    candidate: str, feedback: str, max_lines: int = 60
) -> str:
    """Return line-numbered candidate regions likely tied to observables."""

    source_lines = _text(candidate).splitlines()
    lowered_feedback = _text(feedback).lower()
    patterns = [
        r"\b(?:printf|fprintf|puts|putchar|write|scanf|fscanf|read)\s*\(",
        r"\breturn\b",
        r"\b(?:if|for|while|switch)\s*\(",
    ]
    if any(token in lowered_feedback for token in ("crash", "signal", "segv")):
        patterns.extend(
            [
                r"\b(?:malloc|calloc|realloc|free)\s*\(",
                r"->|\[[^\]]+\]|\*\s*[A-Za-z_(]",
            ]
        )
    if "timeout" in lowered_feedback:
        patterns.extend([r"\bwhile\s*\(\s*(?:1|true)\s*\)", r"\bfor\s*\(\s*;"])
    matcher = re.compile("|".join(f"(?:{item})" for item in patterns))
    selected: set[int] = set()
    for index, line in enumerate(source_lines):
        if matcher.search(line):
            selected.update(
                range(max(0, index - 2), min(len(source_lines), index + 3))
            )
        if len(selected) >= max_lines:
            break
    ordered = sorted(selected)[:max_lines]
    if not ordered:
        return "No high-confidence localization lines were found; inspect the full candidate."
    return "\n".join(
        f"{index + 1:6d} | {source_lines[index]}" for index in ordered
    )


def confirmed_equivalence_pass(report: Mapping[str, Any]) -> bool:
    """Accept only confirmed zero-mismatch runs, without the strict gate.

    The strict report also rejects crashes, timeouts, inconclusive executions,
    and early stopping.  P0's experiment contract intentionally uses the
    looser confirmed subset: at least one confirmed run, no mismatches, and a
    100% confirmed equivalence ratio.
    """

    try:
        confirmed_runs = int(report.get("confirmed_runs", 0) or 0)
        mismatches = int(report.get("mismatches", 0) or 0)
        confirmed_ratio = float(
            report.get("confirmed_equivalence_ratio", -1.0) or -1.0
        )
    except (TypeError, ValueError):
        return False
    return (
        confirmed_runs > 0
        and mismatches == 0
        and confirmed_ratio >= 100.0
    )


def _estimated_source_tokens_from_bytes(byte_count: int) -> int:
    """Conservative local estimate for punctuation-dense C/LLVM evidence."""

    return max(1, (max(0, int(byte_count)) + 1) // 2)


def _recovery_context_check(
    config: RecoveryConfig,
    system_prompt: str,
    model_prompt: str,
    attachment_paths: Sequence[str],
) -> Dict[str, Any]:
    prompt_bytes = len(
        (system_prompt + "\n" + model_prompt).encode(
            "utf-8", errors="replace"
        )
    )
    attachment_bytes = sum(
        Path(path).stat().st_size
        for path in attachment_paths
        if Path(path).is_file()
    )
    estimated_input_tokens = _estimated_source_tokens_from_bytes(
        prompt_bytes + attachment_bytes
    )
    max_output_tokens = int(config.max_output_tokens or 0)
    safety_margin_tokens = max(
        0, int(config.context_safety_margin_tokens)
    )
    required_tokens = (
        estimated_input_tokens
        + max_output_tokens
        + safety_margin_tokens
    )
    context_window_tokens = int(config.context_window_tokens or 0)
    return {
        "fit": (
            context_window_tokens <= 0
            or required_tokens <= context_window_tokens
        ),
        "prompt_bytes": prompt_bytes,
        "attachment_bytes": attachment_bytes,
        "estimated_input_tokens": estimated_input_tokens,
        "max_output_tokens": max_output_tokens,
        "safety_margin_tokens": safety_margin_tokens,
        "required_tokens": required_tokens,
        "context_window_tokens": context_window_tokens,
        "token_count_kind": (
            "conservative_source_estimate_2_utf8_bytes_per_token"
        ),
        "attachment_paths": list(attachment_paths),
    }


def run_recovery_loop(
    ir_text: str,
    output_recovered_c_path: str,
    case_output_dir: str,
    metadata: Optional[Mapping[str, str]] = None,
    fuzzer_callback: Optional[Callable[[str], Mapping[str, Any]]] = None,
    config: Optional[RecoveryConfig] = None,
    model_client: Optional[VertexGemini] = None,
    request_executor: Optional[
        Callable[[Callable[[], str], Mapping[str, Any]], str]
    ] = None,
    resume_state_path: Optional[str] = None,
) -> RecoveryResult:
    """Recover, compile-check, optionally fuzz, and repair the C candidate.

    ``fuzzer_callback`` is supplied by ``main.py`` so this module reuses the
    existing SemanticFuzzer instead of creating a second fuzzing implementation.
    It receives a candidate C path and returns the normal fuzzer report.
    """

    config = config or RecoveryConfig()
    client = model_client or VertexGemini(config)
    metadata = dict(metadata or {})
    raw_initial_prompt_override = metadata.get("initial_prompt_override")
    initial_prompt_override = (
        raw_initial_prompt_override
        if isinstance(raw_initial_prompt_override, str)
        else ""
    )
    initial_prompt_has_no_system = bool(
        metadata.get("initial_prompt_has_no_system", False)
    )
    output_dir = str(Path(case_output_dir).resolve())
    os.makedirs(output_dir, exist_ok=True)
    recovery_state_path = Path(
        resume_state_path or os.path.join(output_dir, "recovery_state.json")
    )
    recovery_identity_sha256 = hashlib.sha256(
        ir_text.encode("utf-8", errors="replace")
    ).hexdigest()

    candidate = ""
    pseudo_source = None
    pseudo_path_for_api: Optional[str] = None
    last_candidate_path: Optional[str] = None
    last_error: Optional[str] = None
    last_report: Optional[Dict[str, Any]] = None
    diagnostic_history: List[str] = []
    context_safe_split_active = False
    ir_evidence_audited = False
    print(
        f"[LLM] Bắt đầu recovery loop | max_iter={config.max_iterations} | "
        f"fuzz_iter={config.fuzz_iterations}, timeout={config.fuzz_timeout}s | "
        f"context_window={config.context_window_tokens or 'provider-default'}"
    )

    backend = _text(config.pseudo_backend).strip().lower()
    if not backend or backend in {
        "llvm2c",
        "clean_pseudocode",
        "llvm-to-c",
        "llvm_to_c",
    }:
        backend_mode = "llvm2c"
    elif backend in {"2", "ir", "llvm", "raw_ir", "raw"}:
        backend_mode = "ir"
    elif backend in {"ghidra", "ghidra_pseudocode", "external_pseudocode"}:
        backend_mode = "ghidra_pseudocode"
    elif backend in {"assembly", "asm", "objdump", "raw_assembly"}:
        backend_mode = "assembly"
    else:
        raise RecoveryError(
            f"Unsupported pseudocode backend {backend!r}; use 'llvm2c', "
            "'ghidra', 'assembly', or 'ir'."
        )

    use_pseudocode = backend_mode in {
        "llvm2c",
        "ghidra_pseudocode",
        "assembly",
    }
    if backend_mode == "llvm2c":
        print(
            "[LLM] LLVM2C mode: transpile Clean LLVM IR thành C pseudocode "
            "làm model evidence."
        )
        pseudo_path = os.path.join(output_dir, "clean_pseudocode.c")
        input_ir = (
            _text(metadata.get("input_ir"))
            if isinstance(metadata, Mapping)
            else ""
        )
        if not input_ir or not os.path.isfile(input_ir):
            raise RecoveryError(
                "LLVM2C mode requires metadata.input_ir pointing to Clean LLVM IR."
            )
        try:
            from tools.llvm_to_c import transpile_llvm_ir_to_c

            transpile_llvm_ir_to_c(input_ir, pseudo_path)
            pseudo_source = Path(pseudo_path).read_text(
                encoding="utf-8",
                errors="replace",
            )
        except Exception as exc:
            raise RecoveryError(f"LLVM2C transpilation failed: {exc}") from exc
        if not pseudo_source.strip():
            raise RecoveryError("LLVM2C produced an empty pseudocode artifact.")
        pseudo_path_for_api = pseudo_path
        print(
            "[LLM] [✓] LLVM2C pseudocode ready: "
            f"{os.path.relpath(pseudo_path, output_dir)}"
        )
    elif backend_mode == "ghidra_pseudocode":
        print(
            "[LLM] Ghidra mode: use the frozen program-level pseudocode as "
            "model evidence."
        )
        pseudo_source = ir_text
        if not pseudo_source.strip():
            raise RecoveryError("Ghidra produced an empty pseudocode artifact.")
        input_pseudocode = (
            _text(metadata.get("input_ir"))
            if isinstance(metadata, Mapping)
            else ""
        )
        pseudo_path_for_api = (
            input_pseudocode if input_pseudocode and os.path.isfile(input_pseudocode)
            else None
        )
    elif backend_mode == "assembly":
        print(
            "[LLM] Assembly mode: use the frozen program-level objdump "
            "representation as model evidence."
        )
        pseudo_source = ir_text
        if not pseudo_source.strip():
            raise RecoveryError("objdump produced an empty assembly artifact.")
        input_assembly = (
            _text(metadata.get("input_ir"))
            if isinstance(metadata, Mapping)
            else ""
        )
        pseudo_path_for_api = (
            input_assembly
            if input_assembly and os.path.isfile(input_assembly)
            else None
        )
    else:
        print("[LLM] Direct IR mode: send LLVM IR as model evidence.")
        pseudo_path_for_api = None

    start_iteration = 1
    resumed_request_sha256: Optional[str] = None
    if recovery_state_path.is_file():
        try:
            saved_state = json.loads(
                recovery_state_path.read_text(encoding="utf-8")
            )
        except (OSError, ValueError):
            saved_state = {}
        if (
            saved_state.get("schema_version") == "1.0"
            and saved_state.get("ir_sha256") == recovery_identity_sha256
            and saved_state.get("max_iterations") == config.max_iterations
            and saved_state.get("status") == "REQUEST_PENDING"
        ):
            saved_iteration = int(saved_state.get("iteration", 1))
            if 1 <= saved_iteration <= config.max_iterations:
                start_iteration = saved_iteration
                candidate = _text(saved_state.get("candidate"))
                last_error = saved_state.get("last_error")
                saved_report = saved_state.get("last_report")
                last_report = (
                    dict(saved_report)
                    if isinstance(saved_report, Mapping)
                    else None
                )
                saved_history = saved_state.get("diagnostic_history")
                diagnostic_history = (
                    [str(item) for item in saved_history][-4:]
                    if isinstance(saved_history, list)
                    else []
                )
                context_safe_split_active = bool(
                    saved_state.get("context_safe_split_active", False)
                )
                ir_evidence_audited = bool(
                    saved_state.get("ir_evidence_audited", False)
                )
                resumed_request_sha256 = _text(
                    saved_state.get("request_sha256")
                ) or None
                print(
                    "[LLM] Resume recovery state tại iteration "
                    f"{start_iteration}/{config.max_iterations}."
                )

    def save_recovery_state(
        *,
        iteration: int,
        status: str,
        request_sha256: Optional[str] = None,
    ) -> None:
        payload = {
            "schema_version": "1.0",
            "status": status,
            "iteration": iteration,
            "max_iterations": config.max_iterations,
            "ir_sha256": recovery_identity_sha256,
            "request_sha256": request_sha256,
            "candidate": candidate,
            "last_error": last_error,
            "last_report": last_report,
            "diagnostic_history": diagnostic_history[-4:],
            "context_safe_split_active": context_safe_split_active,
            "ir_evidence_audited": ir_evidence_audited,
        }
        temporary = recovery_state_path.with_name(
            recovery_state_path.name + ".tmp"
        )
        temporary.write_text(
            json.dumps(
                payload,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
                default=str,
            )
            + "\n",
            encoding="utf-8",
        )
        os.replace(temporary, recovery_state_path)

    # Count both normal responses and the first response preserved before a
    # MAX_TOKENS retry.  This keeps the physical-call budget correct after an
    # interrupted process is resumed.
    response_artifacts = list(Path(output_dir).glob("recovery_iter*.response.txt"))
    max_tokens_response_artifacts = list(
        Path(output_dir).glob("recovery_iter*.max_tokens.response.txt")
    )
    total_model_calls = len(response_artifacts) + len(max_tokens_response_artifacts)
    # The flow contract owns the provider-call budget. A one-shot flow sets
    # max_iterations=1 and must remain a literal one-call flow even when the
    # provider returns MAX_TOKENS.
    max_allowed_calls = config.max_iterations

    for iteration in range(start_iteration, config.max_iterations + 1):
        if total_model_calls >= max_allowed_calls:
            print(
                f"[LLM] Đã đạt giới hạn tối đa {max_allowed_calls} model calls "
                f"(model_call_count={total_model_calls}). Dừng recovery loop.",
                flush=True,
            )
            break
        print(f"[LLM] --- Iteration {iteration}/{config.max_iterations} ---")
        def make_prompt(
            max_chars: Optional[int],
            evidence_mode: str,
        ) -> str:
            direct_ir_modes = {"llvm_ir", "raw_ir"}
            attached_label = {
                "dual": (
                    "COMPLETE LLVM2C PSEUDOCODE AND CLEANED/DELIFTED "
                    "LLVM IR ATTACHED IN THIS REQUEST"
                ),
                "pseudocode": (
                    "COMPLETE LLVM2C PSEUDOCODE ATTACHED IN THIS REQUEST"
                ),
                "ghidra_pseudocode": (
                    "COMPLETE GHIDRA PROGRAM PSEUDOCODE ATTACHED IN THIS REQUEST"
                ),
                "assembly": (
                    "COMPLETE OBJDUMP PROGRAM ASSEMBLY ATTACHED IN THIS REQUEST"
                ),
                "llvm_ir": (
                    "COMPLETE CLEANED/DELIFTED LLVM IR ATTACHED IN THIS REQUEST"
                ),
                "raw_ir": (
                    "COMPLETE RAW NON-DEOBFUSCATED LLVM IR ATTACHED IN THIS REQUEST"
                ),
            }.get(
                evidence_mode,
                "COMPLETE MODEL INPUT ARTIFACT ATTACHED IN THIS REQUEST",
            )
            if iteration == 1:
                if initial_prompt_override:
                    return initial_prompt_override
                if use_pseudocode and pseudo_source is None:
                    raise RecoveryError(
                        "LLVM2C pseudocode is missing from pseudocode mode."
                    )
                use_pseudo = (
                    use_pseudocode and evidence_mode not in direct_ir_modes
                )
                seed_text = pseudo_source if use_pseudo else ir_text
                seed_attached = bool(attachment_paths)
                return build_initial_prompt(
                    seed_text,
                    {},
                    max_chars,
                    use_pseudo=use_pseudo,
                    seed_attached_file=seed_attached,
                    attached_evidence_label=attached_label,
                    dual_ir_text=(
                        ir_text if evidence_mode == "dual" else None
                    ),
                    ir_representation=config.ir_representation,
                )
            use_pseudo = (
                use_pseudocode
                and pseudo_source is not None
                and evidence_mode not in direct_ir_modes
            )
            if (
                evidence_mode == "dual"
                and pseudo_source is not None
                and not attachment_paths
            ):
                repair_input = (
                    "<LLVM2C_PSEUDOCODE>\n"
                    f"{pseudo_source}\n"
                    "</LLVM2C_PSEUDOCODE>\n"
                    "<CLEANED_LLVM_IR>\n"
                    f"{ir_text}\n"
                    "</CLEANED_LLVM_IR>"
                )
            else:
                repair_input = pseudo_source if use_pseudo else ir_text
            source_label = {
                "dual": "LLVM2C pseudocode plus cleaned/delifted LLVM IR",
                "pseudocode": "LLVM2C transpiled pseudocode",
                "ghidra_pseudocode": "program-level Ghidra pseudocode",
                "assembly": "program-level objdump assembly",
                "llvm_ir": "cleaned/delifted LLVM IR",
                "raw_ir": "raw non-deobfuscated LLVM IR",
            }.get(
                evidence_mode,
                "LLVM2C transpiled pseudocode"
                if use_pseudo
                else "cleaned/delifted LLVM IR",
            )
            return build_repair_prompt(
                repair_input,
                candidate,
                last_error or _format_fuzz_feedback(last_report or {}),
                max_chars,
                source_label=source_label,
                evidence_attached=bool(attachment_paths),
                attached_evidence_label=attached_label,
            )

        response: Optional[str] = None
        last_request_error: Optional[str] = None
        current_request_uses_ir = False
        try:
            print(
                f"[LLM] Requesting model={config.model} | "
                f"request_timeout={config.request_timeout}s | "
                f"max_output_tokens={config.max_output_tokens} | "
                f"thinking_level={config.thinking_level or 'default'}"
            )
            attachment_paths: List[str] = []
            pseudo_attachment: Optional[str] = None
            ir_attachment: Optional[str] = None
            if config.use_file_api:
                input_ir_path = (
                    _text(metadata.get("input_ir"))
                    if isinstance(metadata, Mapping)
                    else ""
                )
                if use_pseudocode:
                    if (
                        not pseudo_path_for_api
                        or not os.path.isfile(pseudo_path_for_api)
                    ):
                        raise RecoveryError(
                            "File-API recovery enabled but LLVM2C pseudocode "
                            "is unavailable."
                        )
                    pseudo_attachment = pseudo_path_for_api
                    attachment_paths = [pseudo_attachment]
                    if config.attach_clean_ir:
                        if not input_ir_path or not os.path.isfile(
                            input_ir_path
                        ):
                            raise RecoveryError(
                                "File-API recovery enabled but cleaned LLVM IR "
                                f"is unavailable: {input_ir_path or '<missing>'}"
                            )
                        ir_attachment = input_ir_path
                        attachment_paths.append(ir_attachment)
                else:
                    if input_ir_path and os.path.isfile(input_ir_path):
                        ir_attachment = input_ir_path
                        attachment_paths = [ir_attachment]

            evidence_mode = (
                "dual"
                if use_pseudocode and config.attach_clean_ir
                else "ghidra_pseudocode"
                if backend_mode == "ghidra_pseudocode"
                else "assembly"
                if backend_mode == "assembly"
                else "pseudocode"
                if use_pseudocode
                else "raw_ir"
                if _text(config.ir_representation).lower() == "raw"
                else "llvm_ir"
            )
            system_prompt = (
                ""
                if iteration == 1
                and initial_prompt_override
                and initial_prompt_has_no_system
                else build_system_prompt(
                    config.attach_clean_ir,
                    evidence_mode=evidence_mode,
                )
            )
            model_prompt = make_prompt(None, evidence_mode)
            initial_context = _recovery_context_check(
                config,
                system_prompt,
                model_prompt,
                attachment_paths,
            )
            selected_context = initial_context
            if (
                evidence_mode == "dual"
                and not initial_context["fit"]
                and pseudo_attachment
                and ir_attachment
            ):
                context_safe_split_active = True
                if iteration == 1:
                    evidence_mode = "pseudocode"
                    attachment_paths = [pseudo_attachment]
                elif not ir_evidence_audited or iteration % 2 == 0:
                    evidence_mode = "llvm_ir"
                    attachment_paths = [ir_attachment]
                else:
                    evidence_mode = "pseudocode"
                    attachment_paths = [pseudo_attachment]
                system_prompt = (
                    ""
                    if iteration == 1
                    and initial_prompt_override
                    and initial_prompt_has_no_system
                    else build_system_prompt(
                        config.attach_clean_ir,
                        evidence_mode=evidence_mode,
                    )
                )
                model_prompt = make_prompt(None, evidence_mode)
                selected_context = _recovery_context_check(
                    config,
                    system_prompt,
                    model_prompt,
                    attachment_paths,
                )
                print(
                    "[LLM] Dual evidence vượt local context gate; "
                    f"round này dùng {evidence_mode}, round kế tiếp đổi nguồn.",
                    flush=True,
                )

            context_record = {
                "schema_version": "1.0",
                "iteration": iteration,
                "prompt_policy_version": P0_PROMPT_POLICY_VERSION,
                "evidence_mode": evidence_mode,
                "context_safe_split_active": context_safe_split_active,
                "dual_request": initial_context,
                "selected_request": selected_context,
            }
            Path(
                os.path.join(
                    output_dir,
                    f"recovery_iter{iteration}.context.json",
                )
            ).write_text(
                json.dumps(
                    context_record,
                    ensure_ascii=True,
                    indent=2,
                    sort_keys=True,
                )
                + "\n",
                encoding="utf-8",
            )
            if not selected_context["fit"]:
                overflow = (
                    int(selected_context["required_tokens"])
                    - int(selected_context["context_window_tokens"])
                )
                raise LLMContextOverflowError(
                    "P0 request exceeds context window after evidence "
                    f"scheduling by {overflow} estimated tokens "
                    f"(mode={evidence_mode})"
                )
            current_request_uses_ir = evidence_mode in {
                "dual",
                "llvm_ir",
                "raw_ir",
            }
            print(
                "[LLM] Readable evidence attachments "
                f"(mode={evidence_mode}, estimated_input_tokens="
                f"{selected_context['estimated_input_tokens']}): "
                + (
                    ", ".join(
                        os.path.basename(path)
                        for path in attachment_paths
                    )
                    or "<inline prompt>"
                ),
                flush=True,
            )
            request_hasher = hashlib.sha256()
            request_hasher.update(system_prompt.encode("utf-8"))
            request_hasher.update(b"\0")
            request_hasher.update(model_prompt.encode("utf-8"))
            for attachment_path in attachment_paths:
                request_hasher.update(b"\0")
                request_hasher.update(
                    os.path.basename(attachment_path).encode("utf-8")
                )
                request_hasher.update(b"\0")
                with open(attachment_path, "rb") as attachment_handle:
                    for chunk in iter(
                        lambda: attachment_handle.read(1024 * 1024), b""
                    ):
                        request_hasher.update(chunk)
            request_sha256 = request_hasher.hexdigest()
            if (
                iteration == start_iteration
                and resumed_request_sha256 is not None
                and request_sha256 != resumed_request_sha256
            ):
                raise RecoveryError(
                    "Refusing recovery resume because the exact request hash "
                    f"drifted: expected {resumed_request_sha256}, "
                    f"computed {request_sha256}"
                )
            save_recovery_state(
                iteration=iteration,
                status="REQUEST_PENDING",
                request_sha256=request_sha256,
            )

            def send_request() -> str:
                return client.generate(
                    model_prompt,
                    attachment_paths=attachment_paths,
                    system_instruction=system_prompt,
                )

            # Persist the exact request material before the provider call. This
            # is append-only evaluation evidence and does not alter prompting.
            Path(
                os.path.join(output_dir, f"recovery_iter{iteration}.prompt.txt")
            ).write_text(model_prompt, encoding="utf-8")
            Path(
                os.path.join(output_dir, f"recovery_iter{iteration}.system.txt")
            ).write_text(system_prompt, encoding="utf-8")

            request_context = {
                "iteration": iteration,
                "request_sha256": request_sha256,
                "max_iterations": config.max_iterations,
                "prompt_policy_version": P0_PROMPT_POLICY_VERSION,
                "evidence_mode": evidence_mode,
            }
            response = (
                request_executor(send_request, request_context)
                if request_executor is not None
                else send_request()
            )
            total_model_calls += 1
            response_meta = dict(getattr(client, "last_response_meta", {}) or {})
            finish_reason = _text(response_meta.get("finish_reason"))
            usage = response_meta.get("usage_metadata") or {}
            print(
                f"[LLM] Đã nhận phản hồi từ model (iter={iteration}) | "
                f"finishReason={finish_reason or 'UNSPECIFIED'} | "
                f"promptTokens={usage.get('prompt_token_count', usage.get('promptTokenCount', '?'))} | "
                f"outputTokens={usage.get('candidates_token_count', usage.get('candidatesTokenCount', '?'))}"
            )
            if finish_reason.upper() == "MAX_TOKENS":
                current_thinking = _text(config.thinking_level).upper()
                reduced_thinking = {
                    "HIGH": "LOW",
                    "MEDIUM": "LOW",
                    "LOW": "MINIMAL",
                    "": "LOW",
                }.get(current_thinking)
                if reduced_thinking:
                    if total_model_calls >= max_allowed_calls:
                        print(
                            f"[LLM] MAX_TOKENS xảy ra nhưng đã đạt giới hạn {max_allowed_calls} model calls "
                            f"(model_call_count={total_model_calls}). Bỏ qua retry.",
                            flush=True,
                        )
                    else:
                        Path(
                            os.path.join(
                                output_dir,
                                f"recovery_iter{iteration}.max_tokens.response.txt",
                            )
                        ).write_text(response, encoding="utf-8")
                        Path(
                            os.path.join(
                                output_dir,
                                f"recovery_iter{iteration}.max_tokens.meta.json",
                            )
                        ).write_text(
                            json.dumps(
                                response_meta,
                                ensure_ascii=True,
                                indent=2,
                                default=str,
                            ),
                            encoding="utf-8",
                        )
                        config.thinking_level = reduced_thinking
                        client_config = getattr(client, "config", None)
                        if client_config is not None:
                            client_config.thinking_level = reduced_thinking
                        print(
                            "[LLM] MAX_TOKENS: retry cùng iteration với "
                            f"thinking_level={reduced_thinking} để dành ngân sách "
                            "cho source C hoàn chỉnh.",
                            flush=True,
                        )
                        retry_identity = hashlib.sha256(
                            (
                                request_sha256
                                + "\0max_tokens_retry\0"
                                + reduced_thinking
                            ).encode("utf-8")
                        ).hexdigest()
                        retry_context = {
                            **request_context,
                            "request_sha256": retry_identity,
                            "retry_reason": "MAX_TOKENS",
                            "thinking_level": reduced_thinking,
                        }
                        response = (
                            request_executor(send_request, retry_context)
                            if request_executor is not None
                            else send_request()
                        )
                        total_model_calls += 1
                        response_meta = dict(
                            getattr(client, "last_response_meta", {}) or {}
                        )
                        retry_finish = _text(
                            response_meta.get("finish_reason")
                        )
                        retry_usage = response_meta.get("usage_metadata") or {}
                        print(
                            f"[LLM] Retry MAX_TOKENS nhận phản hồi "
                            f"(iter={iteration}) | "
                            f"finishReason={retry_finish or 'UNSPECIFIED'} | "
                            "promptTokens="
                            f"{retry_usage.get('prompt_token_count', retry_usage.get('promptTokenCount', '?'))} | "
                            "outputTokens="
                            f"{retry_usage.get('candidates_token_count', retry_usage.get('candidatesTokenCount', '?'))}",
                            flush=True,
                        )
        except LLMRateLimitError as exc:
            # 429 rate limit: exponential backoff with jitter
            import time as _time
            import random as _random
            _RATE_LIMIT_MAX_RETRIES = 120
            last_request_error = str(exc)
            print(
                f"[LLM] Model request lỗi: {last_request_error}",
                flush=True,
            )
            _rl_success = False
            for _rl_attempt in range(1, _RATE_LIMIT_MAX_RETRIES + 1):
                # exponential backoff: 2, 4, 8, 16, 32, up to 60s, plus 0-5s jitter
                backoff = min(60, (2 ** min(_rl_attempt, 6)) * 2)
                jitter = _random.uniform(0, 5)
                sleep_time = backoff + jitter
                print(
                    f"[LLM] Rate limit 429 — chờ {sleep_time:.1f}s rồi thử lại "
                    f"(lần {_rl_attempt}/{_RATE_LIMIT_MAX_RETRIES})...",
                    flush=True,
                )
                _time.sleep(sleep_time)
                try:
                    response = (
                        request_executor(send_request, request_context)
                        if request_executor is not None
                        else send_request()
                    )
                    total_model_calls += 1
                    response_meta = dict(getattr(client, "last_response_meta", {}) or {})
                    finish_reason = _text(response_meta.get("finish_reason"))
                    usage = response_meta.get("usage_metadata") or {}
                    print(
                        f"[LLM] Rate limit retry thành công (lần {_rl_attempt}) | "
                        f"finishReason={finish_reason or 'UNSPECIFIED'} | "
                        f"promptTokens={usage.get('prompt_token_count', usage.get('promptTokenCount', '?'))} | "
                        f"outputTokens={usage.get('candidates_token_count', usage.get('candidatesTokenCount', '?'))}",
                        flush=True,
                    )
                    _rl_success = True
                    break
                except LLMRateLimitError as _rl_exc:
                    last_request_error = str(_rl_exc)
                    print(
                        f"[LLM] Vẫn bị rate limit (lần {_rl_attempt}): {last_request_error}",
                        flush=True,
                    )
                except RecoveryError as _rl_exc:
                    last_request_error = str(_rl_exc)
                    print(
                        f"[LLM] Lỗi khác sau rate limit retry (lần {_rl_attempt}): {last_request_error}",
                        flush=True,
                    )
                    raise
            if not _rl_success:
                print(
                    f"[LLM] Đã thử {_RATE_LIMIT_MAX_RETRIES} lần trong 1 tiếng nhưng vẫn bị rate limit. Dừng.",
                    flush=True,
                )
                raise RecoveryError(last_request_error or "Rate limit exhausted after 120 retries")
        except RecoveryError as exc:
            last_request_error = str(exc)
            print(f"[LLM] Model request lỗi: {last_request_error}")
            if isinstance(exc, LLMEmptyResponseError):
                print(f"[LLM] [!] Nhận phản hồi rỗng từ Vertex REST (safety block/recitation/timeout). Bỏ qua và tiếp tục vòng lặp sửa lỗi.")
                last_error = f"LLM empty response: {exc}"
                continue
            raise
        if response is None:
            print(f"[LLM] Không nhận được phản hồi model ở iteration {iteration}")
            raise RecoveryError(last_request_error or "Failed to get response from LLM")

        response_path = os.path.join(output_dir, f"recovery_iter{iteration}.response.txt")
        os.makedirs(output_dir, exist_ok=True)
        Path(response_path).write_text(response, encoding="utf-8")
        Path(os.path.join(output_dir, f"recovery_iter{iteration}.meta.json")).write_text(
            json.dumps(response_meta, ensure_ascii=True, indent=2, default=str),
            encoding="utf-8",
        )
        try:
            candidate = _sanitize_recovered_candidate(extract_c_source(response, require_json=config.require_json))
        except RecoveryError as exc:
            parse_error = str(exc)
            if _text(response_meta.get("finish_reason")).upper() == "MAX_TOKENS":
                parse_error += (
                    " Vertex finishReason=MAX_TOKENS: model hit its output ceiling; "
                    "the response is incomplete."
                )
            last_error = f"LLM output rejected before compile: {parse_error}"
            partial = _extract_partial_response(response)
            if partial and "#include" in partial:
                # Do not feed a truncated translation unit back to the model: it
                # anchors the next round on the same broken prefix. The raw response
                # is already persisted for inspection; the next round must regenerate
                # the complete unit from the artifact and validation feedback.
                candidate = ""
                last_error += (
                    " The previous response was truncated and was discarded. "
                    "Regenerate one complete translation unit from the attached/original "
                    "artifact; do not return another partial response."
                )
                print(
                    f"[LLM] Iteration {iteration}: partial source discarded, "
                    "regenerate from artifact, không compile"
                )
            else:
                candidate = ""
            Path(os.path.join(output_dir, f"recovery_iter{iteration}.parse.txt")).write_text(
                last_error,
                encoding="utf-8",
            )
            if not candidate:
                print(f"[LLM] Iteration {iteration}: candidate bị reject trước compile: {parse_error}")
            continue

        if not candidate.strip():
            last_error = "Recovered candidate is empty after sanitation."
            print(f"[LLM] Iteration {iteration}: candidate trống sau sanitize, bỏ qua round này.")
            continue

        candidate_path = os.path.join(output_dir, f"recovered_iter{iteration}.c")
        Path(candidate_path).write_text(candidate, encoding="utf-8")
        last_candidate_path = candidate_path
        print(f"[LLM] Iteration {iteration}: đã sinh candidate -> {os.path.relpath(candidate_path, output_dir)}")

        try:
            compiled, compile_error = _run_compile_check(candidate_path, output_dir)
        except Exception as exc:
            compiled, compile_error = False, str(exc)
        if not compiled:
            compile_diagnostic = (
                "Compilation failed:\n"
                + (compile_error or "unknown compiler error")
            )
            if diagnostic_history:
                compile_diagnostic += (
                    "\n\nPRIOR ROUND HISTORY:\n- "
                    + "\n- ".join(diagnostic_history[-4:])
                )
            last_error = compile_diagnostic
            diagnostic_history.append(
                f"round={iteration}: compilation_failed: "
                f"{_diagnostic_text(compile_error, 1000)}"
            )
            diagnostic_history[:] = diagnostic_history[-4:]
            Path(os.path.join(output_dir, f"recovery_iter{iteration}.compile.txt")).write_text(last_error, encoding="utf-8")
            print(f"[LLM] Iteration {iteration}: compile fail: {(compile_error or '').strip()[:800]}")
            continue

        if current_request_uses_ir:
            ir_evidence_audited = True

        if fuzzer_callback is None:
            shutil.copy2(candidate_path, output_recovered_c_path)
            print(f"[LLM] Iteration {iteration}: compile OK, no fuzz callback, mark success.")
            save_recovery_state(iteration=iteration, status="COMPLETED")
            return RecoveryResult(True, output_recovered_c_path, iteration)

        try:
            last_report = dict(fuzzer_callback(candidate_path))
        except Exception as exc:
            last_error = f"Fuzzing callback failed: {exc}"
            print(f"[LLM] Iteration {iteration}: fuzz callback lỗi: {exc}")
            continue
        ratio = last_report.get("equivalence_ratio", 0.0)
        mismatches = last_report.get("mismatches", 0)
        matches = last_report.get("matches", 0)
        print(
            f"[LLM] Iteration {iteration}: fuzz ratio={ratio:.2f}%, "
            f"matches={matches}, mismatches={mismatches}, "
            f"inconclusive={last_report.get('inconclusive', 0)}"
        )
        if confirmed_equivalence_pass(last_report):
            if (
                context_safe_split_active
                and config.attach_clean_ir
                and not ir_evidence_audited
                and iteration < config.max_iterations
                and total_model_calls < max_allowed_calls
            ):
                last_error = (
                    "The candidate compiled and passed the current differential "
                    "sample, but the oversized dual-evidence request was split. "
                    "Before acceptance, regenerate or confirm the complete C "
                    "against the cleaned/delifted LLVM IR evidence, preserving "
                    "all behavior already recovered from pseudocode."
                )
                diagnostic_history.append(
                    f"round={iteration}: semantic_pass_pending_ir_crosscheck"
                )
                diagnostic_history[:] = diagnostic_history[-4:]
                print(
                    "[LLM] Semantic pass tạm thời; bắt buộc thêm một round "
                    "cross-check cleaned IR trước khi accept.",
                    flush=True,
                )
                continue
            print(f"[LLM] Iteration {iteration}: semantic pass, accept candidate.")
            shutil.copy2(candidate_path, output_recovered_c_path)
            save_recovery_state(iteration=iteration, status="COMPLETED")
            return RecoveryResult(True, output_recovered_c_path, iteration, fuzz_report=last_report)
        last_error = _format_fuzz_feedback(
            last_report,
            prior_history=diagnostic_history,
        )
        diagnostic_history.append(
            _compact_fuzz_round(iteration, last_report)
        )
        diagnostic_history[:] = diagnostic_history[-4:]
        print(f"[LLM] Iteration {iteration}: chưa pass semantic, tiếp tục sửa.")

    # Keep the last generated candidate for inspection even when equivalence is
    # not confirmed; this is useful input for the next manual tuning round.
    if last_candidate_path and os.path.isfile(last_candidate_path):
        shutil.copy2(last_candidate_path, output_recovered_c_path)
        print("[LLM] Đã kết thúc loop mà chưa đạt semantic. Giữ candidate cuối cùng để debug.")
        save_recovery_state(
            iteration=config.max_iterations, status="COMPLETED"
        )
        return RecoveryResult(False, output_recovered_c_path, config.max_iterations, last_error, last_report)

    print("[LLM] Không tạo được candidate hợp lệ trong toàn bộ vòng lặp.")
    save_recovery_state(
        iteration=config.max_iterations, status="COMPLETED"
    )
    return RecoveryResult(False, None, config.max_iterations, last_error, last_report)
