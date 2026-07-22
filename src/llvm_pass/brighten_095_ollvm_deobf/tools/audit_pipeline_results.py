#!/usr/bin/env python3
"""Summarize a Brighten pipeline directory without conflating failure classes."""

import argparse
import collections
import json
from pathlib import Path
import re


def load_json(path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def one(directory, pattern):
    matches = sorted(directory.glob(pattern))
    return matches[0] if len(matches) == 1 else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pipeline_dir")
    parser.add_argument("--report")
    args = parser.parse_args()

    root = Path(args.pipeline_dir).resolve()
    summary_path = root / "pipeline_summary.json"
    summary = load_json(summary_path) if summary_path.exists() else {}
    case_dirs = sorted(path for path in root.glob("p*") if path.is_dir())

    ledger_statuses = collections.Counter()
    native_statuses = collections.Counter()
    native_classes = collections.Counter()
    native_findings = collections.Counter()
    partial_reasons = collections.Counter()
    missing_ledgers = []
    semantic_nonpass = []
    semantic_unbound = []
    cases = []

    for case_dir in case_dirs:
        case = {"case": case_dir.name}
        ledger_path = one(case_dir, "*_deobf_proof_ledger.json")
        if ledger_path:
            ledger = load_json(ledger_path)
            status = ledger.get("status", "unknown")
            ledger_statuses[status] += 1
            case["deobf_status"] = status
            residuals = [
                proof for proof in ledger.get("proofs", [])
                if proof.get("result") != "proved"
            ]
            case["residual_count"] = len(residuals)
            case["residuals"] = [
                {
                    "function": item.get("function"),
                    "origin": item.get("origin"),
                    "kind": item.get("kind"),
                    "engine": item.get("proof_engine"),
                    "reason": item.get("residual_reason"),
                }
                for item in residuals
            ]
            for item in residuals:
                reason = item.get("residual_reason") or "unspecified"
                if reason.startswith("memory_join_recurrence:"):
                    category = "memory_join_recurrence_incomplete_store_coverage"
                elif reason.startswith("state_root_or_transition_set_not_recovered"):
                    region = re.search(r"region_rejection=([^;]+)", reason)
                    plumbing = re.search(r"ssa_plumbing_rejection=([^;]+)", reason)
                    details = []
                    if region:
                        details.append("region=" + region.group(1))
                    if plumbing:
                        details.append("ssa=" + plumbing.group(1).split(":", 1)[0])
                    category = "state_or_transition_recovery_failed"
                    if details:
                        category += ":" + ",".join(details)
                else:
                    category = reason.split(";", 1)[0]
                partial_reasons[category] += 1
        else:
            missing_ledgers.append(case_dir.name)
            case["deobf_status"] = "missing"

        semantic_path = one(case_dir, "*_semantic_report.json")
        if semantic_path:
            semantic = load_json(semantic_path)
            case["semantic_fully_equivalent"] = semantic.get("is_fully_equivalent")
            case["semantic_matches"] = semantic.get("matches")
            case["semantic_mismatches"] = semantic.get("mismatches")
            has_binding = bool(
                semantic.get("execution_binding")
                or semantic.get("artifacts")
                or semantic.get("binary_sha256")
                or semantic.get("prog2_sha256")
            )
            case["semantic_report_has_artifact_binding"] = has_binding
            if not has_binding:
                semantic_unbound.append(case_dir.name)
            if semantic.get("is_fully_equivalent") is False:
                semantic_nonpass.append({
                    "case": case_dir.name,
                    "total_runs": semantic.get("total_runs"),
                    "matches": semantic.get("matches"),
                    "mismatches": semantic.get("mismatches"),
                    "artifact_binding_present": has_binding,
                    "examples": semantic.get("mismatch_examples", [])[:5],
                })

        native_path = one(case_dir, "*_native_contract_report.json")
        if native_path:
            native = load_json(native_path)
            native_statuses[native.get("status", "unknown")] += 1
            native_classes[native.get("output_class", "unknown")] += 1
            for finding in native.get("findings", []):
                native_findings[str(finding)] += 1
            case["native_status"] = native.get("status")
            case["native_output_class"] = native.get("output_class")
            case["native_findings"] = native.get("findings", [])
        cases.append(case)

    output = {
        "schema": "brighten-pipeline-audit-v1",
        "pipeline_dir": str(root),
        "pipeline_summary_counts": summary.get("counts"),
        "observed": {
            "case_directories": len(case_dirs),
            "ledger_statuses": dict(ledger_statuses),
            "missing_ledger_count": len(missing_ledgers),
            "missing_ledgers": missing_ledgers,
            "partial_reason_categories": dict(partial_reasons.most_common()),
            "semantic_nonpass_count": len(semantic_nonpass),
            "semantic_nonpass": semantic_nonpass,
            "semantic_reports_without_artifact_binding_count": len(semantic_unbound),
            "semantic_reports_without_artifact_binding": semantic_unbound,
            "native_report_statuses": dict(native_statuses),
            "native_output_classes": dict(native_classes),
            "native_findings": dict(native_findings.most_common()),
        },
        "cases": cases,
    }
    encoded = json.dumps(output, indent=2, sort_keys=True) + "\n"
    if args.report:
        Path(args.report).write_text(encoded, encoding="utf-8")
    print(encoded, end="")


if __name__ == "__main__":
    main()
