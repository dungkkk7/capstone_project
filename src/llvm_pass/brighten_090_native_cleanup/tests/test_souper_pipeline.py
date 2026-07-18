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
assert maximum_mode == "maximum"
assert "-souper-use-cegis" in maximum_flags
assert any(flag.startswith("-souper-synthesis-comps=") for flag in maximum_flags)
assert "-souper-harvest-uses" in maximum_flags
artifact_names = module.optimization_artifact_paths("case_brightened.bc")
assert artifact_names["after_souper"] == "case_brightened.ll"
assert artifact_names["before_souper"] == "case_brightened_before_souper.ll"

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
    assert report["output_bytes"] == output_path.stat().st_size

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
