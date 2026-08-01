import os
import re
import json

def calculate_ir_metrics(raw_ir_path: str, clean_ir_path: str) -> dict:
    """Calculates deobfuscation metrics between Raw LLVM IR and Clean LLVM IR."""
    raw_loc = 0
    clean_loc = 0
    raw_switches = 0
    clean_switches = 0
    raw_instructions = 0
    clean_instructions = 0

    if os.path.exists(raw_ir_path):
        with open(raw_ir_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            raw_loc = len(lines)
            for l in lines:
                s = l.strip()
                if not s or s.startswith(";"):
                    continue
                raw_instructions += 1
                if s.startswith("switch "):
                    raw_switches += 1

    if os.path.exists(clean_ir_path):
        with open(clean_ir_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            clean_loc = len(lines)
            for l in lines:
                s = l.strip()
                if not s or s.startswith(";"):
                    continue
                clean_instructions += 1
                if s.startswith("switch "):
                    clean_switches += 1

    loc_reduction_pct = (
        ((raw_loc - clean_loc) / raw_loc * 100.0) if raw_loc > 0 else 0.0
    )
    inst_reduction_pct = (
        ((raw_instructions - clean_instructions) / raw_instructions * 100.0)
        if raw_instructions > 0
        else 0.0
    )
    switches_eliminated = max(0, raw_switches - clean_switches)
    cff_unflatten_pct = (
        (switches_eliminated / raw_switches * 100.0) if raw_switches > 0 else 100.0
    )

    return {
        "raw_ir_loc": raw_loc,
        "clean_ir_loc": clean_loc,
        "ir_loc_reduction_pct": round(loc_reduction_pct, 2),
        "raw_instructions": raw_instructions,
        "clean_instructions": clean_instructions,
        "inst_reduction_pct": round(inst_reduction_pct, 2),
        "raw_switches": raw_switches,
        "clean_switches": clean_switches,
        "cff_unflatten_pct": round(cff_unflatten_pct, 2),
    }

def calculate_c_metrics(c_source_path: str, fuzz_report_data: dict = None) -> dict:
    """Calculates output C metrics including LOC and differential fuzzing results."""
    c_loc = 0
    if os.path.exists(c_source_path):
        with open(c_source_path, "r", encoding="utf-8", errors="ignore") as f:
            c_loc = len(f.readlines())

    matches = 0
    total_runs = 0
    semantic_pass = False

    if fuzz_report_data:
        matches = fuzz_report_data.get("matches", 0) or 0
        total_runs = fuzz_report_data.get("total_runs", 0) or 0
        status = fuzz_report_data.get("status", "")
        semantic_pass = (total_runs > 0 and matches == total_runs) or (status == "pass")

    return {
        "c_loc": c_loc,
        "fuzz_total_runs": total_runs,
        "fuzz_matches": matches,
        "semantic_pass": semantic_pass,
    }
