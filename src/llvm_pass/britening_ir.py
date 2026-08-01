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
import struct
import tempfile

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
    "brighten-repair-pass,brighten-remill-runtime-pass,brighten-devirt-pass,always-inline,brighten-state-ssa-pass,brighten-address-canonicalize,brighten-stack-frame-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-global-data-recovery-pass,brighten-devirt-pass,brighten-type-reconstruct,deadargelim,function-attrs,ipsccp,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,globaldce,brighten-native-cleanup-pass,brighten-guest-pointer-resolver-canonicalize,095,brighten-devirt-pass,brighten-address-canonicalize,brighten-stack-frame-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-type-reconstruct,dfa-jump-threading,simplifycfg,adce,default<O3>,brighten-native-cleanup-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-late-residual-format-string-recovery,brighten-guest-pointer-resolver-canonicalize,brighten-local-state-ssa-pass,brighten-region-ssa-unflatten-pass,brighten-address-canonicalize,simplifycfg,adce,jump-threading,simplifycfg,sroa,mem2reg,adce,default<O3>,brighten-address-canonicalize,brighten-post-state-frame-pass,brighten-heap-proven-resolver-collapse,brighten-native-cleanup-post-frame-pass,dce,globaldce,brighten-native-cleanup-final-pass,verify"
)
if os.environ.get("BRIGHTEN_DISABLE_STACK_FRAME", "").lower() in {"1", "true", "yes"}:
    PASS_PIPELINE = PASS_PIPELINE.replace(",brighten-stack-frame-pass", "")
    PASS_PIPELINE = PASS_PIPELINE.replace(",brighten-post-state-frame-pass", "")
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


def late_address_canonicalize_index(pipeline_parts):
    """Return the final 080 canonicalization boundary in a pass pipeline.

    The post-State 040 consumer needs the canonical form produced after the
    tail optimizer, not an earlier address pass which may still see unstable
    ConstantExpr anchors or non-fixed frame offsets.
    """
    return len(pipeline_parts) - 1 - pipeline_parts[::-1].index(
        "brighten-address-canonicalize"
    )


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


def verify_native_contract(input_path):
    """Run the non-mutating final native-contract gate on one final IR file."""
    if not os.path.isfile(input_path):
        return False

    opt_bin = shutil.which("opt-21") or shutil.which("opt")
    plugin_path = os.path.abspath(
        os.path.join(
            SCRIPT_DIR,
            "brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so",
        )
    )
    if not opt_bin or not os.path.isfile(plugin_path):
        write_native_contract_report(input_path, None, strict_enforced=True)
        return False

    try:
        os.unlink(native_contract_report_path(input_path))
    except FileNotFoundError:
        pass

    cmd = [
        opt_bin,
        "-load-pass-plugin",
        plugin_path,
        "-brighten-native-strict",
        "-passes",
        "brighten-native-cleanup-final-pass,verify",
        "-disable-output",
        input_path,
    ]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=float(os.environ.get("BRIGHTEN_FINAL_VERIFY_TIMEOUT", "60")),
        )
    except (OSError, subprocess.TimeoutExpired):
        write_native_contract_report(input_path, None, strict_enforced=True)
        return False

    report = parse_native_contract_reports(result.stderr)
    write_native_contract_report(input_path, report, strict_enforced=True)
    return bool(
        result.returncode == 0
        and report
        and report.get("is_fully_native", False)
    )

def finalize_ir(input_ll, output_prefix, timeout=None):
    """Produce the canonical post-delift IR and binary artifacts.

    ``*_brightened.ll`` is a pipeline intermediate. Downstream recovery and
    evaluation must consume this bundle output instead of silently granting
    final authority to the intermediate.
    """
    runner = os.path.join(
        SCRIPT_DIR,
        "brighten_100_delift_bundle",
        "run_brighten_delift_pipeline.sh",
    )
    log_path = f"{output_prefix}_delift_bundle.log"
    output_ll = f"{output_prefix}.ll"
    if not os.path.isfile(input_ll):
        return None, "missing_input", log_path
    if not os.path.isfile(runner):
        return None, "missing_runner", log_path
    try:
        result = subprocess.run(
            ["bash", runner, input_ll, output_prefix],
            capture_output=True,
            text=True,
            timeout=(
                timeout
                if timeout is not None
                else float(os.environ.get("BRIGHTEN_DELIFT_TIMEOUT", "180"))
            ),
        )
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write(result.stdout or "")
            handle.write(result.stderr or "")
    except subprocess.TimeoutExpired as exc:
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write(exc.stdout or "")
            handle.write(exc.stderr or "")
            handle.write("\nDelift bundle timed out.\n")
        return None, "timeout", log_path
    except OSError as exc:
        with open(log_path, "w", encoding="utf-8") as handle:
            handle.write(f"{exc}\n")
        return None, "execution_error", log_path
    if result.returncode != 0 or not os.path.isfile(output_ll):
        return None, f"failed:{result.returncode}", log_path
    # The bundle performs its final native reporter after every O3/095
    # mutation. Persist that last report beside the authoritative *_final.ll;
    # downstream tools must never reuse the earlier brightened-intermediate
    # report for a different module.
    native_report = parse_native_contract_reports(
        (result.stdout or "") + (result.stderr or "")
    )
    write_native_contract_report(
        output_ll, native_report, strict_enforced=False
    )
    return output_ll, "applied", log_path


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

