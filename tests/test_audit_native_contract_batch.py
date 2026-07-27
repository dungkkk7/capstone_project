#!/usr/bin/env python3
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "tools" / "audit_native_contract_batch.py"
spec = importlib.util.spec_from_file_location("audit_native_contract_batch", SCRIPT)
audit = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(audit)


class AuditNativeContractBatchTest(unittest.TestCase):
    def run_audit(self, root: Path, *extra: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(root), *extra],
            check=False,
            text=True,
            capture_output=True,
        )

    def write_report(self, root: Path, name: str, payload: dict) -> None:
        (root / name).write_text(json.dumps(payload), encoding="utf-8")

    def test_empty_root(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_audit(Path(directory))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["reports_found"], 0)

    def test_compliant_report_does_not_imply_behavior_or_link(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_report(root, "ok_final_native_contract_report.json", {
                "status": "compliant", "metrics": {"native_contract_violations": 0}, "findings": []
            })
            result = self.run_audit(root)
        self.assertEqual(result.returncode, 0, result.stderr)
        summary = json.loads(result.stdout)
        self.assertEqual(summary["cases"][0]["status"], "compliant")
        self.assertEqual(summary["categories"]["behavior"]["case_count"], 0)
        self.assertEqual(summary["categories"]["link"]["case_count"], 0)

    def test_noncompliant_report_groups_prefix_and_categories(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_report(root, "bad_final_native_contract_report.json", {
                "status": "non_compliant",
                "metrics": {"native_contract_violations": 2, "ptrtoint_inttoptr": {"ptrtoint": 1, "inttoptr": 1}},
                "findings": [
                    "guest stack backing global: frame_storage_backing.main",
                    "guest CFG / flattened dispatcher model: main",
                ],
            })
            result = self.run_audit(root)
            allowed = self.run_audit(root, "--allow-noncompliant")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(allowed.returncode, 0, allowed.stderr)
        summary = json.loads(result.stdout)
        self.assertEqual(summary["non_compliant_cases"], 1)
        self.assertEqual(summary["findings_by_prefix"]["guest stack backing global"]["count"], 1)
        self.assertEqual(summary["categories"]["fake_frame"]["case_count"], 1)
        self.assertEqual(summary["categories"]["pointer"]["case_count"], 1)
        self.assertEqual(summary["categories"]["cfg"]["case_count"], 1)


if __name__ == "__main__":
    unittest.main()
