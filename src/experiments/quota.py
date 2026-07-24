from __future__ import annotations

import datetime as dt
import time
from pathlib import Path
from typing import Any, Callable, Dict, Mapping

from llm_recovery.llm_recovery import (
    LLMEmptyResponseError,
    LLMRateLimitError,
)

from .storage import (
    atomic_write_json,
    atomic_write_text,
    load_json,
    sha256_text,
)


class QuotaWaitExceeded(RuntimeError):
    """The provider is still throttling after the allowed wait budget."""


class QuotaController:
    """Retry the exact rejected request without consuming a model response."""

    SCHEMA_VERSION = "1.0"

    def __init__(
        self,
        llm_config: Mapping[str, Any],
        output_dir: str | Path,
        *,
        method: str,
        event_callback: Callable[[str, Dict[str, Any]], None] | None = None,
        response_metadata_getter: Callable[[], Mapping[str, Any]] | None = None,
        response_metadata_setter: (
            Callable[[Mapping[str, Any]], None] | None
        ) = None,
        sleep_fn: Callable[[float], None] = time.sleep,
        now_fn: Callable[[], dt.datetime] | None = None,
    ):
        policy = dict(llm_config.get("rate_limit") or {})
        self.enabled = bool(policy.get("enabled", True))
        self.max_wait_seconds = float(
            policy.get("max_wait_seconds", 3600)
        )
        self.default_retry_after_seconds = float(
            policy.get("default_retry_after_seconds", 3600)
        )
        self.method = method
        self.event_callback = event_callback
        self.response_metadata_getter = response_metadata_getter
        self.response_metadata_setter = response_metadata_setter
        self.sleep_fn = sleep_fn
        self.now_fn = now_fn or (lambda: dt.datetime.now(dt.timezone.utc))
        self.path = Path(output_dir) / "quota_state.json"
        self.response_cache_root = Path(output_dir) / "quota_responses"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.api_attempt_count = 0
        self.accepted_model_call_count = 0
        self.quota_throttle_count = 0
        self.quota_wait_duration_ms = 0
        self._state: Dict[str, Any] = {}
        self._load_checkpoint()

    def _now(self) -> dt.datetime:
        value = self.now_fn()
        if value.tzinfo is None:
            return value.replace(tzinfo=dt.timezone.utc)
        return value.astimezone(dt.timezone.utc)

    def _load_checkpoint(self) -> None:
        if not self.path.is_file():
            return
        try:
            state = load_json(self.path)
        except (OSError, ValueError):
            return
        if (
            state.get("schema_version") != self.SCHEMA_VERSION
            or state.get("method") != self.method
        ):
            return
        self._state = state
        self.api_attempt_count = int(state.get("api_attempt_count", 0))
        self.accepted_model_call_count = int(
            state.get("accepted_model_call_count", 0)
        )
        self.quota_throttle_count = int(
            state.get("quota_throttle_count", 0)
        )
        self.quota_wait_duration_ms = int(
            state.get("quota_wait_duration_ms", 0)
        )

    def _write_state(
        self,
        status: str,
        context: Mapping[str, Any],
        **extra: Any,
    ) -> Dict[str, Any]:
        state = {
            "schema_version": self.SCHEMA_VERSION,
            "status": status,
            "method": self.method,
            "request_sha256": context.get("request_sha256"),
            "iteration": context.get("iteration"),
            "max_iterations": context.get("max_iterations"),
            "updated_at_utc": self._now().isoformat(),
            "api_attempt_count": self.api_attempt_count,
            "accepted_model_call_count": self.accepted_model_call_count,
            "quota_throttle_count": self.quota_throttle_count,
            "quota_wait_duration_ms": self.quota_wait_duration_ms,
            "max_wait_seconds": self.max_wait_seconds,
            **extra,
        }
        atomic_write_json(self.path, state)
        self._state = state
        return state

    def _emit(
        self,
        event_type: str,
        context: Mapping[str, Any],
        **extra: Any,
    ) -> None:
        if self.event_callback is None:
            return
        self.event_callback(
            event_type,
            {
                "method": self.method,
                "request_sha256": context.get("request_sha256"),
                "iteration": context.get("iteration"),
                "max_iterations": context.get("max_iterations"),
                "api_attempt_count": self.api_attempt_count,
                "accepted_model_call_count": self.accepted_model_call_count,
                "quota_throttle_count": self.quota_throttle_count,
                "quota_wait_duration_ms": self.quota_wait_duration_ms,
                **extra,
            },
        )

    @staticmethod
    def _parse_utc(value: Any) -> dt.datetime | None:
        if not value:
            return None
        try:
            parsed = dt.datetime.fromisoformat(str(value))
        except ValueError:
            return None
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=dt.timezone.utc)
        return parsed.astimezone(dt.timezone.utc)

    def _complete_checkpointed_wait(
        self,
        context: Mapping[str, Any],
        *,
        resumed_from_checkpoint: bool,
    ) -> None:
        wait_started = self._parse_utc(
            self._state.get("wait_started_at_utc")
        ) or self._now()
        retry_at = self._parse_utc(
            self._state.get("next_retry_at_utc")
        ) or self._now()
        now = self._now()
        remaining = max(0.0, (retry_at - now).total_seconds())
        self._emit(
            "quota_wait_started",
            context,
            wait_seconds=remaining,
            next_retry_at_utc=retry_at.isoformat(),
            resumed_from_checkpoint=resumed_from_checkpoint,
        )
        if remaining > 0:
            self.sleep_fn(remaining)
        completed_at = self._now()
        elapsed_ms = max(
            0,
            int((completed_at - wait_started).total_seconds() * 1000),
        )
        # Fake clocks used by tests may not advance during sleep.
        if elapsed_ms == 0 and remaining > 0:
            elapsed_ms = int(remaining * 1000)
        self.quota_wait_duration_ms += elapsed_ms
        self._write_state("RESUMED", context)
        self._emit(
            "quota_resumed",
            context,
            waited_ms=elapsed_ms,
            resumed_from_checkpoint=resumed_from_checkpoint,
        )

    def _resume_wait_if_needed(self, context: Mapping[str, Any]) -> None:
        if self._state.get("status") != "WAITING_FOR_QUOTA":
            return
        if self._state.get("request_sha256") != context.get(
            "request_sha256"
        ):
            return
        if self._state.get("iteration") != context.get("iteration"):
            return
        self._complete_checkpointed_wait(
            context, resumed_from_checkpoint=True
        )

    def _response_cache_paths(
        self, context: Mapping[str, Any]
    ) -> tuple[Path, Path] | None:
        request_sha256 = str(context.get("request_sha256") or "").lower()
        if (
            len(request_sha256) != 64
            or any(character not in "0123456789abcdef" for character in request_sha256)
        ):
            return None
        cache_dir = self.response_cache_root / request_sha256
        return cache_dir / "response.txt", cache_dir / "manifest.json"

    def _load_cached_response(
        self, context: Mapping[str, Any]
    ) -> tuple[str, Dict[str, Any], bool] | None:
        paths = self._response_cache_paths(context)
        if paths is None:
            return None
        response_path, manifest_path = paths
        if not response_path.is_file() or not manifest_path.is_file():
            return None
        try:
            manifest = load_json(manifest_path)
            response = response_path.read_text(encoding="utf-8")
        except (OSError, ValueError):
            return None
        if manifest.get("method") != self.method:
            return None
        if manifest.get("request_sha256") != context.get("request_sha256"):
            return None
        if manifest.get("iteration") != context.get("iteration"):
            return None
        if manifest.get("response_sha256") != sha256_text(response):
            return None
        metadata = manifest.get("response_metadata") or {}
        if not isinstance(metadata, dict):
            return None
        return response, metadata, bool(manifest.get("empty_response", False))

    def _persist_accepted_response(
        self, context: Mapping[str, Any], response: str
    ) -> Dict[str, Any]:
        paths = self._response_cache_paths(context)
        if paths is None:
            raise ValueError("request_sha256 must be a lowercase SHA-256 digest")
        response_path, manifest_path = paths
        response_sha256 = sha256_text(response)
        atomic_write_text(response_path, response)
        manifest = {
            "schema_version": self.SCHEMA_VERSION,
            "method": self.method,
            "request_sha256": context.get("request_sha256"),
            "iteration": context.get("iteration"),
            "response_sha256": response_sha256,
            "response_path": str(response_path),
            "response_metadata": (
                dict(self.response_metadata_getter() or {})
                if self.response_metadata_getter is not None
                else {}
            ),
            "empty_response": response == "",
        }
        atomic_write_json(manifest_path, manifest)
        return manifest

    def execute(
        self,
        request_call: Callable[[], str],
        context: Mapping[str, Any],
    ) -> str:
        cached = self._load_cached_response(context)
        if cached is not None:
            cached_response, cached_metadata, cached_empty = cached
            if self.response_metadata_setter is not None:
                self.response_metadata_setter(cached_metadata)
            cache_paths = self._response_cache_paths(context)
            response_sha256 = sha256_text(cached_response)
            self._write_state(
                "RESPONSE_REPLAYED",
                context,
                response_sha256=response_sha256,
                response_cache_path=(
                    str(cache_paths[0]) if cache_paths is not None else None
                ),
            )
            self._emit(
                "provider_response_replayed",
                context,
                response_sha256=response_sha256,
            )
            if cached_empty:
                raise LLMEmptyResponseError(
                    "Replayed checkpointed empty provider response"
                )
            return cached_response
        self._resume_wait_if_needed(context)
        while True:
            self.api_attempt_count += 1
            self._write_state("REQUESTING", context)
            try:
                response = request_call()
            except LLMEmptyResponseError:
                cached = self._persist_accepted_response(context, "")
                self.accepted_model_call_count += 1
                self._write_state(
                    "EMPTY_RESPONSE_ACCEPTED",
                    context,
                    response_sha256=cached["response_sha256"],
                    response_cache_path=cached["response_path"],
                )
                self._emit(
                    "provider_empty_response",
                    context,
                    response_sha256=cached["response_sha256"],
                )
                raise
            except LLMRateLimitError as exc:
                if not self.enabled:
                    raise
                self.quota_throttle_count += 1
                requested_wait = (
                    float(exc.retry_after_seconds)
                    if exc.retry_after_seconds is not None
                    else self.default_retry_after_seconds
                )
                remaining_budget = max(
                    0.0,
                    self.max_wait_seconds
                    - self.quota_wait_duration_ms / 1000.0,
                )
                if remaining_budget <= 0:
                    self._write_state(
                        "WAITING_FOR_QUOTA",
                        context,
                        wait_started_at_utc=self._now().isoformat(),
                        next_retry_at_utc=None,
                        provider_error=str(exc),
                        wait_budget_exhausted=True,
                    )
                    self._emit(
                        "quota_throttled",
                        context,
                        provider_status_code=exc.status_code,
                        provider_retry_after_seconds=exc.retry_after_seconds,
                        requested_wait_seconds=requested_wait,
                        remaining_wait_budget_seconds=remaining_budget,
                    )
                    raise QuotaWaitExceeded(
                        f"{self.method} remains rate limited after "
                        f"{self.max_wait_seconds:.0f}s quota wait"
                    ) from exc
                wait_seconds = min(
                    max(1.0, requested_wait), remaining_budget
                )
                wait_started = self._now()
                retry_at = wait_started + dt.timedelta(
                    seconds=wait_seconds
                )
                self._write_state(
                    "WAITING_FOR_QUOTA",
                    context,
                    wait_started_at_utc=wait_started.isoformat(),
                    next_retry_at_utc=retry_at.isoformat(),
                    provider_error=str(exc),
                    provider_status_code=exc.status_code,
                    provider_retry_after_seconds=exc.retry_after_seconds,
                    wait_capped_to_budget=wait_seconds < requested_wait,
                )
                self._emit(
                    "quota_throttled",
                    context,
                    provider_status_code=exc.status_code,
                    provider_retry_after_seconds=exc.retry_after_seconds,
                    requested_wait_seconds=requested_wait,
                    remaining_wait_budget_seconds=remaining_budget,
                )
                self._complete_checkpointed_wait(
                    context, resumed_from_checkpoint=False
                )
                continue
            except Exception:
                self._write_state("REQUEST_FAILED", context)
                raise
            response_text = str(response)
            cached = self._persist_accepted_response(context, response_text)
            self.accepted_model_call_count += 1
            self._write_state(
                "RESPONSE_ACCEPTED",
                context,
                response_sha256=cached["response_sha256"],
                response_cache_path=cached["response_path"],
            )
            return response_text

    def metrics(self) -> Dict[str, int]:
        return {
            "api_attempt_count": self.api_attempt_count,
            "accepted_model_call_count": self.accepted_model_call_count,
            "quota_throttle_count": self.quota_throttle_count,
            "quota_wait_duration_ms": self.quota_wait_duration_ms,
        }
