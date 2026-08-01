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
            (Path(row["clean_source"]).parts[2], row["submission_id"])
            for row in csv.DictReader(
                (self.project_root / "data" / "custom_dataset.csv").open(encoding="utf-8")
            )
        }
        contracts = load_contracts(str(self.project_root))
        self.assertEqual(len(rows), 40)
        self.assertEqual(rows, set(contracts))

    def test_resolves_contract_from_dataset_binary_path(self):
        path = self.project_root / "data" / "obfuscated" / "p04028" / "s626776881_fla_bcf_instsub.elf"
        contract = resolve_input_contract(str(self.project_root), str(path))
        self.assertIsNotNone(contract)
        self.assertEqual(contract["kind"], "encoded_line_stream")

    def test_counted_long_list_rejects_mutated_or_missing_count(self):
        contract = load_contracts(str(self.project_root))[("p00165", "s722254321")]
        valid, reason = validate_contract_payload(contract, b"1\n2 -1\n0\n")
        self.assertFalse(valid)
        self.assertIsNotNone(reason)

    def test_scanf_conversion_completeness_accepts_c_integer_forms(self):
        contract = {
            "kind": "encoded_line_stream",
            "constraints": {"newline_required": True},
            "scanf_required_conversions": [
                {"source": "line", "line_index": 0, "format": "%d%d"},
                {"source": "line", "line_index": 1, "format": "%i %x %o %s"},
                {"source": "line", "line_index": 2, "format": "%% %*2d %3s"},
            ],
        }
        payload = b"-8 +5\n0x10 ff 077 word\n% 12 abc\n"
        valid, reason = validate_contract_payload(contract, payload)
        self.assertTrue(valid, reason)

    def test_scanf_conversion_completeness_rejects_partial_eof_width_and_unsupported(self):
        base = {
            "kind": "encoded_line_stream",
            "scanf_required_conversions": [
                {"source": "line", "line_index": 0, "format": "%d%d"},
            ],
        }
        for payload in (b"8@5\n", b"8\n", b"8 +\n"):
            valid, reason = validate_contract_payload(base, payload)
            self.assertFalse(valid)
            self.assertEqual(reason, "scanf_conversion_incomplete")

        width = {
            "kind": "encoded_line_stream",
            "scanf_required_conversions": [
                {"source": "stdin", "format": "%2d%2d"},
            ],
        }
        self.assertTrue(validate_contract_payload(width, b"1234\n")[0])
        self.assertFalse(validate_contract_payload(width, b"12x4\n")[0])

        unsupported = {
            "kind": "encoded_line_stream",
            "scanf_required_conversions": [
                {"source": "stdin", "format": "%f"},
            ],
        }
        valid, reason = validate_contract_payload(unsupported, b"1.0\n")
        self.assertFalse(valid)
        self.assertEqual(reason, "scanf_format_unsupported")

    def test_p01571_rejects_partial_sscanf_header_and_keeps_valid_corpus(self):
        contract = load_contracts(str(self.project_root), prefer_custom=True)[
            ("p01571", "s327549193")
        ]
        invalid = b"8@5\nqwerty asdf zxcv\nqwert\nasf\ntyui\nzxcvb\nghjk\n"
        valid, reason = validate_contract_payload(contract, invalid)
        self.assertFalse(valid)
        self.assertEqual(reason, "scanf_conversion_incomplete")

        seed = (self.project_root / "data" / "seeds" / "p01571" / "p01571_seed.txt").read_bytes()
        corpus, stats = generate_contract_inputs(contract, [seed], 20, rng_seed=1571)
        self.assertEqual(len(corpus), 20)
        self.assertGreater(stats["accepted"], 0)
        self.assertTrue(all(validate_contract_payload(contract, payload, [seed])[0] for payload in corpus))

    def test_custom_contracts_reject_old_crash_and_timeout_inputs(self):
        contracts = load_contracts(str(self.project_root), prefer_custom=True)
        p02950_timeout = b"719 0\n" + b" ".join([b"0"] * 718) + b"\n"
        invalid = {
            ("p00165", "s722254321"): b"1\n2 -1\n0\n",
            ("p00793", "s729150918"): b"2000 2000 8000 8000 9000 9500\n",
            ("p00788", "s998194081"): b"2 1\n0 0\n",
            ("p00859", "s595927985"): b"2 1\n1 2@100\n0 0\n",
            ("p01296", "s236329906"): b"2\n1 1 x\n0\n",
            ("p01315", "s212409236"): b"2\nitem 1 1 1 1 1 1 1 1 1\n0\n",
            ("p01970", "s660972586"): b"3\n2 -999997 3\n",
            ("p02029", "s891773536"): b"3 2\n10 1\n20 2\n30 3\n20 2\n",
            ("p02788", "s653265412"): b"3 3 0\n1 2\n5 4\n9 2\n",
            ("p02814", "s915631953"): b"2 50\n5 10\n",
            ("p02950", "s864110221"): p02950_timeout,
            ("p03142", "s710805295"): b"3 3\n9 2\n5 3\n3 3\n",
            ("p03199", "s752471056"): b"5 3\n1 1 $\n3 1 0\n60238\n2 8 1\n",
            ("p03261", "s577603531"): b"39718\n0\nh_pn\nemrdifh\nbtgn\ncnzemq\n",
            ("p03430", "s601450783"): b"34808\nybcqbcmbh\nc\n",
            ("p03776", "s721771429"): b"4 -12281 1 1 2 3 1000000\n",
            ("p03835", "s836003439"): b"17342 -834724\n",
            ("p04028", "s626776881"): b"4041\n4\n8\n",
        }
        for key, payload in invalid.items():
            if key in contracts:
                valid, reason = validate_contract_payload(contracts[key], payload)
                self.assertFalse(valid, f"{key}: {reason}")

    def test_generates_valid_custom_inputs_for_oracle_sensitive_cases(self):
        contracts = load_contracts(str(self.project_root), prefer_custom=True)
        cases = {
            ("p00165", "s722254321"),
            ("p00793", "s729150918"),
            ("p00788", "s998194081"),
            ("p00859", "s595927985"),
            ("p01296", "s236329906"),
            ("p01315", "s212409236"),
            ("p01970", "s660972586"),
            ("p02029", "s891773536"),
            ("p02788", "s653265412"),
            ("p02814", "s915631953"),
            ("p02950", "s864110221"),
            ("p03142", "s710805295"),
            ("p03199", "s752471056"),
            ("p03261", "s577603531"),
            ("p03430", "s601450783"),
            ("p03776", "s721771429"),
            ("p03835", "s836003439"),
            ("p04028", "s626776881"),
        }
        for key in cases:
            case_id, _ = key
            seed_file = self.project_root / "data" / "seeds" / case_id / f"{case_id}_seed.txt"
            if not seed_file.is_file():
                continue
            seed = seed_file.read_bytes()
            contract = contracts[key]
            generated, _ = generate_contract_inputs(contract, [seed], 100)
            self.assertEqual(len(generated), 100, case_id)
            for payload in generated:
                valid, reason = validate_contract_payload(contract, payload, [seed])
                self.assertTrue(valid, f"{case_id}: {reason}")

    def test_generates_and_validates_one_hundred_inputs_for_every_case(self):
        contracts = load_contracts(str(self.project_root))
        rows = csv.DictReader(
            (self.project_root / "data" / "custom_dataset.csv").open(encoding="utf-8")
        )
        for row in rows:
            case_id = Path(row["clean_source"]).parts[2]
            key = (case_id, row["submission_id"])
            if key not in contracts:
                continue
            contract = contracts[key]
            seed_paths = sorted((self.project_root / "data" / "seeds" / case_id).glob("*"))
            seeds = [sp.read_bytes() for sp in seed_paths if sp.is_file()]
            if not seeds:
                continue
            generated, _ = generate_contract_inputs(contract, seeds, 100)
            self.assertEqual(len(generated), 100, case_id)
            for payload in generated:
                valid, reason = validate_contract_payload(contract, payload, seeds)
                self.assertTrue(valid, f"{case_id}: {reason}")


if __name__ == "__main__":
    unittest.main()
