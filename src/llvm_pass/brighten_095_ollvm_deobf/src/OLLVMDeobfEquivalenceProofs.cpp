#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

SMTEquivalenceResult checkEquivalentSMT(Value *Old,
                                                Value *Replacement) {
  if (!Old || !Replacement || Old->getType() != Replacement->getType())
    return SMTEquivalenceResult::Disproved;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto L = Translator.translate(Old);
    auto R = Translator.translate(Replacement);
    if (!L || !R || L->is_bool() != R->is_bool() || L->is_bv() != R->is_bv())
      return SMTEquivalenceResult::Unknown;
    z3::params Params(Ctx);
    Params.set("timeout", 500u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(*L != *R);
    z3::check_result Result = Solver.check();
    if (Result == z3::unsat) return SMTEquivalenceResult::Proved;
    if (Result == z3::sat) return SMTEquivalenceResult::Disproved;
    return SMTEquivalenceResult::Unknown;
  } catch (const z3::exception &) {
    return SMTEquivalenceResult::Unknown;
  }
}

bool proveEquivalentSMT(Value *Old, Value *Replacement) {
  return checkEquivalentSMT(Old, Replacement) ==
         SMTEquivalenceResult::Proved;
}

bool collectPoisonSupport(Value *V,
                                 SmallPtrSetImpl<const Value *> &Support,
                                 unsigned Depth) {
  if (!V || Depth > 64) return false;
  if (isa<Constant>(V) || isa<FreezeInst>(V)) return true;
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (hasPoisonGeneratingFlags(BO)) {
      Support.insert(V);
      return true;
    }
    if (BO->isShift()) {
      auto *Count = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!Count || Count->getValue().uge(BO->getType()->getIntegerBitWidth())) {
        Support.insert(V);
        return true;
      }
    }
    return collectPoisonSupport(BO->getOperand(0), Support, Depth + 1) &&
           collectPoisonSupport(BO->getOperand(1), Support, Depth + 1);
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(V))
    return collectPoisonSupport(Cmp->getOperand(0), Support, Depth + 1) &&
           collectPoisonSupport(Cmp->getOperand(1), Support, Depth + 1);
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    if (auto *TI = dyn_cast<TruncInst>(Cast); TI && TI->hasNoUnsignedWrap()) {
      Support.insert(V);
      return true;
    }
    return collectPoisonSupport(Cast->getOperand(0), Support, Depth + 1);
  }
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    if (II->getIntrinsicID() == Intrinsic::ctpop &&
        II->getType()->isIntegerTy())
      return collectPoisonSupport(II->getArgOperand(0), Support, Depth + 1);
    if ((II->getIntrinsicID() == Intrinsic::fshl ||
         II->getIntrinsicID() == Intrinsic::fshr) &&
        II->getArgOperand(0) == II->getArgOperand(1) &&
        isa<ConstantInt>(II->getArgOperand(2)))
      return collectPoisonSupport(II->getArgOperand(0), Support, Depth + 1);
  }
  // Select has path-dependent poison propagation and unsupported operations
  // may have their own poison rules.  Treat the complete value as one source
  // rather than inventing a relation that the BV solver cannot express.
  Support.insert(V);
  return true;
}

bool hasSamePoisonSupport(Value *Old, Value *Replacement) {
  SmallPtrSet<const Value *, 16> OldSupport, NewSupport;
  if (!collectPoisonSupport(Old, OldSupport) ||
      !collectPoisonSupport(Replacement, NewSupport) ||
      OldSupport.size() != NewSupport.size())
    return false;
  for (const Value *V : OldSupport)
    if (!NewSupport.contains(V)) return false;
  return true;
}

bool sanitizeLiftedFunction(Function &F, Metrics &M,
                                   SmallVectorImpl<ProofRecord> &Proofs) {
  if (!isLiftedFunction(F))
    return false;
  ++M.LiftedFunctions;
  bool Changed = false;
  for (Instruction &I : instructions(F)) {
    bool Local = false;
    if (auto *OBO = dyn_cast<OverflowingBinaryOperator>(&I)) {
      Local |= OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap();
      if (Local) {
        auto *BO = cast<BinaryOperator>(&I);
        BO->setHasNoSignedWrap(false);
        BO->setHasNoUnsignedWrap(false);
      }
    }
    if (auto *PEO = dyn_cast<PossiblyExactOperator>(&I); PEO && PEO->isExact()) {
      cast<BinaryOperator>(&I)->setIsExact(false);
      Local = true;
    }
    if (auto *GEP = dyn_cast<GetElementPtrInst>(&I); GEP && GEP->isInBounds()) {
      GEP->setNoWrapFlags(GEPNoWrapFlags::none());
      Local = true;
    }
    if (auto *TI = dyn_cast<TruncInst>(&I);
        TI && TI->hasNoUnsignedWrap()) {
      TI->setHasNoUnsignedWrap(false);
      Local = true;
    }
    if (!Local) continue;
    Changed = true;
    ++M.FlagsSanitized;
    Proofs.push_back({F.getName().str(), "lifted_semantics_sanitize",
                      valueName(I), "lifted_provenance", "proved"});
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
