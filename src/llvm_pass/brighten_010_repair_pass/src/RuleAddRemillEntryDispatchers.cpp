// Tao dispatcher wrapper cho cac ham lifted sub_.
// - Thu PC tu inst_<pc> va remill_function_call
// - Clone function va chen switch theo PC
// - Gan attribute marker de rule khac reuse
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>
#include <string>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Transforms/Utils/Cloning.h"

namespace brighten_repair {

using namespace llvm;

// Marker attribute để phân biệt hàm dispatcher clone bởi pass.
static constexpr StringRef kDispatcherAttr = "lifter.refine.remill_entry_dispatcher";

static std::optional<uint64_t> ParseInstPCFromBlockName(StringRef Name) {
  // Parse tên block dạng: inst_<hex_pc>...
  if (!Name.starts_with("inst_")) {
    return std::nullopt;
  }

  Name = Name.drop_front(5);
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

static std::optional<uint64_t> ParseDataPCFromName(StringRef Name) {
  // Parse symbol data_<hex_pc> used by McSema for native code addresses.
  if (!Name.starts_with("data_")) {
    return std::nullopt;
  }
  Name = Name.drop_front(5);
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

static std::optional<uint64_t> ParseDataPCFromValue(Value *V) {
  V = V->stripPointerCasts();
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt && CE->getNumOperands() == 1) {
      V = CE->getOperand(0)->stripPointerCasts();
    }
  }
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    return ParseDataPCFromName(GV->getName());
  }
  return std::nullopt;
}

