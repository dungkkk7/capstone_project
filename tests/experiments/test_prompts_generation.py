import copy
import hashlib
import json
import sys
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from experiments.config import DEFAULT_CONFIG  # noqa: E402
from experiments.enums import MethodId  # noqa: E402
from experiments.generation import LeakageError, generate_one_shot  # noqa: E402
from experiments.models import RepresentationArtifact  # noqa: E402
from experiments.prompts import (  # noqa: E402
    B0_MINIMAL_SYSTEM_PROMPT,
    B0_USER_TEMPLATE,
    ONE_SHOT_SYSTEM_PROMPT,
    build_one_shot_prompt,
)
from experiments.storage import sha256_file  # noqa: E402
from llm_recovery import llm_recovery as recovery  # noqa: E402


EXPECTED_SYSTEM = """You are a highly skilled reverse engineer specializing in binary deobfuscation and C reconstruction.
Recover exactly one complete Linux-compilable C11 source file that preserves the observable behavior represented by the supplied low-level program representation.

Requirements:
1. Include main and every required user-defined function.
2. Include required standard headers, declarations, globals, constants, and helpers.
3. Do not omit behavior, use placeholders, or hard-code known test outputs.
4. Return C source only, without Markdown fences or explanations."""

EXPECTED_B0_SYSTEM = """You are a highly skilled reverse engineer specializing in binary deobfuscation and C reconstruction.
Recover exactly one complete Linux-compilable C11 source file that preserves the observable behavior represented by the supplied low-level program representation.
Requirements:
1. Return C source only, without Markdown fences or explanations."""


class CapturingClient:
    def __init__(self):
        self.calls = []
        self.last_response_meta = {
            "finish_reason": "STOP",
            "usage_metadata": {
                "prompt_token_count": 10,
                "candidates_token_count": 5,
                "thoughts_token_count": 3,
            },
        }

    def generate(self, prompt, **kwargs):
        self.calls.append((prompt, kwargs))
        return "int main(void) { return 0; }\n"


class JsonRecoveryClient(CapturingClient):
    def generate(self, prompt, **kwargs):
        self.calls.append((prompt, kwargs))
        return json.dumps({"source": "int main(void) { return 0; }\n"})


class MaxTokensThenCompleteClient(CapturingClient):
    def __init__(self, recovery_config):
        super().__init__()
        self.config = recovery_config

    def generate(self, prompt, **kwargs):
        self.calls.append(
            (prompt, kwargs, self.config.thinking_level)
        )
        if len(self.calls) == 1:
            self.last_response_meta = {
                "finish_reason": "MAX_TOKENS",
                "usage_metadata": {
                    "thoughts_token_count": 900,
                    "candidates_token_count": 100,
                },
            }
            return '{"source":"#include <stdio.h>\\nint main(void) {'
        self.last_response_meta = {
            "finish_reason": "STOP",
            "usage_metadata": {
                "thoughts_token_count": 10,
                "candidates_token_count": 20,
            },
        }
        return json.dumps(
            {"source": "int main(void) { return 0; }\n"}
        )


def config():
    value = copy.deepcopy(DEFAULT_CONFIG)
    value["_project_root"] = str(PROJECT_ROOT)
    value["llm"]["context_window_tokens"] = 1_000_000
    value["llm"]["max_output_tokens"] = 1024
    value["llm"]["transport_retries"] = 0
    return value


def artifact(path: Path, method=MethodId.B0):
    return RepresentationArtifact(
        method=method,
        primary_path=str(path),
        primary_sha256=sha256_file(path),
        byte_count=path.stat().st_size,
        token_count=10,
        builder_version="test",
        attachment_paths=[str(path)],
        attachment_sha256=[sha256_file(path)],
    )


def test_b0_prompt_policy_is_byte_exact():
    assert ONE_SHOT_SYSTEM_PROMPT == EXPECTED_SYSTEM
    pseudocode = "void main(void) {}"
    prompt = build_one_shot_prompt(MethodId.B0, pseudocode)
    assert prompt.system_prompt == EXPECTED_B0_SYSTEM
    assert prompt.system_prompt == B0_MINIMAL_SYSTEM_PROMPT
    assert prompt.user_prompt == B0_USER_TEMPLATE.replace(
        "{GHIDRA_PSEUDOCODE}", pseudocode
    )
    assert "MECHANICAL_EVIDENCE_INVENTORY" not in prompt.user_prompt
    assert "fuzz" not in prompt.user_prompt.lower()


