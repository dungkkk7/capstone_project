from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Dict


_LABEL = re.compile(r"^\s*(?:[-a-zA-Z$._0-9]+|\d+):(?:\s*;.*)?$")
_TARGET = re.compile(r"\blabel\s+%[-a-zA-Z$._0-9]+")


def extract_ir_metrics(path: str | Path) -> Dict[str, int] | None:
    source = Path(path)
    if source.suffix.lower() != ".ll" or not source.is_file():
        return None
    function_count = basic_blocks = instructions = cfg_edges = 0
    in_function = False
    for raw_line in source.read_text(
        encoding="utf-8", errors="replace"
    ).splitlines():
        line = raw_line.strip()
        if line.startswith("define "):
            function_count += 1
            in_function = True
            continue
        if in_function and line == "}":
            in_function = False
            continue
        if not in_function or not line or line.startswith(";"):
            continue
        if _LABEL.match(raw_line):
            basic_blocks += 1
            continue
        if line.startswith(("!", "attributes ", "declare ")):
            continue
        instructions += 1
        if line.startswith(("br ", "switch ", "indirectbr ")):
            cfg_edges += len(_TARGET.findall(line))
    return {
        "function_count": function_count,
        "basic_block_count": basic_blocks,
        "instruction_count": instructions,
        "cfg_edge_count": cfg_edges,
    }
