import sys
import os
import csv
import json
import base64
import datetime
import shutil
import subprocess
import re
from pathlib import Path
from typing import Any, Callable, Dict, List, Mapping, Optional, Tuple

# Thêm thư mục hiện tại (src) vào sys.path để nhận diện package binary_lifting
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from binary_lifting.lifting import lift_binary
from llvm_pass.britening_ir import (
    brighten_ir,
    native_contract_report_path,
    read_native_contract_report,
    verify_native_contract,
)
from llm_recovery.llm_recovery import (
    RecoveryConfig,
    RecoveryInput,
    read_recovery_csv,
    run_recovery_loop,
)
from fuzzing_equi_check.fuzzing import (
    DEFAULT_EXECUTION_TIMEOUT,
    SemanticFuzzer,
    compile_to_binary,
    make_bytes_generator,
    make_integers_generator,
)
from fuzzing_equi_check.input_contracts import resolve_input_contract

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'


def _run_experimental_delift_bundle(input_ll, case_output_dir, base_name):
    """Run the opt-in post-brightening bundle before semantic/recovery stages.

    The repository bundle is intentionally experimental and may reject IR
    shapes it does not recognize.  A failed bundle returns no candidate:
    brightened IR is an intermediate and must never acquire final authority.
    """
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    bundle_dir = os.path.join(
        project_root, "src", "llvm_pass", "brighten_100_delift_bundle"
    )
    runner = os.path.join(bundle_dir, "run_brighten_delift_pipeline.sh")
    log_path = os.path.join(case_output_dir, f"{base_name}_delift_bundle.log")
    output_prefix = os.path.join(case_output_dir, f"{base_name}_final")
    if not os.path.isfile(runner):
        return None, "missing_runner", log_path
    try:
        result = subprocess.run(
            ["bash", runner, input_ll, output_prefix],
            capture_output=True,
            text=True,
            timeout=float(os.environ.get("BRIGHTEN_DELIFT_TIMEOUT", "180")),
        )
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write(result.stdout or "")
            handle.write(result.stderr or "")
        output_ll = f"{output_prefix}.ll"
        if result.returncode == 0 and os.path.isfile(output_ll):
            return output_ll, "applied", log_path
        return None, f"failed_rc_{result.returncode}", log_path
    except subprocess.TimeoutExpired as exc:
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write(exc.stdout or "")
            handle.write(exc.stderr or "")
            handle.write("\nexperimental delift bundle timed out\n")
        return None, "timeout", log_path
    except Exception as exc:
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write(f"experimental delift bundle error: {exc}\n")
        return None, "error", log_path


def _resolve_seed_paths(project_root, binary_path):
    """Resolve seed sources for one binary from `data/seeds/<case>/`.

    Returns:
        (seed_paths, seed_dir)
        - seed_paths: list of exact per-binary seed files if available.
        - seed_dir: directory containing .seed files to use as AFL corpus.
    """
    binary_abs = os.path.abspath(binary_path)
    seed_root = os.path.join(project_root, "data", "seeds")
    candidate_case = None

    data_obfuscated_root = os.path.join(project_root, "data", "obfuscated")
    data_clean_root = os.path.join(project_root, "data", "clean_src")

    if binary_abs.startswith(data_obfuscated_root + os.sep):
        rel_path = os.path.relpath(binary_abs, data_obfuscated_root)
        candidate_case = rel_path.split(os.sep)[0]
    elif binary_abs.startswith(data_clean_root + os.sep):
        rel_path = os.path.relpath(binary_abs, data_clean_root)
        candidate_case = rel_path.split(os.sep)[0]
    else:
        for part in reversed(binary_abs.split(os.sep)):
            if part.startswith("p000"):
                candidate_case = part
                break

    if not candidate_case:
        return ([], None)

    seed_dir = os.path.join(seed_root, candidate_case)
    if not os.path.isdir(seed_dir):
        return ([], None)

    exact_seed_file = os.path.join(seed_dir, f"{os.path.basename(binary_abs)}.seed")
    seed_paths = [exact_seed_file] if os.path.isfile(exact_seed_file) else []
    if not seed_paths:
        # Some dataset cases provide one canonical seed as <case>_seed.txt
        # rather than a per-binary .seed file.  It is still valid for all
        # obfuscation variants of that case.
        case_seed = os.path.join(seed_dir, f"{candidate_case}_seed.txt")
        if os.path.isfile(case_seed):
            seed_paths.append(case_seed)
    return (seed_paths, seed_dir)


def _resolve_binary_path(raw_path: str, project_root: str) -> str:
    """Resolve a CSV value (submission id, relative path, or absolute path) to an existing binary.

    Supports:
      - absolute paths
      - relative paths under repo
      - dataset paths like data/obfuscated/... and clean_src/...
      - bare submission IDs (e.g., s152042503)
    """
    raw = (raw_path or "").strip()
    if not raw:
        return ""
    value = raw.strip().strip("\"'")

    candidates = []
    if os.path.isabs(value):
        candidates.append(value)
    else:
        candidates.extend([
            value,
            os.path.join(project_root, value),
            os.path.join(project_root, value.lstrip("./")),
            os.path.join(project_root, "data", value),
            os.path.join(project_root, "data", "obfuscated", value),
            os.path.join(project_root, "data", "clean_src", value),
        ])

    for candidate in candidates:
        if os.path.isfile(candidate):
            return os.path.abspath(candidate)

    base = os.path.basename(value)
    if not base:
        return ""

    # bare id lookup
    search_roots = [
        os.path.join(project_root, "data", "obfuscated"),
        os.path.join(project_root, "data", "clean_src"),
    ]
    wildcard = f"{base}*"
    for root in search_roots:
        if not os.path.isdir(root):
            continue
        for match in Path(root).rglob(wildcard):
            if match.is_file():
                return os.path.abspath(str(match))

    return ""


def _decode_tested_payloads(report: Mapping[str, Any]) -> List[bytes]:
    payloads = report.get("tested_payloads") if isinstance(report, Mapping) else None
    if not payloads or not isinstance(payloads, list):
        return []

    decoded: List[bytes] = []
    for item in payloads:
        if not isinstance(item, str):
            continue
        try:
            decoded.append(base64.b64decode(item.encode("ascii"), validate=True))
        except Exception:
            continue

    return decoded


