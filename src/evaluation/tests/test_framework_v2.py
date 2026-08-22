from __future__ import annotations

import json
from pathlib import Path

import pytest

from evaluation.aggregate import aggregate_flows
from evaluation.artifact_loader import _artifact_flow_spec
from evaluation.behavior import behavior_matches, classify_divergence
from evaluation.metrics import (
    canonical_e2e_rate,
    compilation_repair_success_rate,
    counterexample_detection_rate,
    final_rsr,
    first_pass_rsr,
    flow_specific_recovery_rate,
    gain,
    inconclusive_rate,
    input_match_rate,
    program_behavioral_pass_rate,
    rate,
    reduction,
    reproducibility_rate,
    semantic_repair_success_rate,
    valid_input_rate,
)
from evaluation.reporting import export_report
from evaluation.schema import (
    BehaviorObservation,
    FLOW_LAYOUT_VERSION,
    FLOW_ORDER,
    FLOW_SPECS,
    LEGACY_FLOW_SPECS,
    LEGACY_TO_CURRENT_FLOW_ID,
    flow_contract,
)
from evaluation.statistical_analysis import paired_analysis
from evaluation.validation import validate_run, validate_runs
from fuzzing_equi_check.fuzzing import check_equivalence


def observation(
    *,
    stdout: bytes = b"",
    stderr: bytes = b"",
    code: int | None = 0,
    signal: int | None = None,
    timeout: bool = False,
) -> BehaviorObservation:
    return BehaviorObservation(stdout, stderr, code, signal, timeout)


def test_exact_behavior_tuple_and_divergence_types():
    base = observation(stdout=b"ok\n", stderr=b"warn", code=0)
    assert behavior_matches(base, base)
    assert classify_divergence(base, base) is None
    assert classify_divergence(base, observation(stdout=b"bad\n", stderr=b"warn")) == "OUTPUT_MISMATCH"
    assert classify_divergence(base, observation(stdout=b"ok\n", stderr=b"bad")) == "STDERR_MISMATCH"
    assert classify_divergence(base, observation(stdout=b"ok\n", stderr=b"warn", code=2)) == "EXIT_STATUS_MISMATCH"
    assert classify_divergence(
        observation(code=-11, signal=11), observation(code=-6, signal=6)
    ) == "SIGNAL_MISMATCH"
    assert classify_divergence(
        base, observation(stdout=b"ok\n", stderr=b"warn", code=None, timeout=True)
    ) == "TIMEOUT_MISMATCH"
    assert classify_divergence(
        observation(code=-11, signal=11), observation(code=0)
    ) == "CRASH_MISMATCH"
    assert classify_divergence(base, observation(stdout=b"x", stderr=b"y", code=2)) == "MIXED_DIVERGENCE"


def test_strict_runtime_oracle_compares_full_tuple_without_sample_exceptions():
    left = {
        "status": "success",
        "returncode": 0,
        "signal": None,
        "stdout": b"same",
        "stderr": b"left",
    }
    right = {**left, "stderr": b"right"}
    matched, reason = check_equivalence(
        left,
        right,
        compare_stderr=True,
        case_id="p00793",  # legacy policy skipped this sample entirely
        strict_oracle=True,
    )
    assert not matched
    assert reason == "Stderr stream mismatch"


def test_canonical_metric_formulas_and_na_behavior():
    assert first_pass_rsr(8, 10) == 80.0
    assert final_rsr(9, 10) == 90.0
    assert gain(90.0, 80.0) == 10.0
    assert compilation_repair_success_rate(1, 2) == 50.0
    assert program_behavioral_pass_rate(7, 8) == 87.5
    assert input_match_rate(95, 100) == 95.0
    assert counterexample_detection_rate(2, 8) == 25.0
    assert reproducibility_rate(8, 10) == 80.0
    assert semantic_repair_success_rate(3, 4) == 75.0
    assert canonical_e2e_rate(6, 10) == 60.0
    assert flow_specific_recovery_rate(7, 10) == 70.0
    assert valid_input_rate(90, 100) == 90.0
    assert inconclusive_rate(1, 10) == 10.0
    assert reduction(100, 60) == 40.0
    assert rate(0, 0) is None
    assert gain(None, 2.0) is None
    assert reduction(0, 0) is None


