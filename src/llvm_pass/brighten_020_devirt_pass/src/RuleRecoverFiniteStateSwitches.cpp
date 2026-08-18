#include "BrightenDevirtPass.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

#include <optional>

namespace brighten_devirt {

using namespace llvm;

namespace {

static constexpr unsigned MaxFiniteValues = 16;

struct FiniteValues {
  bool Known = false;
  SmallVector<APInt, 4> Values;

  static FiniteValues unknown() { return {}; }

  static FiniteValues singleton(const APInt &Value) {
    FiniteValues Result;
    Result.Known = true;
    Result.Values.push_back(Value);
    return Result;
  }

  bool add(const APInt &Value) {
    if (!Known)
      return false;
    for (const APInt &Existing : Values)
      if (Existing == Value)
        return true;
    if (Values.size() >= MaxFiniteValues) {
      Known = false;
      Values.clear();
      return false;
    }
    Values.push_back(Value);
    return true;
  }

  bool merge(const FiniteValues &Other) {
    if (!Known || !Other.Known) {
      Known = false;
      Values.clear();
      return false;
    }
    for (const APInt &Value : Other.Values)
      if (!add(Value))
        return false;
    return true;
  }

  std::optional<APInt> single() const {
    if (!Known || Values.size() != 1)
      return std::nullopt;
    return Values.front();
  }
};

static bool hasPoisonFlags(const BinaryOperator &BO) {
  if (const auto *Overflow = dyn_cast<OverflowingBinaryOperator>(&BO))
    if (Overflow->hasNoSignedWrap() || Overflow->hasNoUnsignedWrap())
      return true;
  if (const auto *Exact = dyn_cast<PossiblyExactOperator>(&BO))
    if (Exact->isExact())
      return true;
  return false;
}

static std::optional<unsigned> shiftAmount(const APInt &Amount,
                                           unsigned BitWidth) {
  if (Amount.getActiveBits() > 64)
    return std::nullopt;
  uint64_t Limited = Amount.getLimitedValue();
  if (Limited >= BitWidth)
    return std::nullopt;
  return static_cast<unsigned>(Limited);
}

static std::optional<APInt> evaluateBinary(unsigned Opcode, const APInt &LHS,
                                           const APInt &RHS) {
  if (LHS.getBitWidth() != RHS.getBitWidth())
    return std::nullopt;
  switch (Opcode) {
  case Instruction::Add:
    return LHS + RHS;
  case Instruction::Sub:
    return LHS - RHS;
  case Instruction::Mul:
    return LHS * RHS;
  case Instruction::Xor:
    return LHS ^ RHS;
  case Instruction::And:
    return LHS & RHS;
  case Instruction::Or:
    return LHS | RHS;
  case Instruction::Shl:
    if (auto Amount = shiftAmount(RHS, LHS.getBitWidth()))
      return LHS.shl(*Amount);
    return std::nullopt;
  case Instruction::LShr:
    if (auto Amount = shiftAmount(RHS, LHS.getBitWidth()))
      return LHS.lshr(*Amount);
    return std::nullopt;
  case Instruction::AShr:
    if (auto Amount = shiftAmount(RHS, LHS.getBitWidth()))
      return LHS.ashr(*Amount);
    return std::nullopt;
  default:
    return std::nullopt;
  }
}

static std::optional<bool> evaluatePredicate(CmpInst::Predicate Predicate,
                                             const APInt &LHS,
                                             const APInt &RHS) {
  switch (Predicate) {
  case CmpInst::ICMP_EQ:
    return LHS == RHS;
  case CmpInst::ICMP_NE:
    return LHS != RHS;
  case CmpInst::ICMP_UGT:
    return LHS.ugt(RHS);
  case CmpInst::ICMP_UGE:
    return LHS.uge(RHS);
  case CmpInst::ICMP_ULT:
    return LHS.ult(RHS);
  case CmpInst::ICMP_ULE:
    return LHS.ule(RHS);
  case CmpInst::ICMP_SGT:
    return LHS.sgt(RHS);
  case CmpInst::ICMP_SGE:
    return LHS.sge(RHS);
  case CmpInst::ICMP_SLT:
    return LHS.slt(RHS);
  case CmpInst::ICMP_SLE:
    return LHS.sle(RHS);
  default:
    return std::nullopt;
  }
}

class EdgeValueEvaluator {
public:
  EdgeValueEvaluator(BasicBlock *Hub, BasicBlock *EdgePred)
      : Hub(Hub), EdgePred(EdgePred) {}

