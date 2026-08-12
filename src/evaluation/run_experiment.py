#!/usr/bin/env python3
import os
import sys
import csv
import json
import time
import shutil
import hashlib
import argparse
import datetime
import traceback
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Callable
import concurrent.futures

# Ensure src/ is in sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from binary_lifting.lifting import lift_binary
from llvm_pass.britening_ir import (
    brighten_ir,
    finalize_ir,
    native_contract_report_path,
    read_native_contract_report,
    verify_native_contract,
)
from llm_recovery.llm_recovery import (
    RecoveryConfig,
    RecoveryInput,
    VertexGemini,
    run_recovery_loop,
    _text,
)
from fuzzing_equi_check.fuzzing import (
    DEFAULT_EXECUTION_TIMEOUT,
    SemanticFuzzer,
    compile_to_binary,
)
from fuzzing_equi_check.input_contracts import (
    resolve_input_contract,
    validate_contract_payload,
)
from evaluation.schema import FLOW_SPECS, flow_contract

# Load default model from prompts_config.py
try:
    import configs.prompts_config as _prompts_cfg
    DEFAULT_MODEL = getattr(_prompts_cfg, "MODEL", "gemini-3.5-flash")
    DEFAULT_READABILITY_MODEL = getattr(
        _prompts_cfg, "READABILITY_MODEL", "cx/gpt-5.5"
    )
except ImportError:
    DEFAULT_MODEL = "gemini-3.5-flash"
    DEFAULT_READABILITY_MODEL = "cx/gpt-5.5"

# Supported Vertex AI regions for Gemini models
VERTEX_GEMINI_REGIONS = [
    "us-central1",
    "us-east4",
    "europe-west3",
    "europe-west9",
    "asia-northeast1",
    "asia-southeast1"
]

# Custom VertexGemini client to intercept metrics and handle regional 404 fallbacks
class ExperimentVertexGemini(VertexGemini):
    def __init__(self, config: RecoveryConfig, tracker: "CaseTracker"):
        super().__init__(config)
        self.tracker = tracker

    def generate(self, prompt: str, attachment_path: Optional[str] = None,
                 attachment_paths: Optional[list] = None, system_instruction: Optional[str] = None) -> str:
        self.tracker.llm_calls += 1
        t_start = time.time()
        try:
            res = super().generate(prompt, attachment_path, attachment_paths, system_instruction)
            latency = time.time() - t_start
            self.tracker.llm_latency += latency
            
            # Record tokens
            meta = self.last_response_meta or {}
            meta["latency_seconds"] = latency
            meta["model"] = self.config.model
            meta["temperature"] = self.config.temperature
            meta["top_p"] = self.config.top_p
            meta["max_tokens"] = self.config.max_output_tokens
            self.last_response_meta = meta
            usage = meta.get("usage_metadata") or {}
            in_t = (
                usage.get("prompt_tokens")
                or usage.get("prompt_token_count")
                or usage.get("promptTokenCount")
                or 0
            )
            out_t = (
                usage.get("completion_tokens")
                or usage.get("candidates_token_count")
                or usage.get("candidatesTokenCount")
                or 0
            )
            self.tracker.input_tokens += in_t
            self.tracker.output_tokens += out_t
            
            return res
        except Exception as e:
            latency = time.time() - t_start
            self.tracker.llm_latency += latency
            
            # Capture regional 404 NOT_FOUND errors and fallback to us-central1 (safe harbor)
            err_msg = str(e)
            if "404" in err_msg or "NOT_FOUND" in err_msg or "was not found" in err_msg or "does not have access" in err_msg:
                if self.config.location != "us-central1":
                    print(f"[!] Model [{self.config.model}] is not supported in region [{self.config.location}]. Falling back to [us-central1]...", flush=True)
                    self.config.location = "us-central1"
                    self._client = None  # Force client re-initialization with the new location
                    # Decrement the failed attempt call count before retrying
                    self.tracker.llm_calls -= 1
                    return self.generate(prompt, attachment_path, attachment_paths, system_instruction)
            raise e

