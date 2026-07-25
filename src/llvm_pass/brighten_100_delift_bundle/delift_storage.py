#!/usr/bin/env python3
"""Remove synthetic register/frame storage without assuming a program name.

The input is textual LLVM IR because this pass deliberately runs before the
normal LLVM optimiser.  All names and frame geometry are discovered from the
module's globals and function metadata; no ``main``, 16 MiB, or 256-byte
assumption is part of the transformation.
"""

from pathlib import Path
import re
import sys


src, dst = map(Path, sys.argv[1:3])
text = src.read_text()


# Register storage may still carry live state across recovered helper
# boundaries.  Treat it as semantic state unless a real LLVM data-flow pass
# proves an access dead; textual zeroing/removal is not sound.
reg_stores = len(re.findall(r"^\s*store\b[^\n]*@native_register_storage", text, re.M))
reg_loads = len(re.findall(r"^\s*%[-A-Za-z$._0-9]+\s*=\s*load\b[^\n]*@native_register_storage", text, re.M))


# Find a synthetic frame global and its declared size.  Different lifts use
# different suffixes, so only the stack metadata and byte-array shape matter.
frame_match = re.search(
    r"^@(?P<name>[A-Za-z$._][A-Za-z0-9$._-]*)\s*=\s*internal\s+global\s+"
    r"\[(?P<size>\d+)\s+x\s+i8\][^\n]*!brighten\.stack\.ensured",
    text,
    re.M,
)
frame_name = frame_match.group("name") if frame_match else None
frame_size = int(frame_match.group("size")) if frame_match else 0


def function_spans(ir: str):
    starts = list(re.finditer(r"^define\b[^\n]*@([A-Za-z$._][A-Za-z0-9$._-]*)\([^\n]*\)[^\n]*\{\s*$", ir, re.M))
    spans = []
    for index, match in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(ir)
        body = ir[match.start():end]
        close = body.rfind("\n}")
        body_end = close + 2 if close >= 0 else len(body)
        spans.append(
            (
                match.group(1),
                match.start(),
                match.start() + body_end,
                body[:body_end],
            )
        )
    return spans


spans = function_spans(text)
entry_name = None
for name, _, _, body in spans:
    if "!brighten.return_candidate" in body:
        entry_name = name
        break
if entry_name is None:
    for name, _, _, body in spans:
        header = body.split("\n", 1)[0]
        if "dllexport" in header:
            entry_name = name
            break
if entry_name is None and spans:
    entry_name = spans[0][0]

direct_n = 0
frame_ssa_defs = 0
frame_slots = set()
frame_addrs = set()
frame_corrs = set()

def fold_same_anchor_deltas(ir: str, global_name: str):
    """Fold ((ptrtoint(anchor) + C) - ptrtoint(anchor)) inside ConstantExprs.

    LLVM's normal InstCombine does not visit this expression when it remains
    nested directly in a load/store GEP.  Match the complete repeated anchor,
    not a program-specific offset or function name.
    """
    anchor = (
        rf"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*"
        rf"\(i8,\s*ptr\s+@{re.escape(global_name)},\s*i64\s+-?\d+\)"
    )
    pattern = re.compile(
        rf"getelementptr\s*\(i8,\s*ptr\s+(?P<anchor>{anchor}),\s*i64\s+"
        rf"sub\s*\(i64\s+add\s*\(i64\s+ptrtoint\s*\(ptr\s+(?P=anchor)"
        rf"\s+to\s+i64\),\s*i64\s+(?P<delta>-?\d+)\),\s*i64\s+"
        rf"ptrtoint\s*\(ptr\s+(?P=anchor)\s+to\s+i64\)\)\)"
    )
    def replace(match):
        # Keep the rewrite non-inbounds, but flatten the repeated anchor back
        # to the frame global.  Leaving `getelementptr(frame+TOP, delta)`
        # nested after cancelling ptrtoint(anchor) still hides identical frame
        # slots from LLVM's alias analysis.
        anchor_offset = re.search(
            rf"@{re.escape(global_name)},\s*i64\s+(-?\d+)",
            match.group("anchor"),
        )
        if anchor_offset:
            absolute = int(anchor_offset.group(1)) + int(match.group("delta"))
            return (
                f"getelementptr (i8, ptr @{global_name}, "
                f"i64 {absolute})"
            )
        return (
            f"getelementptr (i8, ptr {match.group('anchor')}, "
            f"i64 {match.group('delta')})"
        )

    return pattern.subn(replace, ir)