def test_one_shot_sends_system_instruction_as_separate_role(tmp_path):
    representation = tmp_path / "ghidra_original_program.c"
    representation.write_text("// Function: main\nint main(){return 0;}\n")
    client = CapturingClient()

    result = generate_one_shot(
        MethodId.B0,
        artifact(representation),
        tmp_path / "generation",
        config(),
        model_client=client,
    )

    assert result.logical_generation_count == 1
    assert result.model_call_count == 1
    assert result.output_tokens == 5
    assert result.thinking_tokens == 3
    assert result.billable_output_tokens == 8
    assert result.total_tokens == 18
    assert len(client.calls) == 1
    user_prompt, kwargs = client.calls[0]
    assert user_prompt.startswith(
        "Representation type: decompiler-generated pseudocode"
    )
    assert kwargs["system_instruction"] == B0_MINIMAL_SYSTEM_PROMPT
    request = json.loads(
        (tmp_path / "generation" / "request.json").read_text()
    )
    assert "minimal Ghidra-only one-shot baseline" in (
        request["prompt_policy"]["provenance_note"]
    )
    assert request["decoding"]["thinking_level"] == "HIGH"
    assert request["context_gate"]["context_window_tokens"] == 1_000_000
    assert request["context_gate"]["model_spec_source"].startswith(
        "https://docs.cloud.google.com/"
    )
    assert request["context_gate"]["model_spec_verified_date"] == "2026-07-24"


def test_b0_rejects_ir_attachment(tmp_path):
    representation = tmp_path / "raw.ll"
    representation.write_text("define i32 @main() { ret i32 0 }\n")
    with pytest.raises(LeakageError):
        generate_one_shot(
            MethodId.B0,
            artifact(representation),
            tmp_path / "generation",
            config(),
            model_client=CapturingClient(),
        )


def test_a0_sends_only_raw_lifted_ir_in_one_shot(tmp_path):
    representation = tmp_path / "raw.ll"
    raw_ir = "define i32 @main() { ret i32 0 }\n"
    representation.write_text(raw_ir)
    client = CapturingClient()

    result = generate_one_shot(
        MethodId.A0,
        artifact(representation, MethodId.A0),
        tmp_path / "generation",
        config(),
        model_client=client,
    )

    assert result.logical_generation_count == 1
    assert result.model_call_count == 1
    assert len(client.calls) == 1
    user_prompt, kwargs = client.calls[0]
    assert raw_ir in user_prompt
    assert "<RAW_LIFTED_LLVM_IR>" in user_prompt
    assert "<OBFUSCATED_PSEUDOCODE>" not in user_prompt
    assert kwargs["system_instruction"] == EXPECTED_SYSTEM
    request = json.loads(
        (tmp_path / "generation" / "request.json").read_text()
    )
    assert request["representation_sha256"] == sha256_file(
        representation
    )
    assert request["forbidden_scan"]["passed"] is True


def test_p0_processing_consumes_precomputed_pseudocode_without_ghidra(
    tmp_path, monkeypatch
):
    prepared = tmp_path / "prepared_ghidra.c"
    prepared.write_text(
        "// Function: main\nint main(void) { return 0; }\n"
    )
    monkeypatch.setattr(
        recovery,
        "_decompile_binary_with_ghidra",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(
            AssertionError("processing must not invoke Ghidra")
        ),
    )
    client = JsonRecoveryClient()
    output = tmp_path / "generation"
    result = recovery.run_recovery_loop(
        ir_text="define i32 @main() { ret i32 0 }",
        output_recovered_c_path=str(output / "candidate.c"),
        case_output_dir=str(output),
        metadata={
            "precomputed_ghidra_pseudocode_path": str(prepared),
            "precomputed_ghidra_pseudocode_sha256": hashlib.sha256(
                prepared.read_bytes()
            ).hexdigest(),
        },
        config=recovery.RecoveryConfig(
            max_iterations=1,
            pseudo_backend="ghidra",
            two_stage_recovery=True,
            use_file_api=False,
            require_json=True,
        ),
        model_client=client,
    )

    assert result.success is True
    assert (output / "ghidra_pseudocode.c").read_bytes() == (
        prepared.read_bytes()
    )
    assert len(client.calls) == 1


def test_p0_ghidra_prompts_require_evidence_driven_reconstruction():
    pseudocode = r'''
// Function: main
undefined8 main(void)
{
  int local_10;
  __isoc99_scanf("%d",&local_10);
  printf("%d\n",local_10 + 1);
  return 0;
}
'''

    system_prompt = recovery.build_system_prompt(attach_clean_ir=False)
    initial_prompt = recovery.build_initial_prompt(
        pseudocode,
        {
            "sample_id": "p00001",
            "binary_path": "/must/not/leak/or/influence/recovery",
        },
        use_pseudo=True,
    )

    assert "Rank evidence before interpreting it" in system_prompt
    assert "complete reachable-call graph from the entry point" in system_prompt
    assert "semantic variable ledger" in system_prompt
    assert "variadic I/O" in system_prompt
    assert "ONLY the complete model-input artifact" in system_prompt
    assert "per-function consensus ledger" in system_prompt

    assert "<MECHANICAL_EVIDENCE_INVENTORY>" in initial_prompt
    assert "__isoc99_scanf" in initial_prompt
    assert '"%d\\n"' in initial_prompt
    assert "Contract pass:" in initial_prompt
    assert "Function pass:" in initial_prompt
    assert "Storage pass:" in initial_prompt
    assert "Control-flow pass:" in initial_prompt
    assert "Simulation pass:" in initial_prompt
    assert "Source pass:" in initial_prompt
    assert "Prefer faithful lower-level C with `goto`" in initial_prompt
    assert "IN_CONTEXT_DEMO" not in initial_prompt
    assert "Return the complete raw C11 translation unit only" in initial_prompt
    assert "/must/not/leak/or/influence/recovery" not in initial_prompt


