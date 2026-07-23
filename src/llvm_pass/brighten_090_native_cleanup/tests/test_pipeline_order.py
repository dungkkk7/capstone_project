#!/usr/bin/env python3

import importlib.util
from pathlib import Path


pipeline_file = Path(__file__).resolve().parents[2] / "britening_ir.py"
spec = importlib.util.spec_from_file_location("britening_ir", pipeline_file)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
passes = module.PASS_PIPELINE.split(",")

late_bridge = max(i for i, name in enumerate(passes)
                  if name == "brighten-extern-call-bridge")
cleanup = [i for i, name in enumerate(passes)
           if name == "brighten-native-cleanup-pass"]
final = passes.index("brighten-native-cleanup-final-pass")
late_state = passes.index("brighten-local-state-ssa-pass")
region_unflatten = passes.index("brighten-region-ssa-unflatten-pass")
late_jump_threading = max(i for i, name in enumerate(passes)
                          if name == "jump-threading")
verify = passes.index("verify")

assert len(cleanup) == 2, "production pipeline must have one cleanup retry"
assert cleanup[0] < late_bridge < passes.index("default<O3>") < cleanup[1], (
    "cleanup retry must follow late extern lowering and dispatcher-removing O3"
)
assert cleanup[-1] < final, "the final cleanup pass must follow recovery"
assert cleanup[-1] < late_state < final, (
    "late State promotion must consume cleanup-localized State before reporting"
)
assert late_state < region_unflatten < final, (
    "region-SSA unflattening must consume promoted state before final reporting"
)
assert region_unflatten < late_jump_threading < final < verify, (
    "late CFG simplification must precede the final proof/report gate"
)
assert final + 1 == verify, (
    "no mutation pass may run after the final native contract report"
)
