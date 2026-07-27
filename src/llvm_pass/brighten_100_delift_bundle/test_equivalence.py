#!/usr/bin/env python3
import json, random, subprocess, sys
from pathlib import Path

def run(path, xs):
    p = subprocess.run([str(path)], input=(' '.join(map(str, xs)) + '\n').encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=3)
    return p.returncode, p.stdout, p.stderr


def main(argv):
    bins = [Path(p) for p in argv]
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

    mismatches = []
    for idx, xs in enumerate(cases):
        results = [run(path, xs) for path in bins]
        if any(result != results[0] for result in results[1:]):
            mismatches.append({
                'case_index': idx,
                'input': xs,
                'results': [
                    {
                        'binary': str(path),
                        'returncode': result[0],
                        'stdout': result[1].decode(errors='replace'),
                        'stderr': result[2].decode(errors='replace'),
                    }
                    for path, result in zip(bins, results)
                ],
            })
            if len(mismatches) >= 10:
                break

    report = {
        'case_count': len(cases),
        'binaries': [str(path) for path in bins],
        'all_equal': not mismatches,
        'mismatch_count': len(mismatches),
        'mismatches': mismatches,
    }
    print(json.dumps(report, indent=2))
    return 0 if not mismatches else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
