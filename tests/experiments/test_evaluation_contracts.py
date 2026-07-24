import copy
import sys
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from experiments.config import DEFAULT_CONFIG  # noqa: E402
from experiments.evaluation import (  # noqa: E402
    EvaluationError,
    _compare,
    build_union_corpus,
    discover_inputs,
)
from experiments.storage import sha256_bytes  # noqa: E402
from fuzzing_equi_check.input_contracts import (  # noqa: E402
    generate_contract_inputs,
    load_contracts,
    validate_contract_payload,
)


def config():
    value = copy.deepcopy(DEFAULT_CONFIG)
    value["_project_root"] = str(PROJECT_ROOT)
    return value


def outcome(status="success", code=0, stdout=b"", stderr=b"", signal=None):
    return {
        "status": status,
        "returncode": code,
        "signal": signal,
        "stdout": stdout,
        "stderr": stderr,
    }


def test_common_oracle_outcome_policy():
    cfg = config()
    assert _compare(outcome(stdout=b"x"), outcome(stdout=b"x"), cfg) == "MATCH"
    assert _compare(outcome(stdout=b"x"), outcome(stdout=b"y"), cfg) == "MISMATCH_STDOUT"
    assert _compare(
        outcome(), outcome(status="timeout", code=None), cfg
    ) == "MISMATCH_TIMEOUT_ASYMMETRY"
    assert _compare(
        outcome(status="timeout", code=None),
        outcome(status="timeout", code=None),
        cfg,
    ) == "INCONCLUSIVE_BOTH_TIMEOUT"
    crash = outcome(status="crash", code=-11, signal=11)
    assert _compare(crash, crash, cfg) == "INCONCLUSIVE_BOTH_CRASH"


def test_contract_generation_is_seeded_without_global_drift():
    contracts = load_contracts(str(PROJECT_ROOT), prefer_custom=True)
    contract = next(iter(contracts.values()))
    seed_dir = PROJECT_ROOT / "data" / "seeds" / contract["case_id"]
    seed = next(path for path in sorted(seed_dir.iterdir()) if path.is_file()).read_bytes()

    first, first_stats = generate_contract_inputs(
        contract, [seed], 5, rng_seed=12345
    )
    second, second_stats = generate_contract_inputs(
        contract, [seed], 5, rng_seed=12345
    )

    assert first == second
    assert first_stats == second_stats


def test_counted_long_list_generation_includes_growth_boundaries():
    contracts = load_contracts(str(PROJECT_ROOT), prefer_custom=True)
    contract = contracts[("p00033", "s763935897")]
    seed = (
        PROJECT_ROOT / "data" / "seeds" / "p00033" / "p00033_seed.txt"
    ).read_bytes()

    generated, _ = generate_contract_inputs(
        contract, [seed], 10, rng_seed=12345
    )
    counts = {int(payload.split()[0]) for payload in generated}

    assert {1, 2, 4, 8, 16, 64}.issubset(counts)
    for payload in generated:
        valid, reason = validate_contract_payload(
            contract, payload, [seed]
        )
        assert valid, reason


def _corpus_item(path: Path, data: bytes, *, origin=None):
    path.write_bytes(data)
    return {
        "input_id": path.stem,
        "category": "seed",
        "path": str(path),
        "sha256": sha256_bytes(data),
        "size": len(data),
        "contract_valid": True,
        "origin_method": origin,
    }


def test_union_corpus_is_frozen_and_reused_on_resume(tmp_path):
    base = _corpus_item(tmp_path / "base.bin", b"base\n")
    first_union, first_hash = build_union_corpus(
        [base], [], tmp_path / "common"
    )
    extra = _corpus_item(
        tmp_path / "later.bin", b"later\n", origin="B0"
    )

    resumed_union, resumed_hash = build_union_corpus(
        [base], [[extra]], tmp_path / "common"
    )

    assert resumed_hash == first_hash
    assert [item["sha256"] for item in resumed_union] == [
        item["sha256"] for item in first_union
    ]


def test_frozen_union_detects_input_tampering(tmp_path):
    base = _corpus_item(tmp_path / "base.bin", b"base\n")
    union, _ = build_union_corpus([base], [], tmp_path / "common")
    Path(union[0]["path"]).write_bytes(b"tampered\n")

    with pytest.raises(
        EvaluationError, match="FROZEN_UNION_INPUT_HASH_MISMATCH"
    ):
        build_union_corpus([base], [], tmp_path / "common")


def test_discovery_rejects_compiled_binary_instead_of_silent_afl_fallback(
    tmp_path,
):
    binary = tmp_path / "candidate.bin"
    binary.write_bytes(b"\x7fELF")
    with pytest.raises(
        EvaluationError, match="DISCOVERY_REQUIRES_FROZEN_C_SOURCE"
    ):
        discover_inputs(
            None,
            str(binary),
            [],
            "P0",
            tmp_path / "discovery",
            config(),
        )