def test_p0_and_b0_use_separate_prompt_policies():
    pseudocode = (
        "// Function: main\n"
        "int main(void) { return 0; }\n"
    )
    b0_prompt = build_one_shot_prompt(MethodId.B0, pseudocode)

    assert b0_prompt.system_prompt == B0_MINIMAL_SYSTEM_PROMPT
    assert b0_prompt.system_prompt != recovery.build_system_prompt(False)
    assert "MECHANICAL_EVIDENCE_INVENTORY" not in b0_prompt.user_prompt
    assert "Mandatory silent reconstruction" in recovery.build_system_prompt(
        False
    )


def test_p0_candidate_parser_accepts_raw_c_source():
    source = "#include <stdio.h>\nint main(void) { return 0; }\n"

    assert recovery.extract_c_source(
        source,
        require_json=False,
    ) == source


def test_p0_splits_oversized_dual_evidence_and_requires_ir_crosscheck(
    tmp_path, monkeypatch
):
    monkeypatch.setattr(
        recovery,
        "_run_compile_check",
        lambda *_args, **_kwargs: (True, None),
    )
    prepared = tmp_path / "prepared_ghidra.c"
    prepared.write_text(
        "int main(void) { return 0; }\n"
        + ("/* pseudocode evidence */\n" * 900)
    )
    cleaned_ir = tmp_path / "delifted.ll"
    cleaned_ir.write_text(
        "define i32 @main() { ret i32 0 }\n"
        + ("; cleaned IR evidence\n" * 900)
    )

    class ContextCapturingClient(CapturingClient):
        def generate(self, prompt, **kwargs):
            self.calls.append((prompt, kwargs))
            return "int main(void) { return 0; }\n"

    client = ContextCapturingClient()
    passing_report = {
        "equivalence_ratio": 100.0,
        "confirmed_equivalence_ratio": 100.0,
        "confirmed_runs": 1,
        "matches": 1,
        "mismatches": 0,
        "inconclusive": 0,
    }
    output = tmp_path / "generation"
    result = recovery.run_recovery_loop(
        ir_text=cleaned_ir.read_text(),
        output_recovered_c_path=str(output / "candidate.c"),
        case_output_dir=str(output),
        metadata={
            "input_ir": str(cleaned_ir),
            "precomputed_ghidra_pseudocode_path": str(prepared),
            "precomputed_ghidra_pseudocode_sha256": hashlib.sha256(
                prepared.read_bytes()
            ).hexdigest(),
        },
        fuzzer_callback=lambda _candidate: passing_report,
        config=recovery.RecoveryConfig(
            max_iterations=5,
            pseudo_backend="ghidra",
            two_stage_recovery=True,
            use_file_api=True,
            attach_clean_ir=True,
            require_json=False,
            max_output_tokens=256,
            context_window_tokens=18_000,
            context_safety_margin_tokens=128,
        ),
        model_client=client,
    )

    assert result.success is True
    assert result.iterations == 2
    assert len(client.calls) == 2
    first_attachments = client.calls[0][1]["attachment_paths"]
    second_attachments = client.calls[1][1]["attachment_paths"]
    assert first_attachments == [
        str(output / "ghidra_recovery_input.c")
    ]
    assert second_attachments == [str(cleaned_ir)]
    first_context = json.loads(
        (output / "recovery_iter1.context.json").read_text()
    )
    second_context = json.loads(
        (output / "recovery_iter2.context.json").read_text()
    )
    assert first_context["evidence_mode"] == "pseudocode"
    assert second_context["evidence_mode"] == "llvm_ir"
    assert first_context["dual_request"]["fit"] is False
    assert second_context["selected_request"]["fit"] is True


def test_candidate_validator_allows_descriptive_dummy_scanf_name():
    source = (
        "#include <stdio.h>\n"
        "int main(void) { int dummy_scanf; "
        'return scanf("%d", &dummy_scanf) != 1; }\n'
    )

    assert recovery.extract_c_source(
        json.dumps({"source": source}),
        require_json=True,
    ) == source


