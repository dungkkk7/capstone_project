#!/usr/bin/env python3

import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


pipeline_file = Path(__file__).resolve().parents[2] / "britening_ir.py"
spec = importlib.util.spec_from_file_location("britening_ir", pipeline_file)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

plugin = module.resolve_souper_plugin()
assert plugin is not None, "project-local LLVM 21 Souper plugin is missing"
assert Path(plugin).resolve() == (
    pipeline_file.parents[2]
    / "dependency/souper/build-llvm21/libsouperPass.so"
).resolve()
assert b"dependency/souper/bin/z3" in Path(plugin).read_bytes(), (
    "Souper plugin must use the bundled project-relative Z3 executable"
)
maximum_mode, maximum_flags = module.souper_mode_flags("maximum")
assert module.SOUPER_CASE_BUDGET_SECONDS == 1800
assert module.SOUPER_SAFE_FALLBACK_RESERVE_SECONDS == 120
assert maximum_mode == "maximum"
assert "-souper-use-cegis" in maximum_flags
assert any(flag.startswith("-souper-synthesis-comps=") for flag in maximum_flags)
assert "-souper-harvest-uses" in maximum_flags
artifact_names = module.optimization_artifact_paths("case_brightened.bc")
assert artifact_names["after_souper"] == "case_brightened.ll"
assert artifact_names["before_souper"] == "case_brightened_before_souper.ll"
assert "brighten-ollvm-deobf-pass" not in module.PASS_PIPELINE
assert module.DEOBF_ROUND_PIPELINE.count("brighten-ollvm-deobf-pass") == 1
assert module.DEOBF_ROUND_PIPELINE.endswith("verify")
assert module.DEOBF_FIXED_POINT_MAX_ROUNDS == 8
assert module.deobf_proof_ledger_path("case_brightened.bc").endswith(
    "case_brightened_deobf_proof_ledger.json"
)

with tempfile.TemporaryDirectory() as directory:
    diagnostic_log = Path(directory) / "souper.log"
    diagnostic_log.write_text(
        "; entering Souper's runOnFunction() for foo()\n"
        "================= LHS number 1 ====================\n"
        "got 7 candidates from LHS\n"
        "(3 guesses were too expensive)\n"
        "no solutions for LHS number 1\n"
        "done with LHS number 2 after doing a replacement\n"
        "query error for LHS number 3\n",
        encoding="utf-8",
    )
    summary = module.summarize_souper_log(str(diagnostic_log))
    assert summary["functions_processed"] == 1
    assert summary["lhs_attempts"] == 1
    assert summary["candidates_considered"] == 7
    assert summary["too_expensive_guesses"] == 3
    assert summary["lhs_without_solution"] == 1
    assert summary["replacements_found"] == 1
    assert summary["query_errors"] == 1

with tempfile.TemporaryDirectory() as directory:
    lifted_bc = Path(directory) / "lifted.bc"
    lifted_ll = Path(directory) / "lifted.ll"
    redundant_ll = Path(directory) / "brightened_before_brightening.ll"
    lifted_bc.write_bytes(b"dummy")
    lifted_ll.write_text("; canonical lifted IR\n", encoding="utf-8")
    redundant_ll.write_text("; redundant old snapshot\n", encoding="utf-8")
    resolved = module._resolve_before_brightening_artifact(
        str(lifted_bc), str(redundant_ll)
    )
    assert Path(resolved) == lifted_ll
    assert not redundant_ll.exists()

source = """
define i32 @foo(i32 %x) {
entry:
  %add = add nsw i32 %x, 1
  %cmp = icmp sgt i32 %add, %x
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}
"""

with tempfile.TemporaryDirectory() as directory:
    fixed_point_bc = Path(directory) / "fixed-point.bc"
    subprocess.run(
        ["llvm-as-21", "-o", fixed_point_bc], input=source, text=True,
        check=True,
    )
    assert module.run_deobf_fixed_point(str(fixed_point_bc))
    fixed_point_report = json.loads(
        Path(module.deobf_proof_ledger_path(str(fixed_point_bc))).read_text(
            encoding="utf-8"
        )
    )
    assert fixed_point_report["fixed_point"]["converged"] is True
    assert 1 <= fixed_point_report["fixed_point"]["rounds"] <= 8
    subprocess.run(["opt-21", "-passes=verify", fixed_point_bc, "-disable-output"],
                   check=True)

with tempfile.TemporaryDirectory() as directory:
    fixed_point_ll = Path(directory) / "fixed-point.ll"
    fixed_point_ll.write_text(source, encoding="utf-8")
    assert module.run_deobf_fixed_point(str(fixed_point_ll))
    assert fixed_point_ll.read_text(encoding="utf-8").startswith("; ModuleID")
    subprocess.run(["opt-21", "-passes=verify", fixed_point_ll, "-disable-output"],
                   check=True)

