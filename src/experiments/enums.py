from __future__ import annotations

from enum import Enum


class MethodId(str, Enum):
    P0 = "P0"
    A0 = "A0"
    B0 = "B0"


class Stage(str, Enum):
    ENROLLED = "enrolled"
    REPRESENTATION = "representation"
    CONTEXT_CHECK = "context_check"
    GENERATION = "generation"
    CANDIDATE_EXTRACT = "candidate_extract"
    BUILD = "build"
    SMOKE_RUN = "smoke_run"
    FROZEN_REPLAY = "frozen_replay"
    FUZZ_DISCOVERY = "fuzz_discovery"
    UNION_REPLAY = "union_replay"
    FINALIZED = "finalized"


class TerminalStatus(str, Enum):
    PASS = "PASS"
    REPRESENTATION_FAILED = "REPRESENTATION_FAILED"
    CONTEXT_OVERFLOW = "CONTEXT_OVERFLOW"
    LLM_REQUEST_FAILED = "LLM_REQUEST_FAILED"
    LLM_EMPTY_RESPONSE = "LLM_EMPTY_RESPONSE"
    INVALID_CANDIDATE = "INVALID_CANDIDATE"
    BUILD_FAILED = "BUILD_FAILED"
    NOT_RUNNABLE = "NOT_RUNNABLE"
    BEHAVIOR_MISMATCH = "BEHAVIOR_MISMATCH"
    EVAL_INCONCLUSIVE = "EVAL_INCONCLUSIVE"
    INFRA_ERROR = "INFRA_ERROR"
    WAITING_FOR_QUOTA = "WAITING_FOR_QUOTA"
    CANCELLED = "CANCELLED"
