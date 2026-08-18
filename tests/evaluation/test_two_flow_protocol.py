import json
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src"))

from evaluation.assembly_baseline import (
    AssemblyBaselineError,
    clean_objdump_program,
    export_program_assembly,
)
from evaluation.ghidra_baseline import GhidraBaselineError, export_program_pseudocode
from evaluation.run_experiment import CaseTracker
from evaluation.run_two_flow_experiment import StrictOneShotVertexGemini, run_b0_experiment
from evaluation.two_flow_protocol import (
    B1_GHIDRA_ITERATIVE,
    B2_ASSEMBLY_ONESHOT,
    B3_ASSEMBLY_ITERATIVE,
    EVALUATION_FLOW_ORDER,
    EVALUATION_FLOWS,
    LLM4DECOMPILE_B0_INSTRUCTION,
    LLM4DECOMPILE_ASSEMBLY_AFTER,
    LLM4DECOMPILE_ASSEMBLY_BEFORE,
    PRIMARY_FLOW_ORDER,
    PRIMARY_FLOWS,
    build_b0_prompt,
    build_b2_prompt,
    protocol_manifest,
)
from llm_recovery.llm_recovery import RecoveryConfig, VertexGemini


def test_primary_protocol_contains_only_baseline_and_proposed_method():
    assert PRIMARY_FLOW_ORDER == ("B0", "F3")
    assert set(PRIMARY_FLOWS) == {"B0", "F3"}
    assert PRIMARY_FLOWS["B0"].provider_call_budget == 1
    assert PRIMARY_FLOWS["B0"].compiler_feedback is False
    assert PRIMARY_FLOWS["B0"].behavioral_feedback is False
    assert PRIMARY_FLOWS["F3"].provider_call_budget == 5
    assert PRIMARY_FLOWS["F3"].compiler_feedback is True
    assert PRIMARY_FLOWS["F3"].behavioral_feedback is True


def test_b1_is_registered_as_a_non_primary_feedback_ablation():
    assert EVALUATION_FLOW_ORDER == ("B0", "B1", "B2", "B3", "F3")
    assert set(EVALUATION_FLOWS) == {"B0", "B1", "B2", "B3", "F3"}
    assert B1_GHIDRA_ITERATIVE.provider_call_budget == 5
    assert B1_GHIDRA_ITERATIVE.compiler_feedback is True
    assert B1_GHIDRA_ITERATIVE.behavioral_feedback is True
    assert "B1" not in PRIMARY_FLOWS
    manifest = protocol_manifest()
    assert manifest["registered_ablations"]["B1"]["initial_system_instruction"] is None
    assert "byte-identical B0 prompt" in manifest["registered_ablations"]["B1"]["initial_request"]


def test_b2_b3_are_registered_without_changing_primary_flows():
    assert B2_ASSEMBLY_ONESHOT.provider_call_budget == 1
    assert B2_ASSEMBLY_ONESHOT.compiler_feedback is False
    assert B3_ASSEMBLY_ITERATIVE.provider_call_budget == 5
    assert B3_ASSEMBLY_ITERATIVE.compiler_feedback is True
    assert {"B2", "B3"}.isdisjoint(PRIMARY_FLOWS)
    manifest = protocol_manifest()["registered_ablations"]
    assert manifest["B2"]["paper_section"] == "4.1.1"
    assert manifest["B2"]["initial_system_instruction"] is None
    assert "byte-identical B2 prompt" in manifest["B3"]["initial_request"]


def test_b0_prompt_preserves_paper_instruction_and_raw_ghidra_text():
    pseudocode = "int main(void) { return 7; }\n"
    assert build_b0_prompt(pseudocode) == (
        LLM4DECOMPILE_B0_INSTRUCTION + "\n\n" + pseudocode
    )
    manifest = protocol_manifest()
    assert manifest["baseline_prompt"]["source_section"] == "4.2.1"
    assert manifest["baseline_prompt"]["system_instruction"] is None
    assert "excluded from the primary claim" in manifest["historical_six_flow_role"]


def test_b2_prompt_matches_official_inference_serialization():
    assembly = "<main>:\n\tpush %rbp\n\tret\n"
    assert build_b2_prompt(assembly) == (
        LLM4DECOMPILE_ASSEMBLY_BEFORE
        + assembly.strip()
        + LLM4DECOMPILE_ASSEMBLY_AFTER
    )


def test_objdump_cleaner_keeps_all_functions_and_removes_bytes_and_comments():
    raw = """
sample: file format elf64-x86-64

0000000000401000 <helper>:
  401000:\t55                   \tpush   %rbp
  401001:\t48 8b 05 00 00 00 00 \tmov 0x0(%rip),%rax # 404000 <data>

0000000000401010 <main>:
  401010:\te8 eb ff ff ff       \tcall 401000 <helper>
  401015:\tc3                   \tret
"""
    assert clean_objdump_program(raw) == (
        "<helper>:\n"
        "push   %rbp\n"
        "mov 0x0(%rip),%rax\n\n"
        "<main>:\n"
        "call 401000 <helper>\n"
        "ret\n"
    )


def test_assembly_exporter_rejects_non_elf_input(tmp_path):
    candidate = tmp_path / "sample.bin"
    candidate.write_text("not a binary")
    with pytest.raises(AssemblyBaselineError, match="not ELF"):
        export_program_assembly(candidate, tmp_path / "out")


def test_b0_rejects_pipeline_derived_binary(tmp_path):
    candidate = tmp_path / "sample_final.bin"
    candidate.write_bytes(b"\x7fELF placeholder")
    with pytest.raises(GhidraBaselineError, match="original obfuscated ELF"):
        export_program_pseudocode(candidate, tmp_path / "out")


def test_b0_rejects_non_elf_input(tmp_path):
    candidate = tmp_path / "sample.bin"
    candidate.write_text("not a binary")
    with pytest.raises(GhidraBaselineError, match="not an ELF"):
        export_program_pseudocode(candidate, tmp_path / "out")


def test_protocol_manifest_is_json_serializable():
    json.dumps(protocol_manifest(), sort_keys=True)


def test_b0_runner_source_has_no_recovery_loop():
    import inspect

    source = inspect.getsource(run_b0_experiment)
    assert "run_recovery_loop" not in source
    assert "client.generate" in source
    assert "logical_provider_call_budget\": 1" in source


def test_b0_provider_client_has_no_retry_path():
    import inspect

    source = inspect.getsource(StrictOneShotVertexGemini.generate)
    assert "self.tracker.llm_calls != 0" in source
    assert "super().generate" in source
    assert "return self.generate" not in source
    assert "us-central1" not in source


def test_b0_provider_client_enforces_one_physical_request(monkeypatch):
    physical_calls = []

    def fake_generate(self, prompt, **kwargs):
        physical_calls.append(prompt)
        self.last_response_meta = {}
        return "int main(void) { return 0; }"

    monkeypatch.setattr(VertexGemini, "generate", fake_generate)
    tracker = CaseTracker("sample", "B0")
    client = StrictOneShotVertexGemini(RecoveryConfig(), tracker)
    assert client.generate("request") == "int main(void) { return 0; }"
    with pytest.raises(RuntimeError, match="forbids provider retry"):
        client.generate("request again")
    assert physical_calls == ["request"]
    assert tracker.llm_calls == 1
