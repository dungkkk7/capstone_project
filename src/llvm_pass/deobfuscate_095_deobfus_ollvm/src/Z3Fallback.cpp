#include "Deobfuscate095Internal.h"
#include "RuleEngineSupport.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"

#include <memory>
#include <optional>

namespace deobfuscate095 {
namespace {

using namespace llvm;

Value *leaf(const SimplificationProof &P, unsigned Index) {
  return Index < P.Leaves.size() ? P.Leaves[Index] : nullptr;
}

ConstantInt *integerConstant(IntegerType *Ty, uint64_t Value) {
  return ConstantInt::get(Ty, Value, false);
}

Value *materializeProof(IRBuilder<> &B, Instruction &Old,
                        const SimplificationProof &P) {
  auto *Ty = dyn_cast<IntegerType>(Old.getType());
  if (!Ty || Ty->getBitWidth() > 64)
    return nullptr;

  Value *L0 = leaf(P, 0);
  Value *L1 = leaf(P, 1);
  Value *A = leaf(P, P.LeftIndex);
  Value *C = leaf(P, P.RightIndex);
  auto K = [&]() -> ConstantInt * {
    return integerConstant(Ty, P.Constant);
  };
  auto IsTy = [&](Value *V) {
    return V && V->getType() == Ty;
  };

  switch (P.Kind) {
  case CandidateKind::ConstantZero:
    return ConstantInt::get(Ty, 0);
  case CandidateKind::ConstantOne:
    return ConstantInt::get(Ty, 1);
  case CandidateKind::ConstantAllOnes:
    return cast<ConstantInt>(ConstantInt::getAllOnesValue(Ty));
  case CandidateKind::Leaf0:
    return IsTy(L0) ? L0 : nullptr;
  case CandidateKind::Leaf1:
    return IsTy(L1) ? L1 : nullptr;
  case CandidateKind::Add:
  case CandidateKind::PairAdd:
    return IsTy(A) && IsTy(C)
               ? B.CreateAdd(A, C, "deobf.z3.add")
               : nullptr;
  case CandidateKind::Sub01:
  case CandidateKind::PairSub:
    return IsTy(A) && IsTy(C)
               ? B.CreateSub(A, C, "deobf.z3.sub")
               : nullptr;
  case CandidateKind::Sub10:
    return IsTy(L0) && IsTy(L1)
               ? B.CreateSub(L1, L0, "deobf.z3.sub")
               : nullptr;
  case CandidateKind::PairMul:
    return IsTy(A) && IsTy(C)
               ? B.CreateMul(A, C, "deobf.z3.mul")
               : nullptr;
  case CandidateKind::Xor:
  case CandidateKind::PairXor:
    return IsTy(A) && IsTy(C)
               ? B.CreateXor(A, C, "deobf.z3.xor")
               : nullptr;
  case CandidateKind::And:
  case CandidateKind::PairAnd:
    return IsTy(A) && IsTy(C)
               ? B.CreateAnd(A, C, "deobf.z3.and")
               : nullptr;
  case CandidateKind::Or:
  case CandidateKind::PairOr:
    return IsTy(A) && IsTy(C)
               ? B.CreateOr(A, C, "deobf.z3.or")
               : nullptr;
  case CandidateKind::Not0:
  case CandidateKind::UnaryNot:
    return IsTy(L0) ? B.CreateNot(L0, "deobf.z3.not")
                    : nullptr;
  case CandidateKind::Not1:
    return IsTy(L1) ? B.CreateNot(L1, "deobf.z3.not")
                    : nullptr;
  case CandidateKind::Neg0:
  case CandidateKind::UnaryNeg:
    return IsTy(L0) ? B.CreateNeg(L0, "deobf.z3.neg")
                    : nullptr;
  case CandidateKind::Neg1:
    return IsTy(L1) ? B.CreateNeg(L1, "deobf.z3.neg")
                    : nullptr;
  case CandidateKind::AddConst:
    return IsTy(L0) ? B.CreateAdd(L0, K(), "deobf.z3.addc")
                    : nullptr;
  case CandidateKind::SubConst:
    return IsTy(L0) ? B.CreateSub(L0, K(), "deobf.z3.subc")
                    : nullptr;
  case CandidateKind::XorConst:
    return IsTy(L0) ? B.CreateXor(L0, K(), "deobf.z3.xorc")
                    : nullptr;
  case CandidateKind::AndConst:
    return IsTy(L0) ? B.CreateAnd(L0, K(), "deobf.z3.andc")
                    : nullptr;
  case CandidateKind::OrConst:
    return IsTy(L0) ? B.CreateOr(L0, K(), "deobf.z3.orc")
                    : nullptr;
  case CandidateKind::MulConst:
    return IsTy(L0) ? B.CreateMul(L0, K(), "deobf.z3.mulc")
                    : nullptr;
  case CandidateKind::ShlConst:
    return IsTy(L0) ? B.CreateShl(L0, K(), "deobf.z3.shlc")
                    : nullptr;
  case CandidateKind::LShrConst:
    return IsTy(L0) ? B.CreateLShr(L0, K(), "deobf.z3.lshrc")
                    : nullptr;
  case CandidateKind::AShrConst:
    return IsTy(L0) ? B.CreateAShr(L0, K(), "deobf.z3.ashrc")
                    : nullptr;
  }
  return nullptr;
}

bool runPredicateFallback(Module &M, Z3Prover &Prover,
                          unsigned Limit,
                          FallbackMetrics &Metrics) {
  if (Limit == 0)
    return false;

  SmallVector<Value *, 64> Conditions;
  SmallPtrSet<Value *, 64> Seen;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      Value *Condition = nullptr;
      if (auto *BI = dyn_cast<BranchInst>(&I);
          BI && BI->isConditional())
        Condition = BI->getCondition();
      else if (auto *SI = dyn_cast<SelectInst>(&I))
        Condition = SI->getCondition();
      if (!Condition || isa<ConstantInt>(Condition) ||
          !Seen.insert(Condition).second)
        continue;
      Conditions.push_back(Condition);
      if (Conditions.size() >= Limit)
        break;
    }
    if (Conditions.size() >= Limit)
      break;
  }