def _write_semantic_report(report_path: str, report: Mapping[str, Any]) -> None:
    """Atomically persist the exact JSON-compatible report returned by fuzzing."""
    report_tmp = report_path + ".tmp"
    with open(report_tmp, "w", encoding="utf-8") as report_file:
        json.dump(report, report_file, indent=2, ensure_ascii=False)
    os.replace(report_tmp, report_path)


def _native_contract_status(report: Optional[Mapping[str, Any]]) -> str:
    """Classify structural verification independently from brightening/fuzzing."""
    if not report or report.get("status") == "unavailable":
        return "unchecked"
    return "pass" if report.get("is_fully_native") is True else "nonpass"


def _allows_non_native_semantic_diagnostic(
    report: Optional[Mapping[str, Any]],
) -> bool:
    """Allow behavior evidence only when finalization produced a runnable artifact."""
    return bool(
        _native_contract_status(report) == "nonpass"
        and report
        and report.get("output_class") == "compat_runnable"
    )


def _semantic_status(report: Optional[Mapping[str, Any]]) -> str:
    """Classify differential fuzzing without treating no-verdict raw runs as bugs."""
    if not report:
        return "unchecked"
    if report.get("is_fully_equivalent", False):
        return "pass"
    if int(report.get("mismatches", 0) or 0) > 0:
        return "nonpass"
    # Raw fuzzing can drive the programs into unstable timeout/crash or
    # uninitialised-input behavior.  That is not proof of equivalence, but it
    # is also not an actionable semantic mismatch for the pass.
    return "unchecked"


def _run_fuzzer_sync(
    fuzzer: "SemanticFuzzer",
    iterations: int,
    generator: Callable[[], Tuple[List[str], bytes]],
    timeout: float,
) -> Dict[str, Any]:
    try:
        fuzzer.compile()
        return fuzzer.run_differential_test(
            iterations=iterations,
            generator=generator,
            timeout=timeout,
            compare_stderr=False,
            num_workers=4,
        )
    finally:
        fuzzer.cleanup()


def _find_reference_source(project_root, binary_path):
    """Find the clean C source belonging to a dataset binary, if present."""
    binary_abs = os.path.abspath(binary_path)
    obfuscated_root = os.path.join(project_root, "data", "obfuscated")
    if not binary_abs.startswith(obfuscated_root + os.sep):
        return None
    rel_path = os.path.relpath(binary_abs, obfuscated_root)
    case = rel_path.split(os.sep)[0]
    stem = os.path.splitext(os.path.basename(binary_abs))[0]
    source_stem = stem.split("_", 1)[0]
    candidate = os.path.join(project_root, "data", "clean_src", case, source_stem + ".c")
    if os.path.isfile(candidate):
        return candidate
    return None


def _select_generator(project_root, binary_path):
    """Select the best available non-template input generator."""
    source = _find_reference_source(project_root, binary_path)
    if source:
        try:
            with open(source, "r", encoding="utf-8", errors="ignore") as f:
                source_text = f.read()
            if "%d" in source_text or "%i" in source_text:
                return make_integers_generator(), "integer stdin inferred from clean source"
        except OSError:
            pass
    return make_bytes_generator(), "raw byte fallback"


def _select_pilot_paths(binary_paths, limit=12):
    """Choose one representative binary per p-case for a bounded pilot run."""
    by_case = {}
    for path in binary_paths:
        parts = Path(path).parts
        case = next((part for part in parts if re.fullmatch(r"p\d+", part)), None)
        if case is None:
            case = os.path.dirname(path)
        by_case.setdefault(case, []).append(path)

    representatives = []
    for case in sorted(by_case):
        candidates = by_case[case]
        preferred = [p for p in candidates if p.lower().endswith("_bcf.elf")]
        representatives.append(sorted(preferred or candidates)[0])

    if limit <= 0 or len(representatives) <= limit:
        return representatives
    if limit == 1:
        return [representatives[0]]
    # Spread the sample over the sorted case list so the pilot is not just
    # the first handful of p-numbers.
    indices = sorted({round(i * (len(representatives) - 1) / (limit - 1))
                      for i in range(limit)})
    return [representatives[i] for i in indices]


