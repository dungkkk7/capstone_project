"""Prompt serialization for the five-flow evaluation protocol.

B1/B2 are the paper-derived LLM4Decompile baselines. F1/F2/F3 use the
project's evidence-grounded prompts and differ by artifact and feedback
policy, not by LLVM optimization level.
"""

from __future__ import annotations

import hashlib
from typing import Final


PROTOCOL_VERSION: Final = "five-flow-b1-b2-f1-f2-f3-v1"
LLM4DECOMPILE_PAPER_URL: Final = "https://arxiv.org/abs/2403.05286v3"
LLM4DECOMPILE_GHIDRA_SECTION: Final = "4.2.1"
LLM4DECOMPILE_ASSEMBLY_SECTION: Final = "4.1.1"
LLM4DECOMPILE_OFFICIAL_REPOSITORY: Final = (
    "https://github.com/albertan017/LLM4Decompile"
)
LLM4DECOMPILE_GHIDRA_INSTRUCTION: Final = (
    "Generate linux compilable C/C++ code of the main and other functions "
    "in the supplied snippet without using goto, fix any missing headers. "
    "Do not explain anything."
)
LLM4DECOMPILE_ASSEMBLY_BEFORE: Final = "# This is the assembly code:\n"
LLM4DECOMPILE_ASSEMBLY_AFTER: Final = "\n# What is the source code?\n"


def build_b1_prompt(ghidra_pseudocode: str) -> str:
    if not ghidra_pseudocode.strip():
        raise ValueError("B1 requires non-empty Ghidra pseudocode")
    return f"{LLM4DECOMPILE_GHIDRA_INSTRUCTION}\n\n{ghidra_pseudocode}"


def build_b2_prompt(program_assembly: str) -> str:
    if not program_assembly.strip():
        raise ValueError("B2 requires non-empty objdump assembly")
    return (
        LLM4DECOMPILE_ASSEMBLY_BEFORE
        + program_assembly.strip()
        + LLM4DECOMPILE_ASSEMBLY_AFTER
    )


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()
