#!/usr/bin/env python3
"""Create a new experiment run by reusing frozen preparation artifacts."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from experiments.config import load_config, validate_config, config_fingerprint
from experiments.identity import read_dataset
from experiments.runner import ExperimentRunner
from experiments.storage import atomic_write_json, load_json
from experiments.enums import Stage


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset")
    parser.add_argument("--config", required=True)
    parser.add_argument("--from-run", required=True)
    parser.add_argument("--to-run", required=True)
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    config = load_config(args.config, project_root)
    config["_config_sha256"] = config_fingerprint(config)
    validate_config(config)
    source_root = Path(config["paths"]["result_root"]) / args.from_run
    target_root = Path(config["paths"]["result_root"]) / args.to_run
    if not (source_root / "experiment_manifest.json").is_file():
        raise SystemExit(f"Missing source run: {source_root}")
    if target_root.exists():
        raise SystemExit(f"Target run already exists: {target_root}")

    source_manifest = load_json(source_root / "experiment_manifest.json")
    source_methods = source_manifest.get("methods") or []
    target_methods = [str(method) for method in config["experiment"]["methods"]]
    if source_methods != target_methods:
        raise SystemExit(
            f"Method set mismatch: source={source_methods}, target={target_methods}"
        )

    runner = ExperimentRunner(args.dataset, config, args.to_run)
    runner.initialize()
    samples = read_dataset(args.dataset, project_root)
    for sample in samples:
        source_sample = source_root / "samples" / sample.sample_id
        target_sample = target_root / "samples" / sample.sample_id
        for name in ("identity.json", "preparation_manifest.json"):
            shutil.copy2(source_sample / name, target_sample / name)
        shutil.copytree(
            source_sample / "common",
            target_sample / "common",
            dirs_exist_ok=True,
        )
        for method in target_methods:
            source_method = source_sample / method
            target_method = target_sample / method
            shutil.copytree(
                source_method / "representation",
                target_method / "representation",
                dirs_exist_ok=True,
            )
            source_result = load_json(source_method / "result.json")
            target_result = load_json(target_method / "result.json")
            target_result["representation"] = source_result.get("representation")
            target_result["final_stage"] = Stage.GENERATION.value
            target_result["terminal_status"] = "CANCELLED"
            target_result["failure_code"] = None
            target_result["failure_message"] = None
            target_result["generation"] = None
            target_result["build"] = None
            target_result["evaluation"] = None
            target_result["e2e_pass"] = False
            target_result["provenance"] = {
                "prepared_from_run": args.from_run,
                "preparation_reused": True,
                "llm_model_changed": True,
            }
            atomic_write_json(target_method / "result.json", target_result)

    print(f"Cloned preparation: {args.from_run} -> {args.to_run}")
    print(f"Target: {target_root}")
    print("Next: run the process phase with the target config and run ID.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
