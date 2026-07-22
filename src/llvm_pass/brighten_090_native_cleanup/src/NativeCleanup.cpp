#include "NativeCleanup.h"
#include "NativeCleanupInternal.h"
#include "NativeStateSSA.h"

#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace brighten_native_cleanup {

cl::opt<bool> NativeStrict(
    "brighten-native-strict",
    cl::desc("Fail unless the complete module satisfies the native IR contract"),
    cl::init(false));

cl::opt<bool> NativeStateSSA(
    "brighten-native-state-ssa",
    cl::desc("Lower native functions from State pointer ABI to SSA slots"),
    cl::init(false));

bool NativeCleanupPass::cleanupModule(Module &M, bool EnforceStrict,
                                      bool PostSouper) {
  // The final pipeline element is a verifier, not a second recovery pass.
  // Running the mutation pipeline again after O3 hides phase-ownership bugs.
  if (EnforceStrict) {
    bool Changed = false;
    unsigned FinalUndefinedScaffolds =
        lowerFullyOverwrittenUndefinedScaffolds(M);
    if (FinalUndefinedScaffolds) {
      Changed = true;
      errs() << "  final fully-overwritten undef/poison scaffolds normalized: "
             << FinalUndefinedScaffolds << "\n";
    }
    unsigned FinalUndefinedShuffleLanes =
        lowerUnobservedUndefinedShuffleLanes(M);
    if (FinalUndefinedShuffleLanes) {
      Changed = true;
      errs() << "  final unobserved undef/poison shuffle lanes normalized: "
             << FinalUndefinedShuffleLanes << "\n";
    }
    unsigned FinalVectorBroadcasts = lowerSingleLaneVectorBroadcasts(M);
    if (FinalVectorBroadcasts) {
      Changed = true;
      errs() << "  final single-lane vector broadcasts normalized: "
             << FinalVectorBroadcasts << "\n";
    }
    // The exact vector rewrites above can leave their old poison-seeded
    // insertelement scaffolds use-empty.  Remove those dead instructions
    // before the contract report so it describes the published module rather
    // than temporary operands with no observable users.
    if (cleanupNativeDeadInstructions(M))
      Changed = true;
    unsigned PromotedDispatchers = promoteStackDispatcherStateSlots(M, Changed);
    if (PromotedDispatchers)
      errs() << "  final stack dispatcher state slots promoted to SSA: "
             << PromotedDispatchers << "\n";
    unsigned FinalPointerIntegers =
        rewriteRecoveredPointerIntegerIdentities(M, Changed);
    if (FinalPointerIntegers)
      errs() << "  final recovered pointer integer identities lowered: "
             << FinalPointerIntegers << "\n";
    unsigned FinalStackRecoveredGEPs =
        rewriteRecoveredGlobalStackIndexedGEPs(M, Changed);
    if (FinalStackRecoveredGEPs)
      errs() << "  final recovered stack-indexed GEPs restored: "
             << FinalStackRecoveredGEPs << "\n";
    unsigned FinalVarargPointers =
        rewriteRecoveredVarargSaveSlots(M, Changed);
    if (FinalVarargPointers)
      errs() << "  final recovered variadic pointer save slots lowered: "
             << FinalVarargPointers << "\n";
    unsigned DeadInlineAsm = eraseUnusedInlineAsmCalls(M, Changed);
    if (DeadInlineAsm)
      errs() << "  final unused inline-asm calls erased: " << DeadInlineAsm
             << "\n";
    if (PostSouper) {
      unsigned AggregatePassthroughs =
          forwardRecoveredAggregatePassthroughs(M, Changed);
      if (AggregatePassthroughs)
        errs() << "  post-Souper aggregate ABI passthroughs forwarded: "
               << AggregatePassthroughs << "\n";
      unsigned SimplifiedSignedCompares =
          simplifyRecoveredSignedCompareIdioms(M, Changed);
      if (SimplifiedSignedCompares)
        errs() << "  post-Souper recovered signed comparisons simplified: "
               << SimplifiedSignedCompares << "\n";
      unsigned EarlyAffineFramePointers =
          canonicalizeFrameBackingAffinePointers(M, Changed);
      if (EarlyAffineFramePointers)
        errs() << "  post-Souper early affine frame pointers canonicalized: "
               << EarlyAffineFramePointers << "\n";
      unsigned EarlyScanfShadows =
          isolateRecoveredScanfDestinations(M, Changed);
      if (EarlyScanfShadows)
        errs() << "  post-Souper early recovered scanf destinations isolated: "
               << EarlyScanfShadows << "\n";
      unsigned FinalDynamicFrames =
          localizeProvenDynamicFrameRegions(M, Changed);
      if (FinalDynamicFrames)
        errs() << "  post-Souper dynamic guest-frame regions localized: "
               << FinalDynamicFrames << "\n";
      unsigned FinalAffineFramePointers =
          canonicalizeFrameBackingAffinePointers(M, Changed);
      if (FinalAffineFramePointers)
        errs() << "  post-Souper affine frame pointers canonicalized: "
               << FinalAffineFramePointers << "\n";
      unsigned FinalForwardedStackLoads = 0;
      unsigned FinalStackDataSelects = 0;
      unsigned FinalRawNativeStackPointers = 0;
      // Forwarding one exact RSP spill can expose the frame fallback of a
      // generated data-select tree; collapsing that tree can in turn make the
      // next spill exact.  Iterate this proof chain to a fixed point instead
      // of depending on a case-specific number of nested recovered calls.
      for (;;) {
        unsigned Forwarded = forwardProvenAffineStackSlotLoads(M, Changed);
        unsigned Lowered = lowerRawNativeStackIntToPtrs(M, Changed);
        unsigned Collapsed =
            collapseFrameProvenantDataPointerSelects(M, Changed);
        FinalForwardedStackLoads += Forwarded;
        FinalRawNativeStackPointers += Lowered;
        FinalStackDataSelects += Collapsed;
        if (!Forwarded && !Lowered && !Collapsed)
          break;
      }
      if (FinalForwardedStackLoads)
        errs() << "  post-Souper proven affine stack loads forwarded: "
               << FinalForwardedStackLoads << "\n";
      if (FinalStackDataSelects)
        errs() << "  post-Souper stack-provenant data selects collapsed: "
               << FinalStackDataSelects << "\n";
      unsigned FinalScanfShadows =
          isolateRecoveredScanfDestinations(M, Changed);
      if (FinalScanfShadows)
        errs() << "  post-Souper recovered scanf destinations isolated: "
               << FinalScanfShadows << "\n";
      unsigned FinalCompactedFrames =
          compactProvenConstantFrameBackings(M, Changed);
      if (FinalCompactedFrames)
        errs() << "  post-Souper proven fake stack backings converted to "
                  "native frames: "
               << FinalCompactedFrames << "\n";
      // default<O3> can reassociate a recovered frame GEP back into an
      // inttoptr of an architectural RSP/RBP expression. Re-run only the
      // provenance-gated stack lowering here; arbitrary heap/data integer
      // pointers remain untouched. Keep this after data-select collapsing:
      // a newly recovered fallback does not by itself prove that every
      // pre-existing guest/global range arm is impossible.
      if (FinalRawNativeStackPointers)
        errs() << "  post-Souper raw guest stack inttoptrs lowered: "
               << FinalRawNativeStackPointers << "\n";
      unsigned FinalPrivateFrames =
          localizeProvenPrivateFrameArguments(M, Changed);
      if (FinalPrivateFrames)
        errs() << "  post-Souper private frame ABIs localized: "
               << FinalPrivateFrames << "\n";
    }
    unsigned FinalNativeDataArtifacts =
        eraseUnusedNativeDataArtifacts(M, Changed);
    if (FinalNativeDataArtifacts)
      errs() << "  final unused lifted segment artifacts removed: "
             << FinalNativeDataArtifacts << "\n";
    unsigned FinalNativeResidualSegments =
        canonicalizeLiveNativeResidualSegments(M, Changed);
    if (FinalNativeResidualSegments)
      errs() << "  final live residual segments canonicalized: "
             << FinalNativeResidualSegments << "\n";
    eraseUnusedInternalGlobals(M, Changed);
    stripRemillMetadata(M, Changed);
    reportNativeContract(M, 0, 0, true);
    return Changed;
  }

  bool Changed = false;
  SmallVector<std::string, 32> Violations;
  // Recovered guest ranges are required by the later scanf/external-pointer
  // lowering.  Strip them only after every such use has been materialized.
  stripRemillMetadata(M, Changed, false);

  unsigned ResidualLibcFormats = materializeResidualLibcFormats(M, Changed);
  if (ResidualLibcFormats)
    errs() << "  residual guest libc formats materialized: "
           << ResidualLibcFormats << "\n";
  preserveRecoveredGlobalsAcrossOptimization(M);

  unsigned WidenedRecoveredScalars =
      widenOverNarrowRecoveredScalars(M, Changed);
  if (WidenedRecoveredScalars)
    errs() << "  over-narrow recovered scalars widened: "
           << WidenedRecoveredScalars << "\n";

  unsigned DeadArguments = canonicalizeDeadLiftedArguments(M);
  if (DeadArguments) {
    Changed = true;
    errs() << "  dead lifted poison arguments canonicalized: " << DeadArguments
           << "\n";
  }

  // Do not fill an undef/poison PHI incoming edge in native mode.  A common
  // value on the other edges is not proof that the missing predecessor had
  // the same architectural state; the strict report must retain this gap.

  // Never freeze unresolved architectural values in the native pipeline.
  // `freeze` makes an unknown register/flag stable but does not recover its
  // machine meaning; strict certification must observe and reject it instead.
  unsigned UndefinedScaffolds = lowerFullyOverwrittenUndefinedScaffolds(M);
  if (UndefinedScaffolds) {
    Changed = true;
    errs() << "  fully-overwritten undef/poison scaffolds normalized: "
           << UndefinedScaffolds << "\n";
  }
  unsigned UndefinedShuffleLanes = lowerUnobservedUndefinedShuffleLanes(M);
  if (UndefinedShuffleLanes) {
    Changed = true;
    errs() << "  unobserved undef/poison shuffle lanes normalized: "
           << UndefinedShuffleLanes << "\n";
  }
  unsigned VectorBroadcasts = lowerSingleLaneVectorBroadcasts(M);
  if (VectorBroadcasts) {
    Changed = true;
    errs() << "  single-lane vector broadcasts normalized: "
           << VectorBroadcasts << "\n";
  }

  // Pointer-translation lowering may use an already-proven frame anchor, but
  // native cleanup never creates a synthetic stack to supply one.
  unsigned NativeTranslations =
      rewriteNativeScanfVarargAddresses(M, Changed);
  NativeTranslations += lowerProvenNativePointerTranslations(M, Changed);
  if (NativeTranslations)
    errs() << "  proven native pointer translations lowered: "
           << NativeTranslations << "\n";

  // Preserve callback entrypoints before wrapper inlining removes the only
  // link from a naked qsort trampoline to its lifted comparator body.
  // qsort invokes the trampoline with (lhs, rhs); once the wrapper is gone
  // there is no sound way to reconstruct that callback contract later.
  unsigned EarlyCallbackBridges =
      lowerNativeCallbackTrampolines(M, Changed);
  if (EarlyCallbackBridges)
    errs() << "  early native callback ABI bridges lowered: "
           << EarlyCallbackBridges << "\n";

  unsigned InlinedExternWrappers = inlineExternalLiftedWrappers(M, Changed);
  if (InlinedExternWrappers)
    errs() << "  external lifted wrappers inlined: "
           << InlinedExternWrappers << "\n";

  // Normalize libc arms in a surviving runtime-PC dispatcher before
  // State-SSA plans and rewrites its call graph.  Deferring this until after
  // State-SSA makes RewriteExternalNativeCalls reject the dispatcher plan
  // transaction on lifted variadic declarations such as vscanf.lifted_abi.
  unsigned EarlyNativeExternalABIs =
      normalizeNativeExternalABIs(M, Changed, &Violations);
  if (EarlyNativeExternalABIs)
    errs() << "  early native libc call ABIs normalized: "
           << EarlyNativeExternalABIs << "\n";
  unsigned EarlyQsortArrays = rewriteResidualQsortArrayArguments(M, Changed);
  if (EarlyQsortArrays)
    errs() << "  residual qsort array arguments recovered: "
           << EarlyQsortArrays << "\n";
  unsigned EarlyConstantGuestPointers =
      rewriteConstantGuestPointerOperands(M, Changed);
  if (EarlyConstantGuestPointers)
    errs() << "  early constant guest pointers lowered: "
           << EarlyConstantGuestPointers << "\n";
  unsigned EarlyMissingScanfDestinations =
      materializeMissingScanfDestinations(M, Changed);
  if (EarlyMissingScanfDestinations)
    errs() << "  missing scanf destinations materialized: "
           << EarlyMissingScanfDestinations << "\n";

  unsigned NativeDataPointers = materializeNativeSegmentPointers(M, Changed);
  if (NativeDataPointers)
    errs() << "  segment pointers materialized as native data: "
           << NativeDataPointers << "\n";
  unsigned MaterializedQsortArrays =
      rewriteResidualQsortArrayArguments(M, Changed);
  if (MaterializedQsortArrays)
    errs() << "  residual qsort array arguments recovered: "
           << MaterializedQsortArrays << "\n";

  // Strict mode is the production contract: do not let the old internal
  // State-pointer ABI survive merely because the optional optimization flag
  // was omitted.
  if (NativeStateSSA || NativeStrict) {
    bool StateSSAChanged = lowerNativeStateABI(M);
    if (!StateSSAChanged) {
      // The native ABI pass is transactional: false means either that there
      // was no proven native State plan or that a plan failed and was rolled
      // back.  The address/stack rewrites below depend on the SSA ABI and
      // must not run on the original lifted ABI after such a rollback.
      errs() << "  native State ABI not lowered; preserving dependent native rewrites\n";
    } else {
      Changed = true;
      errs() << "  native State ABI lowered to explicit SSA slots\n";

    // Entrypoint wrappers can contain scratch State/stack buffers even when
    // no additional `.native` function needed an SSA clone in this pass.
    if (lowerNativeMainStateBuffer(M)) {
      Changed = true;
      errs() << "  native entrypoint State scratch buffer removed\n";
    }
    if (lowerNativeMainStackBuffer(M)) {
      Changed = true;
      errs() << "  oversized guest stack scratch buffer lowered\n";
    }

    // Preserve translated stack integer addresses until the pass can prove
    // their guest-frame provenance.  Rewriting them from affine patterns
    // alone changes valid guest pointers into host stack addresses.
    unsigned NativeDataStackPointers = rewriteNativeDataStackGEPs(M, Changed);
    if (NativeDataStackPointers)
      errs() << "  translated stack GEPs rebased on native_stack: "
             << NativeDataStackPointers << "\n";
    if (cleanupNativeDeadInstructions(M))
      Changed = true;

    unsigned PreservedRBP = preserveNativeRBPOutputs(M, Changed);
    if (PreservedRBP)
      errs() << "  callee-saved native RBP outputs preserved: "
             << PreservedRBP << "\n";

    // Remove the analysis-only return markers before ABI normalization.  They
    // are hidden LLVM uses of old external call results and would otherwise
    // make a dead `free` return look live.
    unsigned EarlyReturnMarkers = eraseBrightenReturnMarkers(M, Changed);
    if (EarlyReturnMarkers)
      errs() << "  early transient RAX return markers erased: "
             << EarlyReturnMarkers << "\n";

    unsigned AllocatorRAX = repairNativeAllocatorRAX(M, Changed);
    if (AllocatorRAX)
      errs() << "  allocator return values restored in native RAX SSA: "
             << AllocatorRAX << "\n";

    unsigned NativeExternalABIs = normalizeNativeExternalABIs(
        M, Changed, &Violations);
    if (NativeExternalABIs)
      errs() << "  native libc call ABIs normalized: " << NativeExternalABIs
             << "\n";
    unsigned NativeQsortArrays = rewriteResidualQsortArrayArguments(M, Changed);
    if (NativeQsortArrays)
      errs() << "  residual qsort array arguments recovered: "
             << NativeQsortArrays << "\n";
    unsigned NativeConstantGuestPointers =
        rewriteConstantGuestPointerOperands(M, Changed);
    if (NativeConstantGuestPointers)
      errs() << "  native constant guest pointers lowered: "
             << NativeConstantGuestPointers << "\n";

    // State-ABI lowering can synthesize the final guest-base + dynamic-index
    // expression after the first cleanup sweep.  Rewrite its scanf save-slot
    // use after that lowering as well, while the recovered-global provenance
    // metadata is still available.
    unsigned LateScanfPointers = rewriteNativeScanfVarargAddresses(M, Changed);
    if (LateScanfPointers)
      errs() << "  late native scanf pointer addresses lowered: "
             << LateScanfPointers << "\n";
    unsigned LateQsortArrays = rewriteResidualQsortArrayArguments(M, Changed);
    if (LateQsortArrays)
      errs() << "  residual qsort array arguments recovered: "
             << LateQsortArrays << "\n";
    // Keep recovered typed globals as distinct native objects.  Replacing
    // them with a byte-preserving whole-segment copy destroys the very type
    // recovery this phase established and reintroduces ELF image blobs.
    unsigned ExternalPointers =
        rewriteRecoveredExternalPointerArguments(M, Changed);
    if (ExternalPointers)
      errs() << "  recovered external pointer arguments lowered: "
             << ExternalPointers << "\n";
    unsigned VarargPointers = rewriteRecoveredVarargSaveSlots(M, Changed);
    if (VarargPointers)
      errs() << "  recovered variadic pointer save slots lowered: "
             << VarargPointers << "\n";
    unsigned LateGuestPointers = rewriteDynamicGuestAddressIntToPtr(M, Changed);
    if (LateGuestPointers)
      errs() << "  late dynamic guest pointers lowered: " << LateGuestPointers
             << "\n";
    unsigned RawNativeStackPointers = lowerRawNativeStackIntToPtrs(M, Changed);
    if (RawNativeStackPointers)
      errs() << "  raw guest stack inttoptrs lowered: "
             << RawNativeStackPointers << "\n";
    unsigned ResidualGuestPointers =
        rewriteResidualRecoveredDataIntToPtrs(M, Changed);
    if (ResidualGuestPointers)
      errs() << "  residual guest data inttoptrs lowered: "
             << ResidualGuestPointers << "\n";
    unsigned RecoveredPointerByteGEPs =
        rewriteMaterializedRecoveredPointerByteGEPs(M, Changed);
    if (RecoveredPointerByteGEPs)
      errs() << "  recovered pointer byte GEPs rematerialized: "
             << RecoveredPointerByteGEPs << "\n";
    }
  }

  if ((NativeStateSSA || NativeStrict) && lowerNativeStackAddresses(M)) {
    Changed = true;
    errs() << "  native stack addresses rebased on recovered frame\n";
  }

  // A failed State-SSA transaction can still leave a valid recovered frame
  // backing and direct scanf pointer selects.  Normalize only those stack
  // arms even in that rollback mode; the broad external-pointer sweep above
  // remains gated by the proven native State ABI.
  unsigned RollbackScanfPointers =
      rewriteRecoveredExternalPointerArguments(M, Changed, true);
  if (RollbackScanfPointers)
    errs() << "  rollback-mode scanf stack pointer arms lowered: "
           << RollbackScanfPointers << "\n";

  unsigned NativeVarargExternalPointers =
      rewriteNativeVarargExternalPointerArguments(M, Changed);
  if (NativeVarargExternalPointers)
    errs() << "  native variadic external pointer arguments restored: "
           << NativeVarargExternalPointers << "\n";

  unsigned ReturnMarkers = eraseBrightenReturnMarkers(M, Changed);
  if (ReturnMarkers)
    errs() << "  transient RAX return markers erased: " << ReturnMarkers
           << "\n";

  unsigned DeadRIPAliases = rewriteDeadRIPDataAliases(M, Changed);
  if (DeadRIPAliases)
    errs() << "  dead RIP data carriers replaced by incoming RIP: "
           << DeadRIPAliases << "\n";

  unsigned GuestIdentityAliases =
      rewriteGuestAddressIdentityAliasIntegers(M, Changed);
  if (GuestIdentityAliases)
    errs() << "  guest address identity aliases lowered: "
           << GuestIdentityAliases << "\n";

  unsigned DataAliases = rewriteRemainingDataAliasesToNativeSegments(M, Changed);
  if (DataAliases)
    errs() << "  remaining guest data aliases lowered: " << DataAliases << "\n";

  unsigned NativeResidualSegments =
      canonicalizeLiveNativeResidualSegments(M, Changed);
  if (NativeResidualSegments)
    errs() << "  live residual segments canonicalized as native bytes: "
           << NativeResidualSegments << "\n";

  // Conservatively preserved residual segments acquire their exact guest
  // range while the final data_<addr> aliases are removed above.  Revisit
  // dynamic inttoptrs now: the earlier State-SSA-dependent sweep could not
  // prove their mapping before that provenance existed (and a later cleanup
  // sweep may legitimately roll its State transaction back).
  unsigned FinalDynamicGuestPointers = 0;
  unsigned FinalResidualGuestPointers = 0;
  if (DataAliases) {
    FinalDynamicGuestPointers =
        rewriteDynamicGuestAddressIntToPtr(M, Changed);
    FinalResidualGuestPointers =
        rewriteResidualRecoveredDataIntToPtrs(M, Changed);
  }
  if (FinalDynamicGuestPointers)
    errs() << "  final dynamic guest pointers lowered: "
           << FinalDynamicGuestPointers << "\n";
  if (FinalResidualGuestPointers)
    errs() << "  final residual guest data inttoptrs lowered: "
           << FinalResidualGuestPointers << "\n";

  unsigned ConstantGuestPointers =
      rewriteConstantGuestPointerOperands(M, Changed);
  if (ConstantGuestPointers)
    errs() << "  constant guest pointers lowered: " << ConstantGuestPointers
           << "\n";

  unsigned StackRecoveredGEPs =
      rewriteRecoveredGlobalStackIndexedGEPs(M, Changed);
  if (StackRecoveredGEPs)
    errs() << "  recovered stack-indexed GEPs restored: "
           << StackRecoveredGEPs << "\n";

  unsigned FinalVarargPointers = rewriteRecoveredVarargSaveSlots(M, Changed);
  if (FinalVarargPointers)
    errs() << "  final recovered variadic pointer save slots lowered: "
           << FinalVarargPointers << "\n";

  unsigned ExactNativeSegmentGEPs =
      rewriteExactNativeSegmentGEPs(M, Changed);
  if (ExactNativeSegmentGEPs)
    errs() << "  exact native segment GEPs rewritten: "
           << ExactNativeSegmentGEPs << "\n";

  unsigned EntrypointArtifacts = eraseDeadMcsemaEntrypoint(M, Changed);
  if (EntrypointArtifacts) {
    errs() << "  McSema entrypoint artifacts removed: "
           << EntrypointArtifacts << "\n";
  }

  unsigned StartupDispatches = eraseDeadSyntheticStartupDispatch(M, Changed);
  if (StartupDispatches) {
    errs() << "  synthetic startup dispatches removed: "
           << StartupDispatches << "\n";
  }

  lowerNativeCallbackTrampolines(M, Changed);
  unsigned QsortCallbacks = lowerNativeQsortCallbacks(M, Changed);
  if (QsortCallbacks)
    errs() << "  qsort callback ABI bridges lowered: " << QsortCallbacks
           << "\n";
  eraseDeadInlineAsmTrampolines(M, Changed);
  eraseUnusedInlineAsmCalls(M, Changed);
  eraseUnusedInternalGlobals(M, Changed);

  unsigned RemovedFunctions = 0;
  // Removing a native clone can make its Remill dispatcher dead, which can
  // in turn make another lifted helper dead.  Iterate to a fixed point so a
  // single cleanup pass does not leave a second-order dispatcher behind.
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  unsigned PreservedEntrypointBoundary =
      preserveNativeEntrypointStateBoundary(M, Changed);
  if (PreservedEntrypointBoundary)
    errs() << "  native entry State-ABI boundaries kept opaque: "
           << PreservedEntrypointBoundary << "\n";
  unsigned PreservedNestedBoundaries =
      preserveNestedNativeFrameBoundaries(M, Changed);
  if (PreservedNestedBoundaries)
    errs() << "  nested native frame boundaries kept opaque: "
           << PreservedNestedBoundaries << "\n";
  normalizeNativeEntrypoint(M, Changed);
  // State/entrypoint normalization can expose one final direct inttoptr of
  // the architectural RSP in native bodies.  Run the provenance-gated stack
  // lowering once more after the entry seed is in place; this is deliberately
  // separate from the broad data-pointer cleanup above.
  unsigned LateRawNativeStackPointers = 0;
  bool HasNativeEntrypointCall = false;
  if (Function *Main = M.getFunction("main"))
    for (BasicBlock &BB : *Main)
      for (Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (Function *Callee = CB->getCalledFunction();
              Callee && Callee->getName().ends_with(".native"))
            HasNativeEntrypointCall = true;
  bool LateStackAlreadyLowered =
      M.getNamedMetadata("brighten.late.stack.lowered") != nullptr;
  bool HasLateStackCandidate = hasRawNativeStackIntToPtrCandidate(M);
  if ((HasNativeEntrypointCall || HasLateStackCandidate) &&
      !LateStackAlreadyLowered) {
    LateRawNativeStackPointers = lowerRawNativeStackIntToPtrs(M, Changed);
    NamedMDNode *Marker = M.getOrInsertNamedMetadata(
        "brighten.late.stack.lowered");
    Marker->addOperand(MDNode::get(
        M.getContext(), {ConstantAsMetadata::get(
                            ConstantInt::get(Type::getInt1Ty(M.getContext()),
                                             true))}));
  }
  if (LateRawNativeStackPointers)
    errs() << "  late raw guest stack inttoptrs lowered: "
           << LateRawNativeStackPointers << "\n";
  unsigned DynamicFrameRegions =
      localizeProvenDynamicFrameRegions(M, Changed);
  if (DynamicFrameRegions)
    errs() << "  dynamic guest-frame regions localized: "
           << DynamicFrameRegions << "\n";
  unsigned AffineFramePointers =
      canonicalizeFrameBackingAffinePointers(M, Changed);
  if (AffineFramePointers)
    errs() << "  affine frame pointers canonicalized: "
           << AffineFramePointers << "\n";
  unsigned StackDataSelects =
      collapseFrameProvenantDataPointerSelects(M, Changed);
  if (StackDataSelects)
    errs() << "  stack-provenant data selects collapsed: "
           << StackDataSelects << "\n";
  unsigned CompactedFrames = compactProvenConstantFrameBackings(M, Changed);
  if (CompactedFrames)
    errs() << "  proven fake stack backings converted to native frames: "
           << CompactedFrames << "\n";
  // Run the proven startup cleanup once more after dead lifted-function
  // cleanup; otherwise `.init_proc`/`start` can remain externally visible
  // roots and keep their State global alive. Entrypoint ABI recovery belongs
  // to pass 050, and cleanup must never fabricate a guest-stack backing store.
  unsigned LateEntrypointArtifacts = eraseDeadMcsemaEntrypoint(M, Changed);
  if (LateEntrypointArtifacts) {
    RemovedFunctions += LateEntrypointArtifacts;
    errs() << "  late McSema entrypoint artifacts removed: "
           << LateEntrypointArtifacts << "\n";
  }
  unsigned LateStartupDispatches =
      eraseDeadSyntheticStartupDispatch(M, Changed);
  if (LateStartupDispatches) {
    RemovedFunctions += LateStartupDispatches;
    errs() << "  late synthetic startup dispatches removed: "
           << LateStartupDispatches << "\n";
  }
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  unsigned LocalizedStateGlobals = localizePrivateStateGlobals(M, Changed);
  if (LocalizedStateGlobals)
    errs() << "  private State globals localized: "
           << LocalizedStateGlobals << "\n";
  unsigned RemovedGlobals = 0;
  unsigned RemovedStateGlobals = 0;
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedGlobals(M, Changed);
    unsigned RemovedStateThisRound = eraseDeadStateGlobals(M, Changed);
    RemovedGlobals += RemovedThisRound;
    RemovedStateGlobals += RemovedStateThisRound;
    if (!RemovedThisRound && !RemovedStateThisRound)
      break;
  }
  eraseUnusedInternalGlobals(M, Changed);
  unsigned NativeDataArtifacts = eraseUnusedNativeDataArtifacts(M, Changed);
  if (NativeDataArtifacts)
    errs() << "  unused native segment artifacts removed: "
           << NativeDataArtifacts << "\n";
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  if (RemovedStateGlobals)
    errs() << "  dead State globals removed: " << RemovedStateGlobals << "\n";

  unsigned LateMissingScanfDestinations =
      materializeMissingScanfDestinations(M, Changed);
  if (LateMissingScanfDestinations)
    errs() << "  late missing scanf destinations materialized: "
           << LateMissingScanfDestinations << "\n";
  // Preserve scanf failure semantics; do not seed or trap destinations.
  unsigned PromotedDispatchers = promoteStackDispatcherStateSlots(M, Changed);
  if (PromotedDispatchers)
    errs() << "  stack dispatcher state slots promoted to SSA: "
           << PromotedDispatchers << "\n";
  // Do not broadly initialize scanf destinations before the call.  Native
  // scanf leaves an integer destination unchanged when conversion/EOF fails;
  // the narrow seeding above is limited to recovered integer locals whose
  // zero-backed frame would otherwise turn raw failed conversions into
  // defined-looking values.
  unsigned IsolatedWorkArray =
      isolateRecoveredWorkArrayPrefix(M, Changed);
  if (IsolatedWorkArray)
    errs() << "  recovered work-array invalid prefix isolated: "
           << IsolatedWorkArray << "\n";
  // Do not synthesize null-pointer stores for recovered global bounds.  The
  // lifted image-backed address space can legitimately use negative offsets
  // into adjacent mapped segments; trapping here caused SIGSEGVs on valid
  // contract inputs.  Keep the original access unless provenance is proven.
  unsigned LatePointerIntegers =
      rewriteRecoveredPointerIntegerIdentities(M, Changed);
  if (LatePointerIntegers)
    errs() << "  late recovered pointer integer identities lowered: "
           << LatePointerIntegers << "\n";
  // No recovery step below this point consumes guest-range provenance; remove
  // it now so the final NativeStrict contract remains metadata-free.
  // Keep guest-range provenance across the intervening O3 pipeline.  A later
  // cleanup invocation still needs it to materialize libc format constants
  // after translator calls have folded to raw guest addresses.  The final
  // strict verifier strips it once all rewrites are complete.
  stripRemillMetadata(M, Changed, false);
  foldExactPointerRoundTrips(M, Changed);
  reportNativeContract(M, RemovedFunctions, RemovedGlobals, false);

  return Changed;
}

} // namespace brighten_native_cleanup