def _elf_pt_loads(binary_path):
    """Return validated ELF64 PT_LOAD descriptors, or None (fail closed)."""
    if not binary_path or not os.path.isfile(binary_path):
        return None
    try:
        with open(binary_path, "rb") as f:
            hdr = f.read(64)
            if len(hdr) != 64 or hdr[:4] != b"\x7fELF" or hdr[4] != 2 or hdr[5] != 1:
                return None
            e_phoff, = struct.unpack_from("<Q", hdr, 32)
            e_phentsize, e_phnum = struct.unpack_from("<HH", hdr, 54)
            if e_phentsize != 56 or not e_phnum or e_phnum > 4096:
                return None
            f.seek(e_phoff)
            loads = []
            for _ in range(e_phnum):
                ph = f.read(56)
                if len(ph) != 56:
                    return None
                typ, flags = struct.unpack_from("<II", ph, 0)
                if typ != 1:
                    continue
                _, vaddr, _, filesz, memsz, align = struct.unpack_from("<QQQQQQ", ph, 8)
                if not memsz or filesz > memsz or not align or align & (align - 1):
                    return None
                end = vaddr + memsz
                if end > (1 << 64) - 1:
                    return None
                page = align if align >= 0x1000 else 0x1000
                mapped_begin = vaddr & -page
                mapped_end = (end + page - 1) & -page
                if mapped_end <= end or mapped_end > (1 << 64) - 1:
                    return None
                loads.append((vaddr, filesz, memsz, flags, page, mapped_begin, mapped_end))
            return loads or None
    except (OSError, struct.error):
        return None

def _inject_pt_load_metadata(input_path, binary_path):
    """Serialize proven loader mapping facts into a temporary bitcode module."""
    loads = _elf_pt_loads(binary_path)
    if not loads:
        return input_path, None
    llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
    llvm_as = shutil.which("llvm-as-21") or shutil.which("llvm-as")
    if not llvm_dis or not llvm_as:
        return input_path, None
    tmpdir = tempfile.mkdtemp(prefix="brighten-ptload-")
    ll = os.path.join(tmpdir, "input.ll")
    bc = os.path.join(tmpdir, "input.bc")
    try:
        if subprocess.run([llvm_dis, input_path, "-o", ll], capture_output=True).returncode:
            shutil.rmtree(tmpdir, ignore_errors=True); return input_path, None
        with open(ll, "a", encoding="utf-8") as f:
            ids = []
            # Numeric metadata definitions are required by llvm-as; reserve a
            # high temporary range which LLVM renumbers on serialization.
            for i, (vaddr, filesz, memsz, flags, page, mb, me) in enumerate(loads):
                ident = f"!{900000 + i}"
                ids.append(ident)
                f.write(f"\n{ident} = !{{i64 {vaddr}, i64 {filesz}, i64 {memsz}, i64 {flags}, i64 {page}, i64 {mb}, i64 {me}}}")
            f.write("\n!brighten.elf.pt_loads = !{" + ", ".join(ids) + "}\n")
        if subprocess.run([llvm_as, ll, "-o", bc], capture_output=True).returncode:
            shutil.rmtree(tmpdir, ignore_errors=True); return input_path, None
        return bc, tmpdir
    except OSError:
        shutil.rmtree(tmpdir, ignore_errors=True); return input_path, None


def _pt_load_guest_map_enabled():
    """Return the explicit experimental opt-in for PT_LOAD address mapping.

    The production path must not synthesize page-tail storage until 070 can
    rewrite every potentially-aliasing writable use transactionally.
    """
    return os.environ.get("BRIGHTEN_ENABLE_PT_LOAD_MAP", "0").lower() in {
        "1", "true", "yes", "on"
    }


