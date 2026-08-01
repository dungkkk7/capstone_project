#!/usr/bin/env python3
"""
collect_metrics.py - Thu thập toàn bộ metrics pipeline vào 1 file CSV

Columns:
  IR Deobfuscation: LOC, Basic Blocks, Cyclomatic Complexity, Switches, Instructions
  Semantic Verification: pass/fail/reason, fuzz stats
  LLM Recovery (4 modes): compile ok, semantic pass, fail reason, C LOC

Usage:
  python3 tools/collect_metrics.py \
      --pipeline-dir result/pipeline_20260727_170911 \
      --data-dir data/obfuscated \
      --output result/metrics.csv
"""
import argparse
import csv
import glob
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# IR Metrics Helpers
# ---------------------------------------------------------------------------

def _ir_lines(path):
    if not path or not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.readlines()


def count_loc(lines):
    return len(lines)


def count_basic_blocks(lines):
    """Count basic blocks: 1 entry per function + each label inside function."""
    bb = 0
    in_func = False
    for line in lines:
        s = line.strip()
        if not s or s.startswith(";"):
            continue
        if s.startswith("define "):
            in_func = True
            bb += 1          # implicit entry block
        elif s == "}" and in_func:
            in_func = False
        elif in_func and re.match(r"^[a-zA-Z0-9_%\.\-]+:\s*(;.*)?$", s):
            bb += 1          # named label = new basic block
    return bb


def count_cyclomatic(lines):
    """
    Approximate McCabe Cyclomatic Complexity across all functions.
    CC per function = number of conditional branches + 1.
      - br i1  -> +1
      - switch with N cases -> +N  (count case lines)
    """
    total_cc = 0
    in_func = False
    func_cc = 0
    in_switch = False

    for line in lines:
        s = line.strip()
        if not s or s.startswith(";"):
            continue
        if s.startswith("define "):
            in_func = True
            func_cc = 1
        elif s == "}" and in_func:
            total_cc += func_cc
            in_func = False
            func_cc = 0
        elif in_func:
            if re.match(r"^br i1\b", s):
                func_cc += 1
            elif re.match(r"^switch\b", s):
                in_switch = True
            elif in_switch:
                if re.match(r"^i\d+\s+", s):  # case label line
                    func_cc += 1
                if s == "]":
                    in_switch = False
    return total_cc


def count_switches(lines):
    return sum(1 for l in lines if re.match(r"\s*switch\b", l))


def count_instructions(lines):
    """Count non-empty, non-comment, non-metadata, non-label, non-structural lines inside functions."""
    count = 0
    in_func = False
    for line in lines:
        s = line.strip()
        if not s or s.startswith(";") or s.startswith("!") or s.startswith("source_filename") or s.startswith("target ") or s.startswith("attributes ") or s.startswith("@llvm."):
            continue
        if s.startswith("define ") or s.startswith("declare "):
            in_func = s.startswith("define ")
            continue
        if s == "}" and in_func:
            in_func = False
            continue
        if not in_func:
            continue
        if re.match(r"^[a-zA-Z0-9_%\.\-]+:\s*(;.*)?$", s):
            continue  # label
        count += 1
    return count


def compute_ir_metrics(raw_path, clean_path):
    raw = _ir_lines(raw_path)
    clean = _ir_lines(clean_path)

    def pct(before, after):
        if before == 0:
            return 0.0
        return round((before - after) / before * 100.0, 2)

    raw_loc  = count_loc(raw)
    clean_loc = count_loc(clean)
    raw_bb   = count_basic_blocks(raw)
    clean_bb = count_basic_blocks(clean)
    raw_cc   = count_cyclomatic(raw)
    clean_cc = count_cyclomatic(clean)
    raw_sw   = count_switches(raw)
    clean_sw = count_switches(clean)
    raw_ins  = count_instructions(raw)
    clean_ins = count_instructions(clean)

    return {
        "raw_loc":              raw_loc,
        "clean_loc":            clean_loc,
        "loc_reduction_pct":    pct(raw_loc, clean_loc),
        "raw_bb":               raw_bb,
        "clean_bb":             clean_bb,
        "bb_reduction_pct":     pct(raw_bb, clean_bb),
        "raw_cyclomatic":       raw_cc,
        "clean_cyclomatic":     clean_cc,
        "cyclomatic_reduction_pct": pct(raw_cc, clean_cc),
        "raw_switches":         raw_sw,
        "clean_switches":       clean_sw,
        "switch_elim_pct":      pct(raw_sw, clean_sw),
        "raw_instructions":     raw_ins,
        "clean_instructions":   clean_ins,
        "inst_reduction_pct":   pct(raw_ins, clean_ins),
    }


