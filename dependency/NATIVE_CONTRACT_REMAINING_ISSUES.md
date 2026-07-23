# Native Contract Remaining Issues

Status: 2026-07-23

Branch: `agent/semantic-40-of-40`

## Validated baseline

The current implementation preserves the completed semantic recovery:

- Brightening: 40/40
- Semantic: 40/40
- Valid-domain: 40/40
- Native contract: 1/40 (`p03430`)
- Regression suite: PASS

The latest full result is `result/pipeline_20260723_220323`. Result directories are
local validation evidence and are not part of the commit.

## Remaining native-contract findings

| Finding | Cases |
| --- | ---: |
| Stack backing global | 39 |
| Flattened dispatcher | 21 |
| Lifted global | 7 |
| Stack backing allocation | 7 |
| State type | 7 |
| Generated address conversion | 6 |
| Guest stack function ABI | 5 |
| Stack `inttoptr` | 3 |
| `undef`/`poison` | 1 |
| Raw segment type | 0 |

These counts are overlapping findings, not distinct case counts.

## Confirmed blockers

### Stack-frame recovery

- `p00033` has a cyclic affine RBP transition of `-8` and an unproven store:
  `store i64 %state_2328.1.i, ptr %33`.
- `p00165`, `p00788`, and `p02100` have cyclic RSP transitions of
  `-80/-128`, `-48`, and `-64`.
- `p01315` retains cyclic/prologue stack transitions.
- `p02029` and `p03510` require recovery through recursive helpers.
- `p03142` combines cyclic aggregate RSP state with an unproven store location.
- `p03261` has no finite stack-pointer PHI and passes an unproven backing-derived
  value to a call.
- `p03835`, `p02474`, and `p03854` have no finite affine stack-pointer PHI.
- `p00678` calls its backing owner `sub_401150.14` 18 times, beyond the safe
  bounded-inlining model.
- `p03111` has recursive backing owners `sub_409950.60` and `sub_409bb0.92`,
  plus generated `scanf` destination dispatch and stack `inttoptr`.

The remaining stack cases need an explicit recovered frame ABI across recursive
or multi-owner helpers. Local rewriting or increasingly broad inlining is not
sufficiently safe.

### Flattened dispatchers

`p02950` demonstrates why frame compaction cannot run through an unresolved
flattened dispatcher. Dispatcher backedges also carry register state through
PHIs. Direct branch rewiring or early compaction can therefore preserve apparent
control flow while corrupting state.

These cases need real dispatcher unflattening or SSA/state promotion that
preserves PHI-carried register values.

### State ABI

The remaining State cases are:

- `p00001`
- `p00793`
- `p00859`
- `p01571`
- `p02814`
- `p03199`
- `p03434`

They retain real `@__mcsema_reg_state global %struct.State` usage or callback
boundaries. This is not only a dead identified-type-name problem; it requires
callback and state ABI lowering.

### Generated address conversions

Generated address conversions and stack `inttoptr` operations cannot be removed
by name-based suppression. They must be rewritten only after provenance-safe
frame and destination recovery proves the underlying address.

## Unsafe approaches tested and reverted

- Rewriting an external-call incoming `RSP-8` value to RSP helped `p00033` but
  crashed `p02950`.
- Allowing exact affine accesses without a finite stack-pointer PHI made
  `p03835` pass the native contract but reduced semantic recovery to 2/100.
- Treating a generated data-pointer select fallback as frame provenance created
  no additional native passes and weakened the proof boundary.
- Raising the backing-owner inlining limit from 8 to 24 preserved semantic
  behavior but worsened `p00678` from one contract finding to three.
- Adding late `instcombine` produced poison vector splats.

All of these experiments were removed. The current code keeps the safe
behavioral baseline instead of trading one passing case for regressions in
another.

## Completed improvement

Residual globals using identified `seg_*` top-level constant structs are now
canonicalized to layout-equivalent literal structs while preserving packedness,
element types, initializers, linkage, address space, TLS, metadata, and
attributes.

This reduced raw segment-type findings from 24 to 0 without semantic or
valid-domain regressions.

## Recommended next work

1. Implement true dispatcher unflattening or state SSA promotion.
2. Define a recovered stack-frame ABI for recursive and multi-owner helpers.
3. Lower the callback/state ABI for the seven remaining State cases.
4. Clean generated address conversions only after provenance-safe recovery.
5. Keep `p02950` and `p03835` as safety regressions for every broader proof rule.
