#!/usr/bin/env python3
"""Remove synthetic register/frame storage without assuming a program name.

The input is textual LLVM IR because this pass deliberately runs before the
normal LLVM optimiser.  All names and frame geometry are discovered from the
module's globals and function metadata; no ``main``, 16 MiB, or 256-byte
assumption is part of the transformation.
"""

from pathlib import Path
import os
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
        spans.append((match.group(1), match.start(), match.start() + (close + 2 if close >= 0 else len(body)), body))
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
frame_slots = set()
frame_addrs = set()
frame_corrs = set()

if frame_name and os.environ.get("DELIFT_EXPERIMENTAL_FRAME_COMPACTION") == "1":
    frame_input = text
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
        text = text.replace(f"@{frame_name}", "__FRAME_BASE__")
        # The common lifted forms use a top pointer followed by a constant or
        # a dynamic delta.  Keep dynamic deltas intact but normalize constants.
        nested = re.compile(r"getelementptr(?:\s+inbounds(?:\s+\w+)*)?\s*\(i8,\s*ptr\s+__FRAME_TOP__,\s*i64\s+(-?\d+)\)")
        text = nested.sub(lambda m: f"__FRAME_PTR_{int(m.group(1))}__", text)
        frame_slots = {int(x) for x in re.findall(r"__FRAME_PTR_(-?\d+)__", text)}
        frame_slots.add(0)
        # If the frame global is used in several functions, a single local
        # alloca cannot be valid for all users; retain the discovered global
        # geometry and avoid emitting invalid SSA.
        users = [name for name, _, _, body in function_spans(text) if "__FRAME_BASE__" in body or "__FRAME_TOP__" in body]
        local_mode = bool(entry_name and len(set(users)) <= 1)
        if local_mode:
            low = min(frame_slots)
            high = max(frame_slots)
            alignment = 16
            capacity = max(alignment, high - low + alignment)
            top_index = -low + alignment
            entry = next((item for item in function_spans(text) if item[0] == entry_name), None)
            if entry:
                _, start, end, body = entry
                body = body.replace("__FRAME_BASE__", "%delift.frame.base")
                body = body.replace("__FRAME_TOP__", "%delift.frame.top")
                for offset in sorted(frame_slots):
                    body = body.replace(f"__FRAME_PTR_{offset}__", f"%delift.frame.slot.{offset}")
                defs = [
                    f"  %delift.frame.storage = alloca [{capacity} x i8], align {alignment}",
                    f"  %delift.frame.base = getelementptr inbounds i8, ptr %delift.frame.storage, i64 {alignment}",
                    f"  %delift.frame.top = getelementptr inbounds i8, ptr %delift.frame.base, i64 {top_index - alignment}",
                ]
                for offset in sorted(frame_slots):
                    defs.append(f"  %delift.frame.slot.{offset} = getelementptr inbounds i8, ptr %delift.frame.top, i64 {offset}")
                entry_pos = body.find("entry:\n")
                if entry_pos >= 0:
                    body = body[: entry_pos + len("entry:\n")] + "\n".join(defs) + "\n" + body[entry_pos + len("entry:\n"):]
                    text = text[:start] + body + text[end:]
                    text = re.sub(rf"^@{re.escape(frame_name)}\s*=.*\n", "", text, flags=re.M)
                else:
                    local_mode = False
            if local_mode and "__FRAME_" in text:
                local_mode = False
        if not local_mode:
            # Keep a valid, input-derived backing global for multi-entry IR.
            # The local compaction is unsafe when several functions share the
            # synthetic global, so retain the original frame expressions.
            text = frame_input

if "__FRAME_" in text:
    raise SystemExit("unresolved frame placeholders remain")
dst.write_text(text)
print(f"entry function: {entry_name or '<none>'}")
print(f"frame global: {frame_name or '<none>'}")
print(f"frame source size: {frame_size or 0}")
print(f"direct frame expressions: {direct_n}")
print(f"register stores preserved: {reg_stores}")
print(f"register loads preserved: {reg_loads}")
print(f"frame slots: {sorted(frame_slots)}")
