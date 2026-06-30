// Recover fallthrough target sau no-return call.
// - Tim PC duoc store (return/fallthrough)
// - Them case vao switch dispatch va sua PHI
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

static std::optional<uint64_t> ParseHexPCSuffix(StringRef Name, StringRef Prefix) {
  // Parse hậu tố hex theo tiền tố (inst_/data_) dùng chung nhiều chỗ.
  if (!Name.starts_with(Prefix)) {
    return std::nullopt;
  }

  Name = Name.drop_front(Prefix.size());
  if (Name.empty()) {
    return std::nullopt;
  }

  size_t End = 0;
  while (End < Name.size() && std::isxdigit(static_cast<unsigned char>(Name[End]))) {
    ++End;
  }
  if (End == 0) {
    return std::nullopt;
  }

  uint64_t PC = 0;
  if (Name.take_front(End).getAsInteger(16, PC)) {
    return std::nullopt;
  }
  return PC;
}

static std::optional<uint64_t> ParseInstPC(const BasicBlock &BB) {
  return ParseHexPCSuffix(BB.getName(), "inst_");
}

static std::optional<uint64_t> ParseDataPC(const Value *V) {
  V = V->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    return ParseHexPCSuffix(GV->getName(), "data_");
  }
  return std::nullopt;
}

static std::optional<uint64_t> EvalPCValue(Value *V, Value *TargetValue, uint64_t KnownTarget,
                                           unsigned Depth = 0) {
  // Evaluator nhỏ cho biểu thức PC đơn giản trong IR, có giới hạn depth
  // để tránh đệ quy sâu/chu kỳ không mong muốn.
  if (!V || Depth > 32) {
    return std::nullopt;
  }
  if (V == TargetValue) {
    return KnownTarget;
  }

  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    return CI->getZExtValue();
  }

  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    switch (CE->getOpcode()) {
      case Instruction::PtrToInt:
        return ParseDataPC(CE->getOperand(0));
      case Instruction::Add: {
        auto L = EvalPCValue(CE->getOperand(0), TargetValue, KnownTarget, Depth + 1);
        auto R = EvalPCValue(CE->getOperand(1), TargetValue, KnownTarget, Depth + 1);
        if (L && R) {
          return *L + *R;
        }
        return std::nullopt;
      }
      case Instruction::Sub: {
        auto L = EvalPCValue(CE->getOperand(0), TargetValue, KnownTarget, Depth + 1);
        auto R = EvalPCValue(CE->getOperand(1), TargetValue, KnownTarget, Depth + 1);
        if (L && R) {
          return *L - *R;
        }
        return std::nullopt;
      }
      case Instruction::Trunc:
      case Instruction::ZExt:
      case Instruction::SExt:
      case Instruction::BitCast:
        return EvalPCValue(CE->getOperand(0), TargetValue, KnownTarget, Depth + 1);
      default:
        return std::nullopt;
    }
  }

  if (auto *I = dyn_cast<Instruction>(V)) {
    switch (I->getOpcode()) {
      case Instruction::PtrToInt:
        return ParseDataPC(I->getOperand(0));
      case Instruction::Add: {
        auto L = EvalPCValue(I->getOperand(0), TargetValue, KnownTarget, Depth + 1);
        auto R = EvalPCValue(I->getOperand(1), TargetValue, KnownTarget, Depth + 1);
        if (L && R) {
          return *L + *R;
        }
        return std::nullopt;
      }
      case Instruction::Sub: {
        auto L = EvalPCValue(I->getOperand(0), TargetValue, KnownTarget, Depth + 1);
        auto R = EvalPCValue(I->getOperand(1), TargetValue, KnownTarget, Depth + 1);
        if (L && R) {
          return *L - *R;
        }
        return std::nullopt;
      }
      case Instruction::Trunc:
      case Instruction::ZExt:
      case Instruction::SExt:
      case Instruction::BitCast:
        return EvalPCValue(I->getOperand(0), TargetValue, KnownTarget, Depth + 1);
      default:
        return std::nullopt;
    }
  }

  return std::nullopt;
}