def test_five_flow_layout_and_legacy_contract_detection(tmp_path: Path):
    expected = {
        "B1": ("GHIDRA_PSEUDOCODE_ONESHOT", False, False, True, False),
        "B2": ("OBJDUMP_ASSEMBLY_ONESHOT", False, False, False, False),
        "F1": ("CLEAN_IR_ITERATIVE", False, True, False, True),
        "F2": ("RAW_IR_ITERATIVE", True, False, False, True),
        "F3": ("CLEAN_IR_ONESHOT", False, True, False, False),
    }
    assert tuple(FLOW_SPECS) == FLOW_ORDER == ("B1", "B2", "F1", "F2", "F3")
    assert LEGACY_TO_CURRENT_FLOW_ID == {
        "F2": "F1",
        "F5": "F2",
        "F4": "F3",
        "F1": "F4",
        "F3": "F5",
    }
    assert {
        flow_id: (
            spec.name,
            spec.requires_raw_ir,
            spec.requires_clean_ir,
            spec.requires_pseudocode,
            spec.iterative,
        )
        for flow_id, spec in FLOW_SPECS.items()
    } == expected
    assert FLOW_SPECS["B1"].requires_pseudocode
    assert not FLOW_SPECS["B1"].iterative
    assert FLOW_SPECS["B2"].requires_assembly
    assert not FLOW_SPECS["B2"].iterative

    legacy_dir = tmp_path / "legacy" / "F5"
    legacy_dir.mkdir(parents=True)
    assert _artifact_flow_spec(legacy_dir, "F5") == LEGACY_FLOW_SPECS["F5"]

    current_dir = tmp_path / "current" / "F2"
    current_dir.mkdir(parents=True)
    (current_dir / "flow_contract.json").write_text(
        json.dumps(flow_contract(FLOW_SPECS["F2"])),
        encoding="utf-8",
    )
    assert _artifact_flow_spec(current_dir, "F2") == FLOW_SPECS["F2"]

    b2_dir = tmp_path / "current" / "B2"
    b2_dir.mkdir(parents=True)
    (b2_dir / "flow_contract.json").write_text(
        json.dumps(flow_contract(FLOW_SPECS["B2"])),
        encoding="utf-8",
    )
    assert _artifact_flow_spec(b2_dir, "B2") == FLOW_SPECS["B2"]


def make_run(sample: str, flow: str, **overrides):
    base = {
        "experiment_id": "experiment_fixture",
        "run_id": f"{sample}-{flow}",
        "sample_id": sample,
        "flow_id": flow,
        "flow_name": FLOW_SPECS[flow].name,
        "flow_layout_version": FLOW_LAYOUT_VERSION,
        "error_context_enabled": FLOW_SPECS[flow].iterative,
        "iterative": FLOW_SPECS[flow].iterative,
        "repeat_id": 0,
        "benchmark_name": sample,
        "status": "PASS",
        "llm_calls": 1,
        "compiler_attempts": 1,
        "compile_success_first": True,
        "any_compile_success_within_budget": True,
        "last_candidate_compile_success": True,
        "compile_repair_case": False,
        "compile_repair_rounds": 0,
        "compile_repair_success": None,
        "behavioral_repair_case": False,
        "behavioral_repair_rounds": 0,
        "behavioral_repair_success": None,
        "compiler_repair_applied": False,
        "behavioral_repair_applied": False,
        "first_behavioral_pass": True,
        "final_behavioral_pass": True,
        "counterexample_ever_found": False,
        "reproducible_counterexample_ever_found": False,
        "final_counterexample_found": False,
        "reproducible_final_counterexample": False,
        "fuzzing_completed": True,
        "behavioral_validation_completed": True,
        "fuzz_generated": 10,
        "fuzz_executed_on_both": 10,
        "fuzz_valid": 10,
        "fuzz_invalid": 0,
        "fuzz_matches": 10,
        "fuzz_mismatches": 0,
        "fuzz_execution_errors": 0,
        "input_match_rate": 100.0,
        "binary_lifting_completed": True,
        "raw_ir_generated": True,
        "llvm_deobfuscation_completed": True,
        "llvm_ir_verification_completed": True,
        "pseudocode_generated": True,
        "llm_generation_completed": True,
        "compilation_completed": True,
        "candidate_accepted": True,
        "re_executability_success": True,
        "canonical_e2e_success": True,
        "flow_specific_recovery_success": True,
        "input_tokens": 10,
        "output_tokens": 5,
        "total_tokens": 15,
        "estimated_api_cost": None,
        "llm_latency": 1.0,
        "preprocessing_time": None,
        "compile_time": 0.1,
        "fuzzing_time": 1.0,
        "total_runtime": 2.0,
        "time_to_first_candidate": None,
        "time_to_first_compilable_candidate": None,
        "time_to_first_behavioral_pass_candidate": None,
        "counterexamples_used": 0,
        "regression_corpus_size": None,
        "peak_memory": None,
        "cpu_time": None,
        "readability_variables": None,
        "readability_loops": None,
        "readability_conditions": None,
        "readability_logic_flow": None,
        "readability_structure": None,
        "readability_overall": None,
        "readability_correctness_assessed": None,
        "evaluator_id": None,
        "evaluation_method": None,
        "original_sloc": None,
        "recovered_sloc": None,
        "sloc_ratio": None,
        "provenance_warnings": [],
        "inconclusive_reason": None,
    }
    base.update(overrides)
    return base


