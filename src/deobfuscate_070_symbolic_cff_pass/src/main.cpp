#include <algorithm>
#include <cstdlib>
#include <limits>
#include <optional>
#include <unordered_map>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Support/Casting.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Transforms/Utils/Local.h"
#include "z3++.h"

namespace deobfuscate_symbolic_cff {

using namespace llvm;

namespace {

constexpr StringLiteral kProxyPhiMD = "lifter.deobf.symbolic.unflat.proxy";
constexpr StringLiteral kProxyOriginMD = "lifter.deobf.symbolic.unflat.origin";
constexpr StringLiteral kProcessedFunctionMD = "lifter.deobf.symbolic_cff.processed";
constexpr unsigned kZ3TimeoutMs = 20;

thread_local const DenseMap<BasicBlock *, BasicBlock *> *CurrentPathPreds = nullptr;

struct PathPredsScope {
  const DenseMap<BasicBlock *, BasicBlock *> *Old;
  PathPredsScope(const DenseMap<BasicBlock *, BasicBlock *> *NewMap) {
    Old = CurrentPathPreds;
    CurrentPathPreds = NewMap;
  }
  ~PathPredsScope() {
    CurrentPathPreds = Old;
  }
};

bool traceCFF() { return std::getenv("LIFTER_CFF_TRACE") != nullptr; }

void trace(StringRef Msg) {
  if (traceCFF()) llvm::errs() << "[CFFTRACE] " << Msg << "\n";
}

struct DispatcherInfo {
  BasicBlock *block = nullptr;
  SwitchInst *sw = nullptr;
  Value *condition = nullptr;
  PHINode *state_phi = nullptr;
  SmallVector<PHINode *, 8> phis;
  struct TargetInfo {
    BasicBlock *target = nullptr;
    BasicBlock *dispatch_pred = nullptr;
  };
  DenseMap<int64_t, TargetInfo> targets;
};

struct Redirect {
  BasicBlock *src = nullptr;
  BasicBlock *old_successor = nullptr;
  BasicBlock *true_target = nullptr;
  BasicBlock *true_dispatch_pred = nullptr;
  Value *condition = nullptr;
  BasicBlock *false_target = nullptr;
  BasicBlock *false_dispatch_pred = nullptr;
};

using EvalEnv = DenseMap<Value *, APInt>;
struct SolvedState {
  ConstantInt *state;
  EvalEnv env;
};
using StateSolveCache = DenseMap<BasicBlock *, SmallVector<SolvedState, 8>>;
using PhiValueMap = DenseMap<PHINode *, Value *>;

struct IncomingEdge {
  BasicBlock *from = nullptr;
  BasicBlock *dispatch_pred = nullptr;
  PhiValueMap values;
};

std::optional<APInt> evalInt(Value *V, const DataLayout &DL, EvalEnv &Env, unsigned Depth = 0);
std::optional<DispatcherInfo::TargetInfo> targetForState(const DispatcherInfo &Info, ConstantInt *State,
                                                         const DataLayout &DL, const EvalEnv &InitialEnv = EvalEnv());

std::optional<uint64_t> globalByteOffset(Value *Ptr, GlobalVariable *&GV, const DataLayout &DL) {
  Ptr = Ptr->stripPointerCasts();
  APInt Offset(DL.getPointerSizeInBits(), 0);
  if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
    if (!GEP->accumulateConstantOffset(DL, Offset)) return std::nullopt;
    Ptr = GEP->getPointerOperand()->stripPointerCasts();
  }
  GV = dyn_cast<GlobalVariable>(Ptr);
  if (!GV || !GV->hasInitializer()) return std::nullopt;
  return Offset.getZExtValue();
}

std::optional<APInt> evalConstantGlobalLoad(LoadInst *LI, const DataLayout &DL) {
  if (!LI || LI->isAtomic()) return std::nullopt;
  auto *ITy = dyn_cast<IntegerType>(LI->getType());
  if (!ITy || ITy->getBitWidth() == 0 || ITy->getBitWidth() > 64 || ITy->getBitWidth() % 8) {
    return std::nullopt;
  }

  GlobalVariable *GV = nullptr;
  auto Off = globalByteOffset(LI->getPointerOperand(), GV, DL);
  if (!Off || !GV || !GV->isConstant()) return std::nullopt;

  unsigned Bytes = ITy->getBitWidth() / 8;
  Constant *Init = GV->getInitializer();
  uint64_t Value = 0;
  bool Ok = false;
  if (auto *CDA = dyn_cast<ConstantDataArray>(Init)) {
    if ((CDA->isString() || CDA->getElementType()->isIntegerTy(8)) && *Off + Bytes <= CDA->getNumElements()) {
      for (unsigned I = 0; I < Bytes; ++I) {
        unsigned Shift = DL.isLittleEndian() ? I * 8 : (Bytes - 1 - I) * 8;
        Value |= static_cast<uint64_t>(CDA->getElementAsInteger(*Off + I)) << Shift;
      }
      Ok = true;
    }
  } else if (auto *CA = dyn_cast<ConstantArray>(Init)) {
    if (CA->getType()->getElementType()->isIntegerTy(8) && *Off + Bytes <= CA->getNumOperands()) {
      Ok = true;
      for (unsigned I = 0; I < Bytes; ++I) {
        auto *CI = dyn_cast<ConstantInt>(CA->getOperand(*Off + I));
        if (!CI) { Ok = false; break; }
        unsigned Shift = DL.isLittleEndian() ? I * 8 : (Bytes - 1 - I) * 8;
        Value |= static_cast<uint64_t>(CI->getZExtValue()) << Shift;
      }
    }
  } else if (auto *CI = dyn_cast<ConstantInt>(Init)) {
    if (*Off == 0 && Bytes == (CI->getBitWidth() + 7) / 8) {
      Value = CI->getZExtValue();
      Ok = true;
    }
  }
  if (!Ok) return std::nullopt;
  return APInt(ITy->getBitWidth(), Value);
}

std::optional<bool> evalICmp(ICmpInst *ICI, const DataLayout &DL, EvalEnv &Env, unsigned Depth) {
  auto L = evalInt(ICI->getOperand(0), DL, Env, Depth + 1);
  auto R = evalInt(ICI->getOperand(1), DL, Env, Depth + 1);
  if (!L || !R) return std::nullopt;
  unsigned Bits = std::max(L->getBitWidth(), R->getBitWidth());
  APInt A = L->zextOrTrunc(Bits);
  APInt B = R->zextOrTrunc(Bits);
  switch (ICI->getPredicate()) {
    case ICmpInst::ICMP_EQ: return A == B;
    case ICmpInst::ICMP_NE: return A != B;
    case ICmpInst::ICMP_UGT: return A.ugt(B);
    case ICmpInst::ICMP_UGE: return A.uge(B);
    case ICmpInst::ICMP_ULT: return A.ult(B);
    case ICmpInst::ICMP_ULE: return A.ule(B);
    case ICmpInst::ICMP_SGT: return A.sgt(B);
    case ICmpInst::ICMP_SGE: return A.sge(B);
    case ICmpInst::ICMP_SLT: return A.slt(B);
    case ICmpInst::ICMP_SLE: return A.sle(B);
    default: return std::nullopt;
  }
}

std::optional<bool> evalBool(Value *V, const DataLayout &DL, EvalEnv &Env, unsigned Depth = 0) {
  if (!V || Depth > 32) return std::nullopt;
  if (auto *ICI = dyn_cast<ICmpInst>(V)) return evalICmp(ICI, DL, Env, Depth + 1);
  auto Val = evalInt(V, DL, Env, Depth + 1);
  if (!Val || Val->getBitWidth() != 1) return std::nullopt;
  return Val->isOne();
}

std::optional<APInt> evalInt(Value *V, const DataLayout &DL, EvalEnv &Env, unsigned Depth) {
  if (!V || Depth > 32) return std::nullopt;
  if (auto It = Env.find(V); It != Env.end()) return It->second;
  if (auto *CI = dyn_cast<ConstantInt>(V)) return CI->getValue();
  if (auto *LI = dyn_cast<LoadInst>(V)) return evalConstantGlobalLoad(LI, DL);
  if (auto *ICI = dyn_cast<ICmpInst>(V)) {
    auto B = evalICmp(ICI, DL, Env, Depth + 1);
    if (!B) return std::nullopt;
    return APInt(1, *B ? 1 : 0);
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    auto C = evalBool(Sel->getCondition(), DL, Env, Depth + 1);
    if (!C) return std::nullopt;
    return evalInt(*C ? Sel->getTrueValue() : Sel->getFalseValue(), DL, Env, Depth + 1);
  }
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (CurrentPathPreds) {
      auto It = CurrentPathPreds->find(PN->getParent());
      if (It != CurrentPathPreds->end()) {
        BasicBlock *Pred = It->second;
        int Idx = PN->getBasicBlockIndex(Pred);
        if (Idx >= 0) {
          return evalInt(PN->getIncomingValue(Idx), DL, Env, Depth + 1);
        }
      }
    }
    std::optional<APInt> Seen;
    for (Value *Incoming : PN->incoming_values()) {
      auto Cur = evalInt(Incoming, DL, Env, Depth + 1);
      if (!Cur) return std::nullopt;
      if (!Seen) Seen = *Cur;
      else if (*Seen != *Cur) return std::nullopt;
    }
    return Seen;
  }
  if (auto *Fr = dyn_cast<FreezeInst>(V)) return evalInt(Fr->getOperand(0), DL, Env, Depth + 1);

  if (auto *Cast = dyn_cast<CastInst>(V)) {
    auto Inner = evalInt(Cast->getOperand(0), DL, Env, Depth + 1);
    if (!Inner) return std::nullopt;
    auto *ITy = dyn_cast<IntegerType>(Cast->getDestTy());
    if (!ITy) return std::nullopt;
    unsigned Bits = ITy->getBitWidth();
    if (isa<SExtInst>(Cast)) return Inner->sextOrTrunc(Bits);
    return Inner->zextOrTrunc(Bits);
  }

  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    auto L = evalInt(BO->getOperand(0), DL, Env, Depth + 1);
    auto R = evalInt(BO->getOperand(1), DL, Env, Depth + 1);
    if (!L || !R) return std::nullopt;
    unsigned Bits = std::max(L->getBitWidth(), R->getBitWidth());
    APInt A = L->zextOrTrunc(Bits);
    APInt B = R->zextOrTrunc(Bits);
    switch (BO->getOpcode()) {
      case Instruction::Add: return A + B;
      case Instruction::Sub: return A - B;
      case Instruction::Mul: return A * B;
      case Instruction::And: return A & B;
      case Instruction::Or: return A | B;
      case Instruction::Xor: return A ^ B;
      case Instruction::Shl: return A.shl(B.getLimitedValue(Bits));
      case Instruction::LShr: return A.lshr(B.getLimitedValue(Bits));
      case Instruction::AShr: return A.ashr(B.getLimitedValue(Bits));
      default: return std::nullopt;
    }
  }
  return std::nullopt;
}

ConstantInt *evalState(Value *V, IntegerType *Ty, const DataLayout &DL, EvalEnv Env) {
  auto Val = evalInt(V, DL, Env);
  if (!Val) return nullptr;
  return cast<ConstantInt>(ConstantInt::get(Ty, Val->zextOrTrunc(Ty->getBitWidth())));
}

ConstantInt *evalState(Value *V, IntegerType *Ty, const DataLayout &DL) {
  EvalEnv Env;
  return evalState(V, Ty, DL, Env);
}

bool isProxyPhi(const PHINode *PN) { return PN->getMetadata(kProxyPhiMD) != nullptr; }

void markProxyPhi(PHINode *Proxy, PHINode *Original) {
  Proxy->setMetadata(kProxyPhiMD, MDNode::get(Proxy->getContext(), {}));
  if (Original->hasName()) {
    Proxy->setMetadata(kProxyOriginMD,
                       MDNode::get(Proxy->getContext(), MDString::get(Proxy->getContext(), Original->getName())));
  }
}

bool proxyMatchesOriginal(PHINode *Proxy, PHINode *Original) {
  if (!Proxy || !Original || !isProxyPhi(Proxy) || Proxy->getType() != Original->getType()) return false;
  if (auto *MD = Proxy->getMetadata(kProxyOriginMD)) {
    if (MD->getNumOperands() != 1) return false;
    auto *S = dyn_cast_or_null<MDString>(MD->getOperand(0).get());
    return S && Original->hasName() && S->getString() == Original->getName();
  }
  if (!Original->hasName()) return false;
  std::string Prefix = (Original->getName() + ".symunflat").str();
  return Proxy->getName().starts_with(Prefix);
}

