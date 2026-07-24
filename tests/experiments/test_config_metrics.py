import copy
import csv
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from experiments.config import (  # noqa: E402
    ConfigError,
    DEFAULT_CONFIG,
    load_config,
    validate_config,
)
from experiments.p0_legacy import build_p0_recovery_config  # noqa: E402
from experiments.reporting import (  # noqa: E402
    AggregateIntegrityError,
    _method_summary,
    aggregate_run,
)


def validated_config():
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["llm"]["fake_response_path"] = "/tmp/fake.c"
    return config


def test_p0_must_remain_five_iterations():
    config = validated_config()
    config["p0"]["max_iterations"] = 1
    with pytest.raises(ConfigError, match="max_iterations=5"):
        validate_config(config)


def test_a0_cannot_enable_passes():
    config = validated_config()
    config["representation"]["a0"]["allow_passes"] = ["instcombine"]
    with pytest.raises(ConfigError, match="allow_passes"):
        validate_config(config)


def _result(run_id, sample_id, method, passed):
    return {
        "schema_version": "2.0",
        "run_id": run_id,
        "sample_id": sample_id,
        "method": method,
        "terminal_status": "PASS" if passed else "BUILD_FAILED",
        "final_stage": "finalized",
        "e2e_pass": passed,
        "identity": {"original_elf_sha256": "abc"},
        "representation": {"primary_sha256": "r", "byte_count": 1, "token_count": 1},
        "generation": {
            "model_call_count": 1 if method != "P0" else 5,
            "logical_generation_count": 1 if method != "P0" else 5,
            "iterations": 1 if method != "P0" else 5,
        },
        "build": {"ok": passed},
        "evaluation": {
            "union_input_count": 10,
            "smoke_runnable": True,
        } if passed else None,
        "integrity": {},
        "timing": {},
    }


def test_pairwise_metrics_use_enrolled_programs(tmp_path):
    outcomes = {
        "P0": [True, True, False, True],
        "B0": [False, True, False, True],
        "A0": [False, False, False, True],
    }
    for method, values in outcomes.items():
        for index, passed in enumerate(values):
            path = (
                tmp_path
                / "samples"
                / f"p{index:05d}"
                / method
                / "result.json"
            )
            path.parent.mkdir(parents=True)
            path.write_text(
                json.dumps(_result("test", f"p{index:05d}", method, passed))
            )
    config = validated_config()
    config["statistics"]["bootstrap_resamples"] = 200
    aggregate = aggregate_run(tmp_path, config)

    assert aggregate["method_summary"]["P0"]["e2e_rate"] == 0.75
    assert aggregate["method_summary"]["B0"]["e2e_rate"] == 0.50
    assert aggregate["method_summary"]["A0"]["e2e_rate"] == 0.25
    stats = {item["comparison"]: item for item in aggregate["statistics"]}
    assert stats["P0-current_vs_B0-one-shot"][
        "risk_difference_percentage_points"
    ] == 25.0
    assert stats["P0-current_vs_A0-one-shot"][
        "risk_difference_percentage_points"
    ] == 50.0

    aggregate_dir = tmp_path / "aggregate"
    metrics = json.loads((aggregate_dir / "metrics.json").read_text())
    assert metrics["primary_endpoint"]["name"] == "e2e_rate"
    assert metrics["execution_context"]["fake_llm"] is True
    assert (
        metrics["execution_context"]["evidence_eligibility"]
        == "pipeline_validation_only"
    )
    assert metrics["methods"]["P0"]["e2e_rate_wilson_ci"]
    assert metrics["methods"]["P0"]["estimated_total_cost_usd"] is None
    assert metrics["pricing"]["plan"] == "standard_paygo_global"
    with (aggregate_dir / "metrics_long.csv").open(newline="") as handle:
        metric_rows = list(csv.DictReader(handle))
    assert any(
        row["method"] == "P0"
        and row["metric"] == "e2e_rate"
        and row["statistic"] == "point"
        and float(row["value"]) == 0.75
        and row["denominator"] == "4"
        for row in metric_rows
    )

    figure_manifest = json.loads(
        (aggregate_dir / "figures_manifest.json").read_text()
    )
    assert figure_manifest["figure_count"] == 4
    assert figure_manifest["execution_context"]["fake_llm"] is True
    for figure in figure_manifest["figures"]:
        ET.parse(aggregate_dir / "figures" / figure["path"])
    dashboard = (aggregate_dir / "dashboard.html").read_text()
    assert "Binary reconstruction experiment results" in dashboard
    assert "FAKE-LLM · PIPELINE VALIDATION ONLY" in dashboard
    assert "Not a research result." in dashboard
    assert "75.0%" in dashboard
    assert "audit/events.jsonl" in dashboard
    report = (aggregate_dir / "report.md").read_text()
    assert "NOT A RESEARCH RESULT" in report