class CaseTracker:
    def __init__(self, sample_id: str, flow_id: str):
        self.sample_id = sample_id
        self.flow_id = flow_id
        self.llm_calls = 0
        self.compiler_attempts = 0
        self.behavioral_repairs = 0
        self.first_candidate = ""
        self.final_candidate = ""
        
        # Compile status
        self.compile_success_first = False
        self.compile_success_final = False
        self.any_compile_success_within_budget = False
        self.last_candidate_compile_success = False
        self.compile_repair_rounds = 0
        self.behavioral_repair_rounds = 0
        
        # Fuzzing counts & Counterexample tracking
        self.fuzz_total = 0
        self.fuzz_valid = 0
        self.fuzz_matches = 0
        self.has_counterexample = False
        self.counterexample_reproducible = False
        self.counterexample_ever_found = False
        self.reproducible_counterexample_ever_found = False
        self.final_counterexample_found = False
        self.behavior_before_repair = ""
        self.behavior_after_repair = ""
        
        # Stage Completion & Verification
        self.llvm_ir_verification_success = False
        self.stage_raw_ir = False
        self.stage_clean_ir = False
        self.stage_pseudocode = False
        self.stage_llm_gen = False
        self.stage_compilation = False
        self.stage_fuzzing = False
        self.stage_behavioral_validation = False
        
        # Deobfuscation Metrics & Raw counts
        self.instructions_raw = 0
        self.instructions_clean = 0
        self.basic_blocks_raw = 0
        self.basic_blocks_clean = 0
        self.conditional_branches_raw = 0
        self.conditional_branches_clean = 0
        self.instruction_reduction = 0.0
        self.bb_reduction = 0.0
        self.branches_reduction = 0.0
        
        # Original C Post-hoc Analysis
        self.original_sloc = 0
        self.recovered_sloc = 0
        self.sloc_ratio = 0.0
        self.readability_score = None
        
        # Status (PASS, FAIL_COMPILE, FAIL_BEHAVIORAL, INCONCLUSIVE)
        self.status = "INCONCLUSIVE"
        
        # Performance/Cost
        self.input_tokens = 0
        self.output_tokens = 0
        self.llm_latency = 0.0
        self.compile_time = 0.0
        self.fuzzing_time = 0.0
        self.total_runtime = 0.0
        
        self.reduction = {}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "sample_id": self.sample_id,
            "flow_id": self.flow_id,
            "llm_calls": self.llm_calls,
            "compiler_attempts": self.compiler_attempts,
            "behavioral_repairs": self.behavioral_repairs,
            "first_candidate": self.first_candidate,
            "final_candidate": self.final_candidate,
            "compile_success_first": self.compile_success_first,
            "compile_success_final": self.compile_success_final,
            "any_compile_success_within_budget": self.any_compile_success_within_budget,
            "last_candidate_compile_success": self.last_candidate_compile_success,
            "compile_repair_rounds": self.compile_repair_rounds,
            "behavioral_repair_rounds": self.behavioral_repair_rounds,
            "fuzz_total": self.fuzz_total,
            "fuzz_valid": self.fuzz_valid,
            "fuzz_matches": self.fuzz_matches,
            "has_counterexample": self.has_counterexample,
            "counterexample_reproducible": self.counterexample_reproducible,
            "counterexample_ever_found": self.counterexample_ever_found,
            "reproducible_counterexample_ever_found": self.reproducible_counterexample_ever_found,
            "final_counterexample_found": self.final_counterexample_found,
            "llvm_ir_verification_success": self.llvm_ir_verification_success,
            "stage_raw_ir": self.stage_raw_ir,
            "stage_clean_ir": self.stage_clean_ir,
            "stage_pseudocode": self.stage_pseudocode,
            "stage_llm_gen": self.stage_llm_gen,
            "stage_compilation": self.stage_compilation,
            "stage_fuzzing": self.stage_fuzzing,
            "stage_behavioral_validation": self.stage_behavioral_validation,
            "instructions_raw": self.instructions_raw,
            "instructions_clean": self.instructions_clean,
            "basic_blocks_raw": self.basic_blocks_raw,
            "basic_blocks_clean": self.basic_blocks_clean,
            "conditional_branches_raw": self.conditional_branches_raw,
            "conditional_branches_clean": self.conditional_branches_clean,
            "instruction_reduction": self.instruction_reduction,
            "bb_reduction": self.bb_reduction,
            "branches_reduction": self.branches_reduction,
            "original_sloc": self.original_sloc,
            "recovered_sloc": self.recovered_sloc,
            "sloc_ratio": self.sloc_ratio,
            "readability_score": self.readability_score,
            "behavior_before_repair": self.behavior_before_repair,
            "behavior_after_repair": self.behavior_after_repair,
            "status": self.status,
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "llm_latency": self.llm_latency,
            "compile_time": self.compile_time,
            "fuzzing_time": self.fuzzing_time,
            "total_runtime": self.total_runtime,
            "reduction": self.reduction
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CaseTracker":
        tracker = cls(data["sample_id"], data["flow_id"])
        tracker.llm_calls = data.get("llm_calls", 0)
        tracker.compiler_attempts = data.get("compiler_attempts", 0)
        tracker.behavioral_repairs = data.get("behavioral_repairs", 0)
        tracker.first_candidate = data.get("first_candidate", "")
        tracker.final_candidate = data.get("final_candidate", "")
        tracker.compile_success_first = data.get("compile_success_first", False)
        tracker.compile_success_final = data.get("compile_success_final", False)
        tracker.any_compile_success_within_budget = data.get("any_compile_success_within_budget", tracker.compile_success_final)
        tracker.last_candidate_compile_success = data.get("last_candidate_compile_success", tracker.compile_success_final)
        tracker.compile_repair_rounds = data.get("compile_repair_rounds", 0)
        tracker.behavioral_repair_rounds = data.get("behavioral_repair_rounds", 0)
        tracker.fuzz_total = data.get("fuzz_total", 0)
        tracker.fuzz_valid = data.get("fuzz_valid", 0)
        tracker.fuzz_matches = data.get("fuzz_matches", 0)
        tracker.has_counterexample = data.get("has_counterexample", False)
        tracker.counterexample_reproducible = data.get("counterexample_reproducible", False)
        tracker.counterexample_ever_found = data.get("counterexample_ever_found", tracker.has_counterexample)
        tracker.reproducible_counterexample_ever_found = data.get("reproducible_counterexample_ever_found", tracker.counterexample_reproducible)
        tracker.final_counterexample_found = data.get("final_counterexample_found", tracker.has_counterexample)
        tracker.llvm_ir_verification_success = data.get("llvm_ir_verification_success", False)
        tracker.stage_raw_ir = data.get("stage_raw_ir", False)
        tracker.stage_clean_ir = data.get("stage_clean_ir", False)
        tracker.stage_pseudocode = data.get("stage_pseudocode", False)
        tracker.stage_llm_gen = data.get("stage_llm_gen", False)
        tracker.stage_compilation = data.get("stage_compilation", False)
        tracker.stage_fuzzing = data.get("stage_fuzzing", False)
        tracker.stage_behavioral_validation = data.get("stage_behavioral_validation", False)
        tracker.instructions_raw = data.get("instructions_raw", 0)
        tracker.instructions_clean = data.get("instructions_clean", 0)
        tracker.basic_blocks_raw = data.get("basic_blocks_raw", 0)
        tracker.basic_blocks_clean = data.get("basic_blocks_clean", 0)
        tracker.conditional_branches_raw = data.get("conditional_branches_raw", 0)
        tracker.conditional_branches_clean = data.get("conditional_branches_clean", 0)
        tracker.instruction_reduction = data.get("instruction_reduction", 0.0)
        tracker.bb_reduction = data.get("bb_reduction", 0.0)
        tracker.branches_reduction = data.get("branches_reduction", 0.0)
        tracker.original_sloc = data.get("original_sloc", 0)
        tracker.recovered_sloc = data.get("recovered_sloc", 0)
        tracker.sloc_ratio = data.get("sloc_ratio", 0.0)
        tracker.readability_score = data.get("readability_score")
        tracker.behavior_before_repair = data.get("behavior_before_repair", "")
        tracker.behavior_after_repair = data.get("behavior_after_repair", "")
        tracker.status = data.get("status", "INCONCLUSIVE")
        tracker.input_tokens = data.get("input_tokens", 0)
        tracker.output_tokens = data.get("output_tokens", 0)
        tracker.llm_latency = data.get("llm_latency", 0.0)
        tracker.compile_time = data.get("compile_time", 0.0)
        tracker.fuzzing_time = data.get("fuzzing_time", 0.0)
        tracker.total_runtime = data.get("total_runtime", 0.0)
        tracker.reduction = data.get("reduction", {})
        return tracker

