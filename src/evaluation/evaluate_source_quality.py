#!/usr/bin/env python3
"""Evaluate readability of accepted recovered C and regenerate the report."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from evaluation.artifact_loader import load_campaign
from evaluation.readability import DEFAULT_READABILITY_MODEL, evaluate_campaign
from evaluation.reporting import export_report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("campaign", help="Campaign id (eval_...) or directory")
    parser.add_argument("--model", default=DEFAULT_READABILITY_MODEL)
    parser.add_argument("--max-workers", type=int, default=8)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--result-root", default="result")
    parser.add_argument("--reports-root", default="reports")
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[2]
    campaign_arg = Path(args.campaign)
    if campaign_arg.is_absolute() or campaign_arg.is_dir():
        campaign_dir = campaign_arg
    else:
        campaign_dir = project_root / args.result_root / campaign_arg
    campaign_dir = campaign_dir.resolve()
    if not campaign_dir.is_dir():
        raise SystemExit(f"Campaign directory does not exist: {campaign_dir}")
    timestamp = campaign_dir.name.removeprefix("eval_")
    experiment_id = f"experiment_{timestamp}"

    summary = evaluate_campaign(
        project_root,
        campaign_dir,
        experiment_id,
        model=args.model.strip(),
        max_workers=args.max_workers,
        force=args.force,
    )
    report_dir = (project_root / args.reports_root / experiment_id).resolve()
    export_report(
        load_campaign(project_root, campaign_dir, experiment_id), report_dir
    )
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    print(f"[✓] Readability-aware report regenerated at {report_dir}")
    if summary["failures"]:
        raise SystemExit(
            f"Readability evaluation failed for {len(summary['failures'])} "
            "accepted source(s)."
        )


if __name__ == "__main__":
    main()
