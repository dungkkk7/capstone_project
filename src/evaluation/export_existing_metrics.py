#!/usr/bin/env python3
"""Regenerate a complete schema-v2 report from an existing campaign.

This command is strictly offline with respect to recovery: it never calls the
LLM, compiler, lifting pipeline, deobfuscator, llvm2c, fuzzer, or repair loop.
LLVM verification is a read-only analysis of already-created IR artifacts.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from evaluation.artifact_loader import load_campaign
from evaluation.reporting import export_report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "campaign",
        help="Campaign id (eval_...) or an explicit campaign directory.",
    )
    parser.add_argument("--result-root", default="result")
    parser.add_argument("--reports-root", default="reports")
    parser.add_argument("--output-experiment-id", default=None)
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[2]
    campaign_arg = Path(args.campaign)
    campaign_dir = (
        campaign_arg
        if campaign_arg.is_absolute()
        else project_root / args.result_root / campaign_arg
    )
    campaign_dir = campaign_dir.resolve()
    if not campaign_dir.is_dir():
        raise SystemExit(f"Campaign directory does not exist: {campaign_dir}")
    timestamp = campaign_dir.name.removeprefix("eval_")
    experiment_id = args.output_experiment_id or f"experiment_{timestamp}"
    report_dir = (project_root / args.reports_root / experiment_id).resolve()

    data = load_campaign(project_root, campaign_dir, experiment_id)
    result = export_report(data, report_dir)
    print(
        f"[✓] Loaded {len(data['runs'])} runs across "
        f"{len({run['sample_id'] for run in data['runs']})} samples."
    )
    print(
        f"[✓] Validation: "
        f"{sum(item['severity'] == 'ERROR' for item in result['validation_errors'])} errors, "
        f"{sum(item['severity'] == 'WARNING' for item in result['validation_errors'])} warnings."
    )
    print(f"[✓] Report regenerated at {report_dir}")
    print("[✓] No LLM, compiler, fuzzing, or repair stage was executed.")


if __name__ == "__main__":
    main()
