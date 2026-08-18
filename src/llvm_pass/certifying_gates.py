"""Read-only structural, behavioral and native evidence gates."""

from __future__ import annotations

import base64
import json
import os
import sys
from pathlib import Path
from typing import Any

from llvm_pass.certification import (
    Decision,
    GateResult,
    GateSpec,
    atomic_write_json,
    sha256_file,
)
from llvm_pass.certifying_runtime import (
    SCRIPT_DIR,
    _corpus_sha256,
    _find_tool,
    _read_seed_payloads,
    _run_logged,
)

def make_llvm_verify_gate(timeout: float) -> GateSpec:
    def evaluate(candidate: Path, stage_dir: Path) -> GateResult:
        opt = _find_tool(("opt-21", "opt"))
        if opt is None:
            return GateResult(
                gate_id="llvm_verify",
                decision=Decision.INCONCLUSIVE,
                summary="opt-21/opt not found",
            )
        command = [opt, "-passes=verify", "-disable-output", str(candidate)]
        stdout_path = stage_dir / "gate-llvm-verify.stdout.log"
        stderr_path = stage_dir / "gate-llvm-verify.stderr.log"
        completed = _run_logged(
            command,
            stdout_path=stdout_path,
            stderr_path=stderr_path,
            timeout=timeout,
        )
        if completed is None:
            return GateResult(
                gate_id="llvm_verify",
                decision=Decision.ERROR,
                summary="LLVM verifier could not complete",
                command=command,
                evidence_paths=[str(stdout_path), str(stderr_path)],
            )
        return GateResult(
            gate_id="llvm_verify",
            decision=Decision.PASS if completed.returncode == 0 else Decision.FAIL,
            summary=(
                "LLVM module is well formed"
                if completed.returncode == 0
                else "LLVM verifier rejected the module"
            ),
            command=command,
            returncode=completed.returncode,
            evidence_paths=[str(stdout_path), str(stderr_path)],
        )

    return GateSpec("llvm_verify", evaluate, required=True, blocking=True)


def make_entrypoint_gate(symbol: str, timeout: float) -> GateSpec:
    checker = SCRIPT_DIR / "brighten_100_delift_bundle" / "entrypoint_contract.py"

    def evaluate(candidate: Path, stage_dir: Path) -> GateResult:
        report_path = stage_dir / "gate-entrypoint.json"
        command = [
            sys.executable,
            str(checker),
            str(candidate),
            "--symbol",
            symbol,
            "--timeout",
            str(timeout),
            "--report",
            str(report_path),
        ]
        stdout_path = stage_dir / "gate-entrypoint.stdout.log"
        stderr_path = stage_dir / "gate-entrypoint.stderr.log"
        completed = _run_logged(
            command,
            stdout_path=stdout_path,
            stderr_path=stderr_path,
            timeout=timeout + 5.0,
        )
        if completed is None:
            decision = Decision.ERROR
            summary = "entrypoint checker could not complete"
            returncode = None
        elif completed.returncode == 0:
            decision = Decision.PASS
            summary = f"public definition @{symbol} is preserved"
            returncode = completed.returncode
        elif completed.returncode == 2:
            decision = Decision.FAIL
            summary = f"public definition @{symbol} is missing"
            returncode = completed.returncode
        else:
            decision = Decision.INCONCLUSIVE
            summary = "entrypoint inspection was inconclusive"
            returncode = completed.returncode
        return GateResult(
            gate_id="entrypoint",
            decision=decision,
            summary=summary,
            command=command,
            returncode=returncode,
            evidence_paths=[str(report_path), str(stdout_path), str(stderr_path)],
            metrics={"symbol": symbol},
        )

    return GateSpec("entrypoint", evaluate, required=True, blocking=True)


def make_bundle_link_gate(bundle_binary: Path) -> GateSpec:
    def evaluate(_candidate: Path, stage_dir: Path) -> GateResult:
        exists = bundle_binary.is_file() and bundle_binary.stat().st_size > 0
        executable = exists and os.access(bundle_binary, os.X_OK)
        elf_magic = False
        if exists:
            try:
                with bundle_binary.open("rb") as handle:
                    elf_magic = handle.read(4) == b"\x7fELF"
            except OSError:
                elf_magic = False
        passed = bool(exists and executable and elf_magic)
        binary_hash = sha256_file(bundle_binary) if exists else None
        report_path = stage_dir / "gate-bundle-link.json"
        payload = {
            "decision": "pass" if passed else "fail",
            "binary": str(bundle_binary),
            "binary_size": bundle_binary.stat().st_size if exists else 0,
            "binary_sha256": binary_hash,
            "is_executable": executable,
            "has_elf_magic": elf_magic,
        }
        atomic_write_json(report_path, payload)
        return GateResult(
            gate_id="bundle_link",
            decision=Decision.PASS if passed else Decision.FAIL,
            summary=(
                "bundle produced a non-empty executable ELF"
                if passed
                else "bundle did not produce a non-empty executable ELF"
            ),
            evidence_paths=[str(bundle_binary), str(report_path)],
            metrics={
                "binary_size": payload["binary_size"],
                "binary_sha256": binary_hash,
                "is_executable": executable,
                "has_elf_magic": elf_magic,
            },
        )

    return GateSpec("bundle_link", evaluate, required=True, blocking=True)


