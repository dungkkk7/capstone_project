#!/usr/bin/env python3
"""Read-only batch summary for final native-contract reports.

The report emitted by the native-contract verifier proves only the structural
contract.  In particular, a ``compliant`` report is deliberately *not*
reported as behavior or native-link evidence; those categories appear only
when a report itself contains corresponding evidence.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


REPORT_GLOB = "*_final_native_contract_report.json"
CATEGORY_ORDER = ("behavior", "link", "runtime", "fake_frame", "pointer", "abi", "cfg")

# Matching is intentionally evidence-oriented: it classifies text already in
# the report and never turns the top-level structural status into another
# category's status.
CATEGORY_TERMS = {
    "behavior": ("behavior", "behaviour", "differential", "stdout", "stderr", "side effect"),
    "link": ("native link", "native_link", "linker", "link status", "linked"),
    "runtime": ("runtime", "remill", "mcsema", "native_residual", "startup", "loader", "tls"),
    "fake_frame": ("fake frame", "frame backing", "frame_storage", "stack backing", "register storage", "state global"),
    "pointer": ("pointer", "ptrtoint", "inttoptr", "guest address", "mapper", "resolver", "range-dispatch"),
    "abi": (" abi", "abi ", "callback", "vararg", "prototype", "calling convention"),
    "cfg": (" cfg", "cfg ", "dispatcher", "flattened", "indirect branch", "state machine", "control flow"),
}


def finding_prefix(finding: str) -> str:
    """Return the stable leading classification portion of a finding."""
    text = finding.strip()
    for separator in (":", "(", "["):
        if separator in text:
            text = text.split(separator, 1)[0].strip()
    return text or "<empty finding>"


def _evidence_items(report: dict[str, Any]) -> Iterable[str]:
    findings = report.get("findings", [])
    if isinstance(findings, list):
        for finding in findings:
            if isinstance(finding, str):
                yield finding
    metrics = report.get("metrics", {})
    if isinstance(metrics, dict):
        for key, value in metrics.items():
            yield f"metric {key}: {value}"
    for key in ("behavior", "behavior_status", "link", "link_status", "native_link", "differential"):
        if key in report:
            yield f"{key}: {report[key]}"


def classify_evidence(report: dict[str, Any]) -> dict[str, list[str]]:
    categories = {category: [] for category in CATEGORY_ORDER}
    for evidence in _evidence_items(report):
        lowered = evidence.lower().replace("_", " ")
        for category, terms in CATEGORY_TERMS.items():
            if any(term in lowered for term in terms):
                categories[category].append(evidence)
    return categories


def _case_name(path: Path, root: Path) -> str:
    return str(path.relative_to(root))


def summarize(root: Path) -> dict[str, Any]:
    """Load reports below *root* without creating, changing, or deleting files."""
    reports = sorted(path for path in root.rglob(REPORT_GLOB) if path.is_file())
    cases: list[dict[str, Any]] = []
    status_counts: Counter[str] = Counter()
    prefixes: dict[str, dict[str, Any]] = {}
    category_cases: dict[str, list[dict[str, Any]]] = {category: [] for category in CATEGORY_ORDER}
    invalid_reports: list[dict[str, str]] = []

    for path in reports:
        case = _case_name(path, root)
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            status = "invalid"
            evidence = {category: [] for category in CATEGORY_ORDER}
            invalid_reports.append({"case": case, "error": str(error)})
            findings: list[str] = []
        else:
            if not isinstance(payload, dict):
                payload = {}
                status = "invalid"
                invalid_reports.append({"case": case, "error": "report root is not an object"})
            else:
                raw_status = payload.get("status")
                status = raw_status if isinstance(raw_status, str) and raw_status else "unavailable"
            evidence = classify_evidence(payload)
            raw_findings = payload.get("findings", [])
            findings = [item for item in raw_findings if isinstance(item, str)] if isinstance(raw_findings, list) else []

        status_counts[status] += 1
        case_categories = [category for category, items in evidence.items() if items]
        cases.append({"case": case, "status": status, "categories": case_categories})
        for finding in findings:
            prefix = finding_prefix(finding)
            entry = prefixes.setdefault(prefix, {"count": 0, "cases": [], "findings": []})
            entry["count"] += 1
            if case not in entry["cases"]:
                entry["cases"].append(case)
            entry["findings"].append(finding)
        for category, items in evidence.items():
            if items:
                category_cases[category].append({"case": case, "evidence": items})

    categories = {
        category: {"case_count": len(category_cases[category]), "cases": category_cases[category]}
        for category in CATEGORY_ORDER
    }
    non_compliant = sum(1 for case in cases if case["status"] == "non_compliant")
    return {
        "schema": "native-contract-batch-audit-v1",
        "root": str(root.resolve()),
        "reports_found": len(reports),
        "status_counts": dict(sorted(status_counts.items())),
        "non_compliant_cases": non_compliant,
        "cases": cases,
        "findings_by_prefix": dict(sorted(prefixes.items())),
        "categories": categories,
        "invalid_reports": invalid_reports,
    }


def text_summary(summary: dict[str, Any]) -> str:
    lines = [
        f"native contract reports: {summary['reports_found']}",
        f"non_compliant cases: {summary['non_compliant_cases']}",
        "per-case status:",
    ]
    lines.extend(f"  {item['case']}: {item['status']}" for item in summary["cases"])
    lines.append("findings by prefix:")
    lines.extend(f"  {prefix}: {item['count']}" for prefix, item in summary["findings_by_prefix"].items())
    lines.append("evidence categories:")
    lines.extend(f"  {category}: {item['case_count']} case(s)" for category, item in summary["categories"].items())
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Read-only native-contract batch validator")
    parser.add_argument("root", type=Path, help="directory containing final contract reports")
    parser.add_argument("--format", choices=("json", "text"), default="json")
    parser.add_argument("--allow-noncompliant", action="store_true")
    args = parser.parse_args(argv)
    if not args.root.is_dir():
        parser.error(f"root is not a directory: {args.root}")
    summary = summarize(args.root)
    if args.format == "json":
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print(text_summary(summary))
    return 0 if args.allow_noncompliant or summary["non_compliant_cases"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
