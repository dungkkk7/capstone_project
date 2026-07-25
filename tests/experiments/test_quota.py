import copy
import datetime as dt
import hashlib
import json
import sys
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

import llm_recovery.llm_recovery as recovery  # noqa: E402
from experiments.config import DEFAULT_CONFIG  # noqa: E402
from experiments.enums import MethodId  # noqa: E402
from experiments.generation import (  # noqa: E402
    EmptyResponseError,
    generate_one_shot,
)
from experiments.models import (  # noqa: E402
    RepresentationArtifact,
    VariantResult,
)
from experiments.quota import (  # noqa: E402
    QuotaController,
    QuotaWaitExceeded,
)
from experiments.runner import (  # noqa: E402
    ExperimentRunner,
    RunIntegrityError,
)
from experiments.storage import load_json  # noqa: E402
from llm_recovery.llm_recovery import (  # noqa: E402
    LLMEmptyResponseError,
    LLMRateLimitError,
    LLMTransientError,
    RecoveryConfig,
)


class FakeClock:
    def __init__(self):
        self.current = dt.datetime(2026, 7, 24, tzinfo=dt.timezone.utc)
        self.sleeps = []

    def now(self):
        return self.current

    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.current += dt.timedelta(seconds=seconds)


def quota_config(max_wait=10, default_wait=5):
    return {
        "rate_limit": {
            "enabled": True,
            "max_wait_seconds": max_wait,
            "default_retry_after_seconds": default_wait,
        }
    }


def test_quota_controller_waits_and_counts_attempts(tmp_path):
    clock = FakeClock()
    events = []
    controller = QuotaController(
        quota_config(),
        tmp_path,
        method="B0",
        event_callback=lambda name, payload: events.append((name, payload)),
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )
    calls = 0

    def request():
        nonlocal calls
        calls += 1
        if calls == 1:
            raise LLMRateLimitError(
                "quota",
                retry_after_seconds=2,
                status_code=429,
            )
        return "ok"

    result = controller.execute(
        request,
        {
            "request_sha256": "a" * 64,
            "iteration": 1,
            "max_iterations": 1,
        },
    )

    assert result == "ok"
    assert controller.metrics() == {
        "api_attempt_count": 2,
        "accepted_model_call_count": 1,
        "quota_throttle_count": 1,
        "quota_wait_duration_ms": 30000,
    }
    assert [name for name, _ in events] == [
        "quota_throttled",
        "quota_wait_started",
        "quota_resumed",
    ]
    state = json.loads((tmp_path / "quota_state.json").read_text())
    assert state["status"] == "RESPONSE_ACCEPTED"


def test_transient_provider_cancellation_retries_same_iteration(tmp_path):
    clock = FakeClock()
    controller = QuotaController(
        quota_config(),
        tmp_path,
        method="P0",
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )
    calls = 0

    def request():
        nonlocal calls
        calls += 1
        if calls == 1:
            raise LLMTransientError("cancelled", status_code=499)
        return '{"source":"int main(void){return 0;}"}'

    context = {
        "request_sha256": "d" * 64,
        "iteration": 2,
        "max_iterations": 5,
    }
    assert controller.execute(request, context).startswith("{")
    assert calls == 2
    assert clock.sleeps == [30.0]
    assert controller.metrics()["api_attempt_count"] == 2
    assert controller.metrics()["accepted_model_call_count"] == 1
    state = json.loads((tmp_path / "quota_state.json").read_text())
    assert state["status"] == "RESPONSE_ACCEPTED"
    assert state["transient_retry_count"] == 1


def test_transient_provider_cancellation_is_bounded(tmp_path):
    clock = FakeClock()
    policy = quota_config()
    policy["rate_limit"]["transient_max_retries"] = 2
    controller = QuotaController(
        policy,
        tmp_path,
        method="P0",
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )
    context = {
        "request_sha256": "e" * 64,
        "iteration": 1,
        "max_iterations": 5,
    }
    with pytest.raises(LLMTransientError):
        controller.execute(
            lambda: (_ for _ in ()).throw(
                LLMTransientError("cancelled", status_code=499)
            ),
            context,
        )
    assert clock.sleeps == [30.0] * 120
    assert controller.metrics()["api_attempt_count"] == 121
    state = json.loads((tmp_path / "quota_state.json").read_text())
    assert state["status"] == "REQUEST_FAILED"
    assert state["transient_retry_exhausted"] is True


