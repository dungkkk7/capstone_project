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
final_sroa = max(i for i, name in enumerate(passes) if name == "sroa")
final_mem2reg = max(i for i, name in enumerate(passes) if name == "mem2reg")
final_instcombine = max(i for i, name in enumerate(passes)
                        if name == "instcombine<no-verify-fixpoint>")
late_devirt = max(i for i, name in enumerate(passes)
                  if name == "brighten-devirt-pass")

assert len(cleanup) == 2, "production pipeline must have one cleanup retry"
assert late_devirt < cleanup[0], (
    "late devirtualization must consume optimizer-exposed immutable PC tables "
    "before State/native cleanup"
)
assert cleanup[0] < late_bridge < passes.index("default<O3>") < cleanup[1], (
    "cleanup retry must follow late extern lowering and dispatcher-removing O3"
)
assert cleanup[-1] < final, "the final cleanup pass must remain report-only"
assert cleanup[-1] < late_state < final, (
    "late State promotion must consume cleanup-localized State before reporting"
)
assert late_state < region_unflatten < final, (
    "region-SSA unflattening must consume promoted state before final reporting"
)
assert region_unflatten < final_sroa < final_mem2reg < final_instcombine < final, (
    "the final scalarization must consume State allocas exposed by cleanup "
    "and fold partial aggregate scaffolding before native-contract reporting"
)
