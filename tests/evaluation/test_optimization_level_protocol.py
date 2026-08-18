import importlib.util
import os
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[2]
MODULE = ROOT / "src" / "llvm_pass" / "britening_ir.py"


def load(level):
    saved = os.environ.get("BRIGHTEN_OPT_LEVEL")
    try:
        if level is None:
            os.environ.pop("BRIGHTEN_OPT_LEVEL", None)
        else:
            os.environ["BRIGHTEN_OPT_LEVEL"] = level
        spec = importlib.util.spec_from_file_location(f"brighten_{level}", MODULE)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        if saved is None:
            os.environ.pop("BRIGHTEN_OPT_LEVEL", None)
        else:
            os.environ["BRIGHTEN_OPT_LEVEL"] = saved


@pytest.mark.parametrize("level", ["O1", "O2", "O3"])
def test_standard_optimization_treatment_is_explicit_and_repeated(level):
    module = load(level)
    assert module.PASS_PIPELINE.split(",").count(f"default<{level}>") == 2
    for other in {"O1", "O2", "O3"} - {level}:
        assert f"default<{other}>" not in module.PASS_PIPELINE


def test_invalid_optimization_level_fails_closed():
    with pytest.raises(ValueError, match="must be one of O1, O2, O3"):
        load("Oz")
