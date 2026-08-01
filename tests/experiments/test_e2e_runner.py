import copy
import hashlib
import json
import sys
import threading
from contextlib import nullcontext
from pathlib import Path
from types import SimpleNamespace


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from experiments import cli as cli_module  # noqa: E402
from experiments import p0_legacy as p0_module  # noqa: E402
from experiments import runner as runner_module  # noqa: E402
from experiments.cli import _parser  # noqa: E402
from experiments.config import DEFAULT_CONFIG  # noqa: E402
from experiments.enums import MethodId, Stage, TerminalStatus  # noqa: E402
from experiments.evaluation import prepare_base_corpus  # noqa: E402
from experiments.models import RepresentationArtifact  # noqa: E402
from experiments.p0_legacy import P0LegacyAdapter  # noqa: E402
from experiments.runner import ExperimentRunner  # noqa: E402


class RecordingAudit:
    def __init__(self):
        self.events = []

    def log(self, event_type, **kwargs):
        self.events.append((event_type, kwargs))


def test_e2e_alias_is_accepted():
    args = _parser().parse_args(
        [
            "e2e",
            "dataset.csv",
            "--config",
            "experiment.yaml",
            "--run-id",
            "test-run",
        ]
    )

    assert args.command == "e2e"


def test_process_subcommand_is_accepted():
    args = _parser().parse_args(
        [
            "process",
            "dataset.csv",
            "--config",
            "experiment.yaml",
            "--run-id",
            "test-run",
        ]
    )

    assert args.command == "process"


def test_refuzz_defaults_to_a0_b0_only():
    args = _parser().parse_args(
        [
            "refuzz",
            "dataset.csv",
            "--run-id",
            "test-run",
        ]
    )

    assert args.command == "refuzz"
    assert args.mode == "ab"


def test_refuzz_cli_dispatches_without_running_e2e(monkeypatch):
    actions = []
    fake_runner = SimpleNamespace(
        refuzz=lambda: actions.append("refuzz"),
        command_lock=lambda _command: nullcontext(),
    )
    monkeypatch.setattr(
        cli_module, "_runner_from_args", lambda _args: fake_runner
    )

    exit_code = cli_module.main(
        ["refuzz", "dataset.csv", "--run-id", "test-run"]
    )

    assert exit_code == 0
    assert actions == ["refuzz"]


def test_e2e_cli_reports_checkpointed_incomplete_run(
    monkeypatch,
):
    fake_runner = SimpleNamespace(
        run=lambda: False,
        command_lock=lambda _command: nullcontext(),
    )
    monkeypatch.setattr(
        cli_module, "_runner_from_args", lambda _args: fake_runner
    )

    exit_code = cli_module.main(
        [
            "e2e",
            "dataset.csv",
            "--config",
            "experiment.yaml",
            "--run-id",
            "test-run",
        ]
    )

    assert exit_code == 75


def test_command_lock_rejects_concurrent_command_for_same_run(tmp_path):
    first = object.__new__(ExperimentRunner)
    first.run_id = "shared-run"
    first.run_root = tmp_path / "shared-run"
    second = object.__new__(ExperimentRunner)
    second.run_id = first.run_id
    second.run_root = first.run_root

    with first.command_lock("e2e"):
        try:
            with second.command_lock("evaluate"):
                raise AssertionError("concurrent command unexpectedly acquired lock")
        except runner_module.RunIntegrityError as exc:
            message = str(exc)

    assert "already active" in message
    assert '"command": "e2e"' in message


def test_command_lock_is_released_after_command(tmp_path):
    first = object.__new__(ExperimentRunner)
    first.run_id = "reusable-run"
    first.run_root = tmp_path / "reusable-run"
    second = object.__new__(ExperimentRunner)
    second.run_id = first.run_id
    second.run_root = first.run_root

    with first.command_lock("e2e"):
        pass
    with second.command_lock("evaluate"):
        pass


