# Brighten OLLVM deobfuscation resilience fix

## Scope of the supplied run

The supplied `pipeline_20260720_235931` contains 49 case directories.
An artifact-level audit found:

| Class | Count | Meaning |
|---|---:|---|
| `pass_detected_scope` ledgers | 30 | Deobfuscation proof completed for detected scope |
| `partial_with_residuals` ledgers | 12 | The pass stopped fail-closed because required proof was incomplete |
| Missing proof ledgers | 7 | Processing stopped before a ledger was published, or the pipeline failed to bind/persist it |
| Semantic reports | 30 | 28 reported pass, 2 reported non-pass |
| Native-contract reports found | 32 | All are `compat_runnable`, all are `non_compliant` |

The seven cases without a proof ledger are:

`p00035`, `p00100`, `p00120`, `p00142`, `p00187`, `p00414`, and `p00818`.

`p00035` and `p00100` are directly covered by the supplied verifier logs. The
other five have no captured stderr/backtrace in the archive, so they cannot be
honestly assigned the same root cause from artifacts alone. `p00120` is also
special: it contains a brightened bitcode file and native report but no proof
ledger or semantic report, which points to a later publication/harness failure
or an interrupted multi-stage run rather than proving a dispatcher crash.

## Root cause 1: header SSA values survive into cloned plumbing

The concrete verifier failures have this form:

```llvm
%28 = lshr i32 %deobf.dispatch.state.cell.1.reload.reload1588, 31
%.deobf.plumbing1989 = xor i32 %.deobf.plumbing1987, %28
```

`tryRecoverGeneralFunnelPlumbingDispatcher` cloned a returning round in the
order `Sink -> Outer -> Header`. Values defined in the old lookup Header could
still be operands of existing or cloned Sink/Outer/case instructions. After the
old dispatcher was bypassed, those old Header definitions no longer dominated
their uses. The verifier therefore rejected `%28`, `%29`, and analogous
instructions.

### Fix

Before cloning/relinking the general-funnel CFG, the pass now:

1. Demotes Header PHIs with `DemotePHIToStack`.
2. Demotes every non-void Header instruction with a use outside Header using
   `DemoteRegToStack`.
3. Clones the resulting stores/reloads instead of retaining references to the
   obsolete Header SSA definitions.
4. Records `llvm_header_phi_and_liveout_demotion` in the proof dependencies.

This preserves the round semantics: the current case consumes the value stored
by the preceding Header round, then the cloned Header computes/stores the value
for the next round.

## Root cause 2: saved transition conditions become stale after reg2mem

Three plumbing engines cached a raw `Value *Condition` during proof discovery,
then demoted PHIs/registers and later built a new conditional branch from that
old pointer. Reg2mem can replace a select operand with a source-local reload.
Using the pre-demotion pointer can therefore create a non-dominating branch
operand or move a decision across side effects.

### Fix

The general-funnel, partitioned-SSA-plumbing, and SSA-plumbing engines now:

- retain the owning `SelectInst *`;
- require the select to be owned by the transition source block before moving
  the decision to that source edge;
- refresh `Selector->getCondition()` after all PHI/live-out demotions;
- use the per-edge clone map when the refreshed condition or finite-state value
  was cloned.

The source-ownership check is intentionally conservative. Unsupported shapes
remain residuals rather than being rewritten speculatively.

## Root cause 3: one bad rewrite aborted the whole `opt` process

The previous dispatcher/compare-ladder path called `report_fatal_error` as soon
as `verifyFunction` rejected a rewrite. That made one candidate destroy the
entire case, prevented the proof ledger from being written, and lost all safe
work already completed in the module.

### Fix

Each dispatcher and compare-ladder candidate is now a function-body
transaction:

1. Clone the exact pre-rewrite function body.
2. Perform the rewrite.
3. Verify the rewritten function.
4. Commit only when verification succeeds.
5. Otherwise restore the cloned body, mark that candidate
   `ollvm.deobf.verifier_rejected`, emit an unresolved
   `transactional_verifier_guard` proof record, and continue with a fresh
   worklist.

The guard also detects a candidate attempt for which no recovery engine reports
success but the function body nevertheless changed. Such an attempt is rolled
back and recorded as `transactional_mutation_guard`.

This changes the expected failure mode from an LLVM process abort to a valid
bitcode output plus `partial_with_residuals`. It does not falsely label the
candidate as recovered.

## The two reported semantic failures do not reproduce from saved artifacts

Neither of the 30 historical semantic reports binds `prog2` to a hash of the
saved IR or generated executable. Replaying the exact payload corpus after
recompiling each saved `*_brightened.ll` produced:

| Case | Historical report | Saved-artifact replay | Stored `prog2` examples reproduced |
|---|---|---|---:|
| `p03114` | 0/100 match | 100/100 match | 0/5 |
| `p00624` | 74/75 match, then reference SIGSEGV vs `prog2` success | 100/100 match over all 100 recorded payloads | 0/1 |

The local forensic compiler was Clang 17, so LLVM-21-only textual markers
`icmp samesign` and `captures(none)` were removed in a temporary copy. The
saved files themselves were not modified. The included replay tool defaults to
Clang 21 and untouched bitcode; that is the authoritative way to repeat this on
the target machine.

The evidence establishes that the historical `prog2` output is not
reproducible from the artifact stored beside the report. It strongly suggests
a stale/shared/wrong executable path or report-to-artifact publication race,
but the archive does not contain the original transient executable, so the
exact harness race cannot be proven post hoc.