static bool IsKnownNoReturnCall(const CallInst &CI) {
  // Danh sách hàm no-return phổ biến mà rule muốn bắt.
  const Function *Callee = CI.getCalledFunction();
  if (!Callee) {
    return false;
  }

  StringRef Name = Callee->getName();
  return Name.contains("__assert_fail") || Name == "abort" || Name.ends_with("_abort") ||
         Name == "exit" || Name.ends_with("_exit");
}

static Value *GetMemoryArgument(CallInst &CI) {
  // Theo convention remill: arg thứ 3 thường là memory pointer.
  if (CI.arg_size() >= 3 && CI.getArgOperand(2)->getType()->isPointerTy()) {
    return CI.getArgOperand(2);
  }
  return nullptr;
}

static std::optional<uint64_t> FindStoredReturnPC(CallInst &CI, Value *TargetValue,
                                                  uint64_t KnownTarget) {
  // Quét ngược một đoạn ngắn để tìm store chứa return/fallthrough PC.
  BasicBlock *BB = CI.getParent();
  unsigned Seen = 0;
  for (auto It = CI.getIterator(); It != BB->begin() && Seen < 32;) {
    --It;
    ++Seen;

    auto *Store = dyn_cast<StoreInst>(&*It);
    if (!Store || !Store->getValueOperand()->getType()->isIntegerTy()) {
      continue;
    }

    auto PC = EvalPCValue(Store->getValueOperand(), TargetValue, KnownTarget);
    if (PC && *PC != KnownTarget) {
      return PC;
    }
  }
  return std::nullopt;
}

static bool SwitchHasCase(const SwitchInst &SW, uint64_t PC) {
  // Tránh thêm case trùng.
  for (auto Case : SW.cases()) {
    if (Case.getCaseValue()->getZExtValue() == PC) {
      return true;
    }
  }
  return false;
}

static Value *FallbackIncoming(Type *Ty, Value *MemoryIncoming, uint64_t PC) {
  // Giá trị fallback để bù incoming cho PHI khi thêm cạnh CFG mới.
  if (MemoryIncoming && MemoryIncoming->getType() == Ty) {
    return MemoryIncoming;
  }
  if (auto *IntTy = dyn_cast<IntegerType>(Ty)) {
    return ConstantInt::get(IntTy, PC);
  }
  return UndefValue::get(Ty);
}

static bool ValueDominatesEndOfBlock(Value *V, BasicBlock &BB, DominatorTree &DT) {
  if (isa<Constant>(V) || isa<Argument>(V)) {
    return true;
  }

  auto *I = dyn_cast<Instruction>(V);
  if (!I || !BB.getTerminator()) {
    return false;
  }
  if (I->getParent() == &BB) {
    return I == BB.getTerminator() || I->comesBefore(BB.getTerminator());
  }
  return DT.dominates(I, BB.getTerminator());
}

static Value *FallbackIncoming(Type *Ty, Value *MemoryIncoming, uint64_t PC,
                               BasicBlock &Pred, DominatorTree &DT) {
  // Không dùng memory value từ no-return block nếu nó không dominate edge mới
  // từ switch predecessor; verifier sẽ reject PHI incoming như vậy.
  if (MemoryIncoming && MemoryIncoming->getType() == Ty &&
      ValueDominatesEndOfBlock(MemoryIncoming, Pred, DT)) {
    return MemoryIncoming;
  }
  if (auto *IntTy = dyn_cast<IntegerType>(Ty)) {
    return ConstantInt::get(IntTy, PC);
  }
  return UndefValue::get(Ty);
}

static unsigned CountTerminatorEdgesTo(const BasicBlock &Pred, const BasicBlock &Succ) {
  // Đếm số cạnh từ terminator Pred sang Succ, bao gồm cả multi-edge.
  const Instruction *Term = Pred.getTerminator();
  if (!Term) {
    return 0;
  }

  if (const auto *BI = dyn_cast<BranchInst>(Term)) {
    unsigned Count = 0;
    for (unsigned I = 0, E = BI->getNumSuccessors(); I != E; ++I) {
      if (BI->getSuccessor(I) == &Succ) {
        ++Count;
      }
    }
    return Count;
  }

  if (const auto *SW = dyn_cast<SwitchInst>(Term)) {
    unsigned Count = SW->getDefaultDest() == &Succ ? 1 : 0;
    for (auto Case : SW->cases()) {
      if (Case.getCaseSuccessor() == &Succ) {
        ++Count;
      }
    }
    return Count;
  }

  if (const auto *IBR = dyn_cast<IndirectBrInst>(Term)) {
    unsigned Count = 0;
    for (unsigned I = 0, E = IBR->getNumDestinations(); I != E; ++I) {
      if (IBR->getDestination(I) == &Succ) {
        ++Count;
      }
    }
    return Count;
  }

  if (const auto *II = dyn_cast<InvokeInst>(Term)) {
    unsigned Count = 0;
    if (II->getNormalDest() == &Succ) {
      ++Count;
    }
    if (II->getUnwindDest() == &Succ) {
      ++Count;
    }
    return Count;
  }

  return 0;
}