def test_prepared_base_corpus_is_validated(tmp_path):
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["_config_sha256"] = "input-preparation-test"
    config["paths"]["result_root"] = str(tmp_path)
    runner = ExperimentRunner(
        str(PROJECT_ROOT / "data/custom_dataset.csv"),
        config,
        "input-preparation-test",
        pilot=1,
    )
    sample = runner.samples[0]

    prepare_base_corpus(
        sample,
        runner._sample_dir(sample) / "common" / "base_corpus",
        config,
    )

    assert runner._prepared_input_available(sample) is True
    manifest = json.loads(
        runner._base_corpus_manifest_path(sample).read_text()
    )
    first_input = Path(manifest["inputs"][0]["path"])
    first_input.write_bytes(first_input.read_bytes() + b"corrupt")
    assert runner._prepared_input_available(sample) is False


def test_preparation_freezes_all_method_inputs_without_generation(tmp_path):
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["_config_sha256"] = "three-phase-preparation"
    config["paths"]["result_root"] = str(tmp_path)
    runner = ExperimentRunner(
        str(PROJECT_ROOT / "data/custom_dataset.csv"),
        config,
        "three-phase-preparation",
        pilot=1,
    )
    sample = runner.samples[0]
    for method in runner.methods:
        (runner._sample_dir(sample) / method.value).mkdir(
            parents=True, exist_ok=True
        )

    def freeze(method, output_dir, suffix):
        output = Path(output_dir)
        output.mkdir(parents=True, exist_ok=True)
        primary = output / f"model_input{suffix}"
        primary.write_text(f"frozen {method.value} evidence\n")
        digest = hashlib.sha256(primary.read_bytes()).hexdigest()
        artifact = RepresentationArtifact(
            method=method,
            primary_path=str(primary),
            primary_sha256=digest,
            byte_count=primary.stat().st_size,
            token_count=1,
            builder_version="test-preparation",
            attachment_paths=[str(primary)],
            attachment_sha256=[digest],
            provenance={"prepared_without_llm": True},
        )
        (output / "representation_manifest.json").write_text(
            json.dumps(artifact.to_dict())
        )
        return artifact

    runner.p0_adapter = SimpleNamespace(
        prepare=lambda _sample, _common, variant: freeze(
            MethodId.P0, Path(variant) / "representation", ".c"
        )
    )
    runner.a0_builder = SimpleNamespace(
        build=lambda _sample, _common, output: freeze(
            MethodId.A0, output, ".ll"
        )
    )
    runner.b0_builder = SimpleNamespace(
        build=lambda _sample, output: freeze(MethodId.B0, output, ".c")
    )

    runner._prepare_input_sample(sample)

    preparation = json.loads(
        (runner._sample_dir(sample) / "preparation_manifest.json").read_text()
    )
    assert preparation["llm_calls"] == 0
    assert preparation["fuzz_calls"] == 0
    assert set(preparation["representations"]) == {"P0", "A0", "B0"}
    assert all(
        entry["status"] == "ready_for_llm"
        for entry in preparation["representations"].values()
    )
    for method in runner.methods:
        result = json.loads(runner._result_path(sample, method).read_text())
        assert result["representation"] is not None
        assert result["generation"] is None
        assert result["final_stage"] == Stage.GENERATION.value


def test_p0_preparation_does_not_start_fuzzing_or_llm(
    tmp_path, monkeypatch
):
    original = tmp_path / "original.bin"
    original.write_bytes(b"ELF")
    sample = SimpleNamespace(
        sample_id="sample-1",
        original_elf_path=str(original),
        original_elf_sha256=hashlib.sha256(original.read_bytes()).hexdigest(),
    )
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)

    class FakeLift:
        def build(self, _sample, output_dir):
            output = Path(output_dir)
            output.mkdir(parents=True, exist_ok=True)
            raw_bc = output / "raw.bc"
            raw_bc.write_bytes(b"raw bitcode")
            return {"raw_bc_path": str(raw_bc), "cache_key": "test"}

    def fake_brighten(_raw_bc, brightened_bc, **_kwargs):
        target = Path(brightened_bc)
        target.write_bytes(b"brightened bitcode")
        target.with_suffix(".ll").write_text(
            "define i32 @main() { ret i32 0 }\n"
        )
        return True

    def fake_compile(_source, output):
        Path(output).write_bytes(b"reference executable")

    def fake_export(_binary, output, **_kwargs):
        source = "// Function: main\nint main(void) { return 0; }\n"
        Path(output).write_text(source)
        return source

    monkeypatch.setattr(p0_module, "brighten_ir", fake_brighten)
    monkeypatch.setattr(
        p0_module, "read_native_contract_report", lambda _path: {}
    )
    monkeypatch.setattr(p0_module, "compile_to_binary", fake_compile)
    monkeypatch.setattr(p0_module, "export_ghidra_pseudocode", fake_export)
    monkeypatch.setattr(
        p0_module,
        "SemanticFuzzer",
        lambda *_args, **_kwargs: (_ for _ in ()).throw(
            AssertionError("preparation must not start fuzzing")
        ),
    )
    adapter = P0LegacyAdapter(config, FakeLift())

    representation = adapter.prepare(
        sample, tmp_path / "common", tmp_path / "P0"
    )

    assert representation.provenance["prepared_without_llm"] is True
    assert Path(representation.provenance["pseudocode_path"]).is_file()
    assert not (tmp_path / "P0" / "generation").exists()
    assert not (tmp_path / "P0" / "p0_internal_precheck.json").exists()


