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

    def test_manifest_covers_exact_filtered_pilot_dataset(self):
        rows = {
            (row["case_id"], row["submission_id"])
            for row in csv.DictReader(
                (self.project_root / "data" / "pilot_mix3_50.csv").open(encoding="utf-8")
            )
        }
        contracts = load_contracts(str(self.project_root))
        self.assertEqual(len(rows), 49)
        self.assertEqual(rows, set(contracts))

    def test_resolves_contract_from_dataset_binary_path(self):
        path = self.project_root / "data" / "obfuscated" / "p00183" / "s868256135_fla_bcf_instsub.elf"
        contract = resolve_input_contract(str(self.project_root), str(path))
        self.assertEqual(contract["kind"], "board_stream")

    def test_counted_long_list_rejects_mutated_or_missing_count(self):
        contract = load_contracts(str(self.project_root))[("p00523", "s224448187")]
        valid, reason = validate_contract_payload(contract, b"7\n1\n5\n4\n5\n2\n4\n")
        self.assertFalse(valid)
        self.assertEqual(reason, "counted_long_list_size")
        valid, reason = validate_contract_payload(contract, b"6\n1\n5\n4\n5\n2\n4\n")
        self.assertTrue(valid, reason)

    def test_dimension_expression_rejects_out_of_bounds_header(self):
        contract = load_contracts(str(self.project_root))[("p00672", "s657381439")]
        seed = (self.project_root / "data/seeds/p00672/p00672_seed.txt").read_bytes()
        valid, reason = validate_contract_payload(contract, seed)
        self.assertTrue(valid, reason)
        malformed = seed.replace(b"3 6 6\nspeed", b"-999997 6 6\nspeed")
        valid, reason = validate_contract_payload(contract, malformed)
        self.assertFalse(valid)
        self.assertEqual(reason, "dimension_expression_bounds")

    def test_case_specific_bounds_reject_old_false_mismatches(self):
        contracts = load_contracts(str(self.project_root))
        invalid = {
            ("p00200", "s958104051"): b"6 5\n1 2 200 10\n1 4 400 15\n1 3 250 25\n2 4 100 10\n4 0 150 20\n3 5 300 20\n2\n1 5 0\n1 5 1\n0 0\n",
            ("p00313", "s852342213"): b"5\n3 1 2 3\n2 -999996 5\n2 3 4\n",
            ("p00056", "s237479322"): b"10\n2594734\n0\n",
            ("p02060", "s706882681"): b"10\n1 2 3 4\n1 2 4 259377\n",
            ("p00212", "s286523912"): b"2 6 6 5 1\n1 2 1500\n1 3 4500\n2 1 2000\n5 4 1000\n6 4 2200\n3 1000000 3000\n0 0 0 0 0\n",
            ("p00924", "s930678486"): b"6 2\n1 0 0 1 0 1\n1 3 2\n",
            ("p01415", "s248769728"): b"1 1 1 2 3 1000000\n50\n",
        }
        for key, payload in invalid.items():
            valid, reason = validate_contract_payload(contracts[key], payload)
            self.assertFalse(valid, f"{key}: {reason}")

    def test_circle_batches_reject_count_desynchronization(self):
        contract = load_contracts(str(self.project_root))[("p00818", "s818780493")]
        seed = (self.project_root / "data/seeds/p00818/p00818_seed.txt").read_bytes()
        valid, reason = validate_contract_payload(contract, seed)
        self.assertTrue(valid, reason)
        malformed = seed.replace(b"\n2\n0 0 1.0000001", b"\n4\n0 0 1.0000001", 1)
        valid, reason = validate_contract_payload(contract, malformed)
        self.assertFalse(valid)
        self.assertIn(reason, {"circle_batch_size", "circle_batch_count", "circle_batch_terminator"})

    def test_structural_contracts_reject_timeout_and_short_read_payloads(self):
        contracts = load_contracts(str(self.project_root))
        invalid = {
            ("p00230", "s380322669"): b"263349\n0 0\n0\n",
            ("p00671", "s180500470"): b"5 5 10 2\n1 1 1\n0 0 0 0\n",
            ("p02559", "s544278538"): b"5 -999995\n1 2 3 4 5\n",
            ("p03114", "s312521097"): b"4\n5\n1 2\n2 0\n",
        }
        for key, payload in invalid.items():
            valid, reason = validate_contract_payload(contracts[key], payload)
            self.assertFalse(valid, f"{key}: {reason}")

    def test_custom_contracts_reject_old_crash_and_timeout_inputs(self):
        contracts = load_contracts(str(self.project_root), prefer_custom=True)
        p02950_timeout = b"719 0\n" + b" ".join([b"0"] * 718) + b"\n"
        invalid = {
            ("p00165", "s722254321"): b"1\n2 -1\n0\n",
            ("p00793", "s729150918"): b"2000 2000 8000 8000 9000 9500\n",
            ("p00788", "s998194081"): b"2 1\n0 0\n",
            ("p01296", "s236329906"): b"2\n1 1 x\n0\n",
            ("p01315", "s212409236"): b"2\nitem 1 1 1 1 1 1 1 1 1\n0\n",
            ("p01970", "s660972586"): b"3\n2 -999997 3\n",
            ("p02029", "s891773536"): b"3 2\n10 1\n20 2\n30 3\n20 2\n",
            ("p02788", "s653265412"): b"3 3 0\n1 2\n5 4\n9 2\n",
            ("p02814", "s915631953"): b"2 50\n5 10\n",
            ("p02950", "s864110221"): p02950_timeout,
            ("p03142", "s710805295"): b"3 3\n9 2\n5 3\n3 3\n",
        }
        for key, payload in invalid.items():
            valid, reason = validate_contract_payload(contracts[key], payload)
            self.assertFalse(valid, f"{key}: {reason}")

    def test_generates_valid_custom_inputs_for_oracle_sensitive_cases(self):
        contracts = load_contracts(str(self.project_root), prefer_custom=True)
        cases = {
            ("p00165", "s722254321"),
            ("p00793", "s729150918"),
            ("p00788", "s998194081"),
            ("p01296", "s236329906"),
            ("p01315", "s212409236"),
            ("p01970", "s660972586"),
            ("p02029", "s891773536"),
            ("p02788", "s653265412"),
            ("p02814", "s915631953"),
            ("p02950", "s864110221"),
            ("p03142", "s710805295"),
        }
        for key in cases:
            case_id, _ = key
            seed = (
                self.project_root
                / "data"
                / "seeds"
                / case_id
                / f"{case_id}_seed.txt"
            ).read_bytes()
            contract = contracts[key]
            generated, _ = generate_contract_inputs(contract, [seed], 100)
            self.assertEqual(len(generated), 100, case_id)
            for payload in generated:
                valid, reason = validate_contract_payload(contract, payload, [seed])
                self.assertTrue(valid, f"{case_id}: {reason}")

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
