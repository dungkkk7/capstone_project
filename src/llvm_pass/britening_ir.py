#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# One plugin per semantic responsibility.  015 no longer owns ABI recovery and
# 090 no longer owns State/stack/format/string repair.
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
    "deobfuscate_095_deobfus_ollvm/build/lib095.so",
]

# The production pipeline has two analysis waves.  Wave A removes lifting
# semantics in dependency order.  095 then proves opaque/MBA simplifications;
# wave B consumes the newly exposed CFG/data-flow facts.  No broad god-pass is
# allowed to silently repeat unrelated recovery responsibilities.
DEFAULT_PASS_PIPELINE = (
    "brighten-repair-pass,"
    "brighten-remill-runtime-pass,"
    "brighten-devirt-pass,"
    "always-inline,"
    "function(sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg),"
    "brighten-state-ssa-pass,"
    "brighten-address-canonicalize,"
    "brighten-stack-frame-pass,"
    "brighten-abi-recovery-pass,"
    "brighten-extern-call-bridge,"
    "brighten-global-data-recovery-pass,"
    "brighten-type-reconstruct,"
    "default<O2>,"
    "095,"
    "brighten-region-ssa-unflatten-pass,"
    "brighten-devirt-pass,"
    "brighten-local-state-ssa-pass,"
    "brighten-address-canonicalize,"
    "brighten-post-state-frame-pass,"
    "brighten-abi-recovery-pass,"
    "brighten-extern-call-bridge,"
    "brighten-global-data-recovery-pass,"
    "brighten-type-reconstruct,"
    "default<O2>,"
    "function(instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce,adce),"
    "globaldce,"
    "brighten-native-cleanup-pass,"
    "verify"
)

NATIVE_CONTRACT_REPORT_SUFFIX = "_native_contract_report.json"


class Color:
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    RED = "\033[91m"
    GRAY = "\033[90m"
    END = "\033[0m"


def _selected_optimization_level() -> str:
    level = os.environ.get("BRIGHTEN_OPT_LEVEL", "O2").strip().upper()
    if level not in {"O1", "O2", "O3"}:
        raise ValueError("BRIGHTEN_OPT_LEVEL must be O1, O2, or O3")
    return level


def pipeline_for_optimization_level(pipeline: str, level: str | None = None) -> str:
    selected = (level or _selected_optimization_level()).strip().upper()
    if selected not in {"O1", "O2", "O3"}:
        raise ValueError(f"unsupported optimization level: {selected}")
    return re.sub(r"default<O[123]>", f"default<{selected}>", pipeline)


def late_address_canonicalize_index(pipeline_parts: list[str]) -> int:
    return len(pipeline_parts) - 1 - pipeline_parts[::-1].index(
        "brighten-address-canonicalize"
    )


def native_contract_report_path(output_path: str) -> str:
    return f"{os.path.splitext(output_path)[0]}{NATIVE_CONTRACT_REPORT_SUFFIX}"


def parse_native_contract_reports(stderr: str):
    reports = []
    current = None
    metric_re = re.compile(r"^  ([^:]+): ([0-9]+)$")
    for line in (stderr or "").splitlines():
        if line == "brighten-native-cleanup report:":
            current = {"metrics": {}, "findings": []}
            reports.append(current)
            continue
        if current is None:
            continue
        if line.startswith("  native contract finding: "):
            current["findings"].append(
                line[len("  native contract finding: ") :]
            )
            continue
        match = metric_re.match(line)
        if match:
            key = match.group(1).strip().replace(" ", "_")
            current["metrics"][key] = int(match.group(2))
    if not reports:
        return None
    final = reports[-1]
    violations = final["metrics"].get("native_contract_violations")
    final["is_fully_native"] = violations == 0 if violations is not None else False
    final["status"] = "compliant" if final["is_fully_native"] else "non_compliant"
    final["output_class"] = "clean_ir" if final["is_fully_native"] else "residual_lifted_ir"
    final["report_count"] = len(reports)
    return final


def write_native_contract_report(output_path: str, report, strict_enforced=False):
    path = native_contract_report_path(output_path)
    payload = {
        "schema_version": 2,
        "output": os.path.abspath(output_path),
        "strict_enforced": bool(strict_enforced),
        **(
            report
            or {
                "status": "unavailable",
                "is_fully_native": False,
                "metrics": {},
                "findings": [],
                "report_count": 0,
                "output_class": "unknown",
            }
        ),
    }
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
    os.replace(tmp, path)
    return path