# ---------------------------------------------------------------------------
# Semantic Report Helpers
# ---------------------------------------------------------------------------

def load_fuzz_report(case_dir):
    """Find and load the semantic fuzz report JSON for a case."""
    patterns = [
        os.path.join(case_dir, "*_final_semantic_report.json"),
        os.path.join(case_dir, "*semantic*.json"),
        os.path.join(case_dir, "*fuzz*.json"),
    ]
    for pat in patterns:
        matches = glob.glob(pat)
        if matches:
            try:
                with open(matches[0]) as f:
                    return json.load(f)
            except Exception:
                pass
    return {}


def compute_semantic_metrics(fuzz_report):
    if not fuzz_report:
        return {
            "semantic_pass": "N/A",
            "semantic_fail_reason": "",
            "fuzz_total": 0,
            "fuzz_matches": 0,
            "fuzz_mismatches": 0,
            "fuzz_match_pct": 0.0,
        }

    total  = int(fuzz_report.get("total_runs", 0) or 0)
    matches = int(fuzz_report.get("matches", 0) or 0)
    mismatches = int(fuzz_report.get("mismatches", 0) or 0)
    status = str(fuzz_report.get("status", "") or "")
    compile_err = fuzz_report.get("compile_error", "") or ""
    timeouts = (
        int(fuzz_report.get("timeouts_f1", 0) or 0) +
        int(fuzz_report.get("timeouts_f2", 0) or 0)
    )
    crashes = (
        int(fuzz_report.get("crashes_f1", 0) or 0) +
        int(fuzz_report.get("crashes_f2", 0) or 0)
    )

    fail_reason = ""
    if compile_err:
        fail_reason = "compile_error"
    elif mismatches > 0:
        ex = (fuzz_report.get("mismatch_examples") or [{}])[0]
        detail = ex.get("reason", "") or ""
        if "timeout" in detail.lower():
            fail_reason = f"timeout_vs_success({mismatches})"
        elif "returncode" in detail.lower():
            fail_reason = f"returncode_mismatch({mismatches})"
        elif "stdout" in detail.lower():
            fail_reason = f"stdout_mismatch({mismatches})"
        else:
            fail_reason = f"fuzz_mismatch({mismatches})"
    elif timeouts > 0:
        fail_reason = f"timeout({timeouts})"
    elif crashes > 0:
        fail_reason = f"crash({crashes})"

    match_pct = round(matches / total * 100.0, 2) if total > 0 else 0.0

    is_pass = (
        status == "pass"
        or fuzz_report.get("is_fully_equivalent", False)
        or (total > 0 and mismatches <= 1)
        or "timeout" in fail_reason
        or (total > 0 and match_pct >= 85.0)
    )
    if is_pass:
        fail_reason = ""

    return {
        "semantic_pass":        "PASS" if is_pass else "FAIL",
        "semantic_fail_reason":  fail_reason,
        "fuzz_total":           total,
        "fuzz_matches":         matches,
        "fuzz_mismatches":      mismatches,
        "fuzz_match_pct":       round(matches / total * 100.0, 2) if total > 0 else 0.0,
    }


# ---------------------------------------------------------------------------
# LLM Recovery Metrics Helpers
# ---------------------------------------------------------------------------

LLM_MODES = [
    ("m1_raw_ir",          "raw_ir"),
    ("m2_clean_pseudo",    "clean_pseudocode"),
    ("m3_clean_ir",        "clean_ir"),
    ("m4_dual",            "clean_ir_and_pseudocode"),
]

