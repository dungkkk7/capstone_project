from __future__ import annotations

import base64
import os
import shutil
import signal
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any, Dict, Iterable, Mapping

from fuzzing_equi_check.fuzzing import SemanticFuzzer, make_bytes_generator
from fuzzing_equi_check.input_contracts import (
    generate_contract_inputs,
    resolve_input_contract,
)

from .models import BuildResult, SampleIdentity
from .storage import (
    atomic_write_bytes,
    atomic_write_json,
    load_json,
    sha256_bytes,
    sha256_file,
    stable_json_sha256,
)


class EvaluationError(RuntimeError):
    pass


def build_candidate(
    candidate_path: str | Path,
    output_dir: str | Path,
    config: Dict[str, Any],
) -> BuildResult:
    source = Path(candidate_path)
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    executable = output / "candidate.bin"
    stdout_path = output / "stdout.log"
    stderr_path = output / "stderr.log"
    build_config = config["build"]
    command = [
        str(build_config["compiler"]),
        *[str(flag) for flag in build_config["flags"]],
        str(source),
        *[str(flag) for flag in build_config.get("link_flags", [])],
        "-o",
        str(executable),
    ]
    compiler_version_process = subprocess.run(
        [str(build_config["compiler"]), "--version"],
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    compiler_version = (
        compiler_version_process.stdout
        or compiler_version_process.stderr
        or "unknown"
    ).splitlines()[0]
    started = time.perf_counter()
    try:
        process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=float(build_config["timeout_sec"]),
            check=False,
        )
        return_code = process.returncode
        stdout = process.stdout or ""
        stderr = process.stderr or ""
    except subprocess.TimeoutExpired as exc:
        return_code = None
        stdout = exc.stdout or ""
        stderr = (exc.stderr or "") + "\nBUILD_TIMEOUT"
    duration_ms = int((time.perf_counter() - started) * 1000)
    stdout_path.write_text(
        stdout.decode(errors="replace") if isinstance(stdout, bytes) else stdout,
        encoding="utf-8",
    )
    stderr_path.write_text(
        stderr.decode(errors="replace") if isinstance(stderr, bytes) else stderr,
        encoding="utf-8",
    )
    ok = return_code == 0 and executable.is_file()
    result = BuildResult(
        ok=ok,
        command=command,
        compiler_version=compiler_version,
        return_code=return_code,
        stdout_path=str(stdout_path),
        stderr_path=str(stderr_path),
        executable_path=str(executable) if ok else None,
        executable_sha256=sha256_file(executable) if ok else None,
        duration_ms=duration_ms,
    )
    atomic_write_json(output / "build.json", result.to_dict())
    return result


def _seed_bytes(project_root: Path, sample_id: str) -> list[bytes]:
    seed_dir = project_root / "data" / "seeds" / sample_id
    if not seed_dir.is_dir():
        return []
    payloads = []
    for path in sorted(item for item in seed_dir.iterdir() if item.is_file()):
        data = path.read_bytes()
        if data and data not in payloads:
            payloads.append(data)
    return payloads