PHINode *proxyPhiForOriginal(PHINode *Original, BasicBlock *BB) {
  if (!Original || !BB) return nullptr;
  for (Instruction &I : *BB) {
    auto *PN = dyn_cast<PHINode>(&I);
    if (!PN) break;
    if (proxyMatchesOriginal(PN, Original)) return PN;
  }
  return nullptr;
}

std::optional<unsigned> intBitWidth(Type *Ty) {
  auto *ITy = dyn_cast<IntegerType>(Ty);
  if (!ITy || ITy->getBitWidth() == 0 || ITy->getBitWidth() > 64) return std::nullopt;
  return ITy->getBitWidth();
}

z3::expr z3Const(z3::context &Ctx, const APInt &Val, unsigned Bits) {
  return Ctx.bv_val(Val.zextOrTrunc(Bits).getZExtValue(), Bits);
}

z3::expr resizeBV(z3::expr Expr, unsigned FromBits, unsigned ToBits, bool Signed = false) {
  if (FromBits == ToBits) return Expr;
  if (FromBits < ToBits) return Signed ? z3::sext(Expr, ToBits - FromBits) : z3::zext(Expr, ToBits - FromBits);
  return Expr.extract(ToBits - 1, 0);
}

struct Z3ExprTranslator {
  z3::context &Ctx;
  const DataLayout &DL;
  PHINode *StatePhi = nullptr;
  z3::expr StateExpr;
  std::unordered_map<Value *, z3::expr> VarMap;

  Z3ExprTranslator(z3::context &Ctx, const DataLayout &DL, PHINode *StatePhi, z3::expr StateExpr)
      : Ctx(Ctx), DL(DL), StatePhi(StatePhi), StateExpr(StateExpr) {}

  std::optional<z3::expr> intExpr(Value *V, unsigned Depth = 0) {
    if (!V || Depth > 48) return std::nullopt;
    if (StatePhi && V == StatePhi) return StateExpr;

    auto BW = intBitWidth(V->getType());
    if (!BW) return std::nullopt;

    auto It = VarMap.find(V);
    if (It != VarMap.end()) return It->second;

    if (auto *CI = dyn_cast<ConstantInt>(V)) return z3Const(Ctx, CI->getValue(), *BW);
    if (auto *LI = dyn_cast<LoadInst>(V)) {
      if (!LI->isVolatile()) {
        auto Val = evalConstantGlobalLoad(LI, DL);
        if (Val) return z3Const(Ctx, *Val, *BW);
      }
    }
    if (auto *Fr = dyn_cast<FreezeInst>(V)) return intExpr(Fr->getOperand(0), Depth + 1);
    if (auto *ICI = dyn_cast<ICmpInst>(V)) {
      auto B = boolExpr(ICI, Depth + 1);
      if (!B) return std::nullopt;
      return z3::ite(*B, Ctx.bv_val(1, 1), Ctx.bv_val(0, 1));
    }
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      auto C = boolExpr(Sel->getCondition(), Depth + 1);
      auto T = intExpr(Sel->getTrueValue(), Depth + 1);
      auto F = intExpr(Sel->getFalseValue(), Depth + 1);
      if (!C || !T || !F) return std::nullopt;
      auto TBW = intBitWidth(Sel->getTrueValue()->getType());
      auto FBW = intBitWidth(Sel->getFalseValue()->getType());
      if (!TBW || !FBW) return std::nullopt;
      return z3::ite(*C, resizeBV(*T, *TBW, *BW), resizeBV(*F, *FBW, *BW));
    }
    if (auto *Cast = dyn_cast<CastInst>(V)) {
      auto Inner = intExpr(Cast->getOperand(0), Depth + 1);
      auto FromBW = intBitWidth(Cast->getOperand(0)->getType());
      if (!Inner || !FromBW) return std::nullopt;
      return resizeBV(*Inner, *FromBW, *BW, isa<SExtInst>(Cast));
    }
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      auto L = intExpr(BO->getOperand(0), Depth + 1);
      auto R = intExpr(BO->getOperand(1), Depth + 1);
      auto LBW = intBitWidth(BO->getOperand(0)->getType());
      auto RBW = intBitWidth(BO->getOperand(1)->getType());
      if (!L || !R || !LBW || !RBW) return std::nullopt;
      z3::expr A = resizeBV(*L, *LBW, *BW);
      z3::expr B = resizeBV(*R, *RBW, *BW);
      switch (BO->getOpcode()) {
        case Instruction::Add: return A + B;
        case Instruction::Sub: return A - B;
        case Instruction::Mul: return A * B;
        case Instruction::And: return A & B;
        case Instruction::Or: return A | B;
        case Instruction::Xor: return A ^ B;
        case Instruction::Shl: return z3::shl(A, B);
        case Instruction::LShr: return z3::lshr(A, B);
        case Instruction::AShr: return z3::ashr(A, B);
        default: break;
      }
    }

    // Fallback: create a new free variable for this value
    z3::expr Var = Ctx.bv_const(("val_" + std::to_string(VarMap.size())).c_str(), *BW);
    VarMap.emplace(V, Var);
    return Var;
  }

  std::optional<z3::expr> boolExpr(Value *V, unsigned Depth = 0) {
    if (!V || Depth > 48) return std::nullopt;
    if (auto *CI = dyn_cast<ConstantInt>(V)) {
      if (CI->getType()->isIntegerTy(1)) return Ctx.bool_val(!CI->isZero());
    }
    if (auto *ICI = dyn_cast<ICmpInst>(V)) {
      auto L = intExpr(ICI->getOperand(0), Depth + 1);
      auto R = intExpr(ICI->getOperand(1), Depth + 1);
      auto LBW = intBitWidth(ICI->getOperand(0)->getType());
      auto RBW = intBitWidth(ICI->getOperand(1)->getType());
      if (!L || !R || !LBW || !RBW) return std::nullopt;
      unsigned BW = std::max(*LBW, *RBW);
      z3::expr A = resizeBV(*L, *LBW, BW);
      z3::expr B = resizeBV(*R, *RBW, BW);
      switch (ICI->getPredicate()) {
        case ICmpInst::ICMP_EQ: return A == B;
        case ICmpInst::ICMP_NE: return A != B;
        case ICmpInst::ICMP_UGT: return z3::ugt(A, B);
        case ICmpInst::ICMP_UGE: return z3::uge(A, B);
        case ICmpInst::ICMP_ULT: return z3::ult(A, B);
        case ICmpInst::ICMP_ULE: return z3::ule(A, B);
        case ICmpInst::ICMP_SGT: return z3::sgt(A, B);
        case ICmpInst::ICMP_SGE: return z3::sge(A, B);
        case ICmpInst::ICMP_SLT: return z3::slt(A, B);
        case ICmpInst::ICMP_SLE: return z3::sle(A, B);
        default: return std::nullopt;
      }
    }
    auto I = intExpr(V, Depth + 1);
    auto BW = intBitWidth(V->getType());
    if (!I || !BW || *BW != 1) return std::nullopt;
    return *I == Ctx.bv_val(1, 1);
  }
};

bool foldOpaqueBranches(Function &F) {
  const DataLayout &DL = F.getDataLayout();
  bool Changed = false;
  
  SmallVector<BranchInst *, 16> Branches;
  for (BasicBlock &BB : F) {
    if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator())) {
      if (BI->isConditional()) {
        Branches.push_back(BI);
      }
    }
  }
  
  for (BranchInst *BI : Branches) {
    if (!BI->getParent()) continue;
    
    z3::context Ctx;
    Ctx.set("timeout", static_cast<int>(kZ3TimeoutMs));
    
    Z3ExprTranslator Translator{Ctx, DL, nullptr, Ctx.bv_val(0, 32)};
    auto CondExpr = Translator.boolExpr(BI->getCondition());
    if (!CondExpr) continue;
    
    z3::solver SolverTrue(Ctx);
    SolverTrue.add(!*CondExpr);
    bool AlwaysTrue = (SolverTrue.check() == z3::unsat);
    
    z3::solver SolverFalse(Ctx);
    SolverFalse.add(*CondExpr);
    bool AlwaysFalse = (SolverFalse.check() == z3::unsat);
    
    if (AlwaysTrue || AlwaysFalse) {
      BasicBlock *BB = BI->getParent();
      BasicBlock *Taken = BI->getSuccessor(AlwaysTrue ? 0 : 1);
      BasicBlock *Dead = BI->getSuccessor(AlwaysTrue ? 1 : 0);
      
      BranchInst::Create(Taken, BB);
      BI->eraseFromParent();
      
      for (PHINode &PN : Dead->phis()) {
        while (true) {
          int Idx = PN.getBasicBlockIndex(BB);
          if (Idx < 0) break;
          PN.removeIncomingValue(static_cast<unsigned>(Idx), false);
        }
      }
      
      Changed = true;
    }
  }
  
  if (Changed) {
    bool Removed = true;
    while (Removed) {
      Removed = false;
      for (auto It = F.begin(); It != F.end();) {
        BasicBlock *BB = &*It++;
        if (BB == &F.getEntryBlock() || !pred_empty(BB)) continue;
        
        for (BasicBlock *Succ : successors(BB)) {
          for (PHINode &PN : Succ->phis()) {
            while (true) {
              int Idx = PN.getBasicBlockIndex(BB);
              if (Idx < 0) break;
              PN.removeIncomingValue(static_cast<unsigned>(Idx), false);
            }
          }
        }
        
        BB->dropAllReferences();
        BB->eraseFromParent();
        Removed = true;
      }
    }
  }
  
  return Changed;
}

SmallVector<ConstantInt *, 4> solveStateValuesForEncodedCondition(const DispatcherInfo &Info,
                                                                  ConstantInt *Encoded,
                                                                  const DataLayout &DL) {
  SmallVector<ConstantInt *, 4> Results;
  auto *StateTy = dyn_cast<IntegerType>(Info.state_phi->getType());
  auto *CondTy = dyn_cast<IntegerType>(Info.condition->getType());
  if (!StateTy || !CondTy || StateTy->getBitWidth() == 0 || StateTy->getBitWidth() > 64 ||
      CondTy->getBitWidth() == 0 || CondTy->getBitWidth() > 64) {
    return Results;
  }

  z3::context Ctx;
  Ctx.set("timeout", static_cast<int>(kZ3TimeoutMs));
  z3::expr State = Ctx.bv_const("state", StateTy->getBitWidth());
  Z3ExprTranslator Translator{Ctx, DL, Info.state_phi, State};
  auto EncExpr = Translator.intExpr(Info.condition);
  if (!EncExpr) return Results;

  z3::solver Solver(Ctx);
  Solver.add(resizeBV(*EncExpr, CondTy->getBitWidth(), Encoded->getBitWidth()) ==
             z3Const(Ctx, Encoded->getValue(), Encoded->getBitWidth()));

  constexpr unsigned kMaxSolutions = 8;
  while (Solver.check() == z3::sat) {
    z3::model Model = Solver.get_model();
    z3::expr Val = Model.eval(State, true);
    uint64_t Raw = 0;
    if (!Val.is_numeral() || !Val.is_numeral_u64(Raw)) return {};
    APInt StateVal(StateTy->getBitWidth(), Raw);
    Results.push_back(cast<ConstantInt>(ConstantInt::get(StateTy, StateVal)));
    if (Results.size() >= kMaxSolutions) return {};
    Solver.add(State != z3Const(Ctx, StateVal, StateTy->getBitWidth()));
  }
  return Results;
}

