from __future__ import annotations

import csv
import re
from pathlib import Path
from typing import Any, Dict, Iterable

from fuzzing_equi_check.input_contracts import resolve_input_contract

from .models import SampleIdentity
from .storage import sha256_bytes, sha256_file, stable_json_sha256


class DatasetError(ValueError):
    pass


def _resolve_binary(value: str, project_root: Path) -> Path:
    raw = (value or "").strip().strip("\"'")
    candidates = []
    path = Path(raw).expanduser()
    if path.is_absolute():
        candidates.append(path)
    else:
        candidates.extend(
            [
                project_root / path,
                project_root / "data" / path,
                project_root / "data" / "obfuscated" / path,
            ]
        )
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    raise DatasetError(f"Original obfuscated ELF not found: {value}")


def _seed_manifest(project_root: Path, sample_id: str) -> tuple[str, list[str]]:
    seed_dir = project_root / "data" / "seeds" / sample_id
    if not seed_dir.is_dir():
        return sha256_bytes(b""), []
    entries = []
    paths = []
    for path in sorted(item for item in seed_dir.iterdir() if item.is_file()):
        paths.append(str(path.resolve()))
        entries.append(
            {
                "name": path.name,
                "sha256": sha256_file(path),
                "size": path.stat().st_size,
            }
        )
    return stable_json_sha256(entries), paths


def _obfuscation_tags(binary: Path) -> tuple[str, ...]:
    stem = binary.stem.lower()
    tags = []
    for tag in ("fla", "bcf", "instsub", "sub"):
        if re.search(rf"(?:^|_){re.escape(tag)}(?:_|$)", stem):
            tags.append(tag)
    return tuple(tags)


def read_dataset(
    dataset_path: str | Path,
    project_root: str | Path,
    *,
    pilot: int | None = None,
    sample_ids: Iterable[str] | None = None,
) -> list[SampleIdentity]:
    dataset = Path(dataset_path).resolve()
    root = Path(project_root).resolve()
    with dataset.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise DatasetError("Dataset must have a header")
        rows = list(reader)

    allowed = set(sample_ids or [])
    identities: list[SampleIdentity] = []
    seen: set[str] = set()
    for row_index, row in enumerate(rows, start=1):
        binary_value = (
            row.get("obfuscated_binary")
            or row.get("binary_path")
            or row.get("binary")
            or row.get("path")
            or ""
        )
        binary = _resolve_binary(binary_value, root)
        sample_id = next(
            (part for part in binary.parts if re.fullmatch(r"p\d+", part)),
            binary.stem,
        )
        if allowed and sample_id not in allowed:
            continue
        if sample_id in seen:
            raise DatasetError(f"Duplicate sample_id in experiment dataset: {sample_id}")
        seen.add(sample_id)
        seed_hash, _ = _seed_manifest(root, sample_id)
        input_contract = resolve_input_contract(
            str(root), str(binary), only_custom=True
        )
        identities.append(
            SampleIdentity(
                sample_id=sample_id,
                dataset_row_index=row_index,
                original_elf_path=str(binary),
                original_elf_sha256=sha256_file(binary),
                architecture="amd64",
                input_contract_id=sample_id,
                input_contract_sha256=stable_json_sha256(
                    input_contract
                ),
                seed_manifest_sha256=seed_hash,
                obfuscation_tags=_obfuscation_tags(binary),
            )
        )

    identities.sort(key=lambda item: item.sample_id)
    if pilot is not None:
        identities = identities[: max(1, int(pilot))]
    if not identities:
        raise DatasetError("No experiment samples were selected")
    return identities


def seed_paths_for_sample(project_root: str | Path, sample_id: str) -> list[str]:
    _, paths = _seed_manifest(Path(project_root).resolve(), sample_id)
    return paths
