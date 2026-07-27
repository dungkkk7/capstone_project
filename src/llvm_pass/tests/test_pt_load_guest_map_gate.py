#!/usr/bin/env python3
"""Production gate for the experimental PT_LOAD GuestAddressMap path."""

import importlib.util
import os
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "llvm_pass" / "britening_ir.py"
SPEC = importlib.util.spec_from_file_location("britening_ir", MODULE_PATH)
BRIGHTEN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BRIGHTEN)


class PTLoadGuestMapGateTest(unittest.TestCase):
    def test_default_is_off_and_does_not_inject(self):
        with mock.patch.dict(os.environ, {}, clear=True), mock.patch.object(
            BRIGHTEN, "_inject_pt_load_metadata"
        ) as inject:
            path, tempdir = BRIGHTEN._maybe_inject_pt_load_metadata(
                "input.bc", "input.elf"
            )
        self.assertEqual((path, tempdir), ("input.bc", None))
        inject.assert_not_called()

    def test_explicit_opt_in_is_the_only_injection_path(self):
        with mock.patch.dict(
            os.environ, {"BRIGHTEN_ENABLE_PT_LOAD_MAP": "1"}, clear=True
        ), mock.patch.object(
            BRIGHTEN, "_inject_pt_load_metadata", return_value=("pt.bc", "tmp")
        ) as inject:
            self.assertEqual(
                BRIGHTEN._maybe_inject_pt_load_metadata("input.bc", "input.elf"),
                ("pt.bc", "tmp"),
            )
        inject.assert_called_once_with("input.bc", "input.elf")


if __name__ == "__main__":
    unittest.main()
