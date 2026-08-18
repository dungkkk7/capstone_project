"""Frozen protocol for the primary two-flow source-recovery experiment.

The historical six-flow campaign remains readable as an archived ablation, but
new primary campaigns compare exactly two systems:

* B0: original obfuscated ELF -> Ghidra pseudocode -> one LLM call.
* F3: original obfuscated ELF -> McSema/custom LLVM pipeline -> Clean IR ->
  iterative LLM recovery with compiler and reproducible behavioral feedback.

B0 follows the GPT-4o refinement baseline described in Section 4.2.1 of
LLM4Decompile (Tan et al., EMNLP 2024, arXiv:2403.05286v3).  The paper prints
the instruction below verbatim.  We append the Ghidra snippet without adding
task hints, test cases, compiler diagnostics, or repair feedback.
"""

from __future__ import annotations

import hashlib
from dataclasses import asdict, dataclass
from typing import Final


PROTOCOL_VERSION: Final = "two-flow-b0-f3-v1"
LLM4DECOMPILE_PAPER_URL: Final = "https://arxiv.org/abs/2403.05286v3"
LLM4DECOMPILE_SECTION: Final = "4.2.1"
LLM4DECOMPILE_ASSEMBLY_SECTION: Final = "4.1.1"
LLM4DECOMPILE_OFFICIAL_REPOSITORY: Final = (
    "https://github.com/albertan017/LLM4Decompile"
)

# Printed verbatim in LLM4Decompile, Section 4.2.1.  Preserve capitalization
# and punctuation so future campaigns can prove prompt identity by hash.
LLM4DECOMPILE_B0_INSTRUCTION: Final = (
    "Generate linux compilable C/C++ code of the main and other functions "
    "in the supplied snippet without using goto, fix any missing headers. "
    "Do not explain anything."
)
LLM4DECOMPILE_ASSEMBLY_BEFORE: Final = "# This is the assembly code:\n"
LLM4DECOMPILE_ASSEMBLY_AFTER: Final = "\n# What is the source code?\n"


@dataclass(frozen=True)
class PrimaryFlow:
    flow_id: str
    name: str
    model_input: str
    provider_call_budget: int
    compiler_feedback: bool
    behavioral_feedback: bool
    contribution_role: str


PRIMARY_FLOWS: Final = {
    "B0": PrimaryFlow(
        flow_id="B0",
        name="LLM4DECOMPILE_GHIDRA_ONESHOT",
        model_input="program-level Ghidra pseudocode from the original obfuscated ELF",
        provider_call_budget=1,
        compiler_feedback=False,
        behavioral_feedback=False,
        contribution_role="external baseline",
    ),
    "F3": PrimaryFlow(
        flow_id="F3",
        name="CLEAN_IR_ITERATIVE_MAIN",
        model_input="clean LLVM IR produced by the custom deobfuscation pipeline",
        provider_call_budget=5,
        compiler_feedback=True,
        behavioral_feedback=True,
        contribution_role="proposed method",
    ),
}

PRIMARY_FLOW_ORDER: Final = ("B0", "F3")

# B1 is an explicit ablation, not a replacement for either primary flow.  Its
# first request is byte-identical to B0; only subsequent requests may consume
# compiler diagnostics or reproducible behavioral counterexamples.  Keeping it
# outside PRIMARY_FLOWS preserves the frozen B0-versus-F3 primary claim.
B1_GHIDRA_ITERATIVE: Final = PrimaryFlow(
    flow_id="B1",
    name="LLM4DECOMPILE_GHIDRA_ITERATIVE",
    model_input="program-level Ghidra pseudocode from the original obfuscated ELF",
    provider_call_budget=5,
    compiler_feedback=True,
    behavioral_feedback=True,
    contribution_role="feedback-policy ablation on the B0 representation",
)

# B2 follows the paper's End2End input representation and released inference
# serialization.  The official demo extracts one function; our unit of
# evaluation is a complete CLI program, so the same objdump cleaning rule is
# applied to every function in the original ELF.  B3 holds that representation
# and first request fixed while adding the registered validation loop.
B2_ASSEMBLY_ONESHOT: Final = PrimaryFlow(
    flow_id="B2",
    name="LLM4DECOMPILE_ASSEMBLY_ONESHOT",
    model_input="program-level cleaned objdump assembly from the original obfuscated ELF",
    provider_call_budget=1,
    compiler_feedback=False,
    behavioral_feedback=False,
    contribution_role="paper-derived End2End assembly comparator",
)
B3_ASSEMBLY_ITERATIVE: Final = PrimaryFlow(
    flow_id="B3",
    name="LLM4DECOMPILE_ASSEMBLY_ITERATIVE",
    model_input="program-level cleaned objdump assembly from the original obfuscated ELF",
    provider_call_budget=5,
    compiler_feedback=True,
    behavioral_feedback=True,
    contribution_role="feedback-policy ablation on the B2 representation",
)