def test_one_shot_f2_na_and_validation_behavior():
    valid = make_run("p1", "B1")
    assert not [item for item in validate_run(valid) if item["severity"] == "ERROR"]
    invalid = make_run("p2", "B1", llm_calls=2)
    errors = validate_run(invalid)
    assert any(
        item["violated_rule"] == "RULE_1_ONESHOT_CONTRACT"
        for item in errors
    )
    rows = aggregate_flows([valid, invalid], errors, [])
    f2 = next(row for row in rows if row["flow_id"] == "B1")
    assert f2["eligible_sample_count"] == 1
    assert f2["compilation_repair_gain_pp"] is None
    assert f2["semantic_repair_success_rate_percent"] is None
    assert f2["behavioral_repair_gain_pp"] is None


def test_paired_alignment_and_exclusion_reason():
    runs = [
        make_run("p1", "F1"),
        make_run("p1", "F2"),
        make_run("p2", "F1"),
        make_run("p2", "F2", final_counterexample_found=True),
    ]
    errors = validate_runs(runs)
    comparisons, tests = paired_analysis(runs, errors)
    row = next(
        item
        for item in comparisons
        if item["contrast_id"] == "F1_VS_F2_CLEAN_IR_VS_RAW_IR"
        and item["metric_name"] == "Canonical E2E Rate"
    )
    assert row["paired_sample_count"] == 1
    assert row["excluded_sample_count"] == 1
    assert "DATA_VALIDATION_ERROR" in row["exclusion_reasons"]
    assert any(item["test_name"] == "McNemar exact test" for item in tests)


def test_middle_candidate_compile_success_is_monotonic():
    run = make_run(
        "p1",
        "F1",
        compile_success_first=False,
        any_compile_success_within_budget=True,
        last_candidate_compile_success=False,
        compile_repair_case=True,
        compile_repair_rounds=2,
        compile_repair_success=True,
    )
    rows = aggregate_flows([run], [], [])
    f1 = next(row for row in rows if row["flow_id"] == "F1")
    assert f1["first_pass_rsr_percent"] == 0.0
    assert f1["final_rsr_percent"] == 100.0
    assert f1["compilation_repair_gain_pp"] == 100.0
    assert f1["compilation_repair_success_rate_percent"] == 100.0


def test_reexecutability_does_not_require_semantic_pass():
    run = make_run(
        "p1",
        "F3",
        status="FAIL_BEHAVIORAL",
        canonical_e2e_success=False,
        re_executability_success=True,
        final_behavioral_pass=False,
        fuzz_mismatches=1,
    )
    row = next(item for item in aggregate_flows([run], [], []) if item["flow_id"] == "F3")
    assert row["re_executability_success_count"] == 1
    assert row["re_executability_rate_percent"] == 100.0
    assert row["canonical_e2e_success_count"] == 0


def test_data_validation_rules():
    invalid = make_run(
        "p1",
        "F1",
        status="PASS",
        any_compile_success_within_budget=False,
        fuzz_matches=11,
        fuzz_valid=10,
        fuzz_executed_on_both=9,
        fuzz_generated=8,
        final_counterexample_found=True,
    )
    rules = {item["violated_rule"] for item in validate_run(invalid)}
    assert "RULE_2_NO_EXECUTABLE" in rules
    assert "RULE_3_PASS_REQUIREMENTS" in rules
    assert "RULE_6_COUNTEREXAMPLE_STATE" in rules
    assert "RULE_7_FUZZ_COUNTS" in rules


def test_readability_validation_is_accepted_bounded_and_not_correctness():
    scored = {
        "readability_variables": 4,
        "readability_loops": 3,
        "readability_conditions": 4,
        "readability_logic_flow": 3,
        "readability_structure": 4,
        "readability_overall": 3.6,
        "readability_correctness_assessed": False,
        "evaluator_id": "cx/gpt-5.5",
        "evaluation_method": "llm_absolute_rubric_1_to_5",
    }
    assert not [
        error
        for error in validate_run(make_run("p1", "F1", **scored))
        if error["severity"] == "ERROR"
    ]

    invalid = make_run(
        "p2",
        "F1",
        **{
            **scored,
            "candidate_accepted": False,
            "readability_variables": 6,
            "readability_correctness_assessed": True,
        },
    )
    rules = {error["violated_rule"] for error in validate_run(invalid)}
    assert "RULE_11_READABILITY_ACCEPTED_ONLY" in rules
    assert "RULE_12_READABILITY_SCHEMA" in rules
    assert "RULE_13_READABILITY_NOT_CORRECTNESS" in rules