def _split_top_level(text: str):
    parts = []
    start = 0
    depth = 0
    for index, char in enumerate(text):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
    parts.append(text[start:].strip())
    return parts


def _frame_symbolic_int(expr: str, frame: str, ssa=None, seen=None):
    """Return (frame-address coefficient, constant) for a ConstantExpr.

    The lifted stack rebasing code commonly emits expressions such as
    ``add(ptrtoint(frame_top), -8)`` and ``xor(ptrtoint(frame_top), -1)``.
    They are integer identities modulo 2**64; after the frame coefficient
    cancels, the pointer is an ordinary constant byte offset.  Unknown SSA
    values deliberately return None.
    """
    expr = expr.strip()
    ssa = ssa or {}
    seen = set() if seen is None else set(seen)
    ssa_name = re.fullmatch(r"%[-A-Za-z$._0-9]+", expr)
    if ssa_name and expr in ssa and expr not in seen:
        return _frame_symbolic_int(expr=ssa[expr], frame=frame, ssa=ssa,
                                   seen=seen | {expr})
    expr = re.sub(r"^i\d+\s+", "", expr)
    if re.fullmatch(r"-?\d+", expr):
        return 0, int(expr)

    ptrtoint = re.match(
        r"^ptrtoint\s*\(\s*ptr\s+(?P<p>.+)\s+to\s+i\d+\s*\)$",
        expr,
        re.S,
    )
    if ptrtoint:
        pointer = _frame_symbolic_ptr(ptrtoint.group("p"), frame, ssa, seen)
        if pointer is None:
            return None
        return 1, pointer[1]

    op = re.match(
        r"^(?P<op>add|sub|mul|xor)(?:\s+(?:nuw|nsw|exact))*\s*"
        r"\((?P<body>.*)\)$",
        expr,
        re.S,
    )
    if op:
        args = _split_top_level(op.group("body"))
        if len(args) != 2:
            return None
        left = _frame_symbolic_int(args[0], frame, ssa, seen)
        right = _frame_symbolic_int(args[1], frame, ssa, seen)
        if left is None or right is None:
            return None
        lc, lv = left
        rc, rv = right
        if op.group("op") == "add":
            return lc + rc, lv + rv
        if op.group("op") == "sub":
            return lc - rc, lv - rv
        if op.group("op") == "mul":
            if lc and rc:
                return None
            if rc:
                return rc * lc, rc * lv
            return lc * rv, rv * lv
        # xor(x, -1) is bitwise-not and is linear in the one symbolic
        # variable.  Other XORs are not safe to model as affine arithmetic.
        if rc == 0 and rv == -1:
            return -lc, -lv - 1
        if lc == 0 and lv == -1:
            return -rc, -rv - 1
        if lc == 0 and rc == 0:
            return 0, lv ^ rv
        return None

    cast = re.match(
        r"^(?:zext|sext|trunc|bitcast)\s*\(\s*i\d+\s+(.+)\s*\)\s+to\s+i\d+$",
        expr,
        re.S,
    )
    if cast:
        return _frame_symbolic_int(cast.group(1), frame, ssa, seen)
    return None