static unsigned CountPhiIncomingFrom(const PHINode &Phi, const BasicBlock &Pred) {
  unsigned Count = 0;
  for (unsigned I = 0, E = Phi.getNumIncomingValues(); I != E; ++I) {
    if (Phi.getIncomingBlock(I) == &Pred) {
      ++Count;
    }
  }
  return Count;
}

static Value *FirstPhiIncomingFrom(PHINode &Phi, const BasicBlock &Pred) {
  for (unsigned I = 0, E = Phi.getNumIncomingValues(); I != E; ++I) {
    if (Phi.getIncomingBlock(I) == &Pred) {
      return Phi.getIncomingValue(I);
    }
  }
  return nullptr;
}

static Value *FirstDominatingPhiIncoming(PHINode &Phi, BasicBlock &Pred, DominatorTree &DT) {
  // Khi block đích đã có incoming từ các predecessor khác, ưu tiên reuse một
  // incoming đang dominate switch predecessor. Điều này giữ PHI hợp lệ hơn
  // `undef` và tránh dùng value sinh trong no-return case.
  for (unsigned I = 0, E = Phi.getNumIncomingValues(); I != E; ++I) {
    Value *Incoming = Phi.getIncomingValue(I);
    if (Incoming->getType() == Phi.getType() &&
        ValueDominatesEndOfBlock(Incoming, Pred, DT)) {
      return Incoming;
    }
  }
  return nullptr;
}

static void EnsurePhiIncomingForSwitchEdges(BasicBlock &Target, BasicBlock &NewPred,
                                            Value *MemoryIncoming, uint64_t PC,
                                            DominatorTree &DT) {
  // Đảm bảo mọi PHI ở target có đủ incoming tương ứng số cạnh mới.
  unsigned ExpectedEdges = CountTerminatorEdgesTo(NewPred, Target);
  if (ExpectedEdges == 0) {
    return;
  }

  for (PHINode &Phi : Target.phis()) {
    unsigned Current = CountPhiIncomingFrom(Phi, NewPred);
    Value *Incoming = FirstPhiIncomingFrom(Phi, NewPred);
    if (!Incoming) {
      Incoming = FirstDominatingPhiIncoming(Phi, NewPred, DT);
    }
    if (!Incoming) {
      Incoming = FallbackIncoming(Phi.getType(), MemoryIncoming, PC, NewPred, DT);
    }
    while (Current < ExpectedEdges) {
      Phi.addIncoming(Incoming, &NewPred);
      ++Current;
    }
  }
}

static void RepairSplitBlockUses(BasicBlock &Target, BasicBlock &OriginalPred,
                                 BasicBlock &NewPred, Value *MemoryIncoming, uint64_t PC,
                                 DominatorTree &DT) {
  // Khi split block, các use trực tiếp giá trị định nghĩa ở block cũ
  // có thể không còn dominate với cạnh mới. Ta chèn PHI trung gian để sửa.
  SmallVector<Value *, 8> NeedsPhi;
  DenseSet<Value *> Seen;

  for (Instruction &I : Target) {
    for (Use &U : I.operands()) {
      auto *Def = dyn_cast<Instruction>(U.get());
      if (!Def || Def->getParent() != &OriginalPred || Seen.contains(Def)) {
        continue;
      }
      Seen.insert(Def);
      NeedsPhi.push_back(Def);
    }
  }

  Instruction *InsertPt = &*Target.getFirstInsertionPt();
  for (Value *Def : NeedsPhi) {
    auto *Phi = PHINode::Create(Def->getType(), 2, Def->getName() + ".refine.in", InsertPt);
    Phi->addIncoming(Def, &OriginalPred);
    Phi->addIncoming(FallbackIncoming(Def->getType(), MemoryIncoming, PC, NewPred, DT), &NewPred);

    for (Instruction &I : Target) {
      if (&I == Phi || isa<PHINode>(I)) {
        continue;
      }
      I.replaceUsesOfWith(Def, Phi);
    }
  }
}