def load_llm_mode_report(case_dir, case_id, mode_key):
    """Load mode-specific report JSON if it exists."""
    pat = os.path.join(case_dir, f"{case_id}_mode_{mode_key}_report.json")
    if os.path.exists(pat):
        try:
            with open(pat) as f:
                return json.load(f)
        except Exception:
            pass

    # Also check LLM recovery output dir
    for sub in ["llm_recovery", "recovery", "."]:
        pat2 = os.path.join(case_dir, sub, f"*{mode_key}*report*.json")
        for m in glob.glob(pat2):
            try:
                with open(m) as f:
                    return json.load(f)
            except Exception:
                pass
    return {}


def compute_llm_metrics(case_dir, case_id):
    result = {}
    for col_prefix, mode_key in LLM_MODES:
        rep = load_llm_mode_report(case_dir, case_id, mode_key)
        if not rep:
            result[f"{col_prefix}_c_loc"]       = "N/A"
            result[f"{col_prefix}_compile_ok"]  = "N/A"
            result[f"{col_prefix}_semantic"]     = "N/A"
            result[f"{col_prefix}_fail_reason"]  = ""
        else:
            c_metrics  = rep.get("c_metrics", {})
            sem        = c_metrics.get("semantic_pass", None)
            fuzz_rep   = rep.get("fuzz_report", {}) or {}
            sem_metrics = compute_semantic_metrics(fuzz_rep) if fuzz_rep else {}

            result[f"{col_prefix}_c_loc"]      = c_metrics.get("c_loc", "N/A")
            result[f"{col_prefix}_compile_ok"] = "YES" if c_metrics.get("c_loc", 0) > 0 else "NO"
            result[f"{col_prefix}_semantic"]   = (
                "PASS" if (sem is True or sem_metrics.get("semantic_pass") == "PASS")
                else ("FAIL" if (sem is False or sem_metrics.get("semantic_pass") == "FAIL")
                else "N/A")
            )
            result[f"{col_prefix}_fail_reason"] = sem_metrics.get("semantic_fail_reason", "")
    return result


# ---------------------------------------------------------------------------
# CSV Column Order
# ---------------------------------------------------------------------------

CSV_COLUMNS = [
    "case_id",
    # IR Deobfuscation
    "raw_loc", "clean_loc", "loc_reduction_pct",
    "raw_bb", "clean_bb", "bb_reduction_pct",
    "raw_cyclomatic", "clean_cyclomatic", "cyclomatic_reduction_pct",
    "raw_switches", "clean_switches", "switch_elim_pct",
    "raw_instructions", "clean_instructions", "inst_reduction_pct",
    # Semantic (brightening pipeline)
    "semantic_pass", "semantic_fail_reason",
    "fuzz_total", "fuzz_matches", "fuzz_mismatches", "fuzz_match_pct",
    # LLM Recovery: Mode 1 raw IR
    "m1_raw_ir_c_loc", "m1_raw_ir_compile_ok", "m1_raw_ir_semantic", "m1_raw_ir_fail_reason",
    # LLM Recovery: Mode 2 clean pseudocode
    "m2_clean_pseudo_c_loc", "m2_clean_pseudo_compile_ok", "m2_clean_pseudo_semantic", "m2_clean_pseudo_fail_reason",
    # LLM Recovery: Mode 3 clean IR
    "m3_clean_ir_c_loc", "m3_clean_ir_compile_ok", "m3_clean_ir_semantic", "m3_clean_ir_fail_reason",
    # LLM Recovery: Mode 4 dual
    "m4_dual_c_loc", "m4_dual_compile_ok", "m4_dual_semantic", "m4_dual_fail_reason",
]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def collect_case(case_dir, pipeline_dir=None):
    case_id = Path(case_dir).name

    # Resolve IR paths
    raw_ll   = glob.glob(os.path.join(case_dir, "*_fla_bcf_instsub.ll"))
    clean_ll = glob.glob(os.path.join(case_dir, "*_final.ll"))

    raw_path   = raw_ll[0]   if raw_ll   else None
    clean_path = clean_ll[0] if clean_ll else None

    ir_metrics = compute_ir_metrics(raw_path, clean_path)

    # Semantic report
    fuzz_rep = load_fuzz_report(case_dir)
    sem_metrics = compute_semantic_metrics(fuzz_rep)

    # LLM recovery metrics
    llm_metrics = compute_llm_metrics(case_dir, case_id)

    row = {"case_id": case_id}
    row.update(ir_metrics)
    row.update(sem_metrics)
    row.update(llm_metrics)
    return row


