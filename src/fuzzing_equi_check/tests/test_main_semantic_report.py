import json
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from main import (  # noqa: E402
    _allows_non_native_semantic_diagnostic,
    _semantic_status,
    _write_semantic_report,
)


class SemanticReportPersistenceTests(unittest.TestCase):
    def test_round_trips_structured_afl_counterexample_atomically(self):
        report = {
            "total_runs": 2,
            "matches": 1,
            "mismatches": 1,
            "is_fully_equivalent": False,
            "tested_payloads": ["MwoxIDIK"],
            "afl_stats": {"paths_total": "7", "bitmap_cvg": "0.01%"},
            "afl_seed_filter": {
                "rejected_count": 1,
                "rejected_examples": [
                    {"payload_base64": "OTk5CjEgMgo=", "reason": "structural_token_changed"}
                ],
            },
            "mismatch_examples": [
                {
                    "index": 1,
                    "args": [],
                    "stdin": "3\n1 2\n",
                    "reason": "stdout mismatch",
                    "prog1": {"status": "success", "returncode": 0, "stdout": "A\n", "stderr": ""},
                    "prog2": {"status": "success", "returncode": 0, "stdout": "B\n", "stderr": ""},
                }
            ],
        }

        with tempfile.TemporaryDirectory() as directory:
            report_path = Path(directory) / "case_semantic_report.json"
            _write_semantic_report(str(report_path), report)

            with report_path.open("r", encoding="utf-8") as report_file:
                persisted = json.load(report_file)

            self.assertEqual(persisted, report)
            self.assertFalse(Path(str(report_path) + ".tmp").exists())

    def test_semantic_status_separates_mismatch_from_no_verdict(self):
        self.assertEqual(_semantic_status(None), "unchecked")
        self.assertEqual(
            _semantic_status({"is_fully_equivalent": True, "mismatches": 0}),
            "pass",
        )
        self.assertEqual(
            _semantic_status({
                "is_fully_equivalent": False,
                "mismatches": 1,
                "inconclusive": 0,
            }),
            "nonpass",
        )
        self.assertEqual(
            _semantic_status({
                "is_fully_equivalent": False,
                "mismatches": 0,
                "inconclusive": 3,
            }),
            "unchecked",
        )

    def test_only_compat_runnable_nonpass_gets_diagnostic_execution(self):
        self.assertTrue(
            _allows_non_native_semantic_diagnostic({
                "status": "non_compliant",
                "is_fully_native": False,
                "output_class": "compat_runnable",
            })
        )
        self.assertFalse(
            _allows_non_native_semantic_diagnostic({
                "status": "non_compliant",
                "is_fully_native": False,
                "output_class": "structural_only",
            })
        )
        self.assertFalse(
            _allows_non_native_semantic_diagnostic({
                "status": "compliant",
                "is_fully_native": True,
                "output_class": "fully_native",
            })
        )
        self.assertFalse(_allows_non_native_semantic_diagnostic(None))


if __name__ == "__main__":
    unittest.main()
