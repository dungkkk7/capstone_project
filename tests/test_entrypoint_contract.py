from __future__ import annotations

import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = PROJECT_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from llvm_pass.brighten_100_delift_bundle import entrypoint_contract  # noqa: E402


def test_parse_posix_nm_ignores_undefined_symbols() -> None:
    output = "main T 0 10\nprintf U 0 0\nhelper T 10 4\n"
    assert entrypoint_contract.parse_posix_nm(output) == {"main", "helper"}


def test_missing_artifact_is_a_disproved_contract(tmp_path: Path) -> None:
    result = entrypoint_contract.inspect_entrypoint(tmp_path / "missing.ll")
    assert result.decision == "fail"
    assert "does not exist" in result.summary


def test_public_main_is_detected_via_llvm_symbol_table(
    tmp_path: Path, monkeypatch
) -> None:
    artifact = tmp_path / "module.bc"
    artifact.write_bytes(b"bitcode-placeholder")
    monkeypatch.setattr(entrypoint_contract, "_find_tool", lambda _names: "llvm-nm")
    monkeypatch.setattr(
        entrypoint_contract,
        "_materialize_bitcode",
        lambda path, _workdir, _timeout: (path, [], ""),
    )

    def fake_run(command, capture_output, text, timeout):
        assert "--extern-only" in command
        return subprocess.CompletedProcess(command, 0, "main T 0 10\n", "")

    monkeypatch.setattr(entrypoint_contract.subprocess, "run", fake_run)
    result = entrypoint_contract.inspect_entrypoint(artifact, "main")
    assert result.decision == "pass"
    assert result.public_definitions == ["main"]


def test_missing_public_main_is_rejected(tmp_path: Path, monkeypatch) -> None:
    artifact = tmp_path / "module.bc"
    artifact.write_bytes(b"bitcode-placeholder")
    monkeypatch.setattr(entrypoint_contract, "_find_tool", lambda _names: "llvm-nm")
    monkeypatch.setattr(
        entrypoint_contract,
        "_materialize_bitcode",
        lambda path, _workdir, _timeout: (path, [], ""),
    )
    monkeypatch.setattr(
        entrypoint_contract.subprocess,
        "run",
        lambda command, capture_output, text, timeout: subprocess.CompletedProcess(
            command, 0, "helper T 0 10\n", ""
        ),
    )

    result = entrypoint_contract.inspect_entrypoint(artifact, "main")
    assert result.decision == "fail"
    assert "missing" in result.summary
