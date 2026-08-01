#!/usr/bin/env python3

import importlib.util
import json
import tempfile
from pathlib import Path


pipeline_file = Path(__file__).resolve().parents[2] / "britening_ir.py"
spec = importlib.util.spec_from_file_location("britening_ir", pipeline_file)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


stderr = """brighten-native-cleanup report:
  remaining State globals/aliases: 1
  native contract violations: 7
brighten-native-cleanup report:
  remaining State globals/aliases: 0
  ptrtoint/inttoptr: 2/6
  native contract violations: 3
  native contract finding: guest CFG / flattened dispatcher model: main
  native contract finding: guest stack backing global: frame_storage_backing.main
"""

report = module.parse_native_contract_reports(stderr)
assert report["report_count"] == 2
assert report["status"] == "non_compliant"
assert report["is_fully_native"] is False
assert report["metrics"]["remaining_State_globals_aliases"] == 0
assert report["metrics"]["ptrtoint_inttoptr"] == {
    "ptrtoint": 2,
    "inttoptr": 6,
}
assert report["metrics"]["native_contract_violations"] == 3
assert len(report["findings"]) == 2

with tempfile.TemporaryDirectory() as directory:
    output = Path(directory) / "case_brightened.bc"
    path = module.write_native_contract_report(str(output), report)
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    assert Path(path).name == "case_brightened_native_contract_report.json"
    assert payload["status"] == "non_compliant"
    assert payload["output"] == str(output.resolve())

print("Native contract report tests: PASS")