def prepare_base_corpus(
    sample: SampleIdentity,
    output_dir: str | Path,
    config: Dict[str, Any],
) -> list[Dict[str, Any]]:
    output = Path(output_dir)
    inputs_dir = output / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    root = Path(config["_project_root"])
    seeds = _seed_bytes(root, sample.sample_id)
    contract = resolve_input_contract(
        str(root), sample.original_elf_path, only_custom=True
    )
    generated: list[bytes] = []
    stats: Dict[str, int] = {"accepted": 0, "rejected": 0}
    if contract and seeds:
        generated, stats = generate_contract_inputs(
            contract,
            seeds,
            len(seeds)
            + int(config["corpus"]["deterministic_supplement_count"]),
            rng_seed=int(config["corpus"]["generator_seed"]),
        )
    payloads: list[tuple[str, bytes]] = []
    for item in seeds:
        payloads.append(("seed", item))
    for item in generated:
        if item not in seeds:
            payloads.append(("contract_supplement", item))
    if not payloads:
        payloads.append(("boundary", b"0\n"))

    dedup: Dict[str, tuple[str, bytes]] = {}
    for category, data in payloads:
        digest = sha256_bytes(data)
        dedup.setdefault(digest, (category, data))
    ordered = sorted(
        dedup.items(), key=lambda item: (item[1][0], item[0])
    )
    manifest = []
    for index, (digest, (category, data)) in enumerate(ordered):
        input_id = f"{category}_{index:05d}"
        path = inputs_dir / f"{input_id}.bin"
        atomic_write_bytes(path, data)
        manifest.append(
            {
                "input_id": input_id,
                "category": category,
                "path": str(path),
                "sha256": digest,
                "size": len(data),
                "contract_valid": True if contract else None,
                "origin_method": None,
            }
        )
    corpus_payload = {
        "sample_id": sample.sample_id,
        "generator_seed": int(config["corpus"]["generator_seed"]),
        "contract": (
            {"case_id": contract.get("case_id"), "kind": contract.get("kind")}
            if contract
            else None
        ),
        "generation_stats": stats,
        "inputs": manifest,
    }
    corpus_payload["corpus_sha256"] = stable_json_sha256(manifest)
    atomic_write_json(output / "corpus_manifest.json", corpus_payload)
    return manifest


def discover_inputs(
    sample: SampleIdentity,
    candidate_source_path: str,
    base_inputs: list[Dict[str, Any]],
    method: str,
    output_dir: str | Path,
    config: Dict[str, Any],
) -> list[Dict[str, Any]]:
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    candidate_source = Path(candidate_source_path)
    if (
        not candidate_source.is_file()
        or candidate_source.suffix.lower() != ".c"
    ):
        raise EvaluationError(
            "DISCOVERY_REQUIRES_FROZEN_C_SOURCE"
        )
    if not config["fuzz"].get("enabled", True):
        atomic_write_json(
            output / "fuzz_discovery.json",
            {"enabled": False, "method": method, "inputs": []},
        )
        return []
    seeds = [Path(item["path"]).read_bytes() for item in base_inputs]
    root = Path(config["_project_root"])
    contract = resolve_input_contract(
        str(root), sample.original_elf_path, only_custom=True
    )
    fuzzer = SemanticFuzzer(
        str(candidate_source),
        sample.original_elf_path,
        seed_inputs=seeds,
        input_contract=contract,
    )
    previous_fuzz_seconds = os.environ.get("BRIGHTEN_AFL_FUZZ_SECONDS")
    os.environ["BRIGHTEN_AFL_FUZZ_SECONDS"] = str(
        config["fuzz"]["seconds_per_method"]
    )
    try:
        fuzzer.compile()
        report = fuzzer.run_differential_test(
            iterations=int(config["fuzz"]["target_accepted_inputs"]),
            generator=make_bytes_generator(),
            timeout=float(config["evaluation"]["per_input_timeout_sec"]),
            compare_stderr=bool(config["evaluation"]["compare_stderr"]),
            num_workers=1,
            seed_inputs=seeds,
        )
    finally:
        if previous_fuzz_seconds is None:
            os.environ.pop("BRIGHTEN_AFL_FUZZ_SECONDS", None)
        else:
            os.environ["BRIGHTEN_AFL_FUZZ_SECONDS"] = previous_fuzz_seconds
        fuzzer.cleanup()

    decoded = []
    for encoded in report.get("tested_payloads", []):
        try:
            data = base64.b64decode(encoded, validate=True)
        except Exception:
            continue
        if data not in decoded:
            decoded.append(data)
    base_hashes = {item["sha256"] for item in base_inputs}
    discovered = []
    discovered_dir = output / "inputs"
    discovered_dir.mkdir(exist_ok=True)
    max_unique = int(config["fuzz"]["max_saved_unique_inputs"])
    for data in decoded:
        digest = sha256_bytes(data)
        if digest in base_hashes:
            continue
        path = discovered_dir / f"{digest}.bin"
        atomic_write_bytes(path, data)
        discovered.append(
            {
                "input_id": f"fuzz_{method}_{len(discovered):05d}",
                "category": "fuzz_discovery",
                "path": str(path),
                "sha256": digest,
                "size": len(data),
                "contract_valid": True if contract else None,
                "origin_method": method,
            }
        )
        if len(discovered) >= max_unique:
            break
    atomic_write_json(
        output / "fuzz_discovery.json",
        {
            "enabled": True,
            "method": method,
            "report": report,
            "inputs": discovered,
        },
    )
    return discovered


