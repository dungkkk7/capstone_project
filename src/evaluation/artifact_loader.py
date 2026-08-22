"""Lossless migration of completed campaign artifacts into schema v2.

No recovery stage is executed here.  Values are taken from immutable artifacts
or derived mechanically from their paths/content.  Unrecoverable historical
fields remain ``None`` and are accompanied by provenance warnings.
"""

from __future__ import annotations

import base64
import csv
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any, Iterable

from evaluation.behavior import (
    behavior_matches,
    classify_divergence,
    observation_from_record,
)
from evaluation.metrics import input_match_rate, reduction
from evaluation.schema import (
    ARTIFACT_FLOW_ORDER,
    FLOW_LAYOUT_VERSION,
    FLOW_SPECS,
    LEGACY_FLOW_LAYOUT_VERSION,
    LEGACY_FLOW_SPECS,
    LEGACY_TO_CURRENT_FLOW_ID,
    SCHEMA_VERSION,
    FlowSpec,
)


ROUND_RE = re.compile(
    r"round=(?P<round>\d+): matches=(?P<matches>\d+), "
    r"mismatches=(?P<mismatches>\d+), inconclusive=(?P<inconclusive>\d+)"
)
COMPILE_CATEGORY_PATTERNS = (
    ("COMPILER_TIMEOUT", r"timed? out|timeout"),
    ("INTERNAL_COMPILER_ERROR", r"internal compiler error|PLEASE submit a bug"),
    ("MISSING_HEADER", r"file not found|No such file or directory"),
    ("UNDECLARED_SYMBOL", r"undeclared identifier|implicit declaration"),
    ("TYPE_ERROR", r"incompatible|cannot convert|invalid operands|type error"),
    ("LINKER_ERROR", r"linker command failed|ld: error"),
    ("UNRESOLVED_EXTERNAL", r"undefined reference|undefined symbol"),
    ("UNSUPPORTED_CONSTRUCT", r"unsupported|not supported"),
    ("SYNTAX_ERROR", r"expected [;,\)\}]|syntax error"),
)


def sha256_file(path: Path) -> str | None:
    if not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _artifact_flow_spec(flow_dir: Path, flow_id: str) -> FlowSpec:
    """Use an explicit new-layout contract or preserve the legacy ID meaning."""

    contract_path = flow_dir / "flow_contract.json"
    if not contract_path.is_file():
        return LEGACY_FLOW_SPECS[flow_id]
    contract = _read_json(contract_path)
    if contract.get("flow_id") != flow_id:
        raise ValueError(
            f"Flow contract ID mismatch in {contract_path}: "
            f"{contract.get('flow_id')!r} != {flow_id!r}"
        )
    expected = FLOW_SPECS[flow_id]
    return FlowSpec(
        flow_id,
        str(contract.get("flow_name") or expected.name),
        bool(contract.get("requires_raw_ir")),
        bool(contract.get("requires_clean_ir")),
        bool(contract.get("requires_pseudocode")),
        bool(
            contract.get(
                "error_context_enabled",
                contract.get("iterative"),
            )
        ),
        requires_assembly=bool(
            contract.get("requires_assembly", expected.requires_assembly)
        ),
        optimization_level=contract.get(
            "optimization_level", expected.optimization_level
        ),
        llm_enabled=bool(contract.get("llm_enabled", expected.llm_enabled)),
    )


def _iso_timestamp(timestamp: float) -> str:
    return dt.datetime.fromtimestamp(timestamp, tz=dt.timezone.utc).isoformat()


def _git_commit(project_root: Path) -> str | None:
    try:
        return subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=project_root,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None


def _tool_version(command: list[str]) -> str | None:
    try:
        output = subprocess.run(
            command, check=True, capture_output=True, text=True
        ).stdout
        return output.splitlines()[0].strip() if output else None
    except (OSError, subprocess.CalledProcessError):
        return None


def _llvm_tools() -> tuple[str | None, str | None]:
    opt = shutil.which("opt-21") or shutil.which("opt")
    clang = shutil.which("clang-21") or shutil.which("clang")
    for root in (Path("/usr/lib/llvm-21/bin"), Path("/usr/local/bin")):
        if opt is None and (root / "opt").is_file():
            opt = str(root / "opt")
        if clang is None and (root / "clang").is_file():
            clang = str(root / "clang")
    return opt, clang


def _dataset_rows(project_root: Path) -> dict[str, dict[str, str]]:
    candidates = [
        project_root / "data" / "test_new.csv",
        project_root / "data" / "custom_dataset.csv",
    ]
    mapping: dict[str, dict[str, str]] = {}
    for candidate in candidates:
        if not candidate.is_file():
            continue
        with candidate.open("r", encoding="utf-8", newline="") as handle:
            for row in csv.DictReader(handle):
                binary = row.get("obfuscated_binary", "")
                match = re.search(r"(p\d+)", binary)
                if match:
                    mapping.setdefault(match.group(1), row)
    return mapping


def _ir_counts(path: Path) -> tuple[int, int, int]:
    instructions = basic_blocks = branches = 0
    if not path.is_file():
        return instructions, basic_blocks, branches
    in_function = False
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        text = line.strip()
        if not text or text.startswith(";"):
            continue
        if text.startswith("define "):
            in_function = True
            continue
        if text == "}":
            in_function = False
            continue
        if not in_function:
            continue
        if re.match(r"^(?:[-a-zA-Z$._][-a-zA-Z$._0-9]*|\d+):(?:\s*;.*)?$", text):
            basic_blocks += 1
            continue
        instructions += 1
        if text.startswith("br i1 ") or text.startswith("switch "):
            branches += 1
    return instructions, basic_blocks, branches


def _verify_ir(path: Path, opt: str | None) -> tuple[bool, bool | None, str | None]:
    if not path.is_file():
        return False, None, "IR artifact is missing"
    if opt is None:
        return False, None, "LLVM opt is unavailable"
    process = subprocess.run(
        [opt, "-passes=verify", "-disable-output", str(path)],
        capture_output=True,
        text=True,
    )
    error = (process.stderr or process.stdout).strip() or None
    return True, process.returncode == 0, error


def _compile_failure_category(diagnostics: str | None) -> str | None:
    if not diagnostics:
        return None
    for category, pattern in COMPILE_CATEGORY_PATTERNS:
        if re.search(pattern, diagnostics, re.IGNORECASE):
            return category
    return "OTHER"


def _usage(meta: dict[str, Any], *keys: str) -> int | None:
    usage = meta.get("usage_metadata") or {}
    for key in keys:
        if key in usage and usage[key] is not None:
            return int(usage[key])
    return None


def _usage_number(meta: dict[str, Any], *keys: str) -> float | None:
    """Read provider-supplied numeric metadata without inventing pricing."""

    usage = meta.get("usage_metadata") or {}
    for container in (meta, usage):
        for key in keys:
            value = container.get(key) if isinstance(container, dict) else None
            if value is None:
                continue
            try:
                return float(value)
            except (TypeError, ValueError):
                continue
    return None


