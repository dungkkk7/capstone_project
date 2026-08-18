# Deobfuscate 095 — rule-first LLVM engine

`095` is the expression and predicate deobfuscation stage used by the clean-IR
pipeline. Its hot path is deterministic and does not invoke SMT.

## Architecture

1. Match the independently implemented Chernobog identity catalog.
2. Rewrite 108 MBA identities to a simpler LLVM expression.
3. Apply direct predicate and conditional-jump rules.
4. Repeat to a bounded fixpoint.
5. Optionally run a small Z3 fallback on unmatched expressions only.

The public rule names and mathematical identities are tracked against
`19h/chernobog` revision
`d272b5dffbfbcaea479fb64e469577c2d8011c4c`. This directory does not reuse the
former capstone `Chernobog*Rules.{cpp,h}` implementation. The matcher,
catalog, LLVM materializer, reports, and tests are a fresh LLVM-IR
implementation.

## Catalog contract

- 108 MBA rules.
- 22 direct predicate rules.
- 9 direct jump rules.
- Lazy commutative matching for add, multiply, and/or/xor.
- Exact-width constants and repeated-variable bindings.
- `not` is recognized as `xor -1`; `neg` as `sub 0`; `mul 2` also matches the
  common LLVM `shl 1` spelling.
- Rules carrying `nsw`, `nuw`, or `exact` assumptions are not matched by the
  bit-vector catalog.

Run exact catalog certification with:

```bash
opt-21 -load-pass-plugin build/lib095.so \
  -095-verify-rule-catalog \
  -095-report=/tmp/095.json \
  -passes=095 input.ll -disable-output
```

Every MBA identity is proved by Z3 at i1, i8, i16, i32, and i64 during that
certification command. CI requires all 108 rules to pass.

## Runtime options

The default production path performs zero Z3 queries.

```text
-095-max-rounds=N
-095-enable-z3-fallback
-095-max-predicate-z3-candidates=N
-095-max-mba-candidates=N
-095-max-mba-recipes-per-expression=N
-095-z3-timeout-ms=N
-095-verify-rule-catalog
-095-rule-catalog-timeout-ms=N
-095-report=PATH
```

Candidate limits alone do not enable SMT. `-095-enable-z3-fallback` is required,
which prevents an old command line from accidentally restoring the slow
scan-every-expression behavior.

## Scope of “100%”

The testable guarantee is that 100% of the 108 registered MBA identities are
present and pass exact bit-vector equivalence checks at the certified widths.
This is not a claim that every possible future obfuscation is one of those
identities. Unmatched expressions remain unchanged unless the explicit Z3
fallback proves a replacement.