def test_quota_checkpoint_resumes_same_request_after_interruption(tmp_path):
    clock = FakeClock()

    def interrupted_sleep(_seconds):
        raise KeyboardInterrupt

    first = QuotaController(
        quota_config(),
        tmp_path,
        method="A0",
        sleep_fn=interrupted_sleep,
        now_fn=clock.now,
    )
    context = {
        "request_sha256": "b" * 64,
        "iteration": 1,
        "max_iterations": 1,
    }
    with pytest.raises(KeyboardInterrupt):
        first.execute(
            lambda: (_ for _ in ()).throw(
                LLMRateLimitError("quota", retry_after_seconds=3)
            ),
            context,
        )
    waiting = json.loads((tmp_path / "quota_state.json").read_text())
    assert waiting["status"] == "WAITING_FOR_QUOTA"
    assert waiting["request_sha256"] == "b" * 64

    resumed = QuotaController(
        quota_config(),
        tmp_path,
        method="A0",
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )
    assert resumed.execute(lambda: "ok", context) == "ok"
    assert clock.sleeps == [30.0]
    assert resumed.metrics()["api_attempt_count"] == 2
    assert resumed.metrics()["accepted_model_call_count"] == 1


def test_quota_wait_budget_is_fixed_to_one_hour(tmp_path):
    clock = FakeClock()
    controller = QuotaController(
        quota_config(max_wait=2, default_wait=2),
        tmp_path,
        method="B0",
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )
    with pytest.raises(QuotaWaitExceeded, match="after 3600s"):
        controller.execute(
            lambda: (_ for _ in ()).throw(
                LLMRateLimitError("still limited")
            ),
            {
                "request_sha256": "same",
                "iteration": 1,
                "max_iterations": 1,
            },
        )
    assert controller.metrics()["api_attempt_count"] == 121
    assert controller.metrics()["quota_wait_duration_ms"] == 3600000


def test_accepted_response_is_replayed_without_second_api_call(tmp_path):
    context = {
        "request_sha256": "c" * 64,
        "iteration": 1,
        "max_iterations": 1,
    }
    first = QuotaController(
        quota_config(),
        tmp_path,
        method="A0",
        response_metadata_getter=lambda: {
            "model_version": "frozen-version",
            "usage_metadata": {"prompt_token_count": 12},
        },
    )
    assert first.execute(lambda: "accepted response", context) == (
        "accepted response"
    )

    events = []
    replayed_metadata = {}
    resumed = QuotaController(
        quota_config(),
        tmp_path,
        method="A0",
        event_callback=lambda name, payload: events.append((name, payload)),
        response_metadata_setter=lambda metadata: replayed_metadata.update(
            metadata
        ),
    )

    def must_not_call_provider():
        raise AssertionError("provider was called after accepted response")

    assert resumed.execute(must_not_call_provider, context) == (
        "accepted response"
    )
    assert resumed.metrics() == {
        "api_attempt_count": 1,
        "accepted_model_call_count": 1,
        "quota_throttle_count": 0,
        "quota_wait_duration_ms": 0,
    }
    assert [name for name, _ in events] == [
        "provider_response_replayed"
    ]
    assert replayed_metadata["model_version"] == "frozen-version"
    assert replayed_metadata["usage_metadata"]["prompt_token_count"] == 12


class OneShotRateLimitedClient:
    def __init__(self):
        self.calls = 0
        self.last_response_meta = {
            "finish_reason": "STOP",
            "usage_metadata": {
                "prompt_token_count": 10,
                "candidates_token_count": 8,
            },
        }

    def generate(self, prompt, **kwargs):
        self.calls += 1
        if self.calls == 1:
            raise LLMRateLimitError("quota", retry_after_seconds=1)
        return json.dumps(
            {"source": "int main(void) { return 0; }\n"}
        )