def make_behavior_gate(
    *,
    bundle_binary: Path,
    reference: Path,
    iterations: int,
    execution_timeout: float,
    jobs: int,
    seed_dir: Path | None,
    seed_files: list[Path],
    domain_contract: dict[str, Any] | None,
    corpus_seed: int,
) -> GateSpec:
    def evaluate(_candidate: Path, stage_dir: Path) -> GateResult:
        from fuzzing_equi_check.fuzzing import SemanticFuzzer, make_bytes_generator
        from fuzzing_equi_check.input_contracts import (
            generate_contract_inputs,
            validate_contract_payload,
        )

        report_path = stage_dir / "gate-behavior.json"
        corpus_path = stage_dir / "gate-behavior-corpus.json"
        bundle_report_path = stage_dir / "gate-bundle-link.json"
        if domain_contract is None:
            atomic_write_json(
                report_path,
                {
                    "decision": "inconclusive",
                    "reason": "no frozen valid-input contract was supplied",
                },
            )
            return GateResult(
                gate_id="behavior",
                decision=Decision.INCONCLUSIVE,
                summary="no frozen valid-input contract; random bytes cannot certify semantics",
                evidence_paths=[str(report_path)],
            )

        try:
            with bundle_report_path.open("r", encoding="utf-8") as handle:
                expected_bundle_hash = json.load(handle).get("binary_sha256")
        except (OSError, ValueError, AttributeError):
            expected_bundle_hash = None
        current_bundle_hash = sha256_file(bundle_binary)
        if not expected_bundle_hash or current_bundle_hash != expected_bundle_hash:
            atomic_write_json(
                report_path,
                {
                    "decision": "error",
                    "reason": "bundle bytes changed after the bundle-link gate",
                    "expected_sha256": expected_bundle_hash,
                    "observed_sha256": current_bundle_hash,
                },
            )
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary="bundle bytes changed before differential execution",
                evidence_paths=[str(report_path), str(bundle_report_path)],
            )

        try:
            seed_payloads, seed_sources = _read_seed_payloads(seed_files, seed_dir)
            corpus, corpus_stats = generate_contract_inputs(
                domain_contract,
                seed_payloads,
                iterations,
                rng_seed=corpus_seed,
            )
            invalid_payloads = [
                {"index": index, "reason": reason}
                for index, payload in enumerate(corpus)
                for valid, reason in [
                    validate_contract_payload(domain_contract, payload, seed_payloads)
                ]
                if not valid
            ]
            if invalid_payloads:
                raise ValueError(
                    "valid-input generator emitted payloads outside the frozen "
                    f"contract: {invalid_payloads[:3]}"
                )
            corpus_hash = _corpus_sha256(corpus)
            atomic_write_json(
                corpus_path,
                {
                    "schema_version": 1,
                    "rng_seed": corpus_seed,
                    "requested_inputs": iterations,
                    "generated_inputs": len(corpus),
                    "generation_stats": corpus_stats,
                    "seed_sources": seed_sources,
                    "seed_payloads_base64": [
                        base64.b64encode(payload).decode("ascii")
                        for payload in seed_payloads
                    ],
                    "corpus_sha256": corpus_hash,
                    "payloads_base64": [
                        base64.b64encode(payload).decode("ascii") for payload in corpus
                    ],
                },
            )
        except Exception as exc:
            atomic_write_json(
                report_path,
                {
                    "decision": "error",
                    "phase": "corpus_generation",
                    "exception": type(exc).__name__,
                    "message": str(exc),
                },
            )
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary=f"could not build the frozen valid-input corpus: {exc}",
                evidence_paths=[str(report_path), str(corpus_path)],
            )

        if len(corpus) != iterations:
            atomic_write_json(
                report_path,
                {
                    "decision": "inconclusive",
                    "reason": "valid-input generator could not fill the frozen corpus",
                    "requested_inputs": iterations,
                    "generated_inputs": len(corpus),
                    "corpus_sha256": corpus_hash,
                },
            )
            return GateResult(
                gate_id="behavior",
                decision=Decision.INCONCLUSIVE,
                summary=(
                    "valid-input generator produced only "
                    f"{len(corpus)}/{iterations} unique inputs"
                ),
                evidence_paths=[str(report_path), str(corpus_path)],
                metrics={
                    "requested_runs": iterations,
                    "generated_inputs": len(corpus),
                    "corpus_seed": corpus_seed,
                    "corpus_sha256": corpus_hash,
                    "binary_sha256": current_bundle_hash,
                },
            )

        expected_reference_hash = sha256_file(reference)
        if expected_reference_hash is None:
            atomic_write_json(
                report_path,
                {
                    "decision": "error",
                    "reason": "reference binary is missing before differential execution",
                },
            )
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary="reference binary is missing before differential execution",
                evidence_paths=[str(report_path), str(corpus_path)],
            )

        fuzzer = SemanticFuzzer(
            str(bundle_binary),
            str(reference),
            seed_inputs=corpus,
            input_contract=domain_contract,
        )
        report: dict[str, Any]
        compiled_candidate_hash: str | None = None
        compiled_reference_hash: str | None = None
        try:
            compiled_candidate, compiled_reference = fuzzer.compile()
            compiled_candidate_hash = sha256_file(compiled_candidate)
            compiled_reference_hash = sha256_file(compiled_reference)
            if compiled_candidate_hash != current_bundle_hash:
                raise RuntimeError(
                    "compiled candidate copy does not match the bundle-link hash"
                )
            if compiled_reference_hash != expected_reference_hash:
                raise RuntimeError(
                    "compiled reference copy does not match the frozen reference hash"
                )

            # ``run_differential_test_fallback`` normally regenerates inputs
            # when ``input_contract`` is present.  Certification has already
            # generated, validated, persisted and hashed the corpus, so disable
            # that internal generation step and replay these exact bytes only.
            fuzzer.input_contract = None
            report = fuzzer.run_differential_test_fallback(
                iterations=iterations,
                generator=make_bytes_generator(),
                timeout=execution_timeout,
                compare_stderr=True,
                num_workers=jobs,
                seed_inputs=corpus,
                strict_oracle=True,
            )
        except Exception as exc:
            atomic_write_json(
                report_path,
                {
                    "decision": "error",
                    "exception": type(exc).__name__,
                    "message": str(exc),
                },
            )
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary=f"differential execution failed: {exc}",
                evidence_paths=[str(report_path), str(corpus_path)],
            )
        finally:
            fuzzer.cleanup()

        bundle_hash_after = sha256_file(bundle_binary)
        reference_hash_after = sha256_file(reference)
        if (
            bundle_hash_after != current_bundle_hash
            or reference_hash_after != expected_reference_hash
        ):
            report["certification_error"] = {
                "reason": "program bytes changed during differential execution",
                "candidate_sha256_before": current_bundle_hash,
                "candidate_sha256_after": bundle_hash_after,
                "reference_sha256_before": expected_reference_hash,
                "reference_sha256_after": reference_hash_after,
            }
            atomic_write_json(report_path, report)
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary="program bytes changed during differential execution",
                evidence_paths=[str(report_path), str(corpus_path)],
                metrics=report["certification_error"],
            )

        try:
            tested_payloads = [
                base64.b64decode(item.encode("ascii"), validate=True)
                for item in report.get("tested_payloads", [])
            ]
        except (AttributeError, TypeError, ValueError) as exc:
            report["certification_error"] = {
                "reason": "behavior report contains an invalid tested corpus",
                "message": str(exc),
            }
            atomic_write_json(report_path, report)
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary="behavior report contains an invalid tested corpus",
                evidence_paths=[str(report_path), str(corpus_path)],
            )
        replayed_corpus_hash = _corpus_sha256(tested_payloads)
        if tested_payloads != corpus or replayed_corpus_hash != corpus_hash:
            report["certification_error"] = {
                "reason": "differential execution did not replay the frozen corpus exactly",
                "expected_count": len(corpus),
                "observed_count": len(tested_payloads),
                "expected_sha256": corpus_hash,
                "observed_sha256": replayed_corpus_hash,
            }
            atomic_write_json(report_path, report)
            return GateResult(
                gate_id="behavior",
                decision=Decision.ERROR,
                summary="differential execution did not replay the frozen corpus exactly",
                evidence_paths=[str(report_path), str(corpus_path)],
                metrics=report["certification_error"],
            )

        report["certification_corpus"] = {
            "path": str(corpus_path),
            "rng_seed": corpus_seed,
            "sha256": corpus_hash,
            "replayed_sha256": replayed_corpus_hash,
            "input_count": len(corpus),
        }
        report["tested_programs"] = {
            "candidate_sha256": current_bundle_hash,
            "reference_sha256": expected_reference_hash,
            "compiled_candidate_sha256": compiled_candidate_hash,
            "compiled_reference_sha256": compiled_reference_hash,
        }
        atomic_write_json(report_path, report)

        total = int(report.get("total_runs", 0))
        matches = int(report.get("matches", 0))
        mismatches = int(report.get("mismatches", 0))
        inconclusive = int(report.get("inconclusive", 0))
        confirmed = int(report.get("confirmed_runs", 0))
        fully_equivalent = bool(report.get("is_fully_equivalent", False))
        metrics = {
            "requested_runs": iterations,
            "total_runs": total,
            "matches": matches,
            "mismatches": mismatches,
            "inconclusive": inconclusive,
            "confirmed_runs": confirmed,
            "corpus_seed": corpus_seed,
            "corpus_sha256": corpus_hash,
            "binary_sha256": current_bundle_hash,
            "reference_sha256": expected_reference_hash,
        }
        if mismatches > 0:
            decision = Decision.FAIL
            summary = f"behavioral divergence found on {mismatches} registered input(s)"
        elif (
            inconclusive > 0
            or total != iterations
            or confirmed != iterations
            or matches != iterations
        ):
            decision = Decision.INCONCLUSIVE
            summary = (
                "behavioral gate did not obtain one exact match for every "
                f"registered input: total={total}, confirmed={confirmed}, "
                f"matches={matches}, expected={iterations}, "
                f"inconclusive={inconclusive}"
            )
        elif fully_equivalent:
            decision = Decision.PASS
            summary = f"no divergence found on all {iterations} registered inputs"
        else:
            decision = Decision.INCONCLUSIVE
            summary = "behavioral report did not satisfy the strict pass predicate"
        return GateResult(
            gate_id="behavior",
            decision=decision,
            summary=summary,
            evidence_paths=[str(report_path), str(corpus_path)],
            metrics=metrics,
        )

    # Continue collecting native evidence after a behavioral failure so the
    # report can distinguish semantic, structural and native-delifting causes.
    return GateSpec("behavior", evaluate, required=True, blocking=False)


