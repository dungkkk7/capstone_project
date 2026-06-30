// Rewrite __remill_function_call thanh direct calls.
// - Uu tien sub_<pc> hoac dispatcher
// - Neu khong resolve duoc thi goi noop helper
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>
#include <vector>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"

namespace brighten_repair {

using namespace llvm;

static constexpr StringRef kDispatcherAttr = "lifter.refine.remill_entry_dispatcher";

static std::optional<uint64_t> ParseInstPCFromBlockName(StringRef Name) {
  // Parse inst_<hex> để map block -> PC.
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

bool BrightenRepairPass::NormalizeRemillFunctionCalls(Module &M) {
  // Rewrite call __remill_function_call(state, pc_const, mem)
  // -> gọi trực tiếp sub_<pc> / dispatcher nếu tìm được,
  // -> fallback noop helper nếu không resolve được.
  auto *RemillCall = M.getFunction("__remill_function_call");
  if (!RemillCall) {
    return false;
  }

  DenseMap<uint64_t, Function *> DispatcherByPC;
  DenseSet<uint64_t> AmbiguousPCs;
  // Thu map PC -> dispatcher (loại bỏ PC ambiguous).
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

  bool Changed = false;
  std::vector<CallInst *> Worklist;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm()) {
          continue;
        }

        auto *Callee = CI->getCalledFunction();
        if (Callee != RemillCall) {
          continue;
        }

        if (CI->arg_size() != 3) {
          continue;
        }

        if (!isa<ConstantInt>(CI->getArgOperand(1))) {
          continue;
        }

        // Gom trước rồi rewrite sau để tránh invalid iterator.
        Worklist.push_back(CI);
      }
    }
  }

  for (CallInst *CI : Worklist) {
    auto *PCConst = cast<ConstantInt>(CI->getArgOperand(1));
    const uint64_t PC = PCConst->getZExtValue();

    IRBuilder<> B(CI);

    // Ưu tiên gọi trực tiếp sub_<pc> thật.
    if (Function *Target = FindLiftedSubroutineByPC(M, PC)) {
      if (Target->getFunctionType() == CI->getFunctionType()) {
        auto *NewCall = B.CreateCall(Target, {CI->getArgOperand(0), CI->getArgOperand(1), CI->getArgOperand(2)});
        CI->replaceAllUsesWith(NewCall);
        CI->eraseFromParent();
        Changed = true;
        continue;
      }
    }

    auto It = DispatcherByPC.find(PC);
    if (It != DispatcherByPC.end()) {
      // Nếu có dispatcher đã clone cho PC này, dùng dispatcher.
      Function *Target = It->second;
      if (Target && Target->getFunctionType() == CI->getFunctionType()) {
        auto *NewCall = B.CreateCall(Target, {CI->getArgOperand(0), CI->getArgOperand(1), CI->getArgOperand(2)});
        CI->replaceAllUsesWith(NewCall);
        CI->eraseFromParent();
        Changed = true;
        continue;
      }
    }

    // Không resolve được thì fallback noop để giữ type + luồng memory.
    Function *Noop = GetOrCreateNoopCallHelper(M, CI->getFunctionType());
    auto *NewCall = B.CreateCall(Noop, {CI->getArgOperand(0), CI->getArgOperand(1), CI->getArgOperand(2)});
    CI->replaceAllUsesWith(NewCall);
    CI->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