def read_native_contract_report(output_path: str):
    try:
        with open(native_contract_report_path(output_path), "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def _opt() -> str | None:
    return shutil.which("opt-21") or shutil.which("opt")


def _plugin_paths() -> list[str] | None:
    paths = [os.path.abspath(os.path.join(SCRIPT_DIR, p)) for p in PLUGINS]
    missing = [p for p in paths if not os.path.isfile(p)]
    if missing:
        print(f"{Color.RED}[x] Missing plugin(s):{Color.END}")
        for path in missing:
            print(f"  {path}")
        return None
    return paths


def verify_native_contract(input_path: str) -> bool:
    opt_bin = _opt()
    plugin = os.path.join(
        SCRIPT_DIR,
        "brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so",
    )
    if not opt_bin or not os.path.isfile(input_path) or not os.path.isfile(plugin):
        write_native_contract_report(input_path, None, strict_enforced=True)
        return False
    result = subprocess.run(
        [
            opt_bin,
            "-load-pass-plugin",
            plugin,
            "-brighten-native-strict",
            "-passes=brighten-native-cleanup-final-pass,verify",
            "-disable-output",
            input_path,
        ],
        capture_output=True,
        text=True,
        timeout=float(os.environ.get("BRIGHTEN_FINAL_VERIFY_TIMEOUT", "60")),
    )
    report = parse_native_contract_reports(result.stderr)
    write_native_contract_report(input_path, report, strict_enforced=True)
    return bool(result.returncode == 0 and report and report.get("is_fully_native"))


def finalize_ir(input_ll: str, output_prefix: str, timeout=None):
    runner = os.path.join(
        SCRIPT_DIR, "brighten_100_delift_bundle", "run_brighten_delift_pipeline.sh"
    )
    output_ll = f"{output_prefix}.ll"
    log_path = f"{output_prefix}_delift_bundle.log"
    if not os.path.isfile(input_ll):
        return None, "missing_input", log_path
    try:
        result = subprocess.run(
            ["bash", runner, input_ll, output_prefix],
            capture_output=True,
            text=True,
            timeout=timeout or float(os.environ.get("BRIGHTEN_DELIFT_TIMEOUT", "180")),
        )
    except subprocess.TimeoutExpired as exc:
        Path(log_path).write_text((exc.stdout or "") + (exc.stderr or "") + "\ntimeout\n")
        return None, "timeout", log_path
    except OSError as exc:
        Path(log_path).write_text(str(exc) + "\n")
        return None, "execution_error", log_path
    Path(log_path).write_text((result.stdout or "") + (result.stderr or ""))
    report = parse_native_contract_reports((result.stdout or "") + (result.stderr or ""))
    if os.path.isfile(output_ll):
        write_native_contract_report(output_ll, report, strict_enforced=True)
    if result.returncode != 0 or not os.path.isfile(output_ll):
        return None, f"failed:{result.returncode}", log_path
    if not report or not report.get("is_fully_native"):
        return None, "not_clean", log_path
    return output_ll, "applied", log_path


def clean_unused_types_and_globals(content: str) -> str:
    # Legacy compatibility API. Textual mutation is forbidden in v2.
    return content


def clean_ir_file(ll_path: str, binary_path=None) -> bool:
    del binary_path
    opt_bin = _opt()
    if not opt_bin or not os.path.isfile(ll_path):
        return False
    return subprocess.run(
        [opt_bin, "-passes=verify", "-disable-output", ll_path],
        capture_output=True,
    ).returncode == 0


def brighten_ir(input_path: str, output_path: str | None = None, binary_path=None) -> bool:
    del binary_path
    if not os.path.isfile(input_path):
        print(f"{Color.RED}[x] Input does not exist: {input_path}{Color.END}")
        return False
    opt_bin = _opt()
    plugins = _plugin_paths()
    if not opt_bin or plugins is None:
        return False
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_brightened{ext}"

    pipeline = os.environ.get(
        "BRIGHTEN_PASS_PIPELINE",
        pipeline_for_optimization_level(DEFAULT_PASS_PIPELINE),
    )
    for skipped in os.environ.get("BRIGHTEN_SKIP_PASSES", "").split(","):
        skipped = skipped.strip()
        if skipped:
            pipeline = ",".join(p for p in pipeline.split(",") if p != skipped)

    cmd = [opt_bin]
    for plugin in plugins:
        cmd += ["-load-pass-plugin", plugin]
    if os.environ.get("BRIGHTEN_KEEP_DEBUG_INFO", "0").lower() not in {
        "1",
        "true",
        "yes",
        "on",
    }:
        cmd.append("-strip-debug")
    if os.environ.get("BRIGHTEN_ENABLE_VECTORIZATION", "0").lower() not in {
        "1",
        "true",
        "yes",
        "on",
    }:
        cmd += ["-vectorize-loops=false", "-vectorize-slp=false"]
    if os.environ.get("BRIGHTEN_ENABLE_LOOP_UNROLLING", "0").lower() not in {
        "1",
        "true",
        "yes",
        "on",
    }:
        cmd.append("-disable-loop-unrolling")

    report_path = os.environ.get(
        "BRIGHTEN_095_REPORT", f"{os.path.splitext(output_path)[0]}.095.json"
    )
    cmd += [
        f"-095-report={report_path}",
        f"-095-z3-timeout-ms={os.environ.get('BRIGHTEN_095_Z3_TIMEOUT_MS', '50')}",
        f"-095-max-mba-candidates={os.environ.get('BRIGHTEN_095_MBA_CANDIDATES', '256')}",
        f"-095-max-mba-recipes-per-expression={os.environ.get('BRIGHTEN_095_MBA_RECIPES', '24')}",
    ]
    if os.environ.get("BRIGHTEN_NATIVE_STRICT", "0") == "1":
        cmd.append("-brighten-native-strict")
    cmd += ["-passes", pipeline, input_path, "-o", output_path]

    print(f"{Color.BLUE}[*] semantic brightening v2{Color.END}")
    print(f"{Color.GRAY}    {' '.join(cmd)}{Color.END}")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=float(os.environ.get("BRIGHTEN_OPT_TIMEOUT", "180")),
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"{Color.RED}[x] opt failed: {exc}{Color.END}")
        return False

    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        return False

    report = parse_native_contract_reports(result.stderr)
    write_native_contract_report(
        output_path,
        report,
        strict_enforced=os.environ.get("BRIGHTEN_NATIVE_STRICT", "0") == "1",
    )
    print(f"{Color.GREEN}[ok] brightened IR: {output_path}{Color.END}")
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Semantic McSema IR brightening v2")
    parser.add_argument("-i", "--input", required=True)
    parser.add_argument("-o", "--output")
    parser.add_argument("--opt-level", choices=("O1", "O2", "O3"))
    args = parser.parse_args()
    if args.opt_level:
        os.environ["BRIGHTEN_OPT_LEVEL"] = args.opt_level
    raise SystemExit(0 if brighten_ir(args.input, args.output) else 1)


if __name__ == "__main__":
    main()