  FiniteValues evaluate(Value *V) {
    if (!V)
      return FiniteValues::unknown();
    if (auto It = Cache.find(V); It != Cache.end())
      return It->second;
    if (!Active.insert(V).second)
      return FiniteValues::unknown();
    FiniteValues Result = evaluateImpl(V);
    Active.erase(V);
    Cache[V] = Result;
    return Result;
  }

private:
  FiniteValues evaluateImpl(Value *V) {
    if (auto *CI = dyn_cast<ConstantInt>(V))
      return FiniteValues::singleton(CI->getValue());
    if (isa<UndefValue>(V) || isa<PoisonValue>(V))
      return FiniteValues::unknown();

    if (auto *PN = dyn_cast<PHINode>(V)) {
      if (PN->getParent() == Hub) {
        int Index = PN->getBasicBlockIndex(EdgePred);
        return Index < 0 ? FiniteValues::unknown()
                         : evaluate(PN->getIncomingValue(Index));
      }
      FiniteValues Joined;
      Joined.Known = true;
      for (Value *Incoming : PN->incoming_values())
        if (!Joined.merge(evaluate(Incoming)))
          return FiniteValues::unknown();
      return Joined.Values.empty() ? FiniteValues::unknown() : Joined;
    }

    if (auto *Freeze = dyn_cast<FreezeInst>(V))
      return evaluate(Freeze->getOperand(0));

    if (auto *Cast = dyn_cast<CastInst>(V)) {
      FiniteValues Input = evaluate(Cast->getOperand(0));
      if (!Input.Known || !Cast->getType()->isIntegerTy())
        return FiniteValues::unknown();
      unsigned Width = cast<IntegerType>(Cast->getType())->getBitWidth();
      FiniteValues Result;
      Result.Known = true;
      for (const APInt &Value : Input.Values) {
        APInt Converted = Value;
        switch (Cast->getOpcode()) {
        case Instruction::Trunc:
          Converted = Value.trunc(Width);
          break;
        case Instruction::ZExt:
          Converted = Value.zext(Width);
          break;
        case Instruction::SExt:
          Converted = Value.sext(Width);
          break;
        case Instruction::BitCast:
          if (Value.getBitWidth() != Width)
            return FiniteValues::unknown();
          break;
        default:
          return FiniteValues::unknown();
        }
        if (!Result.add(Converted))
          return FiniteValues::unknown();
      }
      return Result;
    }

    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (!BO->getType()->isIntegerTy() || hasPoisonFlags(*BO))
        return FiniteValues::unknown();
      FiniteValues Left = evaluate(BO->getOperand(0));
      FiniteValues Right = evaluate(BO->getOperand(1));
      if (!Left.Known || !Right.Known)
        return FiniteValues::unknown();
      FiniteValues Result;
      Result.Known = true;
      for (const APInt &LHS : Left.Values)
        for (const APInt &RHS : Right.Values) {
          auto Folded = evaluateBinary(BO->getOpcode(), LHS, RHS);
          if (!Folded || !Result.add(*Folded))
            return FiniteValues::unknown();
        }
      return Result.Values.empty() ? FiniteValues::unknown() : Result;
    }

    if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
      FiniteValues Left = evaluate(Cmp->getOperand(0));
      FiniteValues Right = evaluate(Cmp->getOperand(1));
      if (!Left.Known || !Right.Known)
        return FiniteValues::unknown();
      FiniteValues Result;
      Result.Known = true;
      for (const APInt &LHS : Left.Values)
        for (const APInt &RHS : Right.Values) {
          auto Folded = evaluatePredicate(Cmp->getPredicate(), LHS, RHS);
          if (!Folded || !Result.add(APInt(1, *Folded)))
            return FiniteValues::unknown();
        }
      return Result;
    }

    if (auto *Select = dyn_cast<SelectInst>(V)) {
      FiniteValues Condition = evaluate(Select->getCondition());
      auto Single = Condition.single();
      if (!Single || Single->getBitWidth() != 1)
        return FiniteValues::unknown();
      return evaluate(Single->isOne() ? Select->getTrueValue()
                                      : Select->getFalseValue());
    }

    return FiniteValues::unknown();
  }

  BasicBlock *Hub;
  BasicBlock *EdgePred;
  DenseMap<Value *, FiniteValues> Cache;
  SmallPtrSet<Value *, 32> Active;
};

static bool collectSelectorGraph(Value *V, BasicBlock *Hub,
                                 SmallPtrSetImpl<Instruction *> &Instructions,
                                 SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getParent() != Hub)
    return true;
  if (!(isa<PHINode>(I) || isa<BinaryOperator>(I) || isa<CastInst>(I) ||
        isa<SelectInst>(I) || isa<ICmpInst>(I) || isa<FreezeInst>(I)))
    return false;
  if (I->mayReadOrWriteMemory() || I->mayHaveSideEffects())
    return false;
  Instructions.insert(I);
  if (isa<PHINode>(I))
    return true;
  for (Use &Operand : I->operands())
    if (!collectSelectorGraph(Operand.get(), Hub, Instructions, Seen))
      return false;
  return true;
}

static bool selectorIsLocalToHub(
    const SmallPtrSetImpl<Instruction *> &SelectorInstructions,
    BasicBlock *Hub) {
  for (Instruction *I : SelectorInstructions)
    for (User *U : I->users()) {
      auto *UseI = dyn_cast<Instruction>(U);
      if (!UseI || UseI->getParent() != Hub)
        return false;
    }
  return true;
}

