#!/usr/bin/env python3
"""
collect_metrics.py - Thu thập toàn bộ metrics của pipeline vào 1 file CSV
Chạy: python3 tools/collect_metrics.py [pipeline_result_dir]
Output: metrics_report.csv

Cột CSV:
  IR Deobfuscation : loc, basic_blocks, cyclomatic_complexity, switches, instructions
  Semantic Verify  : pass/fail, fail_reason, fuzz stats
  LLM Recovery     : compile_ok, semantic_pass per mode (nếu có)
"""

import os, sys, glob, json, csv, re, argparse
from pathlib import Path

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ─────────────────────────────────────────────────────────────────────────────
# IR METRICS
# ─────────────────────────────────────────────────────────────────────────────

def parse_ir_metrics(ll_path: str) -> dict:
    """
    Đọc file LLVM IR và tính:
    - loc                : tổng số dòng
    - instructions       : số dòng lệnh thực sự (bỏ comment, blank, metadata)
    - basic_blocks       : số basic block (mỗi label + entry mỗi define)
    - cyclomatic         : McCabe's cyclomatic complexity (br i1 + switch cases + 1/func)
    - switch_count       : số switch statement (proxy CFF)
    - function_count     : số hàm define
    """
    if not os.path.exists(ll_path):
        return {k: 0 for k in [
            "loc","instructions","basic_blocks","cyclomatic","switch_count","function_count"
        ]}

    with open(ll_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    loc = len(lines)
    instructions = 0
    basic_blocks = 0
    cyclomatic = 0
    switch_count = 0
    function_count = 0

    in_func = False
    func_cc = 0  # cyclomatic per function

    for line in lines:
        s = line.strip()

        # skip blank / comment / metadata / module-level
        if not s or s.startswith(";"):
            continue
        if s.startswith("source_filename") or s.startswith("target ") \
                or s.startswith("!") or s.startswith("@") \
                or s.startswith("attributes") or s.startswith("declare"):
            continue

        if s.startswith("define "):
            in_func = True
            function_count += 1
            basic_blocks += 1   # entry basic block
            func_cc = 1          # base cyclomatic = 1 per function
            continue

        if s == "}":
            if in_func:
                cyclomatic += func_cc
                func_cc = 0
            in_func = False
            continue

        if not in_func:
            continue

        # Label line = new basic block
        if re.match(r'^[a-zA-Z0-9_\.\-]+\s*:', s) and not s.startswith("%"):
            basic_blocks += 1
            continue

        # Count as instruction
        instructions += 1

        # Conditional branch = +1 edge (cyclomatic)
        if s.startswith("br i1"):
            func_cc += 1

        # Switch statement: count each 'case' target as +1
        if s.startswith("switch "):
            switch_count += 1
            # Count number of case targets (lines after switch until ']')
            # Approximate: switch adds at least 2 to cyclomatic
            func_cc += 2

    return {
        "loc": loc,
        "instructions": instructions,
        "basic_blocks": basic_blocks,
        "cyclomatic": cyclomatic,
        "switch_count": switch_count,
        "function_count": function_count,
    }


def ir_reduction(raw: dict, clean: dict) -> dict:
    """Tính % giảm giữa raw và clean IR cho từng metric."""
    def pct(r, c):
        return round((r - c) / r * 100, 2) if r > 0 else 0.0

    return {
        "loc_reduction_pct":          pct(raw["loc"],          clean["loc"]),
        "inst_reduction_pct":         pct(raw["instructions"], clean["instructions"]),
        "bb_reduction_pct":           pct(raw["basic_blocks"], clean["basic_blocks"]),
        "cyclomatic_reduction_pct":   pct(raw["cyclomatic"],   clean["cyclomatic"]),
        "switch_elimination_pct":     pct(raw["switch_count"], clean["switch_count"]),
    }


# ─────────────────────────────────────────────────────────────────────────────
# SEMANTIC REPORT
# ─────────────────────────────────────────────────────────────────────────────

def read_semantic_report(case_dir: str, case_id: str) -> dict:
    """Đọc file JSON semantic report nếu có."""
    blank = {
        "semantic_pass": "N/A", "semantic_fail_reason": "",
        "fuzz_total_runs": 0, "fuzz_matches": 0,
        "fuzz_mismatches": 0, "fuzz_match_pct": 0.0,
    }

    patterns = [
        f"{case_dir}/*_final_semantic_report.json",
        f"{case_dir}/*semantic*.json",
        f"{case_dir}/*fuzz*.json",
    ]
    report_file = None
    for pat in patterns:
        hits = glob.glob(pat)
        if hits:
            report_file = hits[0]
            break

    if not report_file:
        return blank

    try:
        data = json.load(open(report_file))
    except Exception:
        return blank

    total = int(data.get("total_runs") or 0)
    matches = int(data.get("matches") or 0)
    mismatches = int(data.get("mismatches") or 0)
    status = data.get("status") or ""

    if total > 0:
        sem_pass = "PASS" if matches == total else "FAIL"
        match_pct = round(matches / total * 100, 2)
    else:
        sem_pass = "PASS" if str(status).lower() == "pass" else ("FAIL" if status else "N/A")
        match_pct = 0.0

    # Fail reason
    fail_reason = ""
    if sem_pass == "FAIL":
        if int(data.get("timeouts_f2") or 0) > 0:
            fail_reason = "timeout"
        elif int(data.get("crashes_f2") or 0) > 0:
            fail_reason = "crash"
        elif mismatches > 0:
            fail_reason = "fuzz_mismatch"
        else:
            fail_reason = "unknown"

    return {
        "semantic_pass":       sem_pass,
        "semantic_fail_reason": fail_reason,
        "fuzz_total_runs":     total,
        "fuzz_matches":        matches,
        "fuzz_mismatches":     mismatches,
        "fuzz_match_pct":      match_pct,
    }


# ─────────────────────────────────────────────────────────────────────────────
# LLM RECOVERY METRICS (per mode)
# ─────────────────────────────────────────────────────────────────────────────

MODES = ["raw_ir", "clean_pseudocode", "clean_ir", "clean_ir_and_pseudocode"]

def read_llm_mode_report(case_dir: str, case_id: str, mode: str) -> dict:
    """Đọc kết quả LLM recovery cho 1 mode cụ thể."""
    blank = {
        f"mode_{mode}_compile_ok":    "N/A",
        f"mode_{mode}_semantic_pass": "N/A",
        f"mode_{mode}_iterations":    "N/A",
        f"mode_{mode}_c_loc":         "N/A",
    }
    report_file = os.path.join(case_dir, f"{case_id}_mode_{mode}_report.json")
    if not os.path.exists(report_file):
        return blank

    try:
        data = json.load(open(report_file))
    except Exception:
        return blank

    c_metrics = data.get("c_metrics", {})
    return {
        f"mode_{mode}_compile_ok":    str(c_metrics.get("compile_ok", "N/A")),
        f"mode_{mode}_semantic_pass": "PASS" if c_metrics.get("semantic_pass") else "FAIL",
        f"mode_{mode}_iterations":    str(data.get("llm_iterations_used", "N/A")),
        f"mode_{mode}_c_loc":         str(c_metrics.get("c_loc", "N/A")),
    }


# ─────────────────────────────────────────────────────────────────────────────
# MAIN COLLECTOR
# ─────────────────────────────────────────────────────────────────────────────

def collect(pipeline_dir: str, output_csv: str):
    case_dirs = sorted(glob.glob(os.path.join(pipeline_dir, "p*")))
    if not case_dirs:
        print(f"[!] Không tìm thấy case nào trong: {pipeline_dir}")
        sys.exit(1)

    rows = []
    for case_dir in case_dirs:
        case_id = Path(case_dir).name

        # --- Find IR files ---
        raw_ll_hits  = glob.glob(f"{case_dir}/*_fla_bcf_instsub.ll")
        final_ll_hits = glob.glob(f"{case_dir}/*_final.ll")

        raw_ll   = raw_ll_hits[0]   if raw_ll_hits   else ""
        final_ll = final_ll_hits[0] if final_ll_hits else ""

        # --- IR metrics ---
        raw_m   = parse_ir_metrics(raw_ll)
        clean_m = parse_ir_metrics(final_ll)
        reduct  = ir_reduction(raw_m, clean_m)

        # --- Semantic report ---
        sem = read_semantic_report(case_dir, case_id)

        # --- LLM mode reports ---
        llm_cols = {}
        for mode in MODES:
            llm_cols.update(read_llm_mode_report(case_dir, case_id, mode))

        # --- Assemble row ---
        row = {
            "case_id":                      case_id,
            # Raw IR
            "raw_loc":                      raw_m["loc"],
            "raw_instructions":             raw_m["instructions"],
            "raw_basic_blocks":             raw_m["basic_blocks"],
            "raw_cyclomatic":               raw_m["cyclomatic"],
            "raw_switch_count":             raw_m["switch_count"],
            "raw_function_count":           raw_m["function_count"],
            # Clean IR
            "clean_loc":                    clean_m["loc"],
            "clean_instructions":           clean_m["instructions"],
            "clean_basic_blocks":           clean_m["basic_blocks"],
            "clean_cyclomatic":             clean_m["cyclomatic"],
            "clean_switch_count":           clean_m["switch_count"],
            "clean_function_count":         clean_m["function_count"],
            # Reduction %
            "loc_reduction_pct":            reduct["loc_reduction_pct"],
            "inst_reduction_pct":           reduct["inst_reduction_pct"],
            "bb_reduction_pct":             reduct["bb_reduction_pct"],
            "cyclomatic_reduction_pct":     reduct["cyclomatic_reduction_pct"],
            "switch_elimination_pct":       reduct["switch_elimination_pct"],
            # Semantic
            **sem,
            # LLM recovery per mode
            **llm_cols,
        }
        rows.append(row)
        print(f"  [{case_id}] LOC {raw_m['loc']:>6} → {clean_m['loc']:>5} "
              f"(-{reduct['loc_reduction_pct']}%) | "
              f"BB {raw_m['basic_blocks']:>5} → {clean_m['basic_blocks']:>4} | "
              f"CC {raw_m['cyclomatic']:>5} → {clean_m['cyclomatic']:>4} | "
              f"SW {raw_m['switch_count']:>4} → {clean_m['switch_count']:>3} | "
              f"Semantic: {sem['semantic_pass']}")

    if not rows:
        return

    # Write CSV
    fieldnames = list(rows[0].keys())
    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    # Summary
    total = len(rows)
    sem_pass = sum(1 for r in rows if r["semantic_pass"] == "PASS")
    avg_loc_red = round(sum(r["loc_reduction_pct"] for r in rows) / total, 2)
    avg_bb_red  = round(sum(r["bb_reduction_pct"] for r in rows) / total, 2)
    avg_cc_red  = round(sum(r["cyclomatic_reduction_pct"] for r in rows) / total, 2)
    avg_sw_red  = round(sum(r["switch_elimination_pct"] for r in rows) / total, 2)

    print()
    print("=" * 70)
    print(f"  TỔNG: {total} cases  |  Semantic PASS: {sem_pass}/{total}")
    print(f"  Avg LOC reduction:        {avg_loc_red}%")
    print(f"  Avg Instruction reduction:{avg_bb_red}%")
    print(f"  Avg Basic Block reduction:{avg_bb_red}%")
    print(f"  Avg Cyclomatic reduction: {avg_cc_red}%")
    print(f"  Avg Switch elimination:   {avg_sw_red}%")
    print(f"  → CSV saved: {output_csv}")
    print("=" * 70)


def main():
    parser = argparse.ArgumentParser(description="Collect pipeline metrics into CSV")
    parser.add_argument(
        "pipeline_dir", nargs="?",
        default=os.path.join(PROJECT_ROOT, "result", "pipeline_20260727_170911"),
        help="Thư mục kết quả pipeline (default: result/pipeline_20260727_170911)"
    )
    parser.add_argument(
        "-o", "--output",
        default=os.path.join(PROJECT_ROOT, "result", "metrics_report.csv"),
        help="Đường dẫn output CSV (default: result/metrics_report.csv)"
    )
    args = parser.parse_args()

    print(f"[*] Thu thập metrics từ: {args.pipeline_dir}")
    print(f"[*] Output CSV: {args.output}")
    print()
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    collect(args.pipeline_dir, args.output)


if __name__ == "__main__":
    main()
