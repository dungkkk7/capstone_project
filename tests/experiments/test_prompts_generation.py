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
    prompt = build_one_shot_prompt(MethodId.B0, "void main(void) {}")
    assert prompt.user_prompt == B0_USER_TEMPLATE.replace(
        "{GHIDRA_PSEUDOCODE}", "void main(void) {}"
    )
    assert "baseline" not in prompt.user_prompt.lower()
    assert "BinDeObfBench" not in prompt.user_prompt


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
    assert user_prompt.startswith("Representation type:")
    assert kwargs["system_instruction"] == EXPECTED_SYSTEM
    request = json.loads(
        (tmp_path / "generation" / "request.json").read_text()
    )
    assert request["prompt_policy"]["provenance_note"].endswith(
        "not represented as the exact prompt from the paper."
    )
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