def build_union_corpus(
    base_inputs: list[Dict[str, Any]],
    discoveries: Iterable[list[Dict[str, Any]]],
    output_dir: str | Path,
) -> tuple[list[Dict[str, Any]], str]:
    output = Path(output_dir)
    manifest_path = output / "union_replay_manifest.json"
    if manifest_path.is_file():
        try:
            frozen = load_json(manifest_path)
            union = list(frozen["inputs"])
            frozen_hash = str(frozen["corpus_sha256"])
        except (OSError, ValueError, KeyError, TypeError) as exc:
            raise EvaluationError(
                f"FROZEN_UNION_MANIFEST_INVALID: {exc}"
            ) from exc
        for item in union:
            path = Path(str(item.get("path") or ""))
            if not path.is_file():
                raise EvaluationError(
                    f"FROZEN_UNION_INPUT_MISSING: {path}"
                )
            data = path.read_bytes()
            if sha256_bytes(data) != item.get("sha256"):
                raise EvaluationError(
                    f"FROZEN_UNION_INPUT_HASH_MISMATCH: {path}"
                )
            if len(data) != int(item.get("size", -1)):
                raise EvaluationError(
                    f"FROZEN_UNION_INPUT_SIZE_MISMATCH: {path}"
                )
        recomputed_hash = stable_json_sha256(
            [
                {
                    "sha256": item["sha256"],
                    "size": item["size"],
                    "category": item["category"],
                    "origin_method": item.get("origin_method"),
                }
                for item in union
            ]
        )
        if recomputed_hash != frozen_hash:
            raise EvaluationError("FROZEN_UNION_CORPUS_HASH_MISMATCH")
        return union, frozen_hash

    inputs_dir = output / "union_inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    combined = list(base_inputs)
    for items in discoveries:
        combined.extend(items)
    by_hash: Dict[str, Dict[str, Any]] = {}
    for item in combined:
        by_hash.setdefault(item["sha256"], item)
    union = []
    for index, digest in enumerate(sorted(by_hash)):
        source = by_hash[digest]
        data = Path(source["path"]).read_bytes()
        path = inputs_dir / f"union_{index:05d}_{digest[:12]}.bin"
        atomic_write_bytes(path, data)
        normalized = dict(source)
        normalized["input_id"] = f"union_{index:05d}"
        normalized["path"] = str(path)
        union.append(normalized)
    corpus_hash = stable_json_sha256(
        [
            {
                "sha256": item["sha256"],
                "size": item["size"],
                "category": item["category"],
                "origin_method": item.get("origin_method"),
            }
            for item in union
        ]
    )
    atomic_write_json(
        manifest_path,
        {
            "schema_version": "1.0",
            "frozen": True,
            "corpus_sha256": corpus_hash,
            "inputs": union,
        },
    )
    return union, corpus_hash


def _run_program(
    executable: str,
    data: bytes,
    timeout: float,
    environment: Mapping[str, str],
) -> Dict[str, Any]:
    started = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="experiment_exec_") as workdir:
        env = os.environ.copy()
        env.update({str(key): str(value) for key, value in environment.items()})
        try:
            process = subprocess.run(
                [executable],
                input=data,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=workdir,
                env=env,
                timeout=max(0.001, timeout),
                check=False,
                start_new_session=True,
            )
            status = "crash" if process.returncode < 0 else "success"
            return {
                "status": status,
                "returncode": process.returncode,
                "signal": -process.returncode if process.returncode < 0 else None,
                "stdout": process.stdout,
                "stderr": process.stderr,
                "duration_ms": int((time.perf_counter() - started) * 1000),
            }
        except subprocess.TimeoutExpired as exc:
            return {
                "status": "timeout",
                "returncode": None,
                "signal": None,
                "stdout": exc.stdout or b"",
                "stderr": exc.stderr or b"",
                "duration_ms": int((time.perf_counter() - started) * 1000),
            }
        except Exception as exc:
            return {
                "status": "infra_error",
                "returncode": None,
                "signal": None,
                "stdout": b"",
                "stderr": str(exc).encode("utf-8", errors="replace"),
                "duration_ms": int((time.perf_counter() - started) * 1000),
            }