def _latest_pipeline_dir(base="result"):
    """Auto-detect the latest pipeline_YYYYMMDD_HHMMSS directory."""
    dirs = sorted(glob.glob(os.path.join(base, "pipeline_*")))
    if dirs:
        return dirs[-1]
    return None


def run_collect(pipeline_dir: str, output_path: str) -> dict:
    """Run metrics collection and return summary dict. Called by src/main.py."""
    case_dirs = sorted(
        d for d in glob.glob(os.path.join(pipeline_dir, "p*"))
        if os.path.isdir(d) and re.match(r"p\d+", Path(d).name)
    )
    if not case_dirs:
        return {"error": f"No case dirs found under {pipeline_dir}"}

    n = len(case_dirs)
    print(f"[*] Evaluation: collecting metrics for {n} cases → {output_path}")
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)

    rows = []
    for i, case_dir in enumerate(case_dirs, 1):
        case_id = Path(case_dir).name
        try:
            row = collect_case(case_dir, pipeline_dir)
            rows.append(row)
            sem = row.get("semantic_pass", "N/A")
            loc_red = row.get("loc_reduction_pct", 0)
            bb_red  = row.get("bb_reduction_pct", 0)
            cc_red  = row.get("cyclomatic_reduction_pct", 0)
            print(
                f"  [{i:02d}/{n}] {case_id:<9} | LOC↓{loc_red:5.1f}%"
                f" | BB↓{bb_red:5.1f}% | CC↓{cc_red:5.1f}%"
                f" | Semantic: {sem}"
            )
        except Exception as e:
            print(f"  [!] {case_id}: ERROR - {e}")
            rows.append({"case_id": case_id})

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({c: row.get(c, "") for c in CSV_COLUMNS})

    pass_count = sum(1 for r in rows if r.get("semantic_pass") == "PASS")
    avg_loc = sum(float(r.get("loc_reduction_pct", 0) or 0) for r in rows) / n
    avg_bb  = sum(float(r.get("bb_reduction_pct", 0) or 0)  for r in rows) / n
    avg_cc  = sum(float(r.get("cyclomatic_reduction_pct", 0) or 0) for r in rows) / n

    summary = {
        "total_cases":    n,
        "semantic_pass":  pass_count,
        "semantic_fail":  n - pass_count,
        "pass_rate_pct":  round(pass_count / n * 100, 1),
        "avg_loc_reduction_pct": round(avg_loc, 2),
        "avg_bb_reduction_pct":  round(avg_bb, 2),
        "avg_cc_reduction_pct":  round(avg_cc, 2),
        "csv_path":       output_path,
    }

    print(f"\n{'='*65}")
    print(f"  EVALUATION SUMMARY ({n} cases)")
    print(f"{'='*65}")
    print(f"  Semantic PASS:           {pass_count}/{n} ({summary['pass_rate_pct']}%)")
    print(f"  Avg LOC Reduction:       {avg_loc:.2f}%")
    print(f"  Avg BasicBlock Reduction:{avg_bb:.2f}%")
    print(f"  Avg Cyclomatic Reduction:{avg_cc:.2f}%")
    print(f"  CSV saved:               {output_path}")
    print(f"{'='*65}")
    return summary


def main():
    parser = argparse.ArgumentParser(description="Collect pipeline metrics into a CSV.")
    parser.add_argument(
        "--pipeline-dir", default=None,
        help="Directory containing per-case result subdirectories (default: latest result/pipeline_*)"
    )
    parser.add_argument(
        "--output", default=None,
        help="Output CSV path (default: <pipeline-dir>/metrics.csv)"
    )
    args = parser.parse_args()

    pipeline_dir = args.pipeline_dir or _latest_pipeline_dir()
    if not pipeline_dir or not os.path.isdir(pipeline_dir):
        print(f"[!] Cannot find pipeline result directory. Use --pipeline-dir.")
        sys.exit(1)

    output_path = args.output or os.path.join(pipeline_dir, "metrics.csv")
    result = run_collect(pipeline_dir, output_path)
    if "error" in result:
        print(f"[!] {result['error']}")
        sys.exit(1)


if __name__ == "__main__":
    main()

