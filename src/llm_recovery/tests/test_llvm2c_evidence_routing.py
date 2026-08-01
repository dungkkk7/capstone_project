from __future__ import annotations

import json
from pathlib import Path

import pytest

from llm_recovery import llm_recovery as recovery
from tools import llvm_to_c


PASSING_REPORT = {
    "confirmed_equivalence_ratio": 100.0,
    "confirmed_runs": 1,
    "matches": 1,
    "mismatches": 0,
    "inconclusive": 0,
}


class CapturingClient:
    def __init__(self) -> None:
        self.calls: list[tuple[str, dict]] = []
        self.last_response_meta = {
            "finish_reason": "STOP",
            "usage_metadata": {},
        }

    def generate(self, prompt: str, **kwargs) -> str:
        self.calls.append((prompt, kwargs))
        return "int main(void) { return 0; }\n"


@pytest.mark.parametrize(
    (
        "backend",
        "attach_clean_ir",
        "ir_representation",
        "expected_mode",
        "expected_files",
    ),
    [
        (
            "llvm2c",
            False,
            "clean",
            "pseudocode",
            ("clean_pseudocode.c",),
        ),
        (
            "llvm2c",
            True,
            "clean",
            "dual",
            ("clean_pseudocode.c", "clean.ll"),
        ),
        (
            "ir",
            False,
            "clean",
            "llvm_ir",
            ("clean.ll",),
        ),
        (
            "ir",
            False,
            "raw",
            "raw_ir",
            ("clean.ll",),
        ),
    ],
)
def test_recovery_routes_exact_requested_evidence_files(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    backend: str,
    attach_clean_ir: bool,
    ir_representation: str,
    expected_mode: str,
    expected_files: tuple[str, ...],
) -> None:
    clean_ir = tmp_path / "clean.ll"
    clean_ir.write_text(
        "define i32 @main() { ret i32 0 }\n",
        encoding="utf-8",
    )
    pseudocode = "int llvm2c_marker(void) { return 7; }\n"

    def fake_transpile(_input: str, output: str) -> None:
        Path(output).write_text(pseudocode, encoding="utf-8")

    monkeypatch.setattr(
        llvm_to_c,
        "transpile_llvm_ir_to_c",
        fake_transpile,
    )
    monkeypatch.setattr(
        recovery,
        "_run_compile_check",
        lambda *_args, **_kwargs: (True, None),
    )
    output = tmp_path / "generation"
    client = CapturingClient()

    result = recovery.run_recovery_loop(
        ir_text=clean_ir.read_text(encoding="utf-8"),
        output_recovered_c_path=str(output / "candidate.c"),
        case_output_dir=str(output),
        metadata={"input_ir": str(clean_ir)},
        fuzzer_callback=lambda _candidate: PASSING_REPORT,
        config=recovery.RecoveryConfig(
            max_iterations=1,
            pseudo_backend=backend,
            attach_clean_ir=attach_clean_ir,
            ir_representation=ir_representation,
            use_file_api=True,
            require_json=False,
        ),
        model_client=client,
    )

    assert result.success is True
    assert len(client.calls) == 1
    prompt, kwargs = client.calls[0]
    assert tuple(
        Path(path).name for path in kwargs["attachment_paths"]
    ) == expected_files
    context = json.loads(
        (output / "recovery_iter1.context.json").read_text(
            encoding="utf-8"
        )
    )
    assert context["evidence_mode"] == expected_mode
    if backend == "llvm2c":
        assert (output / "clean_pseudocode.c").read_text(
            encoding="utf-8"
        ) == pseudocode
        assert "LLVM2C" in kwargs["system_instruction"]
    else:
        assert not (output / "clean_pseudocode.c").exists()
        assert "pseudocode" in kwargs["system_instruction"]
        if ir_representation == "raw":
            assert "raw, non-deobfuscated LLVM IR" in kwargs["system_instruction"]
            assert "raw lifted LLVM IR" in prompt
        else:
            assert "does not carry pseudocode" in kwargs["system_instruction"]
    assert "Ghidra" not in prompt
    assert "Ghidra" not in kwargs["system_instruction"]


def test_llvm2c_inline_dual_prompt_contains_both_representations(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    clean_ir = tmp_path / "clean.ll"
    clean_ir_text = "define i32 @clean_ir_marker() { ret i32 0 }\n"
    clean_ir.write_text(clean_ir_text, encoding="utf-8")
    pseudocode = "int llvm2c_marker(void) { return 7; }\n"
    monkeypatch.setattr(
        llvm_to_c,
        "transpile_llvm_ir_to_c",
        lambda _input, output: Path(output).write_text(
            pseudocode,
            encoding="utf-8",
        ),
    )
    monkeypatch.setattr(
        recovery,
        "_run_compile_check",
        lambda *_args, **_kwargs: (True, None),
    )
    output = tmp_path / "generation"
    client = CapturingClient()

    result = recovery.run_recovery_loop(
        ir_text=clean_ir_text,
        output_recovered_c_path=str(output / "candidate.c"),
        case_output_dir=str(output),
        metadata={"input_ir": str(clean_ir)},
        fuzzer_callback=lambda _candidate: PASSING_REPORT,
        config=recovery.RecoveryConfig(
            max_iterations=1,
            pseudo_backend="llvm2c",
            attach_clean_ir=True,
            use_file_api=False,
            require_json=False,
        ),
        model_client=client,
    )

    assert result.success is True
    prompt, kwargs = client.calls[0]
    assert kwargs["attachment_paths"] == []
    assert pseudocode in prompt
    assert clean_ir_text in prompt
    assert "LLVM-to-C transpiled pseudocode" in prompt
    assert "brightened LLVM IR" in prompt


def test_removed_ghidra_backend_fails_before_model_call(
    tmp_path: Path,
) -> None:
    client = CapturingClient()

    with pytest.raises(recovery.RecoveryError, match="Unsupported pseudocode"):
        recovery.run_recovery_loop(
            ir_text="define i32 @main() { ret i32 0 }\n",
            output_recovered_c_path=str(tmp_path / "candidate.c"),
            case_output_dir=str(tmp_path / "generation"),
            metadata={},
            config=recovery.RecoveryConfig(
                max_iterations=1,
                pseudo_backend="ghidra",
            ),
            model_client=client,
        )

    assert client.calls == []