def test_p0_failed_internal_precheck_is_diagnostic_and_uses_original_oracle(
    tmp_path, monkeypatch
):
    original = tmp_path / "original.elf"
    original.write_bytes(b"original")
    delifted = tmp_path / "delifted.ll"
    delifted.write_text("define i32 @main() { ret i32 0 }\n")
    brightened_bc = tmp_path / "brightened.bc"
    brightened_bc.write_bytes(b"brightened")
    internal_reference = tmp_path / "delifted_ref.bin"
    internal_reference.write_bytes(b"internal-reference")
    pseudocode = tmp_path / "ghidra_pseudocode.c"
    pseudocode.write_text(
        "// Function: main\nint main(void) { return 0; }\n"
    )
    fake_response = tmp_path / "fake_response.c"
    fake_response.write_text("int main(void) { return 0; }\n")

    sample = SimpleNamespace(
        sample_id="sample-1",
        original_elf_path=str(original),
        original_elf_sha256=hashlib.sha256(original.read_bytes()).hexdigest(),
    )
    representation = RepresentationArtifact(
        method=MethodId.P0,
        primary_path=str(delifted),
        primary_sha256=hashlib.sha256(delifted.read_bytes()).hexdigest(),
        byte_count=delifted.stat().st_size,
        token_count=1,
        builder_version="test",
        attachment_paths=[str(pseudocode)],
        attachment_sha256=[
            hashlib.sha256(pseudocode.read_bytes()).hexdigest()
        ],
        provenance={
            "pseudocode_path": str(pseudocode),
            "pseudocode_sha256": hashlib.sha256(
                pseudocode.read_bytes()
            ).hexdigest(),
            "internal_reference": str(internal_reference),
            "internal_reference_sha256": hashlib.sha256(
                internal_reference.read_bytes()
            ).hexdigest(),
            "brightened_bc_path": str(brightened_bc),
            "brightened_bc_sha256": hashlib.sha256(
                brightened_bc.read_bytes()
            ).hexdigest(),
        },
    )
    config = copy.deepcopy(DEFAULT_CONFIG)
    config["_project_root"] = str(PROJECT_ROOT)
    config["llm"]["fake_response_path"] = str(fake_response)

    fuzzer_targets = []

    class FakeFuzzer:
        def __init__(self, file1, file2, **_kwargs):
            self.file1 = file1
            self.file2 = file2
            fuzzer_targets.append(file2)

    reports = [
        {
            "is_fully_equivalent": False,
            "confirmed_runs": 1,
            "mismatches": 1,
            "confirmed_equivalence_ratio": 0.0,
            "tested_payloads": [],
        },
        {
            "is_fully_equivalent": True,
            "confirmed_runs": 1,
            "mismatches": 0,
            "confirmed_equivalence_ratio": 100.0,
            "tested_payloads": [],
        },
    ]

    monkeypatch.setattr(p0_module, "SemanticFuzzer", FakeFuzzer)
    monkeypatch.setattr(
        p0_module, "_select_generator", lambda *_args: (None, "test")
    )
    monkeypatch.setattr(
        p0_module, "_resolve_seed_paths", lambda *_args: ([], None)
    )
    monkeypatch.setattr(
        p0_module, "resolve_input_contract", lambda *_args, **_kwargs: None
    )
    monkeypatch.setattr(
        p0_module,
        "_run_fuzzer_sync",
        lambda *_args, **_kwargs: reports.pop(0),
    )

    def fake_recovery_loop(
        *,
        output_recovered_c_path,
        case_output_dir,
        fuzzer_callback,
        **_kwargs,
    ):
        candidate = Path(output_recovered_c_path)
        candidate.write_text("int main(void) { return 0; }\n")
        Path(case_output_dir, "ghidra_pseudocode.c").write_bytes(
            pseudocode.read_bytes()
        )
        report = fuzzer_callback(str(candidate))
        return p0_module.RecoveryResult(
            success=True,
            source_path=str(candidate),
            iterations=1,
            fuzz_report=report,
        )

    monkeypatch.setattr(
        p0_module, "run_recovery_loop", fake_recovery_loop
    )
    adapter = P0LegacyAdapter(config, SimpleNamespace())
    result = adapter.process(
        sample,
        tmp_path / "P0",
        representation=representation,
    )

    assert result.internal_precheck_passed is False
    assert result.recovery_oracle_path == str(original)
    assert fuzzer_targets == [str(original), str(original)]
    assert result.generation.response_metadata[
        "internal_precheck_passed"
    ] is False


