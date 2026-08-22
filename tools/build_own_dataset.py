#!/usr/bin/env python3
"""Freeze, verify, and build the 40-case repository-owned dataset."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_ROOT = ROOT / "custom_dataset"
CSV_PATH = DATA_ROOT / "dataset.csv"
MANIFEST_PATH = DATA_ROOT / "manifest.json"
BUILD_MANIFEST_PATH = DATA_ROOT / "build_manifest.json"
PLUGIN_ROOT = ROOT / "tools" / "own_obfuscator"
DEFAULT_PLUGIN = PLUGIN_ROOT / "build" / "libOwnObfuscator.so"
PASS_PIPELINE = "function(reg2mem,own-instsub,own-fla,own-bcf),verify"

CATEGORIES = {
    "parsing_state_machine": ["h00004", "h00009", "h00014", "h00017", "h00021"],
    "numeric_bitwise": ["h00002", "h00011", "h00012", "h00013", "h00022"],
    "arrays_windows": ["h00003", "h00010", "h00019", "h00020", "h00023"],
    "strings_encodings": ["h00001", "h00005", "h00007", "h00008", "h00024"],
    "structural_control_flow": ["h00006", "h00015", "h00016", "h00018", "h00025"],
    "graph_algorithms": ["h00026", "h00027", "h00028", "h00029", "h00030"],
    "data_structures": ["h00031", "h00032", "h00033", "h00034", "h00035"],
    "checksums_formats": ["h00036", "h00037", "h00038", "h00039", "h00040"],
}


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def command_version(command: str) -> str:
    result = subprocess.run(
        [command, "--version"], capture_output=True, text=True, timeout=20, check=False
    )
    lines = (result.stdout or result.stderr or "").splitlines()
    return lines[0] if lines else f"exit={result.returncode}"


def run(command: list[str], *, timeout: int = 120) -> subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError as error:
        raise SystemExit(f"missing required tool: {command[0]}") from error


def require_success(result: subprocess.CompletedProcess[bytes], label: str) -> None:
    if result.returncode:
        diagnostics = result.stderr.decode(errors="replace")
        raise SystemExit(f"{label} failed (exit={result.returncode}):\n{diagnostics}")


def category_for(case_id: str) -> str:
    matches = [name for name, members in CATEGORIES.items() if case_id in members]
    if len(matches) != 1:
        raise SystemExit(f"case must belong to exactly one category: {case_id}")
    return matches[0]


def discover_cases() -> list[dict[str, str]]:
    sources = sorted(
        (DATA_ROOT / "clean_src").glob("h[0-9][0-9][0-9][0-9][0-9]/*.c")
    )
    if len(sources) != 40:
        raise SystemExit(f"own_dataset must contain exactly 40 C sources, found {len(sources)}")
    discovered = []
    for source in sources:
        case_id = source.parent.name
        submission_id = source.stem
        seed = DATA_ROOT / "seeds" / case_id / f"{case_id}_seed.txt"
        if not seed.is_file():
            raise SystemExit(f"missing seed: {seed}")
        discovered.append(
            {
                "case_id": case_id,
                "submission_id": submission_id,
                "category": category_for(case_id),
                "source": str(source.relative_to(DATA_ROOT)),
                "seed": str(seed.relative_to(DATA_ROOT)),
            }
        )
    if len({case["submission_id"] for case in discovered}) != 40:
        raise SystemExit("submission IDs must be unique")
    return discovered


def compile_plain(case: dict[str, str], compiler: str, output: Path) -> list[str]:
    source = DATA_ROOT / case["source"]
    command = [
        compiler,
        "-std=c11",
        "-O2",
        "-Wall",
        "-Wextra",
        "-Werror",
        str(source),
        "-o",
        str(output),
    ]
    require_success(run(command), f"plain compile {case['case_id']}")
    return command


def execute_oracle(binary: Path, seed: Path) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        [str(binary)], input=seed.read_bytes(), capture_output=True, timeout=10, check=False
    )


def refresh_manifest(compiler: str) -> dict:
    cases = discover_cases()
    with tempfile.TemporaryDirectory(prefix="own-dataset-freeze-") as temporary:
        temporary_root = Path(temporary)
        for case in cases:
            source = DATA_ROOT / case["source"]
            seed = DATA_ROOT / case["seed"]
            plain = temporary_root / case["case_id"]
            compile_plain(case, compiler, plain)
            oracle = execute_oracle(plain, seed)
            if oracle.returncode != 0 or oracle.stderr:
                raise SystemExit(
                    f"seed oracle failed for {case['case_id']}: "
                    f"exit={oracle.returncode}, stderr={oracle.stderr!r}"
                )
            try:
                expected = oracle.stdout.decode("utf-8")
            except UnicodeDecodeError as error:
                raise SystemExit(f"oracle output is not UTF-8: {case['case_id']}") from error
            case.update(
                {
                    "source_sha256": digest(source),
                    "seed_sha256": digest(seed),
                    "expected_stdout": expected,
                }
            )

    document = {
        "schema_version": 2,
        "dataset_id": "own-dataset-v1-20260815",
        "created_at": "2026-08-15T20:00:00+07:00",
        "freeze_state": "FROZEN_BEFORE_FIRST_RECOVERY_MODEL_CALL",
        "provenance": {
            "public_benchmark_source": False,
            "authored_case_count": 40,
            "authoring": "new exact C11 program instances created for this repository with Codex assistance",
            "copied_from": [],
            "model_prompt_access": "recovery models receive only binary-derived evidence, never source, seed, manifest, or oracle",
            "claim_boundary": "mitigates exact-source memorization; does not prove zero exposure to component algorithms",
        },
        "obfuscation": {
            "kind": "repository-owned OLLVM-style LLVM 21 pass plugin",
            "passes": ["own-instsub", "own-fla", "own-bcf"],
            "pipeline": PASS_PIPELINE,
            "source": "tools/own_obfuscator/OwnObfuscator.cpp",
        },
        "categories": CATEGORIES,
        "cases": cases,
    }
    temporary = MANIFEST_PATH.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, MANIFEST_PATH)

    with CSV_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            [
                "submission_id",
                "token_count",
                "file_size_bytes",
                "clean_source",
                "obfuscated_binary",
                "dataset_split",
            ]
        )
        for case in cases:
            writer.writerow(
                [
                    case["submission_id"],
                    "",
                    "",
                    f"custom_dataset/{case['source']}",
                    "custom_dataset/obfuscated/"
                    f"{case['case_id']}/{case['submission_id']}_fla_bcf_instsub.elf",
                    "own_v1",
                ]
            )
    return document


def ensure_plugin(plugin: Path, llvm_dir: str) -> None:
    plugin_inputs = [PLUGIN_ROOT / "OwnObfuscator.cpp", PLUGIN_ROOT / "CMakeLists.txt"]
    if plugin.is_file() and all(
        source.stat().st_mtime_ns <= plugin.stat().st_mtime_ns for source in plugin_inputs
    ):
        return
    build = plugin.parent
    if not (build / "CMakeCache.txt").is_file():
        configure = [
            "cmake",
            "-S",
            str(PLUGIN_ROOT),
            "-B",
            str(build),
            "-G",
            "Ninja",
            f"-DLLVM_DIR={llvm_dir}",
            "-DCMAKE_BUILD_TYPE=Release",
        ]
        require_success(run(configure, timeout=300), "configure own obfuscator")
    require_success(
        run(["cmake", "--build", str(build), "--parallel", "2"], timeout=600),
        "build own obfuscator",
    )
    if not plugin.is_file():
        raise SystemExit(f"plugin build succeeded but output is missing: {plugin}")


def build_obfuscated(
    case: dict[str, str],
    *,
    compiler: str,
    opt: str,
    llvm_dis: str,
    plugin: Path,
    temporary_root: Path,
) -> tuple[Path, dict[str, object]]:
    source = DATA_ROOT / case["source"]
    raw_bc = temporary_root / f"{case['case_id']}.raw.bc"
    obfuscated_bc = temporary_root / f"{case['case_id']}.obf.bc"
    obfuscated_ll = temporary_root / f"{case['case_id']}.obf.ll"
    linked = temporary_root / f"{case['case_id']}.obf.elf"

    compile_ir = [
        compiler,
        "-std=c11",
        "-O0",
        "-Xclang",
        "-disable-O0-optnone",
        "-fno-discard-value-names",
        "-emit-llvm",
        "-c",
        str(source),
        "-o",
        str(raw_bc),
    ]
    obfuscate = [
        opt,
        "-load-pass-plugin",
        str(plugin),
        f"-passes={PASS_PIPELINE}",
        str(raw_bc),
        "-o",
        str(obfuscated_bc),
    ]
    disassemble = [llvm_dis, str(obfuscated_bc), "-o", str(obfuscated_ll)]
    link = [compiler, "-O0", "-no-pie", str(obfuscated_bc), "-o", str(linked)]
    require_success(run(compile_ir), f"IR compile {case['case_id']}")
    require_success(run(obfuscate), f"obfuscation {case['case_id']}")
    require_success(run(disassemble), f"IR disassembly {case['case_id']}")
    ir = obfuscated_ll.read_text(encoding="utf-8", errors="replace")
    markers = {
        "instsub": ir.count("own.instsub"),
        "fla": ir.count("own.fla"),
        "bcf": ir.count("own.bcf"),
    }
    if any(count == 0 for count in markers.values()):
        raise SystemExit(f"missing obfuscation marker for {case['case_id']}: {markers}")
    require_success(run(link), f"ELF link {case['case_id']}")
    if linked.read_bytes()[:4] != b"\x7fELF":
        raise SystemExit(f"not an ELF output: {case['case_id']}")
    return linked, {
        "compile_ir_command": compile_ir,
        "obfuscation_command": obfuscate,
        "link_command": link,
        "marker_counts": markers,
        "obfuscated_bitcode_sha256": digest(obfuscated_bc),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", default="clang-21")
    parser.add_argument("--opt", default="opt-21")
    parser.add_argument("--llvm-dis", default="llvm-dis-21")
    parser.add_argument("--plugin", type=Path, default=DEFAULT_PLUGIN)
    parser.add_argument("--llvm-dir", default="/usr/lib/llvm-21/lib/cmake/llvm")
    parser.add_argument("--plain-only", action="store_true")
    parser.add_argument(
        "--refresh-manifest",
        action="store_true",
        help="Re-freeze hashes/oracles/CSV before any recovery-model call",
    )
    args = parser.parse_args()

    document = refresh_manifest(args.compiler) if args.refresh_manifest else json.loads(
        MANIFEST_PATH.read_text(encoding="utf-8")
    )
    cases = document["cases"]
    if len(cases) != 40:
        raise SystemExit(f"own_dataset must contain exactly 40 cases, found {len(cases)}")
    if set(document["categories"]) != set(CATEGORIES):
        raise SystemExit("category taxonomy drift")

    plugin = args.plugin.resolve()
    if not args.plain_only:
        ensure_plugin(plugin, args.llvm_dir)

    build_records = []
    with tempfile.TemporaryDirectory(prefix="own-dataset-build-") as temporary:
        temporary_root = Path(temporary)
        for case in cases:
            source = DATA_ROOT / case["source"]
            seed = DATA_ROOT / case["seed"]
            if digest(source) != case["source_sha256"]:
                raise SystemExit(f"source hash drift: {case['case_id']}")
            if digest(seed) != case["seed_sha256"]:
                raise SystemExit(f"seed hash drift: {case['case_id']}")

            plain = temporary_root / f"{case['case_id']}.plain"
            plain_command = compile_plain(case, args.compiler, plain)
            oracle = execute_oracle(plain, seed)
            if (
                oracle.returncode != 0
                or oracle.stderr
                or oracle.stdout.decode("utf-8") != case["expected_stdout"]
            ):
                raise SystemExit(f"frozen plain oracle mismatch: {case['case_id']}")
            record: dict[str, object] = {
                "case_id": case["case_id"],
                "plain_command": plain_command,
                "plain_binary_sha256": digest(plain),
                "oracle_verified": True,
            }

            if not args.plain_only:
                linked, obfuscation_record = build_obfuscated(
                    case,
                    compiler=args.compiler,
                    opt=args.opt,
                    llvm_dis=args.llvm_dis,
                    plugin=plugin,
                    temporary_root=temporary_root,
                )
                obfuscated_oracle = execute_oracle(linked, seed)
                if (
                    obfuscated_oracle.returncode != oracle.returncode
                    or obfuscated_oracle.stdout != oracle.stdout
                    or obfuscated_oracle.stderr != oracle.stderr
                ):
                    raise SystemExit(f"obfuscated semantic mismatch: {case['case_id']}")
                if digest(linked) == digest(plain):
                    raise SystemExit(f"obfuscated binary equals plain binary: {case['case_id']}")
                output = DATA_ROOT / "obfuscated" / case["case_id"] / (
                    case["submission_id"] + "_fla_bcf_instsub.elf"
                )
                output.parent.mkdir(parents=True, exist_ok=True)
                pending = output.with_suffix(output.suffix + ".tmp")
                shutil.copy2(linked, pending)
                os.replace(pending, output)
                record.update(obfuscation_record)
                record.update(
                    {
                        "obfuscated_binary": str(output.relative_to(ROOT)),
                        "obfuscated_binary_sha256": digest(output),
                        "obfuscated_size_bytes": output.stat().st_size,
                    }
                )
            build_records.append(record)

    result = {
        "schema_version": 1,
        "dataset_id": document["dataset_id"],
        "dataset_manifest_sha256": digest(MANIFEST_PATH),
        "dataset_csv_sha256": digest(CSV_PATH),
        "input_contract_sha256": digest(
            DATA_ROOT / "input_contracts" / "dataset.json"
        ),
        "builder_sha256": digest(Path(__file__).resolve()),
        "compiler": args.compiler,
        "compiler_version": command_version(args.compiler),
        "opt": args.opt,
        "opt_version": command_version(args.opt),
        "plugin": str(plugin),
        "plugin_sha256": digest(plugin) if plugin.is_file() else None,
        "plugin_source_sha256": digest(PLUGIN_ROOT / "OwnObfuscator.cpp"),
        "plugin_cmake_sha256": digest(PLUGIN_ROOT / "CMakeLists.txt"),
        "pass_pipeline": PASS_PIPELINE,
        "plain_only": args.plain_only,
        "cases": build_records,
    }
    if not args.plain_only:
        output = BUILD_MANIFEST_PATH
        pending = output.with_suffix(".json.tmp")
        pending.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        os.replace(pending, output)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
