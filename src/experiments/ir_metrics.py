from __future__ import annotations

import math
import re
from collections import Counter
from pathlib import Path
from typing import Any, Dict


_LABEL = re.compile(r"^\s*(?:[-a-zA-Z$._0-9]+|\d+):(?:\s*;.*)?$")
_TARGET = re.compile(r"\blabel\s+%[-a-zA-Z$._0-9]+")
_OPCODE = re.compile(
    r"^(?:%[-a-zA-Z$._0-9]+\s*=\s*)?"
    r"(?P<opcode>[a-z][a-z0-9._]*)\b"
)
_INDIRECT_CALL = re.compile(
    r"\b(?:call|invoke)\b(?![^@\n]*@[A-Za-z$._][-A-Za-z$._0-9]*)"
)
_HELPER = re.compile(
    r"\b(?:__remill|__mcsema|__brighten|frame_storage|"
    r"lifted_|remill_|mcsema_)[A-Za-z0-9_.$]*",
    re.IGNORECASE,
)


def _safe_ratio(numerator: int | float, denominator: int | float) -> float | None:
    return float(numerator) / float(denominator) if denominator else None


def extract_ir_metrics(path: str | Path) -> Dict[str, Any] | None:
    """Extract reproducible structural/deobfuscation indicators from LLVM IR."""

    source = Path(path)
    if source.suffix.lower() != ".ll" or not source.is_file():
        return None
    text = source.read_text(encoding="utf-8", errors="replace")
    function_count = declaration_count = global_count = 0
    basic_blocks = instructions = cfg_edges = 0
    in_function = False
    saw_block_in_function = False
    opcodes: Counter[str] = Counter()
    helper_names = set(_HELPER.findall(text))

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line.startswith("define "):
            function_count += 1
            in_function = True
            saw_block_in_function = False
            continue
        if line.startswith("declare "):
            declaration_count += 1
            continue
        if not in_function and line.startswith("@") and "=" in line:
            global_count += 1
            continue
        if in_function and line == "}":
            if not saw_block_in_function:
                basic_blocks += 1
            in_function = False
            continue
        if not in_function or not line or line.startswith(";"):
            continue
        if _LABEL.match(raw_line):
            basic_blocks += 1
            saw_block_in_function = True
            continue
        if line.startswith(("!", "attributes ")):
            continue
        instructions += 1
        match = _OPCODE.match(line)
        if match:
            opcodes[match.group("opcode")] += 1
        if line.startswith(("br ", "switch ", "indirectbr ", "invoke ")):
            cfg_edges += len(_TARGET.findall(line))

    conditional_branch_count = sum(
        1
        for line in text.splitlines()
        if re.search(r"^\s*br\s+i1\b", line)
    )
    switch_count = opcodes["switch"]
    indirect_branch_count = opcodes["indirectbr"]
    call_count = opcodes["call"] + opcodes["invoke"]
    indirect_call_count = len(_INDIRECT_CALL.findall(text))
    decision_cyclomatic = (
        function_count
        + conditional_branch_count
        + switch_count
        + indirect_branch_count
    )
    cyclomatic = max(
        function_count,
        decision_cyclomatic,
        cfg_edges - basic_blocks + 2 * function_count,
    )
    helper_reference_count = len(_HELPER.findall(text))
    entropy = 0.0
    if instructions:
        for count in opcodes.values():
            probability = count / instructions
            entropy -= probability * math.log2(probability)

    return {
        "byte_count": source.stat().st_size,
        "line_count": len(text.splitlines()),
        "function_count": function_count,
        "declaration_count": declaration_count,
        "global_count": global_count,
        "basic_block_count": basic_blocks,
        "instruction_count": instructions,
        "cfg_edge_count": cfg_edges,
        "cyclomatic_complexity": cyclomatic,
        "conditional_branch_count": conditional_branch_count,
        "switch_count": switch_count,
        "indirect_branch_count": indirect_branch_count,
        "call_count": call_count,
        "indirect_call_count": indirect_call_count,
        "phi_count": opcodes["phi"],
        "select_count": opcodes["select"],
        "alloca_count": opcodes["alloca"],
        "load_count": opcodes["load"],
        "store_count": opcodes["store"],
        "unreachable_count": opcodes["unreachable"],
        "helper_reference_count": helper_reference_count,
        "unique_helper_count": len(helper_names),
        "helper_references_per_kinst": (
            _safe_ratio(helper_reference_count * 1000, instructions)
        ),
        "branch_density": _safe_ratio(
            conditional_branch_count + switch_count + indirect_branch_count,
            instructions,
        ),
        "cfg_edge_density": _safe_ratio(cfg_edges, basic_blocks),
        "opcode_entropy_bits": entropy,
    }