def test_p0_repair_prompt_forbids_counterexample_special_casing():
    repair_prompt = recovery.build_repair_prompt(
        ir_text=(
            "// Function: main\n"
            'int main(void) { int x; scanf("%d", &x); printf("%d\\n", x); }\n'
        ),
        candidate='int main(void) { puts("0"); }\n',
        feedback=(
            "stdin: 41\n"
            "reference stdout: 41\\n\n"
            "candidate stdout: 0\\n\n"
        ),
        max_ir_chars=None,
        source_label="Ghidra decompiler C-like pseudocode",
    )

    assert "concrete counterexample" in repair_prompt
    assert "not as permission" in repair_prompt
    assert "earliest causal divergence" in repair_prompt
    assert "Never add a literal exception" in repair_prompt
    assert "sibling branches, loop iterations, helper callers" in repair_prompt
    assert "Re-simulate the supplied counterexample" in repair_prompt
    assert "Do not reintroduce `frame_storage_backing_*`" in repair_prompt


def test_p0_fuzz_feedback_contains_exact_diff_history_and_localization():
    report = {
        "total_runs": 1,
        "confirmed_runs": 1,
        "matches": 0,
        "mismatches": 1,
        "inconclusive": 0,
        "equivalence_ratio": 0.0,
        "early_stopped": True,
        "early_stop_reason": "asymmetric crash",
        "mismatch_examples": [
            {
                "index": 7,
                "reason": "Stdout stream mismatch",
                "stdin": "41\n",
                "stdin_base64": "NDEK",
                "stdin_hex": "34310a",
                "stdin_byte_length": 3,
                "prog1": {
                    "status": "success",
                    "returncode": 0,
                    "signal": None,
                    "elapsed_ms": 1.0,
                    "stdout": "40\n",
                    "stderr": "",
                    "stdout_byte_length": 3,
                    "stderr_byte_length": 0,
                },
                "prog2": {
                    "status": "success",
                    "returncode": 0,
                    "signal": None,
                    "elapsed_ms": 1.2,
                    "stdout": "41\n",
                    "stderr": "",
                    "stdout_byte_length": 3,
                    "stderr_byte_length": 0,
                },
                "output_diffs": [
                    {
                        "stream": "stdout",
                        "first_differing_byte": 1,
                        "recovered_byte_hex": "30",
                        "reference_byte_hex": "31",
                        "recovered_length": 3,
                        "reference_length": 3,
                        "recovered_window_hex": "34300a",
                        "reference_window_hex": "34310a",
                    }
                ],
            }
        ],
    }
    feedback = recovery._format_fuzz_feedback(
        report,
        prior_history=["round=1: candidate_stdout='0', reference_stdout='41'"],
    )
    prompt = recovery.build_repair_prompt(
        ir_text="// Function: main\n",
        candidate=(
            "#include <stdio.h>\n"
            "int main(void) {\n"
            "  int x; scanf(\"%d\", &x);\n"
            "  if (x > 0) printf(\"%d\\n\", x - 1);\n"
            "  return 0;\n"
            "}\n"
        ),
        feedback=feedback,
        source_label="Ghidra pseudocode",
    )

    assert "stdin_base64=NDEK" in feedback
    assert "stdin_hex=34310a" in feedback
    assert "first_offset=1" in feedback
    assert "PRIOR ROUND HISTORY" in feedback
    assert "CANDIDATE_LOCALIZATION_HINTS" in prompt
    assert 'printf("%d\\n", x - 1)' in prompt
    assert "Map that operation to both attached pseudocode and cleaned IR" in feedback


def test_p0_max_tokens_retries_same_iteration_with_lower_thinking(tmp_path):
    prepared = tmp_path / "prepared_ghidra.c"
    prepared.write_text(
        "// Function: main\nint main(void) { return 0; }\n"
    )
    recovery_config = recovery.RecoveryConfig(
        max_iterations=1,
        pseudo_backend="ghidra",
        two_stage_recovery=True,
        use_file_api=False,
        require_json=True,
        thinking_level="LOW",
    )
    client = MaxTokensThenCompleteClient(recovery_config)
    output = tmp_path / "generation"

    result = recovery.run_recovery_loop(
        ir_text="define i32 @main() { ret i32 0 }",
        output_recovered_c_path=str(output / "candidate.c"),
        case_output_dir=str(output),
        metadata={
            "precomputed_ghidra_pseudocode_path": str(prepared),
            "precomputed_ghidra_pseudocode_sha256": hashlib.sha256(
                prepared.read_bytes()
            ).hexdigest(),
        },
        config=recovery_config,
        model_client=client,
    )

    assert result.success is True
    assert result.iterations == 1
    assert [call[2] for call in client.calls] == ["LOW", "MINIMAL"]
    assert (
        output / "recovery_iter1.max_tokens.response.txt"
    ).is_file()
