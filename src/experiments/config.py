from __future__ import annotations

import copy
import shutil
from pathlib import Path
from typing import Any, Dict, Iterable

import yaml

from .enums import MethodId
from .storage import stable_json_sha256


DEFAULT_CONFIG: Dict[str, Any] = {
    "schema_version": "2.0",
    "experiment": {
        "methods": ["P0", "A0", "B0"],
        "variant_order": ["B0", "A0", "P0"],
        "study_scope": "unspecified",
        "run_seed": 4912026,
        "resume": True,
        "fail_fast": False,
        "require_clean_git": False,
        # Samples are independent, but methods inside one sample remain
        # ordered by default. Raise variant_workers when provider capacity
        # permits independent variants to run concurrently.
        "sample_workers": 1,
        "variant_workers": 1,
        "dispatch_batch_size": 10,
        "dispatch_interval_seconds": 30,
    },
    "paths": {
        "result_root": "result/experiments",
        "ghidra_headless": "/opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless",
        "ida_disassembler": "/opt/ida-pro-9.3/idat",
        "llvm_dis": "/usr/bin/llvm-dis-21",
        "clang": "/usr/bin/clang-21",
    },
    "representation": {
        "no_truncation": True,
        "b0": {"ghidra_timeout_sec": 900, "use_cache": True},
        "a0": {"allow_passes": [], "allow_optimizations": False},
    },
    "llm": {
        "provider": "vertex_ai",
        "model_id": "gemini-3.5-flash",
        "location": "global",
        "temperature": 0.0,
        "top_p": 1.0,
        "candidate_count": 1,
        "max_output_tokens": 65535,
        "thinking_level": "HIGH",
        "request_timeout_sec": 900,
        "context_window_tokens": 1048576,
        "model_spec_source": (
            "https://docs.cloud.google.com/"
            "gemini-enterprise-agent-platform/models/gemini/3-5-flash"
        ),
        "model_spec_verified_date": "2026-07-24",
        "context_safety_margin_tokens": 1024,
        "transport_retries": 5,
        "rate_limit": {
            "enabled": True,
            # Keep a checkpoint alive for the whole quota window. A rejected
            # request retries in-place instead of abandoning the task.
            "max_wait_seconds": 86400,
            "default_retry_after_seconds": 60,
            "retry_initial_seconds": 2,
            "retry_max_delay_seconds": 3600,
            "transient_retry_enabled": True,
            "transient_max_retries": 10,
            "transient_initial_delay_seconds": 2,
            "transient_max_delay_seconds": 30,
        },
        "fake_response_path": None,
        "pricing_plan": "standard_paygo_global",
        "pricing_usd_per_million_input_tokens": 1.25,
        "pricing_usd_per_million_output_tokens": 10.00,
        "pricing_long_context_threshold_tokens": 200000,
        "pricing_usd_per_million_input_tokens_long_context": 2.50,
        "pricing_usd_per_million_output_tokens_long_context": 15.00,
        "pricing_source": (
            "https://cloud.google.com/"
            "gemini-enterprise-agent-platform/generative-ai/pricing"
        ),
        "pricing_verified_date": "2026-07-24",
    },
    "p0": {
        "max_iterations": 5,
        "fuzz_iterations": 100,
        "fuzz_timeout_sec": 0.5,
        "use_lifting_cache": True,
        "attach_clean_ir": True,
    },
    "build": {
        "compiler": "/usr/bin/clang-21",
        "flags": [
            "-std=c11",
            "-O0",
            "-fno-strict-aliasing",
            "-fwrapv",
            "-Wno-everything",
        ],
        "link_flags": ["-lm"],
        "timeout_sec": 60,
    },
    "corpus": {
        "deterministic_supplement_count": 50,
        "generator_seed": 4912026,
    },
    "fuzz": {
        "enabled": True,
        # Every final C candidate follows the same main.py differential-fuzz
        # path against the original ELF. P0 additionally preserves its five
        # internal repair/fuzz iterations.
        "discovery_methods": ["P0", "A0", "B0"],
        "seconds_per_method": 1,
        "target_accepted_inputs": 100,
        "max_saved_unique_inputs": 5000,
    },
    "evaluation": {
        "compare_stdout": True,
        "compare_stderr": True,
        "compare_exit_status": True,
        "per_input_timeout_sec": 0.5,
        "min_confirmed_inputs": 50,
        "max_reference_inconclusive_fraction": 0.20,
        "nondeterminism_repeats": 3,
        "environment": {"LC_ALL": "C", "LANG": "C", "TZ": "UTC"},
    },
    "statistics": {
        "bootstrap_resamples": 10000,
        "bootstrap_seed": 4912026,
        "confidence_level": 0.95,
        "alpha": 0.05,
    },
}