def test_one_shot_keeps_one_generation_after_rate_limit(tmp_path):
    representation_path = tmp_path / "representation.c"
    representation_path.write_text("int main(void);")
    representation = RepresentationArtifact(
        method=MethodId.B0,
        primary_path=str(representation_path),
        primary_sha256="representation-sha",
        byte_count=16,
        token_count=6,
        builder_version="test",
    )
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["llm"]["context_window_tokens"] = 1_000_000
    config["llm"]["transport_retries"] = 0
    config["llm"]["rate_limit"]["max_wait_seconds"] = 10
    config["llm"]["rate_limit"]["default_retry_after_seconds"] = 1
    clock = FakeClock()
    controller = QuotaController(
        config["llm"],
        tmp_path / "generation",
        method="B0",
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )

    generated = generate_one_shot(
        MethodId.B0,
        representation,
        tmp_path / "generation",
        config,
        model_client=OneShotRateLimitedClient(),
        quota_controller=controller,
    )

    assert generated.logical_generation_count == 1
    assert generated.model_call_count == 1
    assert generated.api_attempt_count == 2
    assert generated.quota_throttle_count == 1
    assert generated.quota_wait_duration_ms == 30000


class EmptyOneShotClient:
    def __init__(self):
        self.calls = 0
        self.last_response_meta = {
            "finish_reason": "EMPTY",
            "model_version": "test-version",
            "usage_metadata": {"prompt_token_count": 7},
        }

    def generate(self, prompt, **kwargs):
        self.calls += 1
        raise LLMEmptyResponseError("empty provider response")


def test_empty_response_consumes_one_shot_without_transport_retry(tmp_path):
    representation_path = tmp_path / "representation.c"
    representation_path.write_text("int main(void);")
    representation = RepresentationArtifact(
        method=MethodId.B0,
        primary_path=str(representation_path),
        primary_sha256="representation-sha",
        byte_count=16,
        token_count=6,
        builder_version="test",
    )
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["llm"]["context_window_tokens"] = 1_000_000
    config["llm"]["transport_retries"] = 2
    client = EmptyOneShotClient()

    with pytest.raises(EmptyResponseError) as caught:
        generate_one_shot(
            MethodId.B0,
            representation,
            tmp_path / "generation",
            config,
            model_client=client,
        )

    assert client.calls == 1
    assert caught.value.generation["model_call_count"] == 1
    assert caught.value.generation["logical_generation_count"] == 1
    assert caught.value.generation["api_attempt_count"] == 1
    response = load_json(tmp_path / "generation" / "response.json")
    assert response["failure"] == "EMPTY_RESPONSE"


class P0RateLimitedClient:
    def __init__(self):
        self.prompts = []
        self.kwargs = []
        self.last_response_meta = {
            "finish_reason": "STOP",
            "usage_metadata": {},
        }

    def generate(self, prompt, **kwargs):
        self.prompts.append(prompt)
        self.kwargs.append(kwargs)
        if len(self.prompts) == 1:
            raise LLMRateLimitError("quota", retry_after_seconds=1)
        return json.dumps(
            {"source": "int main(void) { return 0; }\n"}
        )


def test_p0_can_attach_brightened_ir_and_generated_pseudocode(
    tmp_path, monkeypatch
):
    monkeypatch.setattr(
        recovery, "_run_compile_check", lambda *_args, **_kwargs: (True, None)
    )
    monkeypatch.setattr(
        recovery,
        "_find_ghidra_analyze_headless",
        lambda _configured=None: "/bin/true",
    )
    pseudocode = "int main(void) { return 0; }\n"
    monkeypatch.setattr(
        recovery,
        "_decompile_binary_with_ghidra",
        lambda *_args, **_kwargs: pseudocode,
    )
    brightened = tmp_path / "brightened.ll"
    brightened.write_text("define i32 @main() { ret i32 0 }\n")
    reference = tmp_path / "brightened_ref.bin"
    reference.write_bytes(b"reference")

    class CapturingP0Client:
        def __init__(self):
            self.prompts = []
            self.kwargs = []
            self.last_response_meta = {
                "finish_reason": "STOP",
                "usage_metadata": {},
            }

        def generate(self, prompt, **kwargs):
            self.prompts.append(prompt)
            self.kwargs.append(kwargs)
            return json.dumps(
                {"source": "int main(void) { return 0; }\n"}
            )

    client = CapturingP0Client()

    result = recovery.run_recovery_loop(
        ir_text=brightened.read_text(),
        output_recovered_c_path=str(tmp_path / "candidate.c"),
        case_output_dir=str(tmp_path),
        metadata={
            "input_ir": str(brightened),
            "recovery_reference_binary": str(reference),
        },
        fuzzer_callback=lambda _candidate: {
            "is_fully_equivalent": False,
            "equivalence_ratio": 100.0,
            "confirmed_equivalence_ratio": 100.0,
            "confirmed_runs": 1,
            "matches": 1,
            "mismatches": 0,
            "inconclusive": 0,
        },
        config=RecoveryConfig(
            max_iterations=5,
            pseudo_backend="ghidra",
            use_file_api=True,
            attach_clean_ir=True,
            require_json=True,
        ),
        model_client=client,
    )

    assert result.success is True
    assert result.iterations == 1
    assert len(client.prompts) == 1
    generated_pseudo = tmp_path / "ghidra_recovery_input.c"
    assert generated_pseudo.read_text() == pseudocode
    assert client.kwargs[0]["attachment_paths"] == [
        str(generated_pseudo),
        str(brightened),
    ]