SmallVector<SolvedState, 8> stateValuesForKnownTarget(const DispatcherInfo &Info, BasicBlock *Target,
                                                      const DataLayout &DL) {
  SmallVector<SolvedState, 8> Results;
  auto *StateTy = dyn_cast<IntegerType>(Info.state_phi->getType());
  if (!Target || !StateTy || StateTy->getBitWidth() == 0 || StateTy->getBitWidth() > 64) return Results;

  DenseSet<int64_t> SeenStates;
  auto AddState = [&](ConstantInt *State) {
    if (!State) return;
    auto Resolved = targetForState(Info, State, DL);
    if (!Resolved || Resolved->target != Target) return;
    if (SeenStates.insert(State->getSExtValue()).second) {
      Results.push_back(SolvedState{State, EvalEnv()});
    }
  };

  for (const auto &[EncodedValue, TargetInfo] : Info.targets) {
    if (TargetInfo.target != Target) continue;

    if (!Info.sw) continue;
    auto *CondTy = dyn_cast<IntegerType>(Info.condition->getType());
    if (!CondTy || CondTy->getBitWidth() == 0 || CondTy->getBitWidth() > 64) continue;

    APInt EncodedBits(CondTy->getBitWidth(), static_cast<uint64_t>(EncodedValue), false, true);
    auto *Encoded = cast<ConstantInt>(ConstantInt::get(CondTy, EncodedBits));

    if (Info.condition == Info.state_phi) {
      AddState(cast<ConstantInt>(ConstantInt::get(StateTy, EncodedBits.zextOrTrunc(StateTy->getBitWidth()))));
      continue;
    }

    for (ConstantInt *State : solveStateValuesForEncodedCondition(Info, Encoded, DL)) AddState(State);
  }
  return Results;
}

unsigned blockOrder(const BasicBlock *BB) {
  if (!BB || !BB->getParent()) return ~0u;
  unsigned Index = 0;
  for (const BasicBlock &Cur : *BB->getParent()) {
    if (&Cur == BB) return Index;
    ++Index;
  }
  return ~0u;
}

bool blockLess(const BasicBlock *A, const BasicBlock *B) {
  unsigned AO = blockOrder(A);
  unsigned BO = blockOrder(B);
  if (AO != BO) return AO < BO;
  return A->getName() < B->getName();
}

PHINode *findStatePhi(Value *V, SmallPtrSetImpl<Value *> &Seen, unsigned Depth = 0) {
  if (!V || Depth > 16 || !Seen.insert(V).second) return nullptr;
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (PN->getType()->isIntegerTy()) return PN;
    return nullptr;
  }
  if (auto *I = dyn_cast<Instruction>(V)) {
    for (Value *Op : I->operands()) {
      if (auto *PN = findStatePhi(Op, Seen, Depth + 1)) return PN;
    }
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands()) {
      if (auto *PN = findStatePhi(Op, Seen, Depth + 1)) return PN;
    }
  }
  return nullptr;
}

PHINode *findStatePhi(Value *V) {
  SmallPtrSet<Value *, 16> Seen;
  return findStatePhi(V, Seen);
}

bool conditionUsesState(Value *V, PHINode *StatePhi, SmallPtrSetImpl<Value *> &Seen, unsigned Depth = 0) {
  if (!V || !StatePhi || Depth > 16 || !Seen.insert(V).second) return false;
  if (V == StatePhi) return true;
  if (auto *I = dyn_cast<Instruction>(V)) {
    for (Value *Op : I->operands())
      if (conditionUsesState(Op, StatePhi, Seen, Depth + 1)) return true;
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands())
      if (conditionUsesState(Op, StatePhi, Seen, Depth + 1)) return true;
  }
  return false;
}

bool conditionUsesState(Value *V, PHINode *StatePhi) {
  SmallPtrSet<Value *, 16> Seen;
  return conditionUsesState(V, StatePhi, Seen);
}

bool isEqualityWithState(Value *V, PHINode *StatePhi, bool &TrueIsCase) {
  auto *ICI = dyn_cast<ICmpInst>(V);
  if (!ICI) return false;
  if (ICI->getPredicate() == ICmpInst::ICMP_EQ) TrueIsCase = true;
  else if (ICI->getPredicate() == ICmpInst::ICMP_NE) TrueIsCase = false;
  else return false;
  return conditionUsesState(ICI, StatePhi) &&
         (isa<ConstantInt>(ICI->getOperand(0)) || isa<ConstantInt>(ICI->getOperand(1)));
}

int64_t freshTargetKey(const DenseMap<int64_t, DispatcherInfo::TargetInfo> &Targets) {
  int64_t Key = std::numeric_limits<int64_t>::min();
  while (Targets.count(Key)) ++Key;
  return Key;
}

void addSyntheticTarget(DenseMap<int64_t, DispatcherInfo::TargetInfo> &Targets,
                        BasicBlock *Target, BasicBlock *Pred) {
  if (!Target || !Pred) return;
  for (auto &[_, Existing] : Targets) {
    if (Existing.target == Target && Existing.dispatch_pred == Pred) return;
  }
  Targets[freshTargetKey(Targets)] = DispatcherInfo::TargetInfo{Target, Pred};
}

bool isPureHeaderBackedgeBlock(BasicBlock *BB, BasicBlock *Header) {
  if (!BB || !Header) return false;
  if (BB == Header) return true;
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  if (!BI || BI->isConditional() || BI->getSuccessor(0) != Header) return false;
  for (Instruction &I : *BB) {
    if (&I == BI) break;
    auto *PN = dyn_cast<PHINode>(&I);
    if (!PN || isProxyPhi(PN)) return false;
  }
  return true;
}

bool collectBranchTreeTargets(BasicBlock *BB, PHINode *StatePhi,
                              DenseMap<int64_t, DispatcherInfo::TargetInfo> &Targets,
                              DenseSet<BasicBlock *> &DispatchBlocks,
                              SmallPtrSetImpl<BasicBlock *> &Seen,
                              unsigned Depth = 0) {
  if (!BB || !StatePhi || Depth > 96) return false;
  auto FollowOrAddLeaf = [&](BasicBlock *Succ, BasicBlock *Pred, unsigned NextDepth) -> bool {
    if (Succ == StatePhi->getParent()) return true;
    auto *SuccBI = dyn_cast<BranchInst>(Succ->getTerminator());
    auto *SuccSW = dyn_cast<SwitchInst>(Succ->getTerminator());
    if (!SuccBI && !SuccSW) {
      addSyntheticTarget(Targets, Succ, Pred);
      return true;
    }
    if (SuccBI && SuccBI->isConditional() && !conditionUsesState(SuccBI->getCondition(), StatePhi)) {
      addSyntheticTarget(Targets, Succ, Pred);
      return true;
    }
    if (SuccSW && !conditionUsesState(SuccSW->getCondition(), StatePhi)) {
      addSyntheticTarget(Targets, Succ, Pred);
      return true;
    }
    return collectBranchTreeTargets(Succ, StatePhi, Targets, DispatchBlocks, Seen, NextDepth);
  };

  if (!Seen.insert(BB).second) return true;
  DispatchBlocks.insert(BB);
  if (auto *SW = dyn_cast<SwitchInst>(BB->getTerminator())) {
    if (!conditionUsesState(SW->getCondition(), StatePhi)) return false;
    BasicBlock *Header = StatePhi->getParent();
    for (auto &C : SW->cases())
      if (!isPureHeaderBackedgeBlock(C.getCaseSuccessor(), Header))
        addSyntheticTarget(Targets, C.getCaseSuccessor(), BB);
    if (!isPureHeaderBackedgeBlock(SW->getDefaultDest(), Header))
      addSyntheticTarget(Targets, SW->getDefaultDest(), BB);
    return true;
  }

  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  if (!BI) return false;
  if (BI->isUnconditional()) {
    return FollowOrAddLeaf(BI->getSuccessor(0), BB, Depth + 1);
  }

  Value *Cond = BI->getCondition();
  if (!conditionUsesState(Cond, StatePhi)) return false;
  bool TrueIsCase = false;
  if (isEqualityWithState(Cond, StatePhi, TrueIsCase)) {
    BasicBlock *CaseSucc = BI->getSuccessor(TrueIsCase ? 0 : 1);
    BasicBlock *OtherSucc = BI->getSuccessor(TrueIsCase ? 1 : 0);
    if (!isPureHeaderBackedgeBlock(CaseSucc, StatePhi->getParent())) addSyntheticTarget(Targets, CaseSucc, BB);
    return FollowOrAddLeaf(OtherSucc, BB, Depth + 1);
  }

  return FollowOrAddLeaf(BI->getSuccessor(0), BB, Depth + 1) &&
         FollowOrAddLeaf(BI->getSuccessor(1), BB, Depth + 1);
}

std::optional<DispatcherInfo> identifyBranchDispatcher(BasicBlock *BB) {
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  if (!BI || !BI->isConditional()) return std::nullopt;
  PHINode *StatePhi = findStatePhi(BI->getCondition());
  if (!StatePhi) return std::nullopt;

  DenseMap<int64_t, DispatcherInfo::TargetInfo> TargetMap;
  DenseSet<BasicBlock *> DispatchBlocks;
  SmallPtrSet<BasicBlock *, 32> Seen;
  if (!collectBranchTreeTargets(BB, StatePhi, TargetMap, DispatchBlocks, Seen)) return std::nullopt;
  if (TargetMap.size() < 3) return std::nullopt;

  for (auto &[_, Target] : TargetMap) {
    if (!Target.target) return std::nullopt;
    for (Instruction &I : *Target.target) {
      if (isa<PHINode>(&I)) continue;
      for (Value *Op : I.operands()) {
        auto *Def = dyn_cast<Instruction>(Op);
        if (Def && DispatchBlocks.count(Def->getParent())) return std::nullopt;
      }
    }
  }

  unsigned BackEdges = 0;
  for (unsigned I = 0; I < StatePhi->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBB = StatePhi->getIncomingBlock(I);
    if (!IncomingBB) continue;
    if (!DispatchBlocks.count(IncomingBB)) ++BackEdges;
  }
  if (BackEdges == 0) return std::nullopt;

  DispatcherInfo Info;
  Info.block = StatePhi->getParent();
  Info.sw = nullptr;
  Info.condition = BI->getCondition();
  Info.state_phi = StatePhi;
  for (Instruction &I : *Info.block) {
    auto *PN = dyn_cast<PHINode>(&I);
    if (!PN) break;
    Info.phis.push_back(PN);
  }
  Info.targets = std::move(TargetMap);
  return Info;
}

std::optional<DispatcherInfo> identifyDispatcher(BasicBlock *BB) {
  auto *SW = dyn_cast<SwitchInst>(BB->getTerminator());
  if (!SW || SW->getNumCases() < 2) return identifyBranchDispatcher(BB);
  auto *StatePhi = dyn_cast<PHINode>(SW->getCondition());
  if (!StatePhi) StatePhi = findStatePhi(SW->getCondition());
  if (!StatePhi) return std::nullopt;
  BasicBlock *Header = StatePhi->getParent();
  if (!Header || Header->getParent() != BB->getParent()) return std::nullopt;

  DenseSet<BasicBlock *> Succs;
  DenseMap<int64_t, DispatcherInfo::TargetInfo> TargetMap;
  for (BasicBlock &Other : *BB->getParent()) {
    auto *OtherSW = dyn_cast<SwitchInst>(Other.getTerminator());
    if (!OtherSW || OtherSW->getCondition() != SW->getCondition()) continue;
    for (auto &C : OtherSW->cases()) {
      TargetMap[C.getCaseValue()->getSExtValue()] = DispatcherInfo::TargetInfo{C.getCaseSuccessor(), &Other};
      Succs.insert(C.getCaseSuccessor());
    }
    Succs.insert(OtherSW->getDefaultDest());
  }

  DenseMap<int64_t, DispatcherInfo::TargetInfo> BranchTreeTargets;
  DenseSet<BasicBlock *> DispatchBlocks;
  SmallPtrSet<BasicBlock *, 32> Seen;
  if (collectBranchTreeTargets(Header, StatePhi, BranchTreeTargets, DispatchBlocks, Seen)) {
    for (auto &[_, Target] : BranchTreeTargets) {
      if (!Target.target) continue;
      bool Exists = false;
      for (auto &[__, Existing] : TargetMap) {
        if (Existing.target == Target.target && Existing.dispatch_pred == Target.dispatch_pred) {
          Exists = true;
          break;
        }
      }
      if (!Exists) addSyntheticTarget(TargetMap, Target.target, Target.dispatch_pred);
      Succs.insert(Target.target);
    }
  }

  if (TargetMap.empty()) return std::nullopt;
  unsigned BackEdges = 0;
  for (unsigned I = 0; I < StatePhi->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBB = StatePhi->getIncomingBlock(I);
    if (Succs.count(IncomingBB)) {
      ++BackEdges;
      continue;
    }
    auto *IncomingBr = dyn_cast<BranchInst>(IncomingBB->getTerminator());
    if (!IncomingBr || IncomingBr->isConditional() || IncomingBr->getSuccessor(0) != Header) continue;
    for (BasicBlock *Pred : predecessors(IncomingBB)) {
      if (Succs.count(Pred)) {
        ++BackEdges;
        break;
      }
    }
  }
  if (BackEdges == 0) return std::nullopt;
  if (StatePhi->getNumIncomingValues() > 2 && BackEdges * 2 <= StatePhi->getNumIncomingValues()) {
    return std::nullopt;
  }

  DispatcherInfo Info;
  Info.block = Header;
  Info.sw = SW;
  Info.condition = SW->getCondition();
  Info.state_phi = StatePhi;
  for (Instruction &I : *Header) {
    auto *PN = dyn_cast<PHINode>(&I);
    if (!PN) break;
    Info.phis.push_back(PN);
  }
  for (BasicBlock *Pred : predecessors(Header)) {
    auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!Br || Br->isConditional() || Br->getSuccessor(0) != Header) continue;
    if (DispatchBlocks.count(Pred)) continue;
    for (Instruction &I : *Pred) {
      auto *PN = dyn_cast<PHINode>(&I);
      if (!PN) break;
      if (llvm::is_contained(Info.phis, PN)) continue;
      Info.phis.push_back(PN);
    }
  }
  Info.targets = std::move(TargetMap);
  return Info;
}

