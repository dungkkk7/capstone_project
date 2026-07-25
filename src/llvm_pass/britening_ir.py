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
    "brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so",
    "deobfuscate_095_deobfus_ollvm/build/lib095.so"
]
PASS_PIPELINE = (
    "brighten-repair-pass,brighten-remill-runtime-pass,brighten-devirt-pass,always-inline,brighten-state-ssa-pass,brighten-stack-frame-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-global-data-recovery-pass,brighten-devirt-pass,brighten-type-reconstruct,deadargelim,function-attrs,ipsccp,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,globaldce,brighten-native-cleanup-pass,095,brighten-extern-call-bridge,dfa-jump-threading,simplifycfg,adce,default<O3>,brighten-native-cleanup-pass,brighten-local-state-ssa-pass,brighten-region-ssa-unflatten-pass,simplifycfg,adce,jump-threading,simplifycfg,sroa,mem2reg,adce,default<O3>,brighten-native-cleanup-final-pass,verify"
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


def native_contract_report_path(output_path):
    """Return the machine-readable native-contract report beside an output."""
    return f"{os.path.splitext(output_path)[0]}{NATIVE_CONTRACT_REPORT_SUFFIX}"


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

    # A repeated CLI invocation must never inherit a stale compliance result
    # from an older output if opt fails before producing a new report.
    try:
        os.unlink(native_contract_report_path(output_path))
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
    # Lifted modules carry the complete Remill runtime DWARF graph. It has no
    # effect on program semantics, but llvm-dis prints thousands of !DI*
    # records into the brightened IR and needlessly inflates LLM/recovery
    # inputs. Strip it structurally in LLVM instead of deleting textual !N
    # records, which may leave dangling metadata references. Keep an explicit
    # opt-out for pass debugging.
    if os.environ.get("BRIGHTEN_KEEP_DEBUG_INFO", "0").lower() not in {
        "1", "true", "yes", "on"
    }:
        cmd.append("-strip-debug")
    # Native ABI lowering is part of the production pipeline.  Keep an
    # explicit opt-out for debugging old lifted IR, but do not make the
    # dataset path depend on a hidden environment variable.
    if os.environ.get("BRIGHTEN_NATIVE_STATE_SSA", "1").lower() not in {
        "0", "false", "off", "no"
    }:
        cmd.append("-brighten-native-state-ssa")

    # Keep deobfuscation proof budgets explicit in the production command.
    # LLVM command-line option defaults from a dynamically loaded plugin are
    # otherwise difficult to audit from batch logs.  Direct/native MBA rules
    # stay enabled when the generic MBA SMT fallback budget is zero.
    mba_z3_candidates = os.environ.get(
        "BRIGHTEN_095_MBA_Z3_CANDIDATES", "0"
    )
    opaque_z3_candidates = os.environ.get(
        "BRIGHTEN_095_OPAQUE_Z3_CANDIDATES", "256"
    )
    for name, value in {
        "BRIGHTEN_095_MBA_Z3_CANDIDATES": mba_z3_candidates,
        "BRIGHTEN_095_OPAQUE_Z3_CANDIDATES": opaque_z3_candidates,
    }.items():
        if not re.fullmatch(r"[0-9]+", value):
            print(
                f"{Color.RED}[✗] {name} phải là số nguyên không âm, "
                f"nhận được: {value!r}{Color.END}"
            )
            return False
    cmd.extend([
        f"-095-max-z3-candidates={mba_z3_candidates}",
        f"-095-max-opaque-z3-candidates={opaque_z3_candidates}",
    ])

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
            print(f"{Color.GREEN}[✓] Brightening hoàn tất! Kết quả đã ghi ra: {output_path}{Color.END}")
            
            # Chạy llvm-dis để sinh file .ll cho dễ đọc nếu file output là .bc
            if output_path.endswith(".bc"):
                llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
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