def _maybe_inject_pt_load_metadata(input_path, binary_path):
    """Keep the PT_LOAD experiment out of the default production pipeline."""
    if not _pt_load_guest_map_enabled():
        return input_path, None
    return _inject_pt_load_metadata(input_path, binary_path)

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

    # PT_LOAD-backed GuestAddressMap recovery is still experimental.  It fixes
    # mapped page-tail accesses, but until recovered subobjects and the source
    # segment are rewritten as one transaction it can create two host objects
    # for the same writable guest bytes.  Keep production fail-closed: an
    # explicit opt-in is required while the cross-object alias invariant is
    # being completed and dataset differential gates are red.
    input_path, ptload_tmpdir = _maybe_inject_pt_load_metadata(
        input_path, binary_path
    )
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
    # This pipeline is an IR recovery pipeline, not a code-generation
    # benchmark. Vectorization and complete/partial loop unrolling obscure
    # recovered source loops without adding source-level information. Keep
    # both transformations opt-in; the scalar simplification passes still
    # canonicalize the loop body and induction variables.
    if os.environ.get("BRIGHTEN_ENABLE_VECTORIZATION", "0").lower() not in {
        "1", "true", "yes", "on"
    }:
        cmd.extend(["-vectorize-loops=false", "-vectorize-slp=false"])
    if os.environ.get("BRIGHTEN_ENABLE_LOOP_UNROLLING", "0").lower() not in {
        "1", "true", "yes", "on"
    }:
        cmd.append("-disable-loop-unrolling")

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
    # Pass 095 defaults to a report path derived from the LLVM module name.
    # When opt is launched from the repository root that default leaks
    # llvm-link.095.<hash>.json files into the root and collides across runs.
    # Keep the proof report beside the requested brightened output instead.
    report_path = os.environ.get(
        "BRIGHTEN_095_REPORT",
        f"{os.path.splitext(output_path)[0]}.095.json",
    )
    cmd.extend([f"-095-report={report_path}"])

    # ConstantExpr uniquing is only stable at an IR serialization boundary.
    # Split at the final 080 canonicalizer: it sees all tail mutations, and
    # its canonical fixed frame GEPs feed the final 040 pointer-slot consumer.
    # The final cleanup reporter remains after every mutation.
    late_anchor_pass = "brighten-address-canonicalize"
    pipeline_parts = pipeline.split(",")
    commands = []
    checkpoint_path = None
    if late_anchor_pass in pipeline_parts:
        split_at = late_address_canonicalize_index(pipeline_parts)
        if split_at == 0:
            print(f"{Color.RED}[✗] Late 080 pass không thể đứng đầu pipeline.{Color.END}")
            return False
        checkpoint_path = f"{output_path}.pre_address_canonicalize.bc"
        commands.append(
            cmd + [
                "-passes", ",".join(pipeline_parts[:split_at] + ["verify"]),
                input_path, "-o", checkpoint_path,
            ]
        )
        commands.append(
            cmd + [
                "-passes", ",".join(pipeline_parts[split_at:]),
                checkpoint_path, "-o", output_path,
            ]
        )
    else:
        commands.append(cmd + ["-passes", pipeline, input_path, "-o", output_path])
    print(f"{Color.BLUE}[*] Đang thực thi brightening với: {opt_bin}{Color.END}")
    for command in commands:
        print(f"{Color.GRAY}    Lệnh: {' '.join(command)}{Color.END}")

    try:
        env = os.environ.copy()
        env["REMILL_STACK_SSA_ALLOW_BOUNDARY"] = "1"
        opt_timeout = float(os.environ.get("BRIGHTEN_OPT_TIMEOUT", "180"))
        try:
            outputs = []
            res = None
            for command in commands:
                res = subprocess.run(command, capture_output=True, text=True,
                                     env=env, timeout=opt_timeout)
                outputs.extend([res.stdout or "", res.stderr or ""])
                if res.returncode != 0:
                    break
            dump_path = os.environ.get("BRIGHTEN_DUMP_OPT_LOG")
            if dump_path:
                with open(dump_path, "w", encoding="utf-8") as dump:
                    dump.write("".join(outputs))
        except subprocess.TimeoutExpired as exc:
            print(f"{Color.RED}[✗] opt timeout sau {opt_timeout:.1f}s; bỏ qua module để tránh treo batch.{Color.END}")
            if exc.stderr:
                print(f"{Color.RED}    Stderr trước timeout: {exc.stderr}{Color.END}")
            return False
        if res.returncode == 0:
            if checkpoint_path and os.environ.get("BRIGHTEN_SAVE_CHECKPOINTS", "0") != "1":
                try:
                    os.unlink(checkpoint_path)
                except FileNotFoundError:
                    pass
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
    finally:
        if ptload_tmpdir:
            shutil.rmtree(ptload_tmpdir, ignore_errors=True)

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
