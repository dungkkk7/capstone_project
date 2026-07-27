#!/usr/bin/env python3
"""Contract-driven input generation for the selected semantic-fuzzing cases.

The manifest is deliberately data-driven.  Seeds remain the executable examples,
while the contract controls which parts may be mutated and validates every
payload before it reaches either program.
"""

from __future__ import annotations

import json
import math
import random
import re
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


_TOKEN_RE = re.compile(rb"[+-]?(?:(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?|\d+)|[A-Za-z_][A-Za-z0-9_]*")
_INT_RE = re.compile(rb"[+-]?\d+")
_FLOAT_RE = re.compile(rb"[+-]?(?:(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?)")
_C_WHITESPACE = b" \t\n\v\f\r"


def _scanf_source(payload: bytes, requirement: Dict[str, Any]) -> Tuple[Optional[bytes], str]:
    """Return the byte stream consumed by one source-derived scanf contract.

    ``scanf`` consumes stdin, while the common ``fgets(...); sscanf(...)``
    pattern consumes one complete input line.  The latter must name its line
    explicitly: guessing a buffer/data-flow relation would make a validity
    claim we cannot prove.
    """
    source = str(requirement.get("source", "stdin"))
    if source == "stdin":
        return payload, ""
    if source == "line":
        line_index = requirement.get("line_index")
        if not isinstance(line_index, int) or line_index < 0:
            return None, "scanf_requirement_source"
        lines = payload.splitlines()
        if line_index >= len(lines):
            return None, "scanf_requirement_eof"
        return lines[line_index], ""
    return None, "scanf_requirement_source"


def _consume_scanf_integer(data: bytes, offset: int, conversion: str, width: Optional[int]) -> Optional[int]:
    end = len(data) if width is None else min(len(data), offset + width)
    token = data[offset:end]
    sign = 0
    if sign < len(token) and token[sign:sign + 1] in (b"+", b"-"):
        sign += 1
    digits = token[sign:]
    if conversion in "du":
        match = re.match(rb"[0-9]+", digits)
    elif conversion == "o":
        match = re.match(rb"[0-7]+", digits)
    elif conversion in "xX":
        match = re.match(rb"(?:0[xX])?[0-9a-fA-F]+", digits)
    elif conversion == "i":
        match = re.match(rb"(?:0[xX][0-9a-fA-F]+|0[0-7]*|[1-9][0-9]*)", digits)
    else:
        return None
    if match is None:
        return None
    return offset + sign + match.end()


def _consume_scanf_conversion(
    data: bytes, offset: int, conversion: str, width: Optional[int]
) -> Optional[int]:
    if conversion in "diuoxX":
        return _consume_scanf_integer(data, offset, conversion, width)
    end = len(data) if width is None else min(len(data), offset + width)
    if conversion == "s":
        cursor = offset
        while cursor < end and data[cursor] not in _C_WHITESPACE:
            cursor += 1
        return cursor if cursor != offset else None
    if conversion == "c":
        count = 1 if width is None else width
        return offset + count if count > 0 and offset + count <= len(data) else None
    # Deliberately fail closed: scansets, floating conversion, %n, positional
    # arguments and locale-sensitive forms need a real C parser/oracle.
    return None


def _validate_scanf_requirement(payload: bytes, requirement: Dict[str, Any]) -> Tuple[bool, str]:
    data, reason = _scanf_source(payload, requirement)
    if data is None:
        return False, reason
    fmt = requirement.get("format")
    if not isinstance(fmt, str) or not fmt:
        return False, "scanf_requirement_format"
    try:
        format_bytes = fmt.encode("ascii")
    except UnicodeEncodeError:
        return False, "scanf_format_unsupported"

    cursor = 0
    index = 0
    assigned = 0
    required = requirement.get("required_conversions")
    while index < len(format_bytes):
        char = format_bytes[index:index + 1]
        if char in _C_WHITESPACE:
            while index < len(format_bytes) and format_bytes[index:index + 1] in _C_WHITESPACE:
                index += 1
            while cursor < len(data) and data[cursor] in _C_WHITESPACE:
                cursor += 1
            continue
        if char != b"%":
            if cursor >= len(data) or data[cursor:cursor + 1] != char:
                return False, "scanf_literal_mismatch"
            cursor += 1
            index += 1
            continue
        index += 1
        if index >= len(format_bytes):
            return False, "scanf_format_unsupported"
        if format_bytes[index:index + 1] == b"%":
            if cursor >= len(data) or data[cursor:cursor + 1] != b"%":
                return False, "scanf_literal_mismatch"
            cursor += 1
            index += 1
            continue
        suppressed = format_bytes[index:index + 1] == b"*"
        if suppressed:
            index += 1
        width_start = index
        while index < len(format_bytes) and format_bytes[index:index + 1].isdigit():
            index += 1
        width = int(format_bytes[width_start:index]) if index != width_start else None
        if width == 0:
            return False, "scanf_format_unsupported"
        if format_bytes[index:index + 2] in (b"hh", b"ll"):
            index += 2
        elif index < len(format_bytes) and format_bytes[index:index + 1] in b"hljztL":
            index += 1
        if index >= len(format_bytes):
            return False, "scanf_format_unsupported"
        conversion = chr(format_bytes[index])
        index += 1
        if conversion != "c":
            while cursor < len(data) and data[cursor] in _C_WHITESPACE:
                cursor += 1
        next_cursor = _consume_scanf_conversion(data, cursor, conversion, width)
        if next_cursor is None:
            if conversion not in "diuoxXsc":
                return False, "scanf_format_unsupported"
            return False, "scanf_conversion_incomplete"
        cursor = next_cursor
        if not suppressed:
            assigned += 1

    if required is None:
        required = assigned
    if not isinstance(required, int) or required < 0 or assigned < required:
        return False, "scanf_requirement_format"
    return True, ""


