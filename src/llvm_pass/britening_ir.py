#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""
### Phân tích chi tiết và đề xuất bổ sung cho từng Phase:

  #### PHASE 0 — Symbol Discovery

  - Chi tiết: Nên thu thập thêm bảng ký hiệu từ ELF gốc (nếu có) hoặc xuất từ IDA Pro để ánh xạ địa chỉ PC (sub_XXXX) sang tên hàm gốc ngay từ đầu.
  - Verify: Đảm bảo metadata được đính kèm dưới dạng LLVM Named Metadata (ví dụ: !brighten.symbols) để các pass sau truy vấn trực tiếp.

  #### PHASE 1 — Structural Repair

  - Chi tiết: Cần bổ sung việc loại bỏ các directive vô nghĩa của Assembly cũ được nhúng qua inline asm của McSema (gây crash compiler mới).

  #### PHASE 2 — Call / Return Devirtualization

  - Chi tiết:
      - brighten-remill-return-lower: Chuyển đổi lệnh return thô (McSema lưu RAX vào State rồi RET void) thành lệnh ret trả về giá trị thực tế của RAX.
      - Cần đảm bảo globaldce chạy ở cuối phase này để xóa bỏ các hàm thunk/dispatcher không còn ai gọi.

  #### PHASE 3 — Register State SSA

  - Chi tiết:
      - brighten-flag-lower: Chuyển đổi toàn bộ các phép tính toán cờ CPU phức tạp (CF, ZF...) thành các biến logic i1 cục bộ. LLVM gvn và dce sau đó sẽ dễ dàng tối giản các lệnh so sánh nhảy.

  #### PHASE 4 — Stack Frame Recovery

  - Chi tiết:
      - brighten-stack-model: Dựng lại bản đồ stack frame bằng cách tìm toán hạng RSP trong SSA.
      - brighten-host-frame: Thay thế các truy cập offset bằng alloca. Chú ý: Cần xử lý trường hợp biến cục bộ bị truyền địa chỉ (passed by pointer/reference) sang hàm khác.

  #### PHASE 5 — ABI Recovery / Function Signature Rewrite

  - Chi tiết:
      - brighten-livein-liveout: Phân tích thanh ghi nào là đầu vào (Live-in) và đầu ra (Live-out) của từng hàm để quyết định danh sách tham số.
      - Chạy deadargelim ngay sau đó để xóa bỏ các tham số thừa (ví dụ hàm không dùng đến RDX nhưng ABI mặc định truyền vào).

  #### PHASE 6 — Global/Data Recovery

  - Chi tiết:
      - brighten-string-recover: Cực kỳ quan trọng. Quét phân đoạn @seg_...__rodata để dựng lại @.str = private unnamed_addr constant ....
      - brighten-jumptable-recover: Nhận diện cấu trúc Jump Table từ lệnh switch gián tiếp để khôi phục cấu trúc điều khiển chuẩn (chuỗi if-else hoặc switch-case sạch).

  #### PHASE 7 — Type Reconstruction

  - Chi tiết:
      - Phân tích các lệnh getelementptr dựa trên kiểu dữ liệu của alloca ở Phase 4 để nhóm các biến đơn lẻ thành struct/array C gốc.

  #### PHASE 8 — Final Native Cleanup

  - Chi tiết:
      - brighten-type-cleanup: Loại bỏ định nghĩa %struct.State và các type thừa ra khỏi IR.
      - function-attrs: Tự động suy luận các thuộc tính hàm (readonly, readnone, nofree) để IR đầu ra chuẩn hóa tối đa.


