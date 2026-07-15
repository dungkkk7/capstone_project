import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from llm_recovery.llm_recovery import (
    RecoveryConfig,
    RecoveryError,
    _vertex_api_base_url,
    _vertex_generation_config,
    _vertex_inline_mime_type,
)


class VertexEndpointTests(unittest.TestCase):
    def test_gemini_35_defaults_to_global_endpoint(self):
        with patch.dict(os.environ, {}, clear=True):
            config = RecoveryConfig()

        self.assertEqual(config.model, "gemini-3.5-flash")
        self.assertEqual(config.location, "global")
        self.assertEqual(config.thinking_level, "HIGH")
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


if __name__ == "__main__":
    unittest.main()