def _validate_scanf_completeness(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    requirements = contract.get("scanf_required_conversions", [])
    if requirements is None:
        return True, ""
    if not isinstance(requirements, list):
        return False, "scanf_requirement_format"
    for requirement in requirements:
        if not isinstance(requirement, dict):
            return False, "scanf_requirement_format"
        valid, reason = _validate_scanf_requirement(payload, requirement)
        if not valid:
            return False, reason
    return True, ""


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    if value == 2:
        return True
    if value % 2 == 0:
        return False
    limit = int(value**0.5)
    factor = 3
    while factor <= limit:
        if value % factor == 0:
            return False
        factor += 2
    return True


def _manifest_path(project_root: str) -> Path:
    return Path(project_root) / "data" / "input_contracts" / "custom_dataset.json"


def _custom_manifest_path(project_root: str) -> Path:
    return Path(project_root) / "data" / "input_contracts" / "custom_dataset.json"


def _load_manifest(path: Path) -> Dict[Tuple[str, str], Dict[str, Any]]:
    if not path.is_file():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        document = json.load(handle)
    return {
        (entry["case_id"], entry["submission_id"]): entry
        for entry in document.get("contracts", [])
    }


def load_contracts(
    project_root: str, *, prefer_custom: bool = False
) -> Dict[Tuple[str, str], Dict[str, Any]]:
    """Load input contracts.

    By default we keep historical behavior for existing pilot pipelines by using
    ``pilot_mix3_50.json``.  For custom dataset runs, call with
    ``prefer_custom=True`` to resolve only custom contracts first.
    """
    if prefer_custom:
        custom_contracts = _load_manifest(_custom_manifest_path(project_root))
        if custom_contracts:
            return custom_contracts
    return _load_manifest(_manifest_path(project_root))


def resolve_input_contract(
    project_root: str, binary_path: str, *, only_custom: bool = False
) -> Optional[Dict[str, Any]]:
    """Resolve a contract from a dataset binary path such as p00183/s868*.elf.

    By default, resolve using the standard manifest and fallback as before.
    Set ``only_custom=True`` to restrict lookup to custom_dataset.json only.
    """
    path = Path(binary_path)
    case_id = next((part for part in path.parts if re.fullmatch(r"p\d+", part)), None)
    submission_id = next((part for part in path.name.split("_", 1) if re.fullmatch(r"s\d+", part)), None)
    if not case_id or not submission_id:
        return None

    key = (case_id, submission_id)
    custom_contract = load_contracts(project_root, prefer_custom=True).get(key)
    if custom_contract is not None or only_custom:
        return custom_contract
    return load_contracts(project_root).get(key)


def _random_ascii_token(length: int, alphabet: str) -> str:
    if not alphabet:
        return ""
    return "".join(random.choice(alphabet) for _ in range(max(1, length)))


def _validate_primitive_modulus_stream(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    constraints = contract.get("constraints", {})
    tokens = payload.split()
    if len(tokens) < 2 or any(not _INT_RE.fullmatch(token) for token in tokens):
        return False, "primitive_modulus_shape"

    p = int(tokens[0])
    expected_min = int(constraints.get("p_min", 2))
    expected_max = int(constraints.get("p_max", 2**31 - 1))
    if p < expected_min or p > expected_max:
        return False, "primitive_modulus_prime_bounds"

    if bool(constraints.get("prime", False)) and not _is_prime(p):
        return False, "primitive_modulus_prime_required"

    body_count = p - 1
    if len(tokens) != 1 + 1 + body_count:
        return False, "primitive_modulus_payload_size"

    value_min = int(constraints.get("value_min", -2**31))
    value_max = int(constraints.get("value_max", 2**31 - 1))
    values = [int(token) for token in tokens[1:]]
    if any(v < value_min or v > value_max for v in values):
        return False, "primitive_modulus_value_bounds"
    return True, ""


def _validate_packet_token(token: str, min_len: int, max_len: int, *, keep_wildcard: bool = False) -> bool:
    if not token:
        return False
    if not (min_len <= len(token) <= max_len):
        return False
    pattern = r"[A-Za-z0-9?]+" if keep_wildcard else r"[A-Za-z0-9]+"
    if not re.fullmatch(pattern, token):
        return False
    if keep_wildcard and any(ch in "#!" for ch in token):
        return False
    return True


def _validate_rule_packet_batches(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    lines = _lines(payload)
    if not lines:
        return False, "rule_packet_lines"

    cursor = 0
    while cursor < len(lines):
        header = lines[cursor].split()
        if len(header) != 2:
            return False, "rule_packet_batch_header"

        try:
            rule_num = int(header[0])
            packet_num = int(header[1])
        except ValueError:
            return False, "rule_packet_batch_header_ints"

        if rule_num == 0 and packet_num == 0:
            return (True, "") if cursor == len(lines) - 1 else (False, "rule_packet_trailing_data")

        if rule_num < 0 or packet_num < 0:
            return False, "rule_packet_negative_counts"

        cursor += 1
        if cursor + rule_num + packet_num > len(lines):
            return False, "rule_packet_truncated_batch"

        for _ in range(rule_num):
            pieces = lines[cursor].split()
            cursor += 1
            if len(pieces) != 3:
                return False, "rule_packet_rule_shape"
            op, src, dst = pieces
            if op not in {"permit", "deny"}:
                return False, "rule_packet_rule_action"
            if not _validate_packet_token(src, 1, 11, keep_wildcard=True):
                return False, "rule_packet_rule_src"
            if not _validate_packet_token(dst, 1, 11, keep_wildcard=True):
                return False, "rule_packet_rule_dst"

        for _ in range(packet_num):
            pieces = lines[cursor].split()
            cursor += 1
            if len(pieces) != 3:
                return False, "rule_packet_packet_shape"
            src, dst, message = pieces
            if not _validate_packet_token(src, 1, 11, keep_wildcard=True):
                return False, "rule_packet_packet_src"
            if not _validate_packet_token(dst, 1, 11, keep_wildcard=True):
                return False, "rule_packet_packet_dst"
            if not message:
                return False, "rule_packet_packet_message"

    return False, "rule_packet_missing_terminator"


def _mutate_rule_packet_batches(seed: bytes, contract: Dict[str, Any]) -> Optional[bytes]:
    lines = _lines(seed)
    if not lines:
        return None

    cursor = 0
    rule_lines: List[int] = []
    packet_lines: List[int] = []
    while cursor < len(lines):
        header = lines[cursor].split()
        if len(header) != 2:
            return None
        try:
            rule_num = int(header[0])
            packet_num = int(header[1])
        except ValueError:
            return None

        cursor += 1
        if rule_num == 0 and packet_num == 0:
            if cursor != len(lines):
                return None
            break

        block_end = cursor + rule_num + packet_num
        if block_end > len(lines):
            return None
        if rule_num < 0 or packet_num < 0:
            return None

        for _ in range(rule_num):
            pieces = lines[cursor].split()
            cursor += 1
            if len(pieces) != 3:
                return None
            rule_lines.append(cursor - 1)
            action, source, destination = pieces
            if action not in {"permit", "deny"}:
                return None
            if not _validate_packet_token(source, 1, 11, keep_wildcard=True):
                return None
            if not _validate_packet_token(destination, 1, 11, keep_wildcard=True):
                return None

        for _ in range(packet_num):
            pieces = lines[cursor].split()
            cursor += 1
            if len(pieces) != 3:
                return None
            source, destination, message = pieces
            packet_lines.append(cursor - 1)
            if not _validate_packet_token(source, 1, 11, keep_wildcard=True):
                return None
            if not _validate_packet_token(destination, 1, 11, keep_wildcard=True):
                return None
            if not message:
                return None

    if not (rule_lines or packet_lines):
        return None

    def mutate_token(text: str, alphabet: str) -> Optional[str]:
        if not text:
            return None
        index = random.randrange(len(text))
        current = text[index]
        choices = [char for char in alphabet if char != current]
        if not choices:
            return None
        return text[:index] + random.choice(choices) + text[index + 1 :]

    mutated = lines[:]
    if random.random() < 0.5 and rule_lines:
        target = random.choice(rule_lines)
        action, source, destination = mutated[target].split()
        if random.random() < 0.5:
            action = "permit" if action == "deny" else "deny"
        elif random.random() < 0.6:
            source = mutate_token(source, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?") or source
        else:
            destination = mutate_token(destination, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?") or destination
        mutated[target] = f"{action} {source} {destination}"
    else:
        if not packet_lines:
            return None
        target = random.choice(packet_lines)
        source, destination, message = mutated[target].split()
        if random.random() < 0.4:
            source = mutate_token(source, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?") or source
        elif random.random() < 0.4:
            destination = mutate_token(destination, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?") or destination
        else:
            message = mutate_token(message, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") or message
        mutated[target] = f"{source} {destination} {message}"

    return ("\n".join(mutated) + "\n").encode()


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


def _valid_dimension_expression(formula: bytes, variables: set[bytes]) -> bool:
    """Recognize the expression subset consumed recursively by p00672."""
    if not formula or len(formula) > 100:
        return False
    tokens = re.findall(rb"[A-Za-z_][A-Za-z0-9_]*|[()+*/-]", formula)
    if b"".join(tokens) != formula:
        return False
    cursor = 0

    def parse_factor() -> bool:
        nonlocal cursor
        if cursor >= len(tokens):
            return False
        token = tokens[cursor]
        if re.fullmatch(rb"[A-Za-z_][A-Za-z0-9_]*", token):
            cursor += 1
            return token in variables
        if token != b"(":
            return False
        cursor += 1
        if not parse_expression() or cursor >= len(tokens) or tokens[cursor] != b")":
            return False
        cursor += 1
        return True

    def parse_term() -> bool:
        nonlocal cursor
        if not parse_factor():
            return False
        while cursor < len(tokens) and tokens[cursor] in {b"*", b"/"}:
            cursor += 1
            if not parse_factor():
                return False
        return True

    def parse_expression() -> bool:
        nonlocal cursor
        if not parse_term():
            return False
        while cursor < len(tokens) and tokens[cursor] in {b"+", b"-"}:
            cursor += 1
            if not parse_term():
                return False
        return True

    return parse_expression() and cursor == len(tokens)


def _validate_dimension_expression_batches(payload: bytes) -> Tuple[bool, str]:
    tokens = payload.split()
    cursor = 0
    saw_batch = False
    identifier = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{0,19}")

    def take_int() -> Optional[int]:
        nonlocal cursor
        if cursor >= len(tokens) or not _INT_RE.fullmatch(tokens[cursor]):
            return None
        value = int(tokens[cursor])
        cursor += 1
        return value

    while cursor < len(tokens):
        n, m, p = take_int(), take_int(), take_int()
        if n is None or m is None or p is None:
            return False, "dimension_expression_header"
        if (n, m, p) == (0, 0, 0):
            return (True, "") if saw_batch and cursor == len(tokens) else (
                False,
                "dimension_expression_terminator",
            )
        # These are the concrete bounds of dim[5], ryou[10], and var[15].
        if not (1 <= n <= 5 and 1 <= m <= 10 and 0 <= p <= 15):
            return False, "dimension_expression_bounds"
        saw_batch = True
        units: set[bytes] = set()
        for _ in range(m):
            if cursor >= len(tokens) or not identifier.fullmatch(tokens[cursor]):
                return False, "dimension_expression_unit_name"
            name = tokens[cursor]
            cursor += 1
            if name in units:
                return False, "dimension_expression_duplicate_unit"
            units.add(name)
            for _ in range(n):
                if take_int() is None:
                    return False, "dimension_expression_vector"
        if cursor >= len(tokens):
            return False, "dimension_expression_formula"
        formula = tokens[cursor]
        cursor += 1
        variables: set[bytes] = set()
        bindings: List[Tuple[bytes, bytes]] = []
        for _ in range(p):
            if cursor + 1 >= len(tokens):
                return False, "dimension_expression_binding"
            variable, unit = tokens[cursor], tokens[cursor + 1]
            cursor += 2
            if not identifier.fullmatch(variable) or not identifier.fullmatch(unit):
                return False, "dimension_expression_binding_name"
            if variable in variables or unit not in units:
                return False, "dimension_expression_binding_reference"
            variables.add(variable)
            bindings.append((variable, unit))
        if not _valid_dimension_expression(formula, variables):
            return False, "dimension_expression_formula"
    return False, "dimension_expression_terminator"


def _integer_tokens(payload: bytes) -> Optional[List[int]]:
    tokens = payload.split()
    if not tokens or any(not _INT_RE.fullmatch(token) for token in tokens):
        return None
    return [int(token) for token in tokens]


def _validate_graph_query_batches(payload: bytes) -> Tuple[bool, str]:
    values = _integer_tokens(payload)
    if values is None:
        return False, "graph_query_integer"
    cursor = 0
    while cursor + 2 <= len(values):
        edges, nodes = values[cursor : cursor + 2]
        cursor += 2
        if (edges, nodes) == (0, 0):
            return (True, "") if cursor == len(values) else (False, "graph_query_trailing")
        if not (0 <= edges <= 10000 and 1 <= nodes <= 100):
            return False, "graph_query_bounds"
        for _ in range(edges):
            if cursor + 4 > len(values):
                return False, "graph_query_edges"
            a, b, cost, time = values[cursor : cursor + 4]
            cursor += 4
            if not (1 <= a <= nodes and 1 <= b <= nodes and cost >= 0 and time >= 0):
                return False, "graph_query_edge_value"
        if cursor >= len(values):
            return False, "graph_query_count"
        queries = values[cursor]
        cursor += 1
        if not (0 <= queries <= 10000):
            return False, "graph_query_count"
        for _ in range(queries):
            if cursor + 3 > len(values):
                return False, "graph_query_queries"
            start, goal, metric = values[cursor : cursor + 3]
            cursor += 3
            if not (1 <= start <= nodes and 1 <= goal <= nodes and metric in (0, 1)):
                return False, "graph_query_query_value"
    return False, "graph_query_terminator"


def _validate_three_group_block(payload: bytes) -> Tuple[bool, str]:
    values = _integer_tokens(payload)
    if values is None:
        return False, "three_group_integer"
    n, cursor = values[0], 1
    if not 1 <= n <= 100:
        return False, "three_group_n"
    for _ in range(3):
        if cursor >= len(values):
            return False, "three_group_count"
        count = values[cursor]
        cursor += 1
        if not 0 <= count <= n or cursor + count > len(values):
            return False, "three_group_count"
        if any(not 1 <= member <= n for member in values[cursor : cursor + count]):
            return False, "three_group_member"
        cursor += count
    return ((True, "") if cursor == len(values) else (False, "three_group_trailing"))


def _validate_header_and_list(payload: bytes) -> Tuple[bool, str]:
    values = _integer_tokens(payload)
    if values is None or len(values) < 6:
        return False, "header_list_integer"
    n, k, duration, slow_speed, fast_speed, length = values[:6]
    if len(values) != 6 + n:
        return False, "header_list_size"
    if not (0 <= n <= 10000 and k >= 0 and duration >= 0):
        return False, "header_list_count"
    if slow_speed <= 0 or fast_speed <= 0 or not 0 <= length <= 10000:
        return False, "header_list_bounds"
    if any(not 1 <= position <= length for position in values[6:]):
        return False, "header_list_position"
    return True, ""


def _validate_fixed_vector_block(payload: bytes) -> Tuple[bool, str]:
    values = _integer_tokens(payload)
    if values is None or len(values) != 9:
        return False, "fixed_vector_size"
    target, *vectors = values
    prices, amounts = vectors[:4], vectors[4:]
    if not 1 <= target <= 500 or any(price < 0 for price in prices):
        return False, "fixed_vector_value"
    # dp has 505 elements and the implementation stores the first overshoot
    # before testing whether it reached N.
    if any(amount <= 0 or target + amount - 1 >= 505 for amount in amounts):
        return False, "fixed_vector_index"
    return True, ""


def _validate_weighted_graph_batches(payload: bytes) -> Tuple[bool, str]:
    values = _integer_tokens(payload)
    if values is None:
        return False, "weighted_graph_integer"
    cursor = 0
    while cursor + 5 <= len(values):
        tickets, cities, edges, start, goal = values[cursor : cursor + 5]
        cursor += 5
        if tickets == 0:
            return (True, "") if (cities, edges, start, goal) == (0, 0, 0, 0) and cursor == len(values) else (
                False,
                "weighted_graph_terminator",
            )
        if not (1 <= tickets <= 9 and 1 <= cities <= 100 and 0 <= edges <= 501):
            return False, "weighted_graph_bounds"
        if not (1 <= start <= cities and 1 <= goal <= cities):
            return False, "weighted_graph_endpoint"
        for _ in range(edges):
            if cursor + 3 > len(values):
                return False, "weighted_graph_edges"
            a, b, cost = values[cursor : cursor + 3]
            cursor += 3
            if not (1 <= a <= cities and 1 <= b <= cities and 0 <= cost <= 10000000):
                return False, "weighted_graph_edge_value"
    return False, "weighted_graph_terminator"


def _validate_slim_span_batches(payload: bytes) -> Tuple[bool, str]:
    """Validate AOJ 1280's ``N M`` plus ``M`` weighted-edge batches.

    Keep this line-aware: the target parser reads one edge per ``fgets`` call,
    so accepting a merely token-equivalent layout can exercise parser failure
    rather than program semantics.
    """
    lines = payload.splitlines()
    if not lines or not payload.endswith(b"\n"):
        return False, "slim_span_newline"

    cursor = 0
    while cursor < len(lines):
        header = lines[cursor].split()
        cursor += 1
        if len(header) != 2 or any(not _INT_RE.fullmatch(token) for token in header):
            return False, "slim_span_header"
        nodes, edges = (int(token) for token in header)
        if nodes == 0:
            return (True, "") if edges == 0 and cursor == len(lines) else (
                False,
                "slim_span_terminator",
            )
        if not (1 <= nodes <= 100 and 0 <= edges <= 5000):
            return False, "slim_span_bounds"
        if cursor + edges > len(lines):
            return False, "slim_span_edges"
        for edge_line in lines[cursor : cursor + edges]:
            fields = edge_line.split()
            if len(fields) != 3 or any(
                not _INT_RE.fullmatch(token) for token in fields
            ):
                return False, "slim_span_edge_integer"
            left, right, weight = (int(token) for token in fields)
            if not (
                1 <= left <= nodes
                and 1 <= right <= nodes
                and 0 <= weight <= 10_000_000
            ):
                return False, "slim_span_edge_value"
        cursor += edges
    return False, "slim_span_terminator"


def _validate_bit_vectors(payload: bytes) -> Tuple[bool, str]:
    values = _integer_tokens(payload)
    if values is None or len(values) < 2:
        return False, "bit_vector_integer"
    n, runs = values[:2]
    if not (1 <= n <= 15 and 1 <= runs <= 15) or len(values) != 2 + n + runs:
        return False, "bit_vector_size"
    bits = values[2 : 2 + n]
    targets = values[2 + n :]
    if any(bit not in (0, 1) for bit in bits):
        return False, "bit_vector_bit"
    if any(length <= 0 for length in targets) or sum(targets) != n:
        return False, "bit_vector_runs"
    return True, ""


def _validate_circle_batches(payload: bytes) -> Tuple[bool, str]:
    tokens = payload.split()
    cursor = 0
    while cursor < len(tokens):
        if not _INT_RE.fullmatch(tokens[cursor]):
            return False, "circle_batch_count"
        count = int(tokens[cursor])
        cursor += 1
        if count == 0:
            return (True, "") if cursor == len(tokens) else (False, "circle_batch_trailing")
        if not 1 <= count <= 100 or cursor + 3 * count > len(tokens):
            return False, "circle_batch_size"
        for _ in range(count):
            try:
                x, y, radius = map(float, tokens[cursor : cursor + 3])
            except (ValueError, OverflowError):
                return False, "circle_batch_number"
            cursor += 3
            if not all(math.isfinite(value) for value in (x, y, radius)) or radius < 0:
                return False, "circle_batch_value"
    return False, "circle_batch_terminator"


def _integer_values(payload: bytes, reason: str) -> Tuple[Optional[List[int]], str]:
    tokens = payload.split()
    if not tokens or any(not _INT_RE.fullmatch(token) for token in tokens):
        return None, reason
    return [int(token) for token in tokens], ""


def _validate_two_row_integer_batches(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "two_row_integer")
    if values is None:
        return False, reason
    cursor = 0
    while cursor < len(values):
        count = values[cursor]
        cursor += 1
        if count == 0:
            return (True, "") if cursor == len(values) else (False, "two_row_trailing")
        # biru[2][102] is indexed from 1 and the scan loops also inspect i + 1.
        if not 1 <= count <= 100 or cursor + 2 * count > len(values):
            return False, "two_row_count"
        rows = values[cursor : cursor + 2 * count]
        if any(value not in (0, 1, 2) for value in rows):
            return False, "two_row_value"
        cursor += 2 * count
    return False, "two_row_terminator"


def _validate_two_matrix_batches(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "two_matrix_integer")
    if values is None:
        return False, reason
    cursor = 0
    while cursor < len(values):
        if cursor + 4 > len(values):
            return False, "two_matrix_header"
        rows, cols, width, extras = values[cursor : cursor + 4]
        cursor += 4
        if (rows, cols, width, extras) == (0, 0, 0, 0):
            return (True, "") if cursor == len(values) else (False, "two_matrix_trailing")
        if not (1 <= rows <= 15 and 1 <= cols <= 30 and 0 <= width <= 50 and 0 <= extras <= 5):
            return False, "two_matrix_bounds"
        cell_count = 2 * rows * cols
        if cursor + cell_count > len(values):
            return False, "two_matrix_size"
        first = values[cursor : cursor + rows * cols]
        second = values[cursor + rows * cols : cursor + cell_count]
        # Negative rewards or costs can turn the DP's checked upper bound into
        # an unchecked negative array index.
        if any(value < 0 for value in first) or any(value < 0 for value in second):
            return False, "two_matrix_cell"
        cursor += cell_count
    return False, "two_matrix_terminator"


def _validate_segment_tree_batches(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "segment_tree_integer")
    if values is None:
        return False, reason
    if len(values) < 2:
        return False, "segment_tree_header"
    count, queries = values[0], values[1]
    if not 1 <= count <= 200000 or not 0 <= queries <= 200000:
        return False, "segment_tree_bounds"
    if len(values) != 2 + count + 3 * queries:
        return False, "segment_tree_size"
    cursor = 2 + count
    for _ in range(queries):
        operation, left, right_or_value = values[cursor : cursor + 3]
        cursor += 3
        if operation == 1:
            if not 0 <= left <= right_or_value <= count:
                return False, "segment_tree_query_range"
        elif operation == 0:
            if not 0 <= left < count:
                return False, "segment_tree_update_index"
        else:
            return False, "segment_tree_operation"
    return True, ""


def _validate_interval_query_block(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "interval_query_integer")
    if values is None:
        return False, reason
    if len(values) < 2:
        return False, "interval_query_header"
    length, queries = values[0], values[1]
    if length < 1 or not 1 <= queries <= 16:
        return False, "interval_query_bounds"
    if len(values) != 2 + 2 * queries:
        return False, "interval_query_size"
    for index in range(2, len(values), 2):
        left, right = values[index : index + 2]
        if not 1 <= left <= right <= length:
            return False, "interval_query_range"
    return True, ""


def _validate_counted_integer_batches(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "counted_integer")
    if values is None:
        return False, reason
    cursor = 0
    while cursor < len(values):
        if cursor + 2 > len(values):
            return False, "counted_integer_header"
        count, limit = values[cursor : cursor + 2]
        cursor += 2
        if count == 0:
            return (True, "") if cursor == len(values) else (False, "counted_integer_trailing")
        if not 1 <= count <= 1000 or limit < 0 or cursor + count > len(values):
            return False, "counted_integer_bounds"
        cursor += count
    return False, "counted_integer_terminator"


def _validate_repeated_int(payload: bytes, constraints: Dict[str, Any], *, single: bool = False) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "repeated_int_integer")
    if values is None:
        return False, reason
    if single and len(values) != 1:
        return False, "single_int_count"
    low = int(constraints.get("min", -(2**63)))
    high = int(constraints.get("max", 2**63 - 1))
    if any(not low <= value <= high for value in values):
        return False, "repeated_int_bounds"
    return True, ""


def _validate_repeated_tuple(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    lines = _lines(payload)
    if not lines:
        return False, "repeated_tuple_lines"
    constraints = contract.get("constraints", {})
    fields = constraints.get("fields", 0)
    if isinstance(fields, list):
        # p00016 consumes int, one delimiter byte, int and stops at 0,0.
        saw_terminator = False
        for index, line in enumerate(lines):
            match = re.fullmatch(r"([+-]?\d+)(.)([+-]?\d+)", line)
            if not match or match.group(2).isspace():
                return False, "repeated_tuple_shape"
            left, right = int(match.group(1)), int(match.group(3))
            if (left, right) == (0, 0):
                saw_terminator = index == len(lines) - 1
                break
        return (True, "") if saw_terminator else (False, "repeated_tuple_terminator")
    expected = int(fields)
    for line in lines:
        parts = line.split(",")
        if len(parts) != expected:
            return False, "repeated_tuple_fields"
        try:
            values = [float(part) for part in parts]
        except ValueError:
            return False, "repeated_tuple_number"
        if any(not math.isfinite(value) for value in values):
            return False, "repeated_tuple_finite"
    return True, ""


def _validate_counted_batches(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "counted_batch_integer")
    if values is None:
        return False, reason
    constraints = contract.get("constraints", {})
    fields = int(constraints.get("record_fields", 1))
    minimum = int(constraints.get("n_min", constraints.get("datac_min", 1)))
    maximum = int(constraints.get("n_max", 100000))
    cursor = 0
    while cursor < len(values):
        count = values[cursor]
        cursor += 1
        if count == 0:
            return (True, "") if cursor == len(values) else (False, "counted_batch_trailing")
        if not minimum <= count <= maximum or cursor + count * fields > len(values):
            return False, "counted_batch_size"
        cursor += count * fields
    return False, "counted_batch_terminator"


def _validate_fixed_records(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "fixed_record_integer")
    if values is None:
        return False, reason
    fields = int(contract.get("constraints", {}).get("fields", 1))
    records = int(contract.get("constraints", {}).get("records_per_case", 1))
    cursor = 0
    termination = str(contract.get("termination", ""))
    while cursor < len(values):
        if "all four" in termination:
            if cursor + fields > len(values):
                return False, "fixed_record_header"
            header = values[cursor : cursor + fields]
            if all(value == 0 for value in header):
                return (True, "") if cursor + fields == len(values) else (False, "fixed_record_trailing")
            size = fields * records
        else:
            if values[cursor] == 0:
                return (True, "") if cursor + 1 == len(values) else (False, "fixed_record_trailing")
            size = fields
        if cursor + size > len(values):
            return False, "fixed_record_size"
        cursor += size
    return False, "fixed_record_terminator"


def _validate_tree_edge_batches(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "tree_edge_integer")
    if values is None:
        return False, reason
    cursor = 0
    while cursor < len(values):
        nodes = values[cursor]
        cursor += 1
        if nodes == 0:
            return (True, "") if cursor == len(values) else (False, "tree_edge_trailing")
        if not 2 <= nodes <= 20 or cursor + 3 * (nodes - 1) > len(values):
            return False, "tree_edge_size"
        for _ in range(nodes - 1):
            left, right, weight = values[cursor : cursor + 3]
            cursor += 3
            if not (1 <= left <= nodes and 1 <= right <= nodes and weight > 0):
                return False, "tree_edge_value"
    return False, "tree_edge_terminator"


def _validate_interval_batches(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "interval_batch_integer")
    if values is None:
        return False, reason
    cursor = 0
    while cursor < len(values):
        target = values[cursor]
        cursor += 1
        if target == 0:
            return (True, "") if cursor == len(values) else (False, "interval_batch_trailing")
        if target < 0 or cursor >= len(values):
            return False, "interval_batch_header"
        count = values[cursor]
        cursor += 1
        if count < 0 or cursor + 2 * count > len(values):
            return False, "interval_batch_size"
        for _ in range(count):
            start, finish = values[cursor : cursor + 2]
            cursor += 2
            if finish < start:
                return False, "interval_batch_range"
    return False, "interval_batch_terminator"


def _validate_range_marking_block(payload: bytes) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "range_marking_integer")
    if values is None:
        return False, reason
    if len(values) < 3:
        return False, "range_marking_header"
    begin, end, count = values[:3]
    if not (0 <= begin < end <= 10000 and 0 <= count <= 10000):
        return False, "range_marking_bounds"
    if len(values) != 3 + 2 * count:
        return False, "range_marking_size"
    for index in range(3, len(values), 2):
        left, right = values[index : index + 2]
        if not 0 <= left <= right <= 10000:
            return False, "range_marking_range"
    return True, ""


def _validate_dimension_batches(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "dimension_batch_integer")
    if values is None or len(values) % 2:
        return False, reason or "dimension_batch_fields"
    constraints = contract.get("constraints", {})
    for index in range(0, len(values), 2):
        width, height = values[index : index + 2]
        if (width, height) == (0, 0):
            return (True, "") if index + 2 == len(values) else (False, "dimension_batch_trailing")
        if not (int(constraints.get("w_min", 1)) <= width <= int(constraints.get("w_max", 128)) and
                int(constraints.get("h_min", 1)) <= height <= int(constraints.get("h_max", 128))):
            return False, "dimension_batch_bounds"
    return False, "dimension_batch_terminator"


def _validate_browser_event_batches(payload: bytes) -> Tuple[bool, str]:
    tokens = payload.split()
    cursor = 0

    def integer() -> Optional[int]:
        nonlocal cursor
        if cursor >= len(tokens) or not _INT_RE.fullmatch(tokens[cursor]):
            return None
        value = int(tokens[cursor])
        cursor += 1
        return value

    while cursor < len(tokens):
        pages = integer()
        if pages is None:
            return False, "browser_page_count"
        if pages == 0:
            return (True, "") if cursor == len(tokens) else (False, "browser_trailing")
        width, height = integer(), integer()
        if not 1 <= pages <= 100 or width is None or height is None or width <= 0 or height <= 0:
            return False, "browser_dimensions"
        names: set[bytes] = set()
        links: List[bytes] = []
        for _ in range(pages):
            if cursor >= len(tokens) or len(tokens[cursor]) > 20:
                return False, "browser_page_name"
            names.add(tokens[cursor])
            cursor += 1
            buttons = integer()
            if buttons is None or not 0 <= buttons <= 100:
                return False, "browser_button_count"
            for _ in range(buttons):
                x1, y1, x2, y2 = integer(), integer(), integer(), integer()
                if None in (x1, y1, x2, y2) or cursor >= len(tokens) or len(tokens[cursor]) > 20:
                    return False, "browser_button_shape"
                if not (0 <= x1 <= x2 <= width and 0 <= y1 <= y2 <= height):
                    return False, "browser_button_bounds"
                links.append(tokens[cursor])
                cursor += 1
        if any(link not in names for link in links):
            return False, "browser_unknown_link"
        commands = integer()
        if commands is None or not 0 <= commands < 100000:
            return False, "browser_command_count"
        for _ in range(commands):
            if cursor >= len(tokens) or tokens[cursor] not in {b"click", b"back", b"forward", b"show"}:
                return False, "browser_command"
            command = tokens[cursor]
            cursor += 1
            if command == b"click":
                x, y = integer(), integer()
                if x is None or y is None or not (0 <= x <= width and 0 <= y <= height):
                    return False, "browser_click"
    return False, "browser_terminator"


def _validate_word_pair_cases(payload: bytes) -> Tuple[bool, str]:
    tokens = payload.split()
    cursor = 0
    while cursor < len(tokens):
        if tokens[cursor] == b"#":
            return (True, "") if cursor + 1 == len(tokens) else (False, "word_pair_trailing")
        if cursor + 6 > len(tokens):
            return False, "word_pair_size"
        first, second = tokens[cursor], tokens[cursor + 1]
        flags = tokens[cursor + 2 : cursor + 6]
        if not first or not second or any(not _INT_RE.fullmatch(flag) for flag in flags):
            return False, "word_pair_fields"
        cursor += 6
    return False, "word_pair_terminator"


def _validate_triangular_integer_stream(payload: bytes) -> Tuple[bool, str]:
    lines = _lines(payload)
    if not lines or len(lines) % 2 == 0:
        return False, "triangular_integer_rows"
    peak = len(lines) // 2 + 1
    expected = list(range(1, peak + 1)) + list(range(peak - 1, 0, -1))
    for line, width in zip(lines, expected):
        fields = line.split(",")
        if len(fields) != width or any(not re.fullmatch(r"[+-]?\d+", field) for field in fields):
            return False, "triangular_integer_shape"
    return True, ""


def _case_integer_values(payload: bytes, reason: str) -> Tuple[Optional[List[int]], str]:
    tokens = payload.split()
    if not tokens or any(not _INT_RE.fullmatch(token) for token in tokens):
        return None, reason
    return [int(token) for token in tokens], ""


def _validate_p00788(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    lines = _lines(payload)
    constraints = contract.get("constraints", {})
    if (
        not lines
        or (constraints.get("newline_required") and not payload.endswith(b"\n"))
    ):
        return False, "p00788_lines"

    p_min = int(constraints.get("p_min", 1))
    p_max = int(constraints.get("p_max", 1000))
    n_min = int(constraints.get("n_min", 1))
    n_max = int(constraints.get("n_max", 1000))
    for index, line in enumerate(lines):
        fields = line.split()
        if len(fields) != 2 or any(not re.fullmatch(r"[+-]?\d+", field) for field in fields):
            return False, "p00788_pair"
        p, n = map(int, fields)
        if (p, n) == (0, 0):
            return (True, "") if index == len(lines) - 1 else (False, "p00788_trailing")
        if not (p_min <= p <= p_max and n_min <= n <= n_max and p <= n):
            return False, "p00788_bounds"
    return False, "p00788_terminator"


def _validate_p02788(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    values, reason = _case_integer_values(payload, "p02788_integer")
    if values is None or len(values) < 3:
        return False, reason or "p02788_header"
    constraints = contract.get("constraints", {})
    n, distance, attack = values[:3]
    if not int(constraints.get("n_min", 1)) <= n <= int(
        constraints.get("n_max", 200000)
    ):
        return False, "p02788_count"
    if len(values) != 3 + 2 * n:
        return False, "p02788_size"
    scalar_max = int(constraints.get("scalar_max", 10**9))
    if not (1 <= distance <= scalar_max and 1 <= attack <= scalar_max):
        return False, "p02788_parameters"
    positions = values[3::2]
    health = values[4::2]
    if (
        any(not 0 <= position <= scalar_max for position in positions)
        or len(set(positions)) != n
        or any(not 1 <= value <= scalar_max for value in health)
    ):
        return False, "p02788_monsters"
    return True, ""


def _validate_p02814(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    values, reason = _case_integer_values(payload, "p02814_integer")
    if values is None or len(values) < 2:
        return False, reason or "p02814_header"
    constraints = contract.get("constraints", {})
    count, limit = values[:2]
    if not int(constraints.get("n_min", 1)) <= count <= int(
        constraints.get("n_max", 100000)
    ):
        return False, "p02814_count"
    if len(values) != 2 + count:
        return False, "p02814_size"
    scalar_max = int(constraints.get("scalar_max", 10**9))
    if not 1 <= limit <= scalar_max:
        return False, "p02814_limit"
    if any(not 2 <= value <= scalar_max or value % 2 for value in values[2:]):
        return False, "p02814_even_values"
    return True, ""


def _validate_p03142(payload: bytes, contract: Dict[str, Any]) -> Tuple[bool, str]:
    values, reason = _case_integer_values(payload, "p03142_integer")
    if values is None or len(values) < 2:
        return False, reason or "p03142_header"

    constraints = contract.get("constraints", {})
    nodes, extra_edges = values[:2]
    edge_count = nodes + extra_edges - 1
    if (
        not 1 <= nodes <= int(constraints.get("n_max", 115000))
        or extra_edges < 0
        or edge_count < 0
        or edge_count > int(constraints.get("edge_max", 514000))
    ):
        return False, "p03142_bounds"
    if len(values) != 2 + 2 * edge_count:
        return False, "p03142_size"

    adjacency: List[List[int]] = [[] for _ in range(nodes)]
    indegree = [0] * nodes
    seen_edges = set()
    for cursor in range(2, len(values), 2):
        source, destination = values[cursor] - 1, values[cursor + 1] - 1
        edge = (source, destination)
        if (
            not 0 <= source < nodes
            or not 0 <= destination < nodes
            or source == destination
            or edge in seen_edges
        ):
            return False, "p03142_edge"
        seen_edges.add(edge)
        adjacency[source].append(destination)
        indegree[destination] += 1

    roots = [node for node, degree in enumerate(indegree) if degree == 0]
    if len(roots) != 1:
        return False, "p03142_root"
    pending = roots
    visited = 0
    while pending:
        node = pending.pop()
        visited += 1
        for destination in adjacency[node]:
            indegree[destination] -= 1
            if indegree[destination] == 0:
                pending.append(destination)
    if visited != nodes:
        return False, "p03142_dag"
    return True, ""


def _validate_p00165(
    payload: bytes, contract: Dict[str, Any]
) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "p00165_integer")
    if values is None:
        return False, reason
    constraints = contract.get("constraints", {})
    n_min = int(constraints.get("n_min", 1))
    n_max = int(constraints.get("n_max", 1000))
    value_min = int(constraints.get("value_min", 0))
    value_max = int(constraints.get("value_max", 1000000))
    cursor = 0
    while cursor < len(values):
        count = values[cursor]
        cursor += 1
        if count == 0:
            return (True, "") if cursor == len(values) else (
                False,
                "p00165_trailing",
            )
        if not n_min <= count <= n_max:
            return False, "p00165_count"
        end = cursor + count * 2
        if end > len(values):
            return False, "p00165_size"
        if any(
            not value_min <= value <= value_max
            for value in values[cursor:end]
        ):
            return False, "p00165_value"
        cursor = end
    return False, "p00165_terminator"


def _validate_p00793(
    payload: bytes, contract: Dict[str, Any]
) -> Tuple[bool, str]:
    tokens = payload.split()
    if not tokens or len(tokens) % 6 or any(
        not _INT_RE.fullmatch(token) for token in tokens
    ):
        return False, "p00793_shape"
    records = [
        tuple(int(token) for token in tokens[index : index + 6])
        for index in range(0, len(tokens), 6)
    ]
    if records[-1] != (0, 0, 0, 0, 0, 0):
        return False, "p00793_terminator"
    coordinate_min = int(
        contract.get("constraints", {}).get("coordinate_min", 1)
    )
    coordinate_max = int(
        contract.get("constraints", {}).get("coordinate_max", 9999)
    )
    for record in records[:-1]:
        if any(
            not coordinate_min <= value <= coordinate_max
            for value in record
        ):
            return False, "p00793_coordinate"
        points = {
            (record[0], record[1]),
            (record[2], record[3]),
            (record[4], record[5]),
        }
        if len(points) != 3:
            return False, "p00793_distinct_points"
    return True, ""


def _validate_p01296(
    payload: bytes, contract: Dict[str, Any]
) -> Tuple[bool, str]:
    if not payload.endswith(b"\n"):
        return False, "p01296_newline"
    try:
        lines = payload.decode("ascii").splitlines()
    except UnicodeDecodeError:
        return False, "p01296_ascii"
    constraints = contract.get("constraints", {})
    n_max = int(constraints.get("n_max", 20025))
    coordinate_max = int(constraints.get("coordinate_max", 1000000000))
    cursor = 0
    while cursor < len(lines):
        if not re.fullmatch(r"\d+", lines[cursor]):
            return False, "p01296_count"
        count = int(lines[cursor])
        cursor += 1
        if count == 0:
            return (True, "") if cursor == len(lines) else (
                False,
                "p01296_trailing",
            )
        if not 1 <= count <= n_max or cursor + count > len(lines):
            return False, "p01296_size"
        for line in lines[cursor : cursor + count]:
            match = re.fullmatch(r"(\d+) (\d+) ([xy])", line)
            if not match:
                return False, "p01296_record"
            if int(match.group(1)) > coordinate_max or int(
                match.group(2)
            ) > coordinate_max:
                return False, "p01296_coordinate"
        cursor += count
    return False, "p01296_terminator"


def _validate_p01315(
    payload: bytes, contract: Dict[str, Any]
) -> Tuple[bool, str]:
    tokens = payload.split()
    if not tokens:
        return False, "p01315_empty"
    constraints = contract.get("constraints", {})
    n_max = int(constraints.get("n_max", 50))
    name_max = int(constraints.get("name_max", 20))
    value_min = int(constraints.get("value_min", 0))
    value_max = int(constraints.get("value_max", 1000000))
    cursor = 0
    while cursor < len(tokens):
        if not _INT_RE.fullmatch(tokens[cursor]):
            return False, "p01315_count"
        count = int(tokens[cursor])
        cursor += 1
        if count == 0:
            return (True, "") if cursor == len(tokens) else (
                False,
                "p01315_trailing",
            )
        if not 1 <= count <= n_max:
            return False, "p01315_count"
        metrics = []
        for _ in range(count):
            if cursor + 10 > len(tokens):
                return False, "p01315_size"
            name = tokens[cursor]
            numeric_tokens = tokens[cursor + 1 : cursor + 10]
            if (
                not 1 <= len(name) <= name_max
                or any(byte < 33 or byte > 126 for byte in name)
            ):
                return False, "p01315_name"
            if any(
                not _INT_RE.fullmatch(token) for token in numeric_tokens
            ):
                return False, "p01315_integer"
            numeric = [int(token) for token in numeric_tokens]
            if any(
                not value_min <= value <= value_max for value in numeric
            ):
                return False, "p01315_value"
            p, a, b, c, d, e, f, s, m = numeric
            elapsed = a + b + c + (d + e) * m
            income = f * s * m - p
            if (
                not 0 < elapsed <= 2**31 - 1
                or not -(2**31) <= income <= 2**31 - 1
            ):
                return False, "p01315_arithmetic"
            metrics.append((income, elapsed))
            cursor += 10
        if metrics:
            maximum_income = max(abs(income) for income, _ in metrics)
            maximum_elapsed = max(elapsed for _, elapsed in metrics)
            if maximum_income * maximum_elapsed > 2**63 - 1:
                return False, "p01315_comparison_overflow"
    return False, "p01315_terminator"


def _validate_p02029(
    payload: bytes, contract: Dict[str, Any]
) -> Tuple[bool, str]:
    values, reason = _integer_values(payload, "p02029_integer")
    if values is None or len(values) < 2:
        return False, reason or "p02029_header"
    constraints = contract.get("constraints", {})
    header_fields = constraints.get("header_fields", [{}, {}])
    count, queries = values[:2]
    if (
        not int(header_fields[0].get("min", 1))
        <= count
        <= int(header_fields[0].get("max", 100000))
        or not int(header_fields[1].get("min", 1))
        <= queries
        <= int(header_fields[1].get("max", 100000))
    ):
        return False, "p02029_header"
    if len(values) != 2 + 2 * count + 2 * queries:
        return False, "p02029_size"
    value_min = int(constraints.get("min", 0))
    value_max = int(constraints.get("max", 1000000000))
    if any(
        not value_min <= value <= value_max for value in values[2:]
    ):
        return False, "p02029_value"
    positions = values[2 : 2 + 2 * count : 2]
    if any(left > right for left, right in zip(positions, positions[1:])):
        return False, "p02029_position_order"
    return True, ""


_CASE_VALIDATORS = {
    "p00165": _validate_p00165,
    "p00793": _validate_p00793,
    "p00788": _validate_p00788,
    "p01296": _validate_p01296,
    "p01315": _validate_p01315,
    "p02029": _validate_p02029,
    "p02788": _validate_p02788,
    "p02814": _validate_p02814,
    "p03142": _validate_p03142,
}


def validate_contract_payload(
    contract: Dict[str, Any], payload: bytes, seed_inputs: Optional[List[bytes]] = None
) -> Tuple[bool, str]:
    """Validate a payload against explicit grammar plus its seed layout."""
    if not payload:
        return False, "empty_payload"
    if b"\x00" in payload:
        return False, "embedded_nul"
    valid, reason = _validate_scanf_completeness(payload, contract)
    if not valid:
        return False, reason
    kind = contract.get("kind", "")
    constraints = contract.get("constraints", {})
    case_validator = _CASE_VALIDATORS.get(str(contract.get("case_id", "")))
    if case_validator is not None:
        return case_validator(payload, contract)

    if kind == "board_stream":
        return _validate_board_stream(payload, contract)
    if kind == "primitive_modulus_stream":
        return _validate_primitive_modulus_stream(payload, contract)
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
    if kind == "rule_packet_batches":
        return _validate_rule_packet_batches(payload, contract)
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
    if kind == "counted_long_list":
        tokens = payload.split()
        if not tokens or any(not _INT_RE.fullmatch(token) for token in tokens):
            return False, "counted_long_list_integer"
        minimum = int(constraints.get("n_min", 0))
        maximum = int(constraints.get("n_max", 2**31 - 1))
        values_per_count = int(constraints.get("values_per_count", 1))
        count_offset = int(constraints.get("count_offset", 0))
        if "n=0" not in str(contract.get("termination", "")):
            count = int(tokens[0])
            if count < minimum or count > maximum:
                return False, "counted_long_list_count"
            if len(tokens) != 1 + count * values_per_count + count_offset:
                return False, "counted_long_list_size"
            if "value_min" in constraints or "value_max" in constraints:
                value_min = int(constraints.get("value_min", -(2**63)))
                value_max = int(constraints.get("value_max", 2**63 - 1))
                data_tokens = tokens[1 + count_offset :]
                if any(
                    not value_min <= int(token) <= value_max
                    for token in data_tokens
                ):
                    return False, "counted_long_list_value_bounds"
            return True, ""
        cursor = 0
        while cursor < len(tokens):
            count = int(tokens[cursor])
            cursor += 1
            if count == 0:
                return (True, "") if cursor == len(tokens) else (
                    False,
                    "counted_long_list_trailing",
                )
            if count < minimum or count > maximum:
                return False, "counted_long_list_count"
            record_end = cursor + count * values_per_count + count_offset
            if record_end > len(tokens):
                return False, "counted_long_list_size"
            if "value_min" in constraints or "value_max" in constraints:
                value_min = int(constraints.get("value_min", -(2**63)))
                value_max = int(constraints.get("value_max", 2**63 - 1))
                data_tokens = tokens[cursor + count_offset : record_end]
                if any(
                    not value_min <= int(token) <= value_max
                    for token in data_tokens
                ):
                    return False, "counted_long_list_value_bounds"
            cursor = record_end
        return False, "counted_long_list_terminator"
    if kind == "dimension_expression_batches":
        return _validate_dimension_expression_batches(payload)
    if kind == "graph_query_batches":
        return _validate_graph_query_batches(payload)
    if kind == "three_group_block":
        return _validate_three_group_block(payload)
    if kind == "header_and_list":
        return _validate_header_and_list(payload)
    if kind == "fixed_vector_block":
        return _validate_fixed_vector_block(payload)
    if kind == "weighted_graph_batches":
        return _validate_weighted_graph_batches(payload)
    if kind == "slim_span_batches":
        return _validate_slim_span_batches(payload)
    if kind == "bit_vectors":
        return _validate_bit_vectors(payload)
    if kind == "circle_batches":
        return _validate_circle_batches(payload)
    if kind == "two_row_integer_batches":
        return _validate_two_row_integer_batches(payload)
    if kind == "two_matrix_batches":
        return _validate_two_matrix_batches(payload)
    if kind == "segment_tree_batches":
        return _validate_segment_tree_batches(payload)
    if kind == "interval_query_block":
        return _validate_interval_query_block(payload)
    if kind == "counted_integer_batches":
        return _validate_counted_integer_batches(payload)
    if kind == "repeated_int":
        return _validate_repeated_int(payload, constraints)
    if kind == "single_int":
        return _validate_repeated_int(payload, constraints, single=True)
    if kind == "repeated_tuple":
        return _validate_repeated_tuple(payload, contract)
    if kind == "counted_batches":
        return _validate_counted_batches(payload, contract)
    if kind == "fixed_records_until_sentinel":
        return _validate_fixed_records(payload, contract)
    if kind == "tree_edge_batches":
        return _validate_tree_edge_batches(payload)
    if kind == "interval_batches":
        return _validate_interval_batches(payload)
    if kind == "range_marking_block":
        return _validate_range_marking_block(payload)
    if kind == "dimension_batches":
        return _validate_dimension_batches(payload, contract)
    if kind == "browser_event_batches":
        return _validate_browser_event_batches(payload)
    if kind == "word_pair_cases":
        return _validate_word_pair_cases(payload)
    if kind == "triangular_integer_stream":
        return _validate_triangular_integer_stream(payload)
    if kind == "fixed_tuple_block":
        values, reason = _integer_values(payload, "fixed_tuple_integer")
        records = int(constraints.get("records", 1))
        fields = int(constraints.get("fields", 1))
        if values is None or len(values) != records * fields:
            return False, reason or "fixed_tuple_size"
        return True, ""
    if kind == "line_variable_arity":
        lines = _lines(payload)
        if not lines:
            return False, "line_variable_rows"
        for line in lines:
            fields = line.split()
            if len(fields) < int(constraints.get("min_values", 1)) + 1 or len(fields) > 1001:
                return False, "line_variable_arity"
            if any(not re.fullmatch(r"[+-]?\d+", field) for field in fields):
                return False, "line_variable_integer"
        return True, ""
    if kind == "encoded_line_stream":
        lines = payload.splitlines()
        if not lines or (constraints.get("newline_required") and not payload.endswith(b"\n")):
            return False, "encoded_line_newline"
        maximum = int(constraints.get("max_line_length", 9999))
        if any(not line or len(line) > maximum or any(byte < 32 or byte > 126 for byte in line) for line in lines):
            return False, "encoded_line_shape"
        return True, ""
    if kind == "sentinel_int_lines":
        lines = _lines(payload)
        if not lines or lines[-1] != "0":
            return False, "sentinel_int_terminator"
        if any(not re.fullmatch(r"[1-9]\d*", line) for line in lines[:-1]):
            return False, "sentinel_int_line"
        maximum = int(constraints.get("max", 50000))
        if any(int(line) > maximum for line in lines[:-1]):
            return False, "sentinel_int_bounds"
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
    mutation = str(contract.get("mutation", ""))
    preserve_counts = "preserve_counts" in mutation
    preserve_leading_count = "preserve_count" in mutation
    termination = str(contract.get("termination", ""))
    lines = seed.splitlines(keepends=True)
    protected = set()
    if preserve_leading_count and contract.get("kind") == "counted_long_list":
        constraints = contract.get("constraints", {})
        values_per_count = int(constraints.get("values_per_count", 1))
        count_offset = int(constraints.get("count_offset", 0))
        cursor = 0
        while cursor < len(matches):
            if not _INT_RE.fullmatch(matches[cursor].group(0)):
                break
            protected.add(cursor)
            count = int(matches[cursor].group(0))
            cursor += 1
            if count == 0:
                break
            cursor += count * values_per_count + count_offset
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
            elif (
                preserve_leading_count
                and contract.get("kind") == "counted_long_list"
                and absolute == 0
            ):
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
            for _ in range(10):
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
    if kind == "primitive_modulus_stream":
        return _mutate_numeric(seed, contract)
    if kind == "rule_packet_batches":
        return _mutate_rule_packet_batches(seed, contract)
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
    if kind == "encoded_line_stream":
        lines = seed.splitlines(keepends=True)
        op = random.choice(["mutate_char", "mutate_num", "add_line"])
        if op == "add_line":
            new_val = str(random.randint(0, 100000)).encode() + b"\n"
            idx = random.randint(0, len(lines))
            lines.insert(idx, new_val)
            return b"".join(lines)
        if op == "mutate_char" and lines:
            line_idx = random.randrange(len(lines))
            line = lines[line_idx]
            if line:
                char_idx = random.randrange(len(line))
                if line[char_idx:char_idx+1] != b"\n":
                    new_char = bytes([random.randint(32, 126)])
                    lines[line_idx] = line[:char_idx] + new_char + line[char_idx+1:]
                    return b"".join(lines)
        return _mutate_characters(seed, contract)
    if kind in {
        "layered_grid_block",
        "triangular_string_matrix",
        "repeated_token",
        "word_batches",
        "word_pair_cases",
        "named_edge_query_batches",
    } or any(
        marker in mutation for marker in ("cells_only", "characters_only", "strings_only", "names_and_counts", "alphabet_only", "token_value_only")
    ):
        return _mutate_characters(seed, contract)
    return _mutate_numeric(seed, contract)


def _random_valid_case_payload(contract: Dict[str, Any]) -> Optional[bytes]:
    case_id = str(contract.get("case_id", ""))
    constraints = contract.get("constraints", {})
    if case_id == "p00165":
        output = []
        for _ in range(random.randint(1, 3)):
            count = random.randint(
                int(constraints.get("n_min", 1)),
                min(int(constraints.get("n_max", 1000)), 8),
            )
            output.append(str(count))
            for _ in range(count):
                output.append(
                    f"{random.randint(2, 1000000)} "
                    f"{random.randint(0, 1000000)}"
                )
        output.append("0")
        return ("\n".join(output) + "\n").encode()
    if case_id == "p00793":
        output = []
        for _ in range(random.randint(1, 4)):
            points = set()
            while len(points) < 3:
                points.add(
                    (
                        random.randint(1, 9999),
                        random.randint(1, 9999),
                    )
                )
            output.append(
                " ".join(
                    str(coordinate)
                    for point in points
                    for coordinate in point
                )
            )
        output.append("0 0 0 0 0 0")
        return ("\n".join(output) + "\n").encode()
    if case_id == "p00788":
        pairs = []
        for _ in range(random.randint(1, 5)):
            n = random.randint(
                int(constraints.get("n_min", 1)),
                int(constraints.get("n_max", 1000)),
            )
            p = random.randint(
                int(constraints.get("p_min", 1)),
                min(int(constraints.get("p_max", 1000)), n),
            )
            pairs.append((p, n))
        return ("\n".join(f"{p} {n}" for p, n in pairs) + "\n0 0\n").encode()
    if case_id == "p01296":
        output = []
        for _ in range(random.randint(1, 3)):
            count = random.randint(1, 10)
            output.append(str(count))
            output.extend(
                f"{random.randint(0, 1000)} "
                f"{random.randint(0, 1000)} "
                f"{random.choice('xy')}"
                for _ in range(count)
            )
        output.append("0")
        return ("\n".join(output) + "\n").encode()
    if case_id == "p01315":
        output = []
        for batch in range(random.randint(1, 3)):
            count = random.randint(1, 5)
            output.append(str(count))
            for record in range(count):
                name = f"item{batch}_{record}_{random.randint(0, 9999)}"
                numeric = [random.randint(1, 20) for _ in range(9)]
                output.append(
                    f"{name} " + " ".join(map(str, numeric))
                )
        output.append("0")
        return ("\n".join(output) + "\n").encode()
    if case_id == "p02029":
        count = random.randint(1, 12)
        queries = random.randint(1, 8)
        positions = sorted(random.sample(range(1, 1001), count))
        output = [f"{count} {queries}"]
        output.extend(
            f"{position} {random.randint(0, 1000)}"
            for position in positions
        )
        output.extend(
            f"{random.randint(0, 1200)} {random.randint(1, count)}"
            for _ in range(queries)
        )
        return ("\n".join(output) + "\n").encode()
    if case_id == "p02788":
        count = random.randint(1, 20)
        scalar_max = int(constraints.get("scalar_max", 10**9))
        distance = random.randint(1, scalar_max)
        attack = random.randint(1, scalar_max)
        positions = random.sample(range(0, max(100, count * 10)), count)
        output = [f"{count} {distance} {attack}"]
        output.extend(
            f"{position} {random.randint(1, scalar_max)}" for position in positions
        )
        return ("\n".join(output) + "\n").encode()
    if case_id == "p02814":
        count = random.randint(1, 20)
        scalar_max = int(constraints.get("scalar_max", 10**9))
        limit = random.randint(1, scalar_max)
        values = [2 * random.randint(1, scalar_max // 2) for _ in range(count)]
        return (f"{count} {limit}\n" + " ".join(map(str, values)) + "\n").encode()
    if case_id == "p03142":
        nodes = random.randint(3, 12)
        chain = {(node, node + 1) for node in range(1, nodes)}
        available = [
            (source, destination)
            for source in range(1, nodes + 1)
            for destination in range(source + 1, nodes + 1)
            if (source, destination) not in chain
        ]
        extra_edges = random.randint(0, min(12, len(available)))
        edges = list(chain)
        edges.extend(random.sample(available, extra_edges))
        random.shuffle(edges)
        output = [f"{nodes} {extra_edges}"]
        output.extend(f"{source} {destination}" for source, destination in edges)
        return ("\n".join(output) + "\n").encode()
    return None


def _random_valid_payload(contract: Dict[str, Any]) -> Optional[bytes]:
    """Create a fresh valid instance for contracts whose seed shape is finite."""
    kind = contract.get("kind", "")
    constraints = contract.get("constraints", {})
    case_payload = _random_valid_case_payload(contract)
    if case_payload is not None:
        return case_payload
    if kind == "board_stream":
        boards = random.randint(int(constraints.get("min_boards", 1)), int(constraints.get("max_boards", 4)))
        alphabet = str(constraints.get("alphabet", "bw+"))
        rows = ["".join(random.choice(alphabet) for _ in range(int(constraints.get("cols", 3)))) for _ in range(boards * int(constraints.get("rows", 3)))]
        return ("\n".join(rows) + "\n0\n").encode()
    if kind == "primitive_modulus_stream":
        p_min = int(constraints.get("p_min", 2))
        p_max = int(constraints.get("p_max", 2999))
        value_min = int(constraints.get("value_min", 0))
        value_max = int(constraints.get("value_max", 2998))
        while True:
            p = random.randint(p_min, p_max)
            if not bool(constraints.get("prime", False)) or _is_prime(p):
                break
        values = [random.randint(value_min, value_max) for _ in range(p - 1)]
        b0 = random.randint(value_min, value_max)
        return (f"{p} {b0}\n" + " ".join(map(str, values)) + "\n").encode()
    if kind == "rule_packet_batches":
        rule_num = random.randint(1, 4)
        packet_num = random.randint(0, 6)
        address_choices = "0123456789abcdef?xXyY"
        message_alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?_-"
        output: List[str] = [f"{rule_num} {packet_num}"]
        for _ in range(rule_num):
            action = random.choice(["permit", "deny"])
            source = "".join(random.choice(address_choices) for _ in range(8))
            destination = "".join(random.choice(address_choices) for _ in range(8))
            output.append(f"{action} {source} {destination}")
        for _ in range(packet_num):
            source = "".join(random.choice(address_choices) for _ in range(8))
            destination = "".join(random.choice(address_choices) for _ in range(8))
            message = "".join(random.choice(message_alphabet) for _ in range(random.randint(1, 12)))
            output.append(f"{source} {destination} {message}")
        output.append("0 0")
        return ("\n".join(output) + "\n").encode()
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
    if kind == "bit_vectors":
        n = random.randint(1, 15)
        runs = random.randint(1, n)
        cuts = sorted(random.sample(range(1, n), runs - 1))
        endpoints = [0, *cuts, n]
        targets = [endpoints[index + 1] - endpoints[index] for index in range(runs)]
        bits = [random.randint(0, 1) for _ in range(n)]
        return (
            f"{n} {runs}\n"
            + " ".join(map(str, bits))
            + "\n"
            + " ".join(map(str, targets))
            + "\n"
        ).encode()
    if kind == "sentinel_int_lines":
        maximum = int(constraints.get("max", 50000))
        count = random.randint(1, 4)
        return ("\n".join(str(random.randint(1, maximum)) for _ in range(count)) + "\n0\n").encode()
    if kind == "three_group_block":
        n = random.randint(1, 100)
        output = [str(n)]
        for _ in range(3):
            count = random.randint(0, min(n, 12))
            members = [random.randint(1, n) for _ in range(count)]
            output.append(" ".join(map(str, [count, *members])))
        return ("\n".join(output) + "\n").encode()
    if kind == "header_and_list":
        length = random.randint(1, 10000)
        n = random.randint(0, min(length, 20))
        header = [n, random.randint(0, 20), random.randint(0, 20),
                  random.randint(1, 100), random.randint(1, 100), length]
        positions = [random.randint(1, length) for _ in range(n)]
        return (" ".join(map(str, header)) + "\n" + " ".join(map(str, positions)) + "\n").encode()
    if kind == "fixed_vector_block":
        target = random.randint(1, 500)
        prices = [random.randint(0, 10000) for _ in range(4)]
        max_amount = 505 - target
        amounts = [random.randint(1, max_amount) for _ in range(4)]
        return (
            f"{target}\n"
            + " ".join(map(str, prices))
            + "\n"
            + " ".join(map(str, amounts))
            + "\n"
        ).encode()
    if kind == "graph_query_batches":
        nodes = random.randint(1, 12)
        edges = random.randint(0, min(20, nodes * nodes))
        output = [f"{edges} {nodes}"]
        for _ in range(edges):
            output.append(
                f"{random.randint(1, nodes)} {random.randint(1, nodes)} "
                f"{random.randint(0, 10000)} {random.randint(0, 10000)}"
            )
        queries = random.randint(0, 10)
        output.append(str(queries))
        for _ in range(queries):
            output.append(
                f"{random.randint(1, nodes)} {random.randint(1, nodes)} {random.randint(0, 1)}"
            )
        output.append("0 0")
        return ("\n".join(output) + "\n").encode()
    if kind == "weighted_graph_batches":
        cities = random.randint(1, 12)
        edges = random.randint(0, min(20, cities * cities))
        output = [
            f"{random.randint(1, 9)} {cities} {edges} "
            f"{random.randint(1, cities)} {random.randint(1, cities)}"
        ]
        for _ in range(edges):
            output.append(
                f"{random.randint(1, cities)} {random.randint(1, cities)} {random.randint(0, 100000)}"
            )
        output.append("0 0 0 0 0")
        return ("\n".join(output) + "\n").encode()
    if kind == "slim_span_batches":
        nodes = random.randint(2, 12)
        edges = random.randint(0, min(20, nodes * (nodes - 1) // 2))
        output = [f"{nodes} {edges}"]
        for _ in range(edges):
            output.append(
                f"{random.randint(1, nodes)} {random.randint(1, nodes)} "
                f"{random.randint(0, 100000)}"
            )
        output.append("0 0")
        return ("\n".join(output) + "\n").encode()
    if kind == "two_row_integer_batches":
        count = random.randint(1, 20)
        first = " ".join(str(random.randint(0, 2)) for _ in range(count))
        second = " ".join(str(random.randint(0, 2)) for _ in range(count))
        return f"{count}\n{first}\n{second}\n0\n".encode()
    if kind == "two_matrix_batches":
        rows = random.randint(1, 5)
        cols = random.randint(1, 8)
        width = random.randint(0, 20)
        extras = random.randint(0, 3)
        rewards = [random.randint(0, 10) for _ in range(rows * cols)]
        costs = [random.randint(0, max(1, width)) for _ in range(rows * cols)]
        output = [f"{rows} {cols} {width} {extras}"]
        for row in range(rows):
            output.append(" ".join(map(str, rewards[row * cols : (row + 1) * cols])))
        for row in range(rows):
            output.append(" ".join(map(str, costs[row * cols : (row + 1) * cols])))
        output.append("0 0 0 0")
        return ("\n".join(output) + "\n").encode()
    if kind == "segment_tree_batches":
        count = random.randint(1, 20)
        queries = random.randint(0, 20)
        output = [f"{count} {queries}", " ".join(str(random.randint(-20, 20)) for _ in range(count))]
        for _ in range(queries):
            if random.randint(0, 1):
                left = random.randint(0, count)
                right = random.randint(left, count)
                output.append(f"1 {left} {right}")
            else:
                output.append(f"0 {random.randrange(count)} {random.randint(-20, 20)}")
        return ("\n".join(output) + "\n").encode()
    if kind == "interval_query_block":
        length = random.randint(1, 100)
        queries = random.randint(1, 8)
        output = [f"{length} {queries}"]
        for _ in range(queries):
            left = random.randint(1, length)
            output.append(f"{left} {random.randint(left, length)}")
        return ("\n".join(output) + "\n").encode()
    if kind == "counted_integer_batches":
        count = random.randint(2, 20)
        limit = random.randint(1, 100)
        values = " ".join(str(random.randint(0, limit)) for _ in range(count))
        return f"{count} {limit}\n{values}\n0 0\n".encode()
    if kind == "range_marking_block":
        begin = random.randint(0, 100)
        end = random.randint(begin + 1, min(10000, begin + 100))
        count = random.randint(0, 12)
        output = [f"{begin} {end}", str(count)]
        for _ in range(count):
            left = random.randint(0, 10000)
            output.append(f"{left} {random.randint(left, 10000)}")
        return ("\n".join(output) + "\n").encode()
    if kind == "dimension_batches":
        cases = random.randint(1, 4)
        output = [
            f"{random.randint(int(constraints.get('w_min', 1)), int(constraints.get('w_max', 128)))} "
            f"{random.randint(int(constraints.get('h_min', 1)), int(constraints.get('h_max', 128)))}"
            for _ in range(cases)
        ]
        output.append("0 0")
        return ("\n".join(output) + "\n").encode()
    if kind == "browser_event_batches":
        pages = random.randint(1, 5)
        width, height = random.randint(10, 1000), random.randint(10, 1000)
        names = [f"page{index}" for index in range(pages)]
        output = [str(pages), f"{width} {height}"]
        for name in names:
            buttons = random.randint(0, 3)
            output.append(f"{name} {buttons}")
            for _ in range(buttons):
                x1, y1 = random.randint(0, width), random.randint(0, height)
                x2, y2 = random.randint(x1, width), random.randint(y1, height)
                output.append(f"{x1} {y1} {x2} {y2} {random.choice(names)}")
        commands = random.randint(0, 12)
        output.append(str(commands))
        for _ in range(commands):
            command = random.choice(["click", "back", "forward", "show"])
            if command == "click":
                output.append(f"click {random.randint(0, width)} {random.randint(0, height)}")
            else:
                output.append(command)
        output.append("0")
        return ("\n".join(output) + "\n").encode()
    return None


def _counted_long_list_boundary_payloads(
    contract: Dict[str, Any],
) -> List[bytes]:
    """Build deterministic size probes that value-only mutation cannot reach.

    Count-preserving mutation is useful after a seed has established a valid
    shape, but it otherwise leaves the evaluator blind to behavior that changes
    as the leading count grows.  Keep the probes bounded so they remain cheap
    for every counted-list contract.
    """
    if contract.get("kind") != "counted_long_list":
        return []

    constraints = contract.get("constraints", {})
    minimum = int(constraints.get("n_min", 0))
    maximum = int(constraints.get("n_max", 2**31 - 1))
    values_per_count = int(constraints.get("values_per_count", 1))
    count_offset = int(constraints.get("count_offset", 0))
    if minimum > maximum or values_per_count < 0 or count_offset < 0:
        return []

    counts = sorted(
        {
            count
            for count in (minimum, 1, 2, 4, 8, 16, 64)
            if minimum <= count <= maximum
        }
    )

    value_min = int(
        constraints.get("value_min", constraints.get("min", 0))
    )
    value_max = int(
        constraints.get(
            "value_max",
            constraints.get("max", max(value_min, value_min + 16)),
        )
    )
    if value_min > value_max:
        return []

    even_values = bool(constraints.get("even_values", False))
    first_value = max(value_min, 1) if value_max >= 1 else value_min
    if even_values and first_value % 2:
        first_value += 1
    if first_value > value_max:
        first_value = value_min
        if even_values and first_value % 2:
            first_value += 1
    if first_value > value_max:
        return []

    step = 2 if even_values else 1
    available_steps = max(0, (value_max - first_value) // step)
    cycle = min(8, available_steps + 1)

    scalar_max = int(constraints.get("scalar_max", 2**31 - 1))
    scalar_min = int(constraints.get("scalar_min", 1))
    scalar = min(max(1, scalar_min), scalar_max)
    if count_offset and scalar_min > scalar_max:
        return []

    payloads: List[bytes] = []
    for count in counts:
        data = [
            first_value + step * (index % cycle)
            for index in range(count * values_per_count)
        ]
        tokens = [count, *([scalar] * count_offset), *data]
        if "n=0" in str(contract.get("termination", "")):
            tokens.append(0)
        payloads.append((" ".join(map(str, tokens)) + "\n").encode())
    return payloads


def generate_contract_inputs(
    contract: Dict[str, Any],
    seed_inputs: List[bytes],
    iterations: int,
    *,
    rng_seed: Optional[int] = None,
) -> Tuple[List[bytes], Dict[str, int]]:
    """Generate validated inputs, retaining exact seeds as the first entries.

    ``rng_seed`` gives experiment callers deterministic generation without
    permanently mutating the module-level RNG used by the legacy fuzzer.
    Existing callers that omit it retain the historical behavior.
    """
    previous_random_state = None
    if rng_seed is not None:
        previous_random_state = random.getstate()
        random.seed(int(rng_seed))
    try:
        return _generate_contract_inputs_impl(contract, seed_inputs, iterations)
    finally:
        if previous_random_state is not None:
            random.setstate(previous_random_state)


def _generate_contract_inputs_impl(
    contract: Dict[str, Any], seed_inputs: List[bytes], iterations: int
) -> Tuple[List[bytes], Dict[str, int]]:
    seeds = _dedupe(seed_inputs)
    if iterations <= 0:
        return [], {"accepted": 0, "rejected": 0}
    accepted = []
    rejected = 0
    for seed in seeds:
        valid, _ = validate_contract_payload(contract, seed, seeds)
        if valid and seed not in accepted:
            accepted.append(seed)

    for candidate in _counted_long_list_boundary_payloads(contract):
        if len(accepted) >= iterations:
            break
        if candidate in accepted:
            continue
        valid, _ = validate_contract_payload(contract, candidate, seeds)
        if valid:
            accepted.append(candidate)
        else:
            rejected += 1

    attempts = 0
    max_attempts = max(100, iterations * 100)
    pool = list(accepted or seeds)
    while len(accepted) < iterations and pool and attempts < max_attempts:
        attempts += 1
        candidate = _random_valid_payload(contract)
        if candidate is None:
            seed = random.choice(pool)
            candidate = _mutate_payload(seed, contract)
        if not candidate or candidate in accepted:
            continue
        valid, _ = validate_contract_payload(contract, candidate, seeds)
        if valid:
            accepted.append(candidate)
            if len(pool) < 2000:
                pool.append(candidate)
        else:
            rejected += 1
    return accepted[:iterations], {"accepted": len(accepted), "rejected": rejected}
