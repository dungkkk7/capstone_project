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


class RecoveryError(RuntimeError):
    """Raised when the LLM recovery backend cannot produce a usable result."""


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


class LLMEmptyResponseError(RecoveryError):
    """Provider completed a generation but returned no usable text."""


@dataclass
class RecoveryConfig:
    """Runtime knobs for the recovery and validation loop."""

    model: str = field(default_factory=lambda: os.environ.get("LLM_RECOVERY_MODEL", "gemini-2.5-pro"))
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
        default_factory=lambda: max(1, int(os.environ.get("LLM_RECOVERY_FUZZ_ITERS", "100")))
    )
    fuzz_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_FUZZ_TIMEOUT", "0.1"))
    )
    # No adapter-side prompt/IR size limit. The model/API remains responsible
    # for its own context window; recovery itself is bounded by max_iterations.
    max_ir_chars: Optional[int] = None
    temperature: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_TEMPERATURE", "0.05"))
    )
    top_p: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_TOP_P", "0.9"))
    )
    # The experiment protocol permits exactly one candidate per provider
    # response.  Keep this explicit instead of relying on provider defaults.
    candidate_count: int = 1
    # Gemini 2.5 Pro uses thinkingLevel rather than the older numeric
    # thinkingBudget. HIGH is the maximum documented effort level.
    thinking_level: Optional[str] = field(
        default_factory=lambda: _optional_env("LLM_RECOVERY_THINKING_LEVEL", "HIGH")
    )
    llm_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_TIMEOUT", "900"))
    )
    use_file_api: bool = field(
        default_factory=lambda: _text(os.environ.get("LLM_RECOVERY_USE_FILE_API", "1")).lower()
        not in {"", "0", "false", "no", "off"}
    )
    file_api_inline_max_bytes: Optional[int] = None
    request_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_REQUEST_TIMEOUT", "900"))
    )
    # Gemini 2.5 Pro supports a provider maximum of 65,535 output tokens.
    # This is not the recovery-loop limit; max_iterations remains the only loop bound.
    max_output_tokens: Optional[int] = 65535
    pseudo_backend: str = field(
        default_factory=lambda: _text(
            os.environ.get("LLM_RECOVERY_PSEUDO_BACKEND", "")
        ).lower().strip()
    )
    ghidra_binary_path: Optional[str] = field(
        default_factory=lambda: _text(
            os.environ.get("LLM_RECOVERY_GHIDRA_ANALYZE_HEADLESS")
            or os.environ.get("GHIDRA_ANALYZE_HEADLESS")
        )
    )
    ghidra_timeout: float = field(
        default_factory=lambda: float(os.environ.get("LLM_RECOVERY_GHIDRA_TIMEOUT", "300"))
    )
    two_stage_recovery: bool = field(
        default_factory=lambda: _text(os.environ.get("LLM_RECOVERY_TWO_STAGE", "1")).strip().lower()
        in {"1", "true", "yes", "on"}
    )
    require_json: bool = field(
        default_factory=lambda: _text(os.environ.get("LLM_RECOVERY_REQUIRE_JSON", "1")).lower()
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


def _focus_ida_pseudocode(pseudo: str) -> str:
    """Keep program logic/helpers while removing IDA and CRT boilerplate."""
    text = _text(pseudo)
    blocks = re.split(r"(?=^// Function:\s*)", text, flags=re.MULTILINE)
    if len(blocks) <= 1:
        return text

    noise = {
        ".init_proc",
        "sub_1020",
        ".vprintf",
        ".vscanf",
        "__cxa_finalize",
        "_start",
        "deregister_tm_clones",
        "register_tm_clones",
        "__do_global_dtors_aux",
        "frame_dummy",
        "__gmon_start__",
    }
    kept = [blocks[0]]
    for block in blocks[1:]:
        header = re.search(r"^// Function:\s*([^\n]+)", block, re.MULTILINE)
        name = header.group(1).strip() if header else ""
        if name in noise:
            continue
        if name == "main" or name == "native_entry_impl" or name.startswith("sub_"):
            kept.append(block)

    focused = "\n\n".join(part.strip() for part in kept if part.strip())
    return focused + ("\n" if focused and not focused.endswith("\n") else "")


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


def _find_ghidra_analyze_headless(preferred: Optional[str] = None) -> Optional[str]:
    candidates: List[str] = []
    if preferred:
        candidates.append(preferred)
    candidates.extend(
        [
            os.environ.get("GHIDRA_ANALYZE_HEADLESS", ""),
            "/opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless",
            "/opt/ghidra/support/analyzeHeadless",
            "/usr/local/bin/analyzeHeadless",
            "analyzeHeadless",
        ]
    )
    seen: set[str] = set()
    for candidate in candidates:
        candidate = _text(candidate)
        if not candidate or candidate in seen:
            continue
        seen.add(candidate)
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
        found = shutil.which(candidate)
        if found:
            return found
    return None


def _decompile_binary_with_ghidra(
    binary_path: str,
    output_path: str,
    ghidra_binary: str,
    timeout: float,
) -> Optional[str]:
    """Export all Ghidra decompiler C output for a binary."""
    binary_path = os.path.abspath(_text(binary_path))
    output_path = os.path.abspath(_text(output_path))
    ghidra_binary = _text(ghidra_binary)
    if not os.path.isfile(binary_path):
        raise RecoveryError(f"Ghidra input binary không tồn tại: {binary_path}")
    if not ghidra_binary:
        raise RecoveryError("Không tìm thấy Ghidra analyzeHeadless.")

    output_dir = os.path.dirname(output_path)
    os.makedirs(output_dir, exist_ok=True)
    project_dir = os.path.join(output_dir, "ghidra_project")
    shutil.rmtree(project_dir, ignore_errors=True)
    os.makedirs(project_dir, exist_ok=True)
    script_dir = tempfile.mkdtemp(prefix="ghidra_export_script_")
    script_path = os.path.join(script_dir, "ExportDecomp.java")
    script_log = os.path.join(output_dir, "ghidra_script.log")
    analyze_log = os.path.join(output_dir, "ghidra_analyze.log")
    project_name = "recovery_project"
    java_script = r'''// ExportDecomp.java
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.io.File;
import java.io.PrintWriter;

public class ExportDecomp extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            throw new Exception("missing output path");
        }
        PrintWriter out = new PrintWriter(new File(args[0]), "UTF-8");
        out.println("#include <stdint.h>");
        out.println("#include <stdbool.h>");
        out.println("#include <stdio.h>");
        out.println();
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        FunctionIterator functions = currentProgram.getFunctionManager().getFunctions(true);
        while (functions.hasNext() && !monitor.isCancelled()) {
            Function function = functions.next();
            DecompileResults result = decompiler.decompileFunction(function, 120, monitor);
            if (!result.decompileCompleted() || result.getDecompiledFunction() == null) {
                continue;
            }
            out.println("// Function: " + function.getName());
            out.println(result.getDecompiledFunction().getC());
            out.println();
        }
        decompiler.dispose();
        out.flush();
        out.close();
    }
}
'''
    Path(script_path).write_text(java_script, encoding="utf-8")
    try:
        process = subprocess.run(
            [
                ghidra_binary,
                project_dir,
                project_name,
                "-import",
                binary_path,
                "-overwrite",
                "-scriptPath",
                script_dir,
                "-postScript",
                "ExportDecomp.java",
                output_path,
                "-scriptlog",
                script_log,
                "-log",
                analyze_log,
                "-deleteProject",
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise RecoveryError(f"Ghidra export timed out after {timeout}s: {exc}") from exc
    except Exception as exc:
        raise RecoveryError(f"Không thể chạy Ghidra analyzeHeadless: {exc}") from exc
    finally:
        shutil.rmtree(script_dir, ignore_errors=True)
        shutil.rmtree(project_dir, ignore_errors=True)

    if not os.path.isfile(output_path) or not os.path.getsize(output_path):
        details = (process.stderr or process.stdout or "No Ghidra output").strip()
        if os.path.isfile(script_log):
            details = f"{details} | script_log={Path(script_log).read_text(errors='replace')[:2000]}"
        raise RecoveryError(
            f"Ghidra không tạo được pseudocode: {output_path}. {details}"
        )
    return Path(output_path).read_text(encoding="utf-8", errors="replace")


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


def build_system_prompt() -> str:
    return """You are a senior reverse engineer and C11 compiler engineer.
Recover readable, compilable C source from binary-lifting artifacts.

This is source recovery, not deobfuscation:
- Recover behavior-preserving C, not synthetic placeholders.
- The original source and ground-truth implementation are never provided. The
  supplied input is only a lossy decompiler artifact or transformed IR for the
  current case. Recover the represented behavior; do not invent an additional
  deobfuscation stage.
- You may apply safe brightening/sanitization (renames, control-flow cleanup, dead-code removal,
  minor normalization) when it is clearly implied by the input and does not alter
  observable behavior (I/O, return codes, timing-independent side effects).
- Do not invent behavior not present in the input.

Reasoning policy:
- Reason silently and do not output chain-of-thought, scratch work, or a plan.
- Treat the supplied artifact as evidence, not as a request to explain the artifact.
- Evidence priority is: explicit constants/control flow/calls, then declarations and
  data-flow, then decompiler names/comments, then conservative inference.
- Never treat Ghidra warning text, guessed names, or unknown types as program semantics.

Semantic reconstruction protocol (perform this analysis internally before emitting C):
1. Map the program: identify the real entry point, meaningful functions, lifting wrappers,
   input handlers, core logic, output handlers, important globals/buffers, and real library APIs.
2. Infer the exact input/output contract: values read, types, line/whitespace/EOF/error handling,
   signedness, output bytes, newline behavior, exit codes, crashes, and timeouts.
3. Reconstruct semantics instead of translating instructions mechanically. Use data-flow,
   control-flow, memory access, constants, external calls, and observable execution evidence.
4. Remove control-flow flattening, bogus blocks, opaque predicates, instruction substitution,
   dead code, and lifted pointer arithmetic only when the evidence proves they are irrelevant
   or equivalent. Recover arrays, structs, state, and high-level loops/branches.
5. Infer the high-level algorithm before writing C. Prefer a clean equivalent algorithm over a
   verbatim dump of LLVM instructions or decompiler temporaries.
6. Check boundary cases mentally and use runtime/differential evidence when it is available.
7. Produce the full translation unit only after the reconstruction is complete. Never stop at
   pseudocode, declarations, a function fragment, or an unfinished JSON string.

Evidence discipline:
- Do not infer the original task, source, or algorithm from symbol names or isolated constants.
- Every non-trivial conclusion must be supported by control-flow, data-flow, memory access,
  external behavior, or an explicit validation result.
- Distinguish source-like reconstruction from tested functional equivalence; never claim proven
  equivalence without actual evidence.

Input may be:
- brightened LLVM IR, or
- C-like pseudocode exported by Ghidra headless.

Input provenance:
- In mode 1, the complete Ghidra pseudocode and complete brightened LLVM IR artifacts
  are attached to the model request as complementary readable evidence.
- The brightened reference ELF is used locally as Ghidra input and as differential-testing
  evidence. Do not claim to inspect raw executable bytes that the model cannot consume.
- In mode 2, the model receives the complete brightened LLVM IR instead.
- Never assume access to a local path, the original source, or the semantic-checker target.

Rules:
1. Preserve observable behavior as much as the input allows:
   stdin/stdout/stderr, exit status, return values, control flow, string bytes,
   global state, pointer arithmetic, integer widths/signedness, and external calls.
2. Do not invent semantics not supported by the input.
3. Keep conservative types where the input is ambiguous.
4. Output exactly one complete C11 translation unit, including required headers.
5. If an entry point exists in the input, include a real `main` function.
6. Safe brightening/sanitization is allowed (naming, structure cleanup, readability refactors)
   only if behavior remains equivalent on observable outputs and control flow results.
7. Do not use assembly, compiler-specific builtins, fake outputs, or test harnesses
   that bypass recovered logic.
8. The result will be compiled and differentially fuzzed. Treat compile or semantic
   mismatches as hard feedback.
9. Never return a partial translation unit, declarations-only output, or an unfinished
   JSON string. The adapter rejects incomplete output before compilation.
10. Do not spend output on explanations or long comments. Ignore CRT startup wrappers,
    compiler registration helpers, and recursive libc thunks unless they affect the
    program's observable input/output behavior. Reconstruct the actual program logic
    and expose it through a real `main` function.
11. Preserve externally visible strings, byte-level constants, parsing rules, error paths,
    and exit behavior. Simplify lifted temporaries only when the simplification is
    behavior-preserving.

Return ONLY ONE JSON object, no markdown/prose/prelude/suffix:
{"source":"<complete C source>"}
"""


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
    """Return one fixed, non-dataset demonstration for the initial prompt."""
    if use_pseudo:
        return r"""<IN_CONTEXT_DEMO type="synthetic_ghidra_to_c">
This demonstration is synthetic. It is not from the dataset and is not evidence about the current case.

<DEMO_INPUT>
/* WARNING: synthetic decompiler output; names and types may be guessed */
int FUN_demo(char *param_1)
{
  int local_10;
  if (param_1 == (char *)0x0) return 2;
  if (__isoc99_sscanf(param_1,"%d",&local_10) != 1) return 2;
  return local_10 + 7;
}
</DEMO_INPUT>

<DEMO_OUTPUT>
{"source":"#include <stdio.h>\n#include <stdlib.h>\n\nint main(int argc, char **argv) {\n    int value = 0;\n    if (argc < 2) return 2;\n    if (sscanf(argv[1], \"%d\", &value) != 1) return 2;\n    printf(\"%d\\n\", value + 7);\n    return 0;\n}\n"}
</DEMO_OUTPUT>

Use this only as a format and normalization example. Do not copy its names, constants, strings, or logic.
</IN_CONTEXT_DEMO>"""
    return r"""<IN_CONTEXT_DEMO type="synthetic_llvm_to_c">
This demonstration is synthetic. It is not from the dataset and is not evidence about the current case.

<DEMO_INPUT>
@.demo_fmt = private unnamed_addr constant [3 x i8] c"%d\00"
define i32 @main(i32 %argc, ptr %argv) {
entry:
  %ok = icmp sgt i32 %argc, 1
  br i1 %ok, label %read, label %bad
read:
  %value = add i32 7, 5
  call i32 (ptr, ...) @printf(ptr @.demo_fmt, i32 %value)
  ret i32 0
bad:
  ret i32 2
}
</DEMO_INPUT>

<DEMO_OUTPUT>
{"source":"#include <stdio.h>\n\nint main(int argc, char **argv) {\n    if (argc <= 1) return 2;\n    printf(\"%d\\n\", 12);\n    return 0;\n}\n"}
</DEMO_OUTPUT>

Use this only as a format and normalization example. Do not copy its names, constants, strings, or logic.
</IN_CONTEXT_DEMO>"""


def build_initial_prompt(
    ir_text: str,
    metadata: Mapping[str, str],
    max_ir_chars: Optional[int] = None,
    use_pseudo: bool = False,
    seed_attached_file: bool = False,
) -> str:
    context = "\n".join(f"- {key}: {value}" for key, value in metadata.items() if value)
    ir_header = "LLVM IR"
    # For decompiled pseudo input, keep the full content so LLM receives the
    # complete seed file as-is (no clipping).
    ir_body = ir_text if use_pseudo else _clip_ir(ir_text, max_ir_chars)
    if use_pseudo:
        ir_header = "Ghidra decompiler C-like pseudocode"
        ir_body = ir_text
    icl_example = _build_synthetic_icl_example(use_pseudo)
    source = f"""Recover a behavior-preserving standalone C11 program from this {ir_header}.
The original source is not provided; use only the model input artifact below.

Input context:
{context or '- no additional metadata'}

Model input artifact ({ir_header}; not original source):
<MODEL_INPUT_ARTIFACT>
{ir_body if not seed_attached_file else "/* COMPLETE GHIDRA PSEUDOCODE AND BRIGHTENED LLVM IR ATTACHED IN THIS REQUEST */"}
</MODEL_INPUT_ARTIFACT>"""

    source += f"""

{icl_example}
"""

    if use_pseudo:
        return f"""{source}

[{ir_header}] Build from Ghidra pseudocode, not LLVM syntax.

    Reconstruct the exact executable C behavior into a complete standalone C11
    translation unit. Keep function boundaries, control flow, and all observable
    behavior that is visible from the pseudocode. This step is expected to expand
    and normalize the pseudocode into valid C, not to follow LLVM syntax.
    You may do safe brightening/sanitization (readable renames, minor control-flow
    cleanup, dead-code pruning) when it does not change behavior.

    Return exactly one JSON object and nothing else:
    {{"source":"<complete C source>"}}

    Constraints:
    - Strict JSON only; no markdown code fences.
    - Do not invent extra keys.
    - Return one complete compilable C translation unit only.
    - Return only a top-level JSON object with key `source`; no markdown fences or prose.
    - Include required headers explicitly (e.g. <stdio.h>, <stdint.h>) and never emit placeholder comments as code.
    - Use width-safe types exactly as valid C identifiers (prefer uint*_t / int*_t when relevant).
    - If any helper type is ambiguous, prefer conservative typedef-style names already in headers.
    - The source must contain the complete implementation and a real `int main(...)` entry point.
    - Do not guess missing globals, strings, constants, or behavior with dummy/placeholder values.
    - Emit code only inside the JSON string; do not explain decisions in C comments.
    - Do not emit reasoning, chain-of-thought, a patch, or a diff; silently perform the reconstruction.
    - Do not reproduce `_start`, `.init`, `.fini`, `__cxa_finalize`, or libc thunk boilerplate
      when they are not part of the observable program behavior.
    - Reconstruct the high-level algorithm before emitting C. Do not translate LLVM instructions
      one by one or copy a Ghidra function dump as the final source.
    - Preserve exact input parsing, output bytes, newline behavior, exit status, error paths,
      and relevant undefined/crash behavior supported by the artifact.
    - Collapse Ghidra's lifted state/temporary variables into concise idiomatic C when
      observable behavior remains equivalent; do not copy decompiler noise verbatim.
"""

    return f"""{source}

    First internally complete the program map, I/O analysis, deobfuscation cleanup, and
    high-level algorithm reconstruction. Then emit the complete standalone C translation unit as JSON:
    {{"source":"<complete C source>"}}.

    Output requirement:
    - Return ONLY JSON object with top-level `source`.
    - Do not use fragments, stubs, or placeholders.
    - If the IR has an entry function equivalent to main, include a full executable function named main.
    - If uncertain, prefer conservative, compilable code that matches observable behavior.
    - Do not claim equivalence or report tests that were not actually performed.
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
    max_ir_chars: Optional[int],
    source_label: str = "brightened LLVM IR",
    evidence_attached: bool = False,
) -> str:
    evidence = (
        "/* COMPLETE GHIDRA PSEUDOCODE AND BRIGHTENED LLVM IR ATTACHED IN THIS REQUEST */"
        if evidence_attached
        else _clip_ir(ir_text, max_ir_chars)
    )
    return f"""Repair the C recovery candidate below using the validation feedback.

<VALIDATION_FEEDBACK>
{feedback}
</VALIDATION_FEEDBACK>

<CANDIDATE_SOURCE>
```c
{candidate}
```
</CANDIDATE_SOURCE>

Model input artifact ({source_label}; not original source):
<MODEL_INPUT_ARTIFACT>
{evidence}
</MODEL_INPUT_ARTIFACT>

    Change only what is needed to restore behavior. Return the complete corrected
    source as exactly one JSON object:
    {{"source":"<complete C source>"}}.
    If compilation/fuzz failed previously, fix the exact error and return a full
    program (never partial). Remove any unfinished/placeholder tail from the
    candidate and produce a valid translation unit.
    The previous candidate is invalid unless it contains a complete `int main(...)`
    definition. If the candidate is truncated, rewrite the entire source from the
    original input; do not return only declarations or a patch/diff.
    Do not omit behavior-relevant functions, globals, wrappers, or thunks. You may omit
    only code that is provably unrelated to observable behavior. Do not add explanations
    or long comments to the source, but return the complete translation unit.
    Re-run the internal reconstruction checklist before repairing: program map, exact I/O
    contract, data-flow/control-flow semantics, obfuscation cleanup, high-level algorithm,
    and observable error behavior. Repair the behavior, not just the compiler diagnostic.
    Reason silently; do not output chain-of-thought or describe the repair.
    Return strict JSON only, no markdown or prose.
"""

def _extract_json_payload(response_text: str) -> Optional[str]:
    """Try to extract the first complete JSON object from model output."""
    text = _text(response_text)
    if not text:
        return None

    fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.IGNORECASE | re.DOTALL)
    if fenced:
        return fenced.group(1).strip()

    depth = 0
    start = None
    in_string = False
    escape = False

    for idx, ch in enumerate(text):
        if in_string:
            if escape:
                escape = False
                continue
            if ch == "\\":
                escape = True
            elif ch == "\"":
                in_string = False
            continue

        if ch == "\"":
            in_string = True
            continue
        if ch == "{":
            if depth == 0:
                start = idx
            depth += 1
        elif ch == "}":
            if depth > 0:
                depth -= 1
                if depth == 0 and start is not None:
                    return text[start : idx + 1].strip()
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
    except (json.JSONDecodeError, TypeError):
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
        if not start:
            raise RecoveryError("LLM response did not contain a valid BEGIN_C_SOURCE block.")
        source = start.group(1).strip()

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
    if not start:
        return None
    return start.group(1).strip()


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
        "dummy_",
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


def _vertex_generation_config(config: RecoveryConfig) -> Dict[str, Any]:
    generation_config: Dict[str, Any] = {
        "temperature": config.temperature,
        "topP": config.top_p,
        "candidateCount": config.candidate_count,
    }
    if config.max_output_tokens:
        generation_config["maxOutputTokens"] = config.max_output_tokens
    thinking_level = _text(config.thinking_level).upper()
    if thinking_level:
        allowed = {"MINIMAL", "LOW", "MEDIUM", "HIGH"}
        if thinking_level not in allowed:
            raise RecoveryError(
                f"Invalid LLM_RECOVERY_THINKING_LEVEL={config.thinking_level!r}; "
                f"expected one of {sorted(allowed)}."
            )
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
        kwargs: Dict[str, Any] = {"vertexai": True, "location": self.config.location}
        if self.config.project:
            kwargs["project"] = self.config.project
        try:
            self._client = genai.Client(**kwargs)
        except Exception as exc:
            raise RecoveryError(f"Could not initialize Vertex Gemini client: {exc}") from exc
        return self._client

    def _generate_rest(
        self,
        prompt: str,
        attachment_path: Optional[str] = None,
        attachment_paths: Optional[Sequence[str]] = None,
        system_instruction: Optional[str] = None,
    ) -> str:
        """Call Vertex AI generateContent through REST with ADC credentials."""
        credentials = _load_adc_credentials()
        access_token = _request_access_token_via_refresh(credentials)

        project = self.config.project or _text(credentials.get("quota_project_id"))
        if not project:
            raise RecoveryError(
                "Could not determine Vertex AI project. Set VERTEX_PROJECT or GOOGLE_CLOUD_PROJECT."
            )

        try:
            import requests
        except ImportError as exc:
            raise RecoveryError("Python package 'requests' is required.") from exc

        url = (
            f"{_vertex_api_base_url(self.config.location)}/"
            f"v1/projects/{project}/locations/{self.config.location}/"
            f"publishers/google/models/{self.config.model}:generateContent"
        )
        paths: List[str] = []
        if attachment_path:
            paths.append(_text(attachment_path))
        if attachment_paths:
            paths.extend(_text(path) for path in attachment_paths)
        paths = list(dict.fromkeys(path for path in paths if path))

        file_parts: List[Dict[str, Any]] = []
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
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        quota_project = self.config.project or _text(credentials.get("quota_project_id"))
        if quota_project:
            headers["x-goog-user-project"] = quota_project

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
            raise RecoveryError(f"Vertex REST failed: HTTP {response.status_code}: {detail}")

        data = response.json()
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
            if isinstance(exc, LLMRateLimitError):
                raise
            if _is_rate_limit_detail(exc):
                raise LLMRateLimitError(
                    f"Vertex Gemini rate limited: {exc}",
                    retry_after_seconds=_retry_after_seconds(None, str(exc)),
                    status_code=429,
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
    command = [compiler, "-std=c11", "-O0", "-w", source_path, "-lm", "-o", output_bin]
    process = subprocess.run(command, capture_output=True, text=True)
    if process.returncode == 0:
        return True, None
    return False, (process.stderr or process.stdout or "compiler returned a non-zero exit code").strip()


def _format_fuzz_feedback(report: Mapping[str, Any]) -> str:
    lines = [
        "Differential fuzzing did not confirm equivalence.",
        f"matches={report.get('matches', 0)}, mismatches={report.get('mismatches', 0)}, "
        f"inconclusive={report.get('inconclusive', 0)}, "
        f"equivalence_ratio={report.get('equivalence_ratio', 0.0):.2f}%",
    ]
    examples = report.get("mismatch_examples") or []
    for sample in examples[:5]:
        left = sample.get("prog1", {})
        right = sample.get("prog2", {})
        lines.append(
            "Mismatch #{index}: input={stdin!r}; recovered(status={ls}, rc={lr}, stdout={lo!r}, stderr={le!r}); "
            "reference(status={rs}, rc={rr}, stdout={ro!r}, stderr={re!r})".format(
                index=sample.get("index", "?"),
                stdin=sample.get("stdin", ""),
                ls=left.get("status"), lr=left.get("returncode"), lo=left.get("stdout", "")[:1200], le=left.get("stderr", "")[:1200],
                rs=right.get("status"), rr=right.get("returncode"), ro=right.get("stdout", "")[:1200], re=right.get("stderr", "")[:1200],
            )
        )
    return "\n".join(lines)


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
    print(
        f"[LLM] Bắt đầu recovery loop | max_iter={config.max_iterations} | "
        f"fuzz_iter={config.fuzz_iterations}, timeout={config.fuzz_timeout}s | prompt=unlimited"
    )

    backend = _text(config.pseudo_backend).strip().lower()
    if not backend:
        backend = "1" if config.two_stage_recovery else "2"
    if backend in {"1", "ghidra", "ghidra-only", "analyzeheadless"}:
        backend_mode = "ghidra"
    elif backend in {"2", "ir", "llvm", "raw_ir", "raw"}:
        backend_mode = "ir"
    elif backend == "auto":
        backend_mode = "ghidra"
    else:
        raise RecoveryError(
            f"pseudo_backend không hợp lệ: {backend}. Chỉ cho phép: 1/ghidra (Ghidra pseudo) hoặc 2/ir (IR raw)."
        )

    use_two_stage = backend_mode == "ghidra"
    if use_two_stage:
        print("[LLM] Mode 1: decompile bằng Ghidra rồi gửi C-like pseudocode cho LLM.")
        pseudo_path = os.path.join(output_dir, "ghidra_recovery_input.c")
        binary_path = ""
        if isinstance(metadata, Mapping):
            binary_path = _text(
                metadata.get("recovery_reference_binary")
            )
        ghidra_binary = _find_ghidra_analyze_headless(config.ghidra_binary_path)
        print(f"[LLM] Mục tiêu decompile: {binary_path or '<missing>'}")
        print(f"[LLM] Ghidra analyzeHeadless: {ghidra_binary or '<missing>'}")
        ghidra_failed: Optional[str] = None
        if not binary_path:
            ghidra_failed = "Mode 1 yêu cầu recovery_reference_binary nhưng không có metadata."
        elif not ghidra_binary:
            ghidra_failed = "Không tìm thấy Ghidra analyzeHeadless."
        elif not os.path.isfile(binary_path):
            ghidra_failed = f"Không tìm thấy binary cho Ghidra: {binary_path}"
        else:
            try:
                pseudo_source = _decompile_binary_with_ghidra(
                    binary_path,
                    os.path.join(output_dir, "ghidra_pseudocode.c"),
                    ghidra_binary=ghidra_binary,
                    timeout=config.ghidra_timeout,
                )
                if not pseudo_source or not pseudo_source.strip():
                    ghidra_failed = "Ghidra không trả về pseudocode."
            except Exception as exc:
                ghidra_failed = f"Ghidra decompile lỗi: {exc}"

        if ghidra_failed:
            Path(os.path.join(output_dir, "recovery_iter0.parse.txt")).write_text(
                ghidra_failed,
                encoding="utf-8",
            )
            print(f"[LLM] {ghidra_failed}. Dừng mode 1; không tự chuyển sang mode 2.")
            raise RecoveryError(ghidra_failed)
        else:
            Path(pseudo_path).write_text(pseudo_source, encoding="utf-8")
            pseudo_path_for_api = pseudo_path
            print(
                f"[LLM] Ghidra pseudocode đã lưu: {os.path.relpath(pseudo_path, output_dir)}"
            )
    else:
        print("[LLM] Mode 2: gửi trực tiếp LLVM IR cho LLM.")
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

    for iteration in range(start_iteration, config.max_iterations + 1):
        print(f"[LLM] --- Iteration {iteration}/{config.max_iterations} ---")
        def make_prompt(max_chars: Optional[int]) -> str:
            if iteration == 1:
                if use_two_stage and pseudo_source is None:
                    raise RecoveryError("Pseudo stage output missing while mode 1 is enabled.")
                use_pseudo = use_two_stage
                seed_text = pseudo_source if use_pseudo else ir_text
                seed_attached = (
                    use_pseudo
                    and pseudo_path_for_api is not None
                    and os.path.isfile(pseudo_path_for_api)
                )
                return build_initial_prompt(
                    seed_text,
                    metadata,
                    max_chars,
                    use_pseudo=use_pseudo,
                    seed_attached_file=seed_attached,
                )
            repair_input = pseudo_source if use_two_stage and pseudo_source is not None else ir_text
            return build_repair_prompt(
                repair_input,
                candidate,
                last_error or _format_fuzz_feedback(last_report or {}),
                max_chars,
                source_label=(
                    "Ghidra decompiler pseudocode"
                    if use_two_stage
                    else "brightened LLVM IR"
                ),
                evidence_attached=(
                    use_two_stage
                    and config.use_file_api
                    and pseudo_path_for_api is not None
                    and os.path.isfile(pseudo_path_for_api)
                ),
            )

        response: Optional[str] = None
        last_request_error: Optional[str] = None
        try:
            print(
                f"[LLM] Requesting model={config.model} | "
                f"request_timeout={config.request_timeout}s | "
                f"max_output_tokens={config.max_output_tokens} | "
                f"thinking_level={config.thinking_level or 'default'}"
            )
            attachment_paths: List[str] = []
            if use_two_stage and config.use_file_api:
                if not pseudo_path_for_api or not os.path.isfile(pseudo_path_for_api):
                    raise RecoveryError("File-API recovery enabled but Ghidra artifact is unavailable.")
                # The reference ELF has already served as Ghidra input. Gemini's
                # inlineData API does not accept raw executable/octet-stream MIME,
                # so attach its readable pseudocode plus the brightened textual IR.
                attachment_paths = [pseudo_path_for_api]
                brightened_ir_path = _text(metadata.get("input_ir"))
                if brightened_ir_path:
                    if not os.path.isfile(brightened_ir_path):
                        raise RecoveryError(
                            f"File-API recovery enabled but brightened LLVM IR is unavailable: "
                            f"{brightened_ir_path}"
                        )
                    attachment_paths.append(brightened_ir_path)
                print(
                    "[LLM] Readable evidence attachments: "
                    + ", ".join(os.path.basename(path) for path in attachment_paths)
                )

            model_prompt = build_system_prompt() + "\n\n" + make_prompt(None)
            request_hasher = hashlib.sha256()
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
                )

            request_context = {
                "iteration": iteration,
                "request_sha256": request_sha256,
                "max_iterations": config.max_iterations,
            }
            response = (
                request_executor(send_request, request_context)
                if request_executor is not None
                else send_request()
            )
            response_meta = dict(getattr(client, "last_response_meta", {}) or {})
            finish_reason = _text(response_meta.get("finish_reason"))
            usage = response_meta.get("usage_metadata") or {}
            print(
                f"[LLM] Đã nhận phản hồi từ model (iter={iteration}) | "
                f"finishReason={finish_reason or 'UNSPECIFIED'} | "
                f"promptTokens={usage.get('prompt_token_count', usage.get('promptTokenCount', '?'))} | "
                f"outputTokens={usage.get('candidates_token_count', usage.get('candidatesTokenCount', '?'))}"
            )
        except RecoveryError as exc:
            last_request_error = str(exc)
            print(f"[LLM] Model request lỗi: {last_request_error}")
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
            last_error = "Compilation failed:\n" + (compile_error or "unknown compiler error")
            Path(os.path.join(output_dir, f"recovery_iter{iteration}.compile.txt")).write_text(last_error, encoding="utf-8")
            print(f"[LLM] Iteration {iteration}: compile fail: {(compile_error or '').strip()[:800]}")
            continue

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
        if last_report.get("is_fully_equivalent", False):
            print(f"[LLM] Iteration {iteration}: semantic pass, accept candidate.")
            shutil.copy2(candidate_path, output_recovered_c_path)
            save_recovery_state(iteration=iteration, status="COMPLETED")
            return RecoveryResult(True, output_recovered_c_path, iteration, fuzz_report=last_report)
        last_error = _format_fuzz_feedback(last_report)
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