def _frame_symbolic_ptr(expr: str, frame: str, ssa=None, seen=None):
    expr = expr.strip()
    ssa = ssa or {}
    seen = set() if seen is None else set(seen)
    ssa_name = re.fullmatch(r"%[-A-Za-z$._0-9]+", expr)
    if ssa_name and expr in ssa and expr not in seen:
        return _frame_symbolic_ptr(expr=ssa[expr], frame=frame, ssa=ssa,
                                   seen=seen | {expr})
    if expr == f"@{frame}":
        return 0, 0
    bitcast = re.match(
        r"^bitcast\s*\(\s*ptr\s+(.+)\s+to\s+ptr\s*\)$", expr, re.S
    )
    if bitcast:
        return _frame_symbolic_ptr(bitcast.group(1), frame, ssa, seen)

    match = re.match(r"^getelementptr(?:\s+[^\(]+)?\s*\((.*)\)$", expr, re.S)
    if match:
        body = match.group(1)
    else:
        instruction = re.match(
            r"^getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s+(.+)$",
            expr,
            re.S,
        )
        if not instruction:
            return None
        body = instruction.group(1)
    if not body:
        return None
    args = _split_top_level(body)
    if len(args) != 3 or args[0].strip() != "i8":
        return None
    pointer_arg = args[1].strip()
    if not pointer_arg.startswith("ptr "):
        return None
    base = _frame_symbolic_ptr(pointer_arg[4:], frame, ssa, seen)
    index = _frame_symbolic_int(args[2], frame, ssa, seen)
    if base is None or index is None:
        return None
    return base[0] + index[0], base[1] + index[1]


def _flatten_constant_frame_geps_body(ir: str, frame: str, frame_size: int,
                                      ssa=None):
    """Flatten all constant affine frame GEPs, including nested ConstantExprs.

    This is intentionally module-wide and syntax-driven because LLVM's normal
    optimizer treats ptrtoint(frame) as an opaque host address.  It only
    rewrites expressions whose symbolic frame-address coefficient cancels and
    whose final byte offset is inside the original object; dynamic indices and
    out-of-bounds/faulting expressions remain byte-for-byte intact.
    """
    # Scan only parenthesized ConstantExpr GEPs.  A plain instruction-form
    # `getelementptr i8, ptr @global, i64 %idx` has no closing parenthesis;
    # letting a greedy token regex span into the next instruction can make an
    # unrelated global GEP look like the outer frame expression and corrupt
    # the IR (e.g. `%x = %delift.frame.slot, align 1`).
    token = re.compile(
        r"\bgetelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\("
    )
    direct = re.compile(
        rf"^getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\(i8,\s*ptr\s+@"
        rf"{re.escape(frame)},\s*i64\s+-?\d+\)$"
    )
    changed = 0
    for _ in range(8):
        candidates = []
        for match in token.finditer(ir):
            open_index = ir.find("(", match.start(), match.end())
            depth = 0
            close_index = None
            for index in range(open_index, len(ir)):
                if ir[index] == "(":
                    depth += 1
                elif ir[index] == ")":
                    depth -= 1
                    if depth == 0:
                        close_index = index + 1
                        break
            if close_index is None:
                continue
            expr = ir[match.start():close_index]
            if direct.fullmatch(expr):
                continue
            symbolic = _frame_symbolic_ptr(expr, frame, ssa)
            if symbolic is None or symbolic[0] != 0:
                continue
            offset = symbolic[1]
            if offset < 0 or offset > frame_size:
                continue
            candidates.append((match.start(), close_index, expr, offset))

        if not candidates:
            break
        # Prefer the outermost successful expression.  If an outer expression
        # is dynamic, its successful inner constant GEPs are still eligible on
        # this pass without overlapping replacements.
        selected = []
        for candidate in sorted(candidates, key=lambda item: (item[0], -item[1])):
            if any(candidate[0] < end and start < candidate[1]
                   for start, end, *_ in selected):
                continue
            selected.append(candidate)
        for start, end, old, offset in reversed(selected):
            new = f"getelementptr (i8, ptr @{frame}, i64 {offset})"
            ir = ir[:start] + new + ir[end:]
            changed += 1
    return ir, changed


def flatten_constant_frame_geps(ir: str, frame: str, frame_size: int):
    """Flatten affine frame GEPs with function-local SSA definitions."""
    spans = function_spans(ir)
    if not spans:
        return _flatten_constant_frame_geps_body(ir, frame, frame_size)

    rebuilt = []
    cursor = 0
    changed = 0
    for _, start, end, body in spans:
        rebuilt.append(ir[cursor:start])
        ssa = {}
        for line in body.splitlines():
            match = re.match(
                r"^\s*(%[-A-Za-z$._0-9]+)\s*=\s*"
                r"(getelementptr\b.*|bitcast\b.*|ptrtoint\b.*|"
                r"(?:add|sub|mul|xor|zext|sext|trunc)\b.*)$",
                line,
            )
            if match:
                ssa[match.group(1)] = match.group(2).strip()
        body, count = _flatten_constant_frame_geps_body(
            body, frame, frame_size, ssa
        )
        rebuilt.append(body)
        changed += count
        cursor = end
    rebuilt.append(ir[cursor:])
    return "".join(rebuilt), changed