def test_p0_defaults_to_pseudocode_only_attachment(tmp_path, monkeypatch):
    monkeypatch.setattr(
        recovery, "_run_compile_check", lambda *_args, **_kwargs: (True, None)
    )
    monkeypatch.setattr(
        recovery, "_find_ghidra_analyze_headless", lambda _configured=None: "/bin/true"
    )
    monkeypatch.setattr(
        recovery,
        "_decompile_binary_with_ghidra",
        lambda *_args, **_kwargs: "int main(void) { return 0; }\n",
    )
    brightened = tmp_path / "brightened.ll"
    brightened.write_text("define i32 @main() { ret i32 0 }\n")
    reference = tmp_path / "brightened_ref.bin"
    reference.write_bytes(b"reference")

    class Client:
        def __init__(self):
            self.kwargs = []
            self.last_response_meta = {"finish_reason": "STOP", "usage_metadata": {}}

        def generate(self, prompt, **kwargs):
            self.kwargs.append(kwargs)
            return json.dumps({"source": "int main(void) { return 0; }\n"})

    client = Client()
    result = recovery.run_recovery_loop(
        ir_text=brightened.read_text(),
        output_recovered_c_path=str(tmp_path / "candidate.c"),
        case_output_dir=str(tmp_path),
        metadata={
            "input_ir": str(brightened),
            "recovery_reference_binary": str(reference),
        },
        fuzzer_callback=lambda _candidate: {
            "is_fully_equivalent": False,
            "equivalence_ratio": 100.0,
            "confirmed_equivalence_ratio": 100.0,
            "confirmed_runs": 1,
            "matches": 1,
            "mismatches": 0,
            "inconclusive": 0,
        },
        config=RecoveryConfig(
            max_iterations=5,
            pseudo_backend="ghidra",
            use_file_api=True,
            require_json=True,
        ),
        model_client=client,
    )
    assert result.success is True
    assert client.kwargs[0]["attachment_paths"] == [
        str(tmp_path / "ghidra_recovery_input.c")
    ]


def test_p0_consumes_at_most_five_accepted_responses(
    tmp_path, monkeypatch
):
    monkeypatch.setattr(
        recovery, "_run_compile_check", lambda *_args, **_kwargs: (True, None)
    )

    class AlwaysRespondingClient:
        def __init__(self):
            self.calls = []
            self.last_response_meta = {
                "finish_reason": "STOP",
                "usage_metadata": {},
            }

        def generate(self, prompt, **kwargs):
            self.calls.append((prompt, kwargs))
            return json.dumps(
                {"source": "int main(void) { return 0; }\n"}
            )

    client = AlwaysRespondingClient()
    result = recovery.run_recovery_loop(
        ir_text="define i32 @main() { ret i32 0 }\n",
        output_recovered_c_path=str(tmp_path / "candidate.c"),
        case_output_dir=str(tmp_path),
        fuzzer_callback=lambda _candidate: {
            "is_fully_equivalent": False,
            "equivalence_ratio": 0.0,
            "matches": 0,
            "mismatches": 1,
            "inconclusive": 0,
        },
        config=RecoveryConfig(
            max_iterations=5,
            pseudo_backend="ir",
            use_file_api=False,
            require_json=True,
        ),
        model_client=client,
    )

    assert result.success is False
    assert result.iterations == 5
    assert len(client.calls) == 5
    assert len(list(tmp_path.glob("recovery_iter*.response.txt"))) == 5