bool reachesBlock(BasicBlock *From, BasicBlock *To, unsigned MaxDepth = 128) {
  if (From == To) return true;
  SmallVector<BasicBlock *, 16> Worklist;
  SmallPtrSet<BasicBlock *, 16> Visited;
  Worklist.push_back(From);
  Visited.insert(From);

  unsigned Count = 0;
  while (!Worklist.empty() && Count++ < MaxDepth) {
    BasicBlock *Curr = Worklist.pop_back_val();
    if (Curr == To) return true;
    for (BasicBlock *Succ : successors(Curr)) {
      if (Visited.insert(Succ).second) {
        Worklist.push_back(Succ);
      }
    }
  }
  return false;
}

std::optional<DispatcherInfo::TargetInfo> targetFor(const DispatcherInfo &Info, ConstantInt *State) {
  auto It = Info.targets.find(State->getSExtValue());
  if (It != Info.targets.end()) return It->second;
  if (Info.sw && Info.sw->getParent() == Info.block) {
    BasicBlock *DefaultDest = Info.sw->getDefaultDest();
    if (DefaultDest && !reachesBlock(DefaultDest, Info.block)) {
      return DispatcherInfo::TargetInfo{DefaultDest, Info.sw->getParent()};
    }
  }
  return std::nullopt;
}

Value *incomingValueForSource(PHINode *PN, BasicBlock *Src);

bool isKnownDispatchTarget(const DispatcherInfo &Info, BasicBlock *BB) {
  if (!BB) return false;
  for (auto &[_, Target] : Info.targets)
    if (Target.target == BB) return true;
  return false;
}

bool instructionUsesDispatcherPhi(Instruction &I, const DispatcherInfo &Info) {
  if (isa<PHINode>(&I)) return false;
  for (Value *Op : I.operands()) {
    auto *PN = dyn_cast<PHINode>(Op);
    if (!PN) continue;
    for (PHINode *DP : Info.phis)
      if (PN == DP) return true;
  }
  return false;
}

bool blockBodyUsesDispatcherPhi(BasicBlock *BB, const DispatcherInfo &Info) {
  if (!BB) return false;
  for (Instruction &I : *BB)
    if (instructionUsesDispatcherPhi(I, Info)) return true;
  return false;
}

bool successorChainUsesDispatcherPhi(BasicBlock *Target, const DispatcherInfo &Info) {
  SmallPtrSet<BasicBlock *, 8> Seen;
  BasicBlock *BB = Target;
  for (unsigned Depth = 0; BB && Depth < 8 && Seen.insert(BB).second; ++Depth) {
    auto *Br = dyn_cast<BranchInst>(BB->getTerminator());
    if (!Br || Br->isConditional()) return false;
    BasicBlock *Succ = Br->getSuccessor(0);
    if (!Succ || Succ == Info.block) return false;
    if (blockBodyUsesDispatcherPhi(Succ, Info)) return true;
    BB = Succ;
  }
  return false;
}

ConstantInt *dispatchConditionForState(const DispatcherInfo &Info, ConstantInt *State,
                                       const DataLayout &DL, const EvalEnv &InitialEnv = EvalEnv()) {
  if (!Info.sw) return nullptr;
  auto *CondTy = dyn_cast<IntegerType>(Info.sw->getCondition()->getType());
  auto *StateTy = dyn_cast<IntegerType>(Info.state_phi->getType());
  if (!CondTy || !StateTy) return nullptr;
  EvalEnv Env = InitialEnv;
  Env[Info.state_phi] = State->getValue().zextOrTrunc(StateTy->getBitWidth());
  return evalState(Info.condition, CondTy, DL, Env);
}

ConstantInt *nextStateFromDispatchBackedge(const DispatcherInfo &Info, BasicBlock *From,
                                           BasicBlock *Succ, const DataLayout &DL,
                                           EvalEnv &Env) {
  if (!From || !Succ || !Info.state_phi) return nullptr;
  bool ReachesHeader = Succ == Info.block;
  if (!ReachesHeader) {
    auto *Br = dyn_cast<BranchInst>(Succ->getTerminator());
    ReachesHeader = Br && !Br->isConditional() && Br->getSuccessor(0) == Info.block;
  }
  if (!ReachesHeader) return nullptr;

  Value *Next = incomingValueForSource(Info.state_phi, From);
  if (!Next) return nullptr;
  auto *Ty = dyn_cast<IntegerType>(Info.state_phi->getType());
  if (!Ty) return nullptr;
  return evalState(Next, Ty, DL, Env);
}

std::optional<DispatcherInfo::TargetInfo> targetForState(const DispatcherInfo &Info, ConstantInt *State,
                                                         const DataLayout &DL, const EvalEnv &InitialEnv) {
  auto *StateTy = dyn_cast<IntegerType>(Info.state_phi->getType());
  if (!StateTy) return std::nullopt;
  ConstantInt *Cond = Info.sw ? dispatchConditionForState(Info, State, DL, InitialEnv) : nullptr;
  if (Info.sw && !Cond) return std::nullopt;

  ConstantInt *CurState = State;
  DenseSet<int64_t> SeenStates;
  for (unsigned StateDepth = 0; CurState && StateDepth < 32; ++StateDepth) {
    if (!SeenStates.insert(CurState->getSExtValue()).second) return std::nullopt;
    EvalEnv Env = InitialEnv;
    Env[Info.state_phi] = CurState->getValue().zextOrTrunc(StateTy->getBitWidth());

    BasicBlock *BB = Info.block;
    SmallPtrSet<BasicBlock *, 16> SeenBlocks;
    bool Restarted = false;
    DenseMap<BasicBlock *, BasicBlock *> PathPreds;
    PathPredsScope Scope(&PathPreds);
    for (unsigned Depth = 0; BB && Depth < 32 && SeenBlocks.insert(BB).second; ++Depth) {
      auto Follow = [&](BasicBlock *Succ, BasicBlock *From) -> std::optional<DispatcherInfo::TargetInfo> {
        PathPreds[Succ] = From;
        if (isPureHeaderBackedgeBlock(Succ, Info.block)) {
          if (ConstantInt *NextState = nextStateFromDispatchBackedge(Info, From, Succ, DL, Env)) {
            CurState = NextState;
            Restarted = true;
            return std::nullopt;
          }
          if (Succ == Info.block) return std::nullopt;
        }
        if (isKnownDispatchTarget(Info, Succ)) return DispatcherInfo::TargetInfo{Succ, From};
        auto IsDispatchNode = [&](BasicBlock *Node) {
          if (!Node) return false;
          if (auto *NodeSW = dyn_cast<SwitchInst>(Node->getTerminator())) {
            return conditionUsesState(NodeSW->getCondition(), Info.state_phi);
          }
          auto *NodeBr = dyn_cast<BranchInst>(Node->getTerminator());
          return NodeBr && NodeBr->isConditional() && conditionUsesState(NodeBr->getCondition(), Info.state_phi);
        };
        if (Succ != Info.block && !IsDispatchNode(Succ)) return DispatcherInfo::TargetInfo{Succ, From};
        if (Info.sw && Succ == Info.sw->getDefaultDest() && !reachesBlock(Succ, Info.block)) return DispatcherInfo::TargetInfo{Succ, From};
        BB = Succ;
        return std::nullopt;
      };

      auto *Term = BB->getTerminator();
      if (auto *SW = dyn_cast<SwitchInst>(Term)) {
        auto CaseValue = evalState(SW->getCondition(), cast<IntegerType>(SW->getCondition()->getType()), DL, Env);
        if (!CaseValue) return std::nullopt;
        auto CaseIt = SW->findCaseValue(CaseValue);
        BasicBlock *Succ = CaseIt == SW->case_default() ? SW->getDefaultDest() : CaseIt->getCaseSuccessor();
        if (!Succ) return std::nullopt;
        if (auto Target = Follow(Succ, BB)) return Target;
        if (Restarted) break;
        continue;
      }
      auto *Br = dyn_cast<BranchInst>(Term);
      if (!Br) return std::nullopt;
      if (Br->isUnconditional()) {
        BasicBlock *Succ = Br->getSuccessor(0);
        if (auto Target = Follow(Succ, BB)) return Target;
        if (Restarted) break;
        continue;
      }
      auto CondValue = evalBool(Br->getCondition(), DL, Env);
      if (!CondValue) return std::nullopt;
      BasicBlock *Succ = Br->getSuccessor(*CondValue ? 0 : 1);
      if (auto Target = Follow(Succ, BB)) return Target;
      if (Restarted) break;
    }
    if (Restarted) continue;
    break;
  }

  return Cond ? targetFor(Info, Cond) : std::nullopt;
}

bool collectStateConstraintsForTarget(const DispatcherInfo &Info, BasicBlock *BB, BasicBlock *Target,
                                      z3::context &Ctx, const DataLayout &DL, const z3::expr &State,
                                      const z3::expr &Path,
                                      SmallVectorImpl<z3::expr> &Constraints,
                                      SmallPtrSetImpl<BasicBlock *> &Seen,
                                      Z3ExprTranslator &Translator,
                                      unsigned Depth = 0) {
  if (!BB || !Target || Depth > 128) return false;
  if (BB == Target) {
    Constraints.push_back(Path);
    return true;
  }
  if (!Seen.insert(BB).second) return true;

  auto TranslateBool = [&](Value *V) -> std::optional<z3::expr> {
    auto Expr = Translator.boolExpr(V);
    if (!Expr) {
      if (traceCFF()) {
        llvm::errs() << "[CFFTRACE] TranslateBool failed to translate: ";
        V->print(llvm::errs());
        llvm::errs() << "\n";
      }
      return std::nullopt;
    }
    return Expr;
  };
  auto TranslateInt = [&](Value *V) -> std::optional<z3::expr> {
    auto Expr = Translator.intExpr(V);
    if (!Expr) {
      if (traceCFF()) {
        llvm::errs() << "[CFFTRACE] TranslateInt failed to translate: ";
        V->print(llvm::errs());
        llvm::errs() << "\n";
      }
      return std::nullopt;
    }
    return Expr;
  };

  Instruction *Term = BB->getTerminator();
  if (auto *SW = dyn_cast<SwitchInst>(Term)) {
    if (!conditionUsesState(SW->getCondition(), Info.state_phi)) return true;
    auto CondExpr = TranslateInt(SW->getCondition());
    auto BW = intBitWidth(SW->getCondition()->getType());
    if (!CondExpr || !BW) return false;

    z3::expr DefaultPath = Path;
    bool Ok = true;
    for (auto &C : SW->cases()) {
      auto *Case = C.getCaseValue();
      z3::expr CaseEq = resizeBV(*CondExpr, *BW, Case->getBitWidth()) ==
                        z3Const(Ctx, Case->getValue(), Case->getBitWidth());
      SmallPtrSet<BasicBlock *, 32> CaseSeen(Seen.begin(), Seen.end());
      Ok &= collectStateConstraintsForTarget(Info, C.getCaseSuccessor(), Target, Ctx, DL, State,
                                             Path && CaseEq, Constraints, CaseSeen, Translator, Depth + 1);
      DefaultPath = DefaultPath && !CaseEq;
    }
    SmallPtrSet<BasicBlock *, 32> DefaultSeen(Seen.begin(), Seen.end());
    Ok &= collectStateConstraintsForTarget(Info, SW->getDefaultDest(), Target, Ctx, DL, State,
                                           DefaultPath, Constraints, DefaultSeen, Translator, Depth + 1);
    return Ok;
  }

  auto *BI = dyn_cast<BranchInst>(Term);
  if (!BI) return true;
  if (BI->isUnconditional()) {
    return collectStateConstraintsForTarget(Info, BI->getSuccessor(0), Target, Ctx, DL, State,
                                            Path, Constraints, Seen, Translator, Depth + 1);
  }
  if (!conditionUsesState(BI->getCondition(), Info.state_phi)) return true;
  auto CondExpr = TranslateBool(BI->getCondition());
  if (!CondExpr) return false;
  SmallPtrSet<BasicBlock *, 32> TrueSeen(Seen.begin(), Seen.end());
  SmallPtrSet<BasicBlock *, 32> FalseSeen(Seen.begin(), Seen.end());
  bool Ok = collectStateConstraintsForTarget(Info, BI->getSuccessor(0), Target, Ctx, DL, State,
                                             Path && *CondExpr, Constraints, TrueSeen, Translator, Depth + 1);
  Ok &= collectStateConstraintsForTarget(Info, BI->getSuccessor(1), Target, Ctx, DL, State,
                                         Path && !*CondExpr, Constraints, FalseSeen, Translator, Depth + 1);
  return Ok;
}

