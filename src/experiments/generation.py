from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any, Callable, Dict

from llm_recovery.llm_recovery import (
    LLMEmptyResponseError,
    RecoveryConfig,
    RecoveryError,
    VertexGemini,
)

from .enums import MethodId
from .models import GenerationResult, RepresentationArtifact
from .prompts import build_one_shot_prompt, prompt_policy_manifest
from .quota import QuotaController
from .storage import (
    atomic_write_json,
    atomic_write_text,
    sha256_file,
    sha256_text,
    stable_json_sha256,
)


class ContextOverflow(RuntimeError):
    pass


class LeakageError(RuntimeError):
    pass


class CandidateError(RuntimeError):
    pass


class EmptyResponseError(CandidateError):
    def __init__(self, message: str, generation: Dict[str, Any]):
        super().__init__(message)
        self.generation = generation


FORBIDDEN_COMMON = (
    "data/clean_src",
    "/clean_src/",
    "expected_output",
    "semantic_report",
    "counterexample",
    "mismatch_input",
)

FORBIDDEN_BY_METHOD = {
    MethodId.B0: (
        "_brightened",
        "brightened_ref.bin",
        "<raw_lifted_llvm_ir>",
    ),
    MethodId.A0: (
        "ghidra_pseudocode",
        "<obfuscated_pseudocode>",
        "brightened_ref.bin",
        "_brightened.ll",
    ),
}