static Value *IncomingForSyntheticEntry(PHINode *Phi, Function &F, IRBuilder<> &B) {
  // Khi tạo block dispatch tổng hợp mới, các PHI ở block đích cần incoming
  // từ block mới này. Hàm này chọn incoming hợp lý theo type:
  // - integer -> ưu tiên PC argument
  // - pointer -> ưu tiên memory, rồi state
  // - không khớp -> undef (fallback an toàn về type).
  Type *Ty = Phi->getType();
  auto ArgIt = F.arg_begin();
  Value *StateArg = F.arg_size() >= 1 ? &*ArgIt++ : nullptr;
  Value *PCArg = F.arg_size() >= 2 ? &*ArgIt++ : nullptr;
  Value *MemoryArg = F.arg_size() >= 3 ? &*ArgIt++ : nullptr;

  if (PCArg && Ty->isIntegerTy() && PCArg->getType()->isIntegerTy()) {
    unsigned DstBits = Ty->getIntegerBitWidth();
    unsigned SrcBits = PCArg->getType()->getIntegerBitWidth();
    if (DstBits == SrcBits) {
      return PCArg;
    }
    return DstBits < SrcBits ? B.CreateTrunc(PCArg, Ty) : B.CreateZExt(PCArg, Ty);
  }

  if (Ty->isPointerTy()) {
    if (MemoryArg && MemoryArg->getType() == Ty) {
      return MemoryArg;
    }
    if (StateArg && StateArg->getType() == Ty) {
      return StateArg;
    }
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

static Value *FallbackForSyntheticDirectUse(Value *Def, Function &F, IRBuilder<> &B) {
  Type *Ty = Def->getType();
  auto ArgIt = F.arg_begin();
  Value *StateArg = F.arg_size() >= 1 ? &*ArgIt++ : nullptr;
  Value *PCArg = F.arg_size() >= 2 ? &*ArgIt++ : nullptr;
  Value *MemoryArg = F.arg_size() >= 3 ? &*ArgIt++ : nullptr;

  if (auto *LI = dyn_cast<LoadInst>(Def)) {
    Value *Ptr = LI->getPointerOperand()->stripPointerCasts();
    if (!LI->isVolatile() && !LI->isAtomic() && isa<GlobalValue>(Ptr)) {
      auto *Reload = B.CreateLoad(LI->getType(), LI->getPointerOperand(),
                                  Def->getName() + ".refine.reload");
      Reload->setAlignment(LI->getAlign());
      return Reload;
    }
  }

  if (PCArg && Ty->isIntegerTy() && PCArg->getType()->isIntegerTy()) {
    unsigned DstBits = Ty->getIntegerBitWidth();
    unsigned SrcBits = PCArg->getType()->getIntegerBitWidth();
    if (DstBits == SrcBits) {
      return PCArg;
    }
    return DstBits < SrcBits ? B.CreateTrunc(PCArg, Ty) : B.CreateZExt(PCArg, Ty);
  }

  if (Ty->isPointerTy()) {
    if (MemoryArg && MemoryArg->getType() == Ty) {
      return MemoryArg;
    }
    if (StateArg && StateArg->getType() == Ty) {
      return StateArg;
    }
  }

  return UndefValue::get(Ty);
}

static Value *UndefFor(Type *Ty) {
  return UndefValue::get(Ty);
}

static void RepairDirectUsesForSyntheticEntry(BasicBlock &TargetBB, BasicBlock &DispatchBB,
                                              Function &Dispatcher, SwitchInst &Switch,
                                              DominatorTree &DT) {
  SmallVector<Value *, 8> NeedsPhi;
  DenseSet<Value *> Seen;

  for (Instruction &I : TargetBB) {
    if (isa<PHINode>(I)) {
      continue;
    }

    for (Use &U : I.operands()) {
      auto *Def = dyn_cast<Instruction>(U.get());
      if (!Def || Def->getParent() == &TargetBB || Seen.contains(Def)) {
        continue;
      }
      Seen.insert(Def);
      NeedsPhi.push_back(Def);
    }
  }

  if (NeedsPhi.empty()) {
    return;
  }

  Instruction *InsertPt = &*TargetBB.getFirstInsertionPt();
  IRBuilder<> DispatchBuilder(&Switch);
  for (Value *Def : NeedsPhi) {
    auto *Phi = PHINode::Create(Def->getType(), 0, Def->getName() + ".refine.entry", InsertPt);
    Value *Fallback = FallbackForSyntheticDirectUse(Def, Dispatcher, DispatchBuilder);

    for (BasicBlock *Pred : predecessors(&TargetBB)) {
      if (Pred == &DispatchBB) {
        Phi->addIncoming(Fallback, Pred);
      } else if (ValueDominatesEndOfBlock(Def, *Pred, DT)) {
        Phi->addIncoming(Def, Pred);
      } else {
        Phi->addIncoming(UndefFor(Def->getType()), Pred);
      }
    }

    for (Instruction &I : TargetBB) {
      if (&I == Phi || isa<PHINode>(I)) {
        continue;
      }
      I.replaceUsesOfWith(Def, Phi);
    }
  }
}

static Value *FallbackOnEdge(Value *Def, BasicBlock &Pred, Function &Dispatcher) {
  Instruction *Term = Pred.getTerminator();
  if (!Term) {
    return UndefFor(Def->getType());
  }
  IRBuilder<> B(Term);
  return FallbackForSyntheticDirectUse(Def, Dispatcher, B);
}

static Value *FallbackBeforeUse(Value *Def, Instruction &User, Function &Dispatcher) {
  IRBuilder<> B(&User);
  return FallbackForSyntheticDirectUse(Def, Dispatcher, B);
}

static void RepairInvalidDominanceUses(Function &Dispatcher) {
  bool Changed = true;
  unsigned Iterations = 0;

  while (Changed && ++Iterations <= 8) {
    Changed = false;
    DominatorTree DT(Dispatcher);

    for (BasicBlock &BB : Dispatcher) {
      for (Instruction &I : llvm::make_early_inc_range(BB)) {
        if (auto *Phi = dyn_cast<PHINode>(&I)) {
          for (unsigned N = 0, E = Phi->getNumIncomingValues(); N != E; ++N) {
            auto *Def = dyn_cast<Instruction>(Phi->getIncomingValue(N));
            if (!Def) {
              continue;
            }
            BasicBlock *Pred = Phi->getIncomingBlock(N);
            if (ValueDominatesEndOfBlock(Def, *Pred, DT)) {
              continue;
            }
            Phi->setIncomingValue(N, FallbackOnEdge(Def, *Pred, Dispatcher));
            Changed = true;
          }
          continue;
        }

        for (unsigned Op = 0, E = I.getNumOperands(); Op != E; ++Op) {
          auto *Def = dyn_cast<Instruction>(I.getOperand(Op));
          if (!Def || DT.dominates(Def, &I)) {
            continue;
          }

          SmallVector<BasicBlock *, 4> Preds(predecessors(&BB));
          if (Preds.empty()) {
            I.setOperand(Op, FallbackBeforeUse(Def, I, Dispatcher));
            Changed = true;
            continue;
          }

          Instruction *InsertPt = &*BB.getFirstInsertionPt();
          auto *RepairPhi =
              PHINode::Create(Def->getType(), Preds.size(),
                              Def->getName() + ".refine.dom", InsertPt);
          for (BasicBlock *Pred : Preds) {
            if (ValueDominatesEndOfBlock(Def, *Pred, DT)) {
              RepairPhi->addIncoming(Def, Pred);
            } else {
              RepairPhi->addIncoming(FallbackOnEdge(Def, *Pred, Dispatcher), Pred);
            }
          }
          I.setOperand(Op, RepairPhi);
          Changed = true;
        }
      }
    }
  }
}

static std::string MakeDispatcherName(Module &M, StringRef FunctionName) {
  // Tạo tên duy nhất tránh đụng symbol hiện có trong module.
  std::string Base = ("__lifter_refine_dispatch_" + FunctionName).str();
  std::string Name = Base;
  unsigned Suffix = 0;
  while (M.getFunction(Name)) {
    Name = Base + "." + std::to_string(++Suffix);
  }
  return Name;
}

static Function *CloneFunctionAsDispatcher(
    Module &M, Function &F, ArrayRef<std::pair<uint64_t, BasicBlock *>> Targets) {
  // Clone nguyên hàm gốc thành một dispatcher wrapper, sau đó chèn
  // block switch ở entry để điều hướng vào các block inst_<pc> cụ thể.
  auto *Dispatcher = Function::Create(
      F.getFunctionType(), GlobalValue::ExternalLinkage, MakeDispatcherName(M, F.getName()), M);
  Dispatcher->copyAttributesFrom(&F);
  Dispatcher->setCallingConv(F.getCallingConv());

  ValueToValueMapTy VMap;
  auto NewArg = Dispatcher->arg_begin();
  for (Argument &OldArg : F.args()) {
    NewArg->setName(OldArg.getName());
    VMap[&OldArg] = &*NewArg++;
  }

  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionInto(
      Dispatcher, &F, VMap, CloneFunctionChangeType::LocalChangesOnly, Returns);
  DominatorTree DT(*Dispatcher);

  Dispatcher->setLinkage(GlobalValue::ExternalLinkage);
  Dispatcher->setDSOLocal(true);
  Dispatcher->addFnAttr(kDispatcherAttr);
  Dispatcher->removeFnAttr(Attribute::AlwaysInline);
  Dispatcher->addFnAttr(Attribute::NoInline);
  Dispatcher->addFnAttr(Attribute::OptimizeNone);

  auto *OriginalEntry = cast<BasicBlock>(VMap[&F.getEntryBlock()]);
  BasicBlock *DispatchBB =
      BasicBlock::Create(M.getContext(), "refine.remill.dispatch", Dispatcher, OriginalEntry);
  IRBuilder<> B(DispatchBB);

  auto ArgIt = Dispatcher->arg_begin();
  (void)*ArgIt++;
  Argument *PCArg = &*ArgIt++;
  auto *Switch = B.CreateSwitch(PCArg, OriginalEntry, Targets.size());

  for (auto [PC, OldTargetBB] : Targets) {
    // Mỗi PC known sẽ map tới block inst tương ứng trong bản clone.
    auto *TargetBB = cast<BasicBlock>(VMap[OldTargetBB]);
    Switch->addCase(ConstantInt::get(cast<IntegerType>(PCArg->getType()), PC), TargetBB);
    for (PHINode &Phi : TargetBB->phis()) {
      Phi.addIncoming(IncomingForSyntheticEntry(&Phi, *Dispatcher, B), DispatchBB);
    }
    RepairDirectUsesForSyntheticEntry(*TargetBB, *DispatchBB, *Dispatcher, *Switch, DT);
  }

  RepairInvalidDominanceUses(*Dispatcher);

  return Dispatcher;
}

bool BrightenRepairPass::AddRemillEntryDispatchers(Module &M) {
  // Rule này chỉ hữu ích khi có __remill_function_call trong module.
  Function *RemillCall = M.getFunction("__remill_function_call");
  if (!RemillCall) {
    return false;
  }

  DenseSet<uint64_t> CalledPCs;
  // Bước 1: thu toàn bộ PC constant từng được gọi qua remill_function_call.
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->getCalledFunction() != RemillCall || CI->arg_size() != 3) {
          continue;
        }
        auto *PC = dyn_cast<ConstantInt>(CI->getArgOperand(1));
        if (PC) {
          CalledPCs.insert(PC->getZExtValue());
        }
      }
    }
  }
  // Stripped ELF có thể không có symbol main. McSema vẫn lift _start và truyền
  // địa chỉ main vào __libc_start_main dưới dạng data_<pc>; thêm PC này để clone
  // dispatcher cho wrapper @main tổng hợp.
  for (Function &F : M) {
    if (!F.getName().contains("start")) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->arg_size() != 8) {
          continue;
        }
        if (auto PC = ParseDataPCFromValue(CI->getArgOperand(0))) {
          CalledPCs.insert(*PC);
        }
      }
    }
  }
  if (CalledPCs.empty()) {
    return false;
  }

  DenseMap<Function *, SmallVector<std::pair<uint64_t, BasicBlock *>, 8>> TargetsByFunction;
  DenseMap<uint64_t, Function *> OwnerByPC;
  DenseSet<uint64_t> AmbiguousPCs;
  // Bước 2: map PC -> function owner thông qua block inst_<pc>.
  // Nếu một PC xuất hiện ở nhiều function thì đánh dấu ambiguous và bỏ qua.
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (BasicBlock &BB : F) {
      auto PC = ParseInstPCFromBlockName(BB.getName());
      if (!PC.has_value() || !CalledPCs.contains(*PC)) {
        continue;
      }
      auto It = OwnerByPC.find(*PC);
      if (It == OwnerByPC.end()) {
        OwnerByPC[*PC] = &F;
        continue;
      }
      if (It->second != &F) {
        AmbiguousPCs.insert(*PC);
      }
    }
  }

  for (Function &F : M) {
    // Bước 3: với mỗi function đủ điều kiện, gom danh sách target duy nhất.
    if (F.isDeclaration() || F.hasFnAttribute(kDispatcherAttr) || F.arg_size() < 3) {
      continue;
    }
    auto ArgIt = F.arg_begin();
    (void)*ArgIt++;
    Argument *PCArg = &*ArgIt++;
    if (!PCArg->getType()->isIntegerTy()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      auto PC = ParseInstPCFromBlockName(BB.getName());
      if (!PC.has_value() || !CalledPCs.contains(*PC) || AmbiguousPCs.contains(*PC)) {
        continue;
      }
      auto OwnerIt = OwnerByPC.find(*PC);
      if (OwnerIt != OwnerByPC.end() && OwnerIt->second == &F) {
        TargetsByFunction[&F].push_back({*PC, &BB});
      }
    }
  }

  bool Changed = false;
  // Bước 4: clone function thành dispatcher cho từng nhóm target đã thu thập.
  for (auto &Entry : TargetsByFunction) {
    Function *F = Entry.first;
    auto &Targets = Entry.second;
    if (Targets.empty()) {
      continue;
    }

    CloneFunctionAsDispatcher(M, *F, Targets);
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