void collectRestrictedStateConstraints(const DispatcherInfo &Info, BasicBlock *BB, BasicBlock *Target,
                                       const SmallPtrSetImpl<BasicBlock *> &Reaching,
                                       z3::context &Ctx, const DataLayout &DL, const z3::expr &State,
                                       const z3::expr &Path,
                                       SmallVectorImpl<z3::expr> &Constraints,
                                       SmallPtrSetImpl<BasicBlock *> &Seen,
                                       Z3ExprTranslator &Translator,
                                       unsigned Depth = 0) {
  if (!BB || !Target || Depth > 128) return;
  if (BB == Target) {
    Constraints.push_back(Path);
    return;
  }
  if (!Seen.insert(BB).second) return;

  auto TranslateBool = [&](Value *V) -> std::optional<z3::expr> {
    return Translator.boolExpr(V);
  };
  auto TranslateInt = [&](Value *V) -> std::optional<z3::expr> {
    return Translator.intExpr(V);
  };

  Instruction *Term = BB->getTerminator();
  if (auto *SW = dyn_cast<SwitchInst>(Term)) {
    auto CondExpr = TranslateInt(SW->getCondition());
    auto BW = intBitWidth(SW->getCondition()->getType());
    if (!CondExpr || !BW) return;

    z3::expr DefaultPath = Path;
    for (auto &C : SW->cases()) {
      BasicBlock *Succ = C.getCaseSuccessor();
      if (!Reaching.count(Succ)) continue;
      auto *Case = C.getCaseValue();
      z3::expr CaseEq = resizeBV(*CondExpr, *BW, Case->getBitWidth()) ==
                        z3Const(Ctx, Case->getValue(), Case->getBitWidth());
      SmallPtrSet<BasicBlock *, 32> CaseSeen(Seen.begin(), Seen.end());
      collectRestrictedStateConstraints(Info, Succ, Target, Reaching, Ctx, DL, State,
                                        Path && CaseEq, Constraints, CaseSeen, Translator, Depth + 1);
      DefaultPath = DefaultPath && !CaseEq;
    }
    BasicBlock *DefaultSucc = SW->getDefaultDest();
    if (Reaching.count(DefaultSucc)) {
      SmallPtrSet<BasicBlock *, 32> DefaultSeen(Seen.begin(), Seen.end());
      collectRestrictedStateConstraints(Info, DefaultSucc, Target, Reaching, Ctx, DL, State,
                                        DefaultPath, Constraints, DefaultSeen, Translator, Depth + 1);
    }
    return;
  }

  auto *BI = dyn_cast<BranchInst>(Term);
  if (!BI) return;
  if (BI->isUnconditional()) {
    BasicBlock *Succ = BI->getSuccessor(0);
    if (Reaching.count(Succ)) {
      collectRestrictedStateConstraints(Info, Succ, Target, Reaching, Ctx, DL, State,
                                        Path, Constraints, Seen, Translator, Depth + 1);
    }
    return;
  }

  auto CondExpr = TranslateBool(BI->getCondition());
  BasicBlock *TrueSucc = BI->getSuccessor(0);
  BasicBlock *FalseSucc = BI->getSuccessor(1);

  if (CondExpr) {
    if (Reaching.count(TrueSucc)) {
      SmallPtrSet<BasicBlock *, 32> TrueSeen(Seen.begin(), Seen.end());
      collectRestrictedStateConstraints(Info, TrueSucc, Target, Reaching, Ctx, DL, State,
                                         Path && *CondExpr, Constraints, TrueSeen, Translator, Depth + 1);
    }
    if (Reaching.count(FalseSucc)) {
      SmallPtrSet<BasicBlock *, 32> FalseSeen(Seen.begin(), Seen.end());
      collectRestrictedStateConstraints(Info, FalseSucc, Target, Reaching, Ctx, DL, State,
                                         Path && !*CondExpr, Constraints, FalseSeen, Translator, Depth + 1);
    }
  } else {
    if (Reaching.count(TrueSucc)) {
      SmallPtrSet<BasicBlock *, 32> TrueSeen(Seen.begin(), Seen.end());
      collectRestrictedStateConstraints(Info, TrueSucc, Target, Reaching, Ctx, DL, State,
                                         Path, Constraints, TrueSeen, Translator, Depth + 1);
    }
    if (Reaching.count(FalseSucc)) {
      SmallPtrSet<BasicBlock *, 32> FalseSeen(Seen.begin(), Seen.end());
      collectRestrictedStateConstraints(Info, FalseSucc, Target, Reaching, Ctx, DL, State,
                                         Path, Constraints, FalseSeen, Translator, Depth + 1);
    }
  }
}

SmallVector<SolvedState, 8> solveStateValuesForTarget(const DispatcherInfo &Info, BasicBlock *Target,
                                                      const DataLayout &DL) {
  SmallVector<SolvedState, 8> Results;
  auto *StateTy = dyn_cast<IntegerType>(Info.state_phi->getType());
  if (!Target || !StateTy || StateTy->getBitWidth() == 0 || StateTy->getBitWidth() > 64) return Results;

  SmallPtrSet<BasicBlock *, 32> Reaching;
  {
    SmallVector<BasicBlock *, 32> Worklist;
    Worklist.push_back(Target);
    Reaching.insert(Target);
    while (!Worklist.empty()) {
      BasicBlock *BB = Worklist.pop_back_val();
      for (BasicBlock *Pred : predecessors(BB)) {
        if (Pred == Info.block) continue;
        if (Reaching.insert(Pred).second) {
          Worklist.push_back(Pred);
        }
      }
    }
  }

  if (traceCFF()) {
    llvm::errs() << "[CFFTRACE] solveStateValuesForTarget: Target=" << blockOrder(Target)
                 << " Reaching size=" << Reaching.size() << " blocks: ";
    for (BasicBlock *BB : Reaching) llvm::errs() << blockOrder(BB) << " ";
    llvm::errs() << "\n";
  }

  z3::context Ctx;
  Ctx.set("timeout", static_cast<int>(kZ3TimeoutMs));
  z3::expr State = Ctx.bv_const("state", StateTy->getBitWidth());
  Z3ExprTranslator Translator{Ctx, DL, Info.state_phi, State};
  SmallVector<z3::expr, 16> Constraints;
  SmallPtrSet<BasicBlock *, 32> Seen;

  collectRestrictedStateConstraints(Info, Info.block, Target, Reaching, Ctx, DL, State, Ctx.bool_val(true),
                                    Constraints, Seen, Translator);

  if (traceCFF()) {
    llvm::errs() << "[CFFTRACE] solveStateValuesForTarget: Constraints size=" << Constraints.size() << "\n";
  }

  if (Constraints.empty()) return Results;

  DenseSet<int64_t> SeenValues;
  constexpr unsigned kMaxTargetStateSolutions = 64;
  for (const z3::expr &Constraint : Constraints) {
    z3::solver Solver(Ctx);
    Solver.add(Constraint);
    unsigned Iterations = 0;
    while (Solver.check() == z3::sat) {
      if (++Iterations > 16) break;
      z3::model Model = Solver.get_model();
      z3::expr Val = Model.eval(State, true);
      uint64_t Raw = 0;
      if (!Val.is_numeral() || !Val.is_numeral_u64(Raw)) return {};
      APInt StateVal(StateTy->getBitWidth(), Raw);
      auto *CI = cast<ConstantInt>(ConstantInt::get(StateTy, StateVal));

      if (traceCFF()) {
        llvm::errs() << "[CFFTRACE] solveStateValuesForTarget: Z3 found state=" << CI->getSExtValue() << "\n";
      }

      EvalEnv Env;
      Env[Info.state_phi] = StateVal;
      for (const auto &[V, Expr] : Translator.VarMap) {
        z3::expr ModelVal = Model.eval(Expr, true);
        uint64_t RawVal = 0;
        if (ModelVal.is_numeral() && ModelVal.is_numeral_u64(RawVal)) {
          auto BW = intBitWidth(V->getType());
          if (BW) {
            Env[V] = APInt(*BW, RawVal);
          }
        }
      }

      auto Resolved = targetForState(Info, CI, DL, Env);
      if (Resolved && Resolved->target == Target && SeenValues.insert(CI->getSExtValue()).second) {
        if (traceCFF()) {
          llvm::errs() << "[CFFTRACE] solveStateValuesForTarget: State matched target! Adding SolvedState.\n";
        }
        Results.push_back(SolvedState{CI, std::move(Env)});
        if (Results.size() > kMaxTargetStateSolutions) return {};
      } else {
        if (traceCFF()) {
          if (!Resolved) {
            llvm::errs() << "[CFFTRACE] solveStateValuesForTarget: targetForState returned nullopt\n";
          } else {
            llvm::errs() << "[CFFTRACE] solveStateValuesForTarget: targetForState target="
                         << blockOrder(Resolved->target) << " expected=" << blockOrder(Target) << "\n";
          }
        }
      }
      Solver.add(State != z3Const(Ctx, StateVal, StateTy->getBitWidth()));
    }
  }
  return Results;
}

Value *incomingValueForSource(PHINode *PN, BasicBlock *Src) {
  if (!PN || !Src) return nullptr;
  if (PN->getParent() == Src) return nullptr;
  int DirectIdx = PN->getBasicBlockIndex(Src);
  if (DirectIdx >= 0) return PN->getIncomingValue(static_cast<unsigned>(DirectIdx));

  for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
    auto *Latch = PN->getIncomingBlock(I);
    auto *LatchPhi = dyn_cast<PHINode>(PN->getIncomingValue(I));
    if (!Latch || !LatchPhi || LatchPhi->getParent() != Latch) continue;
    int LatchIdx = LatchPhi->getBasicBlockIndex(Src);
    if (LatchIdx >= 0) return LatchPhi->getIncomingValue(static_cast<unsigned>(LatchIdx));
  }

  auto ReachesByUncondChain = [](BasicBlock *From, BasicBlock *To) -> bool {
    SmallPtrSet<BasicBlock *, 8> Seen;
    BasicBlock *Cur = From;
    for (unsigned Depth = 0; Cur && Depth < 6 && Seen.insert(Cur).second; ++Depth) {
      if (Cur == To) return true;
      auto *BI = dyn_cast<BranchInst>(Cur->getTerminator());
      if (!BI || BI->isConditional()) return false;
      Cur = BI->getSuccessor(0);
    }
    return false;
  };

  for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBB = PN->getIncomingBlock(I);
    if (IncomingBB && ReachesByUncondChain(Src, IncomingBB)) {
      return PN->getIncomingValue(I);
    }
  }
  return nullptr;
}

struct StateChoice {
  Value *condition = nullptr;
  bool when_true = true;
  APInt value;
};

bool mergeChoiceCondition(const StateChoice &A, const StateChoice &B, Value *&Cond, bool &WhenTrue) {
  if (!A.condition && !B.condition) {
    Cond = nullptr;
    WhenTrue = true;
    return true;
  }
  if (!A.condition) {
    Cond = B.condition;
    WhenTrue = B.when_true;
    return true;
  }
  if (!B.condition) {
    Cond = A.condition;
    WhenTrue = A.when_true;
    return true;
  }
  if (A.condition != B.condition || A.when_true != B.when_true) return false;
  Cond = A.condition;
  WhenTrue = A.when_true;
  return true;
}