def test_p0_rate_limit_retries_same_iteration_and_prompt(
    tmp_path, monkeypatch
):
    monkeypatch.setattr(
        recovery, "_run_compile_check", lambda *_args, **_kwargs: (True, None)
    )
    client = P0RateLimitedClient()
    clock = FakeClock()
    controller = QuotaController(
        quota_config(),
        tmp_path,
        method="P0",
        sleep_fn=clock.sleep,
        now_fn=clock.now,
    )
    config = RecoveryConfig(
        max_iterations=5,
        pseudo_backend="ir",
        use_file_api=False,
        require_json=True,
    )
    result = recovery.run_recovery_loop(
        ir_text="define i32 @main() { ret i32 0 }",
        output_recovered_c_path=str(tmp_path / "candidate.c"),
        case_output_dir=str(tmp_path),
        config=config,
        model_client=client,
        request_executor=controller.execute,
        resume_state_path=str(tmp_path / "recovery_state.json"),
    )

    assert result.success is True
    assert result.iterations == 1
    assert len(client.prompts) == 2
    assert client.prompts[0] == client.prompts[1]
    assert controller.metrics()["api_attempt_count"] == 2
    assert controller.metrics()["accepted_model_call_count"] == 1


def test_p0_resume_refuses_request_hash_drift(tmp_path):
    ir_text = "define i32 @main() { ret i32 0 }"
    (tmp_path / "recovery_state.json").write_text(
        json.dumps(
            {
                "schema_version": "1.0",
                "status": "REQUEST_PENDING",
                "iteration": 1,
                "max_iterations": 5,
                "ir_sha256": hashlib.sha256(ir_text.encode()).hexdigest(),
                "request_sha256": "0" * 64,
                "candidate": "",
                "last_error": None,
                "last_report": None,
            }
        )
    )
    client = P0RateLimitedClient()

    with pytest.raises(
        recovery.RecoveryError, match="exact request hash drifted"
    ):
        recovery.run_recovery_loop(
            ir_text=ir_text,
            output_recovered_c_path=str(tmp_path / "candidate.c"),
            case_output_dir=str(tmp_path),
            config=RecoveryConfig(
                max_iterations=5,
                pseudo_backend="ir",
                use_file_api=False,
                require_json=True,
            ),
            model_client=client,
            resume_state_path=str(tmp_path / "recovery_state.json"),
        )
    assert client.prompts == []


def test_runner_persists_waiting_status_and_quota_audit(tmp_path):
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["_config_sha256"] = "test-config"
    config["paths"]["result_root"] = str(tmp_path)
    config["llm"]["fake_response_path"] = str(
        PROJECT_ROOT / "tests/experiments/fixtures/fake_candidate.c"
    )
    runner = ExperimentRunner(
        str(PROJECT_ROOT / "data/custom_dataset.csv"),
        config,
        "quota-runner-test",
        pilot=1,
    )
    sample = runner.samples[0]
    result = VariantResult.enrolled("quota-runner-test", sample, MethodId.B0)
    callback = runner._quota_event_callback(sample, result)
    payload = {
        "request_sha256": "frozen",
        "iteration": 1,
        "max_iterations": 1,
        "api_attempt_count": 1,
        "accepted_model_call_count": 0,
        "quota_throttle_count": 1,
        "quota_wait_duration_ms": 0,
        "wait_seconds": 3600,
        "next_retry_at_utc": "2026-07-24T01:00:00+00:00",
    }

    callback("quota_throttled", payload)
    callback("quota_wait_started", payload)
    waiting = load_json(
        runner.run_root / "samples" / sample.sample_id / "B0/result.json"
    )
    assert waiting["terminal_status"] == "WAITING_FOR_QUOTA"
    assert waiting["final_stage"] == "generation"
    assert waiting["provenance"]["quota"]["request_sha256"] == "frozen"

    resumed_payload = dict(payload)
    resumed_payload["quota_wait_duration_ms"] = 3_600_000
    callback("quota_resumed", resumed_payload)
    resumed = load_json(
        runner.run_root / "samples" / sample.sample_id / "B0/result.json"
    )
    assert resumed["terminal_status"] == "CANCELLED"
    event_types = [
        json.loads(line)["event_type"]
        for line in (runner.run_root / "audit/events.jsonl")
        .read_text()
        .splitlines()
    ]
    assert event_types == [
        "quota_throttled",
        "variant_checkpoint",
        "quota_wait_started",
        "variant_checkpoint",
        "quota_resumed",
        "variant_checkpoint",
    ]


