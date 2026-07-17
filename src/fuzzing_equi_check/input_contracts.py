#!/usr/bin/env python3
"""Contract-driven input generation for the selected semantic-fuzzing cases.

The manifest is deliberately data-driven.  Seeds remain the executable examples,
while the contract controls which parts may be mutated and validates every
payload before it reaches either program.
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


_TOKEN_RE = re.compile(rb"[+-]?(?:(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?|\d+)|[A-Za-z_][A-Za-z0-9_]*")
_INT_RE = re.compile(rb"[+-]?\d+")
_FLOAT_RE = re.compile(rb"[+-]?(?:(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?)")


def _manifest_path(project_root: str) -> Path:
    return Path(project_root) / "data" / "input_contracts" / "pilot_mix3_50.json"


def load_contracts(project_root: str) -> Dict[Tuple[str, str], Dict[str, Any]]:
    path = _manifest_path(project_root)
    if not path.is_file():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        document = json.load(handle)
    return {
        (entry["case_id"], entry["submission_id"]): entry
        for entry in document.get("contracts", [])
    }


def resolve_input_contract(project_root: str, binary_path: str) -> Optional[Dict[str, Any]]:
    """Resolve a contract from a dataset binary path such as p00183/s868*.elf."""
    path = Path(binary_path)
    case_id = next((part for part in path.parts if re.fullmatch(r"p\d+", part)), None)
    submission_id = next((part for part in path.name.split("_", 1) if re.fullmatch(r"s\d+", part)), None)
    if not case_id or not submission_id:
        return None
    return load_contracts(project_root).get((case_id, submission_id))


def _dedupe(payloads: Iterable[bytes]) -> List[bytes]:
    seen = set()
    output = []
    for payload in payloads:
        payload = bytes(payload)
        if payload not in seen:
            seen.add(payload)
            output.append(payload)
    return output


def _token_kind(token: bytes) -> str:
    if _INT_RE.fullmatch(token):
        return "int"
    if _FLOAT_RE.fullmatch(token):
        return "float"
    return "word"


def _token_skeleton(payload: bytes) -> bytes:
    return _TOKEN_RE.sub(b"<value>", payload)


def _seed_shape_compatible(payload: bytes, seed: bytes) -> bool:
    """Preserve lexical token count/types and exact separators/newline layout."""
    payload_tokens = list(_TOKEN_RE.finditer(payload))
    seed_tokens = list(_TOKEN_RE.finditer(seed))
    if len(payload_tokens) != len(seed_tokens):
        return False
    if [_token_kind(match.group(0)) for match in payload_tokens] != [
        _token_kind(match.group(0)) for match in seed_tokens
    ]:
        return False
    return _token_skeleton(payload) == _token_skeleton(seed)


def _lines(payload: bytes) -> Optional[List[str]]:
    try:
        return payload.decode("utf-8").splitlines()
    except UnicodeDecodeError:
        return None


def _validate_board_stream(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    lines = _lines(payload)
    if not lines or lines[-1] != "0":
        return False, "missing_board_terminator"
    rows = lines[:-1]
    constraints = contract.get("constraints", {})
    width = int(constraints.get("cols", 3))
    height = int(constraints.get("rows", 3))
    if len(rows) == 0 or len(rows) % height:
        return False, "board_row_count"
    if not int(constraints.get("min_boards", 1)) <= len(rows) // height <= int(constraints.get("max_boards", 9999)):
        return False, "board_count"
    alphabet = set(str(constraints.get("alphabet", "")))
    if any(len(row) != width or any(char not in alphabet for char in row) for row in rows):
        return False, "board_cell_shape_or_alphabet"
    return True, ""


def _validate_triangular_strings(payload: bytes) -> Tuple[bool, str]:
    lines = _lines(payload)
    if not lines:
        return False, "missing_triangular_input"
    try:
        n = int(lines[0].strip())
    except ValueError:
        return False, "invalid_triangular_size"
    rows = lines[1:]
    if len(rows) != max(0, n - 1):
        return False, "triangular_row_count"
    if any(len(row) != index or any(char not in "01" for char in row) for index, row in enumerate(rows, 1)):
        return False, "triangular_row_shape"
    return True, ""


def _validate_grid(payload: bytes, kind: str, contract: Dict[str, Any]) -> Tuple[bool, str]:
    lines = _lines(payload)
    if not lines:
        return False, "missing_grid_input"
    try:
        header = [int(value) for value in lines[0].split()]
    except ValueError:
        return False, "invalid_grid_header"
    if kind == "fixed_integer_grid":
        if len(header) != 2:
            return False, "grid_header_fields"
        height, width = header
        if height < 1 or width < 1 or len(lines[1:]) != height:
            return False, "grid_row_count"
        if any(len(row.split()) != width for row in lines[1:]):
            return False, "grid_column_count"
        return True, ""
    if kind == "layered_grid_block":
        if len(header) != 2:
            return False, "layered_grid_header_fields"
        height, width = header
        if height < 1 or width < 1 or len(lines) < height + 2:
            return False, "layered_grid_base_rows"
        if any(len(row) != width for row in lines[1 : height + 1]):
            return False, "layered_grid_base_shape"
        if not any("S" in row for row in lines[1 : height + 1]) or not any(
            "G" in row for row in lines[1 : height + 1]
        ):
            return False, "layered_grid_missing_endpoints"
        try:
            layers = int(lines[height + 1])
        except ValueError:
            return False, "layered_grid_layer_count"
        expected = height + 2 + layers * (height + 1)
        if layers < 0 or len(lines) != expected:
            return False, "layered_grid_layer_rows"
        cursor = height + 2
        for _ in range(layers):
            try:
                int(lines[cursor])
            except ValueError:
                return False, "layered_grid_layer_time"
            cursor += 1
            if any(len(row) != width for row in lines[cursor : cursor + height]):
                return False, "layered_grid_layer_shape"
            cursor += height
        return True, ""
    if kind == "grid_batches":
        cursor = 0
        while cursor < len(lines):
            try:
                height, width = [int(value) for value in lines[cursor].split()]
            except (ValueError, TypeError):
                return False, "grid_batch_header"
            cursor += 1
            if height == 0 and width == 0:
                return (True, "") if cursor == len(lines) else (False, "trailing_after_grid_terminator")
            if height < 1 or width < 1 or cursor + height > len(lines):
                return False, "grid_batch_dimensions"
            if any(len(row) != width for row in lines[cursor : cursor + height]):
                return False, "grid_batch_row_shape"
            alphabet = set(str(contract.get("constraints", {}).get("alphabet", "#@.wcE")))
            if any(char not in alphabet for row in lines[cursor : cursor + height] for char in row):
                return False, "grid_batch_alphabet"
            cursor += height
        return False, "missing_grid_batch_terminator"
    return True, ""


def validate_contract_payload(
    contract: Dict[str, Any], payload: bytes, seed_inputs: Optional[List[bytes]] = None
) -> Tuple[bool, str]:
    """Validate a payload against explicit grammar plus its seed layout."""
    if not payload:
        return False, "empty_payload"
    if b"\x00" in payload:
        return False, "embedded_nul"
    kind = contract.get("kind", "")
    constraints = contract.get("constraints", {})

    if kind == "board_stream":
        return _validate_board_stream(payload, contract)
    if kind == "triangular_string_matrix":
        return _validate_triangular_strings(payload)
    if kind in {"fixed_integer_grid", "layered_grid_block"}:
        return _validate_grid(payload, kind, contract)
    if kind == "grid_batches":
        return _validate_grid(payload, kind, contract)
    if kind == "big_integer_pair":
        lines = _lines(payload)
        if not lines or len(lines) != 1 or not re.fullmatch(r"\d+\s+\d+", lines[0]):
            return False, "big_integer_pair_shape"
        if any(len(part) > int(constraints.get("max_digits", 200000)) for part in lines[0].split()):
            return False, "big_integer_too_long"
        return True, ""
    if kind == "repeated_token":
        lines = _lines(payload)
        alphabet = set(str(constraints.get("alphabet", "")))
        if not lines or not alphabet or any(not line or any(char not in alphabet for char in line) for line in lines):
            return False, "token_alphabet"
        return True, ""
    if kind == "word_batches":
        lines = _lines(payload)
        if not lines:
            return False, "missing_word_batches"
        cursor = 0
        while cursor < len(lines):
            try:
                count = int(lines[cursor])
            except ValueError:
                return False, "word_batch_count"
            cursor += 1
            if count == 0:
                return (True, "") if cursor == len(lines) else (False, "trailing_after_word_terminator")
            if count < 0 or cursor + count > len(lines):
                return False, "word_batch_size"
            if any(not re.fullmatch(r"[a-z]+", line) for line in lines[cursor : cursor + count]):
                return False, "word_batch_alphabet"
            cursor += count
        return False, "missing_word_terminator"
    if kind == "string_pair_block":
        lines = _lines(payload)
        if not lines or len(lines) != 3:
            return False, "string_pair_lines"
        try:
            length = int(lines[0])
        except ValueError:
            return False, "string_pair_length"
        if length < 0 or any(len(line) != length for line in lines[1:]):
            return False, "string_pair_length_mismatch"
        return True, ""
    if kind == "length_and_string":
        lines = _lines(payload)
        if not lines or len(lines) != 2:
            return False, "length_string_lines"
        try:
            length, _ = [int(value) for value in lines[0].split()]
        except (ValueError, TypeError):
            return False, "length_string_header"
        alphabet = set(str(constraints.get("string_alphabet", "")))
        if len(lines[1]) != length or (alphabet and any(char not in alphabet for char in lines[1])):
            return False, "length_string_shape"
        return True, ""
    if kind == "named_edge_query_batches":
        lines = _lines(payload)
        if not lines:
            return False, "missing_named_graph"
        cursor = 0
        while cursor < len(lines):
            try:
                edge_count = int(lines[cursor])
            except ValueError:
                return False, "named_graph_edge_count"
            cursor += 1
            if edge_count == 0:
                return (True, "") if cursor == len(lines) else (False, "trailing_after_named_terminator")
            if cursor + edge_count >= len(lines):
                return False, "named_graph_edges"
            if any("-" not in line and line.strip() for line in lines[cursor : cursor + edge_count]):
                return False, "named_graph_edge_shape"
            cursor += edge_count
            try:
                query_count = int(lines[cursor])
            except ValueError:
                return False, "named_graph_query_count"
            cursor += 1
            if query_count < 0 or cursor + query_count > len(lines):
                return False, "named_graph_queries"
            if any("-" not in line and line.strip() for line in lines[cursor : cursor + query_count]):
                return False, "named_graph_query_shape"
            cursor += query_count
        return False, "missing_named_terminator"
    if kind == "line_stream":
        lines = _lines(payload)
        if not lines or any(len(line) > int(constraints.get("max_line_length", 4095)) for line in lines):
            return False, "line_stream_shape"

    if seed_inputs:
        if not any(_seed_shape_compatible(payload, seed) for seed in seed_inputs):
            return False, "seed_layout_changed"

    termination = str(contract.get("termination", ""))
    if "literal 0 record" in termination and not payload.rstrip().endswith(b"0"):
        return False, "missing_literal_terminator"
    if "n=0" in termination or "t=0" in termination or "c=0" in termination:
        last_line = payload.rstrip().splitlines()[-1].split()
        if not last_line or last_line[0] != b"0":
            return False, "missing_zero_terminator"
    if "all four header integers are 0" in termination:
        last_line = payload.rstrip().splitlines()[-1].split()
        if last_line != [b"0", b"0", b"0", b"0"]:
            return False, "missing_header_terminator"
    return True, ""


def _numeric_replacements(token: bytes, constraints: Dict[str, Any]) -> List[bytes]:
    if _INT_RE.fullmatch(token):
        value = int(token)
        low = int(constraints.get("min", max(-1000000, value - 1000000)))
        high = int(constraints.get("max", min(1000000, value + 1000000)))
        candidates = [value - 1, value + 1, low, high, 0, 1, value * 2]
        return [str(max(low, min(high, item))).encode() for item in candidates if item != value]
    if _FLOAT_RE.fullmatch(token):
        value = float(token)
        low = float(constraints.get("min", -1000000.0))
        high = float(constraints.get("max", 1000000.0))
        candidates = [value - 1.0, value + 1.0, low, high, 0.0, 1.0]
        replacements = []
        for item in candidates:
            if item == value:
                continue
            rendered = format(max(low, min(high, item)), ".8g")
            if "." not in rendered and "e" not in rendered.lower():
                rendered += ".0"
            replacements.append(rendered.encode())
        return replacements
    return []


def _mutate_board(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    lines = _lines(seed)
    if not lines or lines[-1] != "0":
        return None
    alphabet = str(contract.get("constraints", {}).get("alphabet", "bw+"))
    rows = lines[:-1]
    if not rows:
        return None
    row_index = random.randrange(len(rows))
    if not rows[row_index]:
        return None
    col_index = random.randrange(len(rows[row_index]))
    current = rows[row_index][col_index]
    choices = [char for char in alphabet if char != current]
    if not choices:
        return None
    row = rows[row_index]
    rows[row_index] = row[:col_index] + random.choice(choices) + row[col_index + 1 :]
    return ("\n".join(rows) + "\n0\n").encode()


def _mutate_characters(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    data = bytearray(seed)
    allowed = str(contract.get("constraints", {}).get("alphabet", ""))
    positions = [index for index, value in enumerate(data) if value not in b"\r\n \t" and value != 0]
    if not positions:
        return None
    eligible = []
    for index in positions:
        current = chr(data[index])
        if allowed:
            choices = [char for char in allowed if char != current]
        elif current.isalpha():
            alphabet = "abcdefghijklmnopqrstuvwxyz" if current.islower() else "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            choices = [char for char in alphabet if char != current]
        elif current.isdigit():
            choices = [char for char in "0123456789" if char != current]
        else:
            choices = []
        if choices:
            eligible.append((index, choices))
    if not eligible:
        return None
    for index, choices in random.sample(eligible, k=min(len(eligible), random.randint(1, 4))):
        data[index] = ord(random.choice(choices))
    return bytes(data)


def _mutate_layered_grid(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    lines = _lines(seed)
    if not lines or len(lines) < 4:
        return None
    try:
        height, width = [int(value) for value in lines[0].split()]
        layers = int(lines[height + 1])
    except (ValueError, IndexError):
        return None
    positions = []
    for line_index in range(1, len(lines)):
        if line_index == height + 1 or (line_index > height + 1 and (line_index - height - 2) % (height + 1) == 0):
            continue
        if len(lines[line_index]) != width:
            continue
        for column, char in enumerate(lines[line_index]):
            if char in ".#":
                positions.append((line_index, column))
    if not positions:
        return None
    mutable = [list(line) for line in lines]
    for line_index, column in random.sample(positions, k=min(len(positions), random.randint(1, 4))):
        mutable[line_index][column] = random.choice(".#" if mutable[line_index][column] == "." else ".")
    return ("\n".join("".join(line) for line in mutable) + "\n").encode()


def _mutate_counted_words(seed: bytes) -> Optional[bytes]:
    lines = _lines(seed)
    if not lines:
        return None
    word_positions = []
    cursor = 0
    while cursor < len(lines):
        try:
            count = int(lines[cursor])
        except ValueError:
            return None
        cursor += 1
        if count == 0:
            break
        word_positions.extend(range(cursor, min(cursor + count, len(lines))))
        cursor += count
    if not word_positions:
        return None
    mutable = list(lines)
    for index in random.sample(word_positions, k=min(len(word_positions), random.randint(1, 3))):
        chars = list(mutable[index])
        for column in random.sample(range(len(chars)), k=min(len(chars), random.randint(1, 2))):
            chars[column] = random.choice("abcdefghijklmnopqrstuvwxyz")
        mutable[index] = "".join(chars)
    return ("\n".join(mutable) + "\n").encode()


def _mutate_length_string(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    lines = _lines(seed)
    if not lines or len(lines) != 2:
        return None
    alphabet = str(contract.get("constraints", {}).get("string_alphabet", "")) or "abcdefghijklmnopqrstuvwxyz"
    chars = list(lines[1])
    for column in random.sample(range(len(chars)), k=min(len(chars), random.randint(1, 3))):
        chars[column] = random.choice([char for char in alphabet if char != chars[column]])
    lines[1] = "".join(chars)
    return ("\n".join(lines) + "\n").encode()


def _mutate_string_pair(seed: bytes) -> Optional[bytes]:
    lines = _lines(seed)
    if not lines or len(lines) != 3:
        return None
    mutable = list(lines)
    for row_index in (1, 2):
        chars = list(mutable[row_index])
        for column in random.sample(range(len(chars)), k=min(len(chars), random.randint(1, 3))):
            if chars[column].isalpha():
                alphabet = "abcdefghijklmnopqrstuvwxyz" if chars[column].islower() else "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                chars[column] = random.choice([char for char in alphabet if char != chars[column]])
        mutable[row_index] = "".join(chars)
    return ("\n".join(mutable) + "\n").encode()


def _mutate_numeric(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    matches = list(_TOKEN_RE.finditer(seed))
    if not matches:
        return None
    preserve_counts = "preserve_counts" in str(contract.get("mutation", ""))
    termination = str(contract.get("termination", ""))
    lines = seed.splitlines(keepends=True)
    protected = set()
    offset = 0
    for line in lines:
        tokens = list(_TOKEN_RE.finditer(line))
        token_values = [match.group(0) for match in tokens]
        is_zero_line = bool(token_values) and all(value.lstrip(b"+-") in {b"0", b"0.0"} for value in token_values)
        for local_index, match in enumerate(tokens):
            absolute = next(index for index, candidate in enumerate(matches) if candidate.start() == offset + match.start())
            if is_zero_line and termination != "eof":
                protected.add(absolute)
            elif preserve_counts and local_index == 0:
                protected.add(absolute)
            elif contract.get("kind") == "fixed_integer_grid" and line is lines[0]:
                protected.add(absolute)
        offset += len(line)
    mutable = [
        (index, match)
        for index, match in enumerate(matches)
        if index not in protected
    ]
    if not mutable:
        return None
    index, match = random.choice(mutable)
    replacements = _numeric_replacements(match.group(0), contract.get("constraints", {}))
    if _INT_RE.fullmatch(match.group(0)):
        value = int(match.group(0))
        low = int(contract.get("constraints", {}).get("min", max(-1000000, value - 1000000)))
        high = int(contract.get("constraints", {}).get("max", min(1000000, value + 1000000)))
        if low <= high:
            replacements.append(str(random.randint(low, high)).encode())
    elif _FLOAT_RE.fullmatch(match.group(0)):
        value = float(match.group(0))
        low = float(contract.get("constraints", {}).get("min", -1000000.0))
        high = float(contract.get("constraints", {}).get("max", 1000000.0))
        rendered = format(random.uniform(low, high), ".8g")
        if "." not in rendered and "e" not in rendered.lower():
            rendered += ".0"
        replacements.append(rendered.encode())
    if not replacements:
        return None
    replacement = random.choice(replacements)
    return seed[: match.start()] + replacement + seed[match.end() :]


def _mutate_payload(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    kind = contract.get("kind", "")
    mutation = str(contract.get("mutation", ""))
    if kind == "board_stream":
        return _mutate_board(seed, contract)
    if kind == "layered_grid_block":
        return _mutate_layered_grid(seed, contract)
    if kind == "word_batches":
        return _mutate_counted_words(seed)
    if kind == "length_and_string":
        return _mutate_length_string(seed, contract)
    if kind == "string_pair_block":
        return _mutate_string_pair(seed)
    if kind == "triangular_string_matrix":
        lines = _lines(seed)
        if not lines:
            return None
        row_index = random.randrange(1, len(lines))
        if not lines[row_index]:
            return None
        choices = "01"
        col_index = random.randrange(len(lines[row_index]))
        current = lines[row_index][col_index]
        replacement = random.choice([char for char in choices if char != current])
        row = lines[row_index]
        lines[row_index] = row[:col_index] + replacement + row[col_index + 1 :]
        return ("\n".join(lines) + "\n").encode()
    if kind in {
        "layered_grid_block",
        "triangular_string_matrix",
        "repeated_token",
        "word_batches",
        "word_pair_cases",
        "named_edge_query_batches",
        "encoded_line_stream",
    } or any(
        marker in mutation for marker in ("cells_only", "characters_only", "strings_only", "names_and_counts", "alphabet_only", "token_value_only")
    ):
        return _mutate_characters(seed, contract)
    return _mutate_numeric(seed, contract)


def _random_valid_payload(contract: Dict[str, Any]) -> Optional[bytes]:
    """Create a fresh valid instance for contracts whose seed shape is finite."""
    kind = contract.get("kind", "")
    constraints = contract.get("constraints", {})
    if kind == "board_stream":
        boards = random.randint(int(constraints.get("min_boards", 1)), int(constraints.get("max_boards", 4)))
        alphabet = str(constraints.get("alphabet", "bw+"))
        rows = ["".join(random.choice(alphabet) for _ in range(int(constraints.get("cols", 3)))) for _ in range(boards * int(constraints.get("rows", 3)))]
        return ("\n".join(rows) + "\n0\n").encode()
    if kind == "layered_grid_block":
        height = random.randint(2, 5)
        width = random.randint(2, 5)
        layers = random.randint(0, 4)
        base = [[random.choice(".#") for _ in range(width)] for _ in range(height)]
        base[0][0] = "S"
        base[-1][-1] = "G"
        output = [f"{height} {width}"]
        output.extend("".join(row) for row in base)
        output.append(str(layers))
        for _ in range(layers):
            output.append(str(random.randint(1, 20)))
            output.extend("".join(random.choice(".#") for _ in range(width)) for _ in range(height))
        return ("\n".join(output) + "\n").encode()
    if kind == "triangular_string_matrix":
        n = random.randint(2, 12)
        output = [str(n)]
        output.extend("".join(random.choice("01") for _ in range(width)) for width in range(1, n))
        return ("\n".join(output) + "\n").encode()
    if kind == "length_and_string":
        length = random.randint(1, 12)
        alphabet = str(constraints.get("string_alphabet", "o+."))
        value = "".join(random.choice(alphabet) for _ in range(length))
        return f"{length} {random.randint(1, 6)}\n{value}\n".encode()
    return None


def generate_contract_inputs(
    contract: Dict[str, Any], seed_inputs: List[bytes], iterations: int
) -> Tuple[List[bytes], Dict[str, int]]:
    """Generate validated inputs, retaining exact seeds as the first corpus entries."""
    seeds = _dedupe(seed_inputs)
    if iterations <= 0:
        return [], {"accepted": 0, "rejected": 0}
    accepted = []
    rejected = 0
    for seed in seeds:
        valid, _ = validate_contract_payload(contract, seed, seeds)
        if valid and seed not in accepted:
            accepted.append(seed)
    attempts = 0
    max_attempts = max(100, iterations * 100)
    while len(accepted) < iterations and seeds and attempts < max_attempts:
        attempts += 1
        candidate = _random_valid_payload(contract)
        if candidate is None:
            seed = random.choice(seeds)
            candidate = _mutate_payload(seed, contract)
        if not candidate or candidate in accepted:
            continue
        valid, _ = validate_contract_payload(contract, candidate, seeds)
        if valid:
            accepted.append(candidate)
        else:
            rejected += 1
    return accepted[:iterations], {"accepted": len(accepted), "rejected": rejected}