SmallVector<StateChoice, 4> enumerateStateChoices(Value *V, BasicBlock *Src, IntegerType *Ty,
                                                  const DataLayout &DL,
                                                  SmallPtrSetImpl<Value *> &Seen,
                                                  unsigned Depth = 0) {
  SmallVector<StateChoice, 4> Out;
  if (!V || !Ty || Depth > 24) return Out;
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    Out.push_back(StateChoice{nullptr, true, CI->getValue().zextOrTrunc(Ty->getBitWidth())});
    return Out;
  }
  if (!Seen.insert(V).second) return Out;
  if (auto *Fr = dyn_cast<FreezeInst>(V)) return enumerateStateChoices(Fr->getOperand(0), Src, Ty, DL, Seen, Depth + 1);
  if (auto *PN = dyn_cast<PHINode>(V)) {
    return enumerateStateChoices(incomingValueForSource(PN, Src), Src, Ty, DL, Seen, Depth + 1);
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    SmallPtrSet<Value *, 16> TrueSeen(Seen.begin(), Seen.end());
    auto T = enumerateStateChoices(Sel->getTrueValue(), Src, Ty, DL, TrueSeen, Depth + 1);
    for (StateChoice C : T) {
      if (C.condition && C.condition != Sel->getCondition()) return {};
      C.condition = Sel->getCondition();
      C.when_true = true;
      Out.push_back(C);
    }
    SmallPtrSet<Value *, 16> FalseSeen(Seen.begin(), Seen.end());
    auto F = enumerateStateChoices(Sel->getFalseValue(), Src, Ty, DL, FalseSeen, Depth + 1);
    for (StateChoice C : F) {
      if (C.condition && C.condition != Sel->getCondition()) return {};
      C.condition = Sel->getCondition();
      C.when_true = false;
      Out.push_back(C);
    }
    return Out;
  }
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    auto Choices = enumerateStateChoices(Cast->getOperand(0), Src, Ty, DL, Seen, Depth + 1);
    for (StateChoice &C : Choices) C.value = C.value.zextOrTrunc(Ty->getBitWidth());
    return Choices;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO) return Out;
  SmallPtrSet<Value *, 16> LeftSeen(Seen.begin(), Seen.end());
  SmallPtrSet<Value *, 16> RightSeen(Seen.begin(), Seen.end());
  auto Ls = enumerateStateChoices(BO->getOperand(0), Src, Ty, DL, LeftSeen, Depth + 1);
  auto Rs = enumerateStateChoices(BO->getOperand(1), Src, Ty, DL, RightSeen, Depth + 1);
  if (Ls.empty() || Rs.empty() || Ls.size() * Rs.size() > 4) return Out;
  for (const StateChoice &L : Ls) {
    for (const StateChoice &R : Rs) {
      Value *Cond = nullptr;
      bool WhenTrue = true;
      if (!mergeChoiceCondition(L, R, Cond, WhenTrue)) return {};
      APInt A = L.value.zextOrTrunc(Ty->getBitWidth());
      APInt B = R.value.zextOrTrunc(Ty->getBitWidth());
      APInt V(Ty->getBitWidth(), 0);
      switch (BO->getOpcode()) {
        case Instruction::Add: V = A + B; break;
        case Instruction::Sub: V = A - B; break;
        case Instruction::Mul: V = A * B; break;
        case Instruction::And: V = A & B; break;
        case Instruction::Or: V = A | B; break;
        case Instruction::Xor: V = A ^ B; break;
        case Instruction::Shl: V = A.shl(B.getLimitedValue(Ty->getBitWidth())); break;
        case Instruction::LShr: V = A.lshr(B.getLimitedValue(Ty->getBitWidth())); break;
        case Instruction::AShr: V = A.ashr(B.getLimitedValue(Ty->getBitWidth())); break;
        default: return {};
      }
      Out.push_back(StateChoice{Cond, WhenTrue, V});
    }
  }
  return Out;
}

SmallVector<StateChoice, 4> enumerateStateChoices(Value *V, BasicBlock *Src, IntegerType *Ty,
                                                  const DataLayout &DL) {
  SmallPtrSet<Value *, 16> Seen;
  return enumerateStateChoices(V, Src, Ty, DL, Seen);
}

Value *currentPhiValueForSource(PHINode *PN, BasicBlock *Src) {
  if (!PN || !Src) return nullptr;
  if (auto *Proxy = proxyPhiForOriginal(PN, Src)) return Proxy;
  return incomingValueForSource(PN, Src);
}

Value *nextPhiValueForSource(PHINode *PN, BasicBlock *Src, bool RequireMaterializedHeaderPhi = false) {
  if (!PN || !Src) return nullptr;
  Value *V = incomingValueForSource(PN, Src);
  auto *HeaderPhi = dyn_cast_or_null<PHINode>(V);
  if (HeaderPhi && HeaderPhi->getParent() == PN->getParent()) {
    if (auto *Proxy = proxyPhiForOriginal(HeaderPhi, Src)) return Proxy;
    if (RequireMaterializedHeaderPhi) return nullptr;
    if (Value *Current = currentPhiValueForSource(HeaderPhi, Src)) return Current;
  }
  return V;
}

BasicBlock *oldSuccessorForSource(BasicBlock *Src, const DispatcherInfo &Info) {
  auto *Br = dyn_cast<BranchInst>(Src->getTerminator());
  if (!Br || Br->isConditional()) return nullptr;
  BasicBlock *Succ = Br->getSuccessor(0);
  if (Succ == Info.block) return Succ;

  auto *SuccBr = dyn_cast<BranchInst>(Succ->getTerminator());
  if (!SuccBr || SuccBr->isConditional() || SuccBr->getSuccessor(0) != Info.block) return nullptr;
  if (!incomingValueForSource(Info.state_phi, Src)) return nullptr;
  return Succ;
}

std::optional<Redirect> analyzeBackEdge(BasicBlock *Src, const DispatcherInfo &Info,
                                        const DataLayout &DL, StateSolveCache &SolveCache) {
  auto *Br = dyn_cast<BranchInst>(Src->getTerminator());
  if (!Br || Br->isConditional()) return std::nullopt;
  BasicBlock *OldSuccessor = oldSuccessorForSource(Src, Info);
  if (!OldSuccessor) return std::nullopt;
  if (isPureHeaderBackedgeBlock(Src, Info.block)) return std::nullopt;
  auto *Ty = cast<IntegerType>(Info.state_phi->getType());
  Value *Next = incomingValueForSource(Info.state_phi, Src);
  if (!Next) return std::nullopt;
  if (auto *CI = evalState(Next, Ty, DL)) {
    auto Target = targetForState(Info, CI, DL);
    if (!Target || Target->target == Src || Target->target == Info.block) return std::nullopt;
    return Redirect{Src, OldSuccessor, Target->target, Target->dispatch_pred, nullptr, nullptr, nullptr};
  }

  auto Choices = enumerateStateChoices(Next, Src, Ty, DL);
  if (Choices.size() == 1 && !Choices.front().condition) {
    auto *State = cast<ConstantInt>(ConstantInt::get(Ty, Choices.front().value));
    auto Target = targetForState(Info, State, DL);
    if (!Target || Target->target == Src || Target->target == Info.block) return std::nullopt;
    return Redirect{Src, OldSuccessor, Target->target, Target->dispatch_pred, nullptr, nullptr, nullptr};
  }
  if (Choices.size() == 2 && Choices[0].condition && Choices[0].condition == Choices[1].condition &&
      Choices[0].when_true != Choices[1].when_true) {
    StateChoice TrueChoice = Choices[0].when_true ? Choices[0] : Choices[1];
    StateChoice FalseChoice = Choices[0].when_true ? Choices[1] : Choices[0];
    auto *TState = cast<ConstantInt>(ConstantInt::get(Ty, TrueChoice.value));
    auto *FState = cast<ConstantInt>(ConstantInt::get(Ty, FalseChoice.value));
    auto T = targetForState(Info, TState, DL);
    auto F = targetForState(Info, FState, DL);
    if (!T || !F || T->target == Info.block || F->target == Info.block) return std::nullopt;
    return Redirect{Src, OldSuccessor, T->target, T->dispatch_pred, Choices[0].condition, F->target, F->dispatch_pred};
  }

  Value *RawNext = Next;
  if (auto *Fr = dyn_cast<FreezeInst>(RawNext)) RawNext = Fr->getOperand(0);
  auto *Sel = dyn_cast<SelectInst>(RawNext);
  if (Sel) {
    auto *TState = evalState(Sel->getTrueValue(), Ty, DL);
    auto *FState = evalState(Sel->getFalseValue(), Ty, DL);
    if (TState && FState) {
      auto T = targetForState(Info, TState, DL);
      auto F = targetForState(Info, FState, DL);
      if (!T || !F || T->target == Info.block || F->target == Info.block) return std::nullopt;
      return Redirect{Src, OldSuccessor, T->target, T->dispatch_pred, Sel->getCondition(), F->target, F->dispatch_pred};
    }
  }

  std::optional<DispatcherInfo::TargetInfo> SolvedTarget;
  auto CacheIt = SolveCache.find(Src);
  if (CacheIt == SolveCache.end()) {
    auto States = stateValuesForKnownTarget(Info, Src, DL);
    if (States.empty()) {
      if (Info.targets.size() > 128) return std::nullopt;
      if (traceCFF()) llvm::errs() << "[CFFTRACE] solveStateValuesForTarget src " << blockOrder(Src) << "\n";
      States = solveStateValuesForTarget(Info, Src, DL);
    }
    CacheIt = SolveCache.try_emplace(Src, std::move(States)).first;
  }
  const auto &CurrentStates = CacheIt->second;
  if (CurrentStates.empty()) return std::nullopt;

  for (const SolvedState &SState : CurrentStates) {
    ConstantInt *CurrentState = SState.state;
    const EvalEnv &InitialEnv = SState.env;

    EvalEnv Env = InitialEnv;
    Env[Info.state_phi] = CurrentState->getValue().zextOrTrunc(Ty->getBitWidth());
    if (auto *StateProxy = proxyPhiForOriginal(Info.state_phi, Src)) {
      Env[StateProxy] = CurrentState->getValue().zextOrTrunc(Ty->getBitWidth());
    }
    auto *NextState = evalState(Next, Ty, DL, Env);
    if (!NextState) {
      if (traceCFF()) llvm::errs() << "[CFFTRACE] analyzeBackEdge: evalState returned nullptr\n";
      return std::nullopt;
    }
    auto Target = targetForState(Info, NextState, DL, Env);
    if (!Target) {
      if (traceCFF()) llvm::errs() << "[CFFTRACE] analyzeBackEdge: targetForState returned nullopt for NextState=" << NextState->getSExtValue() << "\n";
      return std::nullopt;
    }
    if (Target->target == Src || Target->target == Info.block) {
      if (traceCFF()) llvm::errs() << "[CFFTRACE] analyzeBackEdge: Target is Src or Info.block\n";
      return std::nullopt;
    }
    if (traceCFF()) {
      llvm::errs() << "[CFFTRACE] analyzeBackEdge: State " << CurrentState->getSExtValue()
                   << " -> NextState " << NextState->getSExtValue()
                   << " -> Target " << blockOrder(Target->target) << "\n";
    }
    if (!SolvedTarget) {
      SolvedTarget = *Target;
      continue;
    }
    if (SolvedTarget->target != Target->target || SolvedTarget->dispatch_pred != Target->dispatch_pred) {
      if (traceCFF()) {
        llvm::errs() << "[CFFTRACE] analyzeBackEdge: SolvedTarget mismatch: "
                     << blockOrder(SolvedTarget->target) << " vs " << blockOrder(Target->target) << "\n";
      }
      return std::nullopt;
    }
  }
  if (SolvedTarget) {
    return Redirect{Src, OldSuccessor, SolvedTarget->target, SolvedTarget->dispatch_pred, nullptr, nullptr, nullptr};
  }
  return std::nullopt;
}

bool blockHasNonPhiUseOf(Value *V, BasicBlock *BB) {
  if (!V || !BB) return false;
  for (User *U : V->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (I && I->getParent() == BB && !isa<PHINode>(I)) return true;
  }
  return false;
}