EVALUATION_FLOWS: Final = {
    "B0": PRIMARY_FLOWS["B0"],
    "B1": B1_GHIDRA_ITERATIVE,
    "B2": B2_ASSEMBLY_ONESHOT,
    "B3": B3_ASSEMBLY_ITERATIVE,
    "F3": PRIMARY_FLOWS["F3"],
}
EVALUATION_FLOW_ORDER: Final = ("B0", "B1", "B2", "B3", "F3")


def build_b0_prompt(ghidra_pseudocode: str) -> str:
    """Return the frozen paper-derived B0 request.

    The paper specifies the instruction but not a serialized API envelope.
    This protocol uses one blank line followed by the unmodified Ghidra export.
    That serialization choice is group-owned and recorded separately from the
    cited instruction.
    """

    if not ghidra_pseudocode.strip():
        raise ValueError("B0 requires non-empty Ghidra pseudocode")
    return f"{LLM4DECOMPILE_B0_INSTRUCTION}\n\n{ghidra_pseudocode}"


def build_b2_prompt(program_assembly: str) -> str:
    """Return the assembly prompt serialized by the official implementation."""
    if not program_assembly.strip():
        raise ValueError("B2 requires non-empty objdump assembly")
    return (
        LLM4DECOMPILE_ASSEMBLY_BEFORE
        + program_assembly.strip()
        + LLM4DECOMPILE_ASSEMBLY_AFTER
    )


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def protocol_manifest() -> dict:
    return {
        "protocol_version": PROTOCOL_VERSION,
        "primary_flow_order": list(PRIMARY_FLOW_ORDER),
        "flows": {key: asdict(value) for key, value in PRIMARY_FLOWS.items()},
        "baseline_prompt": {
            "instruction": LLM4DECOMPILE_B0_INSTRUCTION,
            "instruction_sha256": sha256_text(LLM4DECOMPILE_B0_INSTRUCTION),
            "source": LLM4DECOMPILE_PAPER_URL,
            "source_section": LLM4DECOMPILE_SECTION,
            "serialization": "instruction + two LF bytes + raw Ghidra export",
            "system_instruction": None,
        },
        "historical_six_flow_role": (
            "archived exploratory ablation; excluded from the primary claim"
        ),
        "registered_ablations": {
            "B1": {
                **asdict(B1_GHIDRA_ITERATIVE),
                "initial_request": "byte-identical B0 prompt with no system instruction",
                "initial_system_instruction": None,
                "later_requests": (
                    "same Ghidra evidence plus compiler diagnostics or reproducible "
                    "behavioral counterexamples"
                ),
                "causal_question": (
                    "effect of adding iterative validation feedback while holding "
                    "the B0 representation and initial request fixed"
                ),
            },
            "B2": {
                **asdict(B2_ASSEMBLY_ONESHOT),
                "input_builder": "objdump -d followed by the official byte/comment cleaner",
                "program_level_extension": (
                    "the official demo extracts one function; this evaluation keeps all "
                    "functions because the oracle unit is a complete command-line program"
                ),
                "prompt_before": LLM4DECOMPILE_ASSEMBLY_BEFORE,
                "prompt_after": LLM4DECOMPILE_ASSEMBLY_AFTER,
                "initial_system_instruction": None,
                "paper_section": LLM4DECOMPILE_ASSEMBLY_SECTION,
                "official_repository": LLM4DECOMPILE_OFFICIAL_REPOSITORY,
            },
            "B3": {
                **asdict(B3_ASSEMBLY_ITERATIVE),
                "initial_request": "byte-identical B2 prompt with no system instruction",
                "initial_system_instruction": None,
                "later_requests": (
                    "same assembly evidence plus parser/compiler diagnostics or "
                    "reproducible behavioral counterexamples"
                ),
                "causal_question": (
                    "effect of adding iterative validation feedback while holding "
                    "the B2 representation and initial request fixed"
                ),
            },
        },
    }