"""
import os
import sys
import argparse
import subprocess
import shutil
import re
import json
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Thư mục gốc dự án
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))

# Danh sách các pass plugin và đường dẫn tương đối từ SCRIPT_DIR
PLUGINS = [
    "brighten_010_repair_pass/build/BrightenRepairPass.so",
    "brighten_015_runtime_helper_materialization/build/BrightenRuntimeHelperPass.so",
    "brighten_020_devirt_pass/build/BrightenDevirtPass.so",
    "brighten_030_state_ssa_pass/build/BrightenStateSSAPass.so",
    "brighten_040_stack_frame_pass/build/BrightenStackFramePass.so",
    "brighten_050_abi_recovery/build/BrightenABIRecoveryPass.so",
    "brighten_060_extern_call_bridge/build/BrightenExternCallBridgePass.so",
    "brighten_070_global_data_recovery/build/BrightenGlobalDataRecoveryPass.so",
    "brighten_080_type_reconstruction/build/BrightenTypeReconstructionPass.so",
    "brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so"
]
PASS_PIPELINE = (
    "brighten-repair-pass,brighten-remill-runtime-pass,brighten-devirt-pass,always-inline,brighten-state-ssa-pass,brighten-stack-frame-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-global-data-recovery-pass,brighten-devirt-pass,brighten-type-reconstruct,deadargelim,function-attrs,ipsccp,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,globaldce,brighten-native-cleanup-pass,brighten-extern-call-bridge,dfa-jump-threading,simplifycfg,adce,default<O3>,brighten-native-cleanup-pass,brighten-local-state-ssa-pass,brighten-region-ssa-unflatten-pass,simplifycfg,adce,brighten-native-cleanup-final-pass,jump-threading,simplifycfg,adce,verify"
)
if os.environ.get("BRIGHTEN_DISABLE_STACK_FRAME", "").lower() in {"1", "true", "yes"}:
    PASS_PIPELINE = PASS_PIPELINE.replace(",brighten-stack-frame-pass", "")
if os.environ.get("BRIGHTEN_DISABLE_ABI_RECOVERY", "").lower() in {"1", "true", "yes"}:
    PASS_PIPELINE = PASS_PIPELINE.replace(",brighten-abi-recovery-pass", "")
if os.environ.get("BRIGHTEN_DISABLE_EXTERN_BRIDGE", "").lower() in {"1", "true", "yes"}:
    PASS_PIPELINE = PASS_PIPELINE.replace(",brighten-extern-call-bridge", "")
PASS_PIPELINE = os.environ.get("BRIGHTEN_PASS_PIPELINE", PASS_PIPELINE)
class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'


NATIVE_CONTRACT_REPORT_SUFFIX = "_native_contract_report.json"
SOUPER_REPORT_SUFFIX = "_souper_report.json"
SOUPER_PASS_PIPELINE = "function(souper),dce,instcombine,simplifycfg,verify"
SOUPER_MAXIMUM_COMPONENTS = (
    "and,or,xor,add,sub,mul,shl,lshr,ashr,"
    "eq,ne,ult,slt,ule,sle,select,const"
)


def native_contract_report_path(output_path):
    """Return the machine-readable native-contract report beside an output."""
    return f"{os.path.splitext(output_path)[0]}{NATIVE_CONTRACT_REPORT_SUFFIX}"


def souper_report_path(output_path):
    """Return the machine-readable Souper report beside an output."""
    return f"{os.path.splitext(output_path)[0]}{SOUPER_REPORT_SUFFIX}"


def optimization_artifact_paths(output_path):
    """Return explicit IR snapshots used to compare pipeline stages."""
    stem = os.path.splitext(output_path)[0]
    return {
        "before_brightening": f"{stem}_before_brightening.ll",
        "before_souper": f"{stem}_before_souper.ll",
        "after_souper": f"{stem}_after_souper.ll",
    }


def _emit_ll_artifact(source_path, artifact_path, llvm_dis=None):
    """Materialize one textual LLVM IR snapshot without rewriting its IR."""
    source_path = os.path.abspath(source_path)
    artifact_path = os.path.abspath(artifact_path)
    if os.path.splitext(source_path)[1].lower() == ".ll":
        if source_path != artifact_path:
            shutil.copy2(source_path, artifact_path)
        return True
    llvm_dis = llvm_dis or shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
    if not llvm_dis:
        print(f"{Color.RED}[✗] Không tìm thấy llvm-dis-21/llvm-dis để tạo "
              f"artifact {artifact_path}.{Color.END}")
        return False
    result = subprocess.run(
        [llvm_dis, source_path, "-o", artifact_path],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"{Color.RED}[✗] Không thể tạo artifact {artifact_path}: "
              f"{result.stderr}{Color.END}")
        return False
    return True


def _env_enabled(name, default=True):
    value = os.environ.get(name)
    if value is None:
        return default
    return value.lower() not in {"0", "false", "off", "no"}


def souper_mode_flags(mode):
    """Return solver/synthesis flags for a named Souper strength preset."""
    normalized = (mode or "maximum").strip().lower()
    if normalized in {"safe", "default"}:
        return "safe", []
    if normalized in {"maximum", "max", "aggressive"}:
        return "maximum", [
            "-souper-use-cegis",
            f"-souper-synthesis-comps={SOUPER_MAXIMUM_COMPONENTS}",
            "-souper-synthesis-comp-num=4",
            "-souper-synthesis-wiring-iterations=30",
            "-souper-exploit-blockpcs",
            "-souper-harvest-uses",
            "-souper-max-constant-synthesis-tries=100",
            "-souper-max-lhs-size=4096",
        ]
    raise ValueError(
        f"unsupported BRIGHTEN_SOUPER_MODE={mode!r}; use safe or maximum"
    )


def resolve_souper_plugin():
    """Find the project-local LLVM 21 Souper pass plugin."""
    configured = os.environ.get("BRIGHTEN_SOUPER_PLUGIN")
    candidates = [configured] if configured else [
        os.path.join(
            PROJECT_ROOT, "dependency", "souper", "build-llvm21",
            "libsouperPass.so",
        ),
        os.path.join(PROJECT_ROOT, "dependency", "souper", "libsouperPass.so"),
    ]
    return next((os.path.abspath(path) for path in candidates
                 if path and os.path.isfile(path)), None)


def _write_souper_report(output_path, payload):
    report_path = souper_report_path(output_path)
    tmp_path = report_path + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        json.dump({"schema_version": 1, **payload}, handle, indent=2,
                  ensure_ascii=False)
    os.replace(tmp_path, report_path)
    return report_path


def optimize_with_souper(input_path, output_path=None, _mode_override=None):
    """Run Souper after brightening and atomically publish verified output.

    The original bitcode is never replaced until Souper and LLVM's verifier
    both succeed.  This prevents a timeout or solver/plugin failure from
    leaving a partially written pipeline artifact.
    """
    input_path = os.path.abspath(input_path)
    output_path = os.path.abspath(output_path or input_path)
    started = time.monotonic()
    if not _env_enabled("BRIGHTEN_SOUPER", True):
        if input_path != output_path:
            shutil.copy2(input_path, output_path)
        report_path = _write_souper_report(output_path, {
            "status": "disabled",
            "input": os.path.abspath(input_path),
            "output": os.path.abspath(output_path),
        })
        print(f"{Color.YELLOW}[*] Souper optimization disabled; report: "
              f"{report_path}{Color.END}")
        return True

    plugin_path = resolve_souper_plugin()
    opt_bin = shutil.which("opt-21") or shutil.which("opt")
    if not plugin_path or not opt_bin:
        missing = "Souper plugin" if not plugin_path else "opt-21/opt"
        report_path = _write_souper_report(output_path, {
            "status": "unavailable",
            "input": os.path.abspath(input_path),
            "output": os.path.abspath(output_path),
            "error": f"missing {missing}",
        })
        print(f"{Color.RED}[✗] Không thể chạy Souper: thiếu {missing}. "
              f"Report: {report_path}{Color.END}")
        return False

    output_ext = os.path.splitext(output_path)[1].lower()
    temp_output = f"{output_path}.souper.tmp.{os.getpid()}{output_ext or '.bc'}"
    pipeline = os.environ.get("BRIGHTEN_SOUPER_PIPELINE", SOUPER_PASS_PIPELINE)
    try:
        mode, mode_flags = souper_mode_flags(
            _mode_override or os.environ.get("BRIGHTEN_SOUPER_MODE", "maximum")
        )
    except ValueError as exc:
        report_path = _write_souper_report(output_path, {
            "status": "failed",
            "input": input_path,
            "output": output_path,
            "error": str(exc),
        })
        print(f"{Color.RED}[✗] {exc}. Report: {report_path}{Color.END}")
        return False
    default_solver_timeout = "60" if mode == "maximum" else "15"
    solver_timeout = int(os.environ.get(
        "BRIGHTEN_SOUPER_SOLVER_TIMEOUT", default_solver_timeout
    ))
    cmd = [
        opt_bin,
        "-load-pass-plugin", plugin_path,
        "-souper-debug-level=0",
        f"-solver-timeout={solver_timeout}",
        *mode_flags,
        "-passes", pipeline,
        input_path,
        "-o", temp_output,
    ]
    if output_ext == ".ll":
        cmd.insert(-2, "-S")

    env = os.environ.copy()
    bundled_z3 = os.path.join(PROJECT_ROOT, "dependency", "souper", "lib")
    old_library_path = env.get("LD_LIBRARY_PATH")
    env["LD_LIBRARY_PATH"] = (
        bundled_z3 if not old_library_path
        else bundled_z3 + os.pathsep + old_library_path
    )
    default_module_timeout = "900" if mode == "maximum" else "120"
    timeout = float(os.environ.get(
        "BRIGHTEN_SOUPER_TIMEOUT", default_module_timeout
    ))
    input_size = os.path.getsize(input_path)

    def fallback_to_safe(maximum_failure):
        if mode != "maximum":
            return False
        try:
            os.unlink(temp_output)
        except FileNotFoundError:
            pass
        print(f"{Color.YELLOW}[!] Souper maximum không xử lý an toàn module "
              f"này; tự động fallback sang safe.{Color.END}")
        if not optimize_with_souper(
            input_path, output_path, _mode_override="safe"
        ):
            return False
        fallback_path = souper_report_path(output_path)
        try:
            with open(fallback_path, "r", encoding="utf-8") as handle:
                fallback_report = json.load(handle)
        except (OSError, ValueError):
            fallback_report = {
                "status": "pass",
                "input": input_path,
                "output": output_path,
                "mode": "safe",
            }
        fallback_report.pop("schema_version", None)
        fallback_report.update({
            "status": "pass_with_fallback",
            "requested_mode": "maximum",
            "effective_mode": "safe",
            "maximum_failure": maximum_failure,
        })
        report_path = _write_souper_report(output_path, fallback_report)
        print(f"{Color.GREEN}[✓] Souper safe fallback hoàn tất. Report: "
              f"{report_path}{Color.END}")
        return True

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, env=env, timeout=timeout,
            cwd=PROJECT_ROOT,
        )
        if result.returncode != 0 or not os.path.isfile(temp_output):
            error = (result.stderr or result.stdout or
                     f"opt exited with {result.returncode}")[-8000:]
            report_path = _write_souper_report(output_path, {
                "status": "failed",
                "input": os.path.abspath(input_path),
                "output": os.path.abspath(output_path),
                "plugin": plugin_path,
                "mode": mode,
                "mode_flags": mode_flags,
                "pipeline": pipeline,
                "returncode": result.returncode,
                "duration_seconds": round(time.monotonic() - started, 3),
                "error": error,
            })
            failure_color = Color.YELLOW if mode == "maximum" else Color.RED
            failure_mark = "[!]" if mode == "maximum" else "[✗]"
            print(f"{failure_color}{failure_mark} Souper {mode} failed "
                  f"(code={result.returncode}). Report: {report_path}{Color.END}")
            return fallback_to_safe({
                "status": "failed",
                "returncode": result.returncode,
                "duration_seconds": round(time.monotonic() - started, 3),
                "error": error,
            })
        output_size = os.path.getsize(temp_output)
        os.replace(temp_output, output_path)
        report_path = _write_souper_report(output_path, {
            "status": "pass",
            "input": os.path.abspath(input_path),
            "output": os.path.abspath(output_path),
            "plugin": plugin_path,
            "mode": mode,
            "mode_flags": mode_flags,
            "pipeline": pipeline,
            "solver_timeout_seconds": solver_timeout,
            "duration_seconds": round(time.monotonic() - started, 3),
            "input_bytes": input_size,
            "output_bytes": output_size,
        })
        print(f"{Color.GREEN}[✓] Souper optimization hoàn tất: "
              f"{input_size} -> {output_size} bytes. "
              f"Report: {report_path}{Color.END}")
        return True
    except subprocess.TimeoutExpired:
        report_path = _write_souper_report(output_path, {
            "status": "timeout",
            "input": os.path.abspath(input_path),
            "output": os.path.abspath(output_path),
            "plugin": plugin_path,
            "mode": mode,
            "mode_flags": mode_flags,
            "pipeline": pipeline,
            "timeout_seconds": timeout,
            "duration_seconds": round(time.monotonic() - started, 3),
        })
        timeout_color = Color.YELLOW if mode == "maximum" else Color.RED
        timeout_mark = "[!]" if mode == "maximum" else "[✗]"
        print(f"{timeout_color}{timeout_mark} Souper {mode} timeout sau "
              f"{timeout:.1f}s. Report: {report_path}{Color.END}")
        return fallback_to_safe({
            "status": "timeout",
            "timeout_seconds": timeout,
            "duration_seconds": round(time.monotonic() - started, 3),
        })
    except OSError as exc:
        report_path = _write_souper_report(output_path, {
            "status": "failed",
            "input": os.path.abspath(input_path),
            "output": os.path.abspath(output_path),
            "plugin": plugin_path,
            "mode": mode,
            "mode_flags": mode_flags,
            "pipeline": pipeline,
            "error": str(exc),
        })
        print(f"{Color.RED}[✗] Souper execution error: {exc}. "
              f"Report: {report_path}{Color.END}")
        return False
    finally:
        try:
            os.unlink(temp_output)
        except FileNotFoundError:
            pass


def parse_native_contract_reports(stderr):
    """Parse every cleanup report and return the authoritative final report."""
    reports = []
    current = None
    metric_re = re.compile(r"^  ([^:]+): ([0-9]+)(?:/([0-9]+))?$")
    for line in (stderr or "").splitlines():
        if line == "brighten-native-cleanup report:":
            current = {"metrics": {}, "findings": []}
            reports.append(current)
            continue
        if current is None:
            continue
        if line.startswith("  native contract finding: "):
            current["findings"].append(
                line[len("  native contract finding: "):]
            )
            continue
        match = metric_re.match(line)
        if not match:
            continue
        key = match.group(1).strip().replace(" ", "_").replace("/", "_")
        if match.group(3) is None:
            current["metrics"][key] = int(match.group(2))
        else:
            current["metrics"][key] = {
                "ptrtoint": int(match.group(2)),
                "inttoptr": int(match.group(3)),
            }

    if not reports:
        return None
    final = reports[-1]
    violations = final["metrics"].get("native_contract_violations")
    final["is_fully_native"] = violations == 0 if violations is not None else False
    final["status"] = "compliant" if final["is_fully_native"] else "non_compliant"
    # Structural status is intentionally separate from behavioral evidence.
    # A runnable compatibility output must never be mislabeled as native just
    # because LLVM verification succeeded.
    final["output_class"] = (
        "native_candidate" if final["is_fully_native"] else "compat_runnable"
    )
    final["report_count"] = len(reports)
    return final


def write_native_contract_report(output_path, report, strict_enforced=False):
    """Atomically persist the verifier result used to label one output."""
    report_path = native_contract_report_path(output_path)
    payload = {
        "schema_version": 1,
        "output": os.path.abspath(output_path),
        "strict_enforced": bool(strict_enforced),
        **(report or {
            "status": "unavailable",
            "is_fully_native": False,
            "metrics": {},
            "findings": [],
            "report_count": 0,
        }),
    }
    tmp_path = report_path + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
    os.replace(tmp_path, report_path)
    return report_path


def read_native_contract_report(output_path):
    report_path = native_contract_report_path(output_path)
    try:
        with open(report_path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None

def clean_unused_types_and_globals(content):
    # 1. Skip function stripping (keep all defined functions to avoid undefined reference errors)
    new_lines = content.split('\n')
    
    # 2. Iterate to remove unused globals and aliases
    while True:
        lines = content.split('\n')
        globals_def = {}
        for i, line in enumerate(lines):
            match = re.match(r'^@([a-zA-Z0-9_.]+)\s*=\s*(?:internal\s+)?(?:constant|global|alias|thread_local)\s+', line)
            if match:
                globals_def[match.group(1)] = i
                
        if not globals_def:
            break
            
        global_ref_counts = {name: 0 for name in globals_def}
        for i, line in enumerate(lines):
            def_match = re.match(r'^@([a-zA-Z0-9_.]+)\s*=\s*', line)
            def_name = def_match.group(1) if def_match else None
            
            refs = re.findall(r'@([a-zA-Z0-9_.]+)\b', line)
            for ref in refs:
                if ref in global_ref_counts:
                    if ref != def_name:
                        global_ref_counts[ref] += 1
                        
        unused_globals = [name for name, count in global_ref_counts.items() if count == 0]
        if not unused_globals:
            break
            
        new_lines = []
        for i, line in enumerate(lines):
            match = re.match(r'^@([a-zA-Z0-9_.]+)\s*=\s*', line)
            if match and match.group(1) in unused_globals:
                continue
            new_lines.append(line)
        content = '\n'.join(new_lines)
        
    # 3. Remove unused struct/type definitions
    while True:
        lines = content.split('\n')
        types_def = {}
        for i, line in enumerate(lines):
            match = re.match(r'^%([a-zA-Z0-9_.]+)\s*=\s*type\s+', line)
            if match:
                types_def[match.group(1)] = i
                
        if not types_def:
            break
            
        type_ref_counts = {name: 0 for name in types_def}
        for i, line in enumerate(lines):
            def_match = re.match(r'^%([a-zA-Z0-9_.]+)\s*=\s*', line)
            def_name = def_match.group(1) if def_match else None
            
            refs = re.findall(r'%([a-zA-Z0-9_.]+)\b', line)
            for ref in refs:
                if ref in type_ref_counts:
                    if ref != def_name:
                        type_ref_counts[ref] += 1
                        
        unused_types = [name for name, count in type_ref_counts.items() if count == 0]
        if not unused_types:
            break
            
        new_lines = []
        for i, line in enumerate(lines):
            match = re.match(r'^%([a-zA-Z0-9_.]+)\s*=\s*', line)
            if match and match.group(1) in unused_types:
                continue
            new_lines.append(line)
        content = '\n'.join(new_lines)
        
    return content

def clean_ir_file(ll_path, binary_path=None):
    """Compatibility shim retained for callers of the old API.

    IR cleanup is deliberately implemented in LLVM passes.  Textual edits
    cannot safely recover types, replace unresolved pointers, or synthesize an
    entrypoint without changing semantics, so this function only verifies that
    the disassembled file exists and never rewrites it.
    """
    return os.path.exists(ll_path)

def brighten_ir(input_path, output_path=None, binary_path=None):
    """
    Chạy llvm opt với các pass plugin làm đẹp IR (brightening) và dọn dẹp boilerplate
    """
    if not os.path.exists(input_path):
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy file đầu vào tại '{input_path}'{Color.END}")
        return False

    opt_bin = shutil.which("opt-21") or shutil.which("opt")
    if not opt_bin:
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy 'opt-21' hoặc 'opt' trong hệ thống.{Color.END}")
        return False

    # Xác định đường dẫn output
    if not output_path:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_brightened{ext}"

    artifacts = optimization_artifact_paths(output_path)
    llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
    if not _emit_ll_artifact(
        input_path, artifacts["before_brightening"], llvm_dis
    ):
        return False
    print(f"{Color.BLUE}[*] IR trước brightening: "
          f"{artifacts['before_brightening']}{Color.END}")

    # A repeated CLI invocation must never inherit a stale compliance result
    # from an older output if opt fails before producing a new report.
    try:
        os.unlink(native_contract_report_path(output_path))
    except FileNotFoundError:
        pass
    try:
        os.unlink(souper_report_path(output_path))
    except FileNotFoundError:
        pass

    # Build command
    cmd = [opt_bin]

    # Load plugins
    for plugin_rel in PLUGINS:
        plugin_path = os.path.abspath(os.path.join(SCRIPT_DIR, plugin_rel))
        if not os.path.exists(plugin_path):
            print(f"{Color.RED}[✗] Lỗi: Không tìm thấy pass plugin tại '{plugin_path}'{Color.END}")
            return False
        cmd.extend(["-load-pass-plugin", plugin_path])

    if os.environ.get("BRIGHTEN_NATIVE_STRICT", "0") == "1":
        # The plugin must be loaded before opt parses its pass-specific flag.
        cmd.append("-brighten-native-strict")
    if os.environ.get("BRIGHTEN_SAVE_CHECKPOINTS", "0") == "1":
        cmd.append("-print-after-all")
    print_after = os.environ.get("BRIGHTEN_PRINT_AFTER")
    if print_after:
        cmd.extend(["-print-after", print_after])
    # Native ABI lowering is part of the production pipeline.  Keep an
    # explicit opt-out for debugging old lifted IR, but do not make the
    # dataset path depend on a hidden environment variable.
    if os.environ.get("BRIGHTEN_NATIVE_STATE_SSA", "1").lower() not in {
        "0", "false", "off", "no"
    }:
        cmd.append("-brighten-native-state-ssa")

    # Thiết lập pipeline pass và file input/output
    pipeline = os.environ.get("BRIGHTEN_PASS_PIPELINE", PASS_PIPELINE)
    for skipped in os.environ.get("BRIGHTEN_SKIP_PASSES", "").split(","):
        skipped = skipped.strip()
        if skipped:
            pipeline = ",".join(p for p in pipeline.split(",") if p != skipped)
    cmd.extend([
        "-passes", pipeline,
        input_path,
        "-o", output_path
    ])
    print(f"{Color.BLUE}[*] Đang thực thi brightening với: {opt_bin}{Color.END}")
    print(f"{Color.GRAY}    Lệnh: {' '.join(cmd)}{Color.END}")

    try:
        env = os.environ.copy()
        env["REMILL_STACK_SSA_ALLOW_BOUNDARY"] = "1"
        opt_timeout = float(os.environ.get("BRIGHTEN_OPT_TIMEOUT", "180"))
        try:
            res = subprocess.run(cmd, capture_output=True, text=True,
                                 env=env, timeout=opt_timeout)
            dump_path = os.environ.get("BRIGHTEN_DUMP_OPT_LOG")
            if dump_path:
                with open(dump_path, "w", encoding="utf-8") as dump:
                    dump.write(res.stdout or "")
                    dump.write(res.stderr or "")
        except subprocess.TimeoutExpired as exc:
            print(f"{Color.RED}[✗] opt timeout sau {opt_timeout:.1f}s; bỏ qua module để tránh treo batch.{Color.END}")
            if exc.stderr:
                print(f"{Color.RED}    Stderr trước timeout: {exc.stderr}{Color.END}")
            return False
        if res.returncode == 0:
            native_report = parse_native_contract_reports(res.stderr)
            report_path = write_native_contract_report(
                output_path,
                native_report,
                strict_enforced=os.environ.get("BRIGHTEN_NATIVE_STRICT", "0") == "1",
            )
            if native_report:
                metrics = native_report.get("metrics", {})
                print("brighten-native-cleanup final contract report:")
                print(
                    "  native contract violations: "
                    f"{metrics.get('native_contract_violations', 'unknown')}"
                )
                print(f"  contract status: {native_report.get('status')}")
            print(f"{Color.BLUE}[*] Native contract report: {report_path}{Color.END}")
            if not _emit_ll_artifact(
                output_path, artifacts["before_souper"], llvm_dis
            ):
                return False
            print(f"{Color.BLUE}[*] IR sau brightening / trước Souper: "
                  f"{artifacts['before_souper']}{Color.END}")
            print(f"{Color.BLUE}[*] Chạy Souper trên IR sau brightening...{Color.END}")
            if not optimize_with_souper(output_path):
                return False
            if not _emit_ll_artifact(
                output_path, artifacts["after_souper"], llvm_dis
            ):
                return False
            print(f"{Color.BLUE}[*] IR sau Souper: "
                  f"{artifacts['after_souper']}{Color.END}")
            print(f"{Color.GREEN}[✓] Brightening hoàn tất! Kết quả đã ghi ra: {output_path}{Color.END}")
            
            # Chạy llvm-dis để sinh file .ll cho dễ đọc nếu file output là .bc
            if output_path.endswith(".bc"):
                if llvm_dis:
                    output_ll = f"{os.path.splitext(output_path)[0]}.ll"
                    dis = subprocess.run([llvm_dis, output_path, "-o", output_ll],
                                         capture_output=True, text=True)
                    if dis.returncode != 0:
                        print(f"{Color.RED}[✗] llvm-dis thất bại: {dis.stderr}{Color.END}")
                        return False
                    print(f"{Color.BLUE}[*] Đã disassemble kết quả LLVM; không sửa textual IR hậu kỳ: {output_ll}{Color.END}")
            return True
        else:
            print(f"{Color.RED}[✗] Lỗi khi chạy opt (Mã lỗi: {res.returncode}){Color.END}")
            print(f"{Color.RED}    Stderr: {res.stderr}{Color.END}")
            return False
    except Exception as e:
        print(f"{Color.RED}[✗] Lỗi thực thi: {e}{Color.END}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Chạy các pass brightening IR bằng các plugin .so có sẵn")
    parser.add_argument("-i", "--input", required=True, help="Đường dẫn file LLVM Bitcode (.bc) hoặc IR (.ll) đầu vào")
    parser.add_argument("-o", "--output", help="Đường dẫn file đầu ra (.bc hoặc .ll)")
    args = parser.parse_args()

    success = brighten_ir(args.input, args.output)
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
