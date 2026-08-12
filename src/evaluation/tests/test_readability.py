from __future__ import annotations

import json
from pathlib import Path

import pytest

from evaluation.artifact_loader import _source_quality
from evaluation.readability import (
    EvaluationTask,
    evaluate_source,
    parse_readability_response,
)


VALID_RESPONSE = """```json
{
  "scores": {
    "variables": 4,
    "loops": 3,
    "conditions": 4,
    "logic_flow": 3,
    "structural_integrity": 5
  },
  "rationales": {
    "variables": "Names communicate the main roles.",
    "loops": "The loop is recognizable but uses extra state.",
    "conditions": "Predicates are direct and locally understandable.",
    "logic_flow": "One goto still interrupts the main path.",
    "structural_integrity": "Functions and types form a coherent C unit."
  },
  "summary": "Readable C with a small amount of residual control-flow noise."
}
```"""


class FakeClient:
    def __init__(self, response: str, calls: list[str]):
        self.response = response
        self.calls = calls
        self.last_response_meta = {"usage_metadata": {"prompt_tokens": 10}}

    def generate(self, prompt, attachment_path=None, **kwargs):
        self.calls.append(str(attachment_path))
        return self.response


def test_parse_readability_response_uses_five_dimension_mean():
    result = parse_readability_response(VALID_RESPONSE)
    assert result["scores"]["variables"] == 4
    assert result["scores"]["structural_integrity"] == 5
    assert result["overall_score"] == 3.8


def test_parse_readability_response_rejects_non_integer_score():
    payload = VALID_RESPONSE.replace('"variables": 4', '"variables": 3.5')
    with pytest.raises(ValueError, match="variables score"):
        parse_readability_response(payload)


def test_evaluate_source_persists_and_reuses_hash_bound_cache(tmp_path: Path):
    source = tmp_path / "recovered.c"
    source.write_text("int main(void) { return 0; }\n", encoding="utf-8")
    cache = tmp_path / "readability_evaluation.json"
    task = EvaluationTask("p1", "F1", source, cache)
    calls: list[str] = []

    def factory(_model: str):
        return FakeClient(VALID_RESPONSE, calls)

    first = evaluate_source(task, model="cx/gpt-5.5", client_factory=factory)
    second = evaluate_source(task, model="cx/gpt-5.5", client_factory=factory)

    assert first["cache_hit"] is False
    assert second["cache_hit"] is True
    assert len(calls) == 1
    persisted = json.loads(cache.read_text(encoding="utf-8"))
    assert persisted["correctness_assessed"] is False
    assert persisted["accepted_candidate_only"] is True
    assert persisted["evaluator_id"] == "cx/gpt-5.5"
    assert persisted["overall_score"] == 3.8


def test_artifact_loader_reads_only_fresh_accepted_evaluation(tmp_path: Path):
    source = tmp_path / "recovered.c"
    source.write_text("int main(void) { return 0; }\n", encoding="utf-8")
    cache = tmp_path / "readability_evaluation.json"
    task = EvaluationTask("p1", "F1", source, cache)
    evaluate_source(
        task,
        model="cx/gpt-5.5",
        client_factory=lambda _model: FakeClient(VALID_RESPONSE, []),
    )

    ignored = _source_quality(None, source, cache, accepted=False)
    loaded = _source_quality(None, source, cache, accepted=True)
    assert ignored["readability_overall"] is None
    assert loaded["readability_overall"] == 3.8
    assert loaded["readability_structure"] == 5
    assert loaded["evaluator_id"] == "cx/gpt-5.5"

    source.write_text("int main(void) { return 1; }\n", encoding="utf-8")
    stale = _source_quality(None, source, cache, accepted=True)
    assert stale["readability_overall"] is None


def test_loader_rejects_readability_that_claims_correctness(tmp_path: Path):
    source = tmp_path / "accepted.c"
    source.write_text("int main(void) { return 0; }\n", encoding="utf-8")
    cache = tmp_path / "readability_evaluation.json"
    evaluate_source(
        EvaluationTask("p1", "F1", source, cache),
        model="cx/gpt-5.5",
        client_factory=lambda _model: FakeClient(VALID_RESPONSE, []),
    )
    record = json.loads(cache.read_text(encoding="utf-8"))
    record["correctness_assessed"] = True
    cache.write_text(json.dumps(record), encoding="utf-8")

    loaded = _source_quality(None, source, cache, accepted=True)
    assert loaded["readability_overall"] is None