std::optional<Redirect> analyzeIncomingEdge(BasicBlock *Src, const DispatcherInfo &Info,
                                            const DataLayout &DL) {
  if (Info.phis.size() != 1 || Info.phis.front() != Info.state_phi) return std::nullopt;
  auto *Br = dyn_cast<BranchInst>(Src->getTerminator());
  if (!Br || Br->isConditional() || Br->getSuccessor(0) != Info.block) return std::nullopt;
  auto *Ty = dyn_cast<IntegerType>(Info.state_phi->getType());
  if (!Ty) return std::nullopt;

  Value *Incoming = incomingValueForSource(Info.state_phi, Src);
  if (!Incoming) return std::nullopt;
  auto *State = evalState(Incoming, Ty, DL);
  if (!State) return std::nullopt;

  auto Target = targetForState(Info, State, DL);
  if (!Target || Target->target == Src || Target->target == Info.block) return std::nullopt;
  if (blockHasNonPhiUseOf(Info.state_phi, Target->target)) return std::nullopt;
  return Redirect{Src, Info.block, Target->target, Target->dispatch_pred, nullptr, nullptr, nullptr};
}

bool valueAvailableOnEdge(Value *V, BasicBlock *From, DominatorTree &DT) {
  if (!V || !From) return false;
  auto *I = dyn_cast<Instruction>(V);
  if (!I) return true;
  BasicBlock *DefBB = I->getParent();
  if (!DefBB) return false;
  if (DefBB == From) return I != From->getTerminator();
  return DT.dominates(DefBB, From);
}

bool redirectKeepsSuccessor(const Redirect &R, BasicBlock *Succ) {
  if (!Succ) return false;
  if (R.true_target == Succ) return true;
  return R.condition && R.false_target == Succ;
}

bool redirectChangesCFG(const Redirect &R) {
  if (!R.old_successor || !R.true_target) return false;
  if (!R.condition) return R.true_target != R.old_successor;
  return R.true_target != R.old_successor || R.false_target != R.old_successor;
}

bool redirectTargetsBlock(const Redirect &R, BasicBlock *BB) {
  if (!BB) return false;
  return R.true_target == BB || (R.condition && R.false_target == BB);
}

void orderRedirectsByDependency(SmallVectorImpl<Redirect> &Redirects) {
  std::stable_sort(Redirects.begin(), Redirects.end(), [](const Redirect &A, const Redirect &B) {
    bool AFeedsB = redirectTargetsBlock(A, B.src);
    bool BFeedsA = redirectTargetsBlock(B, A.src);
    if (AFeedsB != BFeedsA) return AFeedsB;
    return blockLess(A.src, B.src);
  });
}

bool redirectNeedsMissingSourceProxy(const Redirect &R, const DispatcherInfo &Info) {
  for (PHINode *PN : Info.phis) {
    if (PN == Info.state_phi) continue;
    Value *V = incomingValueForSource(PN, R.src);
    auto *HeaderPhi = dyn_cast_or_null<PHINode>(V);
    if (!HeaderPhi || HeaderPhi->getParent() != Info.block) continue;
    if (!proxyPhiForOriginal(HeaderPhi, R.src)) return true;
  }
  return false;
}

bool sourceHasPendingIncomingRedirect(const Redirect &R, ArrayRef<Redirect> Redirects) {
  for (const Redirect &Other : Redirects) {
    if (&Other == &R) continue;
    if (redirectTargetsBlock(Other, R.src)) return true;
  }
  return false;
}

Value *targetPhiValueForNewEdge(PHINode *PN, const DispatcherInfo &Info,
                                BasicBlock *DispatchPred, BasicBlock *From) {
  if (!PN || !From) return nullptr;
  int Idx = DispatchPred ? PN->getBasicBlockIndex(DispatchPred) : -1;
  if (Idx < 0) return nullptr;
  Value *V = PN->getIncomingValue(static_cast<unsigned>(Idx));
  if (auto *DP = dyn_cast<PHINode>(V)) {
    if (DP->getParent() == Info.block) V = nextPhiValueForSource(DP, From);
  }
  if (!V || V->getType() != PN->getType()) return nullptr;
  return V;
}

bool targetPhisCanAcceptNewEdges(const DispatcherInfo &Info,
                                 const DenseMap<BasicBlock *, SmallVector<IncomingEdge, 4>> &NewEdges,
                                 DominatorTree &DT) {
  for (auto &[Target, Sources] : NewEdges) {
    for (Instruction &I : *Target) {
      auto *PN = dyn_cast<PHINode>(&I);
      if (!PN) break;
      if (isProxyPhi(PN)) continue;
      for (const IncomingEdge &E : Sources) {
        Value *V = targetPhiValueForNewEdge(PN, Info, E.dispatch_pred, E.from);
        if (!V || !valueAvailableOnEdge(V, E.from, DT)) return false;
      }
    }
  }
  return true;
}

bool isNonStateDispatcherPhi(Value *V, const DispatcherInfo &Info) {
  auto *PN = dyn_cast<PHINode>(V);
  if (!PN || PN == Info.state_phi) return false;
  for (PHINode *DP : Info.phis)
    if (PN == DP) return true;
  return false;
}

bool isDispatcherPhi(Value *V, const DispatcherInfo &Info) {
  auto *PN = dyn_cast<PHINode>(V);
  if (!PN) return false;
  for (PHINode *DP : Info.phis)
    if (PN == DP) return true;
  return false;
}

bool blockBodyUsesValue(BasicBlock *BB, Value *V) {
  if (!BB || !V) return false;
  for (Instruction &I : *BB) {
    if (isa<PHINode>(&I)) continue;
    for (Value *Op : I.operands())
      if (Op == V) return true;
  }
  return false;
}

bool targetNeedsProxyForPhi(PHINode *PN, BasicBlock *Target, const DispatcherInfo &Info) {
  if (!PN || !Target || PN->use_empty() || !isDispatcherPhi(PN, Info)) return false;
  return blockBodyUsesValue(Target, PN);
}

bool valueUsesUntrackedExternalPhi(Value *V, BasicBlock *Target, const DispatcherInfo &Info,
                                   SmallPtrSetImpl<Value *> &Seen, unsigned Depth = 0) {
  if (!V || !Target || Depth > 8 || !Seen.insert(V).second) return false;
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (PN->getParent() == Target) return false;
    if (PN == Info.state_phi) return false;
    if (isNonStateDispatcherPhi(PN, Info)) return false;
    return true;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getParent() == Target) return false;
  for (Value *Op : I->operands())
    if (valueUsesUntrackedExternalPhi(Op, Target, Info, Seen, Depth + 1)) return true;
  return false;
}

bool valueUsesUntrackedExternalPhi(Value *V, BasicBlock *Target, const DispatcherInfo &Info) {
  SmallPtrSet<Value *, 16> Seen;
  return valueUsesUntrackedExternalPhi(V, Target, Info, Seen);
}

bool targetBodyCanAcceptNewEdges(const DispatcherInfo &Info,
                                 const DenseMap<BasicBlock *, SmallVector<IncomingEdge, 4>> &NewEdges,
                                 DominatorTree &DT) {
  for (auto &[Target, Sources] : NewEdges) {
    for (const IncomingEdge &E : Sources) {
      SmallPtrSet<Instruction *, 32> LocalDefs;
      for (Instruction &I : *Target) {
        if (isa<PHINode>(&I)) continue;
        for (Value *Op : I.operands()) {
          if (isDispatcherPhi(Op, Info)) continue;
          auto *Def = dyn_cast<Instruction>(Op);
          if (!Def) continue;
          if (isa<PHINode>(Def) && Def->getParent() == Target) continue;
          if (Def->getParent() == Target) {
            if (!LocalDefs.contains(Def)) return false;
            continue;
          }
          if (!valueAvailableOnEdge(Op, E.from, DT)) return false;
        }
        LocalDefs.insert(&I);
      }
    }
  }
  return true;
}

bool applyRedirects(const DispatcherInfo &Info, ArrayRef<Redirect> Redirects, DominatorTree &DT) {
  if (Redirects.empty()) return false;
  trace("applyRedirects:start");
  DenseMap<BasicBlock *, SmallVector<IncomingEdge, 4>> NewEdges;
  SmallVector<const Redirect *, 16> ActiveRedirects;

  auto AddNewEdge = [&](const Redirect &R, BasicBlock *Target, BasicBlock *DispatchPred) -> bool {
    if (!Target || Target == R.old_successor) return true;
    if (successorChainUsesDispatcherPhi(Target, Info)) return false;
    IncomingEdge E;
    E.from = R.src;
    E.dispatch_pred = DispatchPred;
    for (PHINode *PN : Info.phis) {
      Value *Incoming = nextPhiValueForSource(PN, R.src);
      if (!Incoming || !valueAvailableOnEdge(Incoming, R.src, DT)) return false;
      E.values[PN] = Incoming;
    }
    NewEdges[Target].push_back(E);
    return true;
  };

  for (const Redirect &R : Redirects) {
    if (!redirectChangesCFG(R)) continue;
    if (R.condition && !valueAvailableOnEdge(R.condition, R.src, DT)) return false;
    if (!AddNewEdge(R, R.true_target, R.true_dispatch_pred)) return false;
    if (R.false_target && R.false_target != R.true_target)
      if (!AddNewEdge(R, R.false_target, R.false_dispatch_pred)) return false;
    ActiveRedirects.push_back(&R);
  }
  if (ActiveRedirects.empty()) return false;
  trace("applyRedirects:built_edges");

  for (auto &[Target, Sources] : NewEdges) {
    for (const IncomingEdge &E : Sources)
      for (PHINode *PN : Info.phis)
        if (!valueAvailableOnEdge(E.values.lookup(PN), E.from, DT)) return false;
    for (PHINode *DP : Info.phis) {
      if (!targetNeedsProxyForPhi(DP, Target, Info)) continue;
      for (BasicBlock *Pred : predecessors(Target))
        if (!valueAvailableOnEdge(DP, Pred, DT)) return false;
    }
  }
  trace("applyRedirects:availability_ok");
  if (!targetPhisCanAcceptNewEdges(Info, NewEdges, DT)) return false;
  trace("applyRedirects:target_phis_ok");
  if (!targetBodyCanAcceptNewEdges(Info, NewEdges, DT)) return false;
  trace("applyRedirects:target_body_ok");

  DenseMap<BasicBlock *, DenseMap<PHINode *, PHINode *>> Proxies;
  SmallVector<BasicBlock *, 8> Targets;
  for (auto &[Target, _] : NewEdges) Targets.push_back(Target);
  std::sort(Targets.begin(), Targets.end(), blockLess);

  for (BasicBlock *Target : Targets) {
    auto &Sources = NewEdges[Target];
    std::sort(Sources.begin(), Sources.end(), [](const IncomingEdge &A, const IncomingEdge &B) {
      if (A.from != B.from) return blockLess(A.from, B.from);
      return blockLess(A.dispatch_pred, B.dispatch_pred);
    });
    SmallPtrSet<BasicBlock *, 8> NewSourceSet;
    for (const IncomingEdge &E : Sources) NewSourceSet.insert(E.from);
    for (PHINode *DP : Info.phis) {
      if (!targetNeedsProxyForPhi(DP, Target, Info)) continue;
      auto *Proxy = proxyPhiForOriginal(DP, Target);
      if (!Proxy) {
        Proxy = PHINode::Create(DP->getType(), static_cast<unsigned>(Sources.size() + pred_size(Target)), DP->getName() + ".symunflat");
        Proxy->insertBefore(Target->begin());
        markProxyPhi(Proxy, DP);
        for (BasicBlock *Pred : predecessors(Target))
          if (!NewSourceSet.contains(Pred)) Proxy->addIncoming(DP, Pred);
      }
      Proxies[Target][DP] = Proxy;
    }
  }
  trace("applyRedirects:proxies_ok");

  for (BasicBlock *Target : Targets) {
    auto &Sources = NewEdges[Target];
    for (Instruction &I : *Target) {
      auto *PN = dyn_cast<PHINode>(&I);
      if (!PN) break;
      if (isProxyPhi(PN)) {
        PHINode *DP = nullptr;
        for (PHINode *Orig : Info.phis) {
          if (proxyMatchesOriginal(PN, Orig)) {
            DP = Orig;
            break;
          }
        }
        if (!DP) continue;
        for (const IncomingEdge &E : Sources) {
          PN->addIncoming(E.values.lookup(DP), E.from);
        }
      } else {
        for (const IncomingEdge &E : Sources) {
          Value *NewV = targetPhiValueForNewEdge(PN, Info, E.dispatch_pred, E.from);
          if (!NewV || !valueAvailableOnEdge(NewV, E.from, DT)) return false;
          PN->addIncoming(NewV, E.from);
        }
      }
    }
  }
  trace("applyRedirects:target_phis_added");

  for (BasicBlock *Target : Targets) {
    auto It = Proxies.find(Target);
    if (It == Proxies.end()) continue;
    auto &Map = It->second;
    for (Instruction &I : *Target) {
      if (isa<PHINode>(&I)) continue;
      for (PHINode *DP : Info.phis)
        if (auto *Proxy = Map.lookup(DP)) I.replaceUsesOfWith(DP, Proxy);
    }
  }
  trace("applyRedirects:proxy_uses_rewritten");

  for (const Redirect *RP : ActiveRedirects) {
    const Redirect &R = *RP;
    auto *Br = cast<BranchInst>(R.src->getTerminator());
    bool KeepsOldSuccessor = redirectKeepsSuccessor(R, R.old_successor);
    IRBuilder<> B(Br);
    if (R.condition && R.false_target && R.true_target != R.false_target) B.CreateCondBr(R.condition, R.true_target, R.false_target);
    else B.CreateBr(R.true_target);
    Br->eraseFromParent();
    if (R.old_successor && !KeepsOldSuccessor) {
      for (PHINode &PN : R.old_successor->phis()) {
        while (true) {
          int Idx = PN.getBasicBlockIndex(R.src);
          if (Idx < 0) break;
          PN.removeIncomingValue(static_cast<unsigned>(Idx), false);
        }
      }
    }
  }
  trace("applyRedirects:done");
  return true;
}