with tempfile.TemporaryDirectory() as directory:
    capped_bc = Path(directory) / "capped.bc"
    subprocess.run(
        ["llvm-as-21", "-o", capped_bc], input=source, text=True,
        check=True,
    )
    os.environ["BRIGHTEN_DEOBF_MAX_ROUNDS"] = "1"
    try:
        assert not module.run_deobf_fixed_point(str(capped_bc))
    finally:
        os.environ.pop("BRIGHTEN_DEOBF_MAX_ROUNDS", None)
    capped_report = json.loads(
        Path(module.deobf_proof_ledger_path(str(capped_bc))).read_text(
            encoding="utf-8"
        )
    )
    assert capped_report["status"] == "partial_with_residuals"
    assert capped_report["fixed_point"]["converged"] is False
    assert capped_report["fixed_point"]["residual_reason"] == (
        "fixed_point_cap_reached"
    )

residual_dispatcher = """
define void @residual(i32 %dynamic) {
entry: br label %dispatch
dispatch:
  %state = phi i32 [ 1, %entry ], [ %dynamic, %latch ]
  switch i32 %state, label %exit [
    i32 1, label %a
    i32 2, label %b
    i32 3, label %c
    i32 4, label %d
  ]
a: br label %latch
b: br label %latch
c: br label %latch
d: br label %latch
latch: br label %dispatch
exit: ret void
}
"""

with tempfile.TemporaryDirectory() as directory:
    residual_bc = Path(directory) / "residual.bc"
    subprocess.run(
        ["llvm-as-21", "-o", residual_bc], input=residual_dispatcher,
        text=True, check=True,
    )
    assert not module.run_deobf_fixed_point(str(residual_bc))
    residual_report = json.loads(
        Path(module.deobf_proof_ledger_path(str(residual_bc))).read_text(
            encoding="utf-8"
        )
    )
    assert residual_report["fixed_point"]["converged"] is True
    assert residual_report["status"] == "partial_with_residuals"
    assert any(
        proof["result"] == "unresolved"
        for proof in residual_report["proofs"]
    )

with tempfile.TemporaryDirectory() as directory:
    input_path = Path(directory) / "input.ll"
    output_path = Path(directory) / "output.ll"
    input_path.write_text(source, encoding="utf-8")
    os.environ["BRIGHTEN_SOUPER_MODE"] = "safe"
    try:
        assert module.optimize_with_souper(str(input_path), str(output_path))
    finally:
        os.environ.pop("BRIGHTEN_SOUPER_MODE", None)
    optimized = output_path.read_text(encoding="utf-8")
    assert "ret i32 1" in optimized, optimized

    report_path = Path(module.souper_report_path(str(output_path)))
    report = json.loads(report_path.read_text(encoding="utf-8"))
    assert report["status"] == "pass"
    assert report["pipeline"] == module.SOUPER_PASS_PIPELINE
    assert report["module_timeout_seconds"] == 120
    assert report["solver_timeout_seconds"] == 15
    assert report["output_bytes"] == output_path.stat().st_size
    assert Path(report["log"]).is_file()
    assert "replacements_found" in report["diagnostics"]

    os.environ["BRIGHTEN_SOUPER"] = "0"
    disabled_path = Path(directory) / "disabled.ll"
    try:
        assert module.optimize_with_souper(str(input_path), str(disabled_path))
    finally:
        os.environ.pop("BRIGHTEN_SOUPER", None)
    assert disabled_path.read_text(encoding="utf-8") == source
    disabled_report = json.loads(
        Path(module.souper_report_path(str(disabled_path))).read_text(
            encoding="utf-8"
        )
    )
    assert disabled_report["status"] == "disabled"

with tempfile.TemporaryDirectory() as directory:
    input_path = Path(directory) / "fallback-input.ll"
    output_path = Path(directory) / "fallback-output.ll"
    input_path.write_text(source, encoding="utf-8")
    real_run = module.subprocess.run

    def fake_run(command, **kwargs):
        if "-souper-use-cegis" in command:
            return subprocess.CompletedProcess(
                command, -6, "", "function broken after Souper changed it"
            )
        shutil.copy2(input_path, command[-1])
        return subprocess.CompletedProcess(command, 0, "", "")

    module.subprocess.run = fake_run
    try:
        assert module.optimize_with_souper(str(input_path), str(output_path))
    finally:
        module.subprocess.run = real_run
    fallback_report = json.loads(
        Path(module.souper_report_path(str(output_path))).read_text(
            encoding="utf-8"
        )
    )
    assert fallback_report["status"] == "pass_with_fallback"
    assert fallback_report["requested_mode"] == "maximum"
    assert fallback_report["effective_mode"] == "safe"
    assert fallback_report["maximum_failure"]["returncode"] == -6
    assert fallback_report["maximum_failure"]["log"].endswith(
        "_souper_maximum.log"
    )
    assert fallback_report["log"].endswith("_souper_safe.log")
