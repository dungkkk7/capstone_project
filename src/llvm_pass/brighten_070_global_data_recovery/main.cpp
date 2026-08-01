#include "llvm/Support/ErrorHandling.h"
#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

#include <algorithm>
#include <cstdlib>

namespace brighten_global {

using namespace llvm;

static bool IsDynamicAddressCarrier(const Instruction *I) {
  if (auto *GEP = dyn_cast_or_null<GetElementPtrInst>(I)) {
    for (unsigned Op = 1; Op < GEP->getNumOperands(); ++Op)
      if (!isa<ConstantInt>(GEP->getOperand(Op)))
        return true;
    return false;
  }
  if (auto *ITP = dyn_cast_or_null<IntToPtrInst>(I))
    return !isa<Constant>(ITP->getOperand(0));
  if (auto *BO = dyn_cast_or_null<BinaryOperator>(I))
    if (BO->getOpcode() == Instruction::Add ||
        BO->getOpcode() == Instruction::Sub)
      return !isa<Constant>(BO->getOperand(0)) ||
             !isa<Constant>(BO->getOperand(1));
  return false;
}

// A merged guest segment is one storage object.  Splitting a candidate while
// an unresolved dynamic GEP can still address the same segment creates two
// independent LLVM globals for one guest byte range; stores through one then
// fail to alias loads through the other.  Only an Array/RawBytes candidate
// rooted at that exact dynamic base owns such an access, because its recovery
// rule supplied the backing-range evidence.  Every other dynamic carrier is
// unbounded here, so it may overlap any candidate in its source segment and
// forces that segment to remain unsplit.
static bool RefHasOwnedDynamicBacking(const GuestAddressRef &Ref,
                                      const GlobalDataContext &Ctx) {
  if (!IsDynamicAddressCarrier(Ref.UserInst))
    return true;
  for (const auto &Candidate : Ctx.Candidates) {
    if (!Candidate || Candidate->SourceSegment != Ref.Segment ||
        Candidate->Begin != Ref.GuestAddr)
      continue;
    if (Candidate->Kind == ObjectKind::Array ||
        Candidate->Kind == ObjectKind::RawBytes)
      return true;
  }
  return false;
}

static void RefuseCandidatesWithUnresolvedDynamicAlias(GlobalDataContext &Ctx) {
  SmallPtrSet<GuestSegment *, 8> UnsafeSegments;
  for (const auto &Ref : Ctx.AddressRefs) {
    if (!Ref || !Ref->Segment || !Ref->Segment->BaseResolved ||
        !Ref->UserInst || !Ref->UserInst->getParent())
      continue;
    if (!RefHasOwnedDynamicBacking(*Ref, Ctx))
      UnsafeSegments.insert(Ref->Segment);
  }
  if (UnsafeSegments.empty())
    return;

  std::vector<std::unique_ptr<ObjectCandidate>> Safe;
  Safe.reserve(Ctx.Candidates.size());
  for (auto &Candidate : Ctx.Candidates) {
    // Conflict resolution intentionally leaves rejected slots empty.  This
    // preflight runs afterwards and must treat those slots as absent rather
    // than dereferencing a tombstone.
    if (!Candidate)
      continue;
    if (!UnsafeSegments.contains(Candidate->SourceSegment)) {
      Safe.push_back(std::move(Candidate));
      continue;
    }
    Ctx.Report.Details.push_back(
        "candidate=" + Candidate->Name + " action=refused reason="
        "unresolved-dynamic-may-alias-source-segment");
  }
  Ctx.Candidates = std::move(Safe);
}

// A recovered object is a second LLVM storage location until every source
// reference in its interval is rewritten.  A guest-address identity compare
// cannot be retargeted without proving pointer identity for all aliases, so
// it is a hard transactional boundary: leave the source range intact rather
// than split writable storage into a residual plus dyn_bytes/scalar view.
static void RefuseCandidatesWithObservedAddressIdentity(GlobalDataContext &Ctx) {
  std::vector<std::unique_ptr<ObjectCandidate>> Safe;
  Safe.reserve(Ctx.Candidates.size());
  for (auto &Candidate : Ctx.Candidates) {
    if (!Candidate)
      continue;
    // This guard owns writable aliasing only.  Existing readonly string
    // recovery may retain the source identity carrier while rewriting a
    // separately-proven content use; it never creates divergent writable
    // state.  Do not turn that established representation rule into a broad
    // no-string policy here.
    if (!Candidate->SourceSegment || !Candidate->SourceSegment->Writable) {
      Safe.push_back(std::move(Candidate));
      continue;
    }
    bool IdentityObserved = false;
    for (const auto &Ref : Ctx.AddressRefs) {
      if (!Ref || Ref->Segment != Candidate->SourceSegment ||
          Ref->ConsumerKind != DataConsumerKind::ComparisonOnly)
        continue;
      if (Ref->GuestAddr >= Candidate->Begin &&
          Ref->GuestAddr < Candidate->End) {
        IdentityObserved = true;
        break;
      }
    }
    if (!IdentityObserved) {
      Safe.push_back(std::move(Candidate));
      continue;
    }
    Ctx.Report.Details.push_back(
        "candidate=" + Candidate->Name + " action=refused reason="
        "address-identity-observable");
  }
  Ctx.Candidates = std::move(Safe);
}

// The mapped page tail is already a concrete, zero-initialized byte object.
// Register it as the sole rewrite owner rather than materializing a scalar or
// dyn_bytes view inside it.  This makes both fixed and dynamic tail accesses
// converge on one backing global, while the synthetic physical overhang of
// the preceding lifted aggregate becomes dead provenance.
static void InstallMappedPageTailOwners(GlobalDataContext &Ctx) {
  if (!Ctx.HasAuthoritativeGuestAddressMap)
    return;
  for (const auto &Seg : Ctx.Segments) {
    if (!Seg || !Seg->IsMappedPageTail || !Seg->GV || !Seg->BaseResolved ||
        Seg->Size == 0 || Ctx.RecoveredObjects.count(Seg->GuestBase))
      continue;
    // A dynamic resolver carrier is not proof that every value reaching it is
    // in this tail.  Replacing its base with the zero tail before CFG/range
    // structuralization turns out-of-tail values into zero reads/writes.  In
    // that case retain the original physical lifted backing as the sole live
    // storage and leave this tail unreferenced; a later bounded resolver rule
    // may install it once the range proof exists.
    bool HasUnboundedDynamicCarrier = false;
    for (const auto &Ref : Ctx.AddressRefs)
      if (Ref && Ref->Segment == Seg.get() && Ref->UserInst &&
          Ref->UserInst->getParent() && IsDynamicAddressCarrier(Ref->UserInst)) {
        HasUnboundedDynamicCarrier = true;
        break;
      }
    if (HasUnboundedDynamicCarrier) {
      Ctx.Report.Details.push_back(
          "segment=" + Seg->GV->getName().str() + " action=preserved reason="
          "requires-structural-cfg-range-proof");
      continue;
    }
    auto Obj = std::make_unique<RecoveredObject>();
    Obj->Begin = Seg->GuestBase;
    Obj->End = Seg->GuestBase + Seg->Size;
    Obj->Kind = ObjectKind::RawBytes;
    Obj->Ty = Seg->GV->getValueType();
    Obj->GV = Seg->GV;
    Obj->SourceSegment = Seg.get();
    Obj->ReadOnly = Seg->ReadOnly;
    Obj->Name = Seg->GV->getName().str();
    Obj->Action = "authoritative-mapped-page-tail";
    Ctx.RecoveredObjects[Obj->Begin] = std::move(Obj);
  }
}

// PT_LOAD mode partitions one guest image into a logical source range and a
// mapped zero tail.  Candidate materialization creates new LLVM storage, so
// partial recovery is sound only when every live access in a writable source
// range is assigned to a single recovered owner.  An unresolved fixed access,
// any dynamic carrier, or an observable address/memory ordering boundary
// leaves the original source as the sole owner.  This gate is deliberately
// PT-only: it quarantines the experimental partition without changing the
// established non-PT recovery lifecycle.
static void RefusePartialWritableCandidatesInAuthoritativeMap(
    GlobalDataContext &Ctx) {
  if (!Ctx.HasAuthoritativeGuestAddressMap)
    return;

  SmallPtrSet<GuestSegment *, 8> Unsafe;
  for (const auto &Seg : Ctx.Segments)
    if (Seg && Seg->Writable && Seg->IsMappedPageTail)
      Unsafe.insert(Seg.get());

  for (const auto &Ref : Ctx.AddressRefs) {
    if (!Ref || !Ref->Segment || !Ref->Segment->Writable ||
        !Ref->UserInst || !Ref->UserInst->getParent())
      continue;
    GuestSegment *Seg = Ref->Segment;
    if (Seg->IsMappedPageTail) {
      Unsafe.insert(Seg);
      continue;
    }
    if (!Ref->SkipReason.empty() ||
        Ref->ConsumerKind == DataConsumerKind::ComparisonOnly ||
        IsDynamicAddressCarrier(Ref->UserInst)) {
      Unsafe.insert(Seg);
      continue;
    }
    bool Covered = false;
    for (const auto &Candidate : Ctx.Candidates) {
      if (!Candidate || Candidate->SourceSegment != Seg)
        continue;
      if (Ref->GuestAddr >= Candidate->Begin &&
          Ref->GuestAddr < Candidate->End) {
        Covered = true;
        break;
      }
    }
    if (!Covered)
      Unsafe.insert(Seg);
  }

  if (Unsafe.empty())
    return;
  std::vector<std::unique_ptr<ObjectCandidate>> Safe;
  Safe.reserve(Ctx.Candidates.size());
  for (auto &Candidate : Ctx.Candidates) {
    if (!Candidate)
      continue;
    if (!Candidate->SourceSegment ||
        !Unsafe.contains(Candidate->SourceSegment)) {
      Safe.push_back(std::move(Candidate));
      continue;
    }
    Ctx.Report.Details.push_back(
        "candidate=" + Candidate->Name + " action=refused reason="
        "authoritative-map-region-not-transactionally-covered");
  }
  Ctx.Candidates = std::move(Safe);
}

PreservedAnalyses BrightenGlobalDataRecoveryPass::run(Module &M,
                                                       ModuleAnalysisManager &) {
  GlobalDataContext Ctx(M);
  bool Changed = false;

  // Analysis / helper passes (do not modify IR)
  DiscoverGuestSegments(Ctx);
  FlattenSegmentBytes(Ctx);
  BuildGuestAddressMap(Ctx);
  InstallMappedPageTailOwners(Ctx);
  GenerateObjectCandidates(Ctx);
  ResolveObjectConflicts(Ctx);
  RefuseCandidatesWithUnresolvedDynamicAlias(Ctx);
  RefuseCandidatesWithObservedAddressIdentity(Ctx);
  RefusePartialWritableCandidatesInAuthoritativeMap(Ctx);

  // Recovering one proven object must not be cancelled by an unrelated
  // unresolved carrier.  The source segment remains as a byte-preserving
  // residual for every such carrier; only references whose full candidate
  // range is proven are rewritten.  In particular, do not manufacture a
  // pointer-sized object for an uncovered dynamic GEP -- that would split a
  // logical array and change its bounds/aliasing semantics.
  //
  // This is deliberately a diagnostic rather than an early return.  A
  // previous all-or-nothing preflight made a format string in a mixed ELF
  // image unrecoverable merely because another section of the same image had
  // a dynamic fallback.  Cleanup below retains that source image while any
  // live unresolved use remains.
  if (Ctx.Mode == DataRecoveryMode::NativeStrict) {
    for (const auto &Ref : Ctx.AddressRefs) {
      if (!Ref->Segment || !Ref->Segment->BaseResolved || !Ref->UserInst ||
          !Ref->UserInst->getParent() || !Ref->SkipReason.empty())
        continue;
      bool Covered = false;
      for (const auto &Candidate : Ctx.Candidates) {
        if (Ref->GuestAddr >= Candidate->Begin &&
            Ref->GuestAddr < Candidate->End) {
          Covered = true;
          break;
        }
      }
      if (Covered)
        continue;
      // The generated translator range-checks the guest address before this
      // dynamic GEP and returns the resulting segment pointer.  It is storage
      // infrastructure, not an uncovered program data consumer; all actual
      // users of the translated pointer are analyzed independently.
      if (Ref->UserInst->getFunction()->getName() ==
          "__translate_guest_pointer")
        continue;
      // Address-identity comparisons and arithmetic-only intermediate bases
      // do not themselves consume memory and therefore do not require a
      // recovered object.  Their downstream pointer consumers are recorded
      // independently.  Unknown dynamic GEP carriers and direct
      // LoadStorePointer uses must remain covered: ignoring those categories
      // allowed partial rewrites before strict validation found the gap.
      if (Ref->ConsumerKind == DataConsumerKind::ComparisonOnly ||
          Ref->ConsumerKind == DataConsumerKind::ArithmeticOnly)
        continue;
      errs() << "[brighten-global-data] preserving residual: unresolved guest "
                "address carrier at 0x"
             << Twine::utohexstr(Ref->GuestAddr) << " kind="
             << static_cast<unsigned>(Ref->ConsumerKind) << "\n";
      errs() << "  instruction: ";
      Ref->UserInst->print(errs());
      errs() << "\n";
    }
  }

  // Transformation passes
  Changed |= MaterializeRecoveredGlobals(Ctx);
  Changed |= RecoverJumpTableCFG(Ctx);
  Changed |= RewriteGuestDataReferences(Ctx);
  Changed |= RewriteGuestPointerTranslatorCalls(Ctx);
  Changed |= RemoveDeadSegmentConstantUsers(Ctx);
  Changed |= CleanupDeadSegmentArtifacts(Ctx);

  bool HasVerifierError = VerifyGlobalDataRecovery(Ctx);
  const bool AuditOnly = std::getenv("BRIGHTEN_GLOBAL_AUDIT_ONLY") != nullptr;
  if (Ctx.Mode == DataRecoveryMode::NativeStrict && HasVerifierError &&
      !AuditOnly) {
    report_fatal_error("global data recovery validation failed in strict mode");
  }
  PrintGlobalDataRecoveryReport(Ctx);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses BrightenGuestPointerResolverCanonicalizePass::run(
    Module &M, ModuleAnalysisManager &) {
  return CanonicalizeGuestPointerResolvers(M) ? PreservedAnalyses::none()
                                              : PreservedAnalyses::all();
}

PreservedAnalyses BrightenLateResidualFormatStringRecoveryPass::run(
    Module &M, ModuleAnalysisManager &) {
  return RecoverLateResidualFormatStrings(M) ? PreservedAnalyses::none()
                                              : PreservedAnalyses::all();
}

} // namespace brighten_global

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "BrightenGlobalDataRecoveryPass", "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-global-data-recovery-pass") {
                    MPM.addPass(
                        brighten_global::BrightenGlobalDataRecoveryPass());
                    return true;
                  }
                  if (Name == "brighten-guest-pointer-resolver-canonicalize") {
                    MPM.addPass(
                        brighten_global::BrightenGuestPointerResolverCanonicalizePass());
                    return true;
                  }
                  if (Name == "brighten-late-residual-format-string-recovery") {
                    MPM.addPass(
                        brighten_global::BrightenLateResidualFormatStringRecoveryPass());
                    return true;
                  }
                  return false;
                });
          }};
}