def test_aggregate_refuses_nonterminal_quota_result(tmp_path):
    config = validated_config()
    for method in ("P0", "A0", "B0"):
        payload = _result("test", "p00001", method, False)
        if method == "B0":
            payload["terminal_status"] = "WAITING_FOR_QUOTA"
            payload["final_stage"] = "generation"
        path = tmp_path / "samples" / "p00001" / method / "result.json"
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(payload))

    with pytest.raises(AggregateIntegrityError, match="nonterminal variant"):
        aggregate_run(tmp_path, config)
    assert not (tmp_path / "aggregate").exists()


def test_aggregate_refuses_entire_missing_enrolled_sample(tmp_path):
    config = validated_config()
    for method in ("P0", "A0", "B0"):
        path = tmp_path / "samples" / "p00001" / method / "result.json"
        path.parent.mkdir(parents=True)
        path.write_text(
            json.dumps(_result("test", "p00001", method, False))
        )
    (tmp_path / "experiment_manifest.json").write_text(
        json.dumps(
            {
                "methods": ["P0", "A0", "B0"],
                "sample_ids": ["p00001", "p00002"],
            }
        )
    )

    with pytest.raises(
        AggregateIntegrityError, match="enrolled sample set mismatch"
    ):
        aggregate_run(tmp_path, config)


def test_candidate_count_must_remain_one():
    config = validated_config()
    config["llm"]["candidate_count"] = 2
    with pytest.raises(ConfigError, match="candidate_count"):
        validate_config(config)


def test_real_run_requires_explicit_context_window():
    config = validated_config()
    config["llm"]["fake_response_path"] = None
    config["llm"]["context_window_tokens"] = 0
    with pytest.raises(ConfigError, match="explicitly set"):
        validate_config(config)


def test_real_run_requires_model_spec_provenance():
    config = validated_config()
    config["llm"]["fake_response_path"] = None
    config["llm"]["model_spec_source"] = ""
    with pytest.raises(ConfigError, match="official HTTPS source"):
        validate_config(config)


def test_pricing_requires_official_provenance():
    config = validated_config()
    config["llm"]["pricing_source"] = ""
    with pytest.raises(ConfigError, match="pricing_source"):
        validate_config(config)


def test_cost_includes_response_and_reasoning_tokens():
    config = validated_config()
    config["llm"]["fake_response_path"] = None
    result = _result("test", "p00001", "P0", True)
    result["generation"].update(
        {
            "input_tokens": 100,
            "output_tokens": 20,
            "thinking_tokens": 30,
            "billable_output_tokens": 50,
        }
    )

    summary = _method_summary([result], config)["P0"]

    assert summary["total_output_tokens"] == 20
    assert summary["total_thinking_tokens"] == 30
    assert summary["total_billable_output_tokens"] == 50
    assert summary["estimated_total_cost_usd"] == pytest.approx(
        (100 * 1.25 + 50 * 10.00) / 1_000_000
    )


def test_cost_uses_long_context_price_tier():
    config = validated_config()
    config["llm"]["fake_response_path"] = None
    result = _result("test", "p00001", "P0", True)
    result["generation"].update(
        {
            "input_tokens": 200001,
            "output_tokens": 20,
            "thinking_tokens": 30,
            "billable_output_tokens": 50,
        }
    )

    summary = _method_summary([result], config)["P0"]

    assert summary["estimated_total_cost_usd"] == pytest.approx(
        (200001 * 2.50 + 50 * 15.00) / 1_000_000
    )


def test_p0_model_freeze_ignores_ambient_sampling_environment(monkeypatch):
    monkeypatch.setenv("LLM_RECOVERY_MODEL", "different-model")
    monkeypatch.setenv("LLM_RECOVERY_TEMPERATURE", "1.5")
    monkeypatch.setenv("LLM_RECOVERY_TOP_P", "0.2")
    config = validated_config()
    config["llm"].update(
        {
            "model_id": "frozen-model",
            "location": "global",
            "temperature": 0.0,
            "top_p": 1.0,
            "candidate_count": 1,
        }
    )

    frozen = build_p0_recovery_config(config)

    assert frozen.model == "frozen-model"
    assert frozen.temperature == 0.0
    assert frozen.top_p == 1.0
    assert frozen.candidate_count == 1
    assert frozen.max_iterations == 5
    assert frozen.pseudo_backend == "ghidra"
    assert frozen.use_file_api is True


def test_unknown_config_key_is_rejected(tmp_path):
    config_path = tmp_path / "bad.yaml"
    config_path.write_text(
        "llm:\n  temprature: 0.0\n",
        encoding="utf-8",
    )
    with pytest.raises(ConfigError, match="llm.temprature"):
        load_config(config_path, PROJECT_ROOT)
