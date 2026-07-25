#!/usr/bin/env python3
import json, random, subprocess, sys
from pathlib import Path

bins = [Path(p) for p in sys.argv[1:]]
if len(bins) < 2:
    raise SystemExit('usage: test_equivalence.py BIN1 BIN2 [BIN3 ...]')

cases = [
    list(range(10)),
    list(range(9, -1, -1)),
    [5] * 10,
    [-5, -1, -9, 0, 3, 3, 2, -2, 8, 7],
    [-2147483648, 2147483647, 0, 1, -1, 123, -123, 999, -999, 42],
]
rng = random.Random(0xB16B00B5)
for _ in range(1000):
    cases.append([rng.randint(-2**31, 2**31 - 1) for _ in range(10)])

def run(path, xs):
    p = subprocess.run([str(path)], input=(' '.join(map(str, xs)) + '\n').encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=3)
    return p.returncode, p.stdout, p.stderr

mismatches=[]
for idx, xs in enumerate(cases):
    results=[run(p,xs) for p in bins]
    if any(r != results[0] for r in results[1:]):
        mismatches.append({
            'case_index': idx,
            'input': xs,
            'results': [
                {'binary': str(p), 'returncode': r[0], 'stdout': r[1].decode(errors='replace'), 'stderr': r[2].decode(errors='replace')}
                for p,r in zip(bins,results)
            ]
        })
        if len(mismatches) >= 10:
            break

report={
    'case_count': len(cases),
    'binaries': [str(p) for p in bins],
    'all_equal': not mismatches,
    'mismatch_count': len(mismatches),
    'mismatches': mismatches,
}
print(json.dumps(report, indent=2))
sys.exit(0 if not mismatches else 1)