class ConfigError(ValueError):
    pass


def _deep_merge(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    merged = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = _deep_merge(merged[key], value)
        else:
            merged[key] = copy.deepcopy(value)
    return merged


def config_fingerprint(config: Dict[str, Any]) -> str:
    """Hash scientific/runtime settings, excluding scheduling-only knobs."""
    payload = copy.deepcopy(
        {key: value for key, value in config.items() if not key.startswith("_")}
    )
    payload.get("experiment", {}).pop("sample_workers", None)
    payload.get("experiment", {}).pop("variant_workers", None)
    payload.get("experiment", {}).pop("dispatch_batch_size", None)
    payload.get("experiment", {}).pop("dispatch_interval_seconds", None)
    return stable_json_sha256(payload)


def _reject_unknown_keys(
    document: Dict[str, Any],
    schema: Dict[str, Any],
    *,
    prefix: str = "",
) -> None:
    for key, value in document.items():
        dotted = f"{prefix}.{key}" if prefix else str(key)
        if key not in schema:
            raise ConfigError(f"Unknown configuration key: {dotted}")
        expected = schema[key]
        if isinstance(value, dict) and isinstance(expected, dict):
            _reject_unknown_keys(value, expected, prefix=dotted)


def load_config(path: str | Path, project_root: str | Path) -> Dict[str, Any]:
    source = Path(path)
    document = yaml.safe_load(source.read_text(encoding="utf-8")) or {}
    if not isinstance(document, dict):
        raise ConfigError("Experiment config root must be a mapping")
    _reject_unknown_keys(document, DEFAULT_CONFIG)
    config = _deep_merge(DEFAULT_CONFIG, document)
    config["_config_path"] = str(source.resolve())
    config["_project_root"] = str(Path(project_root).resolve())
    _resolve_paths(config)
    validate_config(config)
    config["_config_sha256"] = config_fingerprint(config)
    return config


def _resolve_paths(config: Dict[str, Any]) -> None:
    root = Path(config["_project_root"])
    for key, value in list(config["paths"].items()):
        if not value:
            continue
        path = Path(str(value)).expanduser()
        if not path.is_absolute():
            path = root / path
        config["paths"][key] = str(path.resolve())
    compiler = Path(str(config["build"]["compiler"])).expanduser()
    if not compiler.is_absolute():
        compiler = root / compiler
    config["build"]["compiler"] = str(compiler.resolve())
    fake = config["llm"].get("fake_response_path")
    if fake:
        fake_path = Path(str(fake)).expanduser()
        if not fake_path.is_absolute():
            fake_path = root / fake_path
        config["llm"]["fake_response_path"] = str(fake_path.resolve())


def validate_config(config: Dict[str, Any]) -> None:
    try:
        methods = [MethodId(value) for value in config["experiment"]["methods"]]
    except (KeyError, ValueError, TypeError) as exc:
        raise ConfigError("experiment.methods must contain P0, A0 and/or B0") from exc
    if len(methods) != len(set(methods)):
        raise ConfigError("experiment.methods contains duplicates")
    if not methods:
        raise ConfigError("experiment.methods must not be empty")
    try:
        variant_order = [
            MethodId(value)
            for value in config["experiment"].get(
                "variant_order", config["experiment"]["methods"]
            )
        ]
    except (ValueError, TypeError) as exc:
        raise ConfigError(
            "experiment.variant_order must contain valid method IDs"
        ) from exc
    if len(variant_order) != len(set(variant_order)):
        raise ConfigError("experiment.variant_order contains duplicates")
    if set(variant_order) != set(methods):
        raise ConfigError(
            "experiment.variant_order must be a permutation of experiment.methods"
        )
    if not str(
        config["experiment"].get("study_scope") or ""
    ).strip():
        raise ConfigError("experiment.study_scope must not be empty")
    try:
        sample_workers = int(config["experiment"].get("sample_workers", 1))
    except (TypeError, ValueError) as exc:
        raise ConfigError("experiment.sample_workers must be an integer") from exc
    if sample_workers < 1:
        raise ConfigError("experiment.sample_workers must be at least 1")
    try:
        variant_workers = int(config["experiment"].get("variant_workers", 1))
    except (TypeError, ValueError) as exc:
        raise ConfigError("experiment.variant_workers must be an integer") from exc
    if variant_workers < 1:
        raise ConfigError("experiment.variant_workers must be at least 1")
    if int(config["experiment"].get("dispatch_batch_size", 10)) < 1:
        raise ConfigError("experiment.dispatch_batch_size must be at least 1")
    if float(config["experiment"].get("dispatch_interval_seconds", 30)) < 0:
        raise ConfigError("experiment.dispatch_interval_seconds may not be negative")
    if int(config["p0"]["max_iterations"]) != 5:
        raise ConfigError("P0 must preserve max_iterations=5")
    if config["representation"]["a0"].get("allow_passes"):
        raise ConfigError("A0 allow_passes must be empty")
    if config["representation"]["a0"].get("allow_optimizations"):
        raise ConfigError("A0 optimizations must be disabled")
    if not config["representation"].get("no_truncation", True):
        raise ConfigError("Experiment representations may not be truncated")
    fake_response = config["llm"].get("fake_response_path")
    if not fake_response and int(config["llm"].get("context_window_tokens", 0)) <= 0:
        raise ConfigError(
            "llm.context_window_tokens must be explicitly set for real model runs"
        )
    if not fake_response and not str(
        config["llm"].get("model_spec_source") or ""
    ).startswith("https://"):
        raise ConfigError(
            "llm.model_spec_source must record the official HTTPS source "
            "for real model runs"
        )
    if not fake_response and not str(
        config["llm"].get("model_spec_verified_date") or ""
    ).strip():
        raise ConfigError(
            "llm.model_spec_verified_date must be recorded for real model runs"
        )
    if config["llm"].get("provider") != "vertex_ai":
        raise ConfigError(
            "Only llm.provider=vertex_ai is implemented by this harness"
        )
    if not str(config["llm"].get("model_id") or "").strip():
        raise ConfigError("llm.model_id must not be empty")
    if not str(config["llm"].get("location") or "").strip():
        raise ConfigError("llm.location must not be empty")
    if int(config["llm"].get("transport_retries", 0)) < 0:
        raise ConfigError("transport_retries may not be negative")
    if int(config["llm"].get("candidate_count", 1)) != 1:
        raise ConfigError("llm.candidate_count must remain 1")
    if not 0.0 <= float(config["llm"]["temperature"]) <= 2.0:
        raise ConfigError("llm.temperature must be in [0, 2]")
    if not 0.0 < float(config["llm"]["top_p"]) <= 1.0:
        raise ConfigError("llm.top_p must be in (0, 1]")
    if int(config["llm"]["max_output_tokens"]) <= 0:
        raise ConfigError("llm.max_output_tokens must be positive")
    if int(config["llm"]["context_safety_margin_tokens"]) < 0:
        raise ConfigError("llm.context_safety_margin_tokens may not be negative")
    rate_limit = config["llm"].get("rate_limit") or {}
    max_wait = float(rate_limit.get("max_wait_seconds", 3600))
    default_wait = float(
        rate_limit.get("default_retry_after_seconds", 60)
    )
    if max_wait <= 0 or max_wait > 86400:
        raise ConfigError(
            "llm.rate_limit.max_wait_seconds must be in (0, 86400]"
        )
    retry_initial = float(rate_limit.get("retry_initial_seconds", 2))
    retry_max_delay = float(rate_limit.get("retry_max_delay_seconds", 60))
    if default_wait <= 0 or default_wait > 3600:
        raise ConfigError(
            "llm.rate_limit.default_retry_after_seconds must be in (0, 3600]"
        )
    if retry_initial <= 0 or retry_initial > 3600:
        raise ConfigError(
            "llm.rate_limit.retry_initial_seconds must be in (0, 3600]"
        )
    if retry_max_delay <= 0 or retry_max_delay > 3600:
        raise ConfigError(
            "llm.rate_limit.retry_max_delay_seconds must be in (0, 3600]"
        )
    if int(config["evaluation"]["min_confirmed_inputs"]) < 1:
        raise ConfigError("evaluation.min_confirmed_inputs must be positive")
    inconclusive_fraction = float(
        config["evaluation"]["max_reference_inconclusive_fraction"]
    )
    if not 0.0 <= inconclusive_fraction <= 1.0:
        raise ConfigError(
            "evaluation.max_reference_inconclusive_fraction must be in [0, 1]"
        )
    if int(config["statistics"]["bootstrap_resamples"]) < 1:
        raise ConfigError("statistics.bootstrap_resamples must be positive")
    confidence = float(config["statistics"]["confidence_level"])
    if not 0.0 < confidence < 1.0:
        raise ConfigError("statistics.confidence_level must be in (0, 1)")
    alpha = float(config["statistics"]["alpha"])
    if not 0.0 < alpha < 1.0:
        raise ConfigError("statistics.alpha must be in (0, 1)")
    input_price = config["llm"].get(
        "pricing_usd_per_million_input_tokens"
    )
    output_price = config["llm"].get(
        "pricing_usd_per_million_output_tokens"
    )
    if (input_price is None) != (output_price is None):
        raise ConfigError(
            "Both input and output token prices must be set together"
        )
    if input_price is not None and (
        float(input_price) < 0 or float(output_price) < 0
    ):
        raise ConfigError("Token prices may not be negative")
    long_input_price = config["llm"].get(
        "pricing_usd_per_million_input_tokens_long_context"
    )
    long_output_price = config["llm"].get(
        "pricing_usd_per_million_output_tokens_long_context"
    )
    if (long_input_price is None) != (long_output_price is None):
        raise ConfigError(
            "Both long-context input and output prices must be set together"
        )
    threshold = config["llm"].get("pricing_long_context_threshold_tokens")
    if threshold is not None and int(threshold) <= 0:
        raise ConfigError(
            "pricing_long_context_threshold_tokens must be positive"
        )
    if long_input_price is not None and (
        float(long_input_price) < 0 or float(long_output_price) < 0
    ):
        raise ConfigError("Long-context token prices may not be negative")
    if input_price is not None:
        if not str(config["llm"].get("pricing_plan") or "").strip():
            raise ConfigError(
                "llm.pricing_plan must identify the frozen billing tier"
            )
        if not str(config["llm"].get("pricing_source") or "").startswith(
            "https://"
        ):
            raise ConfigError(
                "llm.pricing_source must record the official HTTPS source"
            )
        if not str(
            config["llm"].get("pricing_verified_date") or ""
        ).strip():
            raise ConfigError(
                "llm.pricing_verified_date must be recorded"
            )


def method_list(config: Dict[str, Any]) -> list[MethodId]:
    return [MethodId(value) for value in config["experiment"]["methods"]]
