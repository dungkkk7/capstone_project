#!/usr/bin/env python3
"""Semantics-preserving cleanup of repeated native pointer resolver selects."""
from pathlib import Path
import re
import sys

src, dst = map(Path, sys.argv[1:3])
ir = src.read_text()
select_re = re.compile(r"^(\s*)(%[-A-Za-z$._0-9]+)\s*=\s*select i1 (%[-A-Za-z$._0-9]+), ptr (%[-A-Za-z$._0-9]+), ptr (%[-A-Za-z$._0-9]+)\s*$")
ssa_token_re = re.compile(r"(?<![-A-Za-z$._0-9])%[-A-Za-z$._0-9]+")
removed = 0
chunks = re.split(r"(?=^define\b)", ir, flags=re.M)
out = []
for chunk in chunks:
    if not chunk.startswith("define"):
        out.append(chunk); continue
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
                data = list(m.groups())
                defs[m.group(2)] = {
                    "data": data,
                    "line": index,
                    "block": block,
                }

        refs = {name: [] for name in defs}
        for index, line in enumerate(lines):
            # Resolver-heavy IR may contain thousands of selects.  Tokenize
            # each line once instead of compiling one regex per definition.
            for name in set(ssa_token_re.findall(line)):
                if name in refs:
                    refs[name].append((index, blocks[index]))

        def locally_safe(name, item):
            for index, owner in refs.get(name, ()):
                if index == item["line"]:
                    continue
                if owner != item["block"] or index <= item["line"]:
                    return False
            return True

        repl, drop = {}, set()
        prior_by_key = {}
        for name, item in defs.items():
            d = item["data"]
            if not locally_safe(name, item):
                continue
            nested = defs.get(d[4])
            if (
                nested
                and d[4] not in drop
                and nested["block"] == item["block"]
                and nested["line"] < item["line"]
                and nested["data"][2] == d[2]
                and nested["data"][3] == d[3]
                and locally_safe(d[4], nested)
            ):
                repl[name] = d[4]; drop.add(name)
            else:
                key = tuple(d[2:])
                prior = prior_by_key.get((item["block"], key))
                if prior: repl[name] = prior; drop.add(name)
                else: prior_by_key[(item["block"], key)] = name
        if not repl: break
        removed_lines = {defs[name]["line"] for name in drop}
        lines = [
            line for index, line in enumerate(chunk.splitlines())
            if index not in removed_lines
        ]
        chunk = "\n".join(lines) + ("\n" if chunk.endswith("\n") else "")
        chunk = ssa_token_re.sub(
            lambda match: repl.get(match.group(0), match.group(0)),
            chunk,
        )
        removed += len(repl)
    out.append(chunk)
dst.write_text("".join(out))
print(f"duplicate pointer selects removed: {removed}")
