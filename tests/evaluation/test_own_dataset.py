import hashlib
import csv
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATASET = ROOT / "data" / "own_dataset"
sys.path.insert(0, str(ROOT / "src"))

from fuzzing_equi_check.input_contracts import (
    generate_contract_inputs,
    resolve_input_contract,
    validate_contract_payload,
)
from main import _find_reference_source, _resolve_seed_paths


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def test_own_dataset_is_balanced_frozen_and_self_consistent(tmp_path):
    manifest = json.loads((DATASET / "manifest.json").read_text())
    assert manifest["dataset_id"] == "own-dataset-v1-20260815"
    assert manifest["freeze_state"] == "FROZEN_BEFORE_FIRST_RECOVERY_MODEL_CALL"
    assert manifest["provenance"]["authored_case_count"] == 40
    assert len(manifest["cases"]) == 40
    assert set(manifest["categories"]) == {
        "parsing_state_machine",
        "numeric_bitwise",
        "arrays_windows",
        "strings_encodings",
        "structural_control_flow",
        "graph_algorithms",
        "data_structures",
        "checksums_formats",
    }
    assert all(len(case_ids) == 5 for case_ids in manifest["categories"].values())
    assert len({case["source_sha256"] for case in manifest["cases"]}) == 40

    for case in manifest["cases"]:
        source = DATASET / case["source"]
        seed = DATASET / case["seed"]
        assert sha256(source) == case["source_sha256"]
        assert sha256(seed) == case["seed_sha256"]
        binary = tmp_path / case["case_id"]
        compile_result = subprocess.run(
            [
                "clang-21",
                "-std=c11",
                "-O2",
                "-Wall",
                "-Wextra",
                "-Werror",
                str(source),
                "-o",
                str(binary),
            ],
            capture_output=True,
            text=True,
        )
        assert compile_result.returncode == 0, compile_result.stderr
        run = subprocess.run([str(binary)], input=seed.read_bytes(), capture_output=True)
        assert run.returncode == 0
        assert run.stderr == b""
        assert run.stdout.decode() == case["expected_stdout"]


def test_own_dataset_csv_has_40_existing_source_binary_pairs():
    with (ROOT / "data/own_dataset.csv").open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    assert len(rows) == 40
    assert {row["dataset_split"] for row in rows} == {"own_v1"}
    for row in rows:
        assert (ROOT / row["clean_source"]).is_file()
        assert (ROOT / row["obfuscated_binary"]).is_file()


def test_own_dataset_builder_plain_gate():
    result = subprocess.run(
        ["python3", str(ROOT / "tools" / "build_own_dataset.py"), "--plain-only"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["plain_only"] is True
    assert len(payload["cases"]) == 40
    assert all(case["oracle_verified"] for case in payload["cases"])


def test_all_40_obfuscated_elfs_have_provenance_and_match_seed_oracle():
    manifest = json.loads((DATASET / "manifest.json").read_text())
    build = json.loads((DATASET / "build_manifest.json").read_text())
    records = {record["case_id"]: record for record in build["cases"]}
    assert build["plain_only"] is False
    assert build["pass_pipeline"] == "function(reg2mem,own-instsub,own-fla,own-bcf),verify"
    assert build["dataset_manifest_sha256"] == sha256(DATASET / "manifest.json")
    assert build["dataset_csv_sha256"] == sha256(ROOT / "data/own_dataset.csv")
    assert build["input_contract_sha256"] == sha256(
        ROOT / "data/input_contracts/own_dataset.json"
    )
    assert build["plugin_source_sha256"] == sha256(
        ROOT / "tools/own_obfuscator/OwnObfuscator.cpp"
    )
    assert len(records) == 40

    for case in manifest["cases"]:
        record = records[case["case_id"]]
        binary = ROOT / record["obfuscated_binary"]
        seed = DATASET / case["seed"]
        assert binary.read_bytes()[:4] == b"\x7fELF"
        assert sha256(binary) == record["obfuscated_binary_sha256"]
        assert all(record["marker_counts"][name] > 0 for name in ("instsub", "fla", "bcf"))
        run = subprocess.run([str(binary)], input=seed.read_bytes(), capture_output=True)
        assert run.returncode == 0
        assert run.stderr == b""
        assert run.stdout.decode() == case["expected_stdout"]


def test_obfuscated_elfs_match_plain_programs_on_deterministic_contract_probes(tmp_path):
    manifest = json.loads((DATASET / "manifest.json").read_text())
    for index, case in enumerate(manifest["cases"]):
        source = DATASET / case["source"]
        seed = (DATASET / case["seed"]).read_bytes()
        obfuscated = (
            DATASET
            / "obfuscated"
            / case["case_id"]
            / f"{case['submission_id']}_fla_bcf_instsub.elf"
        )
        plain = tmp_path / case["case_id"]
        result = subprocess.run(
            ["clang-21", "-std=c11", "-O0", str(source), "-o", str(plain)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr
        contract = resolve_input_contract(str(ROOT), str(obfuscated), only_custom=True)
        assert contract is not None
        probes, stats = generate_contract_inputs(
            contract, [seed], 16, rng_seed=26081500 + index
        )
        assert stats["accepted"] >= 1
        for payload in probes:
            expected = subprocess.run(
                [str(plain)], input=payload, capture_output=True, timeout=2
            )
            actual = subprocess.run(
                [str(obfuscated)], input=payload, capture_output=True, timeout=2
            )
            assert (actual.returncode, actual.stdout, actual.stderr) == (
                expected.returncode,
                expected.stdout,
                expected.stderr,
            ), (case["case_id"], payload)


def test_every_own_dataset_seed_has_a_resolvable_valid_contract():
    manifest = json.loads((DATASET / "manifest.json").read_text())
    for case in manifest["cases"]:
        binary = (
            DATASET
            / "obfuscated"
            / case["case_id"]
            / f"{case['submission_id']}_fla_bcf_instsub.elf"
        )
        contract = resolve_input_contract(str(ROOT), str(binary), only_custom=True)
        assert contract is not None, case["case_id"]
        seed = (DATASET / case["seed"]).read_bytes()
        valid, reason = validate_contract_payload(contract, seed, [seed])
        assert valid, (case["case_id"], reason)


def test_main_resolves_own_dataset_source_and_seed():
    binary = DATASET / "obfuscated/h00021/n26081521_fla_bcf_instsub.elf"
    source = _find_reference_source(str(ROOT), str(binary))
    seeds, seed_dir = _resolve_seed_paths(str(ROOT), str(binary))
    assert source == str(DATASET / "src/h00021/n26081521.c")
    assert seeds == [str(DATASET / "seeds/h00021/h00021_seed.txt")]
    assert seed_dir == str(DATASET / "seeds/h00021")
