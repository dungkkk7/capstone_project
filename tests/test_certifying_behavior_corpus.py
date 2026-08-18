from __future__ import annotations

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = PROJECT_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from llvm_pass.certifying_runtime import (  # noqa: E402
    _corpus_sha256,
    _read_seed_payloads,
)


def test_ordered_corpus_hash_is_length_delimited() -> None:
    assert _corpus_sha256([b"ab", b"c"]) != _corpus_sha256([b"a", b"bc"])
    assert _corpus_sha256([b"ab", b"c"]) == _corpus_sha256([b"ab", b"c"])


def test_seed_reader_is_deterministic_and_deduplicates_payloads(
    tmp_path: Path,
) -> None:
    seed_dir = tmp_path / "seeds"
    seed_dir.mkdir()
    (seed_dir / "b.txt").write_bytes(b"second")
    (seed_dir / "a.seed").write_bytes(b"first")
    (seed_dir / "ignored.json").write_text("{}", encoding="utf-8")
    explicit = tmp_path / "explicit.input"
    explicit.write_bytes(b"first")

    payloads, sources = _read_seed_payloads([explicit], seed_dir)

    assert payloads == [b"first", b"second"]
    assert sources == [
        str(explicit.resolve()),
        str((seed_dir / "b.txt").resolve()),
    ]
