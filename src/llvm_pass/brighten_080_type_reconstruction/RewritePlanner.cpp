#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

extern Constant *RebuildConstant(Constant *OldInit, Type *NewTy,
                                 uint64_t Offset, const DataLayout &DL,
                                 LLVMContext &Ctx);
extern void RewritePointerUses(Value *OldVal, Value *NewBase,
                               InferredTypePlan &Plan,
                               TypeReconstructionContext &Ctx);
extern bool PrevalidateTypePlan(InferredTypePlan &Plan,
                                TypeReconstructionContext &Ctx);

Type *InferArrayType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx);
Type *InferStructType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx);

namespace {

static void dumpRejection(const ObjectCandidate &Cand,
                          const InferredTypePlan *Plan,
                          TypeReconstructionContext &Ctx) {
  if (!Ctx.DumpRejections)
    return;
  errs() << "[type-reconstruct] rejected " << Cand.Name << "\n";
  for (const std::string &Reason : Cand.RejectionReasons)
    errs() << "  candidate: " << Reason << "\n";
  if (Plan)
    for (const std::string &Reason : Plan->RejectionReasons)
      errs() << "  plan: " << Reason << "\n";
}

static bool isExternallyOwned(const GlobalVariable &GV) {
  return GV.hasExternalLinkage() || GV.hasWeakLinkage() ||
         GV.hasLinkOnceLinkage() || GV.isExternallyInitialized();
}

} // namespace

bool PlanAndRewrite(TypeReconstructionContext &Ctx, bool OnlyStruct,
                    bool OnlyArray) {
  bool Changed = false;

  for (auto &Owned : Ctx.Candidates) {
    ObjectCandidate &Cand = *Owned;
    const TypeConstraintSolution *Solution = GetTypeSolution(Cand, Ctx);
    if (!Solution || !Solution->Valid || Cand.Accesses.empty()) {
      Ctx.Report.ObjectsRejectedUnknownOffset++;
      dumpRejection(Cand, nullptr, Ctx);
      continue;
    }
    if (Cand.Escaped) {
      Ctx.Report.ObjectsRejectedEscape++;
      dumpRejection(Cand, nullptr, Ctx);
      continue;
    }

    Type *InferredTy = nullptr;
    bool IsArray = false;
    if (!OnlyStruct) {
      InferredTy = InferArrayType(Cand, Ctx);
      IsArray = InferredTy != nullptr;
    }
    if (!InferredTy && !OnlyArray)
      InferredTy = InferStructType(Cand, Ctx);
    if (!InferredTy) {
      Ctx.Report.ObjectsRejectedUnknownOffset++;
      dumpRejection(Cand, nullptr, Ctx);
      continue;
    }

    auto Plan = std::make_unique<InferredTypePlan>();
    Plan->Candidate = &Cand;
    Plan->ProposedRootType = InferredTy;
    Plan->IsArray = IsArray;
    Plan->TotalSize = Cand.ObjectSize;
    Plan->Confidence = Solution->Confidence;

    if (!PrevalidateTypePlan(*Plan, Ctx)) {
      Ctx.Report.ObjectsRejectedInitializer++;
      dumpRejection(Cand, Plan.get(), Ctx);
      continue;
    }

    if (Cand.Kind == ObjectKind::Stack) {
      auto *Old = cast<AllocaInst>(Cand.BaseVal);
      IRBuilder<> Builder(&*Old->getFunction()->getEntryBlock().getFirstInsertionPt());
      AllocaInst *New = Builder.CreateAlloca(
          InferredTy, Old->getAddressSpace(), nullptr,
          "brighten.stack." + Cand.Name);
      New->setAlignment(Old->getAlign());
      New->copyMetadata(*Old);
      New->takeName(Old);

      RewritePointerUses(Old, New, *Plan, Ctx);
      if (!Old->use_empty())
        report_fatal_error(
            "type reconstruction left uses of a replaced stack object");
      Old->eraseFromParent();
      Ctx.Report.AllocasRetyped++;
    } else if (Cand.Kind == ObjectKind::Global) {
      auto *Old = cast<GlobalVariable>(Cand.BaseVal);
      if (isExternallyOwned(*Old)) {
        // External storage layout is an ABI contract.  Keep the object itself
        // and rewrite only in-module accesses to exact typed GEPs.
        RewritePointerUses(Old, Old, *Plan, Ctx);
      } else {
        if (!Old->hasInitializer()) {
          Plan->RejectionReasons.push_back("internal-global-has-no-initializer");
          Ctx.Report.ObjectsRejectedInitializer++;
          dumpRejection(Cand, Plan.get(), Ctx);
          continue;
        }
        Constant *Initializer = RebuildConstant(
            Old->getInitializer(), InferredTy, 0, Ctx.DL, Ctx.M.getContext());
        if (!Initializer) {
          Plan->RejectionReasons.push_back(
              "initializer-cannot-be-rebuilt-without-guessing");
          Ctx.Report.ObjectsRejectedInitializer++;
          dumpRejection(Cand, Plan.get(), Ctx);
          continue;
        }

        auto *New = new GlobalVariable(
            Ctx.M, InferredTy, Old->isConstant(), Old->getLinkage(), Initializer,
            "brighten.global." + Cand.Name, nullptr, Old->getThreadLocalMode(),
            Old->getAddressSpace(), Old->isExternallyInitialized());
        New->copyAttributesFrom(Old);
        New->copyMetadata(Old, 0);
        New->takeName(Old);

        RewritePointerUses(Old, New, *Plan, Ctx);
        if (!Old->use_empty())
          Old->replaceAllUsesWith(New);
        if (!Old->use_empty())
          report_fatal_error(
              "type reconstruction left uses of a replaced global object");
        Old->eraseFromParent();
        Ctx.Report.GlobalsRetyped++;
      }
    } else {
      Plan->RejectionReasons.push_back("unsupported-proven-object-kind");
      dumpRejection(Cand, Plan.get(), Ctx);
      continue;
    }

    Ctx.Report.ObjectsReconstructed++;
    if (IsArray)
      Ctx.Report.ArraysRecovered++;
    else
      Ctx.Report.StructsReconstructed++;
    Plan->Committed = true;
    Ctx.Plans[Cand.BaseVal] = std::move(Plan);
    Changed = true;
  }

  return Changed;
}

} // namespace brighten_type