static BasicBlock *GetOrCreateFallthroughTarget(CallInst &CI, uint64_t ReturnPC,
                                                BasicBlock &NewPred, Value *MemoryIncoming,
                                                DominatorTree &DT) {
  // Nếu đã có block đích ngay sau call + br vô điều kiện thì reuse.
  // Ngược lại split block tại instruction kế tiếp call để tạo target mới.
  Instruction *Next = CI.getNextNode();
  if (!Next) {
    return nullptr;
  }

  if (auto *Br = dyn_cast<BranchInst>(Next)) {
    if (Br->isUnconditional()) {
      return Br->getSuccessor(0);
    }
  }
  if (Next->isTerminator()) {
    return nullptr;
  }

  BasicBlock *OriginalBB = CI.getParent();
  BasicBlock *Target =
      OriginalBB->splitBasicBlock(Next, (Twine("inst_") + Twine::utohexstr(ReturnPC) + ".refine").str());
  RepairSplitBlockUses(*Target, *OriginalBB, NewPred, MemoryIncoming, ReturnPC, DT);
  return Target;
}

bool BrightenRepairPass::RecoverNoReturnFallthroughTargets(Module &M) {
  // Mục tiêu: khôi phục các case fallthrough PC bị thiếu trong switch dispatch
  // khi gặp nhánh có no-return call nhưng vẫn có return PC được lưu trước đó.
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    SmallVector<SwitchInst *, 8> Switches;
    for (BasicBlock &BB : F) {
      auto *SW = dyn_cast<SwitchInst>(BB.getTerminator());
      if (!SW || !SW->getCondition()->getType()->isIntegerTy()) {
        continue;
      }

      unsigned LiftedTargets = 0;
      for (auto Case : SW->cases()) {
        if (Case.getCaseSuccessor()->getName().starts_with("inst_")) {
          ++LiftedTargets;
        }
      }
      if (LiftedTargets >= 2) {
        Switches.push_back(SW);
      }
    }

    for (SwitchInst *SW : Switches) {
      DominatorTree DT(F);
      Value *TargetValue = SW->getCondition();
      BasicBlock *SwitchBB = SW->getParent();

      SmallVector<std::tuple<uint64_t, BasicBlock *, Value *>, 8> NewCases;
      for (auto Case : SW->cases()) {
        uint64_t CasePC = Case.getCaseValue()->getZExtValue();
        BasicBlock *CaseBB = Case.getCaseSuccessor();
        auto BlockPC = ParseInstPC(*CaseBB);
        if (!BlockPC || *BlockPC != CasePC) {
          continue;
        }

        for (Instruction &I : *CaseBB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (!CI || !IsKnownNoReturnCall(*CI)) {
            continue;
          }

          auto ReturnPC = FindStoredReturnPC(*CI, TargetValue, CasePC);
          if (!ReturnPC || SwitchHasCase(*SW, *ReturnPC)) {
            continue;
          }

          Value *MemoryIncoming = GetMemoryArgument(*CI);
          BasicBlock *Target = GetOrCreateFallthroughTarget(*CI, *ReturnPC, *SwitchBB, MemoryIncoming, DT);
          if (!Target || Target->getParent() != &F) {
            continue;
          }

          NewCases.push_back({*ReturnPC, Target, MemoryIncoming});
        }
      }

      for (auto [PC, Target, MemoryIncoming] : NewCases) {
        // Chỉ commit case mới sau khi gom xong để an toàn iterator/CFG edits.
        if (SwitchHasCase(*SW, PC)) {
          continue;
        }
        SW->addCase(ConstantInt::get(cast<IntegerType>(TargetValue->getType()), PC), Target);
        EnsurePhiIncomingForSwitchEdges(*Target, *SwitchBB, MemoryIncoming, PC, DT);
        Changed = true;
      }
    }
  }

  return Changed;
}

}  // namespace brighten_repair