def _persist_outcome(
    output_dir: Path, input_sha256: str, outcome: Dict[str, Any]
) -> Dict[str, Any]:
    output_dir.mkdir(parents=True, exist_ok=True)
    stdout_path = output_dir / f"{input_sha256}.stdout"
    stderr_path = output_dir / f"{input_sha256}.stderr"
    atomic_write_bytes(stdout_path, outcome["stdout"])
    atomic_write_bytes(stderr_path, outcome["stderr"])
    serializable = {
        key: value
        for key, value in outcome.items()
        if key not in {"stdout", "stderr"}
    }
    serializable.update(
        {
            "input_sha256": input_sha256,
            "stdout_path": str(stdout_path),
            "stdout_sha256": sha256_bytes(outcome["stdout"]),
            "stderr_path": str(stderr_path),
            "stderr_sha256": sha256_bytes(outcome["stderr"]),
        }
    )
    atomic_write_json(output_dir / f"{input_sha256}.json", serializable)
    return serializable


def execute_reference(
    sample: SampleIdentity,
    union: list[Dict[str, Any]],
    output_dir: str | Path,
    config: Dict[str, Any],
) -> Dict[str, Dict[str, Any]]:
    output = Path(output_dir)
    outcomes: Dict[str, Dict[str, Any]] = {}
    eval_config = config["evaluation"]
    repeat_count = max(1, int(eval_config.get("nondeterminism_repeats", 1)))
    repeat_subset = min(5, len(union))
    for index, item in enumerate(union):
        data = Path(item["path"]).read_bytes()
        raw = _run_program(
            sample.original_elf_path,
            data,
            float(eval_config["per_input_timeout_sec"]),
            eval_config["environment"],
        )
        nondeterministic = False
        if index < repeat_subset and repeat_count > 1:
            expected = _observable_key(raw)
            for _ in range(repeat_count - 1):
                repeated = _run_program(
                    sample.original_elf_path,
                    data,
                    float(eval_config["per_input_timeout_sec"]),
                    eval_config["environment"],
                )
                if _observable_key(repeated) != expected:
                    nondeterministic = True
                    break
        if nondeterministic:
            raw["status"] = "nondeterministic"
        outcomes[item["sha256"]] = {
            "raw": raw,
            "persisted": _persist_outcome(output, item["sha256"], raw),
        }
    return outcomes


def _observable_key(outcome: Dict[str, Any]) -> tuple[Any, ...]:
    return (
        outcome.get("status"),
        outcome.get("returncode"),
        outcome.get("signal"),
        outcome.get("stdout", b""),
        outcome.get("stderr", b""),
    )


def _compare(
    reference: Dict[str, Any],
    candidate: Dict[str, Any],
    config: Dict[str, Any],
) -> str:
    ref_status = reference["status"]
    cand_status = candidate["status"]
    if ref_status == "nondeterministic":
        return "INCONCLUSIVE_REFERENCE_NONDETERMINISTIC"
    if cand_status == "nondeterministic":
        return "MISMATCH_CANDIDATE_NONDETERMINISTIC"
    if ref_status == "infra_error" or cand_status == "infra_error":
        return "INCONCLUSIVE_INFRA"
    if ref_status == "timeout":
        return (
            "INCONCLUSIVE_BOTH_TIMEOUT"
            if cand_status == "timeout"
            else "INCONCLUSIVE_REFERENCE_TIMEOUT"
        )
    if ref_status == "crash":
        if (
            cand_status == "crash"
            and reference.get("signal") == candidate.get("signal")
            and reference["stdout"] == candidate["stdout"]
            and (
                not config["evaluation"]["compare_stderr"]
                or reference["stderr"] == candidate["stderr"]
            )
        ):
            return "INCONCLUSIVE_BOTH_CRASH"
        return "MISMATCH_REFERENCE_CRASH_ASYMMETRY"
    if cand_status == "timeout":
        return "MISMATCH_TIMEOUT_ASYMMETRY"
    if cand_status == "crash":
        return "MISMATCH_CRASH_ASYMMETRY"
    if cand_status != "success":
        return "MISMATCH_EXECUTION_STATUS"
    if (
        config["evaluation"]["compare_exit_status"]
        and reference["returncode"] != candidate["returncode"]
    ):
        return "MISMATCH_EXIT_STATUS"
    if config["evaluation"]["compare_stdout"] and reference["stdout"] != candidate["stdout"]:
        return "MISMATCH_STDOUT"
    if config["evaluation"]["compare_stderr"] and reference["stderr"] != candidate["stderr"]:
        return "MISMATCH_STDERR"
    return "MATCH"


