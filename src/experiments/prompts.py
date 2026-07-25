from __future__ import annotations

from dataclasses import dataclass

from .enums import MethodId
from .storage import sha256_text


B0_PROMPT_POLICY_VERSION = "b0-minimal-ghidra-one-shot-v1"

ONE_SHOT_SYSTEM_PROMPT = """You are a highly skilled reverse engineer specializing in binary deobfuscation and C reconstruction.
Recover exactly one complete Linux-compilable C11 source file that preserves the observable behavior represented by the supplied low-level program representation.

Requirements:
1. Include main and every required user-defined function.
2. Include required standard headers, declarations, globals, constants, and helpers.
3. Do not omit behavior, use placeholders, or hard-code known test outputs.
4. Return C source only, without Markdown fences or explanations."""

B0_MINIMAL_SYSTEM_PROMPT = """You are a highly skilled reverse engineer specializing in binary deobfuscation and C reconstruction.
Recover exactly one complete Linux-compilable C11 source file that preserves the observable behavior represented by the supplied low-level program representation.
Requirements:
1. Return C source only, without Markdown fences or explanations."""

B0_USER_TEMPLATE = """Representation type: decompiler-generated pseudocode from an OLLVM-obfuscated binary.
<OBFUSCATED_PSEUDOCODE>
{GHIDRA_PSEUDOCODE}
</OBFUSCATED_PSEUDOCODE>"""

A0_USER_TEMPLATE = """Representation type: raw LLVM IR lifted from an OLLVM-obfuscated binary by McSema.
No custom deobfuscation, control-flow recovery, type recovery, cleanup, or LLVM optimization has been applied.
Recover one complete Linux-compilable C11 source file that preserves the observable behavior of the represented program.
<RAW_LIFTED_LLVM_IR>
{RAW_LLVM_IR}
</RAW_LIFTED_LLVM_IR>"""


@dataclass(frozen=True)
class PromptBundle:
    method: MethodId
    system_prompt: str
    user_prompt: str
    policy_version: str

    @property
    def system_prompt_sha256(self) -> str:
        return sha256_text(self.system_prompt)

    @property
    def user_prompt_sha256(self) -> str:
        return sha256_text(self.user_prompt)


def build_one_shot_prompt(method: MethodId, representation: str) -> PromptBundle:
    if method is MethodId.B0:
        user = B0_USER_TEMPLATE.replace(
            "{GHIDRA_PSEUDOCODE}", representation
        )
        system = B0_MINIMAL_SYSTEM_PROMPT
        version = B0_PROMPT_POLICY_VERSION
    elif method is MethodId.A0:
        user = A0_USER_TEMPLATE.replace("{RAW_LLVM_IR}", representation)
        system = ONE_SHOT_SYSTEM_PROMPT
        version = "a0-raw-mcsema-v1"
    else:
        raise ValueError(f"One-shot prompt is only defined for A0/B0, got {method}")
    return PromptBundle(method, system, user, version)


def prompt_policy_manifest(method: MethodId) -> dict[str, str]:
    if method is MethodId.B0:
        template = B0_USER_TEMPLATE
        system = B0_MINIMAL_SYSTEM_PROMPT
        version = B0_PROMPT_POLICY_VERSION
        provenance_note = (
            "Predeclared minimal Ghidra-only one-shot baseline. It intentionally "
            "does not receive P0's dual-evidence reasoning protocol, compiler "
            "diagnostics, or differential-fuzz feedback."
        )
    else:
        template = A0_USER_TEMPLATE
        system = ONE_SHOT_SYSTEM_PROMPT
        version = "a0-raw-mcsema-v1"
        provenance_note = "Group-designed raw lifted-IR prompt."
    return {
        "policy_version": version,
        "system_prompt_sha256": sha256_text(system),
        "user_template_sha256": sha256_text(template),
        "provenance_note": provenance_note,
    }