def test_run_executes_prepare_process_compare_then_evaluate_in_one_call(
    tmp_path, monkeypatch
):
    runner = object.__new__(ExperimentRunner)
    sample = SimpleNamespace(sample_id="sample-1")
    runner.samples = [sample]
    runner.methods = [MethodId.P0]
    runner.execution_order = [MethodId.P0]
    runner.run_id = "e2e-test"
    runner.run_root = tmp_path / "e2e-test"
    runner.config = copy.deepcopy(DEFAULT_CONFIG)
    runner.config["paths"]["result_root"] = str(tmp_path)
    runner.config["experiment"]["sample_workers"] = 1
    runner.config["experiment"]["resume"] = True
    runner.audit = RecordingAudit()
    actions = []
    prepared = {"value": False}

    def initialize():
        actions.append("initialize")
        runner.run_root.mkdir(parents=True, exist_ok=True)

    def prepare(_sample):
        actions.append("prepare")
        prepared["value"] = True

    def process(current_sample):
        actions.append("process")
        variant_dir = runner._sample_dir(current_sample) / "P0"
        candidate = variant_dir / "candidate.c"
        executable = variant_dir / "candidate.bin"
        candidate.parent.mkdir(parents=True, exist_ok=True)
        candidate.write_text("int main(void) { return 0; }\n")
        executable.write_bytes(b"executable")
        result = {
            "final_stage": Stage.FUZZ_DISCOVERY.value,
            "terminal_status": TerminalStatus.CANCELLED.value,
            "failure_code": None,
            "generation": {"candidate_path": str(candidate)},
            "build": {
                "ok": True,
                "executable_path": str(executable),
            },
        }
        result_path = runner._result_path(current_sample, MethodId.P0)
        result_path.write_text(json.dumps(result))

    def compare(current_sample):
        actions.append("compare")
        result_path = runner._result_path(current_sample, MethodId.P0)
        result = json.loads(result_path.read_text())
        result["final_stage"] = Stage.FINALIZED.value
        result["terminal_status"] = TerminalStatus.PASS.value
        result_path.write_text(json.dumps(result))

    runner.initialize = initialize
    runner._prepare_base_input = lambda current_sample: (
        prepare(current_sample) or []
    )
    runner._prepare_method_representation = (
        lambda _sample, _method: {"status": "ready_for_llm"}
    )
    runner._write_preparation_manifest = lambda *_args: None
    runner._generate_sample = process
    runner._process_comparison_sample = compare
    runner._sample_processing_output_ready = (
        lambda current_sample: runner._sample_processing_ready(current_sample)
    )
    runner._aggregate_outputs = lambda: actions.append("aggregate") or {}
    runner._seal_audit = lambda _command: actions.append("seal")
    monkeypatch.setattr(
        runner_module,
        "verify_run_integrity",
        lambda *_args, **_kwargs: actions.append("verify") or {"passed": True},
    )

    completed = runner.run()

    assert completed is True
    assert actions == [
        "initialize",
        "prepare",
        "process",
        "compare",
        "aggregate",
        "seal",
        "verify",
    ]


