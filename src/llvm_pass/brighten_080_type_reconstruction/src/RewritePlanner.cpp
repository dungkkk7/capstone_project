#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

extern Constant *RebuildConstant(Constant *OldInit, Type *NewTy, uint64_t Offset, const DataLayout &DL, LLVMContext &Ctx);
extern void RewritePointerUses(Value *OldVal, Value *NewBase, InferredTypePlan &Plan, TypeReconstructionContext &Ctx);
extern bool PrevalidateTypePlan(InferredTypePlan &Plan, TypeReconstructionContext &Ctx);

Type *InferArrayType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx);
Type *InferStructType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx);

bool PlanAndRewrite(TypeReconstructionContext &Ctx, bool OnlyStruct, bool OnlyArray) {
  bool Changed = false;

  for (auto &Cand : Ctx.Candidates) {
    if (Cand->Accesses.empty())
      continue;

    if (Cand->Escaped) {
      Ctx.Report.ObjectsRejectedEscape++;
      if (Ctx.DumpRejections) {
        errs() << "Rejected candidate " << Cand->Name << " due to escape.\n";
        for (const auto &Reason : Cand->RejectionReasons) {
          errs() << "  Reason: " << Reason << "\n";
        }
      }
      continue;
    }

    Type *InferredTy = nullptr;
    bool IsArray = false;

    if (!OnlyStruct) {
      InferredTy = InferArrayType(*Cand, Ctx);
      if (InferredTy)
        IsArray = true;
    }

    if (!InferredTy && !OnlyArray) {
      InferredTy = InferStructType(*Cand, Ctx);
    }

    if (!InferredTy) {
      Ctx.Report.ObjectsRejectedUnknownOffset++;
      if (Ctx.DumpRejections) {
        errs() << "Rejected candidate " << Cand->Name << " due to no inferred type.\n";
        for (const auto &Reason : Cand->RejectionReasons) {
          errs() << "  Reason: " << Reason << "\n";
        }
      }
      continue;
    }

    auto Plan = std::make_unique<InferredTypePlan>();
    Plan->Candidate = Cand.get();
    Plan->ProposedRootType = InferredTy;
    Plan->IsArray = IsArray;
    Plan->TotalSize = Cand->ObjectSize;

    if (!PrevalidateTypePlan(*Plan, Ctx)) {
      Ctx.Report.ObjectsRejectedInitializer++;
      if (Ctx.DumpRejections) {
        errs() << "Rejected candidate " << Cand->Name << " during plan pre-validation.\n";
        for (const auto &Reason : Plan->RejectionReasons) {
          errs() << "  Reason: " << Reason << "\n";
        }
      }
      continue;
    }

    if (Cand->Kind == ObjectKind::Stack) {
      auto *AI = cast<AllocaInst>(Cand->BaseVal);
      BasicBlock &Entry = AI->getFunction()->getEntryBlock();
      Instruction *InsertBefore = &*Entry.getFirstInsertionPt();
      
      AllocaInst *NewAI = new AllocaInst(InferredTy, AI->getType()->getAddressSpace(), nullptr,
                                         AI->getAlign(), "brighten.stack." + Cand->Name, InsertBefore->getIterator());
      NewAI->takeName(AI);

      RewritePointerUses(AI, NewAI, *Plan, Ctx);

      if (AI->use_empty()) {
        AI->eraseFromParent();
      }

      Ctx.Report.AllocasRetyped++;
      Ctx.Report.ObjectsReconstructed++;
      if (IsArray) {
        Ctx.Report.ArraysRecovered++;
      } else {
        Ctx.Report.StructsReconstructed++;
      }
      Plan->Committed = true;
      Changed = true;

    } else if (Cand->Kind == ObjectKind::Global) {
      auto *GV = cast<GlobalVariable>(Cand->BaseVal);

      bool CanRetypeGlobal = true;
      if (GV->hasExternalLinkage() || GV->hasWeakLinkage() ||
          GV->hasLinkOnceLinkage() || GV->isExternallyInitialized()) {
        CanRetypeGlobal = false;
      }

      if (CanRetypeGlobal) {
        if (!GV->hasInitializer()) {
          Ctx.Report.ObjectsRejectedInitializer++;
          if (Ctx.DumpRejections) {
            errs() << "Rejected candidate " << Cand->Name
                   << " because global has no initializer to rebuild.\n";
          }
          continue;
        }

        Constant *NewInit = nullptr;
        NewInit = RebuildConstant(GV->getInitializer(), InferredTy, 0, Ctx.DL, Ctx.M.getContext());

        if (NewInit) {
          GlobalVariable *NewGV = new GlobalVariable(Ctx.M, InferredTy, GV->isConstant(),
                                                     GV->getLinkage(), NewInit, "brighten.global." + Cand->Name,
                                                     nullptr, GV->getThreadLocalMode(), GV->getType()->getAddressSpace(),
                                                     GV->isExternallyInitialized());
          NewGV->copyAttributesFrom(GV);
          NewGV->takeName(GV);

          RewritePointerUses(GV, NewGV, *Plan, Ctx);

          // With opaque pointers both globals have the same `ptr` value type,
          // even when their storage element types differ.  Keeping the old
          // global for pointer uses that the typed-GEP planner did not rewrite
          // creates two independent host allocations for one guest object:
          // libc writes one allocation while reconstructed indexed accesses
          // read the other.  Redirect every residual use to the new backing
          // object; each existing GEP retains its own source element type.
          if (!GV->use_empty())
            GV->replaceAllUsesWith(NewGV);
          GV->eraseFromParent();

          Ctx.Report.GlobalsRetyped++;
          Ctx.Report.ObjectsReconstructed++;
          if (IsArray) {
            Ctx.Report.ArraysRecovered++;
          } else {
            Ctx.Report.StructsReconstructed++;
          }
          Plan->Committed = true;
          Changed = true;
        } else {
          Ctx.Report.ObjectsRejectedInitializer++;
        }
      } else {
        RewritePointerUses(GV, GV, *Plan, Ctx);

        Ctx.Report.ObjectsReconstructed++;
        if (IsArray) {
          Ctx.Report.ArraysRecovered++;
        } else {
          Ctx.Report.StructsReconstructed++;
        }
        Plan->Committed = true;
        Changed = true;
      }
    }
  }

  return Changed;
}

} // namespace brighten_type