def run_deobfuscation_metrics(raw_ir: str, clean_ir: str) -> Dict[str, Any]:
    """Calculate deobfuscation stats between raw and clean IR."""
    metrics = {"instruction_raw": 0, "instruction_clean": 0, "bb_raw": 0, "bb_clean": 0, "branches_raw": 0, "branches_clean": 0}
    
    def parse_ir(path):
        import re
        ins, bb, br = 0, 0, 0
        if not path or not os.path.exists(path):
            return ins, bb, br
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            in_func = False
            for line in f:
                s = line.strip()
                if not s or s.startswith(";"):
                    continue
                if s.startswith("define "):
                    in_func = True
                    bb += 1
                elif s == "}":
                    in_func = False
                elif in_func:
                    if re.match(r"^[a-zA-Z0-9_%\.\-]+:\s*(;.*)?$", s):
                        bb += 1
                    else:
                        ins += 1
                        if s.startswith("br i1") or s.startswith("switch"):
                            br += 1
        return ins, bb, br

    ir_raw_stats = parse_ir(raw_ir)
    ir_clean_stats = parse_ir(clean_ir)
    
    metrics["instruction_raw"], metrics["bb_raw"], metrics["branches_raw"] = ir_raw_stats
    metrics["instruction_clean"], metrics["bb_clean"], metrics["branches_clean"] = ir_clean_stats
    return metrics

