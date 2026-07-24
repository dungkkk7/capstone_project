import os
import sys
import types
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from llm_recovery.llm_recovery import (
    LLMRateLimitError,
    RecoveryConfig,
    RecoveryError,
    VertexGemini,
    _vertex_api_base_url,
    _vertex_generation_config,
    _vertex_inline_mime_type,
)


class VertexEndpointTests(unittest.TestCase):
    def test_gemini_25_pro_defaults_to_global_endpoint(self):
        with patch.dict(os.environ, {}, clear=True):
            config = RecoveryConfig()

        self.assertEqual(config.model, "gemini-2.5-pro")
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

    def test_rest_request_preserves_system_instruction_role(self):
        captured = {}

        class Response:
            status_code = 200

            def json(self):
                return {
                    "candidates": [
                        {
                            "finishReason": "STOP",
                            "content": {"parts": [{"text": "int main(void){return 0;}"}]},
                        }
                    ],
                    "usageMetadata": {},
                }

        def post(url, json, headers, timeout):
            captured["payload"] = json
            return Response()

        requests_module = types.SimpleNamespace(post=post)
        client = VertexGemini(
            RecoveryConfig(project="test-project", use_file_api=False)
        )
        with patch.dict(sys.modules, {"requests": requests_module}), patch(
            "llm_recovery.llm_recovery._load_adc_credentials",
            return_value={"quota_project_id": "test-project"},
        ), patch(
            "llm_recovery.llm_recovery._request_access_token_via_refresh",
            return_value="token",
        ):
            response = client._generate_rest(
                "USER",
                system_instruction="SYSTEM",
            )

        self.assertIn("int main", response)
        self.assertEqual(
            captured["payload"]["systemInstruction"],
            {"parts": [{"text": "SYSTEM"}]},
        )
        self.assertEqual(
            captured["payload"]["contents"][0]["parts"],
            [{"text": "USER"}],
        )

    def test_rest_429_preserves_retry_after(self):
        class Response:
            status_code = 429
            text = '{"error":{"status":"RESOURCE_EXHAUSTED"}}'
            headers = {"Retry-After": "3600"}

        requests_module = types.SimpleNamespace(
            post=lambda *args, **kwargs: Response()
        )
        client = VertexGemini(
            RecoveryConfig(project="test-project", use_file_api=False)
        )
        with patch.dict(sys.modules, {"requests": requests_module}), patch(
            "llm_recovery.llm_recovery._load_adc_credentials",
            return_value={"quota_project_id": "test-project"},
        ), patch(
            "llm_recovery.llm_recovery._request_access_token_via_refresh",
            return_value="token",
        ):
            with self.assertRaises(LLMRateLimitError) as raised:
                client._generate_rest("USER")

        self.assertEqual(raised.exception.status_code, 429)
        self.assertEqual(raised.exception.retry_after_seconds, 3600)


if __name__ == "__main__":
    unittest.main()