static bool hubContainsOnlySelector(
    BasicBlock *Hub, SwitchInst *SW,
    const SmallPtrSetImpl<Instruction *> &SelectorInstructions) {
  for (Instruction &I : *Hub) {
    if (&I == SW || SelectorInstructions.contains(&I) ||
        isa<DbgInfoIntrinsic>(&I))
      continue;
    auto *PN = dyn_cast<PHINode>(&I);
    if (!PN || !PN->use_empty())
      return false;
  }
  return true;
}

static BasicBlock *destinationFor(SwitchInst *SW, const APInt &Value) {
  auto *ConditionTy = dyn_cast<IntegerType>(SW->getCondition()->getType());
  if (!ConditionTy || ConditionTy->getBitWidth() != Value.getBitWidth())
    return nullptr;
  ConstantInt *State = ConstantInt::get(ConditionTy, Value);
  auto Case = SW->findCaseValue(State);
  return Case == SW->case_default() ? SW->getDefaultDest()
                                    : Case->getCaseSuccessor();
}

static bool valueAvailableBeforeHub(Value *V, BasicBlock *Pred,
                                    BasicBlock *Hub, DominatorTree &DT) {
  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return true;
  if (I->getParent() == Hub)
    return false;
  return DT.dominates(I, Pred->getTerminator());
}

struct EdgeRewrite {
  BasicBlock *Pred = nullptr;
  BranchInst *Branch = nullptr;
  BasicBlock *Destination = nullptr;
};

struct PhiExpansion {
  PHINode *Phi = nullptr;
  Value *Value = nullptr;
  SmallVector<BasicBlock *, 8> Preds;
};

} // namespace

bool BrightenDevirtPass::RecoverFiniteStateSwitches(Module &M) {
  SmallVector<SwitchInst *, 32> Worklist;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        if (auto *SW = dyn_cast<SwitchInst>(BB.getTerminator()))
          Worklist.push_back(SW);

  bool Changed = false;
  for (SwitchInst *SW : Worklist) {
    BasicBlock *Hub = SW->getParent();
    if (!Hub || pred_empty(Hub) ||
        !SW->getCondition()->getType()->isIntegerTy())
      continue;

    SmallPtrSet<Instruction *, 32> SelectorInstructions;
    SmallPtrSet<Value *, 64> Seen;
    if (!collectSelectorGraph(SW->getCondition(), Hub, SelectorInstructions,
                              Seen) ||
        SelectorInstructions.empty() ||
        !selectorIsLocalToHub(SelectorInstructions, Hub) ||
        !hubContainsOnlySelector(Hub, SW, SelectorInstructions))
      continue;

    Function *F = Hub->getParent();
    DominatorTree DT(*F);
    SmallVector<EdgeRewrite, 16> Rewrites;
    bool Proven = true;
    for (BasicBlock *Pred : predecessors(Hub)) {
      auto *Branch = dyn_cast<BranchInst>(Pred->getTerminator());
      if (!Branch || !Branch->isUnconditional() ||
          Branch->getSuccessor(0) != Hub) {
        Proven = false;
        break;
      }
      EdgeValueEvaluator Evaluator(Hub, Pred);
      auto Selector = Evaluator.evaluate(SW->getCondition()).single();
      BasicBlock *Destination =
          Selector ? destinationFor(SW, *Selector) : nullptr;
      if (!Destination || Destination == Hub) {
        Proven = false;
        break;
      }
      Rewrites.push_back({Pred, Branch, Destination});
    }
    if (!Proven || Rewrites.empty())
      continue;

    SmallVector<PhiExpansion, 16> PhiExpansions;
    SmallPtrSet<BasicBlock *, 8> SeenDestinations;
    for (BasicBlock *Destination : successors(Hub)) {
      if (!SeenDestinations.insert(Destination).second)
        continue;
      SmallVector<BasicBlock *, 8> NewPreds;
      for (const EdgeRewrite &Rewrite : Rewrites)
        if (Rewrite.Destination == Destination &&
            !llvm::is_contained(NewPreds, Rewrite.Pred))
          NewPreds.push_back(Rewrite.Pred);
      if (NewPreds.empty())
        continue;

      for (PHINode &Phi : Destination->phis()) {
        int HubIndex = Phi.getBasicBlockIndex(Hub);
        if (HubIndex < 0)
          continue;
        Value *Incoming = Phi.getIncomingValue(HubIndex);
        for (BasicBlock *Pred : NewPreds)
          if (!valueAvailableBeforeHub(Incoming, Pred, Hub, DT)) {
            Proven = false;
            break;
          }
        if (!Proven)
          break;
        PhiExpansions.push_back({&Phi, Incoming, NewPreds});
      }
      if (!Proven)
        break;
    }
    if (!Proven)
      continue;

    for (PhiExpansion &Expansion : PhiExpansions)
      for (BasicBlock *Pred : Expansion.Preds)
        Expansion.Phi->addIncoming(Expansion.Value, Pred);

    for (const EdgeRewrite &Rewrite : Rewrites)
      Rewrite.Branch->setSuccessor(0, Rewrite.Destination);

    errs() << "[devirt-v2] abstractly recovered finite-state switch in @"
           << F->getName() << " with " << Rewrites.size()
           << " proven edge(s)\n";
    DeleteDeadBlock(Hub);
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_devirt
