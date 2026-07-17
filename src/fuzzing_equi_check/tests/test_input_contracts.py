import csv
import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from fuzzing_equi_check.input_contracts import (  # noqa: E402
    generate_contract_inputs,
    load_contracts,
    resolve_input_contract,
    validate_contract_payload,
)


class InputContractManifestTests(unittest.TestCase):
    project_root = Path(__file__).resolve().parents[3]

    def test_manifest_covers_exact_filtered_fifty(self):
        rows = {
            (row["case_id"], row["submission_id"])
            for row in csv.DictReader(
                (self.project_root / "data" / "pilot_mix3_50.csv").open(encoding="utf-8")
            )
        }
        contracts = load_contracts(str(self.project_root))
        self.assertEqual(len(rows), 50)
        self.assertEqual(rows, set(contracts))

    def test_resolves_contract_from_dataset_binary_path(self):
        path = self.project_root / "data" / "obfuscated" / "p00183" / "s868256135_fla_bcf_instsub.elf"
        contract = resolve_input_contract(str(self.project_root), str(path))
        self.assertEqual(contract["kind"], "board_stream")

    def test_generates_and_validates_one_hundred_inputs_for_every_case(self):
        contracts = load_contracts(str(self.project_root))
        rows = csv.DictReader(
            (self.project_root / "data" / "pilot_mix3_50.csv").open(encoding="utf-8")
        )
        for row in rows:
            contract = contracts[(row["case_id"], row["submission_id"])]
            seed_paths = [Path(row["seed_file"])]
            seed_paths.extend(
                sorted((self.project_root / "data" / "seeds" / row["case_id"]).glob("*.seed"))
            )
            seeds = []
            for seed_path in seed_paths:
                if not seed_path.is_absolute():
                    seed_path = self.project_root / seed_path
                if seed_path.is_file() and seed_path.read_bytes() not in seeds:
                    seeds.append(seed_path.read_bytes())
            generated, _ = generate_contract_inputs(contract, seeds, 100)
            self.assertEqual(len(generated), 100, row["case_id"])
            for payload in generated:
                valid, reason = validate_contract_payload(contract, payload, seeds)
                self.assertTrue(valid, f"{row['case_id']}: {reason}")


if __name__ == "__main__":
    unittest.main()
