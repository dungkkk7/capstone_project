import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from llm_recovery.llm_recovery import (
    RecoveryConfig,
    RecoveryError,
    _recovery_attachment_paths,
    _format_fuzz_feedback,
    _validate_request_input_budget,
    _vertex_api_base_url,
    _vertex_generation_config,
    _vertex_inline_mime_type,
    build_repair_prompt,
)


class VertexEndpointTests(unittest.TestCase):
    def test_gemini_35_defaults_to_global_endpoint(self):
        with patch.dict(os.environ, {}, clear=True):
            config = RecoveryConfig()

        self.assertEqual(config.model, "gemini-3.5-flash")
        self.assertEqual(config.location, "global")
        self.assertEqual(config.thinking_level, "HIGH")
        self.assertEqual(config.max_ir_chars, 600000)
        self.assertEqual(config.max_request_input_bytes, 900000)
        self.assertFalse(config.attach_ir_with_ghidra)
        self.assertEqual(
            _vertex_api_base_url(config.location),
            "https://aiplatform.googleapis.com",
        )

    def test_default_generation_config_uses_high_thinking(self):
        with patch.dict(os.environ, {}, clear=True):
            generation_config = _vertex_generation_config(RecoveryConfig())

        self.assertEqual(generation_config["thinkingConfig"], {"thinkingLevel": "HIGH"})
        self.assertEqual(generation_config["maxOutputTokens"], 65535)

    def test_invalid_thinking_level_is_rejected(self):
        with self.assertRaisesRegex(RecoveryError, "Invalid LLM_RECOVERY_THINKING_LEVEL"):
            _vertex_generation_config(RecoveryConfig(thinking_level="max"))

    def test_multi_region_endpoint_uses_rep_hostname(self):
        self.assertEqual(
            _vertex_api_base_url("us"),
            "https://aiplatform.us.rep.googleapis.com",
        )
        self.assertEqual(
            _vertex_api_base_url("eu"),
            "https://aiplatform.eu.rep.googleapis.com",
        )

    def test_legacy_regional_endpoint_is_preserved(self):
        self.assertEqual(
            _vertex_api_base_url("us-central1"),
            "https://us-central1-aiplatform.googleapis.com",
        )

    def test_pseudocode_is_text_but_raw_binary_is_rejected(self):
        self.assertEqual(_vertex_inline_mime_type(Path("ghidra.c")), "text/plain")
        self.assertEqual(_vertex_inline_mime_type(Path("brightened.ll")), "text/plain")
        with self.assertRaisesRegex(RecoveryError, "application/octet-stream"):
            _vertex_inline_mime_type(Path("brightened_ref.bin"))

    def test_ghidra_mode_does_not_duplicate_full_ir_by_default(self):
        with tempfile.TemporaryDirectory() as directory:
            pseudo = Path(directory) / "ghidra.c"
            ir = Path(directory) / "brightened.ll"
            pseudo.write_text("int main(void) { return 0; }", encoding="utf-8")
            ir.write_text("define i32 @main() { ret i32 0 }", encoding="utf-8")
            config = RecoveryConfig(use_file_api=True)
            self.assertEqual(
                _recovery_attachment_paths(
                    True, config, str(pseudo), {"input_ir": str(ir)}
                ),
                [str(pseudo)],
            )
            config.attach_ir_with_ghidra = True
            self.assertEqual(
                _recovery_attachment_paths(
                    True, config, str(pseudo), {"input_ir": str(ir)}
                ),
                [str(pseudo), str(ir)],
            )

    def test_repair_prompt_clips_candidate_and_feedback_independently(self):
        prompt = build_repair_prompt(
            "define i32 @main() { ret i32 0 }",
            "C" * 1000,
            "F" * 1000,
            100,
            max_candidate_chars=120,
            max_feedback_chars=80,
        )
        self.assertIn("candidate source clipped by adapter", prompt)
        self.assertIn("validation feedback clipped by adapter", prompt)
        self.assertLess(len(prompt), 5000)

    def test_request_budget_rejects_oversize_before_vertex_call(self):
        self.assertEqual(_validate_request_input_budget(400, 500, 900), 900)
        with self.assertRaisesRegex(RecoveryError, "selected_input=901 bytes"):
            _validate_request_input_budget(401, 500, 900)

    def test_fuzz_feedback_includes_actionable_crash_details(self):
        feedback = _format_fuzz_feedback({
            "matches": 95,
            "mismatches": 5,
            "inconclusive": 0,
            "equivalence_ratio": 95.0,
            "mismatch_examples": [{
                "index": 7,
                "args": ["--mode", "2"],
                "stdin": "42\n",
                "reason": "Execution status mismatch: crash vs success",
                "prog1": {
                    "status": "crash", "returncode": -11, "signal": 11,
                    "stdout": "", "stderr": "segmentation fault",
                },
                "prog2": {
                    "status": "success", "returncode": 0,
                    "stdout": "42\n", "stderr": "",
                },
            }],
        })
        self.assertIn("Execution status mismatch", feedback)
        self.assertIn("signal=11", feedback)
        self.assertIn("args=['--mode', '2']", feedback)


if __name__ == "__main__":
    unittest.main()