def test_report_and_all_figure_generation(tmp_path: Path):
    runs = [make_run("p1", flow) for flow in FLOW_ORDER]
    for run in runs:
        run.update(
            {
                "readability_variables": 4,
                "readability_loops": 3,
                "readability_conditions": 4,
                "readability_logic_flow": 3,
                "readability_structure": 4,
                "readability_overall": 3.6,
                "readability_correctness_assessed": False,
                "evaluator_id": "cx/gpt-5.5",
                "evaluation_method": "llm_absolute_rubric_1_to_5",
            }
        )
    llvm = [
        {
            "experiment_id": "experiment_fixture",
            "sample_id": "p1",
            "llvm_verify_attempted": True,
            "llvm_verify_success": True,
            "llvm_verify_error": None,
            "raw_instruction_count": 100,
            "clean_instruction_count": 50,
            "instruction_reduction_percent": 50.0,
            "raw_basic_block_count": 20,
            "clean_basic_block_count": 10,
            "basic_block_reduction_percent": 50.0,
            "raw_conditional_branch_count": 10,
            "clean_conditional_branch_count": 5,
            "conditional_branch_reduction_percent": 50.0,
        }
    ]
    compile_attempts = [
        {
            "experiment_id": "experiment_fixture",
            "run_id": run["run_id"],
            "sample_id": "p1",
            "flow_id": run["flow_id"],
            "repeat_id": 0,
            "record_type": "compile_attempt",
            "attempt_index": 1,
            "compile_success": True,
            "failure_category": None,
        }
        for run in runs
    ]
    campaigns = [
        {
            "experiment_id": "experiment_fixture",
            "run_id": run["run_id"],
            "sample_id": "p1",
            "flow_id": run["flow_id"],
            "repeat_id": 0,
            "record_type": "fuzz_campaign",
            "campaign_index": 1,
            "is_fully_equivalent": True,
        }
        for run in runs
    ]
    data = {
        "schema_version": "2.0",
        "experiment_id": "experiment_fixture",
        "campaign_dir": str(tmp_path / "campaign"),
        "runs": runs,
        "llm_attempts": [],
        "compile_attempts": compile_attempts,
        "campaigns": campaigns,
        "counterexamples": [],
        "llvm_samples": llvm,
        "tool_versions": {},
        "git_commit": "abc",
    }
    export_report(data, tmp_path)
    required = {
        "per_sample_results.csv",
        "per_attempt_results.csv",
        "per_flow_metrics.csv",
        "compilation_metrics.csv",
        "behavioral_metrics.csv",
        "repair_metrics.csv",
        "reliability_metrics.csv",
        "llvm_metrics.csv",
        "source_quality_metrics.csv",
        "source_quality_summary.csv",
        "cost_metrics.csv",
        "stage_completion_metrics.csv",
        "ablation_comparisons.csv",
        "statistical_tests.csv",
        "failure_breakdown.csv",
        "counterexamples.csv",
        "data_validation_errors.csv",
        "experiment_summary.json",
        "raw_results.jsonl",
        "report.md",
        "report.tex",
        "report.html",
        "dashboard.html",
    }
    assert required <= {path.name for path in tmp_path.iterdir()}
    manifest = json.loads((tmp_path / "figures_manifest.json").read_text())
    assert len(manifest) == 18
    assert any(
        item["figure_id"] == "iterative_feedback_vs_one_shot"
        for item in manifest
    )
    dashboard = (tmp_path / "dashboard.html").read_text(encoding="utf-8")
    report = (tmp_path / "report.md").read_text(encoding="utf-8")
    assert "Source quality: accepted Recovered C Source only" in report
    assert "Source quality: accepted Recovered C Source only" in dashboard
    assert "3.60" in report
    assert "Flow contracts" not in dashboard
    assert dashboard.count("<b>Ý nghĩa:</b>") == 18
    assert dashboard.count("<b>Cách tính:</b>") == 18
    assert dashboard.count("<b>Cách đọc:</b>") == 18
    for item in manifest:
        for extension in ("png", "svg", "pdf"):
            assert (tmp_path / "figures" / f"{item['figure_id']}.{extension}").is_file()