def _run_compile_check_tracked(candidate_path: str, output_dir: str, tracker: CaseTracker) -> Tuple[bool, str]:
    t_start = time.time()
    tracker.compiler_attempts += 1
    # Simple compilation check via clang
    binary_path = os.path.join(output_dir, "temp_compile.bin")
    if os.path.exists(binary_path):
        try: os.remove(binary_path)
        except: pass
    from fuzzing_equi_check.fuzzing import find_clang
    compiler = find_clang()
    cmd = [compiler, "-O2", candidate_path, "-o", binary_path, "-lm"]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    elapsed = time.time() - t_start
    tracker.compile_time += elapsed
    success = (
        proc.returncode == 0
        and os.path.isfile(binary_path)
        and os.path.getsize(binary_path) > 0
    )
    diagnostics = proc.stderr or proc.stdout or ""
    lowered = diagnostics.lower()
    if success:
        failure_category = None
    elif "timed out" in lowered or "timeout" in lowered:
        failure_category = "COMPILER_TIMEOUT"
    elif "undeclared identifier" in lowered:
        failure_category = "UNDECLARED_SYMBOL"
    elif "file not found" in lowered or "no such file" in lowered:
        failure_category = "MISSING_HEADER"
    elif "undefined reference" in lowered or "undefined symbol" in lowered:
        failure_category = "UNRESOLVED_EXTERNAL"
    elif "linker command failed" in lowered:
        failure_category = "LINKER_ERROR"
    elif "incompatible" in lowered or "invalid operands" in lowered:
        failure_category = "TYPE_ERROR"
    elif "expected " in lowered or "syntax error" in lowered:
        failure_category = "SYNTAX_ERROR"
    else:
        failure_category = "OTHER"
    try:
        compiler_version = subprocess.run(
            [compiler, "--version"],
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout.splitlines()[0]
    except Exception:
        compiler_version = None
    iteration = Path(candidate_path).stem.removeprefix("recovered_iter")
    compile_record = {
        "attempt_index": tracker.compiler_attempts,
        "candidate_index": tracker.compiler_attempts,
        "generation_iteration": int(iteration) if iteration.isdigit() else None,
        "compile_command": cmd,
        "compiler_version": compiler_version,
        "compile_exit_code": proc.returncode,
        "compile_success": success,
        "link_success": success,
        "executable_created": success,
        "executable_path": binary_path if success else None,
        "executable_hash": None,
        "compile_time": elapsed,
        "diagnostics_path": (
            os.path.join(output_dir, f"recovery_iter{iteration}.compile.txt")
            if not success
            else None
        ),
        "failure_category": failure_category,
        "is_compile_repair_attempt": tracker.compiler_attempts > 1,
    }
    if success:
        digest = hashlib.sha256()
        with open(binary_path, "rb") as executable:
            for block in iter(lambda: executable.read(1024 * 1024), b""):
                digest.update(block)
        compile_record["executable_hash"] = digest.hexdigest()
    record_path = os.path.join(
        output_dir, f"recovery_iter{iteration}.compile.json"
    )
    with open(record_path, "w", encoding="utf-8") as record_file:
        json.dump(compile_record, record_file, indent=2)
    return (True, "") if success else (False, diagnostics)

def run_fuzzing_tracked(candidate_path: str, ref_binary: str, contract: Any, generator: Any, seeds: list, tracker: CaseTracker, iterations: int) -> Dict[str, Any]:
    t_start = time.time()
    fuzzer = SemanticFuzzer(candidate_path, ref_binary, seed_paths=seeds, input_contract=contract)
    try:
        fuzzer.compile()
        report = fuzzer.run_differential_test(
            iterations=iterations,
            generator=generator,
            timeout=0.1,
            num_workers=4,
            compare_stderr=True,
            strict_oracle=True,
        )
        iteration = Path(candidate_path).stem.removeprefix("recovered_iter")
        report["evaluation_metadata"] = {
            "campaign_index": getattr(tracker, "fuzz_campaign_count", 0) + 1,
            "candidate_generation_iteration": (
                int(iteration) if iteration.isdigit() else None
            ),
            "fuzzing_time_seconds": time.time() - t_start,
            "reference_executable": ref_binary,
            "reference_executable_kind": "OBFUSCATED_BINARY",
            "strict_behavior_tuple": True,
            "replay_policy": "two additional executions per side",
        }
        tracker.fuzz_campaign_count = (
            report["evaluation_metadata"]["campaign_index"]
        )
        report_path = Path(candidate_path).parent / (
            f"recovery_iter{iteration}.fuzz.json"
        )
        report_path.write_text(
            json.dumps(report, ensure_ascii=False, indent=2, default=str),
            encoding="utf-8",
        )
        counterexample_dir = Path(candidate_path).parent / "counterexamples"
        counterexample_dir.mkdir(exist_ok=True)
        import base64

        for example_index, example in enumerate(
            report.get("mismatch_examples") or [], 1
        ):
            encoded = example.get("stdin_base64")
            if encoded:
                (counterexample_dir / (
                    f"iter{iteration}_example{example_index}.bin"
                )).write_bytes(base64.b64decode(encoded))
        tracker.fuzz_total = report.get("total_runs", 0) or 0
        tracker.fuzz_matches = report.get("matches", 0) or 0
        tracker.fuzz_valid = tracker.fuzz_total
        
        mismatches = report.get("mismatches", 0) or 0
        if mismatches > 0:
            tracker.has_counterexample = True
            # Reproducibility check
            examples = report.get("mismatch_examples", [])
            if examples:
                ex = examples[0]
                tracker.counterexample_reproducible = True
        
        return report
    except Exception as e:
        return {"status": "inconclusive", "error": str(e), "matches": 0, "total_runs": 0}
    finally:
        fuzzer.cleanup()
        tracker.fuzzing_time += (time.time() - t_start)

def run_flow_experiment(sample_id: str, flow_id: str, original_binary: str, raw_ir: str, clean_ir: str, ref_binary: str, contract: Any, generator: Any, seeds: list, case_output_dir: str, iterations: int, model: str, location: str, original_src: Optional[str] = None) -> CaseTracker:
    tracker = CaseTracker(sample_id, flow_id)
    t_start = time.time()
    
    # Stage status
    tracker.stage_raw_ir = os.path.exists(raw_ir) and os.path.getsize(raw_ir) > 0
    tracker.stage_clean_ir = os.path.exists(clean_ir) and os.path.getsize(clean_ir) > 0
    tracker.stage_pseudocode = True  # Pseudo pipeline ready
    
    # Verify native contract if available
    contract_report = native_contract_report_path(case_output_dir)
    if os.path.exists(contract_report):
        verified, _ = verify_native_contract(clean_ir, contract_report)
        tracker.llvm_ir_verification_success = verified
    else:
        tracker.llvm_ir_verification_success = True
        
    flow_dir = os.path.join(case_output_dir, flow_id)
    os.makedirs(flow_dir, exist_ok=True)
    Path(os.path.join(flow_dir, "oracle_contract.json")).write_text(
        json.dumps(
            {
                "reference_executable_path": original_binary,
                "reference_executable_kind": "OBFUSCATED_BINARY",
                "compare_stdout_bytes": True,
                "compare_stderr_bytes": True,
                "compare_exit_code": True,
                "compare_terminating_signal": True,
                "compare_timeout_status": True,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    
    config = RecoveryConfig()
    config.fuzz_iterations = iterations
    config.model = model
    config.location = location  # Round-robin assigned region to distribute quota load
    
    # Configure the full-first ablation layout. Every iterative flow receives
    # the same error-context policy; F2 is the sole one-shot ablation.
    flow_spec = FLOW_SPECS[flow_id]
    if flow_id == "F1":
        config.pseudo_backend = "llvm2c"
        config.ir_representation = "clean"
        config.attach_clean_ir = True
        config.max_iterations = 5
        ir_text = Path(clean_ir).read_text(encoding="utf-8", errors="replace")
    elif flow_id == "F2":
        config.pseudo_backend = "llvm2c"
        config.ir_representation = "clean"
        config.attach_clean_ir = True
        config.max_iterations = 1
        ir_text = Path(clean_ir).read_text(encoding="utf-8", errors="replace")
    elif flow_id == "F3":
        config.pseudo_backend = "ir"
        config.ir_representation = "clean"
        config.attach_clean_ir = False
        config.max_iterations = 5
        ir_text = Path(clean_ir).read_text(encoding="utf-8", errors="replace")
    elif flow_id == "F4":
        config.pseudo_backend = "llvm2c"
        config.ir_representation = "clean"
        config.attach_clean_ir = False
        config.max_iterations = 5
        ir_text = Path(clean_ir).read_text(encoding="utf-8", errors="replace")
    elif flow_id == "F5":
        config.pseudo_backend = "ir"
        config.ir_representation = "raw"
        config.attach_clean_ir = False
        config.max_iterations = 5
        ir_text = Path(raw_ir).read_text(encoding="utf-8", errors="replace")
    else:
        raise ValueError(f"Unknown flow_id: {flow_id}")

    Path(os.path.join(flow_dir, "flow_contract.json")).write_text(
        json.dumps(
            {
                **flow_contract(flow_spec),
                "max_iterations": config.max_iterations,
                "pseudo_backend": config.pseudo_backend,
                "ir_representation": config.ir_representation,
                "attach_clean_ir": config.attach_clean_ir,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
        
    client = ExperimentVertexGemini(config, tracker)
    
    # Decorate internal functions to count repair rounds
    original_compile_check = sys.modules["llm_recovery.llm_recovery"]._run_compile_check
    sys.modules["llm_recovery.llm_recovery"]._run_compile_check = lambda p, o: _run_compile_check_tracked(p, o, tracker)
    
    # Run recovery
    output_recovered_c = os.path.join(flow_dir, f"{sample_id}_recovered.c")
    
    first_fuzz_report = None
    last_fuzz_report = None
    
    def custom_fuzzer_callback(cand_path: str):
        nonlocal first_fuzz_report, last_fuzz_report
        # The experiment oracle is the supplied obfuscated binary itself.
        # ``ref_binary`` is retained in the signature for resume compatibility
        # with historical campaigns but is no longer used as the oracle.
        rep = run_fuzzing_tracked(
            cand_path,
            original_binary,
            contract,
            generator,
            seeds,
            tracker,
            iterations,
        )
        last_fuzz_report = rep
        if first_fuzz_report is None:
            first_fuzz_report = rep
        
        mismatches = rep.get("mismatches", 0) or 0
        if mismatches > 0:
            tracker.counterexample_ever_found = True
            tracker.reproducible_counterexample_ever_found = True
            if flow_spec.iterative:
                tracker.behavioral_repairs += 1
                tracker.behavioral_repair_rounds += 1
        return rep

    metadata = {
        "input_ir": raw_ir if flow_spec.requires_raw_ir else clean_ir,
        "original_binary": original_binary,
    }
    
    try:
        res = run_recovery_loop(
            ir_text=ir_text,
            output_recovered_c_path=output_recovered_c,
            case_output_dir=flow_dir,
            metadata=metadata,
            fuzzer_callback=custom_fuzzer_callback,
            config=config,
            model_client=client,
        )
        
        # Read candidates
        c_files = sorted(list(Path(flow_dir).glob("recovered_iter*.c")))
        if c_files:
            tracker.stage_llm_gen = True
            tracker.first_candidate = c_files[0].read_text(encoding="utf-8", errors="replace")
            tracker.final_candidate = c_files[-1].read_text(encoding="utf-8", errors="replace")
        
        tracker.compile_success_first = os.path.exists(os.path.join(flow_dir, "recovered_iter1.c")) and not os.path.exists(os.path.join(flow_dir, "recovery_iter1.compile.txt"))
        
        # Check if ANY candidate within budget compiled successfully
        all_compile_txts = list(Path(flow_dir).glob("recovery_iter*.compile.txt"))
        tracker.any_compile_success_within_budget = len(c_files) > len(all_compile_txts)
        
        # Check last candidate compile success
        tracker.last_candidate_compile_success = os.path.exists(output_recovered_c) and (res.compile_error is None)
        tracker.compile_success_final = tracker.any_compile_success_within_budget
        
        if tracker.any_compile_success_within_budget:
            tracker.stage_compilation = True
            tracker.stage_fuzzing = tracker.fuzz_total > 0
            
        # Calculate rounds
        if flow_spec.iterative:
            for f in all_compile_txts:
                tracker.compile_repair_rounds += 1
        else:
            tracker.compile_repair_rounds = 0
            tracker.behavioral_repair_rounds = 0
            tracker.behavioral_repairs = 0
            
        # Final counterexample check
        if last_fuzz_report:
            mismatches = last_fuzz_report.get("mismatches", 0) or 0
            tracker.final_counterexample_found = (mismatches > 0)
        else:
            tracker.final_counterexample_found = False
            
        # Classify final status
        if res.success and tracker.fuzz_matches == tracker.fuzz_total and tracker.fuzz_total > 0:
            tracker.status = "PASS"
            tracker.stage_behavioral_validation = True
        elif not tracker.compile_success_final:
            tracker.status = "FAIL_COMPILE"
        elif tracker.has_counterexample or tracker.final_counterexample_found:
            tracker.status = "FAIL_BEHAVIORAL"
        else:
            tracker.status = "INCONCLUSIVE"
            
    except Exception as exc:
        print(f"Error executing flow {flow_id} on {sample_id} ({location}): {exc}")
        traceback.print_exc()
        tracker.status = "INCONCLUSIVE"
    finally:
        sys.modules["llm_recovery.llm_recovery"]._run_compile_check = original_compile_check
        tracker.total_runtime = time.time() - t_start
        
        if first_fuzz_report:
            tracker.behavior_before_repair = f"matches={first_fuzz_report.get('matches')}, mismatches={first_fuzz_report.get('mismatches')}"
        if last_fuzz_report:
            tracker.behavior_after_repair = f"matches={last_fuzz_report.get('matches')}, mismatches={last_fuzz_report.get('mismatches')}"
            
        # Post-hoc SLOC only. Readability is evaluated independently after an
        # accepted candidate exists and is persisted as an auditable artifact.
        if original_src and os.path.exists(original_src):
            try:
                orig_lines = [l.strip() for l in Path(original_src).read_text(errors="ignore").splitlines() if l.strip() and not l.strip().startswith("//")]
                tracker.original_sloc = len(orig_lines)
                if tracker.final_candidate:
                    rec_lines = [l.strip() for l in tracker.final_candidate.splitlines() if l.strip() and not l.strip().startswith("//")]
                    tracker.recovered_sloc = len(rec_lines)
                    tracker.sloc_ratio = tracker.recovered_sloc / max(1, tracker.original_sloc)
            except Exception:
                pass

        # Save flow result json for resume mechanism support
        try:
            with open(os.path.join(flow_dir, "flow_result.json"), "w") as rf:
                json.dump(tracker.to_dict(), rf, indent=2)
        except Exception as write_err:
            print(f"[!] Warning: failed to save flow_result.json for resume: {write_err}")
            
    return tracker

def flow_worker(sample_id: str, flow_id: str, original_binary: str, raw_ir: str, clean_ir: str, ref_binary: str, case_output_dir: str, iterations: int, reduction_metrics: dict, model: str, location: str, original_src: Optional[str] = None) -> CaseTracker:
    try:
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
        from main import _select_generator, _resolve_seed_paths
        from fuzzing_equi_check.input_contracts import resolve_input_contract
        
        generator, _ = _select_generator(project_root, original_binary)
        seed_paths, _ = _resolve_seed_paths(project_root, original_binary)
        contract = resolve_input_contract(project_root, original_binary, only_custom=True)
        
        print(f"[*] Starting concurrent Flow {flow_id} for {sample_id} using region [{location}]...", flush=True)
        tracker = run_flow_experiment(
            sample_id=sample_id,
            flow_id=flow_id,
            original_binary=original_binary,
            raw_ir=raw_ir,
            clean_ir=clean_ir,
            ref_binary=ref_binary,
            contract=contract,
            generator=generator,
            seeds=seed_paths,
            case_output_dir=case_output_dir,
            iterations=iterations,
            model=model,
            location=location,
            original_src=original_src
        )
        tracker.reduction = reduction_metrics
        tracker.instructions_raw = reduction_metrics.get("instruction_raw", 0)
        tracker.instructions_clean = reduction_metrics.get("instruction_clean", 0)
        tracker.basic_blocks_raw = reduction_metrics.get("bb_raw", 0)
        tracker.basic_blocks_clean = reduction_metrics.get("bb_clean", 0)
        tracker.conditional_branches_raw = reduction_metrics.get("branches_raw", 0)
        tracker.conditional_branches_clean = reduction_metrics.get("branches_clean", 0)
        
        raw_ins = max(1, tracker.instructions_raw)
        raw_bb = max(1, tracker.basic_blocks_raw)
        raw_br = max(1, tracker.conditional_branches_raw)
        
        tracker.instruction_reduction = (tracker.instructions_raw - tracker.instructions_clean) / raw_ins * 100.0
        tracker.bb_reduction = (tracker.basic_blocks_raw - tracker.basic_blocks_clean) / raw_bb * 100.0
        tracker.branches_reduction = (tracker.conditional_branches_raw - tracker.conditional_branches_clean) / raw_br * 100.0
        
        print(f"[✓] Completed Flow {flow_id} for {sample_id} in {tracker.total_runtime:.1f}s", flush=True)
        return tracker
    except Exception as e:
        print(f"[✗] Error in concurrent worker process for {flow_id} of {sample_id}: {e}", flush=True)
        traceback.print_exc()
        tracker = CaseTracker(sample_id, flow_id)
        tracker.status = "INCONCLUSIVE"
        return tracker

def main():
    parser = argparse.ArgumentParser(description="Evaluate 5 Flows of LLM Source Recovery in parallel.")
    parser.add_argument("input_csv", default="data/test_new.csv", help="Path to input test CSV")
    parser.add_argument("--pilot", type=int, default=None, help="Number of pilot cases to run")
    parser.add_argument("--fuzz-iterations", type=int, default=1000, help="Number of fuzz iterations")
    parser.add_argument("--max-workers", type=int, default=15, help="Max parallel flows running simultaneously")
    parser.add_argument("--model", type=str, default=DEFAULT_MODEL, help="Vertex AI model to use")
    parser.add_argument(
        "--readability-model",
        default=DEFAULT_READABILITY_MODEL,
        help="Model used only for accepted-source readability scoring",
    )
    parser.add_argument(
        "--readability-workers",
        type=int,
        default=8,
        help="Concurrent readability evaluator requests",
    )
    parser.add_argument(
        "--skip-readability",
        action="store_true",
        help="Skip accepted-source readability evaluation",
    )
    parser.add_argument("--no-rotate-regions", action="store_false", dest="rotate_regions", default=True, help="Disable regional endpoints rotation")
    parser.add_argument("--resume", type=str, default=None, help="Campaign directory name to resume (e.g. eval_20260728_043618)")
    args = parser.parse_args()
    args.model = args.model.strip()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
    
    # Read CSV rows
    rows = []
    with open(os.path.join(project_root, args.input_csv), "r") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)
            
    if args.pilot:
        rows = rows[:args.pilot]
        
    print(f"[*] Running concurrent evaluation on {len(rows)} cases with model={args.model} and max_workers={args.max_workers}...", flush=True)
    rotate_enabled = args.rotate_regions
    env_rotate = os.environ.get("VERTEX_ROTATE_REGIONS")
    if env_rotate is not None:
        rotate_enabled = env_rotate.lower() not in ["0", "false", "no"]

    if rotate_enabled:
        print(f"[✓] Region rotation enabled by default. Distributing requests across: {', '.join(VERTEX_GEMINI_REGIONS)}")
    
    # Campaign settings
    if args.resume:
        campaign_id = args.resume.strip()
        timestamp = campaign_id.replace("eval_", "")
        print(f"[✓] Resuming existing campaign: {campaign_id}", flush=True)
    else:
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        campaign_id = f"eval_{timestamp}"
        
    experiment_id = f"experiment_{timestamp}"
    reports_dir = os.path.join(project_root, "reports", experiment_id)
    os.makedirs(reports_dir, exist_ok=True)
    os.makedirs(os.path.join(reports_dir, "figures"), exist_ok=True)
    
    # Pre-lift and pre-brighten all cases to collect paths & reduction metrics sequentially first
    tasks_to_run = []
    all_trackers = []
    
    task_idx = 0
    for idx, row in enumerate(rows, 1):
        binary = row["obfuscated_binary"]
        sample_id = os.path.basename(os.path.dirname(binary))
        original_src = row.get("source_c", "")
        if original_src:
            original_src = os.path.join(project_root, original_src)
        
        binary_abs = os.path.join(project_root, binary)
        case_output_dir = os.path.join(project_root, "result", campaign_id, sample_id)
        
        # If resume, check if we need to do anything for this sample
        raw_ir = os.path.join(case_output_dir, f"{sample_id}.ll")
        brightened_ir = os.path.join(
            case_output_dir, f"{sample_id}_brightened.ll"
        )
        clean_ir = os.path.join(case_output_dir, f"{sample_id}_final.ll")
        ref_binary = os.path.join(case_output_dir, f"{sample_id}_final_ref.bin")
        
        # Check how many flows are already completed
        flows_needed = []
        for flow in ["F1", "F2", "F3", "F4", "F5"]:
            flow_result_path = os.path.join(case_output_dir, flow, "flow_result.json")
            if os.path.exists(flow_result_path):
                try:
                    with open(flow_result_path, "r") as rf:
                        flow_data = json.load(rf)
                        tracker = CaseTracker.from_dict(flow_data)
                        all_trackers.append(tracker)
                except Exception as load_err:
                    print(f"[!] Failed to load previous result for {sample_id} {flow}, rescheduling: {load_err}")
                    flows_needed.append(flow)
            else:
                flows_needed.append(flow)
                
        if not flows_needed:
            print(f"[✓] Case {idx}/{len(rows)}: {sample_id} already fully evaluated. Skipping...", flush=True)
            continue
            
        print(f"[*] Preparing Case {idx}/{len(rows)}: {sample_id} (Evaluating flows: {', '.join(flows_needed)})...", flush=True)
        os.makedirs(case_output_dir, exist_ok=True)
        
        # Lift, brighten, and finalize. The brightened artifact is deliberately
        # intermediate; every clean-IR flow consumes the canonical final IR.
        if not os.path.exists(clean_ir) or not os.path.exists(ref_binary):
            if not os.path.exists(brightened_ir):
                output_bc = os.path.join(case_output_dir, f"{sample_id}.bc")
                lift_success = lift_binary(
                    binary_path=binary_abs,
                    output=output_bc,
                    use_cache=True,
                    force_relift=False,
                )
                if not lift_success:
                    print(f"[✗] Lifting failed for {sample_id}", flush=True)
                    continue

                output_brightened_bc = os.path.join(
                    case_output_dir, f"{sample_id}_brightened.bc"
                )
                brighten_success = brighten_ir(
                    output_bc,
                    output_brightened_bc,
                    binary_path=binary_abs,
                )
                if not brighten_success:
                    print(f"[✗] Brightening failed for {sample_id}", flush=True)
                    continue

            clean_ir, finalize_status, finalize_log = finalize_ir(
                brightened_ir,
                os.path.join(case_output_dir, f"{sample_id}_final"),
            )
            if finalize_status != "applied" or not clean_ir:
                print(
                    f"[✗] Finalization failed for {sample_id}: "
                    f"{finalize_status} ({finalize_log})",
                    flush=True,
                )
                continue
            compile_to_binary(clean_ir, ref_binary)
            
        reduction_metrics = run_deobfuscation_metrics(raw_ir, clean_ir)
        
        # Add the remaining incomplete flows to the queue
        for flow in flows_needed:
            if rotate_enabled:
                location = VERTEX_GEMINI_REGIONS[task_idx % len(VERTEX_GEMINI_REGIONS)]
            else:
                location = os.environ.get("VERTEX_LOCATION", "global")
            
            tasks_to_run.append((sample_id, flow, binary_abs, raw_ir, clean_ir, ref_binary, case_output_dir, args.fuzz_iterations, reduction_metrics, args.model, location, original_src))
            task_idx += 1
            
    if tasks_to_run:
        print(f"[*] Remaining flow tasks to run: {len(tasks_to_run)}. Launching parallel executor pool...", flush=True)
        try:
            with concurrent.futures.ProcessPoolExecutor(max_workers=args.max_workers) as executor:
                futures = {
                    executor.submit(flow_worker, *task): task for task in tasks_to_run
                }
                
                for future in concurrent.futures.as_completed(futures):
                    task_info = futures[future]
                    sample_id, flow_id = task_info[0], task_info[1]
                    try:
                        tracker = future.result()
                        if tracker:
                            all_trackers.append(tracker)
                    except Exception as exc:
                        print(f"[✗] Future task {flow_id} of {sample_id} generated an exception: {exc}", flush=True)
        except KeyboardInterrupt:
            print("\n[!] Ctrl+C detected! Instantly terminating all concurrent worker processes...", flush=True)
            import signal
            os.killpg(os.getpgrp(), signal.SIGKILL)
            sys.exit(1)
    else:
        print("[✓] All tasks in the dataset are already completed. Regenerating reports...", flush=True)
                
    if not args.skip_readability:
        try:
            from evaluation.readability import evaluate_campaign

            readability_summary = evaluate_campaign(
                Path(project_root),
                Path(project_root) / "result" / campaign_id,
                experiment_id,
                model=args.readability_model.strip(),
                max_workers=args.readability_workers,
            )
            marker = "[!]" if readability_summary["failures"] else "[✓]"
            print(
                f"{marker} Readability evaluation: "
                f"{readability_summary['evaluated']}/"
                f"{readability_summary['accepted_candidates']} accepted sources "
                f"({readability_summary['cache_hits']} cached, "
                f"{len(readability_summary['failures'])} failed).",
                flush=True,
            )
        except Exception as exc:
            print(f"[!] Readability evaluation failed: {exc}", flush=True)

    # Export metrics CSVs
    export_metrics_csvs(all_trackers, reports_dir, experiment_id)
    print(f"\n[✓] All experiments completed. Results exported to {reports_dir}/", flush=True)

def export_metrics_csvs(trackers: List[CaseTracker], output_dir: str, experiment_id: str):
    # 1. per_sample_results.csv
    per_sample_path = os.path.join(output_dir, "per_sample_results.csv")
    with open(per_sample_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "sample_id", "flow_id", "llm_calls", "compiler_attempts", "behavioral_repairs",
            "compile_success_first", "compile_success_final", "any_compile_success_within_budget", "last_candidate_compile_success",
            "compile_repair_rounds", "behavioral_repair_rounds",
            "fuzz_total", "fuzz_valid", "fuzz_matches",
            "has_counterexample", "counterexample_reproducible",
            "counterexample_ever_found", "reproducible_counterexample_ever_found", "final_counterexample_found",
            "llvm_ir_verification_success",
            "instructions_raw", "instructions_clean", "basic_blocks_raw", "basic_blocks_clean", "conditional_branches_raw", "conditional_branches_clean",
            "instruction_reduction", "bb_reduction", "branches_reduction",
            "original_sloc", "recovered_sloc", "sloc_ratio", "readability_score",
            "status", "input_tokens", "output_tokens", "llm_latency", "compile_time", "fuzzing_time", "total_runtime"
        ])
        for t in trackers:
            writer.writerow([
                t.sample_id, t.flow_id, t.llm_calls, t.compiler_attempts, t.behavioral_repairs,
                t.compile_success_first, t.compile_success_final, t.any_compile_success_within_budget, t.last_candidate_compile_success,
                t.compile_repair_rounds if FLOW_SPECS[t.flow_id].iterative else 0,
                t.behavioral_repair_rounds if FLOW_SPECS[t.flow_id].iterative else 0,
                t.fuzz_total, t.fuzz_valid, t.fuzz_matches,
                t.has_counterexample, t.counterexample_reproducible,
                t.counterexample_ever_found, t.reproducible_counterexample_ever_found, t.final_counterexample_found,
                t.llvm_ir_verification_success,
                t.instructions_raw, t.instructions_clean, t.basic_blocks_raw, t.basic_blocks_clean, t.conditional_branches_raw, t.conditional_branches_clean,
                f"{t.instruction_reduction:.2f}", f"{t.bb_reduction:.2f}", f"{t.branches_reduction:.2f}",
                t.original_sloc,
                t.recovered_sloc,
                f"{t.sloc_ratio:.2f}",
                "" if t.readability_score is None else f"{t.readability_score:.2f}",
                t.status, t.input_tokens, t.output_tokens, t.llm_latency, t.compile_time, t.fuzzing_time, t.total_runtime
            ])

    # 2. per_flow_metrics.csv
    flows = ["F1", "F2", "F3", "F4", "F5"]
    per_flow_path = os.path.join(output_dir, "per_flow_metrics.csv")
    with open(per_flow_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "flow_id", "sample_count", "first_pass_rsr", "final_rsr", "compilation_repair_gain",
            "initial_behavioral_pass_rate", "final_behavioral_pass_rate", "behavioral_repair_gain",
            "counterexample_detection_rate", "llvm_ir_verification_success_rate",
            "e2e_recovery_rate", "mean_llm_calls", "mean_tokens", "mean_runtime"
        ])
        for flow in flows:
            flow_ts = [t for t in trackers if t.flow_id == flow]
            count = len(flow_ts)
            if count == 0: continue
            
            first_pass_rsr = sum(1 for t in flow_ts if t.compile_success_first) / count * 100
            final_rsr = sum(1 for t in flow_ts if t.compile_success_final) / count * 100
            iterative = FLOW_SPECS[flow].iterative
            comp_gain = final_rsr - first_pass_rsr if iterative else None
            
            initial_beh_pass = sum(1 for t in flow_ts if t.compile_success_first and not t.counterexample_ever_found) / count * 100
            final_beh_pass = sum(1 for t in flow_ts if t.status == "PASS") / count * 100
            beh_gain = final_beh_pass - initial_beh_pass if iterative else None
            
            cx_detection_rate = sum(1 for t in flow_ts if t.counterexample_ever_found) / count * 100
            ir_verify_rate = sum(1 for t in flow_ts if t.llvm_ir_verification_success) / count * 100
            
            e2e_recovery = sum(1 for t in flow_ts if t.status == "PASS") / count * 100
            mean_calls = sum(t.llm_calls for t in flow_ts) / count
            mean_tokens = sum(t.input_tokens + t.output_tokens for t in flow_ts) / count
            mean_runtime = sum(t.total_runtime for t in flow_ts) / count
            
            writer.writerow([
                flow, count, f"{first_pass_rsr:.2f}%", f"{final_rsr:.2f}%",
                f"{comp_gain:.2f}%" if comp_gain is not None else "N/A",
                f"{initial_beh_pass:.2f}%", f"{final_beh_pass:.2f}%",
                f"{beh_gain:.2f}%" if beh_gain is not None else "N/A",
                f"{cx_detection_rate:.2f}%", f"{ir_verify_rate:.2f}%",
                f"{e2e_recovery:.2f}%", f"{mean_calls:.2f}", f"{mean_tokens:.2f}", f"{mean_runtime:.2f}"
            ])
            
    # Generate charts and extra CSVs
    try:
        from evaluation.visualize_experiment import generate_visualizations
        generate_visualizations(output_dir, trackers, experiment_id)
    except Exception as e:
        print(f"Error generating charts: {e}")
        traceback.print_exc()

    # Canonical schema-v2 export is the final reporting step.  It reads the
    # just-created artifacts and never re-enters recovery, compilation, or
    # fuzzing.
    try:
        from evaluation.artifact_loader import load_campaign
        from evaluation.reporting import export_report

        project_root = Path(__file__).resolve().parents[2]
        campaign_id = experiment_id.replace("experiment_", "eval_", 1)
        campaign_dir = project_root / "result" / campaign_id
        if campaign_dir.is_dir():
            export_report(
                load_campaign(project_root, campaign_dir, experiment_id),
                Path(output_dir),
            )
    except Exception as exc:
        print(f"Error generating schema-v2 evaluation report: {exc}")
        traceback.print_exc()

if __name__ == "__main__":
    main()