def estimate_tokens(text: str) -> int:
    """Conservative deterministic estimate used for the pre-request gate.

    Provider-reported token counts are persisted after a successful request.
    Using three UTF-8 bytes per token errs toward rejecting oversized inputs.
    """

    return max(1, (len(text.encode("utf-8")) + 2) // 3)


def _scan_request(
    method: MethodId,
    system_prompt: str,
    user_prompt: str,
    representation: RepresentationArtifact,
) -> Dict[str, Any]:
    matches = []
    common_haystack = "\n".join(
        [system_prompt, user_prompt, *representation.attachment_paths]
    ).lower()
    for pattern in FORBIDDEN_COMMON:
        if pattern.lower() in common_haystack:
            matches.append(pattern)

    method_haystack = "\n".join(
        [system_prompt, user_prompt, *representation.attachment_paths]
    ).lower()
    # The A0 representation naturally describes "raw LLVM IR"; the scanner
    # forbids Ghidra/P0 evidence rather than the word LLVM itself.
    for pattern in FORBIDDEN_BY_METHOD.get(method, ()):
        if pattern.lower() in method_haystack:
            matches.append(pattern)
    if method is MethodId.B0:
        for attachment in representation.attachment_paths:
            suffix = Path(attachment).suffix.lower()
            if suffix in {".ll", ".bc"}:
                matches.append(suffix)
    return {"passed": not matches, "matches": sorted(set(matches))}


_SINGLE_FENCE = re.compile(
    r"\A\s*```(?:c|C)?[ \t]*\r?\n(?P<body>[\s\S]*?)\r?\n```\s*\Z"
)


def extract_candidate(response: str) -> str:
    normalized = response.replace("\r\n", "\n").replace("\r", "\n")
    if not normalized.strip():
        raise CandidateError("Model returned an empty response")
    match = _SINGLE_FENCE.fullmatch(normalized)
    candidate = match.group("body") if match else normalized
    if not candidate.endswith("\n"):
        candidate += "\n"
    return candidate


def _usage_value(usage: Dict[str, Any], *keys: str) -> int | None:
    for key in keys:
        value = usage.get(key)
        if value is not None:
            try:
                return int(value)
            except (TypeError, ValueError):
                return None
    return None


def generate_one_shot(
    method: MethodId,
    representation: RepresentationArtifact,
    output_dir: str | Path,
    config: Dict[str, Any],
    *,
    model_client: VertexGemini | None = None,
    quota_event_callback: Callable[[str, Dict[str, Any]], None] | None = None,
    quota_controller: QuotaController | None = None,
) -> GenerationResult:
    if method not in {MethodId.A0, MethodId.B0}:
        raise ValueError("generate_one_shot only supports A0 and B0")

    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    representation_text = Path(representation.primary_path).read_text(
        encoding="utf-8", errors="replace"
    )
    prompt = build_one_shot_prompt(method, representation_text)
    scan = _scan_request(
        method, prompt.system_prompt, prompt.user_prompt, representation
    )
    if not scan["passed"]:
        raise LeakageError(
            f"{method.value} request failed leakage scan: {scan['matches']}"
        )

    llm_config = config["llm"]
    input_tokens_estimated = estimate_tokens(
        prompt.system_prompt + "\n" + prompt.user_prompt
    )
    required = (
        input_tokens_estimated
        + int(llm_config["max_output_tokens"])
        + int(llm_config["context_safety_margin_tokens"])
    )
    context_window = int(llm_config.get("context_window_tokens", 0))
    fake_response_path = llm_config.get("fake_response_path")
    if not fake_response_path and required > context_window:
        overflow = required - context_window
        atomic_write_json(
            output / "context_check.json",
            {
                "fit": False,
                "estimated_input_tokens": input_tokens_estimated,
                "max_output_tokens": int(llm_config["max_output_tokens"]),
                "safety_margin_tokens": int(
                    llm_config["context_safety_margin_tokens"]
                ),
                "context_window_tokens": context_window,
                "model_spec_source": llm_config.get("model_spec_source"),
                "model_spec_verified_date": llm_config.get(
                    "model_spec_verified_date"
                ),
                "overflow_tokens": overflow,
            },
        )
        raise ContextOverflow(
            f"{method.value} request exceeds context window by {overflow} estimated tokens"
        )

    request_payload = {
        "method": method.value,
        "protocol": "strict_one_shot",
        "provider": llm_config["provider"],
        "model_id": llm_config["model_id"],
        "location": llm_config["location"],
        "system_prompt": prompt.system_prompt,
        "user_prompt": prompt.user_prompt,
        "system_prompt_sha256": prompt.system_prompt_sha256,
        "user_prompt_sha256": prompt.user_prompt_sha256,
        "representation_sha256": representation.primary_sha256,
        "decoding": {
            "temperature": float(llm_config["temperature"]),
            "top_p": float(llm_config["top_p"]),
            "candidate_count": int(llm_config.get("candidate_count", 1)),
            "max_output_tokens": int(llm_config["max_output_tokens"]),
            "thinking_level": llm_config.get("thinking_level"),
        },
        "prompt_policy": prompt_policy_manifest(method),
        "forbidden_scan": scan,
        "estimated_input_tokens": input_tokens_estimated,
        "context_gate": {
            "context_window_tokens": context_window,
            "context_safety_margin_tokens": int(
                llm_config["context_safety_margin_tokens"]
            ),
            "model_spec_source": llm_config.get("model_spec_source"),
            "model_spec_verified_date": llm_config.get(
                "model_spec_verified_date"
            ),
        },
    }
    request_sha256 = stable_json_sha256(request_payload)
    request_payload["request_sha256"] = request_sha256
    atomic_write_json(output / "request.json", request_payload)
    atomic_write_json(
        output / "context_check.json",
        {
            "fit": True,
            "estimated_input_tokens": input_tokens_estimated,
            "required_tokens": required,
            "context_window_tokens": context_window,
            "model_spec_source": llm_config.get("model_spec_source"),
            "model_spec_verified_date": llm_config.get(
                "model_spec_verified_date"
            ),
            "token_count_kind": "conservative_estimate_3_utf8_bytes_per_token",
        },
    )

    response_meta: Dict[str, Any] = {}
    accepted_calls = 0
    api_attempt_count = 0
    quota_throttle_count = 0
    quota_wait_duration_ms = 0
    empty_response_error: LLMEmptyResponseError | None = None
    started = time.perf_counter()
    if fake_response_path:
        response = Path(fake_response_path).read_text(encoding="utf-8")
        accepted_calls = 1
        api_attempt_count = 1
        response_meta = {
            "provider": "fake",
            "finish_reason": "STOP",
            "usage_metadata": {
                "prompt_token_count": input_tokens_estimated,
                "candidates_token_count": estimate_tokens(response),
            },
        }
    else:
        recovery_config = RecoveryConfig(
            model=str(llm_config["model_id"]),
            location=str(llm_config["location"]),
            temperature=float(llm_config["temperature"]),
            top_p=float(llm_config["top_p"]),
            candidate_count=int(llm_config.get("candidate_count", 1)),
            max_iterations=1,
            max_output_tokens=int(llm_config["max_output_tokens"]),
            thinking_level=llm_config.get("thinking_level"),
            request_timeout=float(llm_config["request_timeout_sec"]),
            llm_timeout=float(llm_config["request_timeout_sec"]),
            use_file_api=False,
            require_json=False,
        )
        client = model_client or VertexGemini(recovery_config)
        if quota_controller is not None:
            quota = quota_controller
            if quota.response_metadata_getter is None:
                quota.response_metadata_getter = (
                    lambda: dict(client.last_response_meta or {})
                )
            if quota.response_metadata_setter is None:
                quota.response_metadata_setter = lambda metadata: setattr(
                    client, "last_response_meta", dict(metadata)
                )
        else:
            quota = QuotaController(
                llm_config,
                output,
                method=method.value,
                event_callback=quota_event_callback,
                response_metadata_getter=(
                    lambda: dict(client.last_response_meta or {})
                ),
                response_metadata_setter=lambda metadata: setattr(
                    client, "last_response_meta", dict(metadata)
                ),
            )
        attempts = 1 + int(llm_config.get("transport_retries", 0))
        last_error: Exception | None = None
        response = ""
        for _ in range(attempts):
            try:
                response = quota.execute(
                    lambda: client.generate(
                        prompt.user_prompt,
                        system_instruction=prompt.system_prompt,
                    ),
                    {
                        "request_sha256": request_sha256,
                        "iteration": 1,
                        "max_iterations": 1,
                    },
                )
                accepted_calls = 1
                response_meta = dict(client.last_response_meta or {})
                break
            except LLMEmptyResponseError as exc:
                last_error = exc
                empty_response_error = exc
                response_meta = dict(client.last_response_meta or {})
                break
            except RecoveryError as exc:
                last_error = exc
        quota_metrics = quota.metrics()
        accepted_calls = quota_metrics["accepted_model_call_count"]
        api_attempt_count = quota_metrics["api_attempt_count"]
        quota_throttle_count = quota_metrics["quota_throttle_count"]
        quota_wait_duration_ms = quota_metrics[
            "quota_wait_duration_ms"
        ]
        if not response and accepted_calls == 0:
            raise RecoveryError(
                "One-shot request failed after "
                f"{api_attempt_count} identical API attempt(s): {last_error}"
            )
    response_meta["quota"] = {
        "api_attempt_count": api_attempt_count,
        "accepted_model_call_count": accepted_calls,
        "quota_throttle_count": quota_throttle_count,
        "quota_wait_duration_ms": quota_wait_duration_ms,
    }
    latency_ms = int((time.perf_counter() - started) * 1000)

    raw_path = atomic_write_text(output / "candidate_raw.txt", response)
    if not response:
        failure_generation = {
            "request_sha256": request_sha256,
            "candidate_path": None,
            "candidate_sha256": None,
            "logical_generation_count": 1,
            "model_call_count": accepted_calls,
            "response_path": str(raw_path),
            "input_tokens": None,
            "output_tokens": None,
            "thinking_tokens": None,
            "billable_output_tokens": None,
            "total_tokens": None,
            "latency_ms": latency_ms,
            "iterations": 1,
            "api_attempt_count": api_attempt_count,
            "quota_throttle_count": quota_throttle_count,
            "quota_wait_duration_ms": quota_wait_duration_ms,
            "response_metadata": response_meta,
        }
        atomic_write_json(
            output / "response.json",
            {
                "request_sha256": request_sha256,
                "response_sha256": sha256_text(response),
                "metadata": response_meta,
                "model_call_count": accepted_calls,
                "api_attempt_count": api_attempt_count,
                "quota_throttle_count": quota_throttle_count,
                "quota_wait_duration_ms": quota_wait_duration_ms,
                "logical_generation_count": 1,
                "failure": "EMPTY_RESPONSE",
            },
        )
        raise EmptyResponseError(
            str(empty_response_error or "Model returned an empty response"),
            failure_generation,
        )
    atomic_write_json(
        output / "response.json",
        {
            "request_sha256": request_sha256,
            "response_sha256": sha256_text(response),
            "metadata": response_meta,
            "model_call_count": accepted_calls,
            "api_attempt_count": api_attempt_count,
            "quota_throttle_count": quota_throttle_count,
            "quota_wait_duration_ms": quota_wait_duration_ms,
            "logical_generation_count": 1,
        },
    )
    candidate = extract_candidate(response)
    candidate_path = atomic_write_text(output / "candidate.c", candidate)
    usage = response_meta.get("usage_metadata") or {}
    input_tokens = _usage_value(
        usage, "prompt_token_count", "promptTokenCount"
    )
    output_tokens = _usage_value(
        usage, "candidates_token_count", "candidatesTokenCount"
    )
    thinking_tokens = _usage_value(
        usage, "thoughts_token_count", "thoughtsTokenCount"
    )
    billable_output_tokens = (
        (output_tokens or 0) + (thinking_tokens or 0)
        if output_tokens is not None or thinking_tokens is not None
        else None
    )
    total_tokens = _usage_value(usage, "total_token_count", "totalTokenCount")
    if (
        total_tokens is None
        and input_tokens is not None
        and billable_output_tokens is not None
    ):
        total_tokens = input_tokens + billable_output_tokens
    return GenerationResult(
        request_sha256=request_sha256,
        candidate_path=str(candidate_path),
        candidate_sha256=sha256_file(candidate_path),
        logical_generation_count=1,
        model_call_count=accepted_calls,
        response_path=str(raw_path),
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        thinking_tokens=thinking_tokens,
        billable_output_tokens=billable_output_tokens,
        total_tokens=total_tokens,
        latency_ms=latency_ms,
        iterations=1,
        api_attempt_count=api_attempt_count,
        quota_throttle_count=quota_throttle_count,
        quota_wait_duration_ms=quota_wait_duration_ms,
        response_metadata=response_meta,
    )