def _attempt_records(
    identifiers: dict[str, Any],
    flow_dir: Path,
    tracker: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    llm_attempts: list[dict[str, Any]] = []
    compile_attempts: list[dict[str, Any]] = []
    attempt_index = 0
    candidates = sorted(
        flow_dir.glob("recovered_iter*.c"),
        key=lambda path: int(re.search(r"(\d+)", path.stem).group(1)),
    )
    candidate_position_by_iteration = {
        int(re.search(r"(\d+)", path.stem).group(1)): position
        for position, path in enumerate(candidates, 1)
    }
    iterations = sorted(
        {
            int(match.group(1))
            for path in flow_dir.glob("recovery_iter*.meta.json")
            if (match := re.search(r"recovery_iter(\d+)", path.name))
        }
    )
    for iteration in iterations:
        variants = [
            ("max_tokens", flow_dir / f"recovery_iter{iteration}.max_tokens.meta.json"),
            ("primary", flow_dir / f"recovery_iter{iteration}.meta.json"),
        ]
        for variant, meta_path in variants:
            if not meta_path.is_file():
                continue
            attempt_index += 1
            meta = _read_json(meta_path)
            response_path = meta_path.with_name(meta_path.name.replace(".meta.json", ".response.txt"))
            candidate_path = flow_dir / f"recovered_iter{iteration}.c"
            is_candidate_response = variant == "primary" and candidate_path.is_file()
            input_tokens = _usage(meta, "prompt_tokens", "prompt_token_count", "promptTokenCount")
            output_tokens = _usage(
                meta,
                "completion_tokens",
                "candidates_token_count",
                "candidatesTokenCount",
            )
            total_tokens = _usage(meta, "total_tokens", "total_token_count", "totalTokenCount")
            if total_tokens is None and input_tokens is not None and output_tokens is not None:
                total_tokens = input_tokens + output_tokens
            llm_attempts.append(
                {
                    **identifiers,
                    "record_type": "llm_attempt",
                    "attempt_index": attempt_index,
                    "generation_iteration": iteration,
                    "candidate_index": (
                        candidate_position_by_iteration.get(iteration)
                        if is_candidate_response
                        else None
                    ),
                    "attempt_variant": variant,
                    "model": meta.get("model") or "ag/gemini-3-flash-agent",
                    "model_version": meta.get("model_version"),
                    "temperature": meta.get("temperature"),
                    "top_p": meta.get("top_p"),
                    "max_tokens": meta.get("max_tokens", 65535),
                    "input_tokens": input_tokens,
                    "output_tokens": output_tokens,
                    "total_tokens": total_tokens,
                    "estimated_cost": _usage_number(
                        meta,
                        "estimated_cost",
                        "estimated_api_cost",
                        "cost_usd",
                        "cost",
                    ),
                    "latency_seconds": meta.get("latency_seconds"),
                    "prompt_path": (
                        str(flow_dir / f"recovery_iter{iteration}.prompt.txt")
                        if (flow_dir / f"recovery_iter{iteration}.prompt.txt").is_file()
                        else None
                    ),
                    "response_path": str(response_path) if response_path.is_file() else None,
                    "candidate_source_path": str(candidate_path) if is_candidate_response else None,
                    "candidate_source_hash": sha256_file(candidate_path) if is_candidate_response else None,
                    "finish_reason": meta.get("finish_reason"),
                    "metadata_path": str(meta_path),
                    "provenance": "recorded_metadata",
                }
            )

    recorded_calls = int(tracker.get("llm_calls", len(llm_attempts)) or 0)
    while len(llm_attempts) < recorded_calls:
        attempt_index += 1
        llm_attempts.append(
            {
                **identifiers,
                "record_type": "llm_attempt",
                "attempt_index": attempt_index,
                "generation_iteration": None,
                "candidate_index": None,
                "attempt_variant": "missing_historical_artifact",
                "model": None,
                "model_version": None,
                "temperature": None,
                "top_p": None,
                "max_tokens": None,
                "input_tokens": None,
                "output_tokens": None,
                "total_tokens": None,
                "estimated_cost": None,
                "latency_seconds": None,
                "prompt_path": None,
                "response_path": None,
                "candidate_source_path": None,
                "candidate_source_hash": None,
                "finish_reason": None,
                "metadata_path": None,
                "provenance": "aggregate_only_missing_artifact",
            }
        )

    for candidate_position, candidate_path in enumerate(candidates, 1):
        iteration = int(re.search(r"(\d+)", candidate_path.stem).group(1))
        diagnostics_path = flow_dir / f"recovery_iter{iteration}.compile.txt"
        diagnostics = (
            diagnostics_path.read_text(encoding="utf-8", errors="replace")
            if diagnostics_path.is_file()
            else None
        )
        structured_path = flow_dir / f"recovery_iter{iteration}.compile.json"
        structured = _read_json(structured_path) if structured_path.is_file() else {}
        success = bool(structured.get("compile_success")) if structured else diagnostics is None
        executable_path = flow_dir / "temp_compile.bin"
        compile_attempts.append(
            {
                **identifiers,
                "record_type": "compile_attempt",
                "attempt_index": candidate_position,
                "generation_iteration": iteration,
                "candidate_index": candidate_position,
                "compile_command": structured.get("compile_command") or [
                    "<historical-compiler-path-unrecorded>", "-O2",
                    str(candidate_path), "-o", str(executable_path), "-lm",
                ],
                "compiler_version": structured.get("compiler_version"),
                "compile_exit_code": structured.get(
                    "compile_exit_code", 0 if success else 1
                ),
                "compile_success": success,
                "link_success": success,
                "executable_created": success,
                "executable_path": str(executable_path) if success and executable_path.is_file() else None,
                "executable_hash": (
                    sha256_file(executable_path)
                    if success and executable_path.is_file() and candidate_path == candidates[-1]
                    else None
                ),
                "compile_time": structured.get("compile_time"),
                "diagnostics_path": str(diagnostics_path) if diagnostics_path.is_file() else None,
                "failure_category": _compile_failure_category(diagnostics),
                "is_compile_repair_attempt": candidate_position > 1,
                "candidate_source_path": str(candidate_path),
                "candidate_source_hash": sha256_file(candidate_path),
                "provenance": "candidate_and_diagnostics_artifacts",
            }
        )
    return llm_attempts, compile_attempts


def _compact_campaigns(state: dict[str, Any]) -> dict[int, dict[str, Any]]:
    campaigns: dict[int, dict[str, Any]] = {}
    for item in state.get("diagnostic_history") or []:
        match = ROUND_RE.search(str(item))
        if not match:
            if "semantic_pass_pending_ir_crosscheck" in str(item):
                round_match = re.search(r"round=(\d+)", str(item))
                if round_match:
                    campaigns[int(round_match.group(1))] = {
                        "matches": None,
                        "mismatches": 0,
                        "inconclusive": 0,
                        "is_fully_equivalent": True,
                        "compact_only": True,
                    }
            continue
        values = {key: int(value) for key, value in match.groupdict().items()}
        campaigns[values["round"]] = {
            "matches": values["matches"],
            "mismatches": values["mismatches"],
            "inconclusive": values["inconclusive"],
            "total_runs": values["matches"] + values["mismatches"] + values["inconclusive"],
            "confirmed_runs": values["matches"] + values["mismatches"],
            "is_fully_equivalent": False,
            "compact_only": True,
        }
    return campaigns


def _campaign_records(
    identifiers: dict[str, Any],
    flow_dir: Path,
    state: dict[str, Any],
    compile_attempts: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    campaigns = _compact_campaigns(state)
    for report_path in flow_dir.glob("recovery_iter*.fuzz.json"):
        match = re.search(r"recovery_iter(\d+)", report_path.name)
        if match:
            campaigns[int(match.group(1))] = {
                **_read_json(report_path),
                "compact_only": False,
                "report_path": str(report_path),
            }
    final_report = state.get("last_report")
    if isinstance(final_report, dict) and final_report:
        final_iteration = int(state.get("iteration") or 0)
        final_signature = (
            int(final_report.get("matches", 0) or 0),
            int(final_report.get("mismatches", 0) or 0),
            int(final_report.get("inconclusive", 0) or 0),
        )
        matching_rounds = [
            round_index
            for round_index, compact in campaigns.items()
            if (
                compact.get("matches"),
                compact.get("mismatches"),
                compact.get("inconclusive"),
            )
            == final_signature
        ]
        report_round = max(matching_rounds) if matching_rounds else final_iteration
        campaigns[report_round] = {**final_report, "compact_only": False}

    iteration_to_candidate = {
        int(attempt["generation_iteration"]): int(attempt["candidate_index"])
        for attempt in compile_attempts
        if attempt["compile_success"]
    }
    records: list[dict[str, Any]] = []
    for campaign_index, iteration in enumerate(sorted(campaigns), 1):
        report = campaigns[iteration]
        matches = report.get("matches")
        mismatches = int(report.get("mismatches", 0) or 0)
        inconclusive = int(report.get("inconclusive", 0) or 0)
        confirmed = report.get("confirmed_runs")
        if confirmed is None and matches is not None:
            confirmed = int(matches) + mismatches
        total = report.get("total_runs")
        if total is None and confirmed is not None:
            total = int(confirmed) + inconclusive
        config = report.get("fuzz_config") or {}
        evaluation_metadata = report.get("evaluation_metadata") or {}
        generated = config.get("afl_candidates")
        if generated is None:
            accepted = config.get("contract_inputs_accepted")
            rejected = config.get("contract_inputs_rejected")
            if accepted is not None or rejected is not None:
                generated = int(accepted or 0) + int(rejected or 0)
        if generated is None:
            generated = total
        executed = total
        valid = confirmed
        fuzzing_completed = bool(total and not report.get("error"))
        records.append(
            {
                **identifiers,
                "record_type": "fuzz_campaign",
                "campaign_index": campaign_index,
                "generation_iteration": iteration,
                "candidate_index": iteration_to_candidate.get(iteration),
                "fuzzing_time": evaluation_metadata.get(
                    "fuzzing_time_seconds"
                ),
                "fuzzing_completed": fuzzing_completed,
                # The campaign verdict is based on reproducible mismatches.
                # Inputs the historical runner marked unstable are excluded from
                # fuzz_valid; they do not turn an otherwise completed zero-
                # mismatch campaign into an inconclusive sample.
                "behavioral_conclusion": fuzzing_completed,
                "fuzz_generated": int(generated) if generated is not None else None,
                "fuzz_executed_on_both": int(executed) if executed is not None else None,
                "fuzz_valid": int(valid) if valid is not None else None,
                "fuzz_invalid": (
                    int(generated) - int(valid)
                    if generated is not None and valid is not None
                    else None
                ),
                "fuzz_matches": int(matches) if matches is not None else None,
                "fuzz_mismatches": mismatches,
                "fuzz_execution_errors": inconclusive,
                "corpus_size_initial": None,
                "corpus_size_final": config.get("afl_stage_inputs"),
                "seed": None,
                "budget_seconds": config.get("afl_fuzz_seconds"),
                "budget_inputs": 1000,
                "harness_status": "OK" if not report.get("error") else "ERROR",
                "coverage": (report.get("afl_stats") or {}).get("bitmap_cvg"),
                "is_fully_equivalent": bool(report.get("is_fully_equivalent")),
                "early_stopped": bool(report.get("early_stopped")),
                "compact_only": bool(report.get("compact_only")),
                "report": report,
                "provenance": (
                    "recovery_state.last_report"
                    if not report.get("compact_only")
                    else "recovery_state.diagnostic_history"
                ),
            }
        )
    return records


def _counterexample_records(
    identifiers: dict[str, Any],
    campaigns: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for campaign in campaigns:
        report = campaign.get("report") or {}
        for example_position, example in enumerate(report.get("mismatch_examples") or [], 1):
            candidate = observation_from_record(example.get("prog1") or {})
            reference = observation_from_record(example.get("prog2") or {})
            payload = base64.b64decode(example.get("stdin_base64", ""))
            payload_hash = hashlib.sha256(payload).hexdigest()
            counterexample_id = hashlib.sha256(
                (
                    f"{identifiers['sample_id']}:{identifiers['flow_id']}:"
                    f"{campaign['campaign_index']}:{payload_hash}"
                ).encode("utf-8")
            ).hexdigest()[:24]
            divergence = classify_divergence(reference, candidate)
            records.append(
                {
                    **identifiers,
                    "record_type": "counterexample",
                    "counterexample_id": counterexample_id,
                    "candidate_index": campaign.get("candidate_index"),
                    "campaign_index": campaign["campaign_index"],
                    "example_index": example_position,
                    "input_path": None,
                    "input_base64": example.get("stdin_base64"),
                    "input_hash": payload_hash,
                    "input_valid": True,
                    "minimized_input_path": None,
                    "divergence_type": divergence,
                    "replay_count": 2,
                    "replay_success_count": 2,
                    "reproducible": True,
                    "used_for_repair": campaign != campaigns[-1],
                    "reference_behavior": reference.as_json(),
                    "candidate_behavior": candidate.as_json(),
                    "reference_stdout": reference.as_json()["stdout_base64"],
                    "candidate_stdout": candidate.as_json()["stdout_base64"],
                    "reference_stderr": reference.as_json()["stderr_base64"],
                    "candidate_stderr": candidate.as_json()["stderr_base64"],
                    "reference_exit_code": reference.exit_code,
                    "candidate_exit_code": candidate.exit_code,
                    "reference_signal": reference.terminating_signal,
                    "candidate_signal": candidate.terminating_signal,
                    "reference_timeout": reference.timeout_status,
                    "candidate_timeout": candidate.timeout_status,
                    "behavior_match": behavior_matches(reference, candidate),
                    "provenance": "confirmed historical mismatch; replay count from implementation default",
                }
            )
    return records


def _strip_c_comments(text: str) -> str:
    """Remove C/C++ comments while preserving literals and line structure."""

    output: list[str] = []
    state = "normal"
    escaped = False
    index = 0
    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if state == "normal":
            if char == "/" and next_char == "*":
                state = "block_comment"
                output.extend((" ", " "))
                index += 2
                continue
            if char == "/" and next_char == "/":
                state = "line_comment"
                output.extend((" ", " "))
                index += 2
                continue
            output.append(char)
            if char == '"':
                state = "string"
                escaped = False
            elif char == "'":
                state = "char"
                escaped = False
        elif state == "line_comment":
            if char == "\n":
                output.append(char)
                state = "normal"
            else:
                output.append(" ")
        elif state == "block_comment":
            if char == "*" and next_char == "/":
                output.extend((" ", " "))
                state = "normal"
                index += 2
                continue
            output.append("\n" if char == "\n" else " ")
        else:
            output.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif (state == "string" and char == '"') or (
                state == "char" and char == "'"
            ):
                state = "normal"
        index += 1
    return "".join(output)


def _source_quality(
    original: Path | None,
    recovered: Path | None,
    evaluation: Path | None = None,
    *,
    accepted: bool = False,
) -> dict[str, Any]:
    clang_format = shutil.which("clang-format")
    base = {
        "readability_variables": None,
        "readability_loops": None,
        "readability_conditions": None,
        "readability_logic_flow": None,
        "readability_structure": None,
        "readability_overall": None,
        "readability_variables_rationale": None,
        "readability_loops_rationale": None,
        "readability_conditions_rationale": None,
        "readability_logic_flow_rationale": None,
        "readability_structure_rationale": None,
        "readability_summary": None,
        "readability_rubric_version": None,
        "readability_source_sha256": None,
        "readability_evaluated_at": None,
        "readability_correctness_assessed": None,
        "evaluator_id": None,
        "evaluation_method": None,
        "original_sloc": None,
        "recovered_sloc": None,
        "sloc_ratio": None,
        "sloc_method": None,
    }

    def sloc(path: Path) -> int | None:
        if not path.is_file():
            return None
        if clang_format:
            process = subprocess.run(
                [clang_format, str(path)], capture_output=True, text=True
            )
            if process.returncode == 0:
                text = process.stdout
            else:
                text = path.read_text(encoding="utf-8", errors="replace")
        else:
            text = path.read_text(encoding="utf-8", errors="replace")
        # Count non-empty source lines after removing comments.  Use a small
        # lexical scanner so comment markers inside C strings/chars are not
        # mistaken for comments (the common regex approach gets this wrong).
        text = _strip_c_comments(text)
        return sum(bool(line.strip()) for line in text.splitlines())

    original_sloc = (
        sloc(original)
        if original and original.is_file()
        else None
    )
    recovered_sloc = (
        sloc(recovered)
        if recovered and recovered.is_file()
        else None
    )
    base.update(
        {
            "original_sloc": original_sloc,
            "recovered_sloc": recovered_sloc,
            "sloc_method": (
                "clang-format-nonempty-lines"
                if clang_format
                else "lexical-comment-stripped-nonempty-lines"
            ),
            "sloc_ratio": (
                recovered_sloc / original_sloc
                if original_sloc and recovered_sloc is not None
                else None
            ),
        }
    )
    if (
        not accepted
        or not recovered
        or not recovered.is_file()
        or not evaluation
        or not evaluation.is_file()
    ):
        return base

    try:
        record = _read_json(evaluation)
        source_hash = sha256_file(recovered)
        if not source_hash or record.get("source_sha256") != source_hash:
            return base
        scores = record.get("scores") or {}
        rationales = record.get("rationales") or {}
        dimensions = (
            "variables",
            "loops",
            "conditions",
            "logic_flow",
            "structural_integrity",
        )
        score_values = {key: scores[key] for key in dimensions}
        if any(
            isinstance(value, bool)
            or not isinstance(value, int)
            or value not in range(1, 6)
            for value in score_values.values()
        ):
            return base
        overall = float(record.get("overall_score"))
        expected_overall = round(
            sum(score_values.values()) / len(score_values), 2
        )
        if (
            not 1.0 <= overall <= 5.0
            or abs(overall - expected_overall) > 0.001
            or record.get("accepted_candidate_only") is not True
            or record.get("correctness_assessed") is not False
            or not str(record.get("evaluator_id") or "").strip()
            or not str(record.get("evaluation_method") or "").strip()
            or any(
                not str(rationales.get(key) or "").strip()
                for key in dimensions
            )
            or not str(record.get("summary") or "").strip()
        ):
            return base
    except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError):
        return base

    base.update(
        {
            "readability_variables": score_values["variables"],
            "readability_loops": score_values["loops"],
            "readability_conditions": score_values["conditions"],
            "readability_logic_flow": score_values["logic_flow"],
            "readability_structure": score_values["structural_integrity"],
            "readability_overall": overall,
            "readability_variables_rationale": rationales.get("variables"),
            "readability_loops_rationale": rationales.get("loops"),
            "readability_conditions_rationale": rationales.get("conditions"),
            "readability_logic_flow_rationale": rationales.get("logic_flow"),
            "readability_structure_rationale": rationales.get(
                "structural_integrity"
            ),
            "readability_summary": record.get("summary"),
            "readability_rubric_version": record.get("rubric_version"),
            "readability_source_sha256": source_hash,
            "readability_evaluated_at": record.get("evaluated_at"),
            "readability_correctness_assessed": bool(
                record.get("correctness_assessed", False)
            ),
            "evaluator_id": record.get("evaluator_id"),
            "evaluation_method": record.get("evaluation_method"),
        }
    )
    return base


def _append_derived_f6(
    experiment_id: str,
    runs: list[dict[str, Any]],
    llm_attempts: list[dict[str, Any]],
    compile_attempts: list[dict[str, Any]],
    campaigns: list[dict[str, Any]],
    counterexamples: list[dict[str, Any]],
) -> None:
    """Derive a strict Raw-IR one-call checkpoint from F5's first API call.

    This never executes recovery work. A first-call artifact with no accepted
    Candidate C is a generation failure. Missing historical call/campaign
    evidence is CANCELLED rather than guessed into PASS or FAIL.
    """

    source_runs = [run for run in runs if run["flow_id"] == "F5"]
    llm_by_run: dict[str, list[dict[str, Any]]] = {}
    compile_by_run: dict[str, list[dict[str, Any]]] = {}
    campaign_by_run: dict[str, list[dict[str, Any]]] = {}
    counterexample_by_run: dict[str, list[dict[str, Any]]] = {}
    for record in llm_attempts:
        if record["flow_id"] == "F5":
            llm_by_run.setdefault(record["run_id"], []).append(record)
    for record in compile_attempts:
        if record["flow_id"] == "F5":
            compile_by_run.setdefault(record["run_id"], []).append(record)
    for record in campaigns:
        if record["flow_id"] == "F5":
            campaign_by_run.setdefault(record["run_id"], []).append(record)
    for record in counterexamples:
        if record["flow_id"] == "F5":
            counterexample_by_run.setdefault(record["run_id"], []).append(record)

    for source in source_runs:
        source_run_id = source["run_id"]
        derived_run_id = hashlib.sha256(
            (
                f"{experiment_id}:{source['sample_id']}:F6:"
                f"{source['repeat_id']}:derived-from-F5-first-call"
            ).encode("utf-8")
        ).hexdigest()[:20]
        source_llm = sorted(
            llm_by_run.get(source_run_id, []),
            key=lambda item: int(item["attempt_index"]),
        )
        first_llm = source_llm[0] if source_llm else None
        first_missing = bool(
            first_llm is None
            or first_llm.get("provenance") == "aggregate_only_missing_artifact"
        )
        candidate_available = bool(
            first_llm and first_llm.get("candidate_source_path")
        )
        candidate_index = first_llm.get("candidate_index") if first_llm else None
        generation_iteration = (
            first_llm.get("generation_iteration") if first_llm else None
        )

        matching_compiles = [
            item
            for item in compile_by_run.get(source_run_id, [])
            if candidate_available
            and (
                (
                    candidate_index is not None
                    and item.get("candidate_index") == candidate_index
                )
                or (
                    generation_iteration is not None
                    and item.get("generation_iteration") == generation_iteration
                )
            )
        ]
        first_compile = (
            min(matching_compiles, key=lambda item: int(item["attempt_index"]))
            if matching_compiles
            else None
        )
        compile_success = bool(
            first_compile and first_compile.get("compile_success")
        )
        matching_campaigns = [
            item
            for item in campaign_by_run.get(source_run_id, [])
            if compile_success
            and (
                (
                    first_compile.get("candidate_index") is not None
                    and item.get("candidate_index")
                    == first_compile.get("candidate_index")
                )
                or (
                    first_compile.get("generation_iteration") is not None
                    and item.get("generation_iteration")
                    == first_compile.get("generation_iteration")
                )
            )
        ]
        first_campaign = (
            min(
                matching_campaigns,
                key=lambda item: int(item["campaign_index"]),
            )
            if matching_campaigns
            else None
        )
        mismatches = (
            int(first_campaign.get("fuzz_mismatches") or 0)
            if first_campaign
            else None
        )
        behavioral_conclusion = bool(
            first_campaign and first_campaign.get("behavioral_conclusion")
        )
        final_counterexample = bool(
            behavioral_conclusion and mismatches and mismatches > 0
        )
        behavioral_pass = bool(
            behavioral_conclusion and mismatches == 0
        )

        if first_missing:
            status = "CANCELLED"
            derived_gap = "FIRST_LLM_CALL_ARTIFACT_MISSING"
        elif not candidate_available:
            status = "FAIL_GENERATION"
            derived_gap = None
        elif first_compile is None:
            status = "CANCELLED"
            derived_gap = "FIRST_COMPILE_ARTIFACT_MISSING"
        elif not compile_success:
            status = "FAIL_COMPILE"
            derived_gap = None
        elif first_campaign is None or not behavioral_conclusion:
            status = "CANCELLED"
            derived_gap = "FIRST_FUZZ_CAMPAIGN_ARTIFACT_MISSING"
        elif final_counterexample:
            status = "FAIL_BEHAVIORAL"
            derived_gap = None
        else:
            status = "PASS"
            derived_gap = None

        fairness = dict(source.get("fairness_configuration") or {})
        fairness.update(
            {
                "flow_name": FLOW_SPECS["F6"].name,
                "error_context_enabled": False,
                "max_iterations": 1,
                "compile_repair_budget": 0,
                "behavioral_repair_budget": 0,
                "derived_from_flow_id": "F5",
                "derivation_policy": "first_actual_provider_call_only",
            }
        )
        configuration_hash = hashlib.sha256(
            json.dumps(
                fairness,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        valid = first_campaign.get("fuzz_valid") if first_campaign else None
        matches = first_campaign.get("fuzz_matches") if first_campaign else None
        match_rate = (
            input_match_rate(matches, valid)
            if matches is not None and valid is not None
            else None
        )
        warnings = list(source.get("provenance_warnings") or [])
        warnings.append(
            "F6 is derived from F5's first actual provider call; it is not an "
            "independent recovery run."
        )
        if derived_gap:
            warnings.append(f"Derived F6 evidence gap: {derived_gap}.")

        first_source_path = (
            Path(str(first_llm["candidate_source_path"]))
            if first_llm and first_llm.get("candidate_source_path")
            else None
        )
        f6_evaluation_path = (
            first_source_path.parent / "readability_evaluation_f6.json"
            if first_source_path
            else None
        )
        f6_quality = _source_quality(
            None,
            first_source_path,
            f6_evaluation_path,
            accepted=status == "PASS",
        )
        f6_quality["original_sloc"] = source.get("original_sloc")
        if f6_quality["original_sloc"] and f6_quality["recovered_sloc"] is not None:
            f6_quality["sloc_ratio"] = (
                f6_quality["recovered_sloc"] / f6_quality["original_sloc"]
            )
        if status == "PASS" and f6_quality["readability_overall"] is None:
            warnings.append(
                "Accepted derived F6 candidate has no valid readability evaluator record."
            )

        derived = dict(source)
        derived.update(
            {
                "run_id": derived_run_id,
                "flow_id": "F6",
                "flow_name": FLOW_SPECS["F6"].name,
                "artifact_flow_id": source.get("artifact_flow_id"),
                "derived_from_flow_id": "F5",
                "derived_from_run_id": source_run_id,
                "derivation_policy": "first_actual_provider_call_only",
                "independent_run": False,
                "error_context_enabled": False,
                "iterative": False,
                "started_at": None,
                "completed_at": None,
                "configuration_hash": configuration_hash,
                "fairness_configuration": fairness,
                "historical_status": "DERIVED_FROM_F5",
                "status": status,
                "inconclusive_reason": None,
                "cancelled_reason": derived_gap,
                "llm_calls": 1,
                "input_tokens": (
                    first_llm.get("input_tokens") if first_llm else None
                ),
                "output_tokens": (
                    first_llm.get("output_tokens") if first_llm else None
                ),
                "total_tokens": (
                    first_llm.get("total_tokens") if first_llm else None
                ),
                "estimated_api_cost": (
                    first_llm.get("estimated_cost") if first_llm else None
                ),
                "llm_latency": (
                    first_llm.get("latency_seconds") if first_llm else None
                ),
                "compile_time": (
                    first_compile.get("compile_time") if first_compile else None
                ),
                "fuzzing_time": (
                    first_campaign.get("fuzzing_time")
                    if first_campaign
                    else None
                ),
                "total_runtime": None,
                "time_to_first_candidate": None,
                "time_to_first_compilable_candidate": None,
                "time_to_first_behavioral_pass_candidate": None,
                "compiler_attempts": 1 if first_compile else 0,
                "compile_success_first": (
                    bool(first_compile.get("compile_success"))
                    if first_compile
                    else None
                ),
                "any_compile_success_within_budget": (
                    bool(first_compile.get("compile_success"))
                    if first_compile
                    else None
                ),
                "last_candidate_compile_success": (
                    bool(first_compile.get("compile_success"))
                    if first_compile
                    else None
                ),
                "compile_repair_case": False,
                "compile_repair_rounds": 0,
                "compile_repair_success": None,
                "compile_candidate_before_repair": None,
                "compile_candidate_after_repair": None,
                "compiler_feedback_path": None,
                "compiler_repair_applied": False,
                "behavioral_repair_case": False,
                "behavioral_repair_rounds": 0,
                "behavioral_repair_success": None,
                "behavioral_candidate_before_repair": None,
                "behavioral_candidate_after_repair": None,
                "behavioral_repair_applied": False,
                "counterexamples_used": 0,
                "counterexample_ids_used": [],
                "regression_corpus_size": None,
                "first_behavioral_pass": (
                    behavioral_pass if behavioral_conclusion else None
                ),
                "final_behavioral_pass": (
                    behavioral_pass if behavioral_conclusion else None
                ),
                "counterexample_ever_found": final_counterexample,
                "reproducible_counterexample_ever_found": final_counterexample,
                "final_counterexample_found": final_counterexample,
                "reproducible_final_counterexample": final_counterexample,
                "fuzzing_completed": bool(
                    first_campaign and first_campaign.get("fuzzing_completed")
                ),
                "behavioral_validation_completed": behavioral_conclusion,
                "fuzz_generated": (
                    first_campaign.get("fuzz_generated")
                    if first_campaign
                    else None
                ),
                "fuzz_executed_on_both": (
                    first_campaign.get("fuzz_executed_on_both")
                    if first_campaign
                    else None
                ),
                "fuzz_valid": valid,
                "fuzz_invalid": (
                    first_campaign.get("fuzz_invalid")
                    if first_campaign
                    else None
                ),
                "fuzz_matches": matches,
                "fuzz_mismatches": mismatches,
                "fuzz_execution_errors": (
                    first_campaign.get("fuzz_execution_errors")
                    if first_campaign
                    else None
                ),
                "input_match_rate": match_rate,
                "llm_generation_completed": candidate_available,
                "compilation_completed": compile_success,
                "candidate_accepted": status == "PASS",
                # This project-level re-executability metric intentionally
                # measures executable availability only. Semantic/behavioral
                # correctness is reported separately as Canonical E2E.
                "re_executability_success": bool(
                    first_compile and first_compile.get("compile_success")
                ),
                "canonical_e2e_success": bool(
                    status == "PASS"
                    and source.get("binary_lifting_completed")
                    and source.get("raw_ir_generated")
                    and source.get("llvm_deobfuscation_completed")
                    and source.get("llvm_ir_verification_completed")
                    and source.get("pseudocode_generated")
                ),
                "flow_specific_recovery_success": bool(
                    status == "PASS" and source.get("raw_ir_generated")
                ),
                **f6_quality,
                "provenance_warnings": warnings,
            }
        )
        runs.append(derived)

        if first_llm:
            llm_attempts.append(
                {
                    **first_llm,
                    "run_id": derived_run_id,
                    "flow_id": "F6",
                    "attempt_index": 1,
                    "derived_from_flow_id": "F5",
                    "derived_from_run_id": source_run_id,
                    "independent_run": False,
                }
            )
        if first_compile:
            compile_attempts.append(
                {
                    **first_compile,
                    "run_id": derived_run_id,
                    "flow_id": "F6",
                    "attempt_index": 1,
                    "is_compile_repair_attempt": False,
                    "derived_from_flow_id": "F5",
                    "derived_from_run_id": source_run_id,
                    "independent_run": False,
                }
            )
        if first_campaign:
            derived_campaign = {
                **first_campaign,
                "run_id": derived_run_id,
                "flow_id": "F6",
                "campaign_index": 1,
                "derived_from_flow_id": "F5",
                "derived_from_run_id": source_run_id,
                "independent_run": False,
            }
            campaigns.append(derived_campaign)
            for item in counterexample_by_run.get(source_run_id, []):
                if item.get("campaign_index") != first_campaign.get(
                    "campaign_index"
                ):
                    continue
                derived_counterexample_id = hashlib.sha256(
                    (
                        f"{item['counterexample_id']}:F6:"
                        "derived-first-call"
                    ).encode("utf-8")
                ).hexdigest()[:24]
                counterexamples.append(
                    {
                        **item,
                        "run_id": derived_run_id,
                        "flow_id": "F6",
                        "counterexample_id": derived_counterexample_id,
                        "used_for_repair": False,
                        "derived_from_flow_id": "F5",
                        "derived_from_run_id": source_run_id,
                        "independent_run": False,
                    }
                )


def load_campaign(
    project_root: Path, campaign_dir: Path, experiment_id: str
) -> dict[str, Any]:
    dataset = _dataset_rows(project_root)
    opt, clang = _llvm_tools()
    git_commit = _git_commit(project_root)
    tool_versions = {
        "python": _tool_version(["python3", "--version"]),
        "llvm_opt": _tool_version([opt, "--version"]) if opt else None,
        "clang": _tool_version([clang, "--version"]) if clang else None,
        "fuzzer": "historical AFL++ metadata; binary version unrecorded",
    }
    runs: list[dict[str, Any]] = []
    llm_attempts: list[dict[str, Any]] = []
    compile_attempts: list[dict[str, Any]] = []
    campaigns: list[dict[str, Any]] = []
    counterexamples: list[dict[str, Any]] = []
    llvm_by_sample: dict[str, dict[str, Any]] = {}

    for sample_dir in sorted(path for path in campaign_dir.iterdir() if path.is_dir()):
        sample_id = sample_dir.name
        raw_ir = sample_dir / f"{sample_id}.ll"
        clean_ir = sample_dir / f"{sample_id}_final.ll"
        brightened_ir = sample_dir / f"{sample_id}_brightened.ll"
        sample_pseudocode_ready = any(
            path.is_file() and path.stat().st_size > 0
            for path in (
                list(sample_dir.glob("*/ghidra_original_program.c"))
                + list(sample_dir.glob("*/clean_pseudocode.c"))
            )
        )
        sample_assembly_ready = any(
            path.is_file() and path.stat().st_size > 0
            for path in (
                list(sample_dir.glob("*/objdump_original_program.s"))
                + list(sample_dir.glob("*/objdump_raw.txt"))
            )
        )
        raw_counts = _ir_counts(raw_ir)
        clean_counts = _ir_counts(clean_ir)
        verify_attempted, verify_success, verify_error = _verify_ir(clean_ir, opt)
        llvm_by_sample[sample_id] = {
            "experiment_id": experiment_id,
            "sample_id": sample_id,
            "raw_ir_path": str(raw_ir) if raw_ir.is_file() else None,
            "clean_ir_path": str(clean_ir) if clean_ir.is_file() else None,
            "brightened_intermediate_path": (
                str(brightened_ir) if brightened_ir.is_file() else None
            ),
            "llvm_verify_attempted": verify_attempted,
            "llvm_verify_success": verify_success,
            "llvm_verify_error": verify_error,
            "raw_instruction_count": raw_counts[0],
            "clean_instruction_count": clean_counts[0],
            "instruction_reduction_percent": reduction(raw_counts[0], clean_counts[0]),
            "raw_basic_block_count": raw_counts[1],
            "clean_basic_block_count": clean_counts[1],
            "basic_block_reduction_percent": reduction(raw_counts[1], clean_counts[1]),
            "raw_conditional_branch_count": raw_counts[2],
            "clean_conditional_branch_count": clean_counts[2],
            "conditional_branch_reduction_percent": reduction(raw_counts[2], clean_counts[2]),
        }
        for artifact_flow_id in ARTIFACT_FLOW_ORDER:
            flow_dir = sample_dir / artifact_flow_id
            artifact_spec = _artifact_flow_spec(flow_dir, artifact_flow_id)
            contract_path = flow_dir / "flow_contract.json"
            if contract_path.is_file():
                flow_id = artifact_flow_id
                required = artifact_spec
                flow_layout_version = str(
                    _read_json(contract_path).get(
                        "flow_layout_version",
                        FLOW_LAYOUT_VERSION,
                    )
                )
                source_flow_layout_version = flow_layout_version
            else:
                # Old campaigns used identical configurations under a different
                # ID order. Re-key them into the current full-first layout while
                # retaining the physical artifact ID for auditability.
                flow_id = LEGACY_TO_CURRENT_FLOW_ID[artifact_flow_id]
                required = FLOW_SPECS[flow_id]
                flow_layout_version = FLOW_LAYOUT_VERSION
                source_flow_layout_version = LEGACY_FLOW_LAYOUT_VERSION
            result_path = flow_dir / "flow_result.json"
            state_path = flow_dir / "recovery_state.json"
            if not result_path.is_file():
                continue
            tracker = _read_json(result_path)
            state = _read_json(state_path) if state_path.is_file() else {}
            files = list(flow_dir.glob("*")) + [result_path, state_path]
            mtimes = [path.stat().st_mtime for path in files if path.exists()]
            repeat_id = 0
            run_id = hashlib.sha256(
                f"{experiment_id}:{sample_id}:{flow_id}:{repeat_id}".encode("utf-8")
            ).hexdigest()[:20]
            row = dataset.get(sample_id, {})
            identifiers = {
                "schema_version": SCHEMA_VERSION,
                "experiment_id": experiment_id,
                "run_id": run_id,
                "sample_id": sample_id,
                "flow_id": flow_id,
                "artifact_flow_id": artifact_flow_id,
                "repeat_id": repeat_id,
                "benchmark_name": row.get("submission_id") or sample_id,
            }
            flow_llm, flow_compile = _attempt_records(identifiers, flow_dir, tracker)
            flow_campaigns = _campaign_records(
                identifiers, flow_dir, state, flow_compile
            )
            flow_counterexamples = _counterexample_records(identifiers, flow_campaigns)
            llm_attempts.extend(flow_llm)
            compile_attempts.extend(flow_compile)
            campaigns.extend(flow_campaigns)
            counterexamples.extend(flow_counterexamples)

            compile_success_first = bool(flow_compile and flow_compile[0]["compile_success"])
            any_compile = any(attempt["compile_success"] for attempt in flow_compile)
            last_compile = bool(flow_compile and flow_compile[-1]["compile_success"])
            first_failed_compile = (
                int(flow_compile[0]["generation_iteration"])
                if flow_compile and not flow_compile[0]["compile_success"]
                else None
            )
            compile_repair_rounds = (
                sum(
                    int(attempt["generation_iteration"]) > first_failed_compile
                    for attempt in flow_compile
                )
                if first_failed_compile is not None
                else 0
            )
            first_cex_iteration = next(
                (
                    int(campaign["generation_iteration"])
                    for campaign in flow_campaigns
                    if campaign["fuzz_mismatches"] > 0
                ),
                None,
            )
            behavioral_repair_rounds = (
                sum(
                    int(attempt["generation_iteration"]) > first_cex_iteration
                    for attempt in flow_compile
                )
                if first_cex_iteration is not None
                else 0
            )
            compile_before = (
                flow_compile[0]["candidate_source_path"]
                if first_failed_compile is not None
                else None
            )
            compile_after_attempt = next(
                (
                    attempt
                    for attempt in flow_compile[1:]
                    if attempt["compile_success"]
                ),
                flow_compile[-1] if first_failed_compile is not None and flow_compile else None,
            )
            behavior_before_attempt = next(
                (
                    attempt
                    for attempt in flow_compile
                    if first_cex_iteration is not None
                    and int(attempt["generation_iteration"]) == first_cex_iteration
                ),
                None,
            )
            final_campaign = flow_campaigns[-1] if flow_campaigns else None
            final_counterexample = bool(
                final_campaign and final_campaign["fuzz_mismatches"] > 0
            )
            final_pass = bool(
                final_campaign
                and final_campaign["fuzzing_completed"]
                and final_campaign["fuzz_mismatches"] == 0
            )
            if not flow_compile:
                status = "FAIL_GENERATION"
            elif not any_compile:
                status = "FAIL_COMPILE"
            elif final_counterexample:
                status = "FAIL_BEHAVIORAL"
            elif final_pass:
                status = "PASS"
            else:
                status = "INCONCLUSIVE"
            if status == "INCONCLUSIVE":
                if final_campaign and final_campaign["fuzz_execution_errors"] > 0:
                    inconclusive_reason = "NONDETERMINISM"
                elif final_campaign and final_campaign["early_stopped"]:
                    inconclusive_reason = "CAMPAIGN_INTERRUPTED"
                elif final_campaign:
                    inconclusive_reason = "INSUFFICIENT_BUDGET"
                else:
                    inconclusive_reason = "TOOL_ERROR"
            else:
                inconclusive_reason = None
            first_campaign = flow_campaigns[0] if flow_campaigns else None
            first_behavioral_pass = (
                bool(
                    first_campaign["fuzzing_completed"]
                    and first_campaign["fuzz_mismatches"] == 0
                )
                if first_campaign and first_campaign["behavioral_conclusion"]
                else None
            )
            final_behavioral_pass = (
                final_pass
                if final_campaign and final_campaign["behavioral_conclusion"]
                else None
            )
            final_valid = final_campaign.get("fuzz_valid") if final_campaign else None
            final_matches = final_campaign.get("fuzz_matches") if final_campaign else None
            input_rate = (
                input_match_rate(final_matches, final_valid)
                if final_matches is not None and final_valid is not None
                else None
            )
            pseudo_path = flow_dir / "clean_pseudocode.c"
            assembly_paths = (
                flow_dir / "objdump_original_program.s",
                flow_dir / "objdump_raw.txt",
            )
            raw_ready = raw_ir.is_file() and raw_ir.stat().st_size > 0
            clean_ready = clean_ir.is_file() and clean_ir.stat().st_size > 0
            pseudo_ready = (
                pseudo_path.is_file() and pseudo_path.stat().st_size > 0
            ) or (
                flow_dir / "ghidra_original_program.c"
            ).is_file() and (
                flow_dir / "ghidra_original_program.c"
            ).stat().st_size > 0
            assembly_ready = any(
                path.is_file() and path.stat().st_size > 0
                for path in assembly_paths
            )
            required_ready = (
                (not required.requires_raw_ir or raw_ready)
                and (not required.requires_clean_ir or clean_ready)
                and (not required.requires_pseudocode or pseudo_ready)
                and (not required.requires_assembly or assembly_ready)
            )
            canonical_ready = (
                raw_ready
                and clean_ready
                and sample_pseudocode_ready
                and sample_assembly_ready
            )
            recovered_path = flow_dir / f"{sample_id}_recovered.c"
            source_row = row.get("clean_source") or row.get("source_c")
            original_path = project_root / source_row if source_row else None
            quality = _source_quality(
                original_path,
                recovered_path,
                flow_dir / "readability_evaluation.json",
                accepted=status == "PASS",
            )
            total_input_tokens = sum(
                int(attempt["input_tokens"] or 0) for attempt in flow_llm
            )
            total_output_tokens = sum(
                int(attempt["output_tokens"] or 0) for attempt in flow_llm
            )
            estimated_cost_values = [
                float(attempt["estimated_cost"])
                for attempt in flow_llm
                if attempt.get("estimated_cost") is not None
            ]
            oracle_path = flow_dir / "oracle_contract.json"
            oracle_contract = _read_json(oracle_path) if oracle_path.is_file() else {}
            strict_oracle = (
                oracle_contract.get("reference_executable_kind")
                == "OBFUSCATED_BINARY"
                and oracle_contract.get("compare_stdout_bytes") is True
                and oracle_contract.get("compare_stderr_bytes") is True
                and oracle_contract.get("compare_exit_code") is True
                and oracle_contract.get("compare_terminating_signal") is True
                and oracle_contract.get("compare_timeout_status") is True
            )
            warnings: list[str] = []
            if any(
                attempt.get("latency_seconds") is None for attempt in flow_llm
            ):
                warnings.append(
                    "At least one LLM attempt is missing provider latency metadata."
                )
            if not estimated_cost_values:
                warnings.append(
                    "Provider did not return API cost metadata; estimated API cost is unavailable."
                )
            elif len(estimated_cost_values) != len(flow_llm):
                warnings.append(
                    "API cost metadata is incomplete for at least one LLM attempt."
                )
            if any(attempt["prompt_path"] is None for attempt in flow_llm):
                warnings.append(
                    "Historical prompts were not persisted; prompt_path is null."
                )
            if any(
                attempt["compiler_version"] is None for attempt in flow_compile
            ):
                warnings.append(
                    "Historical compiler executable/version and per-attempt timing were not persisted."
                )
            if any(campaign["compact_only"] for campaign in flow_campaigns):
                warnings.append(
                    "Only final fuzz reports and compact prior-round summaries survived."
                )
            if not strict_oracle:
                warnings.extend(
                    [
                        "Historical oracle did not enable strict stderr comparison for every input.",
                        "Historical campaign compared candidates with a Clean-IR-compiled reference, not the mandated obfuscated binary.",
                    ]
                )
            if len(flow_llm) != int(tracker.get("llm_calls", 0) or 0):
                warnings.append("LLM attempt artifact count differs from tracker aggregate.")
            if any(attempt["provenance"] == "aggregate_only_missing_artifact" for attempt in flow_llm):
                warnings.append("At least one LLM call has no response/metadata artifact.")
            if quality["sloc_ratio"] is None:
                warnings.append("Source prerequisite unavailable; SLOC metrics are null.")
            elif quality["sloc_method"] != "clang-format-nonempty-lines":
                warnings.append(
                    "SLOC measured with lexical comment-stripped fallback because clang-format is unavailable."
                )
            if status == "PASS" and quality["readability_overall"] is None:
                warnings.append(
                    "Accepted candidate has no valid readability evaluator record."
                )
            final_fuzz_config = (
                (final_campaign.get("report") or {}).get("fuzz_config") or {}
                if final_campaign
                else {}
            )
            fairness_configuration = {
                "flow_name": required.name,
                "flow_layout_version": flow_layout_version,
                "source_flow_layout_version": source_flow_layout_version,
                "source_flow_name": artifact_spec.name,
                "model": "ag/gemini-3-flash-agent",
                "model_version": sorted(
                    {
                        str(attempt["model_version"])
                        for attempt in flow_llm
                        if attempt["model_version"]
                    }
                ),
                "temperature": None,
                "top_p": None,
                "max_tokens": 65535,
                "max_iterations": state.get("max_iterations"),
                "error_context_enabled": required.iterative,
                "fuzzing_seed": None,
                "fuzzing_budget_inputs": 1000,
                "fuzzing_budget_seconds": final_fuzz_config.get("afl_fuzz_seconds"),
                "runtime_timeout_seconds": final_fuzz_config.get("timeout_seconds"),
                "compile_repair_budget": 4 if required.iterative else 0,
                "behavioral_repair_budget": 4 if required.iterative else 0,
                "cpu_limit": None,
                "memory_limit": None,
            }
            configuration_hash = hashlib.sha256(
                json.dumps(
                    fairness_configuration, sort_keys=True, separators=(",", ":")
                ).encode("utf-8")
            ).hexdigest()
            run = {
                **identifiers,
                "flow_name": required.name,
                "flow_layout_version": flow_layout_version,
                "source_flow_layout_version": source_flow_layout_version,
                "source_flow_name": artifact_spec.name,
                "error_context_enabled": required.iterative,
                "iterative": required.iterative,
                "started_at": _iso_timestamp(min(mtimes)) if mtimes else None,
                "completed_at": _iso_timestamp(max(mtimes)) if mtimes else None,
                "configuration_hash": configuration_hash,
                "request_hash": state.get("request_sha256"),
                "fairness_configuration": fairness_configuration,
                "git_commit": git_commit,
                "tool_versions": tool_versions,
                "original_obfuscated_binary_path": (
                    str(project_root / row["obfuscated_binary"])
                    if row.get("obfuscated_binary")
                    else None
                ),
                "reference_executable_path": oracle_contract.get(
                    "reference_executable_path",
                    str(sample_dir / f"{sample_id}_final_ref.bin"),
                ),
                "reference_executable_kind": oracle_contract.get(
                    "reference_executable_kind",
                    "CLEAN_IR_COMPILED_REFERENCE",
                ),
                "strict_mandated_oracle_compatible": strict_oracle,
                "historical_status": tracker.get("status"),
                "status": status,
                "inconclusive_reason": inconclusive_reason,
                "llm_calls": int(tracker.get("llm_calls", len(flow_llm)) or 0),
                "input_tokens": total_input_tokens,
                "output_tokens": total_output_tokens,
                "total_tokens": total_input_tokens + total_output_tokens,
                "estimated_api_cost": (
                    sum(estimated_cost_values)
                    if estimated_cost_values
                    else None
                ),
                "llm_latency": tracker.get("llm_latency"),
                "preprocessing_time": None,
                "compile_time": tracker.get("compile_time"),
                "fuzzing_time": tracker.get("fuzzing_time"),
                "total_runtime": tracker.get("total_runtime"),
                "time_to_first_candidate": None,
                "time_to_first_compilable_candidate": None,
                "time_to_first_behavioral_pass_candidate": None,
                "compiler_attempts": len(flow_compile),
                "compile_success_first": (
                    compile_success_first if flow_compile else None
                ),
                "any_compile_success_within_budget": (
                    any_compile if flow_compile else None
                ),
                "last_candidate_compile_success": (
                    last_compile if flow_compile else None
                ),
                "compile_repair_case": (
                    first_failed_compile is not None and required.iterative
                ),
                "compile_repair_rounds": (
                    compile_repair_rounds if required.iterative else 0
                ),
                "compile_repair_success": (
                    any_compile
                    if first_failed_compile is not None and required.iterative
                    else None
                ),
                "compile_candidate_before_repair": compile_before,
                "compile_candidate_after_repair": (
                    compile_after_attempt["candidate_source_path"]
                    if compile_after_attempt is not None
                    else None
                ),
                "compiler_feedback_path": (
                    flow_compile[0]["diagnostics_path"]
                    if first_failed_compile is not None
                    else None
                ),
                "compiler_repair_applied": bool(
                    required.iterative and compile_repair_rounds > 0
                ),
                "behavioral_repair_case": (
                    first_cex_iteration is not None and required.iterative
                ),
                "behavioral_repair_rounds": (
                    behavioral_repair_rounds if required.iterative else 0
                ),
                "behavioral_repair_success": (
                    final_pass
                    if first_cex_iteration is not None and required.iterative
                    else None
                ),
                "behavioral_candidate_before_repair": (
                    behavior_before_attempt["candidate_source_path"]
                    if behavior_before_attempt is not None
                    else None
                ),
                "behavioral_candidate_after_repair": (
                    flow_compile[-1]["candidate_source_path"]
                    if first_cex_iteration is not None and flow_compile
                    else None
                ),
                "behavioral_repair_applied": bool(
                    required.iterative and behavioral_repair_rounds > 0
                ),
                "counterexamples_used": sum(
                    bool(item["used_for_repair"]) for item in flow_counterexamples
                ),
                "counterexample_ids_used": [
                    item["counterexample_id"]
                    for item in flow_counterexamples
                    if item["used_for_repair"]
                ],
                "regression_corpus_size": None,
                "first_behavioral_pass": first_behavioral_pass,
                "final_behavioral_pass": final_behavioral_pass,
                "counterexample_ever_found": any(
                    campaign["fuzz_mismatches"] > 0 for campaign in flow_campaigns
                ),
                "reproducible_counterexample_ever_found": any(
                    campaign["fuzz_mismatches"] > 0 for campaign in flow_campaigns
                ),
                "final_counterexample_found": final_counterexample,
                "reproducible_final_counterexample": final_counterexample,
                "fuzzing_completed": bool(final_campaign and final_campaign["fuzzing_completed"]),
                "behavioral_validation_completed": bool(
                    final_campaign and final_campaign["behavioral_conclusion"]
                ),
                "fuzz_generated": final_campaign.get("fuzz_generated") if final_campaign else None,
                "fuzz_executed_on_both": final_campaign.get("fuzz_executed_on_both") if final_campaign else None,
                "fuzz_valid": final_valid,
                "fuzz_invalid": final_campaign.get("fuzz_invalid") if final_campaign else None,
                "fuzz_matches": final_matches,
                "fuzz_mismatches": final_campaign.get("fuzz_mismatches") if final_campaign else None,
                "fuzz_execution_errors": final_campaign.get("fuzz_execution_errors") if final_campaign else None,
                "input_match_rate": input_rate,
                "binary_lifting_completed": raw_ready,
                "raw_ir_generated": raw_ready,
                "llvm_deobfuscation_completed": clean_ready,
                "llvm_ir_verification_completed": verify_success is True,
                "pseudocode_generated": sample_pseudocode_ready,
                "llm_generation_completed": bool(flow_llm),
                "compilation_completed": any_compile,
                "candidate_accepted": status == "PASS",
                # Executable availability is deliberately separate from the
                # semantic PASS status below.
                "re_executability_success": bool(any_compile),
                "canonical_e2e_success": bool(status == "PASS" and canonical_ready),
                "flow_specific_recovery_success": bool(status == "PASS" and required_ready),
                "peak_memory": None,
                "cpu_time": None,
                **llvm_by_sample[sample_id],
                **quality,
                "provenance_warnings": warnings,
            }
            runs.append(run)

    _append_derived_f6(
        experiment_id,
        runs,
        llm_attempts,
        compile_attempts,
        campaigns,
        counterexamples,
    )

    return {
        "schema_version": SCHEMA_VERSION,
        "experiment_id": experiment_id,
        "campaign_dir": str(campaign_dir),
        "runs": runs,
        "llm_attempts": llm_attempts,
        "compile_attempts": compile_attempts,
        "campaigns": campaigns,
        "counterexamples": counterexamples,
        "llvm_samples": list(llvm_by_sample.values()),
        "tool_versions": tool_versions,
        "git_commit": git_commit,
    }