bool phiUsesStayInTargets(PHINode *PN, BasicBlock *Header, ArrayRef<BasicBlock *> Targets) {
  SmallPtrSet<BasicBlock *, 4> Allowed;
  Allowed.insert(Header);
  for (BasicBlock *Target : Targets)
    if (Target) Allowed.insert(Target);

  for (User *U : PN->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I) return false;
    if (!Allowed.contains(I->getParent())) return false;
  }
  return true;
}

bool isSafeToBypassBlock(BasicBlock *BB, const DispatcherInfo &Info) {
  if (!BB) return true;
  if (BB == Info.block) return true;

  for (const Instruction &I : *BB) {
    if (auto *BI = dyn_cast<BranchInst>(&I)) {
      if (BI->isConditional() || BI->getSuccessor(0) != Info.block) {
        return false;
      }
      continue;
    }
    if (auto *PN = dyn_cast<PHINode>(&I)) {
      if (PN == Info.state_phi || isProxyPhi(PN)) continue;
      return false;
    }
    if (isa<StoreInst>(&I)) {
      return false;
    }
    if (I.mayHaveSideEffects() || I.mayWriteToMemory() || I.mayReadFromMemory()) {
      return false;
    }
  }
  return true;
}

bool redirectIsPhiSafe(const Redirect &R, const DispatcherInfo &Info) {
  if (traceCFF()) {
    llvm::errs() << "[CFFTRACE] redirectIsPhiSafe for: " << R.src->getName()
                 << " -> " << (R.true_target ? R.true_target->getName() : "null") << "\n";
  }
  if (R.old_successor && !isSafeToBypassBlock(R.old_successor, Info)) {
    if (traceCFF()) {
      llvm::errs() << "[CFFTRACE] redirectIsPhiSafe: rejected because old_successor "
                   << R.old_successor->getName() << " is not safe to bypass\n";
    }
    return false;
  }
  SmallVector<BasicBlock *, 16> Targets;
  SmallPtrSet<BasicBlock *, 16> Seen;
  for (auto &[_, Target] : Info.targets) {
    if (Target.target && Seen.insert(Target.target).second) Targets.push_back(Target.target);
  }
  if (Info.sw)
    if (auto *Default = Info.sw->getDefaultDest())
      if (Seen.insert(Default).second) Targets.push_back(Default);
  for (PHINode *PN : Info.phis) {
    for (BasicBlock *IncomingBB : PN->blocks()) {
      auto *Br = dyn_cast<BranchInst>(IncomingBB->getTerminator());
      if (Br && !Br->isConditional() && Br->getSuccessor(0) == Info.block &&
          Seen.insert(IncomingBB).second) {
        Targets.push_back(IncomingBB);
      }
    }
  }
  for (PHINode *PN : Info.phis) {
    if (PN == Info.state_phi || PN->use_empty()) continue;
    if (!phiUsesStayInTargets(PN, Info.block, Targets)) {
      if (traceCFF()) {
        llvm::errs() << "[CFFTRACE] redirectIsPhiSafe: phiUsesStayInTargets failed for " << PN->getName() << "\n";
      }
      return false;
    }
  }
  for (PHINode *PN : Info.phis) {
    if (PN == Info.state_phi || PN->use_empty()) continue;
    Value *V = incomingValueForSource(PN, R.src);
    if (traceCFF()) {
      llvm::errs() << "[CFFTRACE] redirectIsPhiSafe: PN=" << PN->getName()
                   << ", incoming value V=" << (V ? V->getName() : "null") << "\n";
    }
    if (V && V != PN && !proxyMatchesOriginal(dyn_cast<PHINode>(V), PN)) {
      if (R.true_target && R.true_target != Info.block) {
        if (traceCFF()) {
          llvm::errs() << "[CFFTRACE] redirectIsPhiSafe: rejected because true_target "
                       << R.true_target->getName() << " != dispatcher " << Info.block->getName() << "\n";
        }
        return false;
      }
      if (R.false_target && R.false_target != Info.block) {
        if (traceCFF()) {
          llvm::errs() << "[CFFTRACE] redirectIsPhiSafe: rejected because false_target "
                       << R.false_target->getName() << " != dispatcher " << Info.block->getName() << "\n";
        }
        return false;
      }
    }
  }
  if (traceCFF()) {
    llvm::errs() << "[CFFTRACE] redirectIsPhiSafe: accepted!\n";
  }
  return true;
}

bool isCFFDefaultBlock(BasicBlock *BB, BasicBlock *Header, const DispatcherInfo &Info) {
  if (!BB || !Header) return false;
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  if (!BI || BI->isConditional() || BI->getSuccessor(0) != Header) return false;
  for (Instruction &I : *BB) {
    if (&I == BI) break;
    auto *PN = dyn_cast<PHINode>(&I);
    if (!PN || !isProxyPhi(PN)) return false;
  }
  for (auto &[_, Target] : Info.targets) {
    if (Target.target == BB) return false;
  }
  return true;
}

bool runOnFunction(Function &F, DominatorTree &DT) {
  const DataLayout &DL = F.getDataLayout();
  bool Changed = foldOpaqueBranches(F);
  if (Changed) DT.recalculate(F);
  bool Progress = true;
  unsigned MaxIterations = std::max<unsigned>(32, std::min<unsigned>(512, static_cast<unsigned>(F.size()) * 2));
  for (unsigned Iter = 0; Progress && Iter < MaxIterations; ++Iter) {
    Progress = false;
    if (traceCFF()) llvm::errs() << "[CFFTRACE] iter " << Iter << " function " << F.getName() << " blocks " << F.size() << "\n";
    for (BasicBlock &BB : F) {
      if (traceCFF()) llvm::errs() << "[CFFTRACE] identify block " << blockOrder(&BB) << "\n";
      auto Info = identifyDispatcher(&BB);
      if (!Info) continue;
      if (traceCFF()) llvm::errs() << "[CFFTRACE] dispatcher block " << blockOrder(Info->block) << " targets " << Info->targets.size() << " phis " << Info->phis.size() << "\n";
      SmallPtrSet<BasicBlock *, 16> SeenSuccs;
      SmallVector<BasicBlock *, 16> Succs;
      auto AddSucc = [&](BasicBlock *Succ) {
        if (Succ && SeenSuccs.insert(Succ).second) Succs.push_back(Succ);
      };
      for (auto &[_, Target] : Info->targets) AddSucc(Target.target);
      if (Info->sw && !isPureHeaderBackedgeBlock(Info->sw->getDefaultDest(), Info->block)) {
        AddSucc(Info->sw->getDefaultDest());
      }
      std::sort(Succs.begin(), Succs.end(), blockLess);
      StateSolveCache SolveCache;
      SmallVector<Redirect, 16> Redirects;
      for (BasicBlock *S : Succs) {
        if (isCFFDefaultBlock(S, Info->block, *Info)) {
          if (traceCFF()) llvm::errs() << "[CFFTRACE] skipping default dest block " << blockOrder(S) << "\n";
          continue;
        }
        if (traceCFF()) llvm::errs() << "[CFFTRACE] analyze succ " << blockOrder(S) << "\n";
        if (auto R = analyzeBackEdge(S, *Info, DL, SolveCache))
          if (redirectIsPhiSafe(*R, *Info)) Redirects.push_back(*R);
      }
      if (Redirects.empty()) {
        SmallVector<BasicBlock *, 8> HeaderPreds(predecessors(Info->block));
        std::sort(HeaderPreds.begin(), HeaderPreds.end(), blockLess);
        for (BasicBlock *P : HeaderPreds) {
          if (isCFFDefaultBlock(P, Info->block, *Info)) {
            if (traceCFF()) llvm::errs() << "[CFFTRACE] skipping default dest block " << blockOrder(P) << "\n";
            continue;
          }
          if (auto R = analyzeIncomingEdge(P, *Info, DL))
            if (redirectIsPhiSafe(*R, *Info)) Redirects.push_back(*R);
        }
      }
      orderRedirectsByDependency(Redirects);
      SmallVector<Redirect, 16> ReadyRedirects;
      for (const Redirect &R : Redirects) {
        if (sourceHasPendingIncomingRedirect(R, Redirects) && redirectNeedsMissingSourceProxy(R, *Info)) {
          continue;
        }
        ReadyRedirects.push_back(R);
      }

      if (!ReadyRedirects.empty()) {
        for (PHINode *PN : Info->phis) {
          if (PN != Info->state_phi) {
            DemotePHIToStack(PN);
          }
        }
        Info->phis.clear();
        Info->phis.push_back(Info->state_phi);

        if (applyRedirects(*Info, ReadyRedirects, DT)) {
          for (const Redirect &R : ReadyRedirects) {
            llvm::errs() << "[CFF] Function: " << F.getName() << " Redirecting: " << R.src->getName()
                         << " -> " << R.true_target->getName();
            if (R.false_target) llvm::errs() << " (or " << R.false_target->getName() << ")";
            llvm::errs() << "\n";
          }
          Changed = true;
          Progress = true;
          DT.recalculate(F);
          break;
        }
      }

      bool RedirectedOne = false;
      for (const Redirect &R : ReadyRedirects) {
        for (PHINode *PN : Info->phis) {
          if (PN != Info->state_phi) {
            DemotePHIToStack(PN);
          }
        }
        Info->phis.clear();
        Info->phis.push_back(Info->state_phi);

        SmallVector<Redirect, 1> One;
        One.push_back(R);
        llvm::errs() << "[CFF] Function: " << F.getName() << " Redirecting: " << R.src->getName()
                     << " -> " << R.true_target->getName();
        if (R.false_target) llvm::errs() << " (or " << R.false_target->getName() << ")";
        llvm::errs() << "\n";
        if (applyRedirects(*Info, One, DT)) {
          Changed = true;
          Progress = true;
          DT.recalculate(F);
          RedirectedOne = true;
          break;
        }
      }
      if (RedirectedOne) break;
    }
  }
  return Changed;
}

}  // namespace

class DeobfuscateSymbolicCFFPass : public PassInfoMixin<DeobfuscateSymbolicCFFPass> {
 public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration()) return PreservedAnalyses::all();
    if (F.getMetadata(kProcessedFunctionMD)) return PreservedAnalyses::all();
    DominatorTree DT(F);
    bool Changed = runOnFunction(F, DT);
    if (!Changed) return PreservedAnalyses::all();
    F.setMetadata(kProcessedFunctionMD, MDNode::get(F.getContext(), {}));
    return PreservedAnalyses::none();
  }
};

}  // namespace deobfuscate_symbolic_cff

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "DeobfuscateSymbolicCFFPass", "0.1.0",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "deobfuscate-symbolic-cff-pass") {
                    MPM.addPass(llvm::createModuleToFunctionPassAdaptor(
                        deobfuscate_symbolic_cff::DeobfuscateSymbolicCFFPass()));
                    return true;
                  }
                  return false;
                });
          }};
}
