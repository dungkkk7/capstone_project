// Guard raw indirect call (inttoptr call).
// - Map PC -> dispatcher (tu rule AddRemillEntryDispatchers)
// - Tao resolver de chi goi vao PC known
// - Fallback tra memory khong doi
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>
#include <vector>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

// Cùng marker với rule dispatcher để tái sử dụng mapping PC -> dispatcher.
static constexpr StringRef kDispatcherAttr = "lifter.refine.remill_entry_dispatcher";

static bool IsLiftedCodeFunction(const Function &F) {
  // Chỉ xử lý trên hàm mã lifted; tránh đụng code host/runtime khác.
  StringRef Name = F.getName();
  return Name.starts_with("sub_") || Name.starts_with("__lifter_refine_dispatch_sub_");
}

static std::optional<uint64_t> ParseInstPCFromBlockName(StringRef Name) {
  // Parse inst_<hex> để truy ra PC từ tên block.
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

static Value *RawIntToPtrTarget(Value *Callee) {
  // Bóc pattern gọi gián tiếp kiểu: call ... inttoptr(i64 %target to ptr)
  // để lấy lại giá trị integer target ban đầu.
  Callee = Callee->stripPointerCasts();
  if (auto *I2P = dyn_cast<IntToPtrInst>(Callee)) {
    return I2P->getOperand(0);
  }
  auto *CE = dyn_cast<ConstantExpr>(Callee);
  if (CE && CE->getOpcode() == Instruction::IntToPtr) {
    return CE->getOperand(0);
  }
  return nullptr;
}

static bool SwitchLooksLikeLiftedDispatch(const SwitchInst &SW) {
  // Heuristic: switch có >=2 nhánh inst_ thường là dispatch theo PC của lifted IR.
  unsigned InstTargets = 0;
  for (auto Case : SW.cases()) {
    if (Case.getCaseSuccessor()->getName().starts_with("inst_")) {
      ++InstTargets;
    }
  }
  return InstTargets >= 2;
}

static bool IsLiftedSwitchDefaultBlock(const BasicBlock &BB) {
  // Chỉ patch trong default block của switch dispatch lifted.
  for (const BasicBlock *Pred : predecessors(&BB)) {
    auto *SW = dyn_cast<SwitchInst>(Pred->getTerminator());
    if (!SW || SW->getDefaultDest() != &BB) {
      continue;
    }
    if (SwitchLooksLikeLiftedDispatch(*SW)) {
      return true;
    }
  }
  return false;
}

static DenseMap<uint64_t, Function *> BuildDispatcherMap(Module &M) {
  // Xây map PC -> dispatcher function từ các hàm đã được đánh dấu attribute.
  // Nếu một PC map tới nhiều dispatcher khác nhau thì loại bỏ (ambiguous).
  DenseMap<uint64_t, Function *> DispatcherByPC;
  DenseSet<uint64_t> AmbiguousPCs;

  for (Function &F : M) {
    if (F.isDeclaration() || !F.hasFnAttribute(kDispatcherAttr)) {
      continue;
    }
    for (BasicBlock &BB : F) {
      auto PC = ParseInstPCFromBlockName(BB.getName());
      if (!PC.has_value()) {
        continue;
      }
      auto It = DispatcherByPC.find(*PC);
      if (It == DispatcherByPC.end()) {
        DispatcherByPC[*PC] = &F;
      } else if (It->second != &F) {
        AmbiguousPCs.insert(*PC);
      }
    }
  }

  for (uint64_t PC : AmbiguousPCs) {
    DispatcherByPC.erase(PC);
  }
  return DispatcherByPC;
}

static Function *GetOrCreateRawIndirectResolver(Module &M, const DenseMap<uint64_t, Function *> &DispatcherByPC) {
  // Tạo resolver nội bộ:
  //   resolve(state, target_pc, memory) -> memory'
  // Nếu target khớp PC known thì gọi dispatcher tương ứng,
  // ngược lại fallback trả memory cũ (không thực thi call thô).
  if (auto *Existing = M.getFunction("__lifter_refine_resolve_indirect_call")) {
    return Existing;
  }

  LLVMContext &Ctx = M.getContext();
  auto *PtrTy = PointerType::get(Ctx, 0);
  auto *I64Ty = Type::getInt64Ty(Ctx);
  auto *FTy = FunctionType::get(PtrTy, {PtrTy, I64Ty, PtrTy}, false);
  auto *Resolver = Function::Create(
      FTy, GlobalValue::InternalLinkage, "__lifter_refine_resolve_indirect_call", M);
  Resolver->addFnAttr(Attribute::NoInline);
  Resolver->addFnAttr(Attribute::OptimizeNone);

  auto ArgIt = Resolver->arg_begin();
  Argument *StateArg = &*ArgIt++;
  StateArg->setName("state");
  Argument *TargetArg = &*ArgIt++;
  TargetArg->setName("target");
  Argument *MemoryArg = &*ArgIt++;
  MemoryArg->setName("memory");

  BasicBlock *FallbackBB = BasicBlock::Create(Ctx, "fallback", Resolver);
  IRBuilder<> FallbackB(FallbackBB);
  FallbackB.CreateRet(MemoryArg);

  BasicBlock *CurrentCheckBB = BasicBlock::Create(Ctx, "check", Resolver, FallbackBB);
  IRBuilder<> B(CurrentCheckBB);

  std::vector<uint64_t> PCs;
  PCs.reserve(DispatcherByPC.size());
  for (const auto &Entry : DispatcherByPC) {
    PCs.push_back(Entry.first);
  }
  llvm::sort(PCs);

  for (uint64_t PC : PCs) {
    // Mỗi PC sinh một cặp block check/call trong resolver.
    Function *TargetFn = DispatcherByPC.lookup(PC);
    if (!TargetFn || TargetFn->arg_size() != 3 || !TargetFn->getReturnType()->isPointerTy()) {
      continue;
    }

    BasicBlock *CallBB = BasicBlock::Create(Ctx, "call", Resolver, FallbackBB);
    BasicBlock *NextCheckBB = BasicBlock::Create(Ctx, "check", Resolver, FallbackBB);

    Value *Match = B.CreateICmpEQ(TargetArg, ConstantInt::get(I64Ty, PC));
    if (auto *GV = M.getNamedValue((Twine("data_") + Twine::utohexstr(PC)).str())) {
      auto *AsInt = ConstantExpr::getPtrToInt(cast<Constant>(GV), I64Ty);
      Value *RelocMatch = B.CreateICmpEQ(TargetArg, AsInt);
      Match = B.CreateOr(Match, RelocMatch);
    }
    B.CreateCondBr(Match, CallBB, NextCheckBB);

    IRBuilder<> CallB(CallBB);
    auto *PCConst = ConstantInt::get(I64Ty, PC);
    Value *Resolved = CallB.CreateCall(TargetFn, {StateArg, PCConst, MemoryArg});
    CallB.CreateRet(Resolved);

    B.SetInsertPoint(NextCheckBB);
  }

  B.CreateBr(FallbackBB);
  return Resolver;
}

bool BrightenRepairPass::GuardRawIndirectCalls(Module &M) {
  // Mục tiêu: thay raw indirect call bằng đường guard có kiểm soát.
  bool Changed = false;
  struct WorkItem {
    CallInst *Call;
    Value *Target;
  };
  std::vector<WorkItem> Worklist;

  for (Function &F : M) {
    if (F.isDeclaration() || !IsLiftedCodeFunction(F)) {
      continue;
    }
    for (BasicBlock &BB : F) {
      if (!IsLiftedSwitchDefaultBlock(BB)) {
        continue;
      }
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->getCalledFunction()) {
          continue;
        }
        if (Value *Target = RawIntToPtrTarget(CI->getCalledOperand())) {
          // Ghi nhận call-site cần rewrite sau (tránh sửa khi đang iterate).
          Worklist.push_back({CI, Target});
        }
      }
    }
  }

  if (Worklist.empty()) {
    return false;
  }

  DenseMap<uint64_t, Function *> DispatcherByPC = BuildDispatcherMap(M);
  Function *Resolver = nullptr;
  if (!DispatcherByPC.empty()) {
    Resolver = GetOrCreateRawIndirectResolver(M, DispatcherByPC);
  }

  for (const WorkItem &Item : Worklist) {
    CallInst *CI = Item.Call;
    Function *F = CI->getFunction();
    if (F->arg_size() < 3 || !F->getReturnType()->isPointerTy()) {
      continue;
    }

    auto ArgIt = F->arg_begin();
    Value *StateArg = &*ArgIt++;
    (void)*ArgIt++;
    Value *MemoryArg = &*ArgIt++;
    if (auto *Ret = dyn_cast<ReturnInst>(CI->getParent()->getTerminator())) {
      if (Ret->getNumOperands() == 1 && Ret->getOperand(0)->getType()->isPointerTy()) {
        MemoryArg = Ret->getOperand(0);
      }
    }

    IRBuilder<> B(CI);
    Value *Resolved = MemoryArg;
    if (Resolver) {
      // Đưa target integer qua resolver để quyết định có gọi dispatcher hay fallback.
      Resolved = B.CreateCall(Resolver, {StateArg, Item.Target, MemoryArg});
    }

    // Chốt block bằng return và xoá toàn bộ phần còn lại trong block hiện tại.
    B.CreateRet(Resolved);

    BasicBlock *BB = CI->getParent();
    for (auto It = CI->getIterator(); It != BB->end();) {
      Instruction &I = *It++;
      I.eraseFromParent();
    }
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