### Harness fix

`tests/differential_validate.py` now emits schema v2 reports with SHA-256
bindings for:

- source and transformed IR;
- pass plugin;
- `opt`, `clang`, and `llvm-dis` binaries/version output;
- generated before/after executables;
- payload report;
- complete captured mismatch streams.

Executable filenames are content-addressed inside a private temporary
directory. `tools/replay_semantic_report.py` independently rebuilds and replays
a published artifact, while `tools/audit_pipeline_results.py` separates
verifier crashes, proof residuals, semantic results, and native-contract
findings.

## Why native contract is 0 PASS

The native-contract result is not the same metric as semantic correctness or
OLLVM dispatcher recovery. All 32 native reports in the archive are classified
`compat_runnable` and `non_compliant`; every one includes
`guest stack backing allocation: main`, while harder cases also retain lifted
state/ABI, inline assembly, raw segment types, poison/undef, or Remill/McSema
artifacts.

Those transformations and the native-contract checker are not present in the
uploaded pass repository. This patch therefore does not pretend to turn native
contract 0/30 into PASS. That requires the separate lift-to-native cleanup
stage and its checker/policy source. Relaxing the checker inside this repository
would only falsify the metric.

The archive contains 32 native reports although the console summary uses a
30-case brightening denominator because `p00016` (partial ledger) and `p00120`
(missing ledger/semantic report) also have native reports.

## The 12 partial cases are proof gaps, not verifier crashes

The residual records break down as follows:

- 20 dispatcher residual records: memory-join recurrence has incomplete store
  coverage, usually with an `alias-barrier` on an unproved reaching state.
- 3 records: transparent-state-carrier resolution plus
  `reachable-unproved-transition`.
- 3 records: transparent-state-carrier resolution plus `latch-phi-pair`.
- 1 record (`p00016`): lookup-region discovery plus an unclassified returning
  case.

The counts are proof records, not case counts; one case can contain several
unresolved dispatchers. These are deliberately left fail-closed. Forcing those
paths through by assuming alias equality or guessing a state transition would
increase the displayed completion count at the cost of possible miscompiles.
The patch improves the unclassified-returning-case diagnostic with the exact
case block and reason.

## Added regression

`tests/general_funnel_header_liveout_dominance.ll` contains:

- a Header PHI;
- the observed `lshr -> xor -> add` live-out pattern;
- Header live-outs consumed in both a case and Sink plumbing;
- a select whose condition is a Header live-out;
- CFG structure that targets `complete_general_funnel_ssa_plumbing`.

The test requires the output to verify, execute with status 0, contain no
remaining dispatcher switch, and carry the new proof dependency.

## Validation performed in this workspace

Completed:

- source and patch whitespace validation (`git diff --check`);
- Python bytecode compilation for all modified/new Python tools;
- baseline parse/compile/execute of the new regression IR with local Clang 17
  (exit status 0);
- full 100-payload replay for `p03114` and `p00624`;
- artifact-level audit of all 49 supplied case directories;
- API review against LLVM 21.1.8 declarations for `CloneFunction`,
  `Function::deleteBody`, and `Function::splice`.

Not completed in this workspace:

- rebuilding/loading the plugin against LLVM 21;
- running the transformed regression through the new plugin;
- rerunning all 49 original cases.

The container does not contain LLVM 21 headers, `opt-21`, or
`libLLVM.so.21.1`; the old bundled `.so` cannot be used to validate changed C++
source. Build and runtime commands below must be run on the supplied target
machine.

## Build and validation commands

```bash
cd brighten_095_ollvm_deobf_resilience_fix
rm -rf build
cmake -S . -B build \
  -DLLVM_DIR=/usr/lib/llvm-21/cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j"$(nproc)"

export LLVM_SYMBOLIZER_PATH="$(command -v llvm-symbolizer-21)"
tests/run_tests.sh
```

Audit the old pipeline:

```bash
python3 tools/audit_pipeline_results.py \
  /home/dungbv/capstone_project/result/pipeline_20260720_235931 \
  --report pipeline_20260720_235931_audit.json
```

Replay the two historical semantic non-pass reports using untouched LLVM 21
bitcode:

```bash
python3 tools/replay_semantic_report.py \
  --case-dir /home/dungbv/capstone_project/result/pipeline_20260720_235931/p03114 \
  --clang clang-21 --report p03114_replay.json

python3 tools/replay_semantic_report.py \
  --case-dir /home/dungbv/capstone_project/result/pipeline_20260720_235931/p00624 \
  --clang clang-21 --report p00624_replay.json
```

For the original failing normalization command, keep `verify` in the pipeline:

```bash
opt-21 \
  -load-pass-plugin ./build/BrightenOLLVMDeobfPass.so \
  -ollvm-deobf-report=normalization-ledger.json \
  -passes='brighten-ollvm-deobf-pass,jump-threading,simplifycfg,adce,verify' \
  input.bc -o normalized.bc
```

Expected behavior after the patch:

- `p00035`/`p00100` should no longer terminate `opt` with the observed Header
  live-out dominance error;
- a remaining verifier rejection is rolled back and published as a residual
  rather than invalid IR or a process abort;
- historical semantic results become artifact-bound and replayable;
- proof-incomplete and native-contract-incomplete cases remain honestly
  classified until their separate proof/native transformations are implemented.
