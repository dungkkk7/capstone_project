from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Dict, Optional

from .enums import MethodId, Stage, TerminalStatus


@dataclass(frozen=True)
class SampleIdentity:
    sample_id: str
    dataset_row_index: int
    original_elf_path: str
    original_elf_sha256: str
    architecture: str
    input_contract_id: str
    input_contract_sha256: str
    seed_manifest_sha256: str
    obfuscation_tags: tuple[str, ...] = ()

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data["obfuscation_tags"] = list(self.obfuscation_tags)
        return data


@dataclass
class RepresentationArtifact:
    method: MethodId
    primary_path: str
    primary_sha256: str
    byte_count: int
    token_count: int
    builder_version: str
    attachment_paths: list[str] = field(default_factory=list)
    attachment_sha256: list[str] = field(default_factory=list)
    tool_versions: Dict[str, str] = field(default_factory=dict)
    provenance: Dict[str, Any] = field(default_factory=dict)
    evidence_byte_count: Optional[int] = None
    evidence_token_count: Optional[int] = None

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data["method"] = self.method.value
        return data


@dataclass
class GenerationResult:
    request_sha256: str
    candidate_path: str
    candidate_sha256: str
    logical_generation_count: int
    model_call_count: int
    response_path: str
    input_tokens: Optional[int] = None
    output_tokens: Optional[int] = None
    thinking_tokens: Optional[int] = None
    billable_output_tokens: Optional[int] = None
    total_tokens: Optional[int] = None
    latency_ms: Optional[int] = None
    iterations: int = 1
    api_attempt_count: Optional[int] = None
    quota_throttle_count: int = 0
    quota_wait_duration_ms: int = 0
    response_metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class BuildResult:
    ok: bool
    command: list[str]
    compiler_version: str
    return_code: Optional[int]
    stdout_path: str
    stderr_path: str
    executable_path: Optional[str]
    executable_sha256: Optional[str]
    duration_ms: int

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class VariantResult:
    run_id: str
    sample_id: str
    method: MethodId
    terminal_status: TerminalStatus
    final_stage: Stage
    e2e_pass: bool = False
    failure_code: Optional[str] = None
    failure_message: Optional[str] = None
    identity: Dict[str, Any] = field(default_factory=dict)
    representation: Optional[Dict[str, Any]] = None
    generation: Optional[Dict[str, Any]] = None
    build: Optional[Dict[str, Any]] = None
    evaluation: Optional[Dict[str, Any]] = None
    timing: Dict[str, int] = field(default_factory=dict)
    provenance: Dict[str, Any] = field(default_factory=dict)
    integrity: Dict[str, Any] = field(default_factory=dict)
    schema_version: str = "2.0"

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data["method"] = self.method.value
        data["terminal_status"] = self.terminal_status.value
        data["final_stage"] = self.final_stage.value
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "VariantResult":
        payload = dict(data)
        payload.pop("_path", None)
        payload["method"] = MethodId(payload["method"])
        payload["terminal_status"] = TerminalStatus(payload["terminal_status"])
        payload["final_stage"] = Stage(payload["final_stage"])
        return cls(**payload)

    @classmethod
    def enrolled(
        cls, run_id: str, sample: SampleIdentity, method: MethodId
    ) -> "VariantResult":
        return cls(
            run_id=run_id,
            sample_id=sample.sample_id,
            method=method,
            terminal_status=TerminalStatus.CANCELLED,
            final_stage=Stage.ENROLLED,
            identity={
                "original_elf_sha256": sample.original_elf_sha256,
                "input_contract_id": sample.input_contract_id,
                "input_contract_sha256": sample.input_contract_sha256,
                "seed_manifest_sha256": sample.seed_manifest_sha256,
            },
        )