  bool Changed = false;
  for (Value *Condition : Conditions) {
    ++Metrics.PredicateCandidates;
    std::optional<bool> Proven =
        Prover.proveBooleanConstant(Condition);
    if (!Proven)
      continue;
    ++Metrics.PredicateProofs;

    SmallVector<User *, 16> Users(
        Condition->user_begin(), Condition->user_end());
    for (User *U : Users) {
      if (auto *BI = dyn_cast<BranchInst>(U)) {
        if (BI->getCondition() == Condition) {
          rule_detail::replaceBranch(*BI, *Proven);
          Changed = true;
        }
      } else if (auto *SI = dyn_cast<SelectInst>(U)) {
        if (SI->getCondition() == Condition) {
          Value *Replacement = *Proven
                                   ? SI->getTrueValue()
                                   : SI->getFalseValue();
          SI->replaceAllUsesWith(Replacement);
          SI->eraseFromParent();
          Changed = true;
        }
      }
    }
  }
  if (Changed)
    Prover.invalidateBooleanCache();
  return Changed;
}

bool runMBAFallback(Module &M, Z3Prover &Prover,
                    const FallbackConfig &Config,
                    FallbackMetrics &Metrics) {
  if (Config.DisableMBA || Config.MBALimit == 0)
    return false;

  SmallVector<Instruction *, 256> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      auto *ITy = dyn_cast<IntegerType>(I.getType());
      if (!ITy || ITy->getBitWidth() > 64 ||
          isa<PHINode>(I) || isa<SelectInst>(I) ||
          isa<ICmpInst>(I) || I.use_empty())
        continue;
      if (!isa<BinaryOperator>(I) && !isa<CastInst>(I))
        continue;
      Candidates.push_back(&I);
      if (Candidates.size() >= Config.MBALimit)
        break;
    }
    if (Candidates.size() >= Config.MBALimit)
      break;
  }

  bool Changed = false;
  for (Instruction *I : Candidates) {
    if (!I->getParent() || I->use_empty())
      continue;
    ++Metrics.MBACandidates;
    auto Proof = Prover.proveSimplerInteger(
        I, 3, Config.MBARecipes);
    if (!Proof)
      continue;

    IRBuilder<> Builder(I);
    Value *Replacement =
        materializeProof(Builder, *I, *Proof);
    if (!Replacement || Replacement == I ||
        Replacement->getType() != I->getType())
      continue;
    ++Metrics.MBAProofs;
    I->replaceAllUsesWith(Replacement);
    I->eraseFromParent();
    Changed = true;
  }
  if (Changed)
    Prover.invalidateBooleanCache();
  return Changed;
}

} // namespace

bool runZ3Fallback(Module &M, const FallbackConfig &Config,
                   FallbackMetrics &Metrics, ProofStats &Proofs) {
  Z3Prover Prover(Config.TimeoutMs);
  bool Changed = false;
  Changed |= runPredicateFallback(
      M, Prover, Config.PredicateLimit, Metrics);
  Changed |= runMBAFallback(M, Prover, Config, Metrics);
  Proofs = Prover.stats();
  return Changed;
}

} // namespace deobfuscate095