def test_waiting_variant_defers_union_corpus_freeze(tmp_path):
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["_config_sha256"] = "union-quota-config"
    config["paths"]["result_root"] = str(tmp_path)
    config["llm"]["fake_response_path"] = str(
        PROJECT_ROOT / "tests/experiments/fixtures/fake_candidate.c"
    )
    runner = ExperimentRunner(
        str(PROJECT_ROOT / "data/custom_dataset.csv"),
        config,
        "union-quota-test",
        pilot=1,
    )
    sample = runner.samples[0]
    for method in runner.methods:
        payload = VariantResult.enrolled(
            "union-quota-test", sample, method
        ).to_dict()
        if method is MethodId.B0:
            payload["terminal_status"] = "WAITING_FOR_QUOTA"
            payload["final_stage"] = "generation"
        else:
            candidate = (
                runner.run_root
                / "samples"
                / sample.sample_id
                / method.value
                / "candidate.c"
            )
            executable = candidate.with_suffix(".bin")
            candidate.parent.mkdir(parents=True, exist_ok=True)
            candidate.write_text("int main(void){return 0;}\n")
            executable.write_bytes(b"test")
            payload["terminal_status"] = "CANCELLED"
            payload["final_stage"] = "fuzz_discovery"
            payload["generation"] = {
                "candidate_path": str(candidate),
                "candidate_sha256": hashlib.sha256(
                    candidate.read_bytes()
                ).hexdigest(),
            }
            payload["build"] = {
                "ok": True,
                "executable_path": str(executable),
            }
        result_path = runner._result_path(sample, method)
        result_path.parent.mkdir(parents=True, exist_ok=True)
        result_path.write_text(json.dumps(payload))

    runner._evaluate_sample(sample)

    assert runner._sample_evaluation_blockers(sample) == [
        "B0:waiting_for_quota"
    ]
    assert not (
        runner.run_root
        / "samples"
        / sample.sample_id
        / "common"
        / "union_corpus_manifest.json"
    ).exists()
    events = [
        json.loads(line)
        for line in (runner.run_root / "audit/events.jsonl")
        .read_text()
        .splitlines()
    ]
    assert events[-1]["event_type"] == "sample_processing_comparison_deferred"
    assert events[-1]["payload"]["blockers"] == [
        "B0:waiting_for_quota"
    ]


def test_resume_rejects_changed_enrolled_sample_set(tmp_path):
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["_config_sha256"] = "sample-freeze-config"
    config["paths"]["result_root"] = str(tmp_path)
    config["llm"]["fake_response_path"] = str(
        PROJECT_ROOT / "tests/experiments/fixtures/fake_candidate.c"
    )
    dataset = str(PROJECT_ROOT / "data/custom_dataset.csv")
    first = ExperimentRunner(
        dataset, config, "sample-freeze", pilot=1
    )
    first.initialize()

    changed = ExperimentRunner(
        dataset, config, "sample-freeze", pilot=2
    )
    with pytest.raises(
        RunIntegrityError, match="enrolled sample set"
    ):
        changed.initialize()


def test_run_id_rejects_path_traversal(tmp_path):
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["_config_sha256"] = "run-id-config"
    config["paths"]["result_root"] = str(tmp_path)
    config["llm"]["fake_response_path"] = str(
        PROJECT_ROOT / "tests/experiments/fixtures/fake_candidate.c"
    )
    with pytest.raises(RunIntegrityError, match="run_id"):
        ExperimentRunner(
            str(PROJECT_ROOT / "data/custom_dataset.csv"),
            config,
            "../../outside",
            pilot=1,
        )