def deduplicate_pointer_selects(ir: str):
    """Remove idempotent/duplicate resolver selects without changing semantics.

    The native resolver is often inlined several times, producing chains such
    as ``select c, A, select c, A, X``.  These are exactly equivalent to the
    inner select, but LLVM's normal cleanup does not always see through the
    generated names.  Restrict this rewrite to pointer selects with identical
    condition and true arm; no range decision is discarded.
    """
    select_re = re.compile(
        r"^(?P<indent>\s*)(?P<name>%[-A-Za-z$._0-9]+)\s*=\s*select i1 "
        r"(?P<cond>%[-A-Za-z$._0-9]+), ptr (?P<yes>%[-A-Za-z$._0-9]+), ptr (?P<no>%[-A-Za-z$._0-9]+)\s*$"
    )
    ssa_token_re = re.compile(r"(?<![-A-Za-z$._0-9])%[-A-Za-z$._0-9]+")
    total = 0
    chunks = re.split(r"(?=^define\b)", ir, flags=re.M)
    rebuilt = []
    for chunk in chunks:
        if not chunk.startswith("define"):
            rebuilt.append(chunk)
            continue
        for _ in range(8):
            defs = {}
            lines = chunk.splitlines()
            block = "<entry>"
            blocks = []
            for index, line in enumerate(lines):
                label = re.match(r"^[A-Za-z$._0-9-]+:\s*(?:;.*)?$", line)
                if label:
                    block = label.group(0).strip()
                blocks.append(block)
                m = select_re.match(line)
                if m:
                    data = m.groupdict()
                    data["line"] = index
                    data["block"] = block
                    defs[data["name"]] = data

            # Textual IR has no dominance query.  Restrict this cleanup to a
            # select whose every use is later in the same basic block; that
            # is enough to prove the replacement value dominates all uses and
            # avoids the old cross-block SSA misrewrite.
            refs = {name: [] for name in defs}
            for index, line in enumerate(lines):
                # Scan the line once.  The previous implementation compiled
                # and executed one regular expression per select definition
                # per line, making resolver-heavy modules effectively
                # quadratic (p00859 spent minutes in this loop).
                for name in set(ssa_token_re.findall(line)):
                    if name in refs:
                        refs[name].append((index, blocks[index]))

            def locally_safe(name, data):
                for index, owner in refs.get(name, ()):
                    if index == data["line"]:
                        continue
                    if owner != data["block"] or index <= data["line"]:
                        return False
                return True

            replacements = {}
            remove = set()
            prior_by_key = {}
            for name, d in defs.items():
                if not locally_safe(name, d):
                    continue
                nested = defs.get(d["no"])
                if (
                    nested
                    and d["no"] not in remove
                    and nested["block"] == d["block"]
                    and nested["line"] < d["line"]
                    and nested["cond"] == d["cond"]
                    and nested["yes"] == d["yes"]
                    and locally_safe(d["no"], nested)
                ):
                    replacements[name] = d["no"]
                    remove.add(name)
                else:
                    key = (d["cond"], d["yes"], d["no"])
                    prior = prior_by_key.get((d["block"], key))
                    if prior:
                        replacements[name] = prior
                        remove.add(name)
                    else:
                        prior_by_key[(d["block"], key)] = name
            if not replacements:
                break
            removed_lines = {defs[name]["line"] for name in remove}
            body = "\n".join(
                line for index, line in enumerate(lines)
                if index not in removed_lines
            )
            body = ssa_token_re.sub(
                lambda match: replacements.get(match.group(0), match.group(0)),
                body,
            )
            chunk = body + ("\n" if chunk.endswith("\n") else "")
            total += len(replacements)
        rebuilt.append(chunk)
    return "".join(rebuilt), total