def make_native_contract_gate() -> GateSpec:
    def evaluate(candidate: Path, _stage_dir: Path) -> GateResult:
        from llvm_pass.britening_ir import (
            native_contract_report_path,
            read_native_contract_report,
            verify_native_contract,
        )

        passed = verify_native_contract(str(candidate))
        report = read_native_contract_report(str(candidate))
        evidence = [native_contract_report_path(str(candidate))]
        if passed:
            return GateResult(
                gate_id="native_contract",
                decision=Decision.PASS,
                summary="final IR satisfies the strict fully-native contract",
                evidence_paths=evidence,
                metrics=(report or {}).get("metrics", {}),
            )
        if report and report.get("status") == "non_compliant":
            return GateResult(
                gate_id="native_contract",
                decision=Decision.FAIL,
                summary="final IR remains compatibility-class, not fully native",
                evidence_paths=evidence,
                metrics=report.get("metrics", {}),
            )
        return GateResult(
            gate_id="native_contract",
            decision=Decision.INCONCLUSIVE,
            summary="native-contract verifier or plugin was unavailable",
            evidence_paths=evidence,
            metrics=(report or {}).get("metrics", {}),
        )

    return GateSpec("native_contract", evaluate, required=True, blocking=False)


def make_native_compile_gate(timeout: float) -> GateSpec:
    def evaluate(candidate: Path, stage_dir: Path) -> GateResult:
        clang = _find_tool(("clang-21", "clang"))
        if clang is None:
            return GateResult(
                gate_id="native_compile",
                decision=Decision.INCONCLUSIVE,
                summary="clang-21/clang not found",
            )
        output = stage_dir / "native-independent.bin"
        try:
            output.unlink()
        except FileNotFoundError:
            pass
        command = [clang, "-O2", str(candidate), "-lm", "-o", str(output)]
        stdout_path = stage_dir / "gate-native-compile.stdout.log"
        stderr_path = stage_dir / "gate-native-compile.stderr.log"
        completed = _run_logged(
            command,
            stdout_path=stdout_path,
            stderr_path=stderr_path,
            timeout=timeout,
        )
        if completed is None:
            return GateResult(
                gate_id="native_compile",
                decision=Decision.ERROR,
                summary="independent native compilation could not complete",
                command=command,
                evidence_paths=[str(stdout_path), str(stderr_path)],
            )
        passed = completed.returncode == 0 and output.is_file()
        return GateResult(
            gate_id="native_compile",
            decision=Decision.PASS if passed else Decision.FAIL,
            summary=(
                "final IR links without the McSema compatibility runtime"
                if passed
                else "final IR does not independently link as a native executable"
            ),
            command=command,
            returncode=completed.returncode,
            evidence_paths=[str(output), str(stdout_path), str(stderr_path)],
            metrics={
                "binary_size": output.stat().st_size if output.is_file() else 0,
                "binary_sha256": sha256_file(output),
            },
        )

    return GateSpec("native_compile", evaluate, required=True, blocking=False)

