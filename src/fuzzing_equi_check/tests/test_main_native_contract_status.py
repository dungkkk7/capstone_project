import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from main import _native_contract_status  # noqa: E402


def test_native_contract_status_is_independent_from_brightening_and_semantic():
    assert _native_contract_status(None) == "unchecked"
    assert _native_contract_status({"status": "unavailable"}) == "unchecked"
    assert _native_contract_status({"is_fully_native": True}) == "pass"
    assert _native_contract_status({"is_fully_native": False}) == "nonpass"
