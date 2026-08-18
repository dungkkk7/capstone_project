from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = PROJECT_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from llvm_pass.run_certifying_brightening import (  # noqa: E402
    _clear_stale_publications,
    _publication_targets,
)


def test_publication_targets_cover_every_authority_alias(tmp_path: Path) -> None:
    prefix = tmp_path / "case"
    assert _publication_targets(prefix) == [
        tmp_path / "case.certified.ll",
        tmp_path / "case.certified.bin",
        tmp_path / "case.validated-compat.ll",
        tmp_path / "case.validated-compat.bin",
        tmp_path / "case.evidence.ll",
    ]


def test_new_run_removes_stale_authority_aliases(tmp_path: Path) -> None:
    prefix = tmp_path / "case"
    targets = _publication_targets(prefix)
    for target in targets:
        target.write_bytes(b"stale")

    removed = _clear_stale_publications(prefix)

    assert removed == [str(target) for target in targets]
    assert all(not target.exists() for target in targets)


def test_directory_at_publication_target_fails_closed(tmp_path: Path) -> None:
    prefix = tmp_path / "case"
    target = tmp_path / "case.certified.ll"
    target.mkdir()
    with pytest.raises(ValueError, match="cannot be replaced"):
        _clear_stale_publications(prefix)


def _llvm_toolchain() -> tuple[Path, Path, Path]:
    llvm_config = next(
        (
            Path(tool)
            for name in (
                "llvm-config-21",
                "llvm-config-20",
                "llvm-config-19",
                "llvm-config-18",
                "llvm-config-17",
                "llvm-config",
            )
            if (tool := shutil.which(name))
        ),
        None,
    )
    if llvm_config is None:
        pytest.fail("GitHub runner has no llvm-config development toolchain")
    cmake_dir = Path(
        subprocess.check_output([str(llvm_config), "--cmakedir"], text=True).strip()
    )
    bindir = Path(
        subprocess.check_output([str(llvm_config), "--bindir"], text=True).strip()
    )
    opt = next((path for path in (bindir / "opt",) if path.is_file()), None)
    filecheck = next(
        (path for path in (bindir / "FileCheck", bindir / "FileCheck-18") if path.is_file()),
        None,
    )
    if not cmake_dir.is_dir() or opt is None or filecheck is None:
        pytest.fail(
            f"incomplete LLVM toolchain: cmake={cmake_dir}, opt={opt}, "
            f"FileCheck={filecheck}"
        )
    return cmake_dir, opt, filecheck


def _build_and_test_pass(
    tmp_path: Path, source: Path, plugin_name: str, test_script: Path
) -> None:
    llvm_dir, opt, filecheck = _llvm_toolchain()
    build = tmp_path / plugin_name
    subprocess.run(
        [
            "cmake",
            "-S",
            str(source),
            "-B",
            str(build),
            "-G",
            "Ninja",
            f"-DLLVM_DIR={llvm_dir}",
            "-DCMAKE_BUILD_TYPE=Release",
        ],
        check=True,
        cwd=PROJECT_ROOT,
    )
    subprocess.run(
        ["cmake", "--build", str(build), "-j2"],
        check=True,
        cwd=PROJECT_ROOT,
    )
    plugin = build / f"{plugin_name}.so"
    assert plugin.is_file(), plugin
    env = os.environ.copy()
    env.update(
        {
            "OPT_BIN": str(opt),
            "FILECHECK_BIN": str(filecheck),
            "PLUGIN": str(plugin),
        }
    )
    subprocess.run(
        ["bash", str(test_script)], check=True, cwd=PROJECT_ROOT, env=env
    )


def test_semantic_brightening_cpp_core_builds_and_runs_ir_regressions(
    tmp_path: Path,
) -> None:
    _build_and_test_pass(
        tmp_path,
        PROJECT_ROOT / "src/llvm_pass/brighten_020_devirt_pass",
        "BrightenDevirtPass",
        PROJECT_ROOT
        / "src/llvm_pass/brighten_020_devirt_pass/tests/run_semantic_tests.sh",
    )
    _build_and_test_pass(
        tmp_path,
        PROJECT_ROOT / "src/llvm_pass/brighten_030_state_ssa_pass",
        "BrightenStateSSAPass",
        PROJECT_ROOT / "src/llvm_pass/brighten_030_state_ssa_pass/tests/run_tests.sh",
    )
