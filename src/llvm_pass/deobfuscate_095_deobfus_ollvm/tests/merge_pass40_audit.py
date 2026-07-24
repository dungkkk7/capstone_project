#!/usr/bin/env python3
"""Merge isolated pass-40 audit summaries with strict coverage checks."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def ordered_case_ids(pipeline_summary: Path) -> list[str]:
    source = json.loads(pipeline_summary.read_text(encoding="utf-8"))
    result = [Path(item["binary"]).parent.name for item in source["cases"]]
    requested = int(source["counts"]["requested"])
    if len(result) != requested or len(set(result)) != requested:
        raise RuntimeError("pipeline summary does not contain unique requested cases")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pipeline-summary", type=Path, required=True)
    parser.add_argument("--case-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    case_ids = ordered_case_ids(args.pipeline_summary)
    cases: list[dict] = []
    for case_id in case_ids:
        path = args.case_root / case_id / "summary.json"
        if not path.is_file():
            raise RuntimeError(f"{case_id}: missing isolated summary: {path}")
        summary = json.loads(path.read_text(encoding="utf-8"))
        items = summary.get("cases", [])
        if summary.get("requested") != 1 or len(items) != 1:
            raise RuntimeError(f"{case_id}: expected exactly one audited case")
        if items[0].get("case") != case_id:
            raise RuntimeError(f"{case_id}: isolated summary id mismatch")
        cases.append(items[0])

    counts: dict[str, int] = {}
    for item in cases:
        status = str(item["status"])
        counts[status] = counts.get(status, 0) + 1
    merged = {
        "requested": len(case_ids),
        "counts": counts,
        "all_passed": counts == {"pass": len(case_ids)},
        "cases": cases,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: merged[key] for key in ("requested", "counts", "all_passed")}))
    return 0 if merged["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
