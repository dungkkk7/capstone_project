#!/usr/bin/env python3
"""Deterministic LLVM IR to semantic C-like pseudocode.

This module is an evidence renderer, not a source-code recovery oracle.  Its
contract is deliberately narrower and stronger than the former regex script:

* preserve every executable effect (unknown instructions are shown, never
  silently discarded); proven closed pure scaffolds may be folded into one
  helper whose contract states the same computation;
* derive scalar widths, function signatures, and allocation sizes from LLVM
  types instead of inventing ``uint64_t``/4096-byte placeholders;
* make PHI semantics explicit as edge-local parallel copies;
* structure reducible branches and natural loops, including multi-exit loops
  only when every exit has a proven closed linear path to one common join;
* retain LLVM poison-generating arithmetic and GEP guarantees as explicit
  pseudocode annotations instead of folding through them;
* inline exact internal outlined address resolvers only after a whole-body and
  direct-call-use proof; affine variants keep their add/GEP poison guarantees
  in explicit recovered-range profiles;
* emit legal, stable identifiers and parse labels independently of LLVM's
  trailing predecessor comments.

The result is intended for humans and LLM evidence.  Aggregate operations and
unmodelled intrinsics use explicit pseudocode helpers, so the output does not
pretend to be directly compilable C.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import argparse
import re
from typing import Dict, List, Optional, Sequence, Set, Tuple


SSA_RE = r"%[-A-Za-z$._0-9]+"
GLOBAL_RE = r"@[-A-Za-z$._0-9]+"
VALUE_RE = rf"(?:{SSA_RE}|{GLOBAL_RE}|-?\d+|true|false|null|poison|undef|zeroinitializer)"


def split_top_level(text: str, delimiter: str = ",") -> List[str]:
    """Split an LLVM list while respecting (), [], {}, and <> nesting."""
    parts: List[str] = []
    start = 0
    stack: List[str] = []
    pairs = {")": "(", "]": "[", "}": "{", ">": "<"}
    quoted = False
    escaped = False
    for index, char in enumerate(text):
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            continue
        if char == '"':
            quoted = True
        elif char in "([{<":
            stack.append(char)
        elif char in pairs and stack and stack[-1] == pairs[char]:
            stack.pop()
        elif char == delimiter and not stack:
            parts.append(text[start:index].strip())
            start = index + 1
    parts.append(text[start:].strip())
    return [part for part in parts if part]


def sanitize_identifier(token: str, prefix: str = "v") -> str:
    raw = token.lstrip("%@")
    raw = re.sub(r"[^A-Za-z0-9_]", "_", raw)
    raw = re.sub(r"_+", "_", raw).strip("_")
    if not raw:
        raw = prefix
    if raw[0].isdigit():
        raw = prefix + raw
    if raw in {
        "auto", "break", "case", "char", "const", "continue", "default",
        "do", "double", "else", "enum", "extern", "float", "for", "goto",
        "if", "int", "long", "register", "return", "short", "signed",
        "sizeof", "static", "struct", "switch", "typedef", "union",
        "unsigned", "void", "volatile", "while", "true", "false", "bool",
    }:
        raw += "_"
    return raw


def label_name(token: str) -> str:
    return "bb_" + sanitize_identifier(token, "block")


def llvm_string_bytes(encoded: str) -> bytes:
    data = bytearray()
    index = 0
    while index < len(encoded):
        if encoded[index] == "\\" and index + 2 < len(encoded):
            pair = encoded[index + 1:index + 3]
            if re.fullmatch(r"[0-9A-Fa-f]{2}", pair):
                data.append(int(pair, 16))
                index += 3
                continue
        data.extend(encoded[index].encode("utf-8", errors="replace"))
        index += 1
    return bytes(data)


def decode_llvm_string(encoded: str) -> str:
    data = bytearray(llvm_string_bytes(encoded))
    if data.endswith(b"\x00"):
        data.pop()
    out = []
    for byte in data:
        if byte == 10:
            out.append("\\n")
        elif byte == 13:
            out.append("\\r")
        elif byte == 9:
            out.append("\\t")
        elif byte in (34, 92):
            out.append("\\" + chr(byte))
        elif 32 <= byte < 127:
            out.append(chr(byte))
        else:
            out.append(f"\\x{byte:02x}")
    return "".join(out)


def is_c_text_string(encoded: str) -> bool:
    """Prove that an i8 array is text rather than a residual binary image.

    A displayed literal must be a complete NUL-terminated C string with no
    embedded NUL and only printable ASCII or ordinary text whitespace.  This
    is a representation invariant, not a length/name-based heuristic.
    """
    data = llvm_string_bytes(encoded)
    return bool(
        data.endswith(b"\x00")
        and b"\x00" not in data[:-1]
        and all(byte in {9, 10, 13} or 32 <= byte < 127 for byte in data[:-1])
    )


def llvm_type_prefix(text: str) -> Optional[Tuple[str, str]]:
    """Return (LLVM type, remainder) for the leading type in ``text``."""
    text = text.strip()
    if not text:
        return None
    if text.startswith("ptr"):
        match = re.match(r"ptr(?:\s+addrspace\(\d+\))?", text)
        assert match
        return match.group(0), text[match.end():].strip()
    if re.match(r"^(?:void|half|float|double|x86_fp80|fp128|ppc_fp128|label|metadata|token)\b", text):
        token = text.split(None, 1)[0]
        return token, text[len(token):].strip()
    match = re.match(r"i\d+\b", text)
    if match:
        return match.group(0), text[match.end():].strip()
    if text.startswith("%"):
        match = re.match(r"%[-A-Za-z$._0-9]+", text)
        if match:
            return match.group(0), text[match.end():].strip()
    if text[0] in "[{<":
        pairs = {"[": "]", "{": "}", "<": ">"}
        close = pairs[text[0]]
        depth = 0
        for index, char in enumerate(text):
            if char == text[0]:
                depth += 1
            elif char == close:
                depth -= 1
                if depth == 0:
                    return text[:index + 1], text[index + 1:].strip()
    return None


def c_type(llvm_type: str) -> str:
    ty = llvm_type.strip()
    if ty == "void":
        return "void"
    if ty == "i1":
        return "bool"
    match = re.fullmatch(r"i(8|16|32|64|128)", ty)
    if match:
        bits = match.group(1)
        return f"uint{bits}_t" if bits != "128" else "unsigned __int128"
    if ty == "half":
        return "_Float16"
    if ty == "float":
        return "float"
    if ty in {"double", "x86_fp80", "fp128", "ppc_fp128"}:
        return "double" if ty == "double" else "long double"
    if ty.startswith("ptr"):
        return "void *"
    array = re.fullmatch(r"\[\s*(\d+)\s+x\s+(.+)\]", ty)
    if array:
        return f"array<{c_type(array.group(2))}, {array.group(1)}>"
    vector = re.fullmatch(r"<\s*(\d+)\s+x\s+(.+)>", ty)
    if vector:
        return f"vector<{c_type(vector.group(2))}, {vector.group(1)}>"
    if ty.startswith("{") or ty.startswith("<{"):
        inner = ty[2:-2] if ty.startswith("<{") else ty[1:-1]
        return "tuple<" + ", ".join(c_type(x) for x in split_top_level(inner)) + ">"
    if ty.startswith("%"):
        return "struct " + sanitize_identifier(ty, "type")
    return "value"


def type_size_bytes(llvm_type: str) -> Optional[int]:
    match = re.fullmatch(r"i(\d+)", llvm_type.strip())
    if match:
        return max(1, (int(match.group(1)) + 7) // 8)
    if llvm_type.strip() == "ptr":
        return 8
    array = re.fullmatch(r"\[\s*(\d+)\s+x\s+(.+)\]", llvm_type.strip())
    if array:
        element = type_size_bytes(array.group(2))
        return int(array.group(1)) * element if element is not None else None
    return None


def value_expr(token: str) -> str:
    token = token.strip()
    token = re.sub(r",?\s*![-A-Za-z$._0-9]+\s+!\d+.*$", "", token)
    if token.startswith("getelementptr"):
        return render_gep(token) or sanitize_llvm_line(token)
    constant_cast = re.match(
        r"^(ptrtoint|inttoptr|bitcast)\s*\(\s*(.+?)\s+to\s+(.+?)\s*\)$",
        token,
    )
    if constant_cast:
        operation, source, target = constant_cast.groups()
        _source_type, source_value = typed_value(source)
        helper = {
            "ptrtoint": "pointer_to_integer",
            "inttoptr": "integer_to_pointer",
            "bitcast": "bit_cast",
        }[operation]
        return f"{helper}<{c_type(target)}>({source_value})"
    if token.startswith("%"):
        return sanitize_identifier(token)
    if token.startswith("@"):
        return sanitize_identifier(token, "global")
    if token == "null":
        return "NULL"
    if token == "true":
        return "true"
    if token == "false":
        return "false"
    if token in {"poison", "undef"}:
        return f"LLVM_{token.upper()}"
    if token == "zeroinitializer":
        return "ZERO_INITIALIZER"
    return token


def typed_value(text: str) -> Tuple[Optional[str], str]:
    parsed = llvm_type_prefix(text)
    if not parsed:
        return None, value_expr(text)
    ty, rest = parsed
    # Constant expressions are a single value even though their spelling
    # contains nested typed operands.  Scanning their inner tokens backwards
    # would incorrectly collapse a GEP to its base global.
    if rest.startswith(("getelementptr", "ptrtoint", "inttoptr", "bitcast")):
        return ty, value_expr(rest)
    # Drop value attributes without guessing at semantic operands.
    tokens = rest.split()
    for token in reversed(tokens):
        if re.fullmatch(VALUE_RE, token.rstrip(",")):
            return ty, value_expr(token.rstrip(","))
    return ty, value_expr(rest)


@dataclass
class Phi:
    result: str
    llvm_type: str
    incoming: List[Tuple[str, str]]


@dataclass
class Block:
    name: str
    lines: List[str] = field(default_factory=list)
    phis: List[Phi] = field(default_factory=list)


@dataclass
class Function:
    name: str
    return_type: str
    args: List[Tuple[str, str]]
    blocks: List[Block]


@dataclass
class ScalarGlobal:
    name: str
    llvm_type: str
    initializer: Optional[str]
    is_constant: bool
    is_external: bool
    is_alias: bool = False
    is_object_view: bool = False


@dataclass(frozen=True)
class AddressRange:
    global_value: str
    guest_begin: int
    size: int


@dataclass
class AddressResolver:
    address: str
    ranges: List[AddressRange]
    members: Set[str]


@dataclass(frozen=True)
class AffineAddressRange:
    global_value: str
    root_bias: int
    size: int
    add_flags: Tuple[str, ...]
    base_gep_flags: Tuple[str, ...]


@dataclass
class AffineAddressResolver:
    root_index: int
    address_index: int
    ranges: List[AffineAddressRange]
    members: Set[str]


def parse_function_header(line: str) -> Optional[Tuple[str, str, List[Tuple[str, str]]]]:
    at = re.search(r"@([-A-Za-z$._0-9]+)\(", line)
    if not at:
        return None
    name = at.group(1)
    open_paren = line.find("(", at.start())
    depth = 0
    close_paren = None
    for index in range(open_paren, len(line)):
        if line[index] == "(":
            depth += 1
        elif line[index] == ")":
            depth -= 1
            if depth == 0:
                close_paren = index
                break
    if close_paren is None:
        return None

    prefix = line[len("define"):at.start()].strip()
    type_candidates = re.findall(
        r"(?:void|half|float|double|x86_fp80|fp128|ppc_fp128|ptr|i\d+|%[-A-Za-z$._0-9]+|\{[^{}]*\}|<\{[^{}]*\}>)",
        prefix,
    )
    return_type = type_candidates[-1] if type_candidates else "void"
    args: List[Tuple[str, str]] = []
    for index, arg in enumerate(split_top_level(line[open_paren + 1:close_paren])):
        parsed = llvm_type_prefix(arg)
        if not parsed or parsed[0] == "void" or arg.strip() == "...":
            continue
        ty, rest = parsed
        names = re.findall(SSA_RE, rest)
        arg_name = sanitize_identifier(names[-1]) if names else f"arg{index}"
        args.append((ty, arg_name))
    return name, return_type, args


def parse_module(
    text: str,
) -> Tuple[List[Tuple[str, str]], List[ScalarGlobal], List[Function]]:
    strings: List[Tuple[str, str]] = []
    for match in re.finditer(
        r'^@([-A-Za-z$._0-9]+)\s*=.*?constant\s+\[\d+\s+x\s+i8\]\s+c"((?:\\.|[^"\\])*)"',
        text,
        re.M,
    ):
        if is_c_text_string(match.group(2)):
            strings.append((sanitize_identifier("@" + match.group(1), "global"), decode_llvm_string(match.group(2))))

    scalar_globals: List[ScalarGlobal] = []
    for raw in text.splitlines():
        alias_match = re.match(
            r"^@([-A-Za-z$._0-9]+)\s*=\s*(.*?)\balias\s+(.+)$",
            raw.strip(),
        )
        if alias_match:
            name, _attributes, definition = alias_match.groups()
            parsed = llvm_type_prefix(definition)
            if not parsed:
                continue
            llvm_type, _remainder = parsed
            if re.fullmatch(
                r"i\d+|half|float|double|x86_fp80|fp128|ppc_fp128|ptr",
                llvm_type,
            ):
                scalar_globals.append(
                    ScalarGlobal(
                        sanitize_identifier("@" + name, "global"),
                        llvm_type,
                        None,
                        False,
                        True,
                        True,
                        name.startswith("native_object_"),
                    )
                )
            continue
        match = re.match(
            r"^@([-A-Za-z$._0-9]+)\s*=\s*(.*?)\b(global|constant)\s+(.+)$",
            raw.strip(),
        )
        if not match:
            continue
        name, attributes, storage_kind, definition = match.groups()
        parsed = llvm_type_prefix(definition)
        if not parsed:
            continue
        llvm_type, remainder = parsed
        if not re.fullmatch(r"i\d+|half|float|double|x86_fp80|fp128|ppc_fp128|ptr", llvm_type):
            continue
        is_external = bool(re.search(r"\bexternal\b", attributes))
        initializer = None
        if not is_external:
            initializer_text = (
                split_top_level(remainder)[0]
                if remainder
                else "zeroinitializer"
            )
            _initializer_type, initializer = typed_value(
                f"{llvm_type} {initializer_text}"
            )
        scalar_globals.append(
            ScalarGlobal(
                sanitize_identifier("@" + name, "global"),
                llvm_type,
                initializer,
                storage_kind == "constant",
                is_external,
            )
        )

    lines = text.splitlines()
    functions: List[Function] = []
    index = 0
    while index < len(lines):
        header = lines[index].strip()
        if not header.startswith("define "):
            index += 1
            continue
        parsed_header = parse_function_header(header)
        if not parsed_header:
            index += 1
            continue
        name, return_type, args = parsed_header
        index += 1
        blocks: List[Block] = []
        current = Block("entry")
        while index < len(lines) and lines[index].strip() != "}":
            raw = lines[index]
            label = re.match(r"^([-A-Za-z$._0-9]+):(?:\s*;.*)?$", raw.strip())
            if label:
                if current.lines or current.phis or blocks:
                    blocks.append(current)
                current = Block(label.group(1))
            elif raw.strip() and not raw.lstrip().startswith(";"):
                instruction = raw.strip()
                if instruction.startswith("switch ") and "[" in instruction:
                    while not instruction.rstrip().endswith("]") and index + 1 < len(lines):
                        index += 1
                        instruction += " " + lines[index].strip()
                current.lines.append(instruction)
            index += 1
        if current.lines or current.phis or not blocks:
            blocks.append(current)
        functions.append(Function(name, return_type, args, blocks))
        index += 1

    for function in functions:
        for block in function.blocks:
            retained: List[str] = []
            for line in block.lines:
                match = re.match(rf"^({SSA_RE})\s*=\s*phi\s+(.+?)\s+(.+)$", line)
                if not match:
                    retained.append(line)
                    continue
                result = sanitize_identifier(match.group(1))
                llvm_type = match.group(2)
                incoming = []
                for value, pred in re.findall(r"\[\s*(.+?)\s*,\s*%([-A-Za-z$._0-9]+)\s*\]", match.group(3)):
                    incoming.append((value_expr(value), pred))
                block.phis.append(Phi(result, llvm_type, incoming))
            block.lines = retained
    return strings, scalar_globals, functions


class FunctionRenderer:
    def __init__(self, function: Function):
        self.function = function
        self.phi_by_edge: Dict[Tuple[str, str], List[Tuple[str, str]]] = {}
        self.value_types: Dict[str, str] = {name: ty for ty, name in function.args}
        self.raw_ssa_occurrences: Dict[str, int] = {}
        self.ssa_definitions: Dict[str, str] = {}
        self.ssa_definition_blocks: Dict[str, str] = {}
        self.ssa_consumers: Dict[str, Set[str]] = {}
        self.phi_value_uses = {
            value
            for block in function.blocks
            for phi in block.phis
            for value, _predecessor in phi.incoming
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", value)
        }
        for block in function.blocks:
            for line_index, line in enumerate(block.lines):
                assignment = re.match(rf"^({SSA_RE})\s*=\s*(.+)$", line)
                consumer = (
                    assignment.group(1)
                    if assignment
                    else f"#{block.name}:{line_index}"
                )
                use_text = assignment.group(2) if assignment else line
                if assignment:
                    self.ssa_definitions[assignment.group(1)] = assignment.group(2)
                    self.ssa_definition_blocks[assignment.group(1)] = block.name
                for token in re.findall(SSA_RE, use_text):
                    self.ssa_consumers.setdefault(token, set()).add(consumer)
                for token in re.findall(SSA_RE, line):
                    self.raw_ssa_occurrences[token] = (
                        self.raw_ssa_occurrences.get(token, 0) + 1
                    )
        for block in function.blocks:
            for phi in block.phis:
                self.value_types[phi.result] = phi.llvm_type
                for value, predecessor in phi.incoming:
                    self.phi_by_edge.setdefault((predecessor, block.name), []).append((phi.result, value))
        self.address_resolvers = self.find_address_resolvers()
        self.outlined_address_resolvers: Dict[str, AddressResolver] = {}
        self.outlined_affine_address_resolvers: Dict[
            str, AffineAddressResolver
        ] = {}
        self.address_map_names: Dict[Tuple[AddressRange, ...], str] = {}
        self.affine_address_map_names: Dict[
            Tuple[AffineAddressRange, ...], str
        ] = {}
        self.suppressed_resolver_values = {
            member
            for resolver in self.address_resolvers.values()
            for member in resolver.members
            if member not in self.address_resolvers
        }

    @staticmethod
    def raw_typed_value(text: str) -> Optional[Tuple[str, str]]:
        """Parse a scalar typed operand without sanitising its LLVM token."""
        parsed = llvm_type_prefix(text)
        if not parsed:
            return None
        llvm_type, remainder = parsed
        tokens = re.findall(VALUE_RE, remainder)
        if not tokens:
            return None
        return llvm_type, tokens[-1]

    def affine_integer(
        self, token: str, seen: Optional[Set[str]] = None
    ) -> Tuple[str, int, Set[str]]:
        """Return root + constant for a chain of integer add/sub constants."""
        if not token.startswith("%"):
            return token, 0, set()
        seen = set() if seen is None else set(seen)
        if token in seen:
            return token, 0, set()
        seen.add(token)
        rhs = self.ssa_definitions.get(token, "")
        match = re.match(
            r"^(add|sub)((?:\s+(?:nuw|nsw|exact|disjoint))*)\s+(.+)$",
            rhs,
        )
        if not match:
            return token, 0, set()
        if match.group(2).strip():
            return token, 0, set()
        parsed = llvm_type_prefix(match.group(3))
        if not parsed or parsed[0] != "i64":
            return token, 0, set()
        operands = split_top_level(parsed[1])
        if len(operands) != 2 or not re.fullmatch(r"-?\d+", operands[1]):
            return token, 0, set()
        root, constant, members = self.affine_integer(operands[0], seen)
        delta = int(operands[1])
        if match.group(1) == "sub":
            delta = -delta
        return root, constant + delta, members | {token}

    @staticmethod
    def gep_parts(text: str) -> Optional[Tuple[str, str]]:
        """Return the pointer base and sole byte index of an exact i8 GEP."""
        value = text.strip()
        if re.match(
            r"^getelementptr\s+(?:inbounds|nuw|nsw|nusw)\b", value
        ):
            return None
        parenthesized = re.match(
            r"^getelementptr(?:\s+inbounds)?(?:\s+(?:nuw|nsw|nusw))*\s*\((.*)\)$",
            value,
        )
        if parenthesized:
            value = parenthesized.group(1)
        else:
            value = re.sub(
                r"^getelementptr(?:\s+inbounds)?(?:\s+(?:nuw|nsw|nusw))*\s+",
                "",
                value,
            )
        parts = split_top_level(value)
        if len(parts) != 3 or parts[0].strip() != "i8":
            return None
        base = re.match(r"^ptr\s+(.+)$", parts[1])
        index = FunctionRenderer.raw_typed_value(parts[2])
        if not base or not index or index[0] != "i64":
            return None
        return base.group(1).strip(), index[1]

    def affine_pointer(
        self, expression: str, seen: Optional[Set[str]] = None
    ) -> Optional[Tuple[str, Optional[str], int, Set[str]]]:
        """Prove GLOBAL + integer-root + constant for nested byte GEPs."""
        seen = set() if seen is None else set(seen)
        expression = expression.strip()
        members: Set[str] = set()
        if expression.startswith("%"):
            if expression in seen:
                return None
            rhs = self.ssa_definitions.get(expression)
            if rhs is None or not rhs.startswith("getelementptr"):
                return None
            seen.add(expression)
            members.add(expression)
            expression = rhs
        parts = self.gep_parts(expression)
        if not parts:
            return None
        base_expression, index = parts
        if base_expression.startswith("@"):
            global_value = base_expression
            root: Optional[str] = None
            constant = 0
            base_members: Set[str] = set()
        else:
            base = self.affine_pointer(base_expression, seen)
            if not base:
                return None
            global_value, root, constant, base_members = base
        members |= base_members
        if re.fullmatch(r"-?\d+", index):
            constant += int(index)
        else:
            index_root, index_constant, index_members = self.affine_integer(index)
            if root is not None and root != index_root:
                return None
            root = index_root
            constant += index_constant
            members |= index_members
        return global_value, root, constant, members

    def match_address_resolver(self, outer: str) -> Optional[AddressResolver]:
        """Match ordered recovered-range selects ending in an inttoptr fallback."""
        outer_block = self.ssa_definition_blocks.get(outer)
        if outer_block is None:
            return None
        cursor = outer
        pending_ranges: List[
            Tuple[str, str, int, Optional[str], int, int]
        ] = []
        members: Set[str] = set()
        address: Optional[str] = None
        while True:
            rhs = self.ssa_definitions.get(cursor, "")
            selected = re.match(
                rf"^select\s+i1\s+({VALUE_RE}),\s+ptr\s+({VALUE_RE}),"
                rf"\s+ptr\s+({VALUE_RE})$",
                rhs,
            )
            if not selected:
                return None
            condition, mapped_value, fallback = selected.groups()
            if not condition.startswith("%") or not mapped_value.startswith("%"):
                return None
            condition_rhs = self.ssa_definitions.get(condition, "")
            compared = re.match(r"^icmp\s+ult\s+(.+)$", condition_rhs)
            if not compared:
                return None
            parsed = llvm_type_prefix(compared.group(1))
            if not parsed or parsed[0] != "i64":
                return None
            operands = split_top_level(parsed[1])
            if (
                len(operands) != 2
                or not operands[0].startswith("%")
                or not re.fullmatch(r"\d+", operands[1])
                or int(operands[1]) <= 0
            ):
                return None
            offset_root, offset_constant, offset_members = self.affine_integer(
                operands[0]
            )
            pointer = self.affine_pointer(mapped_value)
            if not pointer:
                return None
            global_value, pointer_root, pointer_constant, pointer_members = pointer
            pending_ranges.append(
                (
                    global_value,
                    offset_root,
                    offset_constant,
                    pointer_root,
                    pointer_constant,
                    int(operands[1]),
                )
            )
            members |= offset_members | pointer_members | {condition, cursor}

            fallback_rhs = self.ssa_definitions.get(fallback, "")
            terminal = re.match(r"^inttoptr\s+i64\s+(%[-A-Za-z$._0-9]+)\s+to\s+ptr$", fallback_rhs)
            if terminal:
                address = terminal.group(1)
                members.add(fallback)
                break
            if not fallback.startswith("%") or not fallback_rhs.startswith("select "):
                return None
            cursor = fallback

        assert address is not None
        address_root, address_constant, _ = self.affine_integer(address)
        ranges: List[AddressRange] = []
        for (
            global_value,
            offset_root,
            offset_constant,
            pointer_root,
            pointer_constant,
            size,
        ) in pending_ranges:
            if offset_root != address_root or pointer_root != address_root:
                return None
            guest_begin = address_constant - offset_constant
            if pointer_constant != offset_constant or guest_begin < 0:
                return None
            ranges.append(AddressRange(global_value, guest_begin, size))
        if len(pending_ranges) < 2:
            return None
        ranges = list(dict.fromkeys(ranges))
        if any(
            arm.guest_begin < 0
            or arm.guest_begin >= 1 << 64
            or arm.size > (1 << 64) - arm.guest_begin
            for arm in ranges
        ):
            return None
        if any(self.ssa_definition_blocks.get(member) != outer_block for member in members):
            return None
        phi_uses = self.phi_value_uses
        for member in members - {outer}:
            if sanitize_identifier(member) in phi_uses:
                return None
            if not self.ssa_consumers.get(member, set()) <= members:
                return None
        return AddressResolver(address, ranges, members)

    def find_address_resolvers(self) -> Dict[str, AddressResolver]:
        matches: List[Tuple[str, AddressResolver]] = []
        for lhs, rhs in self.ssa_definitions.items():
            if rhs.startswith("select "):
                match = self.match_address_resolver(lhs)
                if match:
                    matches.append((lhs, match))
        # Prefer the maximal proof when a redundant outer chain contains an
        # otherwise valid inner chain.  The canonical range list may already
        # have deduplicated identical arms, whereas the member set still
        # records the full closed scaffold that can safely disappear.
        matches.sort(key=lambda item: len(item[1].members), reverse=True)
        selected: Dict[str, AddressResolver] = {}
        claimed: Set[str] = set()
        for lhs, resolver in matches:
            if resolver.members & claimed:
                continue
            selected[lhs] = resolver
            claimed |= resolver.members
        return selected

    def complete_outlined_address_resolver(self) -> Optional[AddressResolver]:
        """Return the resolver when this whole function is one exact scaffold.

        This deliberately builds on the same closed-use proof used for inline
        range chains.  Requiring a one-block, one-i64-argument function whose
        every instruction belongs to that proof prevents a helper name or
        attributes from becoming presentation evidence.
        """
        if (
            self.function.return_type != "ptr"
            or len(self.function.args) != 1
            or self.function.args[0][0] != "i64"
            or len(self.function.blocks) != 1
            or self.function.blocks[0].phis
        ):
            return None
        block = self.function.blocks[0]
        if not block.lines:
            return None
        returned = re.fullmatch(rf"ret\s+ptr\s+({SSA_RE})", block.lines[-1])
        if not returned:
            return None
        resolver = self.address_resolvers.get(returned.group(1))
        if (
            resolver is None
            or sanitize_identifier(resolver.address) != self.function.args[0][1]
        ):
            return None
        defined: Set[str] = set()
        for line in block.lines[:-1]:
            assignment = re.match(rf"^({SSA_RE})\s*=\s*.+$", line)
            if not assignment or assignment.group(1) not in resolver.members:
                return None
            defined.add(assignment.group(1))
        return resolver if defined == resolver.members else None

    @staticmethod
    def constant_byte_gep(
        expression: str,
    ) -> Optional[Tuple[str, int, Tuple[str, ...]]]:
        """Parse an exact constant i8 GEP while retaining LLVM guarantees."""
        matched = re.fullmatch(
            r"getelementptr((?:\s+(?:inbounds|nuw|nsw|nusw))*)\s*\((.*)\)",
            expression.strip(),
        )
        if not matched:
            return None
        parts = split_top_level(matched.group(2))
        if len(parts) != 3 or parts[0] != "i8":
            return None
        base = re.fullmatch(rf"ptr\s+({GLOBAL_RE})", parts[1])
        index = FunctionRenderer.raw_typed_value(parts[2])
        if (
            not base
            or not index
            or index[0] != "i64"
            or not re.fullmatch(r"-?\d+", index[1])
        ):
            return None
        return base.group(1), int(index[1]), tuple(matched.group(1).split())

    def complete_outlined_affine_address_resolver(
        self,
    ) -> Optional[AffineAddressResolver]:
        """Match a whole flagged affine resolver without erasing poison rules."""
        function = self.function
        if (
            function.return_type != "ptr"
            or len(function.args) not in {1, 2}
            or any(ty != "i64" for ty, _name in function.args)
            or len(function.blocks) != 1
            or function.blocks[0].phis
        ):
            return None
        block = function.blocks[0]
        if not block.lines:
            return None
        returned = re.fullmatch(rf"ret\s+ptr\s+({SSA_RE})", block.lines[-1])
        if not returned:
            return None
        root_index = 0
        address_index = 0 if len(function.args) == 1 else 1
        root_name = function.args[root_index][1]
        address_name = function.args[address_index][1]

        cursor = returned.group(1)
        members: Set[str] = set()
        ranges: List[AffineAddressRange] = []
        saw_flag = False
        while True:
            selected = re.fullmatch(
                rf"select\s+i1\s+({SSA_RE}),\s+ptr\s+({SSA_RE}),"
                rf"\s+ptr\s+({SSA_RE})",
                self.ssa_definitions.get(cursor, ""),
            )
            if not selected:
                return None
            condition, mapped, fallback = selected.groups()
            compared = re.fullmatch(
                rf"icmp\s+ult\s+i64\s+({SSA_RE}),\s+(\d+)",
                self.ssa_definitions.get(condition, ""),
            )
            if not compared or int(compared.group(2)) <= 0:
                return None
            offset, size_text = compared.groups()
            arithmetic = re.fullmatch(
                rf"(add|sub)((?:\s+(?:nuw|nsw))*)\s+i64\s+"
                rf"({SSA_RE}),\s+(-?\d+)",
                self.ssa_definitions.get(offset, ""),
            )
            if (
                not arithmetic
                or sanitize_identifier(arithmetic.group(3)) != root_name
            ):
                return None
            bias = int(arithmetic.group(4))
            if arithmetic.group(1) == "sub":
                bias = -bias
            add_flags = tuple(arithmetic.group(2).split())
            saw_flag |= bool(add_flags)

            pointer = self.gep_parts(self.ssa_definitions.get(mapped, ""))
            if not pointer:
                return None
            base_expression, pointer_index = pointer
            if pointer_index == offset and base_expression.startswith("@"):
                global_value = base_expression
                base_gep_flags: Tuple[str, ...] = ()
            elif sanitize_identifier(pointer_index) == root_name:
                base = self.constant_byte_gep(base_expression)
                if not base or base[1] != bias:
                    return None
                global_value, _base_bias, base_gep_flags = base
            else:
                return None

            ranges.append(
                AffineAddressRange(
                    global_value,
                    bias,
                    int(size_text),
                    add_flags,
                    base_gep_flags,
                )
            )
            members |= {condition, offset, mapped, cursor}
            terminal = re.fullmatch(
                rf"inttoptr\s+i64\s+({SSA_RE})\s+to\s+ptr",
                self.ssa_definitions.get(fallback, ""),
            )
            if terminal:
                if sanitize_identifier(terminal.group(1)) != address_name:
                    return None
                members.add(fallback)
                break
            if not self.ssa_definitions.get(fallback, "").startswith("select "):
                return None
            cursor = fallback

        # The ordinary one-argument form is represented by AddressResolver.
        # This matcher exists only when some retained LLVM guarantee matters.
        if not saw_flag:
            return None
        for member in members - {returned.group(1)}:
            if not self.ssa_consumers.get(member, set()) <= members:
                return None
        defined: Set[str] = set()
        for line in block.lines[:-1]:
            assignment = re.match(rf"^({SSA_RE})\s*=\s*.+$", line)
            if not assignment or assignment.group(1) not in members:
                return None
            defined.add(assignment.group(1))
        if defined != members:
            return None
        return AffineAddressResolver(
            root_index, address_index, ranges, members
        )

    def edge_transfer(self, source: str, target: str, indent: str) -> List[str]:
        copies = self.phi_by_edge.get((source, target), [])
        if not copies:
            return [f"{indent}goto {label_name(target)};"]
        if len(copies) == 1:
            destination, value = copies[0]
            result = [f"{indent}{destination} = {value};"]
        else:
            destinations = ", ".join(destination for destination, _ in copies)
            values = ", ".join(value for _, value in copies)
            result = [
                f"{indent}({destinations}) = ({values}); "
                "/* simultaneous PHI transfer */"
            ]
        result.append(f"{indent}goto {label_name(target)};")
        return result

    def phi_transfer_only(self, source: str, target: str, indent: str) -> List[str]:
        copies = self.phi_by_edge.get((source, target), [])
        if not copies:
            return []
        if len(copies) == 1:
            destination, value = copies[0]
            return [f"{indent}{destination} = {value};"]
        destinations = ", ".join(destination for destination, _ in copies)
        values = ", ".join(value for _, value in copies)
        return [
            f"{indent}({destinations}) = ({values}); "
            "/* simultaneous PHI transfer */"
        ]

    @staticmethod
    def conditional_branch(block: Block) -> Optional[Tuple[str, str, str]]:
        if not block.lines:
            return None
        match = re.match(
            rf"^br\s+i1\s+({VALUE_RE}),\s+label\s+%([-A-Za-z$._0-9]+),"
            rf"\s+label\s+%([-A-Za-z$._0-9]+)",
            block.lines[-1],
        )
        if not match:
            return None
        return value_expr(match.group(1)), match.group(2), match.group(3)

    @staticmethod
    def unconditional_branch(block: Block) -> Optional[str]:
        if not block.lines:
            return None
        match = re.match(r"^br\s+label\s+%([-A-Za-z$._0-9]+)", block.lines[-1])
        return match.group(1) if match else None

    def render_at(self, line: str, block: Block, indent: str) -> List[str]:
        rendered = self.render_instruction(line, block)
        shifted = []
        for item in rendered:
            shifted.append(indent + item[4:] if item.startswith("    ") else indent + item)
        return shifted

    def render_nested_loop_cfg(self) -> Optional[List[str]]:
        """Structure one exact canonical two-level loop topology.

        The matcher is intentionally all-or-nothing. It handles the common
        post-LLVM shape with an entry guard, an outer PHI header, an inner
        self-loop, an outer latch, and one exit. Any additional block or edge
        keeps the general label/goto evidence renderer in control.
        """
        blocks = {block.name: block for block in self.function.blocks}
        if len(blocks) != 5:
            return None
        entry = self.function.blocks[0]
        entry_branch = self.conditional_branch(entry)
        if not entry_branch:
            return None
        entry_cond, entry_yes, entry_no = entry_branch

        match = None
        for outer_name, exit_name, enters_on_true in (
            (entry_yes, entry_no, True),
            (entry_no, entry_yes, False),
        ):
            outer = blocks.get(outer_name)
            exit_block = blocks.get(exit_name)
            inner_name = self.unconditional_branch(outer) if outer else None
            inner = blocks.get(inner_name) if inner_name else None
            inner_branch = self.conditional_branch(inner) if inner else None
            if not outer or not exit_block or not inner or not inner_branch:
                continue
            inner_cond, inner_yes, inner_no = inner_branch
            if inner_yes == inner_name:
                latch_name, exits_inner_on_true = inner_no, False
            elif inner_no == inner_name:
                latch_name, exits_inner_on_true = inner_yes, True
            else:
                continue
            latch = blocks.get(latch_name)
            latch_branch = self.conditional_branch(latch) if latch else None
            if not latch or not latch_branch:
                continue
            latch_cond, latch_yes, latch_no = latch_branch
            if {latch_yes, latch_no} != {outer_name, exit_name}:
                continue
            exits_outer_on_true = latch_yes == exit_name
            if set(blocks) != {
                entry.name, outer_name, inner_name, latch_name, exit_name
            }:
                continue
            match = (
                outer, inner, latch, exit_block, enters_on_true,
                inner_cond, exits_inner_on_true,
                latch_cond, exits_outer_on_true,
            )
            break
        if not match:
            return None

        (
            outer, inner, latch, exit_block, enters_on_true,
            inner_cond, exits_inner_on_true,
            latch_cond, exits_outer_on_true,
        ) = match
        args = ", ".join(
            f"{c_type(ty)} {name}" for ty, name in self.function.args
        )
        out = [
            f"{c_type(self.function.return_type)} "
            f"{sanitize_identifier('@' + self.function.name, 'function')}({args}) {{"
        ]
        for block in self.function.blocks:
            for phi in block.phis:
                out.append(
                    f"    {c_type(phi.llvm_type)} {phi.result}; "
                    "/* loop-carried value */"
                )
        if any(block.phis for block in self.function.blocks):
            out.append("")

        for line in entry.lines[:-1]:
            out.extend(self.render_at(line, entry, "    "))
        entry_test = entry_cond if enters_on_true else f"!({entry_cond})"
        out.append(f"    if ({entry_test}) {{")
        out.extend(self.phi_transfer_only(entry.name, outer.name, "        "))
        out.append("        while (true) { /* outer recovered loop */")
        for line in outer.lines[:-1]:
            out.extend(self.render_at(line, outer, "            "))
        out.extend(self.phi_transfer_only(outer.name, inner.name, "            "))
        out.append("            while (true) { /* inner recovered loop */")
        for line in inner.lines[:-1]:
            out.extend(self.render_at(line, inner, "                "))
        inner_exit_test = (
            inner_cond if exits_inner_on_true else f"!({inner_cond})"
        )
        out.append(f"                if ({inner_exit_test}) {{")
        out.extend(self.phi_transfer_only(inner.name, latch.name, "                    "))
        out.append("                    break;")
        out.append("                }")
        out.extend(self.phi_transfer_only(inner.name, inner.name, "                "))
        out.append("            }")
        for line in latch.lines[:-1]:
            out.extend(self.render_at(line, latch, "            "))
        outer_exit_test = (
            latch_cond if exits_outer_on_true else f"!({latch_cond})"
        )
        out.append(f"            if ({outer_exit_test}) {{")
        out.extend(self.phi_transfer_only(latch.name, exit_block.name, "                "))
        out.append("                break;")
        out.append("            }")
        out.extend(self.phi_transfer_only(latch.name, outer.name, "            "))
        out.append("        }")
        out.append("    } else {")
        out.extend(self.phi_transfer_only(entry.name, exit_block.name, "        "))
        out.append("    }")
        for line in exit_block.lines:
            out.extend(self.render_at(line, exit_block, "    "))
        out.append("}")
        return out

    def render_reducible_cfg(self) -> Optional[List[str]]:
        """Structure reducible branch/loop CFGs with proof from graph shape.

        This handles natural loops with a conditional header and linear latch
        region, plus acyclic if/else regions joined at their immediate
        post-dominator.  The renderer falls back atomically when any edge is
        outside that model, so unsupported control flow remains explicit.
        """
        if len(self.function.blocks) <= 1:
            return None
        blocks = {block.name: block for block in self.function.blocks}
        successors: Dict[str, List[str]] = {}
        terminal: Dict[str, bool] = {}
        for block in self.function.blocks:
            conditional = self.conditional_branch(block)
            unconditional = self.unconditional_branch(block)
            if conditional:
                successors[block.name] = [conditional[1], conditional[2]]
                terminal[block.name] = False
            elif unconditional:
                successors[block.name] = [unconditional]
                terminal[block.name] = False
            elif block.lines and (
                block.lines[-1].startswith("ret ")
                or block.lines[-1] == "unreachable"
            ):
                successors[block.name] = []
                terminal[block.name] = True
            else:
                return None
            if any(target not in blocks for target in successors[block.name]):
                return None

        entry = self.function.blocks[0].name
        reachable = set()
        pending = [entry]
        while pending:
            name = pending.pop()
            if name in reachable:
                continue
            reachable.add(name)
            pending.extend(successors[name])
        if reachable != set(blocks):
            return None

        predecessors: Dict[str, List[str]] = {name: [] for name in blocks}
        for source, targets in successors.items():
            for target in targets:
                predecessors[target].append(source)

        # Classical dominator/post-dominator fixed points are sufficient for
        # these small presentation CFGs and keep the renderer dependency-free.
        all_nodes = set(blocks)
        dominators: Dict[str, set[str]] = {
            name: ({name} if name == entry else set(all_nodes))
            for name in blocks
        }
        changed = True
        while changed:
            changed = False
            for name in blocks:
                if name == entry:
                    continue
                pred_sets = [dominators[pred] for pred in predecessors[name]]
                updated = {name} | (
                    set.intersection(*pred_sets) if pred_sets else set()
                )
                if updated != dominators[name]:
                    dominators[name] = updated
                    changed = True

        def ends_in_unreachable(start: str) -> bool:
            current = start
            seen_path = set()
            while current not in seen_path:
                seen_path.add(current)
                if terminal[current]:
                    return blocks[current].lines[-1] == "unreachable"
                targets = successors[current]
                if len(targets) != 1:
                    return False
                current = targets[0]
            return False

        # Unreachable error arms do not participate in the normal-return
        # post-dominator tree. Keeping them there makes every preceding guard
        # appear to have no join even though the non-error paths reconverge.
        normal_successors = {
            name: [
                target for target in targets
                if not ends_in_unreachable(target)
            ]
            for name, targets in successors.items()
        }
        normal_reachable = set()
        pending = [entry]
        while pending:
            name = pending.pop()
            if name in normal_reachable:
                continue
            normal_reachable.add(name)
            pending.extend(normal_successors[name])
        exits = {
            name for name in normal_reachable
            if terminal[name] and blocks[name].lines[-1].startswith("ret ")
        }
        if not exits:
            return None
        postdominators: Dict[str, set[str]] = {
            name: (
                {name}
                if name in exits or name not in normal_reachable
                else set(normal_reachable)
            )
            for name in blocks
        }
        changed = True
        while changed:
            changed = False
            for name in normal_reachable:
                if name in exits:
                    continue
                succ_sets = [
                    postdominators[target]
                    for target in normal_successors[name]
                ]
                if not succ_sets:
                    continue
                updated = {name} | set.intersection(*succ_sets)
                if updated != postdominators[name]:
                    postdominators[name] = updated
                    changed = True

        loop_nodes: Dict[str, set[str]] = {}
        for latch, targets in successors.items():
            for header in targets:
                if header not in dominators[latch]:
                    continue
                natural = {header, latch}
                stack = [] if latch == header else [latch]
                while stack:
                    node = stack.pop()
                    for pred in predecessors[node]:
                        if pred not in natural:
                            natural.add(pred)
                            stack.append(pred)
                loop_nodes.setdefault(header, {header}).update(natural)
        # Natural-loop regions must be laminar in a reducible CFG: disjoint or
        # strictly nested.  Partially overlapping regions need node splitting
        # (a Relooper-style transform), which this evidence renderer does not
        # guess at.
        loop_sets = list(loop_nodes.values())
        for index, left in enumerate(loop_sets):
            for right in loop_sets[index + 1:]:
                if left & right and not (left <= right or right <= left):
                    return None

        def immediate_postdominator(name: str) -> Optional[str]:
            candidates = postdominators[name] - {name}
            if not candidates:
                return None
            # The nearest post-dominator has the largest post-dominator set.
            return max(candidates, key=lambda item: len(postdominators[item]))

        def negated(expression: str) -> str:
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", expression):
                return f"!{expression}"
            return f"!({expression})"

        args = ", ".join(
            f"{c_type(ty)} {name}" for ty, name in self.function.args
        )
        out = [
            f"{c_type(self.function.return_type)} "
            f"{sanitize_identifier('@' + self.function.name, 'function')}({args}) {{"
        ]
        for block in self.function.blocks:
            for phi in block.phis:
                out.append(
                    f"    {c_type(phi.llvm_type)} {phi.result}; "
                    "/* control-flow value */"
                )
        if any(block.phis for block in self.function.blocks):
            out.append("")

        emitted: set[str] = set()
        failed = False

        def emit_body(
            name: str, indent: str, skip_index: Optional[int] = None
        ) -> None:
            for index, line in enumerate(blocks[name].lines[:-1]):
                if index == skip_index:
                    continue
                out.extend(self.render_at(line, blocks[name], indent))

        def terminal_chain(start: str) -> Optional[List[str]]:
            chain: List[str] = []
            current = start
            seen_chain = set()
            while current not in seen_chain:
                seen_chain.add(current)
                chain.append(current)
                if terminal[current]:
                    return chain
                target = self.unconditional_branch(blocks[current])
                if not target:
                    return None
                current = target
            return None

        def closed_emitted_linear_chain(
            start: str,
            stop: Optional[str],
            allowed: Optional[set[str]],
        ) -> Optional[List[str]]:
            """Prove that a shared acyclic path may be repeated in pseudocode.

            A reducible CFG is not necessarily series-parallel: one arm of a
            diamond may enter a block already reached by its sibling before
            both arrive at the immediate post-dominator.  Repeating that
            block's statements in the two mutually exclusive source regions
            is exact, but only when the repeated path is linear and closed.
            Ordinary SSA values escaping the path would acquire the wrong
            source-language scope, so those shapes remain explicit CFGs.
            PHI values are different: their storage is declared at function
            scope and each incoming assignment is emitted on its exact edge,
            including the edge leaving a repeated path.
            """
            if stop is None or start == stop or start not in emitted:
                return None
            chain: List[str] = []
            current = start
            seen_chain: set[str] = set()
            while current != stop:
                if (
                    current in seen_chain
                    or current not in emitted
                    or current in loop_nodes
                    or (allowed is not None and current not in allowed)
                ):
                    return None
                seen_chain.add(current)
                chain.append(current)
                target = self.unconditional_branch(blocks[current])
                if target is None:
                    return None
                current = target

            chain_set = set(chain)
            chain_edges = {
                (name, stop if index + 1 == len(chain) else chain[index + 1])
                for index, name in enumerate(chain)
            }
            for value, definition_block in self.ssa_definition_blocks.items():
                if definition_block not in chain_set:
                    continue
                for consumer in self.ssa_consumers.get(value, set()):
                    if consumer.startswith("#"):
                        consumer_block = consumer[1:].split(":", 1)[0]
                    else:
                        consumer_block = self.ssa_definition_blocks.get(consumer)
                    if consumer_block not in chain_set:
                        return None
                rendered_value = sanitize_identifier(value)
                for edge, assignments in self.phi_by_edge.items():
                    if any(incoming == rendered_value for _result, incoming in assignments):
                        if edge not in chain_edges:
                            return None
            return chain

        def closed_loop_exit_chain(
            start: str,
            stop: str,
            loop_region: set[str],
        ) -> Optional[List[str]]:
            """Prove a side-effect path from a loop exit to its common join.

            Multi-exit natural loops are still directly representable when
            every exit reaches one common post-dominator through a closed,
            unconditional path.  Such a path can be repeated immediately
            before ``break`` without inventing a dispatcher or changing the
            order of effects.  SSA definitions may not escape the repeated
            path; PHI transfers remain attached to their exact CFG edges.
            """
            if start == stop:
                return []
            chain: List[str] = []
            current = start
            seen_chain: set[str] = set()
            while current != stop:
                if (
                    current in seen_chain
                    or current in loop_region
                    or current in loop_nodes
                ):
                    return None
                seen_chain.add(current)
                chain.append(current)
                target = self.unconditional_branch(blocks[current])
                if target is None:
                    return None
                current = target

            chain_set = set(chain)
            chain_edges = {
                (name, stop if index + 1 == len(chain) else chain[index + 1])
                for index, name in enumerate(chain)
            }
            for value, definition_block in self.ssa_definition_blocks.items():
                if definition_block not in chain_set:
                    continue
                for consumer in self.ssa_consumers.get(value, set()):
                    if consumer.startswith("#"):
                        consumer_block = consumer[1:].split(":", 1)[0]
                    else:
                        consumer_block = self.ssa_definition_blocks.get(consumer)
                    if consumer_block not in chain_set:
                        return None
                rendered_value = sanitize_identifier(value)
                for edge, assignments in self.phi_by_edge.items():
                    if any(
                        incoming == rendered_value
                        for _result, incoming in assignments
                    ) and edge not in chain_edges:
                        return None
            return chain

        def emit_closed_shared_path(
            start: str,
            stop: Optional[str],
            indent: str,
            allowed: Optional[set[str]],
        ) -> bool:
            chain = closed_emitted_linear_chain(start, stop, allowed)
            if not chain:
                return False
            for index, name in enumerate(chain):
                emit_body(name, indent)
                target = stop if index + 1 == len(chain) else chain[index + 1]
                assert target is not None
                out.extend(self.phi_transfer_only(name, target, indent))
            return True

        def emit_terminal_path(
            source: str, start: str, indent: str
        ) -> bool:
            chain = terminal_chain(start)
            if not chain:
                return False
            out.extend(self.phi_transfer_only(source, start, indent))
            for index, name in enumerate(chain):
                emitted.add(name)
                emit_body(name, indent)
                if terminal[name]:
                    out.extend(
                        self.render_at(blocks[name].lines[-1], blocks[name], indent)
                    )
                    continue
                target = chain[index + 1]
                out.extend(self.phi_transfer_only(name, target, indent))
            return True

        def is_unreachable_terminal_path(start: str) -> bool:
            chain = terminal_chain(start)
            return bool(
                chain and blocks[chain[-1]].lines[-1] == "unreachable"
            )

        def branch_expression(
            name: str, rendered_condition: str
        ) -> Tuple[Optional[int], str]:
            body = blocks[name].lines[:-1]
            if not body:
                return None, rendered_condition
            assignment = re.match(rf"^({SSA_RE})\s*=", body[-1])
            if not assignment or sanitize_identifier(
                assignment.group(1)
            ) != rendered_condition:
                return None, rendered_condition
            # Inline only a branch-private boolean definition.
            token = assignment.group(1)
            occurrences = sum(
                len(re.findall(rf"(?<![-A-Za-z$._0-9]){re.escape(token)}(?![-A-Za-z$._0-9])", line))
                for block in self.function.blocks
                for line in block.lines
            )
            if occurrences != 2:
                return None, rendered_condition
            rendered = self.render_instruction(body[-1], blocks[name])
            if len(rendered) != 1:
                return None, rendered_condition
            match = re.match(
                rf"^\s*bool\s+{re.escape(rendered_condition)}\s*=\s*(.+);$",
                rendered[0],
            )
            return (len(body) - 1, match.group(1)) if match else (
                None, rendered_condition
            )

        def emit_loop(header: str, indent: str) -> Optional[str]:
            nonlocal failed
            nodes = loop_nodes[header]
            all_exit_edges = [
                (source, target)
                for source in nodes
                for target in successors[source]
                if target not in nodes
            ]
            # Error/overflow arms ending in return or unreachable are exact
            # terminal paths, not loop exits that need a shared continuation.
            # They are rendered in place by emit_region below.
            nonterminal_exit_edges = [
                edge for edge in all_exit_edges
                if not is_unreachable_terminal_path(edge[1])
            ]
            exit_edges = nonterminal_exit_edges or all_exit_edges
            if len(exit_edges) > 1:
                exit_targets = {target for _source, target in exit_edges}
                if any(target not in normal_reachable for target in exit_targets):
                    failed = True
                    return None
                common_postdominators = set.intersection(*(
                    postdominators[target] for target in exit_targets
                )) - nodes
                if not common_postdominators:
                    failed = True
                    return None
                exit_target = max(
                    common_postdominators,
                    key=lambda item: len(postdominators[item]),
                )
                break_chains: Dict[str, List[str]] = {}
                for target in exit_targets:
                    chain = closed_loop_exit_chain(target, exit_target, nodes)
                    if chain is None:
                        failed = True
                        return None
                    break_chains[target] = chain

                emitted.add(header)
                out.append(f"{indent}while (true) {{")
                emit_region(
                    header,
                    None,
                    indent + "    ",
                    nodes,
                    active_header=header,
                    continue_target=header,
                    break_target=exit_target,
                    break_chains=break_chains,
                )
                out.append(f"{indent}}}")
                if failed or not nodes <= emitted:
                    failed = True
                    return None
                return exit_target
            if len(exit_edges) != 1:
                failed = True
                return None
            exit_source, exit_target = exit_edges[0]
            exit_branch = self.conditional_branch(blocks[exit_source])
            if not exit_branch:
                failed = True
                return None
            condition, yes, no = exit_branch
            inside_targets = [target for target in (yes, no) if target in nodes]
            if len(inside_targets) != 1:
                failed = True
                return None
            inside = inside_targets[0]
            condition_index, condition_expression = branch_expression(
                exit_source, condition
            )
            exit_test = (
                condition_expression
                if yes == exit_target
                else negated(condition_expression)
            )
            continue_test = (
                condition_expression
                if yes == inside
                else negated(condition_expression)
            )

            # Pre-tested natural loop: the header owns the only exit.
            if exit_source == header:
                header_payload = len(blocks[header].lines[:-1]) - (
                    1 if condition_index is not None else 0
                )
                emitted.add(header)
                if inside != header and header_payload == 0:
                    out.append(f"{indent}while ({continue_test}) {{")
                    out.extend(
                        self.phi_transfer_only(header, inside, indent + "    ")
                    )
                    emit_region(inside, header, indent + "    ", nodes)
                    out.append(f"{indent}}}")
                    out.extend(
                        self.phi_transfer_only(header, exit_target, indent)
                    )
                else:
                    out.append(f"{indent}while (true) {{")
                    emit_body(header, indent + "    ", condition_index)
                    out.append(f"{indent}    if ({exit_test}) {{")
                    out.extend(
                        self.phi_transfer_only(
                            header, exit_target, indent + "        "
                        )
                    )
                    out.append(f"{indent}        break;")
                    out.append(f"{indent}    }}")
                    if inside == header:
                        out.extend(
                            self.phi_transfer_only(
                                header, header, indent + "    "
                            )
                        )
                    else:
                        out.extend(
                            self.phi_transfer_only(
                                header, inside, indent + "    "
                            )
                        )
                        emit_region(inside, header, indent + "    ", nodes)
                    out.append(f"{indent}}}")
            else:
                # Loop rotation commonly puts the sole exit test below the
                # header.  Some loops can bypass that test for an iteration,
                # so backedges encountered on the way are explicit continue
                # paths rather than evidence that the region is irreducible.
                header_branch = self.conditional_branch(blocks[header])
                if (
                    inside != header
                    and header_branch is not None
                    and {header_branch[1], header_branch[2]}
                    == {exit_source, inside}
                ):
                    header_condition, header_yes, _header_no = header_branch
                    header_condition_index, header_test = branch_expression(
                        header, header_condition
                    )
                    emitted.update({header, exit_source})
                    out.append(f"{indent}while (true) {{")
                    emit_body(
                        header, indent + "    ", header_condition_index
                    )
                    take_exit_test = (
                        header_test
                        if header_yes == exit_source
                        else negated(header_test)
                    )
                    out.append(f"{indent}    if ({take_exit_test}) {{")
                    out.extend(
                        self.phi_transfer_only(
                            header, exit_source, indent + "        "
                        )
                    )
                    emit_body(
                        exit_source, indent + "        ", condition_index
                    )
                    out.append(f"{indent}        if ({exit_test}) {{")
                    out.extend(
                        self.phi_transfer_only(
                            exit_source, exit_target, indent + "            "
                        )
                    )
                    out.append(f"{indent}            break;")
                    out.append(f"{indent}        }}")
                    out.extend(
                        self.phi_transfer_only(
                            exit_source, inside, indent + "        "
                        )
                    )
                    out.append(f"{indent}    }} else {{")
                    out.extend(
                        self.phi_transfer_only(
                            header, inside, indent + "        "
                        )
                    )
                    out.append(f"{indent}    }}")
                    emit_region(inside, header, indent + "    ", nodes)
                    out.append(f"{indent}}}")
                    if failed or not nodes <= emitted:
                        failed = True
                        return None
                    return exit_target

                emitted.add(header)
                out.append(f"{indent}while (true) {{")
                emit_region(
                    header,
                    exit_source,
                    indent + "    ",
                    nodes,
                    active_header=header,
                    continue_target=header,
                )
                if failed or exit_source in emitted:
                    failed = True
                    return None
                emitted.add(exit_source)
                emit_body(exit_source, indent + "    ", condition_index)
                out.append(f"{indent}    if ({exit_test}) {{")
                out.extend(
                    self.phi_transfer_only(
                        exit_source, exit_target, indent + "        "
                    )
                )
                out.append(f"{indent}        break;")
                out.append(f"{indent}    }}")
                if inside == header:
                    out.extend(
                        self.phi_transfer_only(
                            exit_source, header, indent + "    "
                        )
                    )
                else:
                    out.extend(
                        self.phi_transfer_only(
                            exit_source, inside, indent + "    "
                        )
                    )
                    emit_region(
                        inside, header, indent + "    ", nodes
                    )
                out.append(f"{indent}}}")

            if failed or not nodes <= emitted:
                failed = True
                return None
            return exit_target

        def emit_region(
            start: str,
            stop: Optional[str],
            indent: str,
            allowed: Optional[set[str]] = None,
            active_header: Optional[str] = None,
            continue_target: Optional[str] = None,
            break_target: Optional[str] = None,
            break_chains: Optional[Dict[str, List[str]]] = None,
        ) -> None:
            nonlocal failed

            def emit_break_edge(source: str, target: str, edge_indent: str) -> bool:
                if break_target is None or break_chains is None:
                    return False
                chain = break_chains.get(target)
                if chain is None:
                    return False
                out.extend(self.phi_transfer_only(source, target, edge_indent))
                for index, name in enumerate(chain):
                    emitted.add(name)
                    emit_body(name, edge_indent)
                    next_target = (
                        break_target
                        if index + 1 == len(chain)
                        else chain[index + 1]
                    )
                    out.extend(
                        self.phi_transfer_only(name, next_target, edge_indent)
                    )
                out.append(f"{edge_indent}break;")
                return True

            current: Optional[str] = start
            while current is not None and current != stop and not failed:
                if (
                    continue_target is not None
                    and current == continue_target
                    and current != active_header
                ):
                    out.append(f"{indent}continue;")
                    return
                if allowed is not None and current not in allowed:
                    failed = True
                    return
                entering_active_header = current == active_header
                if current in emitted and not entering_active_header:
                    if emit_closed_shared_path(current, stop, indent, allowed):
                        return
                    failed = True
                    return
                if current in loop_nodes and not entering_active_header:
                    current = emit_loop(current, indent)
                    continue
                if not entering_active_header:
                    emitted.add(current)
                active_header = None
                block = blocks[current]
                emit_body(current, indent)
                branch = self.conditional_branch(block)
                target = self.unconditional_branch(block)
                if branch:
                    condition, yes, no = branch
                    yes_break = (
                        allowed is not None
                        and yes not in allowed
                        and break_chains is not None
                        and yes in break_chains
                    )
                    no_break = (
                        allowed is not None
                        and no not in allowed
                        and break_chains is not None
                        and no in break_chains
                    )
                    if yes_break or no_break:
                        if yes_break and no_break:
                            out.append(f"{indent}if ({condition}) {{")
                            if not emit_break_edge(current, yes, indent + "    "):
                                failed = True
                                return
                            out.append(f"{indent}}} else {{")
                            if not emit_break_edge(current, no, indent + "    "):
                                failed = True
                                return
                            out.append(f"{indent}}}")
                            return
                        exit_on_true = yes_break
                        exit_target = yes if yes_break else no
                        inside_target = no if yes_break else yes
                        exit_test = condition if exit_on_true else negated(condition)
                        out.append(f"{indent}if ({exit_test}) {{")
                        if not emit_break_edge(
                            current, exit_target, indent + "    "
                        ):
                            failed = True
                            return
                        out.append(f"{indent}}}")
                        out.extend(
                            self.phi_transfer_only(
                                current, inside_target, indent
                            )
                        )
                        current = inside_target
                        continue
                    # A guard whose one arm is a proven linear path to
                    # unreachable has no semantic join with the normal arm.
                    # Emit that terminal arm before consulting the normal-flow
                    # post-dominator tree; otherwise its synthetic join can
                    # make the error blocks look like an ordinary if-region.
                    yes_unreachable = is_unreachable_terminal_path(yes)
                    no_unreachable = is_unreachable_terminal_path(no)
                    if yes_unreachable != no_unreachable:
                        terminal_target = yes if yes_unreachable else no
                        normal_target = no if yes_unreachable else yes
                        terminal_test = (
                            condition if yes_unreachable else negated(condition)
                        )
                        out.append(f"{indent}if ({terminal_test}) {{")
                        if not emit_terminal_path(
                            current, terminal_target, indent + "    "
                        ):
                            failed = True
                            return
                        out.append(f"{indent}}}")
                        out.extend(
                            self.phi_transfer_only(
                                current, normal_target, indent
                            )
                        )
                        current = normal_target
                        continue
                    join = immediate_postdominator(current)
                    if not join or join == current:
                        yes_terminal = terminal_chain(yes)
                        no_terminal = terminal_chain(no)
                        if yes_terminal and not no_terminal:
                            out.append(f"{indent}if ({condition}) {{")
                            if not emit_terminal_path(
                                current, yes, indent + "    "
                            ):
                                failed = True
                                return
                            out.append(f"{indent}}}")
                            out.extend(
                                self.phi_transfer_only(current, no, indent)
                            )
                            current = no
                            continue
                        if no_terminal and not yes_terminal:
                            out.append(f"{indent}if ({negated(condition)}) {{")
                            if not emit_terminal_path(
                                current, no, indent + "    "
                            ):
                                failed = True
                                return
                            out.append(f"{indent}}}")
                            out.extend(
                                self.phi_transfer_only(current, yes, indent)
                            )
                            current = yes
                            continue
                        failed = True
                        return
                    condition_index, condition_expression = branch_expression(
                        current, condition
                    )
                    if condition_index is not None:
                        # The condition definition was already emitted by
                        # emit_body above. Keep it there for general ifs whose
                        # arms may consume the SSA boolean.
                        condition_expression = condition
                    yes_empty = yes == join and not self.phi_by_edge.get(
                        (current, yes)
                    )
                    no_empty = no == join and not self.phi_by_edge.get(
                        (current, no)
                    )
                    if yes_empty and not no_empty:
                        out.append(f"{indent}if ({negated(condition_expression)}) {{")
                        out.extend(
                            self.phi_transfer_only(current, no, indent + "    ")
                        )
                        emit_region(
                            no, join, indent + "    ", allowed,
                            continue_target=continue_target,
                            break_target=break_target,
                            break_chains=break_chains,
                        )
                        out.append(f"{indent}}}")
                    elif no_empty and not yes_empty:
                        out.append(f"{indent}if ({condition_expression}) {{")
                        out.extend(
                            self.phi_transfer_only(current, yes, indent + "    ")
                        )
                        emit_region(
                            yes, join, indent + "    ", allowed,
                            continue_target=continue_target,
                            break_target=break_target,
                            break_chains=break_chains,
                        )
                        out.append(f"{indent}}}")
                    else:
                        out.append(f"{indent}if ({condition_expression}) {{")
                        out.extend(
                            self.phi_transfer_only(current, yes, indent + "    ")
                        )
                        emit_region(
                            yes, join, indent + "    ", allowed,
                            continue_target=continue_target,
                            break_target=break_target,
                            break_chains=break_chains,
                        )
                        out.append(f"{indent}}} else {{")
                        out.extend(
                            self.phi_transfer_only(current, no, indent + "    ")
                        )
                        emit_region(
                            no, join, indent + "    ", allowed,
                            continue_target=continue_target,
                            break_target=break_target,
                            break_chains=break_chains,
                        )
                        out.append(f"{indent}}}")
                    current = join
                elif target:
                    if (
                        allowed is not None
                        and target not in allowed
                        and emit_break_edge(current, target, indent)
                    ):
                        return
                    out.extend(self.phi_transfer_only(current, target, indent))
                    current = target
                else:
                    # Return/unreachable is part of the block body only when
                    # there is no branch terminator.
                    for line in block.lines[-1:]:
                        out.extend(self.render_at(line, block, indent))
                    current = None

        emit_region(entry, None, "    ")
        if failed or emitted != set(blocks):
            return None
        out.append("}")
        return out

    def declaration(self, lhs: str, llvm_type: str, expression: str) -> str:
        name = sanitize_identifier(lhs)
        self.value_types[name] = llvm_type
        return f"{c_type(llvm_type)} {name} = {expression};"

    def render_instruction(self, line: str, block: Block) -> List[str]:
        indent = "    "
        source = block.name

        # Terminators first: PHI copies belong to CFG edges, not destination blocks.
        match = re.match(rf"^br\s+i1\s+({VALUE_RE}),\s+label\s+%([-A-Za-z$._0-9]+),\s+label\s+%([-A-Za-z$._0-9]+)", line)
        if match:
            cond, yes, no = value_expr(match.group(1)), match.group(2), match.group(3)
            out = [f"{indent}if ({cond}) {{"]
            out.extend(self.edge_transfer(source, yes, indent * 2))
            out.append(f"{indent}}} else {{")
            out.extend(self.edge_transfer(source, no, indent * 2))
            out.append(f"{indent}}}")
            return out
        match = re.match(r"^br\s+label\s+%([-A-Za-z$._0-9]+)", line)
        if match:
            return self.edge_transfer(source, match.group(1), indent)
        if line.startswith("switch "):
            head = re.match(r"^switch\s+(.+?),\s+label\s+%([-A-Za-z$._0-9]+)\s*\[(.*)\]", line)
            if head:
                _ty, selector = typed_value(head.group(1))
                out = [f"{indent}switch ({selector}) {{"]
                for case_value, case_target in re.findall(
                    r"i\d+\s+(-?\d+),\s+label\s+%([-A-Za-z$._0-9]+)",
                    head.group(3),
                ):
                    out.append(f"{indent}case {case_value}:")
                    out.extend(self.edge_transfer(source, case_target, indent * 2))
                out.append(f"{indent}default:")
                out.extend(self.edge_transfer(source, head.group(2), indent * 2))
                out.append(f"{indent}}}")
                return out
        if line.startswith("ret void"):
            return [f"{indent}return;"]
        match = re.match(r"^ret\s+(.+)$", line)
        if match:
            _ty, value = typed_value(match.group(1))
            return [f"{indent}return {value};"]
        if line == "unreachable":
            return [f"{indent}unreachable();"]

        # Side-effecting operations.
        if line.startswith("store "):
            parts = split_top_level(line[len("store "):])
            ty, value = typed_value(parts[0]) if parts else (None, "")
            pointer_ty, pointer = (
                typed_value(parts[1]) if len(parts) >= 2 else (None, "")
            )
            if ty and pointer_ty and pointer_ty.startswith("ptr"):
                return [f"{indent}store<{c_type(ty)}>({pointer}, {value});"]
        if re.match(r"^(?:tail\s+|musttail\s+|notail\s+)?call\s+", line):
            call = self.render_call(line)
            return [f"{indent}{call};"] if call else [f"{indent}/* LLVM: {line} */"]

        assignment = re.match(rf"^({SSA_RE})\s*=\s*(.+)$", line)
        if not assignment:
            return [f"{indent}/* LLVM: {line} */"]
        lhs, rhs = assignment.group(1), assignment.group(2)

        resolver = self.address_resolvers.get(lhs)
        if resolver:
            profile = tuple(resolver.ranges)
            map_name = self.address_map_names.get(profile)
            if map_name:
                range_argument = map_name
            else:
                range_argument = ", ".join(
                    "recovered_range("
                    f"{sanitize_identifier(arm.global_value, 'global')}, "
                    f"{arm.guest_begin}, {arm.size})"
                    for arm in resolver.ranges
                )
            expression = "resolve_guest_or_native_address(" + ", ".join(
                [sanitize_identifier(resolver.address), range_argument]
            ) + ")"
            return [f"{indent}{self.declaration(lhs, 'ptr', expression)}"]
        if lhs in self.suppressed_resolver_values:
            return []

        match = re.match(r"alloca\s+(.+?)(?:,\s+align\s+\d+)?$", rhs)
        if match:
            ty = match.group(1).split(",", 1)[0].strip()
            name = sanitize_identifier(lhs)
            self.value_types[name] = "ptr"
            array = re.fullmatch(r"\[\s*(\d+)\s+x\s+(.+)\]", ty)
            if array:
                return [f"{indent}{c_type(array.group(2))} {name}[{array.group(1)}];"]
            return [f"{indent}{c_type(ty)} {name};"]
        if rhs.startswith("load "):
            parts = split_top_level(rhs[len("load "):])
            if len(parts) >= 2:
                ty = parts[0].strip().split()[0]
                pointer_ty, pointer = typed_value(parts[1])
                if pointer_ty and pointer_ty.startswith("ptr"):
                    return [f"{indent}{self.declaration(lhs, ty, f'load<{c_type(ty)}>({pointer})')}"]
        match = re.match(r"(add|sub|mul|udiv|sdiv|urem|srem|shl|lshr|ashr|and|or|xor)((?:\s+(?:nuw|nsw|exact|disjoint))*)\s+(.+)$", rhs)
        if match:
            op, flag_text, rest = match.group(1), match.group(2), match.group(3)
            parsed = llvm_type_prefix(rest)
            if parsed:
                ty, operands = parsed
                args = split_top_level(operands)
                if len(args) == 2:
                    left, right = value_expr(args[0]), value_expr(args[1])
                    symbols = {"add": "+", "sub": "-", "mul": "*", "udiv": "/", "sdiv": "/", "urem": "%", "srem": "%", "shl": "<<", "lshr": ">>", "ashr": ">>", "and": "&", "or": "|", "xor": "^"}
                    if op in {"add", "sub"} and re.fullmatch(r"-\d+", right):
                        right = right[1:]
                        symbols[op] = "-" if op == "add" else "+"
                    signed = op in {"sdiv", "srem", "ashr"}
                    if signed:
                        left = f"({signed_c_type(ty)}){left}"
                        right = f"({signed_c_type(ty)}){right}"
                    rendered = self.declaration(
                        lhs, ty, f"{left} {symbols[op]} {right}"
                    )
                    flag_comments = {
                        "nuw": "no unsigned wrap",
                        "nsw": "no signed wrap",
                        "exact": "exact operation",
                        "disjoint": "disjoint operands",
                    }
                    comments = [
                        flag_comments[flag]
                        for flag in flag_text.split()
                        if flag in flag_comments
                    ]
                    if comments:
                        rendered += " /* " + "; ".join(comments) + " */"
                    return [f"{indent}{rendered}"]
        match = re.match(r"icmp(?:\s+(samesign))?\s+([a-z]+)\s+(.+)$", rhs)
        if match:
            same_sign, predicate, rest = match.group(1), match.group(2), match.group(3)
            parsed = llvm_type_prefix(rest)
            if parsed:
                ty, operands = parsed
                args = split_top_level(operands)
                if len(args) == 2:
                    left, right = value_expr(args[0]), value_expr(args[1])
                    symbols = {"eq": "==", "ne": "!=", "ugt": ">", "uge": ">=", "ult": "<", "ule": "<=", "sgt": ">", "sge": ">=", "slt": "<", "sle": "<="}
                    if predicate.startswith("s"):
                        left = f"({signed_c_type(ty)}){left}"
                        right = f"({signed_c_type(ty)}){right}"
                    rendered = self.declaration(
                        lhs,
                        "i1",
                        f"{left} {symbols.get(predicate, predicate)} {right}",
                    )
                    if same_sign:
                        rendered += " /* operands have the same sign bit */"
                    return [f"{indent}{rendered}"]
        match = re.match(r"select\s+i1\s+([^,]+),\s+(.+?),\s+(.+)$", rhs)
        if match:
            cond = value_expr(match.group(1))
            ty, yes = typed_value(match.group(2))
            _no_ty, no = typed_value(match.group(3))
            return [f"{indent}{self.declaration(lhs, ty or 'value', f'{cond} ? {yes} : {no}')}"]
        match = re.match(r"(zext|sext|trunc|bitcast|ptrtoint|inttoptr|addrspacecast)(?:\s+(?:nuw|nsw|exact|nneg))*\s+(.+?)\s+to\s+(.+?)(?:,|$)", rhs)
        if match:
            operation, source_text, target_ty = match.group(1), match.group(2), match.group(3).strip()
            _source_ty, source_value = typed_value(source_text)
            helper = {
                "zext": "zero_extend", "sext": "sign_extend", "trunc": "truncate",
                "bitcast": "bit_cast", "ptrtoint": "pointer_to_integer",
                "inttoptr": "integer_to_pointer", "addrspacecast": "address_space_cast",
            }[operation]
            return [f"{indent}{self.declaration(lhs, target_ty, f'{helper}<{c_type(target_ty)}>({source_value})')}"]
        if rhs.startswith("getelementptr"):
            parsed = render_gep(rhs)
            if parsed:
                return [f"{indent}{self.declaration(lhs, 'ptr', parsed)}"]
        call = self.render_call(rhs)
        if call:
            if (self.raw_ssa_occurrences.get(lhs, 0) <= 1 and
                    sanitize_identifier(lhs) not in self.phi_value_uses):
                return [f"{indent}{call};"]
            return_ty = call_return_type(rhs) or "value"
            return [f"{indent}{self.declaration(lhs, return_ty, call)}"]
        if rhs.startswith("extractvalue "):
            parsed = llvm_type_prefix(rhs[len("extractvalue "):])
            if parsed:
                aggregate_ty, rest = parsed
                parts = split_top_level(rest)
                if len(parts) >= 2 and parts[-1].isdigit():
                    aggregate, field = value_expr(parts[0]), parts[-1]
                    members = split_top_level(
                        aggregate_ty[2:-2] if aggregate_ty.startswith("<{")
                        else aggregate_ty.strip("{} ")
                    )
                    ty = members[int(field)] if int(field) < len(members) else "value"
                    return [f"{indent}{self.declaration(lhs, ty, f'{aggregate}.field{field}')}"]
        if rhs.startswith("insertvalue "):
            parsed = llvm_type_prefix(rhs[len("insertvalue "):])
            if parsed:
                aggregate_ty, rest = parsed
                parts = split_top_level(rest)
                if len(parts) >= 3 and parts[-1].isdigit():
                    aggregate = value_expr(parts[0])
                    _inserted_ty, inserted = typed_value(parts[1])
                    field = parts[-1]
                    expression = f"insert_value({aggregate}, {field}, {inserted})"
                    return [f"{indent}{self.declaration(lhs, aggregate_ty, expression)}"]
        match = re.match(r"freeze\s+(.+)$", rhs)
        if match:
            ty, value = typed_value(match.group(1))
            return [f"{indent}{self.declaration(lhs, ty or 'value', f'freeze({value})')}"]
        return [f"{indent}/* LLVM: {sanitize_llvm_line(line)} */"]

    def render_call(self, text: str) -> Optional[str]:
        parsed = parse_call(text)
        if not parsed:
            return None
        callee, arguments, _return_type = parsed
        raw_name = callee.lstrip("@%")
        rendered_args = []
        for arg in split_top_level(arguments):
            _ty, value = typed_value(arg)
            rendered_args.append(value)
        outlined = self.outlined_address_resolvers.get(raw_name)
        if outlined is not None and len(rendered_args) == 1:
            profile = tuple(outlined.ranges)
            map_name = self.address_map_names.get(profile)
            if map_name:
                return (
                    "resolve_guest_or_native_address("
                    f"{rendered_args[0]}, {map_name})"
                )
        affine = self.outlined_affine_address_resolvers.get(raw_name)
        if affine is not None and len(rendered_args) > max(
            affine.root_index, affine.address_index
        ):
            profile = tuple(affine.ranges)
            map_name = self.affine_address_map_names.get(profile)
            if map_name:
                return (
                    "resolve_affine_guest_or_native_address("
                    f"{rendered_args[affine.root_index]}, "
                    f"{rendered_args[affine.address_index]}, {map_name})"
                )
        if raw_name.startswith("llvm.memcpy.") and len(rendered_args) >= 3:
            return f"memcpy({', '.join(rendered_args[:3])})"
        if raw_name.startswith("llvm.memmove.") and len(rendered_args) >= 3:
            return f"memmove({', '.join(rendered_args[:3])})"
        if raw_name.startswith("llvm.memset.") and len(rendered_args) >= 3:
            return f"memset({', '.join(rendered_args[:3])})"
        function = sanitize_identifier(callee, "function")
        if function.startswith("llvm_lifetime_"):
            return "/* lifetime marker */"
        return f"{function}({', '.join(rendered_args)})"

    def render(self) -> List[str]:
        structured = self.render_nested_loop_cfg()
        if structured is not None:
            return structured
        structured = self.render_reducible_cfg()
        if structured is not None:
            return structured
        args = ", ".join(f"{c_type(ty)} {name}" for ty, name in self.function.args)
        out = [f"{c_type(self.function.return_type)} {sanitize_identifier('@' + self.function.name, 'function')}({args}) {{"]
        for block in self.function.blocks:
            for phi in block.phis:
                out.append(f"    {c_type(phi.llvm_type)} {phi.result}; /* PHI, assigned on incoming edges */")
        if any(block.phis for block in self.function.blocks):
            out.append("")
        show_labels = len(self.function.blocks) > 1
        for block in self.function.blocks:
            if show_labels:
                out.append(f"{label_name(block.name)}:")
            for line in block.lines:
                rendered = self.render_instruction(line, block)
                if rendered == ["    /* lifetime marker */;"]:
                    continue
                out.extend(rendered)
        out.append("}")
        return out


def signed_c_type(llvm_type: str) -> str:
    match = re.fullmatch(r"i(8|16|32|64)", llvm_type.strip())
    return f"int{match.group(1)}_t" if match else c_type(llvm_type)


def render_gep(rhs: str) -> Optional[str]:
    # Instruction-form GEP: getelementptr [flags] TYPE, ptr BASE, INDEX...
    text = rhs.strip()
    flag_match = re.match(
        r"^getelementptr((?:\s+(?:inbounds|nuw|nsw|nusw))*)",
        text,
    )
    flags = flag_match.group(1).split() if flag_match else []
    parenthesized = re.match(
        r"^getelementptr(?:\s+inbounds)?(?:\s+(?:nuw|nsw|nusw))*\s*\((.*)\)$",
        text,
    )
    if parenthesized:
        text = parenthesized.group(1)
    else:
        text = re.sub(r"^getelementptr(?:\s+inbounds)?(?:\s+(?:nuw|nsw|nusw))*\s+", "", text)
    parts = split_top_level(text)
    if len(parts) < 3:
        return None
    base_match = re.match(r"ptr\s+(.+)$", parts[1])
    if not base_match:
        return None
    base = value_expr(base_match.group(1))
    indexes = []
    for item in parts[2:]:
        _ty, index = typed_value(item)
        indexes.append(index)
    helper = "get_element_pointer"
    if flags:
        helper += "_" + "_".join(flags)
    return f"{helper}({base}, {', '.join(indexes)})"


def call_return_type(rhs: str) -> Optional[str]:
    parsed = parse_call(rhs)
    return parsed[2] if parsed else None


def parse_call(text: str) -> Optional[Tuple[str, str, str]]:
    """Return (callee token, argument text, return type) for direct/SSA calls."""
    call_match = re.search(r"\bcall\b", text)
    if not call_match:
        return None
    after = text[call_match.end():].strip()
    callee_match = re.search(rf"({GLOBAL_RE}|{SSA_RE})\(", after)
    if not callee_match:
        return None
    callee = callee_match.group(1)
    open_paren = callee_match.end() - 1
    depth = 0
    close_paren = None
    for index in range(open_paren, len(after)):
        if after[index] == "(":
            depth += 1
        elif after[index] == ")":
            depth -= 1
            if depth == 0:
                close_paren = index
                break
    if close_paren is None:
        return None
    prefix = after[:callee_match.start()]
    candidates = re.findall(
        r"(?:void|half|float|double|x86_fp80|fp128|ppc_fp128|ptr|i\d+|\{[^{}]*\}|<\{[^{}]*\}>)",
        prefix,
    )
    return_type = candidates[0] if candidates else "value"
    return callee, after[open_paren + 1:close_paren], return_type


def sanitize_llvm_line(line: str) -> str:
    return re.sub(SSA_RE, lambda m: sanitize_identifier(m.group(0)),
                  re.sub(GLOBAL_RE, lambda m: sanitize_identifier(m.group(0), "global"), line))


def has_only_direct_call_uses(text: str, function_name: str) -> bool:
    """Prove that an internal helper symbol has no non-call observations."""
    token = "@" + function_name
    definition_count = 0
    for raw in text.splitlines():
        if token not in raw:
            continue
        occurrences = re.findall(
            rf"@{re.escape(function_name)}(?![-A-Za-z$._0-9])", raw
        )
        if not occurrences:
            # A helper name may be the prefix of a separately defined LLVM
            # symbol such as ``resolver`` and ``resolver.1``.
            continue
        if len(occurrences) != 1:
            return False
        if re.match(
            rf"^\s*define\b.*@{re.escape(function_name)}\(", raw
        ):
            if not re.match(
                rf"^\s*define\b.*\binternal\b.*@{re.escape(function_name)}\(",
                raw,
            ):
                return False
            definition_count += 1
            continue
        parsed = parse_call(raw.strip())
        if parsed is None or parsed[0] != token:
            return False
    return definition_count == 1


def transpile_llvm_ir_to_c(ir_path: str, out_c_path: str) -> None:
    text = Path(ir_path).read_text(encoding="utf-8", errors="replace")
    strings, scalar_globals, functions = parse_module(text)
    if not functions:
        raise ValueError(f"no LLVM function definitions found in {ir_path}")

    out = [
        "/* Semantic C-like pseudocode generated from LLVM IR.",
        " * This is evidence, not directly compilable recovered source.",
        " * PHI transfers and unsupported LLVM operations remain explicit.",
        " */",
        "#include <stdbool.h>",
        "#include <stddef.h>",
        "#include <stdint.h>",
        "",
    ]
    for name, string in strings:
        out.append(f'static const char {name}[] = "{string}";')
    for global_value in scalar_globals:
        if global_value.is_external:
            if global_value.is_object_view:
                out.append(
                    f"extern uint8_t {global_value.name}[]; "
                    "/* exact view into shared residual backing */"
                )
                continue
            out.append(
                f"extern {c_type(global_value.llvm_type)} "
                f"{global_value.name};"
                + (
                    " /* exact view into shared residual backing */"
                    if global_value.is_alias
                    else ""
                )
            )
            continue
        qualifier = "const " if global_value.is_constant else ""
        out.append(
            f"static {qualifier}{c_type(global_value.llvm_type)} "
            f"{global_value.name} = {global_value.initializer};"
        )
    if strings or scalar_globals:
        out.append("")
    renderers = [FunctionRenderer(function) for function in functions]
    outlined_address_resolvers: Dict[str, AddressResolver] = {}
    outlined_affine_address_resolvers: Dict[str, AffineAddressResolver] = {}
    for renderer in renderers:
        resolver = renderer.complete_outlined_address_resolver()
        if resolver is not None and has_only_direct_call_uses(
            text, renderer.function.name
        ):
            outlined_address_resolvers[renderer.function.name] = resolver
            continue
        affine_resolver = renderer.complete_outlined_affine_address_resolver()
        if affine_resolver is not None and has_only_direct_call_uses(
            text, renderer.function.name
        ):
            outlined_affine_address_resolvers[
                renderer.function.name
            ] = affine_resolver
    address_map_names: Dict[Tuple[AddressRange, ...], str] = {}
    affine_address_map_names: Dict[
        Tuple[AffineAddressRange, ...], str
    ] = {}
    for renderer in renderers:
        resolvers = list(renderer.address_resolvers.values())
        outlined = outlined_address_resolvers.get(renderer.function.name)
        if outlined is not None:
            resolvers.append(outlined)
        for resolver in resolvers:
            profile = tuple(resolver.ranges)
            if profile not in address_map_names:
                suffix = "" if not address_map_names else f"_{len(address_map_names)}"
                address_map_names[profile] = f"recovered_address_map{suffix}"
        renderer.address_map_names = address_map_names
        renderer.outlined_address_resolvers = outlined_address_resolvers
        affine = outlined_affine_address_resolvers.get(renderer.function.name)
        if affine is not None:
            profile = tuple(affine.ranges)
            if profile not in affine_address_map_names:
                suffix = (
                    "" if not affine_address_map_names
                    else f"_{len(affine_address_map_names)}"
                )
                affine_address_map_names[
                    profile
                ] = f"recovered_affine_address_map{suffix}"
        renderer.affine_address_map_names = affine_address_map_names
        renderer.outlined_affine_address_resolvers = (
            outlined_affine_address_resolvers
        )
    if address_map_names:
        out.extend([
            "/* recovered_range(base, guest_begin, size) maps a guest address",
            " * to base + (address - guest_begin). Ranges are tried in order;",
            " * resolve_guest_or_native_address otherwise preserves the native pointer.",
            " */",
        ])
        for profile, name in address_map_names.items():
            out.append(f"static const recovered_address_range {name}[] = {{")
            for arm in profile:
                out.append(
                    "    recovered_range("
                    f"{sanitize_identifier(arm.global_value, 'global')}, "
                    f"{arm.guest_begin}, {arm.size}),"
                )
            out.append("};")
        out.append("")
    if affine_address_map_names:
        out.extend([
            "/* Each affine range checks root + bias and maps the same offset;",
            " * add_guarantees/gep_guarantees retain LLVM poison conditions.",
            " * The resolver falls back to the original guest/native pointer.",
            " */",
        ])
        for profile, name in affine_address_map_names.items():
            out.append(f"static const recovered_affine_address_range {name}[] = {{")
            for arm in profile:
                add_flags = (
                    "add_guarantees(" + ", ".join(arm.add_flags) + ")"
                    if arm.add_flags else "no_add_guarantees"
                )
                gep_flags = (
                    "gep_guarantees(" + ", ".join(arm.base_gep_flags) + ")"
                    if arm.base_gep_flags else "no_gep_guarantees"
                )
                out.append(
                    "    recovered_affine_range("
                    f"{sanitize_identifier(arm.global_value, 'global')}, "
                    f"{arm.root_bias}, {arm.size}, {add_flags}, {gep_flags}),"
                )
            out.append("};")
        out.append("")
    visible_renderers = [
        renderer for renderer in renderers
        if renderer.function.name not in outlined_address_resolvers
        and renderer.function.name not in outlined_affine_address_resolvers
    ]
    for index, renderer in enumerate(visible_renderers):
        out.extend(renderer.render())
        if index + 1 != len(visible_renderers):
            out.append("")
    Path(out_c_path).write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"[✓] LLVM IR -> semantic pseudocode: {ir_path} -> {out_c_path}")


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_ir")
    parser.add_argument("output_c")
    args = parser.parse_args(argv)
    transpile_llvm_ir_to_c(args.input_ir, args.output_c)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