def canonicalize_frame_geps(ir: str, global_name: str, top: int, frame_size: int):
    """Materialize repeated constant frame addresses once per function.

    The recovered frame is one shared byte object, so a function-local GEP is
    an exact pointer identity and does not change aliasing.  Keeping the
    canonical pointers in SSA removes hundreds of repeated textual
    ``getelementptr @frame, 16711680`` expressions while leaving dynamic frame
    offsets untouched.
    """
    frame_re = re.compile(rf"@{re.escape(global_name)}")
    direct_re = re.compile(
        rf"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*"
        rf"\(i8,\s*ptr\s+@{re.escape(global_name)},\s*i64\s+(-?\d+)\)"
    )
    rebuilt = []
    materialized = 0
    # Keep this rewrite inside the declared object.  A textual GEP can be
    # intentionally out of bounds (for a later fault), and replacing that
    # spelling with a local chain must not turn its provenance/UB behaviour
    # into a different one.
    if top < 0 or top > frame_size:
        return ir, 0
    for name, start, end, body in function_spans(ir):
        if not frame_re.search(body):
            rebuilt.append((start, end, body))
            continue
        offsets = sorted(
            {
                int(value)
                for value in direct_re.findall(body)
                if 0 <= int(value) <= frame_size
            }
        )
        if not offsets:
            rebuilt.append((start, end, body))
            continue
        used = set(re.findall(r"%[-A-Za-z$._0-9]+", body))

        def fresh(stem: str):
            candidate = stem
            suffix = 0
            while candidate in used:
                suffix += 1
                candidate = f"{stem}.{suffix}"
            used.add(candidate)
            return candidate

        top_name = fresh("%delift.frame.top")
        definitions = [
            f"  {top_name} = getelementptr i8, ptr @{global_name}, i64 {top}"
        ]
        replacement = {}
        for offset in offsets:
            if offset == top:
                replacement[offset] = top_name
                continue
            slot_name = fresh("%delift.frame.slot")
            delta = offset - top
            # Deliberately omit `inbounds`: some lifted offsets are negative
            # bookkeeping addresses, and adding inbounds would introduce UB.
            definitions.append(
                f"  {slot_name} = getelementptr i8, ptr {top_name}, i64 {delta}"
            )
            replacement[offset] = slot_name
        rewritten_lines = []
        for line in body.splitlines():
            # A nested constant expression (phi incoming, ptrtoint/add
            # operand, global-style initializer) cannot reference a local SSA
            # value.  Leave those exact spellings alone; ordinary load/store
            # pointer operands are safe to canonicalize.
            if "ptrtoint (ptr" in line or re.search(r"\bphi\b", line):
                rewritten_lines.append(line)
                continue
            for offset, value in replacement.items():
                line = re.sub(
                    rf"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*"
                    rf"\(i8,\s*ptr\s+@{re.escape(global_name)},\s*i64\s+{offset}\)",
                    value,
                    line,
                )
            rewritten_lines.append(line)
        body = "\n".join(rewritten_lines)
        entry = re.search(r"^entry:\s*\n", body, re.M)
        if entry:
            insert_at = entry.end()
            # PHIs must remain the first instructions in a block.  The old
            # insertion point placed the canonical GEPs before entry PHIs,
            # producing invalid IR on functions whose entry block carries a
            # dispatcher state value.
            while True:
                phi = re.match(
                    r"[ \t]*%[-A-Za-z$._0-9]+\s*=\s*phi\b[^\n]*(?:\n|$)",
                    body[insert_at:],
                )
                if not phi:
                    break
                insert_at += phi.end()
            body = body[:insert_at] + "\n".join(definitions) + "\n" + body[insert_at:]
        else:
            first_label = re.search(r"^[A-Za-z$._0-9-]+:\s*\n", body, re.M)
            if not first_label:
                rebuilt.append((start, end, body))
                continue
            insert_at = first_label.end()
            while True:
                phi = re.match(
                    r"[ \t]*%[-A-Za-z$._0-9]+\s*=\s*phi\b[^\n]*(?:\n|$)",
                    body[insert_at:],
                )
                if not phi:
                    break
                insert_at += phi.end()
            body = body[:insert_at] + "\n".join(definitions) + "\n" + body[insert_at:]
        materialized += len(definitions)
        rebuilt.append((start, end, body))

    if not rebuilt:
        return ir, 0
    # Function spans are non-overlapping and cover only function bodies.  Use
    # their original offsets to preserve all module-level text verbatim.
    out = []
    cursor = 0
    for start, end, body in rebuilt:
        out.append(ir[cursor:start])
        out.append(body)
        cursor = end
    out.append(ir[cursor:])
    return "".join(out), materialized