def test_streaming_preparation_does_not_let_p0_block_a0_or_b0():
    runner = object.__new__(ExperimentRunner)
    sample = SimpleNamespace(sample_id="sample-1")
    runner.samples = [sample]
    runner.methods = [MethodId.P0, MethodId.A0, MethodId.B0]
    runner.execution_order = list(runner.methods)
    runner.config = copy.deepcopy(DEFAULT_CONFIG)
    runner.audit = RecordingAudit()

    fast_methods_ready = threading.Event()
    fast_ready_count = 0
    ready_lock = threading.Lock()

    def prepare_method(_sample, method):
        nonlocal fast_ready_count
        if method is MethodId.P0:
            assert fast_methods_ready.wait(timeout=1.0)
        else:
            with ready_lock:
                fast_ready_count += 1
                if fast_ready_count == 2:
                    fast_methods_ready.set()
        return {"status": "ready_for_llm"}

    runner._prepare_base_input = lambda _sample: []
    runner._prepare_method_representation = prepare_method
    runner._sample_generation_ready = lambda _sample: True
    runner._sample_processing_ready = lambda _sample: True
    runner._write_preparation_manifest = lambda *_args: None
    runner._sample_complete = lambda _sample: False
    runner._run_samples = (
        lambda _phase, operation, _is_complete: operation(sample)
    )

    runner._run_streaming_cases()

    assert fast_ready_count == 2


def test_generation_ready_rejects_quota_wait(tmp_path):
    runner = object.__new__(ExperimentRunner)
    sample = SimpleNamespace(sample_id="sample-1")
    runner.run_root = tmp_path
    runner.execution_order = [MethodId.B0]
    runner.config = copy.deepcopy(DEFAULT_CONFIG)
    result_path = runner._result_path(sample, MethodId.B0)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(
        json.dumps(
            {
                "final_stage": Stage.GENERATION.value,
                "terminal_status": TerminalStatus.WAITING_FOR_QUOTA.value,
                "failure_code": "B0_QUOTA_WAIT_EXCEEDED",
            }
        )
    )

    assert runner._sample_generation_ready(sample) is False


def test_terminal_llm_failure_is_ready_for_aggregate(tmp_path):
    runner = object.__new__(ExperimentRunner)
    sample = SimpleNamespace(sample_id="sample-1")
    runner.run_root = tmp_path
    runner.execution_order = [MethodId.A0]
    runner.config = copy.deepcopy(DEFAULT_CONFIG)
    runner.config["_p0_backfill"] = False
    result_path = runner._result_path(sample, MethodId.A0)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(
        json.dumps(
            {
                "final_stage": Stage.FINALIZED.value,
                "terminal_status": TerminalStatus.LLM_REQUEST_FAILED.value,
                "failure_code": "A0_LLM_REQUEST_FAILED",
            }
        )
    )

    assert runner._sample_generation_ready(sample) is True
    assert runner._sample_processing_ready(sample) is True


def test_evaluate_only_aggregates_frozen_processing_results(
    tmp_path, monkeypatch
):
    runner = object.__new__(ExperimentRunner)
    runner.samples = [SimpleNamespace(sample_id="sample-1")]
    runner.methods = [MethodId.P0]
    runner.run_root = tmp_path
    runner.config = copy.deepcopy(DEFAULT_CONFIG)
    runner.audit = RecordingAudit()
    actions = []
    runner.initialize = lambda: actions.append("initialize")
    runner._sample_processing_ready = lambda _sample: True
    runner._sample_processing_output_ready = lambda _sample: True
    runner._aggregate_outputs = (
        lambda: actions.append("aggregate") or {"variant_count": 1}
    )
    runner._seal_audit = lambda _command: actions.append("seal")
    runner._process_comparison_sample = lambda _sample: actions.append(
        "unexpected-fuzz"
    )
    monkeypatch.setattr(
        runner_module,
        "verify_run_integrity",
        lambda *_args, **_kwargs: actions.append("verify") or {"passed": True},
    )

    result = runner.evaluate()

    assert result == {"variant_count": 1}
    assert actions == ["initialize", "aggregate", "seal", "verify"]
