from __future__ import annotations

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
