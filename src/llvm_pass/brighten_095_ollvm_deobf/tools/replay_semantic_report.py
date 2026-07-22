#!/usr/bin/env python3
"""Replay a saved semantic report against the exact published artifact.

This tool is intended for pipeline forensics.  It recompiles the saved
``*_brightened.bc``/``.ll``, executes the report's payload corpus against that
binary and the saved reference executable, and records content hashes for every
artifact.  It therefore detects reports produced from a stale or colliding
executable path.
"""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


MAX_CAPTURE = 1 << 20


def file_sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def manifest(path):
    path = Path(path).resolve()
    return {
        "path": str(path),
        "size": path.stat().st_size,
        "sha256": file_sha256(path),
    }


def tool_identity(path):
    path = Path(path).resolve()
    result = subprocess.run(
        [str(path), "--version"], capture_output=True, text=True, check=False
    )
    return {
        **manifest(path),
        "version": (result.stdout or result.stderr).strip()[:8192],
        "version_returncode": result.returncode,
    }


def run_program(binary, payload, args, timeout):
    try:
        result = subprocess.run(
            [str(binary), *args],
            input=payload,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        if result.returncode == 0:
            status = "success"
        elif result.returncode < 0:
            status = "crash"
        else:
            status = "exit"
        return {
            "status": status,
            "returncode": result.returncode,
            "signal": -result.returncode if result.returncode < 0 else None,
            "stdout": result.stdout.decode("utf-8", errors="replace"),
            "stderr": result.stderr.decode("utf-8", errors="replace"),
            "stdout_sha256": hashlib.sha256(result.stdout).hexdigest(),
            "stderr_sha256": hashlib.sha256(result.stderr).hexdigest(),
            "stdout_b64": base64.b64encode(result.stdout[:MAX_CAPTURE]).decode("ascii"),
            "stderr_b64": base64.b64encode(result.stderr[:MAX_CAPTURE]).decode("ascii"),
        }
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout or b""
        stderr = exc.stderr or b""
        return {
            "status": "timeout",
            "returncode": None,
            "signal": None,
            "stdout": stdout.decode("utf-8", errors="replace"),
            "stderr": stderr.decode("utf-8", errors="replace"),
            "stdout_sha256": hashlib.sha256(stdout).hexdigest(),
            "stderr_sha256": hashlib.sha256(stderr).hexdigest(),
            "stdout_b64": base64.b64encode(stdout[:MAX_CAPTURE]).decode("ascii"),
            "stderr_b64": base64.b64encode(stderr[:MAX_CAPTURE]).decode("ascii"),
        }


def comparable(execution):
    return (
        execution.get("status"),
        execution.get("returncode"),
        execution.get("stdout", ""),
        execution.get("stderr", ""),
    )


def stored_comparable(execution):
    if not execution:
        return None
    return (
        execution.get("status"),
        execution.get("returncode"),
        execution.get("stdout", ""),
        execution.get("stderr", ""),
    )


def unique_match(directory, pattern, *, required=True):
    matches = sorted(directory.glob(pattern))
    if len(matches) == 1:
        return matches[0]
    if not required and not matches:
        return None
    raise SystemExit(
        f"expected exactly one {pattern!r} in {directory}, found {len(matches)}"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--case-dir", required=True)
    parser.add_argument("--semantic-report")
    parser.add_argument("--artifact")
    parser.add_argument("--reference")
    parser.add_argument("--clang", default="clang-21")
    parser.add_argument("--timeout", type=float, default=0.5)
    parser.add_argument("--payload-limit", type=int, default=0)
    parser.add_argument("--report")
    parser.add_argument(
        "--compat-strip-icmp-samesign",
        action="store_true",
        help="audit LLVM 21 text IR with an older local clang; never changes the saved artifact",
    )
    args = parser.parse_args()

    case_dir = Path(args.case_dir).resolve()
    semantic_report = (
        Path(args.semantic_report).resolve()
        if args.semantic_report
        else unique_match(case_dir, "*_semantic_report.json")
    )
    if args.artifact:
        artifact = Path(args.artifact).resolve()
    else:
        bc = sorted(case_dir.glob("*_brightened.bc"))
        artifact = bc[0] if len(bc) == 1 else unique_match(case_dir, "*_brightened.ll")
    reference = (
        Path(args.reference).resolve()
        if args.reference
        else unique_match(case_dir, "*_brightened_ref.bin")
    )
    clang = shutil.which(args.clang) or args.clang
    if not Path(clang).exists():
        raise SystemExit(f"compiler not found: {args.clang}")

    source_report = json.loads(semantic_report.read_text(encoding="utf-8"))
    payloads = [base64.b64decode(item) for item in source_report["tested_payloads"]]
    if args.payload_limit:
        payloads = payloads[: args.payload_limit]
    examples = {item["index"]: item for item in source_report.get("mismatch_examples", [])}

    output = {
        "schema": "ollvm-semantic-artifact-replay-v1",
        "case_dir": str(case_dir),
        "source_report_summary": {
            "total_runs": source_report.get("total_runs"),
            "matches": source_report.get("matches"),
            "mismatches": source_report.get("mismatches"),
            "is_fully_equivalent": source_report.get("is_fully_equivalent"),
        },
        "artifacts": {
            "semantic_report": manifest(semantic_report),
            "saved_artifact": manifest(artifact),
            "reference_executable": manifest(reference),
        },
        "compiler": tool_identity(clang),
        "payloads_replayed": len(payloads),
        "matches": 0,
        "mismatches": 0,
        "reference_crash_mismatches": 0,
        "stored_examples_checked": 0,
        "stored_reference_reproduced": 0,
        "stored_prog2_reproduced": 0,
        "mismatch_examples": [],
        "artifact_binding_disagreements": [],
    }

    with tempfile.TemporaryDirectory(prefix="ollvm-semantic-replay-") as temp:
        temp_dir = Path(temp)
        compile_input = artifact
        if args.compat_strip_icmp_samesign:
            if artifact.suffix != ".ll":
                raise SystemExit(
                    "--compat-strip-icmp-samesign requires a text .ll artifact"
                )
            text = artifact.read_text(encoding="utf-8")
            stripped, samesign_count = re.subn(
                r"\bicmp\s+samesign\s+", "icmp ", text
            )
            stripped, captures_count = re.subn(
                r"\s+captures\(none\)", "", stripped
            )
            compile_input = temp_dir / "compat.ll"
            compile_input.write_text(stripped, encoding="utf-8")
            output["compatibility_transform"] = {
                "kind": "strip_llvm21_only_text_attributes_for_older_clang",
                "icmp_samesign_replacements": samesign_count,
                "captures_none_replacements": captures_count,
                "compile_input_sha256": file_sha256(compile_input),
            }
        rebuilt = temp_dir / "saved-artifact.bin"
        command = [str(clang), str(compile_input), "-O2", "-o", str(rebuilt), "-lm"]
        subprocess.run(command, check=True)
        output["compile_command"] = command
        output["artifacts"]["rebuilt_executable"] = manifest(rebuilt)
        output["execution_binding"] = {
            "saved_artifact_sha256": output["artifacts"]["saved_artifact"]["sha256"],
            "rebuilt_executable_sha256": output["artifacts"]["rebuilt_executable"]["sha256"],
            "compiler_sha256": output["compiler"]["sha256"],
        }

        for index, payload in enumerate(payloads):
            example = examples.get(index, {})
            run_args = [str(value) for value in example.get("args", [])]
            ref_run = run_program(reference, payload, run_args, args.timeout)
            rebuilt_run = run_program(rebuilt, payload, run_args, args.timeout)
            same = comparable(ref_run) == comparable(rebuilt_run)
            if same:
                output["matches"] += 1
            else:
                output["mismatches"] += 1
                if ref_run["status"] == "crash" and rebuilt_run["status"] != "crash":
                    output["reference_crash_mismatches"] += 1
                if len(output["mismatch_examples"]) < 20:
                    output["mismatch_examples"].append({
                        "index": index,
                        "payload_b64": base64.b64encode(payload).decode("ascii"),
                        "args": run_args,
                        "reference": ref_run,
                        "rebuilt_saved_artifact": rebuilt_run,
                    })

            if example:
                output["stored_examples_checked"] += 1
                stored_ref = stored_comparable(example.get("prog1"))
                stored_prog2 = stored_comparable(example.get("prog2"))
                replay_ref = comparable(ref_run)
                replay_prog2 = comparable(rebuilt_run)
                if stored_ref == replay_ref:
                    output["stored_reference_reproduced"] += 1
                if stored_prog2 == replay_prog2:
                    output["stored_prog2_reproduced"] += 1
                if stored_prog2 != replay_prog2:
                    output["artifact_binding_disagreements"].append({
                        "index": index,
                        "stored_prog2": example.get("prog2"),
                        "rebuilt_saved_artifact": rebuilt_run,
                    })

    source_mismatches = int(source_report.get("mismatches") or 0)
    if output["mismatches"] == 0 and source_mismatches:
        classification = "reported_prog2_not_reproducible_from_saved_artifact"
    elif (
        output["mismatches"] > 0
        and output["mismatches"] == output["reference_crash_mismatches"]
    ):
        classification = "reference_crash_only_no_valid_domain_counterexample"
    elif output["mismatches"] > 0:
        classification = "semantic_mismatch_reproduced_from_saved_artifact"
    else:
        classification = "saved_artifact_matches_reference_on_replayed_corpus"
    output["classification"] = classification
    output["saved_artifact_fully_matches_reference"] = output["mismatches"] == 0

    encoded = json.dumps(output, indent=2, sort_keys=True) + "\n"
    if args.report:
        Path(args.report).write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    raise SystemExit(
        1 if classification == "semantic_mismatch_reproduced_from_saved_artifact" else 0
    )


if __name__ == "__main__":
    main()
