#!/usr/bin/env python3
"""Export canonical metrics from an already completed evaluation campaign.

This script does not run lifting, LLVM passes, compilation, fuzzing, or LLM
recovery. It only reads existing ``flow_result.json`` files and regenerates the
CSV metric reports using the corrected metric definitions.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

# Importing this module installs the corrected tracker persistence and exporter.
from evaluation import run_experiment_metrics_fixed as fixed  # noqa: F401
from evaluation import run_experiment as base


def _campaign_timestamp(campaign_id: str) -> str:
    if campaign_id.startswith("eval_"):
        return campaign_id[len("eval_") :]
    return campaign_id


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export corrected metrics from existing flow_result.json files without calling the LLM."
    )
    parser.add_argument(
        "campaign_id",
        help="Existing result campaign directory, for example eval_20260728_124405",
    )
    parser.add_argument(
        "--result-root",
        default="result",
        help="Root directory containing the campaign (default: result)",
    )
    parser.add_argument(
        "--reports-root",
        default="reports",
        help="Root directory for generated reports (default: reports)",
    )
    parser.add_argument(
        "--output-experiment-id",
        default=None,
        help="Optional report directory name. Default: experiment_<campaign timestamp>",
    )
    args = parser.parse_args()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
    campaign_dir = os.path.join(project_root, args.result_root, args.campaign_id)

    if not os.path.isdir(campaign_dir):
        raise SystemExit(f"Campaign directory does not exist: {campaign_dir}")

    trackers = []
    result_files = sorted(Path(campaign_dir).glob("*/F*/flow_result.json"))

    for result_path in result_files:
        try:
            with result_path.open("r", encoding="utf-8") as handle:
                data = json.load(handle)
            trackers.append(base.CaseTracker.from_dict(data))
        except Exception as exc:
            print(f"[!] Skipping unreadable result {result_path}: {exc}", flush=True)

    if not trackers:
        raise SystemExit(
            f"No flow_result.json files were found under {campaign_dir}/<sample>/F*/"
        )

    timestamp = _campaign_timestamp(args.campaign_id)
    experiment_id = args.output_experiment_id or f"experiment_{timestamp}"
    reports_dir = os.path.join(project_root, args.reports_root, experiment_id)
    os.makedirs(reports_dir, exist_ok=True)

    base.export_metrics_csvs(trackers, reports_dir, experiment_id)

    samples = len({tracker.sample_id for tracker in trackers})
    print(
        f"[✓] Loaded {len(trackers)} flow results across {samples} samples.\n"
        f"[✓] Metrics exported to: {reports_dir}\n"
        "[✓] No LLM, lifting, compilation, or fuzzing stage was executed.",
        flush=True,
    )


if __name__ == "__main__":
    main()