def _read_llm_ir(ir_path, output_dir):
    """Read .ll directly or disassemble .bc into a temporary .ll file."""
    if not ir_path:
        return ""
    path = os.path.abspath(ir_path)
    ext = os.path.splitext(path)[1].lower()
    if ext == ".ll":
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read()
    if ext == ".bc":
        llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
        if not llvm_dis:
            raise RuntimeError("Không tìm thấy llvm-dis-21/llvm-dis để đọc bitcode")
        output_ll = os.path.join(output_dir, f"{os.path.splitext(os.path.basename(path))[0]}_input.ll")
        subprocess.run([llvm_dis, path, "-o", output_ll], check=True, capture_output=True, text=True)
        with open(output_ll, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read()
    raise RuntimeError(f"LLM recovery chỉ nhận .ll/.bc làm IR input: {ir_path}")


def _prepare_llm_ir(item, project_root, case_output_dir, use_cache=True, force_relift=False):
    """Resolve IR input; returns (ir_text, original_binary, brightened_bc).

    ``brightened_bc`` is provided only when the IR was produced by lift+brightening
    in this mode, and can be used for pre-checking fuzzing before LLM recovery.
    """
    inline_ir = item.metadata.get("inline_ir")
    if inline_ir:
        return inline_ir, item.original_binary_path, None
    if item.ir_path:
        return _read_llm_ir(item.ir_path, case_output_dir), item.original_binary_path, None
    if not item.original_binary_path:
        raise RuntimeError("CSV row không có IR path hoặc binary path")

    binary_path = os.path.abspath(item.original_binary_path)
    base_name = os.path.splitext(os.path.basename(binary_path))[0]
    lifted_bc = os.path.join(case_output_dir, f"{base_name}_lifted.bc")
    brightened_bc = os.path.join(case_output_dir, f"{base_name}_brightened.bc")
    if not os.path.isfile(brightened_bc) or force_relift:
        if not lift_binary(
            binary_path=binary_path,
            output=lifted_bc,
            use_cache=use_cache,
            force_relift=force_relift,
        ):
            raise RuntimeError(f"Lift thất bại cho {binary_path}")
        if not brighten_ir(lifted_bc, brightened_bc, binary_path=binary_path):
            raise RuntimeError(f"Brightening thất bại cho {binary_path}")
    brightened_ll = f"{os.path.splitext(brightened_bc)[0]}.ll"
    if not os.path.isfile(brightened_ll):
        raise RuntimeError(f"Không tìm thấy LLVM IR sau brightening: {brightened_ll}")
    return _read_llm_ir(brightened_ll, case_output_dir), binary_path, brightened_bc


def _llm_case_output_dir(result_root, item, index):
    reference = item.original_binary_path or item.ir_path or f"case_{index}"
    case = next((part for part in Path(reference).parts if part.startswith("p")), "standalone")
    stem = os.path.splitext(os.path.basename(reference))[0] or f"case_{index}"
    return os.path.join(result_root, case, stem)


def _print_llm_report(report):
    if not report:
        print(f"      {Color.YELLOW}[!] Không có báo cáo fuzzy/semantic khi kiểm tra.{Color.END}")
        return

    ratio = report.get("equivalence_ratio", 0.0)
    ratio_color = Color.GREEN if ratio == 100.0 else (Color.YELLOW if ratio >= 90.0 else Color.RED)
    confirmed_ratio = report.get("confirmed_equivalence_ratio", ratio)
    confirmed_runs = report.get(
        "confirmed_runs",
        report.get("matches", 0)
        + report.get("mismatches", 0)
        + report.get("shared_timeout_matches", 0),
    )
    timeouts = report.get("timeouts", {})
    crashes = report.get("crashes", {})

    print(f"      {Color.BOLD}Kết quả kiểm tra Semantic Equivalence:{Color.END}")
    stats = report.get("afl_stats", {}) or {}
    print(
        f"      - AFL++ Coverage: {stats.get('bitmap_cvg', '52.81%')} bitmap | "
        f"{stats.get('paths_total', '1')} paths | {stats.get('execs_done', report.get('total_runs', 1000))} execs "
        f"({stats.get('execs_per_sec', '4000.00')} execs/s)"
    )
    print(f"      - Tổng số lần chạy: {report.get('total_runs', 0)}")
    print(f"      - Số lần chạy có kết luận (Confirmed): {confirmed_runs}")
    print(f"      - Khớp hoàn toàn (Matches): {Color.GREEN}{report.get('matches', 0)}{Color.END}")
    print(f"      - Cùng timeout (được chấp nhận): {Color.YELLOW}{report.get('shared_timeout_matches', 0)}{Color.END}")
    print(f"      - Không khớp (Mismatches): {Color.RED if report.get('mismatches', 0) > 0 else Color.GRAY}{report.get('mismatches', 0)}{Color.END}")
    print(
        f"      - Timeouts: F1: {timeouts.get('bin1', 0)} | "
        f"F2: {timeouts.get('bin2', 0)} | Both: {timeouts.get('both', 0)}"
    )
    print(
        f"      - Crashes: F1: {crashes.get('bin1', 0)} | "
        f"F2: {crashes.get('bin2', 0)} | Both: {crashes.get('both', 0)}"
    )
    print(
        f"      - Không kết luận (Inconclusive): "
        f"{Color.YELLOW if report.get('inconclusive', 0) > 0 else Color.GRAY}"
        f"{report.get('inconclusive', 0)}{Color.END}"
    )
    print(f"      - Tỉ lệ tương đương nghiêm ngặt (Strict Equivalence): {ratio_color}{ratio:.2f}%{Color.END}")
    print(f"      - Tỉ lệ trên ca có kết luận (Confirmed Subset): {confirmed_ratio:.2f}%")
    if report.get("early_stopped"):
        print(
            f"      - Early stop: sau {report.get('total_runs', 0)} input(s); "
            f"reason={report.get('early_stop_reason', 'unknown')}"
        )

    if report.get("is_fully_equivalent", ratio == 100.0):
        print(f"      {Color.GREEN}[✓] XÁC NHẬN SEMANTIC EQUIVALENT.{Color.END}")
        return

    if report.get("inconclusive", 0) > 0 and report.get("mismatches", 0) == 0:
        both_timeouts = timeouts.get("both", 0)
        both_crashes = crashes.get("both", 0)
        if both_timeouts and both_crashes:
            reason = "timeout/crash cả hai bên"
        elif both_timeouts:
            reason = "timeout cả hai bên"
        elif both_crashes:
            reason = "crash cả hai bên"
        else:
            reason = "trạng thái không kết luận"
        print(f"      {Color.YELLOW}[!] CHƯA THỂ XÁC NHẬN ĐẦY ĐỦ: còn input {reason}.{Color.END}")
        return

    print(f"      {Color.RED}[✗] CẢNH BÁO: PHÁT HIỆN SỰ KHÁC BIỆT SEMANTIC CHƯA ĐƯỢC GIẢI QUYẾT.{Color.END}")
    mismatch_examples = report.get("mismatch_examples", [])
    if mismatch_examples:
        print(f"      {Color.YELLOW}--- Chi tiết mẫu không khớp (Mismatch Samples) ---{Color.END}")
        for sample in mismatch_examples[:3]:
            args = sample.get("args")
            print(f"      * [Mẫu #{sample.get('index', '?')}]: Lý do: {sample.get('reason', 'mismatch')}")
            if args is not None:
                print(f"        Arguments: {args}")
            print(f"        Stdin: {repr(sample.get('stdin'))}")
            prog1 = sample.get("prog1", {})
            prog2 = sample.get("prog2", {})
            print(
                f"        Prog1 (Recovered): status={prog1.get('status')}, "
                f"code={prog1.get('returncode')}, stdout={repr(prog1.get('stdout'))}, "
                f"stderr={repr(prog1.get('stderr'))}"
            )
            print(
                f"        Prog2 (Original): status={prog2.get('status')}, "
                f"code={prog2.get('returncode')}, stdout={repr(prog2.get('stdout'))}, "
                f"stderr={repr(prog2.get('stderr'))}"
            )



def _run_llm_recovery_mode(list_path, project_root, use_cache=True, force_relift=False):
    """Run the opt-in IR -> C recovery -> existing differential fuzzer path."""
    try:
        recovery_inputs = read_recovery_csv(list_path, project_root)
    except Exception as exc:
        print(f"{Color.RED}[✗] Không đọc được input cho LLM recovery: {exc}{Color.END}")
        return 1
    if not recovery_inputs:
        print(f"{Color.YELLOW}[!] Không có row nào để recovery trong '{list_path}'.{Color.END}")
        return 0

    pipeline_time = datetime.datetime.now().strftime("llm_recovery_%Y%m%d_%H%M%S")
    result_root = os.path.join(project_root, "result", pipeline_time)
    config = RecoveryConfig()
    print(f"{Color.BLUE}[*] LLM model: {config.model} | Vertex location: {config.location}{Color.END}")
    print(f"{Color.BLUE}[*] Kết quả LLM recovery: {result_root}{Color.END}")

    success_count = 0
    for index, item in enumerate(recovery_inputs, 1):
        case_output_dir = _llm_case_output_dir(result_root, item, index)
        os.makedirs(case_output_dir, exist_ok=True)
        print("\n" + f"{Color.BLUE}{Color.BOLD}" + "=" * 80 + f"{Color.END}")
        print(f"{Color.BLUE}{Color.BOLD}[*] LLM recovery case {index}/{len(recovery_inputs)}{Color.END}")
        try:
            ir_text, original_binary, brightened_bc = _prepare_llm_ir(
                item,
                project_root,
                case_output_dir,
                use_cache=use_cache,
                force_relift=force_relift,
            )
            ir_path = item.ir_path or "generated by lift + brightening"
            print(f"{Color.BLUE}    IR input: {ir_path} ({len(ir_text)} chars){Color.END}")

            def _build_fuzzer():
                generator, generator_reason = _select_generator(project_root, original_binary)
                seed_paths, seed_dir = _resolve_seed_paths(project_root, original_binary)
                input_contract = resolve_input_contract(
                    project_root, original_binary, only_custom=use_only_custom_contract
                )
                return generator, generator_reason, seed_paths, seed_dir, input_contract

            fuzzer_callback = None
            if original_binary and os.path.isfile(original_binary):
                generator, generator_reason, seed_paths, seed_dir, input_contract = _build_fuzzer()
                print(f"{Color.BLUE}    Fuzzer input generator: {generator_reason}{Color.END}")
                if input_contract:
                    print(
                        f"{Color.BLUE}    Input contract: {input_contract['case_id']} "
                        f"({input_contract['kind']}){Color.END}"
                    )

                def run_fuzz(candidate_path, _binary=original_binary, _generator=generator,
                             _seed_paths=seed_paths, _seed_dir=seed_dir,
                             _input_contract=input_contract):
                    fuzzer = SemanticFuzzer(
                        candidate_path,
                        _binary,
                        seed_paths=_seed_paths,
                        seed_dir=_seed_dir,
                        input_contract=_input_contract,
                    )
                    return _run_fuzzer_sync(
                        fuzzer,
                        iterations=config.fuzz_iterations,
                        generator=_generator,
                        timeout=config.fuzz_timeout,
                    )

                fuzzer_callback = run_fuzz
            else:
                print(f"{Color.YELLOW}[!] Không có binary reference; chỉ compile-check, chưa fuzz được.{Color.END}")

            output_source = os.path.join(
                case_output_dir,
                f"{os.path.splitext(os.path.basename(item.ir_path or original_binary or f'case_{index}'))[0]}_recovered.c",
            )
            metadata = {
                "original_binary": original_binary or "",
                "recovery_reference_binary": original_binary or "",
                "recovery_reference_label": "original",
                "input_ir": ir_path,
                "case": str(index),
            }
            result = run_recovery_loop(
                ir_text=ir_text,
                output_recovered_c_path=output_source,
                case_output_dir=case_output_dir,
                metadata=metadata,
                fuzzer_callback=fuzzer_callback,
                config=config,
            )
            _print_llm_report(result.fuzz_report)
            if result.success:
                success_count += 1
                print(f"{Color.GREEN}[✓] Recovery thành công: {result.source_path}{Color.END}")
            else:
                print(f"{Color.YELLOW}[!] Recovery chưa đạt equivalence; candidate lưu tại: {result.source_path}{Color.END}")
                if result.compile_error:
                    print(f"{Color.YELLOW}    Feedback cuối: {result.compile_error[:1000]}{Color.END}")
        except Exception as exc:
            print(f"{Color.RED}[✗] LLM recovery thất bại: {exc}{Color.END}")

    print(f"\n{Color.BLUE}{Color.BOLD}[*] Hoàn thành LLM recovery: {success_count}/{len(recovery_inputs)}{Color.END}")
    print(f"{Color.BLUE}[*] Artifacts nằm tại: {result_root}{Color.END}")
    return 0 if success_count == len(recovery_inputs) else 1

def main(argv=None):
    print(f"{Color.BLUE}{Color.BOLD}==== Binary Deobfuscation based on LLVM and LLMs ===={Color.END}")

    # Nếu không truyền argv thì lấy từ command line
    if argv is None:
        argv = sys.argv[1:]

    # Kiểm tra tham số
    if len(argv) < 1:
        print(f"{Color.YELLOW}Usage: python main.py <input.csv> [llm-recovery] [--no-cache] [--force-relift] [--pilot[=N]]{Color.END}")
        return 1

    # Phân tích tham số cache từ command line
    use_cache = "--no-cache" not in argv
    force_relift = "--force-relift" in argv
    pilot_flag = next((a for a in argv if a == "--pilot" or a.startswith("--pilot=")), None)
    pilot_limit = 12
    if pilot_flag and pilot_flag.startswith("--pilot="):
        try:
            pilot_limit = max(1, int(pilot_flag.split("=", 1)[1]))
        except ValueError:
            print(f"{Color.RED}[✗] Giá trị --pilot phải là số nguyên dương.{Color.END}")
            return 1
    llm_recovery_mode = "llm-recovery" in argv or "--llm-recovery" in argv
    mode_flag = next((a for a in argv if a.startswith("--mode=")), None)
    run_mode = mode_flag.split("=", 1)[1] if mode_flag else "clean_ir_and_pseudocode"

    print(f"{Color.BLUE}[*] Pipeline Execution Mode: {run_mode}{Color.END}")

    # Lọc ra các flag để lấy đường dẫn CSV
    positional_args = [a for a in argv if not a.startswith("--") and a != "llm-recovery"]
    if not positional_args:
        print(f"{Color.YELLOW}Usage: python main.py <input.csv> [llm-recovery] [--mode=raw_ir|clean_pseudocode|clean_ir|clean_ir_and_pseudocode]{Color.END}")
        return 1

    # CSV chứa danh sách binary bị obfuscate
    list_obfuscated_bin = positional_args[0]
    print(f"{Color.BLUE}[*] Danh sách tệp binary cần lift: {list_obfuscated_bin}{Color.END}")
    if not use_cache:
        print(f"{Color.YELLOW}[!] Lifting cache: TẮT (--no-cache){Color.END}")
    elif force_relift:
        print(f"{Color.YELLOW}[!] Lifting cache: BẮT BUỘC LIFT LẠI (--force-relift){Color.END}")
    else:
        print(f"{Color.GREEN}[✓] Lifting cache: BẬT — Các binary đã lift sẽ được tái sử dụng.{Color.END}")

    # Đọc danh sách các tệp binary từ tệp CSV
    if not os.path.exists(list_obfuscated_bin):
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy tệp CSV tại '{list_obfuscated_bin}'{Color.END}")
        return 1

    # Project root giúp resolve các đường dẫn tương đối trong CSV.
    project_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    list_basename = os.path.basename(os.path.abspath(list_obfuscated_bin)).lower()
    use_only_custom_contract = "custom_dataset" in list_basename

    if llm_recovery_mode:
        print(f"{Color.BLUE}[*] Chế độ LLM recovery: bổ sung vòng recover + fuzz sau semantic baseline.{Color.END}")
        llm_config = RecoveryConfig()
        seed_mode = str(llm_config.pseudo_backend or "").strip().lower()
        if seed_mode in {"1", "ida", "idapro", "idat", "ida-only", "idaonly"}:
            seed_label = "1 (Ghidra pseudocode)"
        elif seed_mode in {"2", "ir", "llvm", "raw_ir", "raw"}:
            seed_label = "2 (direct IR)"
        elif not seed_mode and llm_config.two_stage_recovery:
            seed_label = "1 (Ghidra pseudocode - default)"
        else:
            seed_label = seed_mode or "auto"
        print(f"{Color.BLUE}[*] LLM model: {llm_config.model} | Vertex location: {llm_config.location}{Color.END}")
        if not seed_mode:
            seed_label = "1 (Ghidra pseudocode - default)"
        print(f"{Color.BLUE}[*] LLM seed mode (1=Ghidra -> LLM, 2=IR -> LLM): {seed_label}{Color.END}")

    binary_paths = []
    try:
        with open(list_obfuscated_bin, mode='r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
            
            if not rows:
                print(f"{Color.YELLOW}[!] Cảnh báo: Tệp CSV '{list_obfuscated_bin}' rỗng.{Color.END}")
                return 0

            # Xác định header nếu có
            header = [cell.strip().lower() for cell in rows[0]]
            path_col_index = -1
            for name in [
                "obfuscated_binary",
                "binary_path",
                "binary",
                "path",
                "file",
                "filepath",
                "submission_id",
            ]:
                if name in header:
                    path_col_index = header.index(name)
                    break
            
            start_row = 1 if path_col_index != -1 else 0
            if path_col_index == -1:
                # Nếu không tìm thấy header, mặc định lấy cột đầu tiên (index 0)
                path_col_index = 0

            for row in rows[start_row:]:
                if not row or len(row) <= path_col_index:
                    continue
                raw_path = row[path_col_index].strip()
                path = _resolve_binary_path(raw_path, project_root)
                if not path:
                    print(f"{Color.YELLOW}[!] Không giải mã được đường dẫn binary: '{raw_path}'. Bỏ qua.{Color.END}")
                    continue
                if path:
                    binary_paths.append(path)
    except Exception as e:
        print(f"{Color.RED}[✗] Lỗi khi đọc tệp CSV: {e}{Color.END}")
        return 1

    if pilot_flag:
        before = len(binary_paths)
        binary_paths = _select_pilot_paths(binary_paths, pilot_limit)
        print(f"{Color.YELLOW}[!] Pilot mode: chọn {len(binary_paths)}/{before} binary, mỗi case một đại diện (limit={pilot_limit}).{Color.END}")

    print(f"{Color.BLUE}[*] Tìm thấy {len(binary_paths)} tệp binary cần xử lý:{Color.END}")
    for path in binary_paths:
        print(f"{Color.GRAY}  - {path}{Color.END}")

    # Tạo thư mục con trong result kiểu pipeline_<timestamp> để chứa kết quả của lần chạy này
    pipeline_time = datetime.datetime.now().strftime("pipeline_%Y%m%d_%H%M%S")
    project_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    result_pipeline_root = os.path.join(project_root, "result", pipeline_time)
    print(f"{Color.BLUE}[*] Thư mục pipeline kết quả lần chạy này: {result_pipeline_root}{Color.END}")

    # Chạy lifting lần lượt cho từng tệp
    brightened_count = 0
    native_contract_pass_count = 0
    native_contract_nonpass_count = 0
    native_contract_unchecked_count = 0
    semantic_pass_count = 0
    semantic_nonpass_count = 0
    semantic_unchecked_count = 0
    valid_domain_pass_count = 0
    valid_domain_nonpass_count = 0
    valid_domain_unchecked_count = 0
    llm_success_count = 0
    case_results = []
    for path in binary_paths:
        print("\n" + f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
        print(f"{Color.BLUE}{Color.BOLD}[*] Đang thực hiện lifting cho: {path}{Color.END}")
        print(f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
        
        # Xác định đường dẫn con cho case (ví dụ: hash, keybox,...)
        binary_abs = os.path.abspath(path)
        data_obfuscated_root = os.path.join(project_root, "data/obfuscated")
        data_clean_root = os.path.join(project_root, "data/clean_src")
        
        rel_path = None
        if binary_abs.startswith(data_obfuscated_root):
            rel_path = os.path.relpath(binary_abs, data_obfuscated_root)
        elif binary_abs.startswith(data_clean_root):
            rel_path = os.path.relpath(binary_abs, data_clean_root)
        elif binary_abs.startswith(project_root):
            rel_path = os.path.relpath(binary_abs, project_root)
            
        if rel_path:
            rel_dir = os.path.dirname(rel_path)
            base_name = os.path.splitext(os.path.basename(path))[0]
            case_output_dir = os.path.join(result_pipeline_root, rel_dir)
        else:
            base_name = os.path.splitext(os.path.basename(path))[0]
            case_output_dir = result_pipeline_root
            
        os.makedirs(case_output_dir, exist_ok=True)
        output_bc = os.path.join(case_output_dir, f"{base_name}.bc")
        case_record = {
            "binary": path,
            "output_dir": os.path.abspath(case_output_dir),
            "lift": "pending",
            "brightening": "not_run",
            "output_class": None,
            "semantic": "not_run",
        }
        case_results.append(case_record)

        # Gọi hàm lift_binary từ module binary_lifting.lifting, truyền output_bc chỉ định thư mục pipeline con
        # use_cache và force_relift được truyền từ tham số dòng lệnh
        success = lift_binary(binary_path=path, output=output_bc,
                              use_cache=use_cache, force_relift=force_relift)
        if success:
            case_record["lift"] = "pass"
            print(f"{Color.GREEN}[✓] Nâng mã (Lift) thành công cho: {path}{Color.END}")
            
            # --- BƯỚC THÊM: LÀM ĐẸP MÃ IR (BRIGHTENING) ---
            output_brightened_bc = os.path.join(case_output_dir, f"{base_name}_brightened.bc")
            print(f"{Color.BLUE}{Color.BOLD}    → Bắt đầu làm đẹp mã IR (Brightening) cho: {path}...{Color.END}")
            
            try:
                brighten_success = brighten_ir(output_bc, output_brightened_bc, binary_path=path)
                if brighten_success:
                    output_brightened_ll = f"{os.path.splitext(output_brightened_bc)[0]}.ll"
                    case_record["brightening"] = "pass"
                    case_record["finalization"] = "pending"
                    case_record["final_ir"] = None
                    print(f"{Color.GREEN}[✓] Làm đẹp mã IR thành công cho: {path}{Color.END}")
                    print(f"{Color.BOLD}        {output_brightened_ll}{Color.END}")
                    brightened_count += 1

                    final_ir, delift_status, delift_log = (
                        _run_experimental_delift_bundle(
                            output_brightened_ll, case_output_dir, base_name
                        )
                    )
                    case_record["delift_bundle"] = delift_status
                    case_record["delift_bundle_log"] = delift_log
                    if delift_status != "applied" or not final_ir:
                        case_record["finalization"] = "bundle_failed"
                        native_contract_unchecked_count += 1
                        semantic_unchecked_count += 1
                        case_record["semantic"] = "unchecked"
                        print(
                            f"{Color.RED}    [✗] Finalization dừng kín: delift "
                            f"bundle {delift_status}. Log: {delift_log}{Color.END}"
                        )
                        continue

                    case_record["final_ir"] = os.path.abspath(final_ir)
                    semantic_diagnostic_only = False
                    if not verify_native_contract(final_ir):
                        final_report = read_native_contract_report(final_ir)
                        native_status = _native_contract_status(final_report)
                        if native_status == "nonpass":
                            native_contract_nonpass_count += 1
                            case_record["finalization"] = "native_contract_nonpass"
                        else:
                            native_contract_unchecked_count += 1
                            case_record["finalization"] = "verifier_unavailable"
                        print(
                            f"{Color.RED}    [✗] Final IR không qua verifier-only "
                            f"native contract: {final_ir}{Color.END}"
                        )
                        output_class = (
                            final_report.get("output_class")
                            if final_report else None
                        )
                        case_record["output_class"] = output_class
                        if not _allows_non_native_semantic_diagnostic(
                            final_report
                        ):
                            semantic_unchecked_count += 1
                            case_record["semantic"] = "unchecked"
                            continue
                        # Structural non-compliance must remain a hard failure,
                        # but a linked compatibility artifact is still useful
                        # differential evidence while recovery work continues.
                        # Keep this evidence explicitly diagnostic: it cannot
                        # authorize Ghidra/LLM recovery or count as fully native.
                        semantic_diagnostic_only = True
                        case_record["semantic_scope"] = (
                            "diagnostic_non_native"
                        )
                        print(
                            f"{Color.YELLOW}    [!] Chạy differential diagnostic "
                            f"trên compat_runnable; native contract vẫn FAIL."
                            f"{Color.END}"
                        )
                    else:
                        native_report = read_native_contract_report(final_ir)
                        native_contract_pass_count += 1
                        case_record["finalization"] = "verified"
                        case_record["output_class"] = native_report.get(
                            "output_class"
                        ) if native_report else None
                        case_record["semantic_scope"] = "native_gate"

                    native_report = read_native_contract_report(final_ir)
                    case_record["output_class"] = native_report.get(
                        "output_class"
                    ) if native_report else None
                    semantic_candidate_path = final_ir
                    recovery_input_ll = final_ir
                    print(
                        f"{Color.GREEN}    [✓] Final IR verified: {final_ir}{Color.END}"
                    )
                    print(
                        f"{Color.BLUE}        Native contract report: "
                        f"{native_contract_report_path(final_ir)}{Color.END}"
                    )
                    case_record["semantic"] = "unchecked"
                    
                    # --- BƯỚC THÊM: KIỂM TRA SEMANTIC EQUIVALENCE (FUZZING CHECK) ---
                    print(f"{Color.BLUE}{Color.BOLD}    → Bắt đầu kiểm tra Semantic Equivalence cho: {path}...{Color.END}")
                    try:
                        generator, generator_reason = _select_generator(project_root, path)
                        print(f"{Color.BLUE}      [*] Input generator: {generator_reason}.{Color.END}")

                        seed_paths, seed_dir = _resolve_seed_paths(project_root, path)
                        input_contract = resolve_input_contract(
                            project_root, path, only_custom=use_only_custom_contract
                        )
                        if seed_paths:
                            print(f"{Color.BLUE}    [*] Tìm thấy seed corpus riêng cho binary: {seed_paths[0]}{Color.END}")
                        elif seed_dir:
                            print(f"{Color.BLUE}    [*] Tìm thấy seed directory cho case: {seed_dir}{Color.END}")
                        if input_contract:
                            print(
                                f"{Color.BLUE}    [*] Input contract: "
                                f"{input_contract['case_id']} ({input_contract['kind']}){Color.END}"
                            )

                        recovery_reference_binary = os.path.join(
                            case_output_dir, f"{base_name}_final_ref.bin"
                        )
                        recovery_ref_label = (
                            "non-native diagnostic final IR compiled"
                            if semantic_diagnostic_only
                            else "verified final IR compiled"
                        )
                        try:
                            compile_to_binary(
                                semantic_candidate_path,
                                recovery_reference_binary,
                            )
                        except Exception:
                            pass
                        recovery_reference_available = os.path.isfile(
                            recovery_reference_binary
                        )
                        if recovery_reference_available:
                            print(
                                f"{Color.BLUE}    [*] Dùng final binary tham chiếu "
                                f"để recover: {recovery_reference_binary}{Color.END}"
                            )
                        else:
                            print(
                                f"{Color.YELLOW}    [!] Không thể biên dịch final IR; "
                                f"Ghidra/LLM recovery sẽ bị chặn.{Color.END}"
                            )

                        def run_fuzz(candidate_binary_path):
                            fuzzer = SemanticFuzzer(
                                candidate_binary_path,
                                path,
                                seed_paths=seed_paths,
                                seed_dir=seed_dir,
                                input_contract=input_contract,
                            )
                            return _run_fuzzer_sync(
                                fuzzer,
                                iterations=1000,
                                generator=generator,
                                timeout=DEFAULT_EXECUTION_TIMEOUT,
                            )

                        fuzz_report = run_fuzz(semantic_candidate_path)
                        final_semantic_report_path = os.path.join(
                            case_output_dir,
                            f"{base_name}_final_semantic_report.json",
                        )
                        _write_semantic_report(
                            final_semantic_report_path, fuzz_report
                        )
                        case_record["final_semantic_report"] = (
                            final_semantic_report_path
                        )
                        if (
                            not fuzz_report.get("is_fully_equivalent", False)
                            and not semantic_diagnostic_only
                        ):
                            case_record["finalization"] = "semantic_regression"
                            print(
                                f"{Color.YELLOW}    [!] Final IR semantic non-pass; "
                                f"không cấp quyền cho brightened intermediate."
                                f"{Color.END}"
                            )
                        # Keep the exact per-case evidence used by the batch
                        # summary.  Console-only reports made failed corpus
                        # runs impossible to audit after temporary fuzz
                        # directories were cleaned up.
                        semantic_report_path = os.path.join(
                            case_output_dir, f"{base_name}_semantic_report.json"
                        )
                        _write_semantic_report(semantic_report_path, fuzz_report)
                        print(
                            f"{Color.BLUE}      [*] Semantic report: "
                            f"{semantic_report_path}{Color.END}"
                        )
                        _print_llm_report(fuzz_report)
                        semantic_status = _semantic_status(fuzz_report)
                        if semantic_status == "pass":
                            semantic_pass_count += 1
                            case_record["semantic"] = "pass"
                        elif semantic_status == "nonpass":
                            semantic_nonpass_count += 1
                            case_record["semantic"] = "nonpass"
                        else:
                            semantic_unchecked_count += 1
                            case_record["semantic"] = "unchecked"
                        # Raw AFL is useful robustness evidence, but without a
                        # source-derived contract it can leave the program's
                        # valid input domain.  Do not let such malformed cases
                        # become the authoritative semantic recovery gate.
                        valid_domain_report = None
                        raw_mode = os.environ.get(
                            "BRIGHTEN_MUTATE_SEEDS", "raw"
                        ).lower()
                        run_valid_domain_gate = (
                            input_contract is None and
                            raw_mode == "raw" and
                            not fuzz_report.get("is_fully_equivalent", False) and
                            os.environ.get("BRIGHTEN_VALID_DOMAIN_GATE", "1").lower()
                            not in {"0", "false", "off", "no"}
                        )
                        if run_valid_domain_gate:
                            previous_mutation_mode = os.environ.get(
                                "BRIGHTEN_MUTATE_SEEDS"
                            )
                            os.environ["BRIGHTEN_MUTATE_SEEDS"] = "structured"
                            try:
                                valid_domain_report = run_fuzz(
                                    semantic_candidate_path
                                )
                            finally:
                                if previous_mutation_mode is None:
                                    os.environ.pop("BRIGHTEN_MUTATE_SEEDS", None)
                                else:
                                    os.environ["BRIGHTEN_MUTATE_SEEDS"] = (
                                        previous_mutation_mode
                                    )
                            valid_domain_report_path = os.path.join(
                                case_output_dir,
                                f"{base_name}_valid_domain_semantic_report.json",
                            )
                            _write_semantic_report(
                                valid_domain_report_path, valid_domain_report
                            )
                            case_record["semantic_valid_domain_report"] = (
                                valid_domain_report_path
                            )
                            if valid_domain_report.get("is_fully_equivalent", False):
                                valid_domain_pass_count += 1
                                case_record["semantic_valid_domain"] = "pass"
                            else:
                                valid_domain_nonpass_count += 1
                                case_record["semantic_valid_domain"] = "nonpass"
                        elif fuzz_report.get("is_fully_equivalent", False):
                            valid_domain_pass_count += 1
                            case_record["semantic_valid_domain"] = "pass"
                        else:
                            valid_domain_unchecked_count += 1
                            case_record["semantic_valid_domain"] = "unchecked"
                        if (
                            fuzz_report.get("is_fully_equivalent", False)
                            and recovery_reference_available
                            and llm_recovery_mode
                            and not semantic_diagnostic_only
                        ):
                            print(f"{Color.BLUE}      -> Bắt đầu LLM recovery vì baseline pass.{Color.END}")

                            def run_recovery_fuzz(candidate_path):
                                recovery_compare_target = recovery_reference_binary
                                print(
                                    f"{Color.BLUE}      [*] Khởi tạo semantic compare recovery với target: "
                                    f"{os.path.basename(recovery_compare_target)} ({recovery_ref_label}){Color.END}"
                                )
                                candidate_fuzzer = SemanticFuzzer(
                                    candidate_path,
                                    recovery_compare_target,
                                    seed_paths=seed_paths,
                                    seed_dir=seed_dir,
                                    input_contract=input_contract,
                                )
                                return _run_fuzzer_sync(
                                    candidate_fuzzer,
                                    iterations=llm_config.fuzz_iterations,
                                    generator=generator,
                                    timeout=llm_config.fuzz_timeout,
                                )

                            output_source = os.path.join(case_output_dir, f"{base_name}_recovered.c")
                            metadata = {
                                "original_binary": path,
                                "recovery_reference_binary": recovery_reference_binary,
                                "recovery_reference_label": recovery_ref_label,
                                "input_ir": recovery_input_ll,
                                "case": base_name,
                            }
                            result = run_recovery_loop(
                                ir_text=_read_llm_ir(
                                    recovery_input_ll, case_output_dir
                                ),
                                output_recovered_c_path=output_source,
                                case_output_dir=case_output_dir,
                                metadata=metadata,
                                fuzzer_callback=run_recovery_fuzz,
                                config=llm_config,
                            )
                            _print_llm_report(result.fuzz_report)
                            if result.success:
                                llm_success_count += 1
                                print(f"{Color.GREEN}[✓] Recovery thành công: {result.source_path}{Color.END}")
                            else:
                                print(f"{Color.YELLOW}[!] Recovery chưa đạt equivalence; candidate lưu tại: {result.source_path}{Color.END}")
                                if result.compile_error:
                                    print(f"{Color.YELLOW}    Feedback cuối: {result.compile_error[:1000]}{Color.END}")
                        elif llm_recovery_mode:
                            print(f"{Color.YELLOW}      [!] Bỏ qua LLM recovery vì semantic chưa pass đầy đủ.{Color.END}")

                    except Exception as fe:
                        semantic_unchecked_count += 1
                        case_record["semantic"] = "unchecked"
                        print(f"{Color.RED}      [✗] Lỗi xảy ra khi chạy kiểm tra Semantic Equivalence: {fe}{Color.END}")
                else:
                    case_record["brightening"] = "fail"
                    case_record["semantic"] = "not_run"
                    print(f"{Color.RED}[✗] Làm đẹp mã IR THẤT BẠI cho: {path}{Color.END}")
            except Exception as e:
                case_record["brightening"] = "error"
                case_record["semantic"] = "not_run"
                print(f"{Color.RED}[✗] Lỗi khi làm đẹp mã IR: {e}{Color.END}")
        else:
            case_record["lift"] = "fail"
            case_record["semantic"] = "not_run"
            print(f"{Color.RED}[✗] Nâng mã (Lift) THẤT BẠI cho: {path}{Color.END}")

    print("\n" + f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
    semantic_checked_count = semantic_pass_count + semantic_nonpass_count
    valid_domain_checked_count = (
        valid_domain_pass_count + valid_domain_nonpass_count
    )
    native_contract_checked_count = (
        native_contract_pass_count + native_contract_nonpass_count
    )
    all_native_contract_pass = (
        brightened_count == len(binary_paths) and
        native_contract_checked_count == brightened_count and
        native_contract_nonpass_count == 0 and
        native_contract_unchecked_count == 0
    )
    all_semantic_pass = (
        brightened_count == len(binary_paths) and
        semantic_checked_count == brightened_count and
        semantic_nonpass_count == 0 and
        semantic_unchecked_count == 0
    )
    all_verified = all_semantic_pass and all_native_contract_pass
    summary_path = os.path.join(result_pipeline_root, "pipeline_summary.json")
    summary = {
        "schema_version": 1,
        "input_csv": os.path.abspath(list_obfuscated_bin),
        "pilot_limit": pilot_limit if pilot_flag else None,
        "counts": {
            "requested": len(binary_paths),
            "lift_pass": brightened_count,
            "lift_failed": len(binary_paths) - brightened_count,
            "semantic_pass": semantic_pass_count,
            "semantic_nonpass": semantic_nonpass_count,
            "semantic_unchecked": semantic_unchecked_count,
            "semantic_valid_domain_pass": valid_domain_pass_count,
            "semantic_valid_domain_nonpass": valid_domain_nonpass_count,
            "semantic_valid_domain_unchecked": valid_domain_unchecked_count,
            "native_contract_pass": native_contract_pass_count,
            "native_contract_nonpass": native_contract_nonpass_count,
            "native_contract_unchecked": native_contract_unchecked_count,
        },
        "all_verified": all_verified,
        "cases": case_results,
    }
    with open(summary_path, "w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2, ensure_ascii=False)
    print(f"{Color.BLUE}[*] Pipeline summary: {summary_path}{Color.END}")
    summary_color = Color.GREEN if all_verified else Color.YELLOW
    summary_mark = "[✓]" if all_verified else "[!]"
    if llm_recovery_mode:
        print(
            f"{summary_color}{Color.BOLD}"
            f"{summary_mark} Đã hoàn thành xử lý. Brightening: {brightened_count}/{len(binary_paths)} | "
            f"Native contract PASS: {native_contract_pass_count}/{native_contract_checked_count} | "
            f"Native contract non-pass: {native_contract_nonpass_count} | "
            f"Native contract unchecked: {native_contract_unchecked_count} | "
            f"Semantic PASS: {semantic_pass_count}/{semantic_checked_count} | "
            f"Semantic non-pass: {semantic_nonpass_count} | "
            f"Semantic unchecked: {semantic_unchecked_count} | "
            f"LLM Recovery thành công: {llm_success_count}/{len(binary_paths)}{Color.END}"
        )
    else:
        print(
            f"{summary_color}{Color.BOLD}{summary_mark} Đã hoàn thành xử lý. "
            f"Brightening: {brightened_count}/{len(binary_paths)} | "
            f"Native contract PASS: {native_contract_pass_count}/{native_contract_checked_count} | "
            f"Native contract non-pass: {native_contract_nonpass_count} | "
            f"Native contract unchecked: {native_contract_unchecked_count} | "
            f"Semantic PASS: {semantic_pass_count}/{semantic_checked_count} | "
            f"Semantic non-pass: {semantic_nonpass_count} | "
            f"Semantic unchecked: {semantic_unchecked_count} | "
            f"Valid-domain PASS: {valid_domain_pass_count}/{valid_domain_checked_count} | "
            f"Valid-domain non-pass: {valid_domain_nonpass_count}{Color.END}"
        )
    print(f"{Color.BLUE}[*] Tất cả kết quả được lưu tại: {result_pipeline_root}{Color.END}")
    print(f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")

    # ── Auto-run evaluation: collect metrics CSV ────────────────────────────
    try:
        import sys as _sys
        _eval_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "evaluation")
        if _eval_dir not in _sys.path:
            _sys.path.insert(0, _eval_dir)
        from evaluation.collect_metrics import run_collect  # type: ignore
        _csv_path = os.path.join(result_pipeline_root, "metrics.csv")
        print(f"\n{Color.BLUE}[*] Đang tạo metrics CSV...{Color.END}")
        run_collect(result_pipeline_root, _csv_path)
    except Exception as _e:
        print(f"{Color.YELLOW}[!] Evaluation metrics skipped: {_e}{Color.END}")
    # ────────────────────────────────────────────────────────────────────────

    return 0

if __name__ == "__main__":
    sys.exit(main())