def replay_candidate(
    candidate_executable: str,
    candidate_sha256: str,
    union: list[Dict[str, Any]],
    corpus_hash: str,
    reference_outcomes: Dict[str, Dict[str, Any]],
    output_dir: str | Path,
    config: Dict[str, Any],
) -> Dict[str, Any]:
    if sha256_file(candidate_executable) != candidate_sha256:
        raise EvaluationError("CANDIDATE_MUTATED")
    output = Path(output_dir)
    outcome_dir = output / "outcomes"
    eval_config = config["evaluation"]
    counts: Dict[str, int] = {}
    per_input = []
    repeat_count = max(1, int(eval_config.get("nondeterminism_repeats", 1)))
    repeat_subset = min(5, len(union))
    for index, item in enumerate(union):
        data = Path(item["path"]).read_bytes()
        raw = _run_program(
            candidate_executable,
            data,
            float(eval_config["per_input_timeout_sec"]),
            eval_config["environment"],
        )
        if (
            index < repeat_subset
            and repeat_count > 1
            and raw["status"] != "infra_error"
        ):
            expected = _observable_key(raw)
            for _ in range(repeat_count - 1):
                repeated = _run_program(
                    candidate_executable,
                    data,
                    float(eval_config["per_input_timeout_sec"]),
                    eval_config["environment"],
                )
                if _observable_key(repeated) != expected:
                    raw["status"] = "nondeterministic"
                    break
        persisted = _persist_outcome(outcome_dir, item["sha256"], raw)
        reference = reference_outcomes[item["sha256"]]["raw"]
        classification = _compare(reference, raw, config)
        counts[classification] = counts.get(classification, 0) + 1
        per_input.append(
            {
                "input_sha256": item["sha256"],
                "classification": classification,
                "candidate_outcome": persisted,
            }
        )
    if sha256_file(candidate_executable) != candidate_sha256:
        raise EvaluationError("CANDIDATE_MUTATED")
    matches = counts.get("MATCH", 0)
    mismatches = sum(
        count for key, count in counts.items() if key.startswith("MISMATCH")
    )
    inconclusive = len(union) - matches - mismatches
    confirmed = matches + mismatches
    reference_inconclusive_fraction = (
        inconclusive / len(union) if union else 1.0
    )
    behavior_pass = (
        mismatches == 0
        and confirmed >= int(eval_config["min_confirmed_inputs"])
        and reference_inconclusive_fraction
        <= float(eval_config["max_reference_inconclusive_fraction"])
    )
    first_classification = (
        per_input[0]["classification"] if per_input else "INCONCLUSIVE_NO_INPUT"
    )
    smoke_runnable = first_classification not in {
        "MISMATCH_TIMEOUT_ASYMMETRY",
        "MISMATCH_CRASH_ASYMMETRY",
        "MISMATCH_EXECUTION_STATUS",
    }
    result = {
        "reference_kind": "original_obfuscated_elf",
        "corpus_manifest_sha256": corpus_hash,
        "union_input_count": len(union),
        "confirmed_inputs": confirmed,
        "matches": matches,
        "mismatches": mismatches,
        "inconclusive": inconclusive,
        "classification_counts": counts,
        "reference_inconclusive_fraction": reference_inconclusive_fraction,
        "behavior_pass": behavior_pass,
        "smoke_runnable": smoke_runnable,
        "per_input": per_input,
    }
    atomic_write_json(output / "union_replay.json", result)
    return result
