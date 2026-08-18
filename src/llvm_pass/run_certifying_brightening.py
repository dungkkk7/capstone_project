#!/usr/bin/env python3
"""Run McSema brightening under a fail-closed certification protocol.

The runner separates candidate generation from authority.  It never claims that
all lifted programs are recoverable.  It guarantees that an artifact receives
the ``certified`` suffix only when every gate frozen by protocol v1 passes on
the exact bytes that are published.
"""

from __future__ import annotations

import argparse
import json
import platform
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SRC_ROOT = SCRIPT_DIR.parent
PROJECT_ROOT = SRC_ROOT.parent
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from llvm_pass.certification import (
    OutputClass,
    TransactionalPipeline,
    sha256_file,
)
from llvm_pass.certifying_gates import (
    make_behavior_gate,
    make_bundle_link_gate,
    make_entrypoint_gate,
    make_llvm_verify_gate,
    make_native_compile_gate,
    make_native_contract_gate,
)
from llvm_pass.certifying_runtime import (
    _brightening_snapshot,
    _corpus_sha256,
    _environment_snapshot,
    _find_tool,
    _git_snapshot,
    _load_domain_contract,
    _load_protocol,
    _read_seed_payloads,
    _seed_manifest,
    _tool_version,
    make_brighten_action,
    make_finalize_action,
)