if frame_name:
    frame_input = text
    text, folded_deltas = fold_same_anchor_deltas(text, frame_name)
    text, flattened_frame_geps = flatten_constant_frame_geps(
        text, frame_name, frame_size
    )
    # Candidate top pointers are large constant GEPs into the synthetic frame.
    direct_offsets = [
        int(value)
        for value in re.findall(
            rf"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\(i8,\s*ptr\s+@{re.escape(frame_name)},\s*i64\s+(-?\d+)\)",
            text,
        )
    ]
    top = max(direct_offsets, key=lambda value: (value > frame_size // 2, value), default=0)
    top_candidates = [value for value in direct_offsets if value == top]
    if top_candidates and top > 0:
        top_pattern = rf"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\(i8,\s*ptr\s+@{re.escape(frame_name)},\s*i64\s+{top}\)"
        marker = "__FRAME_TOP__"
        text, direct_n = re.subn(top_pattern, marker, text)
        # Normalize constant expressions relative to the discovered top.
        text = re.sub(
            rf"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\(i8,\s*ptr\s+@{re.escape(frame_name)},\s*i64\s+(-?\d+)\)",
            lambda m: f"__FRAME_PTR_{int(m.group(1)) - top}__",
            text,
        )
        # The common lifted forms use a top pointer followed by a constant or
        # a dynamic delta.  Keep dynamic deltas intact but normalize constants.
        nested = re.compile(r"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\(i8,\s*ptr\s+__FRAME_TOP__,\s*i64\s+(-?\d+)\)")
        text = nested.sub(lambda m: f"__FRAME_PTR_{int(m.group(1))}__", text)
        nested_slot = re.compile(
            r"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*"
            r"\(i8,\s*ptr\s+__FRAME_PTR_(-?\d+)__,\s*i64\s+(-?\d+)\)"
        )
        while True:
            text, combined = nested_slot.subn(
                lambda m: f"__FRAME_PTR_{int(m.group(1)) + int(m.group(2))}__",
                text,
            )
            if not combined:
                break
        frame_slots = {int(x) for x in re.findall(r"__FRAME_PTR_(-?\d+)__", text)}
        frame_slots.add(0)
        text = text.replace(
            "__FRAME_TOP__",
            f"getelementptr (i8, ptr @{frame_name}, i64 {top})",
        )
        for offset in sorted(frame_slots):
            absolute = top + offset
            # Placeholders are restored to the exact original frame GEP.  Do
            # not invent a compact backing object or an out-of-bounds alias.
            text = text.replace(
                f"__FRAME_PTR_{offset}__",
                f"getelementptr (i8, ptr @{frame_name}, i64 {absolute})",
            )
        text, frame_ssa_defs = canonicalize_frame_geps(
            text, frame_name, top, frame_size
        )
else:
    frame_ssa_defs = 0
    flattened_frame_geps = 0

text, dedup_selects = deduplicate_pointer_selects(text)

if "__FRAME_" in text:
    raise SystemExit("unresolved frame placeholders remain")
dst.write_text(text)
print(f"entry function: {entry_name or '<none>'}")
print(f"frame global: {frame_name or '<none>'}")
print(f"frame source size: {frame_size or 0}")
print(f"same-anchor constant deltas folded: {folded_deltas if frame_name else 0}")
print(f"constant affine frame GEPs flattened: {flattened_frame_geps if frame_name else 0}")
print(f"direct frame expressions: {direct_n}")
print(f"function-local frame pointers: {frame_ssa_defs if frame_name else 0}")
print(f"duplicate pointer selects removed: {dedup_selects}")
print(f"register stores preserved: {reg_stores}")
print(f"register loads preserved: {reg_loads}")
print(f"frame slots: {sorted(frame_slots)}")
