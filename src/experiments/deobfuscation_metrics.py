from __future__ import annotations

import math
import re
from collections import Counter
from pathlib import Path
from statistics import median
from typing import Any, Dict, Iterable


_BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)
_LINE_COMMENT = re.compile(r"//[^\n]*")
_FUNCTION = re.compile(
    r"(?m)^[\t ]*(?!if\b|for\b|while\b|switch\b)"
    r"(?:[A-Za-z_][\w\t ]*[\s*]+)+"
    r"(?P<name>[A-Za-z_]\w*)\s*\([^;{}]*\)\s*\{"
)
_ARTIFACT = re.compile(
    r"\b(?:undefined\d*|uVar\d+|iVar\d+|piVar\d+|puVar\d+|"
    r"pbVar\d+|LAB_[A-Fa-f0-9]+|DAT_[A-Fa-f0-9]+|PTR_[A-Za-z0-9_]+|"
    r"CONCAT\d+|frame_storage[A-Za-z0-9_]*|__remill[A-Za-z0-9_]*|"
    r"__mcsema[A-Za-z0-9_]*|__brighten[A-Za-z0-9_]*)\b"
)
_PRINTABLE_STRING = re.compile(rb"[\x20-\x7e]{4,}")


def _strip_comments(text: str) -> str:
    return _LINE_COMMENT.sub("", _BLOCK_COMMENT.sub("", text))


def _max_brace_depth(text: str) -> int:
    depth = maximum = 0
    in_string = False
    escaped = False
    for char in text:
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
            maximum = max(maximum, depth)
        elif char == "}":
            depth = max(0, depth - 1)
    return maximum


def extract_c_metrics(path: str | Path) -> Dict[str, Any] | None:
    """Static source indicators; descriptive, not a semantic-quality score."""

    source = Path(path)
    if source.suffix.lower() not in {".c", ".h"} or not source.is_file():
        return None
    text = source.read_text(encoding="utf-8", errors="replace")
    code = _strip_comments(text)
    lines = text.splitlines()
    code_lines = [
        line for line in code.splitlines() if line.strip()
    ]
    functions = _FUNCTION.findall(code)
    decision_count = len(
        re.findall(r"\b(?:if|for|while|case)\b|&&|\|\||\?(?!\?)", code)
    )
    goto_count = len(re.findall(r"\bgoto\b", code))
    label_count = len(
        re.findall(r"(?m)^[ \t]*[A-Za-z_]\w*:[ \t]*(?:$|[^:])", code)
    )
    artifact_count = len(_ARTIFACT.findall(code))
    source_lines = len(code_lines)
    return {
        "byte_count": source.stat().st_size,
        "line_count": len(lines),
        "source_line_count": source_lines,
        "function_count": len(functions),
        "decision_count": decision_count,
        "cyclomatic_complexity": max(1, len(functions)) + decision_count,
        "goto_count": goto_count,
        "label_count": label_count,
        "loop_count": len(re.findall(r"\b(?:for|while|do)\b", code)),
        "switch_count": len(re.findall(r"\bswitch\s*\(", code)),
        "max_brace_nesting": _max_brace_depth(code),
        "decompiler_artifact_count": artifact_count,
        "artifact_density_per_kloc": (
            artifact_count * 1000 / source_lines if source_lines else None
        ),
    }


def extract_binary_metrics(path: str | Path) -> Dict[str, Any] | None:
    """Format-agnostic binary characteristics, kept separate from IR counts."""

    source = Path(path)
    if not source.is_file():
        return None
    payload = source.read_bytes()
    if not payload:
        return {
            "size_bytes": 0,
            "entropy_bits_per_byte": 0.0,
            "printable_string_count": 0,
            "printable_string_bytes": 0,
            "zero_byte_fraction": 0.0,
        }
    counts = Counter(payload)
    entropy = -sum(
        (count / len(payload)) * math.log2(count / len(payload))
        for count in counts.values()
    )
    strings = _PRINTABLE_STRING.findall(payload)
    return {
        "size_bytes": len(payload),
        "entropy_bits_per_byte": entropy,
        "printable_string_count": len(strings),
        "printable_string_bytes": sum(len(item) for item in strings),
        "zero_byte_fraction": payload.count(0) / len(payload),
    }


def median_summary(
    rows: Iterable[Dict[str, Any]],
    *,
    group_key: str,
    metric_names: Iterable[str],
) -> Dict[str, Dict[str, float | int | None]]:
    grouped: Dict[str, list[Dict[str, Any]]] = {}
    for row in rows:
        grouped.setdefault(str(row[group_key]), []).append(row)
    summary: Dict[str, Dict[str, float | int | None]] = {}
    for group, items in sorted(grouped.items()):
        values: Dict[str, float | int | None] = {"n": len(items)}
        for metric in metric_names:
            observed = [
                float(item[metric])
                for item in items
                if item.get(metric) is not None
            ]
            values[f"median_{metric}"] = (
                median(observed) if observed else None
            )
        summary[group] = values
    return summary
