import json
import sys
import tempfile
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from main import _native_contract_status, _read_deobf_status  # noqa: E402
from llvm_pass.britening_ir import deobf_proof_ledger_path  # noqa: E402


def test_native_contract_status_is_independent_from_brightening_and_semantic():
    assert _native_contract_status(None) == "unchecked"
    assert _native_contract_status({"status": "unavailable"}) == "unchecked"
    assert _native_contract_status({"is_fully_native": True}) == "pass"
    assert _native_contract_status({"is_fully_native": False}) == "nonpass"


def test_deobf_status_exposes_partial_proofs_without_hiding_residuals():
    with tempfile.TemporaryDirectory() as directory:
        output = str(Path(directory) / "case_brightened.bc")
        assert _read_deobf_status(output) == ("unchecked", 0)

        ledger_path = Path(deobf_proof_ledger_path(output))
        ledger_path.write_text(json.dumps({
            "status": "partial_with_residuals",
            "proofs": [
                {"result": "proved"},
                {"result": "unresolved"},
                {"result": "unresolved"},
            ],
        }), encoding="utf-8")
        assert _read_deobf_status(output) == ("partial", 2)

        ledger_path.write_text(json.dumps({
            "status": "pass_detected_scope",
            "proofs": [{"result": "proved"}],
        }), encoding="utf-8")
        assert _read_deobf_status(output) == ("complete", 0)
