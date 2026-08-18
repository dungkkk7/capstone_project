#!/usr/bin/env python3
"""Run the primary B0-versus-F3 evaluation.

This entry point intentionally does not schedule the historical F1/F2/F4/F5/F6
ablations.  Those artifacts remain reproducible through the legacy exporter,
but they are not evidence for the primary research claim.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Optional


SRC_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = SRC_ROOT.parent
sys.path.insert(0, str(SRC_ROOT))

from binary_lifting.lifting import lift_binary
from evaluation.assembly_baseline import DEFAULT_OBJDUMP, export_program_assembly
from evaluation.ghidra_baseline import DEFAULT_GHIDRA_HEADLESS, export_program_pseudocode
from evaluation.run_experiment import (
    DEFAULT_MODEL,
    CaseTracker,
    _run_compile_check_tracked,
    run_deobfuscation_metrics,
    run_flow_experiment,
    run_fuzzing_tracked,
)
from evaluation.two_flow_protocol import (
    EVALUATION_FLOW_ORDER,
    EVALUATION_FLOWS,
    PRIMARY_FLOW_ORDER,
    PRIMARY_FLOWS,
    build_b0_prompt,
    build_b2_prompt,
    protocol_manifest,
    sha256_text,
)
from fuzzing_equi_check.input_contracts import resolve_input_contract
from llvm_pass.britening_ir import brighten_ir, finalize_ir
from llm_recovery.llm_recovery import RecoveryConfig, VertexGemini, extract_c_source
from main import _resolve_seed_paths, _select_generator


def _atomic_json(path: Path, payload: Any) -> None:
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True, default=str)
        + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _git_state() -> dict[str, Any]:
    revision = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    return {
        "commit": revision.stdout.strip() if revision.returncode == 0 else None,
        "worktree_dirty": bool(status.stdout.strip()) if status.returncode == 0 else None,
    }


def _implementation_hashes() -> dict[str, str]:
    files = (
        Path(__file__).resolve(),
        Path(__file__).resolve().with_name("two_flow_protocol.py"),
        Path(__file__).resolve().with_name("schema.py"),
        Path(__file__).resolve().with_name("assembly_baseline.py"),
        Path(__file__).resolve().with_name("ghidra_baseline.py"),
        Path(__file__).resolve().with_name("run_experiment.py"),
        Path(__file__).resolve().parent / "ghidra" / "ExportProgramDecomp.java",
        PROJECT_ROOT / "configs" / "prompts_config.py",
        PROJECT_ROOT / "src" / "llm_recovery" / "llm_recovery.py",
        PROJECT_ROOT / "src" / "llvm_pass" / "britening_ir.py",
        PROJECT_ROOT
        / "src"
        / "llvm_pass"
        / "brighten_100_delift_bundle"
        / "run_brighten_delift_pipeline.sh",
    )
    return {
        str(path.relative_to(PROJECT_ROOT)): _sha256_file(path) for path in files
    }


def _write_case_preflight(
    case: dict[str, str],
    contract: dict[str, Any],
    seeds: list[str],
    generator_reason: str,
) -> None:
    payload = {
        "original_binary": case["binary"],
        "original_binary_sha256": _sha256_file(Path(case["binary"])),
        "input_contract": contract,
        "input_contract_sha256": sha256_text(
            json.dumps(contract, sort_keys=True, separators=(",", ":"))
        ),
        "generator_reason": generator_reason,
        "seeds": [
            {"path": seed, "sha256": _sha256_file(Path(seed))} for seed in seeds
        ],
    }
    path = Path(case["case_dir"]) / "paired_preflight.json"
    if path.is_file():
        previous = json.loads(path.read_text(encoding="utf-8"))
        if previous != payload:
            raise RuntimeError(
                f"Refusing resume because paired preflight changed for {case['sample_id']}"
            )
        return
    _atomic_json(path, payload)


class StrictOneShotVertexGemini(VertexGemini):
    """Provider client that permits one physical request and never retries."""

    def __init__(self, config: RecoveryConfig, tracker: CaseTracker):
        super().__init__(config)
        self.tracker = tracker

    def generate(
        self,
        prompt: str,
        attachment_path: Optional[str] = None,
        attachment_paths: Optional[list[str]] = None,
        system_instruction: Optional[str] = None,
    ) -> str:
        if self.tracker.llm_calls != 0:
            raise RuntimeError("B0 forbids provider retry or repair calls")
        self.tracker.llm_calls = 1
        started = time.perf_counter()
        try:
            response = super().generate(
                prompt,
                attachment_path=attachment_path,
                attachment_paths=attachment_paths,
                system_instruction=system_instruction,
            )
        finally:
            self.tracker.llm_latency += time.perf_counter() - started

        metadata = dict(self.last_response_meta or {})
        usage = metadata.get("usage_metadata") or {}
        self.tracker.input_tokens += int(
            usage.get("prompt_tokens")
            or usage.get("prompt_token_count")
            or usage.get("promptTokenCount")
            or 0
        )
        self.tracker.output_tokens += int(
            usage.get("completion_tokens")
            or usage.get("candidates_token_count")
            or usage.get("candidatesTokenCount")
            or 0
        )
        return response


def run_b0_experiment(
    *,
    sample_id: str,
    original_binary: str,
    case_output_dir: str,
    contract: Any,
    generator: Any,
    seeds: list[str],
    iterations: int,
    model: str,
    location: str,
    ghidra_headless: str,
    original_src: Optional[str] = None,
) -> CaseTracker:
    """Execute exactly one paper-derived Ghidra-to-LLM provider call."""

    tracker = CaseTracker(sample_id, "B0")
    started = time.perf_counter()
    flow_dir = Path(case_output_dir) / "B0"
    flow_dir.mkdir(parents=True, exist_ok=True)
    try:
        pseudocode = export_program_pseudocode(
            original_binary,
            flow_dir / "representation",
            ghidra_headless=ghidra_headless,
        )
        tracker.stage_pseudocode = True
        pseudo_text = pseudocode.read_text(encoding="utf-8", errors="replace")
        prompt = build_b0_prompt(pseudo_text)
        request = {
            "flow": PRIMARY_FLOWS["B0"].__dict__,
            "protocol": protocol_manifest(),
            "model": model,
            "location": location,
            "logical_provider_call_budget": 1,
            "system_instruction": None,
            "prompt_path": str(flow_dir / "request.prompt.txt"),
            "prompt_sha256": sha256_text(prompt),
            "representation_path": str(pseudocode),
            "representation_sha256": _sha256_file(pseudocode),
            "forbidden_feedback": [
                "compiler diagnostics",
                "test output",
                "counterexamples",
                "repair prompt",
            ],
        }
        (flow_dir / "request.prompt.txt").write_text(prompt, encoding="utf-8")
        _atomic_json(flow_dir / "request.json", request)
        _atomic_json(
            flow_dir / "flow_contract.json",
            {
                **PRIMARY_FLOWS["B0"].__dict__,
                "protocol_version": protocol_manifest()["protocol_version"],
            },
        )

        config = RecoveryConfig()
        config.model = model
        config.location = location
        config.max_iterations = 1
        config.require_json = False
        client = StrictOneShotVertexGemini(config, tracker)
        response = client.generate(prompt, system_instruction=None)
        (flow_dir / "response.txt").write_text(response, encoding="utf-8")
        _atomic_json(
            flow_dir / "response.meta.json",
            dict(client.last_response_meta or {}),
        )
        if tracker.llm_calls != 1:
            raise RuntimeError(
                f"B0 violated one-shot contract: logical calls={tracker.llm_calls}"
            )

        candidate = extract_c_source(response, require_json=False)
        candidate_path = flow_dir / "recovered_iter1.c"
        candidate_path.write_text(candidate, encoding="utf-8")
        (flow_dir / f"{sample_id}_recovered.c").write_text(
            candidate, encoding="utf-8"
        )
        tracker.first_candidate = candidate
        tracker.final_candidate = candidate
        tracker.stage_llm_gen = True

        compiled, _diagnostics = _run_compile_check_tracked(
            str(candidate_path), str(flow_dir), tracker
        )
        tracker.compile_success_first = compiled
        tracker.compile_success_final = compiled
        tracker.any_compile_success_within_budget = compiled
        tracker.last_candidate_compile_success = compiled
        tracker.compile_repair_rounds = 0
        tracker.behavioral_repair_rounds = 0
        tracker.behavioral_repairs = 0
        if compiled:
            tracker.stage_compilation = True
            report = run_fuzzing_tracked(
                str(candidate_path),
                original_binary,
                contract,
                generator,
                seeds,
                tracker,
                iterations,
            )
            tracker.stage_fuzzing = tracker.fuzz_total > 0
            mismatches = int(report.get("mismatches", 0) or 0)
            if tracker.fuzz_total > 0 and mismatches == 0:
                tracker.status = "PASS"
                tracker.stage_behavioral_validation = True
            elif mismatches > 0:
                tracker.status = "FAIL_BEHAVIORAL"
            else:
                tracker.status = "INCONCLUSIVE"
        else:
            tracker.status = "FAIL_COMPILE"

        if original_src and Path(original_src).is_file():
            original_lines = [
                line for line in Path(original_src).read_text(errors="ignore").splitlines()
                if line.strip() and not line.lstrip().startswith("//")
            ]
            candidate_lines = [
                line for line in candidate.splitlines()
                if line.strip() and not line.lstrip().startswith("//")
            ]
            tracker.original_sloc = len(original_lines)
            tracker.recovered_sloc = len(candidate_lines)
            tracker.sloc_ratio = len(candidate_lines) / max(1, len(original_lines))
    except Exception as exc:
        tracker.status = "INCONCLUSIVE"
        _atomic_json(
            flow_dir / "failure.json",
            {"type": type(exc).__name__, "message": str(exc)},
        )
    finally:
        tracker.total_runtime = time.perf_counter() - started
        # One-shot invariants remain explicit even on a failed request.
        tracker.compile_repair_rounds = 0
        tracker.behavioral_repair_rounds = 0
        tracker.behavioral_repairs = 0
        _atomic_json(flow_dir / "flow_result.json", tracker.to_dict())
    return tracker


def run_b1_experiment(
    *,
    sample_id: str,
    original_binary: str,
    case_output_dir: str,
    contract: Any,
    generator: Any,
    seeds: list[str],
    iterations: int,
    model: str,
    location: str,
    ghidra_headless: str,
    original_src: Optional[str] = None,
) -> CaseTracker:
    """Run the B0 Ghidra representation with iterative validation feedback."""

    flow_dir = Path(case_output_dir) / "B1"
    flow_dir.mkdir(parents=True, exist_ok=True)
    pseudocode = export_program_pseudocode(
        original_binary,
        flow_dir / "representation",
        ghidra_headless=ghidra_headless,
    )
    pseudo_text = pseudocode.read_text(encoding="utf-8", errors="replace")
    initial_prompt = build_b0_prompt(pseudo_text)
    _atomic_json(
        flow_dir / "b1_ablation_contract.json",
        {
            **EVALUATION_FLOWS["B1"].__dict__,
            "protocol_version": protocol_manifest()["protocol_version"],
            "representation_path": str(pseudocode),
            "representation_sha256": _sha256_file(pseudocode),
            "initial_prompt_sha256": sha256_text(initial_prompt),
            "initial_prompt_identity": "byte-identical to B0 serialization",
            "initial_system_instruction": None,
            "later_request_policy": (
                "compiler diagnostics and reproducible behavioral counterexamples"
            ),
        },
    )
    return run_flow_experiment(
        sample_id=sample_id,
        flow_id="B1",
        original_binary=original_binary,
        raw_ir=str(pseudocode),
        clean_ir=str(pseudocode),
        ref_binary=original_binary,
        contract=contract,
        generator=generator,
        seeds=seeds,
        case_output_dir=case_output_dir,
        iterations=iterations,
        model=model,
        location=location,
        original_src=original_src,
    )


def run_assembly_experiment(
    *,
    flow_id: str,
    sample_id: str,
    original_binary: str,
    case_output_dir: str,
    contract: Any,
    generator: Any,
    seeds: list[str],
    iterations: int,
    model: str,
    location: str,
    objdump: str,
    original_src: Optional[str] = None,
) -> CaseTracker:
    """Run B2/B3 from the paper-derived objdump representation."""
    if flow_id not in {"B2", "B3"}:
        raise ValueError(f"Assembly runner requires B2 or B3, got {flow_id}")
    flow_dir = Path(case_output_dir) / flow_id
    flow_dir.mkdir(parents=True, exist_ok=True)
    assembly = export_program_assembly(
        original_binary,
        flow_dir / "representation",
        objdump=objdump,
    )
    assembly_text = assembly.read_text(encoding="utf-8", errors="replace")
    initial_prompt = build_b2_prompt(assembly_text)
    _atomic_json(
        flow_dir / f"{flow_id.lower()}_assembly_contract.json",
        {
            **EVALUATION_FLOWS[flow_id].__dict__,
            "protocol_version": protocol_manifest()["protocol_version"],
            "representation_path": str(assembly),
            "representation_sha256": _sha256_file(assembly),
            "initial_prompt_sha256": sha256_text(initial_prompt),
            "initial_prompt_identity": (
                "official LLM4Decompile assembly inference serialization"
                if flow_id == "B2"
                else "byte-identical to B2 serialization"
            ),
            "initial_system_instruction": None,
            "later_request_policy": (
                None
                if flow_id == "B2"
                else "parser/compiler diagnostics and reproducible behavioral counterexamples"
            ),
        },
    )
    return run_flow_experiment(
        sample_id=sample_id,
        flow_id=flow_id,
        original_binary=original_binary,
        raw_ir=str(assembly),
        clean_ir=str(assembly),
        ref_binary=original_binary,
        contract=contract,
        generator=generator,
        seeds=seeds,
        case_output_dir=case_output_dir,
        iterations=iterations,
        model=model,
        location=location,
        original_src=original_src,
    )


def _resolve_case(row: dict[str, str], campaign_dir: Path) -> dict[str, str]:
    binary = (PROJECT_ROOT / row["obfuscated_binary"]).resolve()
    if not binary.is_file():
        raise FileNotFoundError(f"Missing obfuscated binary: {binary}")
    sample_id = binary.parent.name
    case_dir = campaign_dir / sample_id
    case_dir.mkdir(parents=True, exist_ok=True)
    clean_source = row.get("clean_source") or row.get("source_c") or ""
    original_src = str((PROJECT_ROOT / clean_source).resolve()) if clean_source else ""
    return {
        "sample_id": sample_id,
        "case_dir": str(case_dir),
        "binary": str(binary),
        "original_src": original_src,
    }


def _prepare_f3_case(case: dict[str, str]) -> dict[str, str]:
    binary = Path(case["binary"])
    sample_id = case["sample_id"]
    case_dir = Path(case["case_dir"])
    raw_bc = case_dir / f"{sample_id}.bc"
    raw_ir = case_dir / f"{sample_id}.ll"
    brightened_bc = case_dir / f"{sample_id}_brightened.bc"
    brightened_ir = case_dir / f"{sample_id}_brightened.ll"
    clean_ir = case_dir / f"{sample_id}_final.ll"
    reference = case_dir / f"{sample_id}_final.bin"

    if not raw_ir.is_file():
        if not lift_binary(str(binary), output=str(raw_bc), use_cache=True):
            raise RuntimeError(f"Lifting failed for {sample_id}")
    if not brightened_ir.is_file():
        if not brighten_ir(str(raw_bc), str(brightened_bc), binary_path=str(binary)):
            raise RuntimeError(f"Brightening failed for {sample_id}")
    if not clean_ir.is_file() or not reference.is_file():
        final, status, log = finalize_ir(
            str(brightened_ir), str(case_dir / f"{sample_id}_final")
        )
        if status != "applied" or not final:
            raise RuntimeError(f"Finalization failed for {sample_id}: {status} ({log})")
    if not reference.is_file():
        raise RuntimeError(f"Final bundle did not produce executable: {reference}")

    return {
        **case,
        "raw_ir": str(raw_ir),
        "clean_ir": str(clean_ir),
        "reference": str(reference),
    }


def _record_f3_preparation_failure(
    case: dict[str, str], error: Exception, opt_level: str, protocol_version: str
) -> CaseTracker:
    tracker = CaseTracker(case["sample_id"], "F3")
    tracker.status = "INCONCLUSIVE"
    flow_dir = Path(case["case_dir"]) / "F3"
    flow_dir.mkdir(parents=True, exist_ok=True)
    _atomic_json(
        flow_dir / "failure.json",
        {
            "boundary": "F3_PIPELINE_PREPARATION",
            "type": type(error).__name__,
            "message": str(error),
        },
    )
    _atomic_json(
        flow_dir / "flow_contract.json",
        {
            **PRIMARY_FLOWS["F3"].__dict__,
            "protocol_version": protocol_version,
            "llvm_optimization_level": opt_level,
        },
    )
    _atomic_json(flow_dir / "flow_result.json", tracker.to_dict())
    return tracker


def _apply_reduction_metrics(
    tracker: CaseTracker, raw_ir: str, clean_ir: str
) -> None:
    metrics = run_deobfuscation_metrics(raw_ir, clean_ir)
    tracker.reduction = metrics
    tracker.instructions_raw = int(metrics.get("instruction_raw", 0) or 0)
    tracker.instructions_clean = int(metrics.get("instruction_clean", 0) or 0)
    tracker.basic_blocks_raw = int(metrics.get("bb_raw", 0) or 0)
    tracker.basic_blocks_clean = int(metrics.get("bb_clean", 0) or 0)
    tracker.conditional_branches_raw = int(metrics.get("branches_raw", 0) or 0)
    tracker.conditional_branches_clean = int(metrics.get("branches_clean", 0) or 0)

    def reduction(before: int, after: int) -> float:
        return (before - after) / before if before else 0.0

    tracker.instruction_reduction = reduction(
        tracker.instructions_raw, tracker.instructions_clean
    )
    tracker.bb_reduction = reduction(
        tracker.basic_blocks_raw, tracker.basic_blocks_clean
    )
    tracker.branches_reduction = reduction(
        tracker.conditional_branches_raw, tracker.conditional_branches_clean
    )


def _summary(
    trackers: list[CaseTracker], report_dir: Path, flow_order: tuple[str, ...]
) -> None:
    rows = [tracker.to_dict() for tracker in trackers]
    with (report_dir / "per_sample_results.csv").open("w", newline="") as handle:
        fields = [
            "sample_id",
            "flow_id",
            "status",
            "llm_calls",
            "compiler_attempts",
            "compile_success_first",
            "compile_success_final",
            "compile_repair_rounds",
            "behavioral_repair_rounds",
            "fuzz_total",
            "fuzz_matches",
            "input_tokens",
            "output_tokens",
            "total_runtime",
        ]
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field) for field in fields})

    flow_rows = []
    for flow_id in flow_order:
        selected = [tracker for tracker in trackers if tracker.flow_id == flow_id]
        denominator = len(selected)
        flow_rows.append(
            {
                "flow_id": flow_id,
                "role": EVALUATION_FLOWS[flow_id].contribution_role,
                "n": denominator,
                "pass_count": sum(item.status == "PASS" for item in selected),
                "canonical_e2e_rate": (
                    sum(item.status == "PASS" for item in selected) / denominator
                    if denominator
                    else None
                ),
                "mean_logical_llm_calls": (
                    sum(item.llm_calls for item in selected) / denominator
                    if denominator
                    else None
                ),
            }
        )
    _atomic_json(report_dir / "summary.json", {"flows": flow_rows})


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run B0/F3 primary evaluation and registered B1/B2/B3 comparators"
        )
    )
    parser.add_argument("input_csv")
    parser.add_argument("--pilot", type=int)
    parser.add_argument(
        "--flows",
        nargs="+",
        choices=EVALUATION_FLOW_ORDER,
        default=list(PRIMARY_FLOW_ORDER),
        help=(
            "Flows to execute. B1 is Ghidra with the exact B0 first request "
            "plus feedback; B2/B3 are paper-derived objdump assembly without/with "
            "the validation loop."
        ),
    )
    parser.add_argument(
        "--prepare-only",
        action="store_true",
        help="Run the deterministic F3 lifting/deobfuscation stages without making provider calls; the campaign can later be resumed.",
    )
    parser.add_argument("--fuzz-iterations", type=int, default=1000)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument(
        "--location",
        default="us-central1",
        help="Single frozen provider region shared by B0 and F3",
    )
    parser.add_argument(
        "--opt-level",
        choices=("O1", "O2", "O3"),
        default="O3",
        help="LLVM standard optimization treatment used by F3; B0 is unchanged",
    )
    parser.add_argument("--ghidra-headless", default=DEFAULT_GHIDRA_HEADLESS)
    parser.add_argument("--objdump", default=DEFAULT_OBJDUMP)
    parser.add_argument("--resume", help="Existing twoflow_YYYYMMDD_HHMMSS campaign ID")
    args = parser.parse_args(argv)
    selected_flows = tuple(
        flow_id for flow_id in EVALUATION_FLOW_ORDER if flow_id in set(args.flows)
    )
    if args.prepare_only and selected_flows != ("F3",):
        parser.error("--prepare-only requires exactly '--flows F3'")
    os.environ["BRIGHTEN_OPT_LEVEL"] = args.opt_level

    csv_path = (PROJECT_ROOT / args.input_csv).resolve()
    with csv_path.open(newline="") as handle:
        rows = list(csv.DictReader(handle))
    if args.pilot:
        rows = rows[: args.pilot]

    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    campaign_id = args.resume or f"twoflow_{stamp}"
    campaign_dir = PROJECT_ROOT / "result" / campaign_id
    report_dir = PROJECT_ROOT / "reports" / campaign_id
    campaign_dir.mkdir(parents=True, exist_ok=True)
    report_dir.mkdir(parents=True, exist_ok=True)
    manifest = protocol_manifest()
    frozen_generation = RecoveryConfig()
    manifest.update(
        {
            "campaign_id": campaign_id,
            "dataset": str(csv_path),
            "model": args.model,
            "location": args.location,
            "generation_config": {
                "temperature": frozen_generation.temperature,
                "top_p": frozen_generation.top_p,
                "candidate_count": frozen_generation.candidate_count,
                "max_output_tokens": frozen_generation.max_output_tokens,
            },
            "fuzz_iterations": args.fuzz_iterations,
            "f3_llvm_optimization_level": args.opt_level,
            "executed_flows": list(selected_flows),
            "ghidra_headless": str(Path(args.ghidra_headless).resolve()),
            "objdump": str(Path(args.objdump).resolve()),
            "dataset_sha256": _sha256_file(csv_path),
            "git": _git_state(),
            "implementation_sha256": _implementation_hashes(),
        }
    )
    existing_manifest_path = campaign_dir / "protocol_manifest.json"
    if existing_manifest_path.is_file():
        existing = json.loads(existing_manifest_path.read_text(encoding="utf-8"))
        if existing != manifest:
            raise RuntimeError(
                "Refusing resume because the frozen protocol fingerprint changed"
            )
    _atomic_json(campaign_dir / "protocol_manifest.json", manifest)
    _atomic_json(report_dir / "protocol_manifest.json", manifest)

    trackers: list[CaseTracker] = []
    for row in rows:
        case = _resolve_case(row, campaign_dir)
        generator, generator_reason = _select_generator(PROJECT_ROOT, case["binary"])
        seeds, _ = _resolve_seed_paths(PROJECT_ROOT, case["binary"])
        contract = resolve_input_contract(PROJECT_ROOT, case["binary"])
        if contract is None:
            raise RuntimeError(
                f"Preflight rejected {case['sample_id']}: no registered input contract"
            )
        _write_case_preflight(case, contract, seeds, generator_reason)
        location = args.location

        if "B0" in selected_flows:
            b0_result_path = Path(case["case_dir"]) / "B0" / "flow_result.json"
            if b0_result_path.is_file():
                tracker = CaseTracker.from_dict(json.loads(b0_result_path.read_text()))
            else:
                tracker = run_b0_experiment(
                    sample_id=case["sample_id"],
                    original_binary=case["binary"],
                    case_output_dir=case["case_dir"],
                    contract=contract,
                    generator=generator,
                    seeds=seeds,
                    iterations=args.fuzz_iterations,
                    model=args.model,
                    location=location,
                    ghidra_headless=args.ghidra_headless,
                    original_src=case["original_src"],
                )
            trackers.append(tracker)

        if "B1" in selected_flows:
            b1_result_path = Path(case["case_dir"]) / "B1" / "flow_result.json"
            if b1_result_path.is_file():
                tracker = CaseTracker.from_dict(json.loads(b1_result_path.read_text()))
            else:
                tracker = run_b1_experiment(
                    sample_id=case["sample_id"],
                    original_binary=case["binary"],
                    case_output_dir=case["case_dir"],
                    contract=contract,
                    generator=generator,
                    seeds=seeds,
                    iterations=args.fuzz_iterations,
                    model=args.model,
                    location=location,
                    ghidra_headless=args.ghidra_headless,
                    original_src=case["original_src"],
                )
            trackers.append(tracker)

        for assembly_flow in ("B2", "B3"):
            if assembly_flow not in selected_flows:
                continue
            result_path = (
                Path(case["case_dir"])
                / assembly_flow
                / "flow_result.json"
            )
            if result_path.is_file():
                tracker = CaseTracker.from_dict(
                    json.loads(result_path.read_text())
                )
            else:
                tracker = run_assembly_experiment(
                    flow_id=assembly_flow,
                    sample_id=case["sample_id"],
                    original_binary=case["binary"],
                    case_output_dir=case["case_dir"],
                    contract=contract,
                    generator=generator,
                    seeds=seeds,
                    iterations=args.fuzz_iterations,
                    model=args.model,
                    location=location,
                    objdump=args.objdump,
                    original_src=case["original_src"],
                )
            trackers.append(tracker)

        if "F3" in selected_flows:
            f3_result_path = Path(case["case_dir"]) / "F3" / "flow_result.json"
            if f3_result_path.is_file():
                tracker = CaseTracker.from_dict(json.loads(f3_result_path.read_text()))
            else:
                try:
                    prepared = _prepare_f3_case(case)
                    if args.prepare_only:
                        metrics = run_deobfuscation_metrics(
                            prepared["raw_ir"], prepared["clean_ir"]
                        )
                        preparation_dir = Path(prepared["case_dir"]) / "F3"
                        preparation_dir.mkdir(parents=True, exist_ok=True)
                        _atomic_json(
                            preparation_dir / "preparation.json",
                            {
                                "sample_id": prepared["sample_id"],
                                "llvm_optimization_level": args.opt_level,
                                "raw_ir": prepared["raw_ir"],
                                "raw_ir_sha256": _sha256_file(Path(prepared["raw_ir"])),
                                "clean_ir": prepared["clean_ir"],
                                "clean_ir_sha256": _sha256_file(Path(prepared["clean_ir"])),
                                "reference": prepared["reference"],
                                "reference_sha256": _sha256_file(Path(prepared["reference"])),
                                "reduction": metrics,
                            },
                        )
                        continue
                    tracker = run_flow_experiment(
                        sample_id=prepared["sample_id"],
                        flow_id="F3",
                        original_binary=prepared["binary"],
                        raw_ir=prepared["raw_ir"],
                        clean_ir=prepared["clean_ir"],
                        ref_binary=prepared["reference"],
                        contract=contract,
                        generator=generator,
                        seeds=seeds,
                        case_output_dir=prepared["case_dir"],
                        iterations=args.fuzz_iterations,
                        model=args.model,
                        location=location,
                        original_src=prepared["original_src"],
                    )
                    _apply_reduction_metrics(
                        tracker, prepared["raw_ir"], prepared["clean_ir"]
                    )
                    _atomic_json(
                        Path(prepared["case_dir"]) / "F3" / "flow_result.json",
                        tracker.to_dict(),
                    )
                    _atomic_json(
                        Path(prepared["case_dir"]) / "F3" / "flow_contract.json",
                        {
                            **PRIMARY_FLOWS["F3"].__dict__,
                            "protocol_version": manifest["protocol_version"],
                            "llvm_optimization_level": args.opt_level,
                            "max_iterations": PRIMARY_FLOWS["F3"].provider_call_budget,
                            "pseudo_backend": "ir",
                            "ir_representation": "clean",
                            "attach_clean_ir": False,
                        },
                    )
                except Exception as exc:
                    tracker = _record_f3_preparation_failure(
                        case, exc, args.opt_level, manifest["protocol_version"]
                    )
            trackers.append(tracker)
        _summary(trackers, report_dir, selected_flows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
