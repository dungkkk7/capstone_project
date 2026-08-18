# Repository-owned command-line dataset v1

This directory contains 40 deterministic C11 command-line programs authored
for this repository on 2026-08-15. They were not copied from CodeNet,
HumanEval, MBPP, ExeBench, or another public benchmark. Ordinary algorithmic
ideas are not claimed as novel; the exact source instances, constants, input
contracts, seeds, and combinations are newly authored.

The taxonomy is balanced at five cases per category:

1. parsing and state machines;
2. numeric and bitwise behavior;
3. arrays and windows;
4. strings and encodings;
5. structural control flow;
6. graph algorithms;
7. data structures;
8. checksums and structured formats.

Each case has one source under `src/`, one frozen seed under `seeds/`, and one
corresponding ELF under `obfuscated/`. `manifest.json` freezes source/seed
SHA-256 values and stdout oracles. `build_manifest.json` records compiler,
LLVM, pass-plugin, transformed-bitcode, binary hashes, commands, and marker
counts for `instsub`, `fla`, and `bcf`.

The binaries are produced by the auditable LLVM 21 plugin in
`tools/own_obfuscator`, using:

```text
C11 -O0 bitcode
  -> reg2mem
  -> own-instsub
  -> own-fla
  -> own-bcf
  -> LLVM verifier
  -> x86_64 ELF
```

Reproduce the integrity gate or rebuild all binaries from repository root:

```bash
python3 tools/build_own_dataset.py --plain-only
python3 tools/build_own_dataset.py
```

Recovery models receive only binary-derived evidence. Source, seed, oracle,
manifest, and input-contract files must never enter a recovery prompt. This
dataset mitigates exact-answer memorization but cannot prove a model has never
learned the component algorithms. Results must therefore be described as
contamination-resistant evidence, not proof of zero training overlap.
