#!/usr/bin/env python3

import importlib.util
import os
from pathlib import Path


pipeline_file = Path(__file__).resolve().parents[2] / "britening_ir.py"
ownership_file = Path(__file__).resolve().parents[1] / "OWNERSHIP.md"

assert ownership_file.is_file(), "090 ownership boundary must be documented"
ownership = ownership_file.read_text(encoding="utf-8")
for required in (
    "lowerNativeStateABI",
    "compactProven*FrameBackings",
    "rewriteDynamicGuestAddressIntToPtr",
    "normalizeNativeExternalABIs",
    "ambiguous provenance",
):
    assert required in ownership, f"missing 090 ownership rule: {required}"


def load_passes(overrides=None):
    keys = {
        "BRIGHTEN_DISABLE_STACK_FRAME",
        "BRIGHTEN_DISABLE_ABI_RECOVERY",
        "BRIGHTEN_DISABLE_EXTERN_BRIDGE",
        "BRIGHTEN_PASS_PIPELINE",
    }
    saved = {key: os.environ.get(key) for key in keys}
    try:
        for key in keys:
            os.environ.pop(key, None)
        for key, value in (overrides or {}).items():
            os.environ[key] = value
        spec = importlib.util.spec_from_file_location(
            "britening_ir_pipeline_order", pipeline_file
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module.PASS_PIPELINE.split(",")
    finally:
        for key, value in saved.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value


passes = load_passes()

split_spec = importlib.util.spec_from_file_location(
    "britening_ir_split_boundary", pipeline_file
)
split_module = importlib.util.module_from_spec(split_spec)
split_spec.loader.exec_module(split_module)
assert split_module.late_address_canonicalize_index([
    "early", "brighten-address-canonicalize", "mid",
    "brighten-address-canonicalize",
]) == 3, "orchestration must checkpoint the final 080 canonicalizer"

cleanup = [i for i, name in enumerate(passes)
           if name == "brighten-native-cleanup-pass"]
final = passes.index("brighten-native-cleanup-final-pass")
deobfuscate = passes.index("095")
late_devirt = passes.index("brighten-devirt-pass", deobfuscate + 1)
late_stack = passes.index("brighten-stack-frame-pass", deobfuscate + 1)
late_abi = passes.index("brighten-abi-recovery-pass", deobfuscate + 1)
late_bridge = passes.index("brighten-extern-call-bridge", deobfuscate + 1)
late_residual_strings = passes.index(
    "brighten-late-residual-format-string-recovery", late_bridge + 1
)
late_type = passes.index("brighten-type-reconstruct", deobfuscate + 1)
dfa = passes.index("dfa-jump-threading", deobfuscate + 1)
late_state = passes.index("brighten-local-state-ssa-pass")
region_unflatten = passes.index("brighten-region-ssa-unflatten-pass")
address_canonicalize = [i for i, name in enumerate(passes)
                        if name == "brighten-address-canonicalize"]
post_state_frame = passes.index("brighten-post-state-frame-pass")
late_jump_threading = max(i for i, name in enumerate(passes)
                          if name == "jump-threading")
o3 = [i for i, name in enumerate(passes) if name == "default<O3>"]
verify = passes.index("verify")

assert len(cleanup) == 2, "production pipeline must have one cleanup retry"
assert len(o3) == 2, "production pipeline must have mid-pipeline and tail O3"
assert (
    cleanup[0]
    < deobfuscate
    < late_devirt
    < late_stack
    < late_abi
    < late_bridge
    < late_type
), "post-095 owner passes must rerun in dependency order"
assert late_type < dfa < o3[0] < cleanup[1] < final, (
    "cleanup retry must follow late owner recovery and CFG/O3 cleanup"
)
for cleanup_index in cleanup:
    abi_after_cleanup = passes.index("brighten-abi-recovery-pass", cleanup_index + 1)
    bridge_after_abi = passes.index("brighten-extern-call-bridge",
                                    abi_after_cleanup + 1)
    assert bridge_after_abi < final, (
        "every post-cleanup materialized ABI producer must have its "
        "050 ABI recovery and 060 extern bridge consumers before reporting"
    )
assert passes[cleanup[1] + 1:cleanup[1] + 4] == [
    "brighten-abi-recovery-pass", "brighten-extern-call-bridge",
    "brighten-late-residual-format-string-recovery",
], "the post-mid-O3 cleanup producer must feed 050, 060, then late 070 format recovery"
assert late_bridge < late_residual_strings < late_state, (
    "late residual format recovery must consume 060 direct ABI calls before "
    "resolver/local-state cleanup"
)
assert cleanup[-1] < final, "the final cleanup pass must follow recovery"
assert cleanup[-1] < late_state < final, (
    "late State promotion must consume cleanup-localized State before reporting"
)
assert late_state < region_unflatten < final, (
    "region-SSA unflattening must consume promoted state before final reporting"
)
heap_resolver = passes.index("brighten-heap-proven-resolver-collapse")
assert len(address_canonicalize) == 4, (
    "address canonicalization must precede both ordinary 040 frame passes and "
    "the post-State 040 consumer"
)
early_stack = passes.index("brighten-stack-frame-pass")
assert address_canonicalize[0] < early_stack, (
    "080 address canonicalization must expose frame offsets before initial 040"
)
assert (region_unflatten < address_canonicalize[-2] < late_jump_threading
        < o3[1] < address_canonicalize[-1]
        < post_state_frame < heap_resolver
        < passes.index("dce", heap_resolver + 1)
        < passes.index("globaldce", heap_resolver + 1) < final
        < verify), (
    "heap resolver recovery must consume final 040 pointer slots before reporting"
)
assert final + 1 == verify, (
    "no mutation pass may run after the final native contract report"
)

disabled_passes = {
    "BRIGHTEN_DISABLE_ABI_RECOVERY": "brighten-abi-recovery-pass",
    "BRIGHTEN_DISABLE_EXTERN_BRIDGE": "brighten-extern-call-bridge",
}
for env_name, pass_name in disabled_passes.items():
    assert pass_name not in load_passes({env_name: "true"}), (
        f"{env_name} must disable every early and post-095 {pass_name} rerun"
    )

stack_disabled = load_passes({"BRIGHTEN_DISABLE_STACK_FRAME": "true"})
assert "brighten-stack-frame-pass" not in stack_disabled, (
    "BRIGHTEN_DISABLE_STACK_FRAME must disable every early and post-095 stack pass rerun"
)
assert "brighten-post-state-frame-pass" not in stack_disabled, (
    "BRIGHTEN_DISABLE_STACK_FRAME must disable dedicated post-State frame recovery"
)

assert load_passes({
    "BRIGHTEN_DISABLE_STACK_FRAME": "1",
    "BRIGHTEN_PASS_PIPELINE": "verify",
}) == ["verify"], "an explicit pipeline override must retain precedence"
