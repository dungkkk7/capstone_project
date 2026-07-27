#!/usr/bin/env python3
import os
import sys
import glob
import argparse
import statistics

def find_latest_pipeline_dir(result_base_dir="/home/dungbv/clau/result"):
    pattern = os.path.join(result_base_dir, "pipeline_*")
    dirs = [d for d in glob.glob(pattern) if os.path.isdir(d)]
    if not dirs:
        return None
    dirs.sort(key=lambda x: os.path.getmtime(x), reverse=True)
    return dirs[0]

def count_lines(filepath):
    if not filepath or not os.path.exists(filepath):
        return None
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            return sum(1 for _ in f)
    except Exception:
        return None

def analyze_pipeline(pipeline_dir):
    p_dirs = sorted([d for d in glob.glob(os.path.join(pipeline_dir, "p*")) if os.path.isdir(d)])
    
    results = []
    
    total_lifted = 0
    total_brightened = 0
    total_final = 0
    
    for d in p_dirs:
        case = os.path.basename(d)
        
        all_ll = glob.glob(os.path.join(d, "*.ll"))
        
        # Lifted IR: *.ll excluding _final and _brightened
        lifted_files = [f for f in all_ll if "_final" not in os.path.basename(f) and "_brightened" not in os.path.basename(f)]
        brightened_files = [f for f in all_ll if "_brightened.ll" in os.path.basename(f)]
        
        # Final IR: *_final.ll excluding step intermediate files like .01-verified-input.ll
        final_files = [f for f in all_ll if "_final.ll" in os.path.basename(f) and not any(f.endswith(ext) for ext in [
            ".01-verified-input.ll", ".02-pointer-opt.ll", ".03-storage-delift.ll", ".04-storage-o3.ll", ".05-unpinned.ll"
        ])]
        
        lifted_path = lifted_files[0] if lifted_files else None
        brightened_path = brightened_files[0] if brightened_files else None
        final_path = final_files[0] if final_files else None
        
        l_loc = count_lines(lifted_path)
        b_loc = count_lines(brightened_path)
        f_loc = count_lines(final_path)
        
        diff = (l_loc - f_loc) if (l_loc is not None and f_loc is not None) else None
        pct = ((diff / l_loc) * 100.0) if (diff is not None and l_loc and l_loc > 0) else None
        
        if l_loc: total_lifted += l_loc
        if b_loc: total_brightened += b_loc
        if f_loc: total_final += f_loc
        
        results.append({
            "case": case,
            "lifted_file": os.path.basename(lifted_path) if lifted_path else None,
            "lifted_loc": l_loc,
            "brightened_file": os.path.basename(brightened_path) if brightened_path else None,
            "brightened_loc": b_loc,
            "final_file": os.path.basename(final_path) if final_path else None,
            "final_loc": f_loc,
            "diff_loc": diff,
            "pct_reduction": pct
        })
        
    return p_dirs, results, total_lifted, total_brightened, total_final

def print_markdown_report(pipeline_dir, results, total_lifted, total_brightened, total_final):
    completed_cases = [r for r in results if r["final_loc"] is not None]
    final_locs = [r["final_loc"] for r in completed_cases]
    
    print(f"# Pipeline LOC Benchmark Report")
    print(f"**Directory**: `{pipeline_dir}`\n")
    
    print("## 📊 Summary Statistics\n")
    print(f"- **Total Cases**: {len(results)}")
    print(f"- **Completed Cases (with final.ll)**: {len(completed_cases)} / {len(results)}")
    print(f"- **Total Lifted LOC**: {total_lifted:,}")
    print(f"- **Total Brightened LOC**: {total_brightened:,}")
    print(f"- **Total Final LOC**: {total_final:,}")
    
    if total_lifted > 0:
        diff_tot = total_lifted - total_final
        pct_tot = (diff_tot / total_lifted) * 100.0
        print(f"- **Total LOC Reduction**: {diff_tot:,} lines ({pct_tot:.2f}%)")
        
    if final_locs:
        print(f"- **Min Final LOC**: {min(final_locs):,}")
        print(f"- **Max Final LOC**: {max(final_locs):,}")
        print(f"- **Mean Final LOC**: {statistics.mean(final_locs):,.2f}")
        print(f"- **Median Final LOC**: {statistics.median(final_locs):,.2f}")
        
        gt_10k = sum(1 for loc in final_locs if loc > 10000)
        gt_1k = sum(1 for loc in final_locs if loc > 1000)
        lt_1k = sum(1 for loc in final_locs if loc < 1000)
        print(f"- **Distribution (Final LOC)**:")
        print(f"  - > 10,000 LOC: {gt_10k} cases")
        print(f"  - > 1,000 LOC: {gt_1k} cases")
        print(f"  - < 1,000 LOC: {lt_1k} cases")
    
    print("\n## 📋 Detailed Case Breakdown\n")
    print("| Case | Lifted IR (.ll) | Brightened IR (.ll) | Final IR (.ll) | Diff (Lines) | % Reduction |")
    print("| :--- | :--- | :--- | :--- | :--- | :--- |")
    
    for r in results:
        c = r["case"]
        l_str = f"{r['lifted_loc']:,}" if r['lifted_loc'] is not None else "-"
        b_str = f"{r['brightened_loc']:,}" if r['brightened_loc'] is not None else "-"
        f_str = f"{r['final_loc']:,}" if r['final_loc'] is not None else "-"
        diff_str = f"{r['diff_loc']:,}" if r['diff_loc'] is not None else "-"
        pct_str = f"{r['pct_reduction']:.2f}%" if r['pct_reduction'] is not None else "-"
        
        print(f"| `{c}` | {l_str} | {b_str} | {f_str} | {diff_str} | {pct_str} |")
        
    diff_tot = total_lifted - total_final
    pct_tot = (diff_tot / total_lifted * 100.0) if total_lifted else 0.0
    print(f"| **TOTAL** | **{total_lifted:,}** | **{total_brightened:,}** | **{total_final:,}** | **{diff_tot:,}** | **{pct_tot:.2f}%** |")

def main():
    parser = argparse.ArgumentParser(description="Measure and report LOC statistics for decompilation/lifting pipeline results.")
    parser.add_argument("path", nargs="?", help="Path to pipeline result directory. Defaults to the latest directory in /home/dungbv/clau/result")
    parser.add_argument("-o", "--output", help="Optional output file path to save the markdown report.")
    
    args = parser.parse_args()
    
    target_dir = args.path
    if not target_dir:
        target_dir = find_latest_pipeline_dir()
        if not target_dir:
            print("Error: No pipeline result directory found.", file=sys.stderr)
            sys.exit(1)
        print(f"Using latest pipeline directory: {target_dir}\n", file=sys.stderr)
    elif not os.path.exists(target_dir):
        print(f"Error: Directory '{target_dir}' does not exist.", file=sys.stderr)
        sys.exit(1)
        
    p_dirs, results, total_lifted, total_brightened, total_final = analyze_pipeline(target_dir)
    
    if args.output:
        orig_stdout = sys.stdout
        with open(args.output, "w", encoding="utf-8") as f:
            sys.stdout = f
            print_markdown_report(target_dir, results, total_lifted, total_brightened, total_final)
        sys.stdout = orig_stdout
        print(f"Report successfully saved to '{args.output}'")
    else:
        print_markdown_report(target_dir, results, total_lifted, total_brightened, total_final)

if __name__ == "__main__":
    main()