def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run brightening/delifting with transactional certification."
    )
    parser.add_argument("--input", required=True, help="raw McSema LLVM IR/bitcode")
    parser.add_argument("--reference", required=True, help="original reference ELF")
    parser.add_argument("--output-prefix", required=True, help="destination prefix")
    parser.add_argument("--workdir", help="persistent root for run evidence")
    parser.add_argument("--seed-dir")
    parser.add_argument("--seed-file", action="append", default=[])
    parser.add_argument("--domain-contract", help="frozen valid-input contract JSON")
    parser.add_argument("--iterations", type=int, default=1000)
    parser.add_argument(
        "--corpus-seed",
        type=int,
        default=0xC0FFEE,
        help="deterministic seed for the frozen valid-input corpus",
    )
    parser.add_argument("--execution-timeout", type=float, default=0.15)
    parser.add_argument("--gate-timeout", type=float, default=180.0)
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--entrypoint", default="main")
    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()

    input_path = Path(args.input).resolve()
    reference = Path(args.reference).resolve()
    output_prefix = Path(args.output_prefix).resolve()
    if not input_path.is_file():
        parser.error(f"input does not exist: {input_path}")
    if not reference.is_file():
        parser.error(f"reference does not exist: {reference}")
    if args.iterations <= 0:
        parser.error("--iterations must be positive")
    if args.jobs <= 0:
        parser.error("--jobs must be positive")
    if args.execution_timeout <= 0 or args.gate_timeout <= 0:
        parser.error("timeouts must be positive")

    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    workdir_root = (
        Path(args.workdir).resolve()
        if args.workdir
        else Path(f"{output_prefix}.cert-work")
    )
    report_path = Path(f"{output_prefix}.certification.json")
    seed_dir = Path(args.seed_dir).resolve() if args.seed_dir else None
    seed_files = [Path(path).resolve() for path in args.seed_file]
    domain_contract_path = (
        Path(args.domain_contract).resolve() if args.domain_contract else None
    )
    try:
        seeds = _seed_manifest(seed_files, seed_dir)
        domain_contract = _load_domain_contract(domain_contract_path)
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    if domain_contract_path is not None and not domain_contract_path.is_file():
        parser.error(f"domain contract does not exist: {domain_contract_path}")

    protocol_path = PROJECT_ROOT / "configs" / "certification_protocol_v1.json"
    if not protocol_path.is_file():
        parser.error(f"frozen certification protocol is missing: {protocol_path}")
    try:
        policy, protocol_payload = _load_protocol(protocol_path)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        parser.error(f"invalid certification protocol: {exc}")

    opt = _find_tool(("opt-21", "opt"))
    clang = _find_tool(("clang-21", "clang"))
    llvm_nm = _find_tool(("llvm-nm-21", "llvm-nm"))
    metadata = {
        "python": sys.version.split()[0],
        "platform": platform.platform(),
        "git": _git_snapshot(PROJECT_ROOT),
        "brightening": _brightening_snapshot(),
        "environment": _environment_snapshot(),
        "protocol": {
            "path": str(protocol_path),
            "sha256": sha256_file(protocol_path),
            "payload": protocol_payload,
        },
        "tools": {
            "opt": {"path": opt, "version": _tool_version(opt)},
            "clang": {"path": clang, "version": _tool_version(clang)},
            "llvm_nm": {"path": llvm_nm, "version": _tool_version(llvm_nm)},
        },
        "behavior": {
            "engine": "deterministic_contract_corpus",
            "iterations": args.iterations,
            "execution_timeout": args.execution_timeout,
            "jobs": args.jobs,
            "strict_oracle": True,
            "compare_stderr": True,
            "corpus_seed": args.corpus_seed,
            "seed_dir": str(seed_dir) if seed_dir else None,
            "seed_manifest": seeds,
            "domain_contract": (
                str(domain_contract_path) if domain_contract_path else None
            ),
            "domain_contract_sha256": (
                sha256_file(domain_contract_path) if domain_contract_path else None
            ),
        },
    }
    pipeline = TransactionalPipeline(
        input_artifact=input_path,
        reference_artifact=reference,
        workdir=workdir_root,
        report_path=report_path,
        policy=policy,
        metadata=metadata,
    )

    brightened = pipeline.workdir / "01-brightened.ll"
    stage1 = pipeline.run_stage(
        stage_id="01-brighten",
        candidate_artifact=brightened,
        action=make_brighten_action(reference),
        gates=[make_llvm_verify_gate(args.gate_timeout)],
    )
    if not stage1.accepted:
        print(json.dumps(pipeline.report.as_dict(), indent=2, sort_keys=True))
        return 2

    final_candidate = pipeline.workdir / "02-final-candidate.ll"
    final_prefix = pipeline.workdir / "02-finalize" / "final"
    bundle_binary = final_prefix.with_suffix(".bin")
    stage2 = pipeline.run_stage(
        stage_id="02-finalize",
        candidate_artifact=final_candidate,
        action=make_finalize_action(final_prefix),
        gates=[
            make_llvm_verify_gate(args.gate_timeout),
            make_entrypoint_gate(args.entrypoint, args.gate_timeout),
            make_bundle_link_gate(bundle_binary),
            make_behavior_gate(
                bundle_binary=bundle_binary,
                reference=reference,
                iterations=args.iterations,
                execution_timeout=args.execution_timeout,
                jobs=args.jobs,
                seed_dir=seed_dir,
                seed_files=seed_files,
                domain_contract=domain_contract,
                corpus_seed=args.corpus_seed,
            ),
            make_native_contract_gate(),
            make_native_compile_gate(args.gate_timeout),
        ],
    )

    output_class = pipeline.report.output_class
    suffix = {
        OutputClass.CERTIFIED: "certified",
        OutputClass.VALIDATED_COMPAT: "validated-compat",
        OutputClass.EVIDENCE_ONLY: "evidence",
        OutputClass.REJECTED: "rejected",
    }[output_class]
    if output_class != OutputClass.REJECTED and final_candidate.is_file():
        publish_binary = output_class in {
            OutputClass.CERTIFIED,
            OutputClass.VALIDATED_COMPAT,
        }
        bundle_gate = next(
            (gate for gate in stage2.gates if gate.gate_id == "bundle_link"), None
        )
        expected_binary_hash = (
            bundle_gate.metrics.get("binary_sha256") if bundle_gate else None
        )
        if publish_binary and not expected_binary_hash:
            raise RuntimeError("bundle-link gate did not record the tested binary hash")

        pipeline.publish(
            artifact_destination=Path(f"{output_prefix}.{suffix}.ll"),
            binary_source=bundle_binary if publish_binary else None,
            binary_destination=(
                Path(f"{output_prefix}.{suffix}.bin") if publish_binary else None
            ),
            expected_binary_sha256=expected_binary_hash,
            allowed_classes=(
                OutputClass.CERTIFIED,
                OutputClass.VALIDATED_COMPAT,
                OutputClass.EVIDENCE_ONLY,
            ),
        )

    summary = {
        "output_class": output_class.value,
        "report": str(report_path),
        "evidence_directory": pipeline.report.evidence_directory,
        "last_accepted_artifact": pipeline.report.last_accepted_artifact,
        "final_candidate": pipeline.report.final_candidate,
        "published_artifact": pipeline.report.published_artifact,
        "published_binary": pipeline.report.published_binary,
        "final_stage_accepted": stage2.accepted,
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0 if output_class == OutputClass.CERTIFIED else 2


if __name__ == "__main__":
    raise SystemExit(main())
