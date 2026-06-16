// Tao wrapper @main khi binary stripped khong co symbol main.
// - Lay PC main tu call __libc_start_main trong lifted _start
// - Set argc/argv/envp vao McSema State
// - Goi dispatcher PC neu co, fallback goi owner subroutine gan nhat
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

static constexpr StringRef kDispatcherAttr = "lifter.refine.remill_entry_dispatcher";

static std::optional<uint64_t> ParseHexSuffix(StringRef Name, StringRef Prefix) {
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

static std::optional<uint64_t> ParseInstPCFromBlockName(StringRef Name) {
  return ParseHexSuffix(Name, "inst_");
}

static std::optional<uint64_t> ParseDataPCFromName(StringRef Name) {
  return ParseHexSuffix(Name, "data_");
}

static std::optional<uint64_t> ParseSubPCFromName(StringRef Name) {
  return ParseHexSuffix(Name, "sub_");
}

static std::optional<uint64_t> ParseEntryPCFromName(StringRef Name) {
  if (auto PC = ParseDataPCFromName(Name)) {
    return PC;
  }
  if (auto PC = ParseHexSuffix(Name, "auto_sub_")) {
    return PC;
  }
  return ParseSubPCFromName(Name);
}

static std::optional<uint64_t> ParseEntryPCFromValue(Value *V) {
  V = V->stripPointerCasts();
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt && CE->getNumOperands() == 1) {
      V = CE->getOperand(0)->stripPointerCasts();
    }
  }
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    return ParseEntryPCFromName(GV->getName());
  }
  return std::nullopt;
}

static std::optional<uint64_t> FindMainPCFromLiftedStart(Module &M) {
  for (Function &F : M) {
    if (F.isDeclaration() || !F.getName().contains("start")) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->arg_size() != 8) {
          continue;
        }
        if (auto PC = ParseEntryPCFromValue(CI->getArgOperand(0))) {
          return PC;
        }
      }
    }
  }
  return std::nullopt;
}

static Function *FindDispatcherByPC(Module &M, uint64_t PC) {
  for (Function &F : M) {
    if (F.isDeclaration() || !F.hasFnAttribute(kDispatcherAttr)) {
      continue;
    }
    for (BasicBlock &BB : F) {
      auto BlockPC = ParseInstPCFromBlockName(BB.getName());
      if (BlockPC.has_value() && *BlockPC == PC) {
        return &F;
      }
    }
  }
  return nullptr;
}

static Function *FindOwnerSubroutineByPC(Module &M, uint64_t PC) {
  Function *Best = nullptr;
  uint64_t BestStart = 0;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    auto Start = ParseSubPCFromName(F.getName());
    if (!Start.has_value() || *Start > PC) {
      continue;
    }
    if (!Best || *Start > BestStart) {
      Best = &F;
      BestStart = *Start;
    }
  }
  return Best;
}

static Value *CreateNestedStateGEP(IRBuilder<> &B, StructType *StateTy, Value *State,
                                   ArrayRef<unsigned> Indices, StringRef Name) {
  SmallVector<Value *, 6> GEPIdx;
  GEPIdx.push_back(B.getInt32(0));
  for (unsigned Idx : Indices) {
    GEPIdx.push_back(B.getInt32(Idx));
  }
  return B.CreateInBoundsGEP(StateTy, State, GEPIdx, Name);
}

static void StoreMainArguments(IRBuilder<> &B, Module &M, Value *State,
                               Argument *Argc, Argument *Argv, Argument *Envp) {
  auto *StateTy = StructType::getTypeByName(M.getContext(), "struct.State");
  if (!StateTy) {
    return;
  }

  Value *EDI = CreateNestedStateGEP(B, StateTy, State, {6, 11, 0, 0}, "EDI");
  B.CreateStore(Argc, EDI)->setAlignment(Align(4));

  Value *RSI = CreateNestedStateGEP(B, StateTy, State, {6, 9, 0, 0}, "RSI");
  B.CreateStore(B.CreatePtrToInt(Argv, B.getInt64Ty()), RSI)->setAlignment(Align(8));

  Value *RDX = CreateNestedStateGEP(B, StateTy, State, {6, 7, 0, 0}, "RDX");
  B.CreateStore(B.CreatePtrToInt(Envp, B.getInt64Ty()), RDX)->setAlignment(Align(8));
}

static Value *LoadReturnCode(IRBuilder<> &B, Module &M, Value *State) {
  auto *StateTy = StructType::getTypeByName(M.getContext(), "struct.State");
  if (!StateTy) {
    return B.getInt32(0);
  }
  Value *RAX = CreateNestedStateGEP(B, StateTy, State, {6, 1, 0, 0}, "RAX");
  auto *Ret64 = B.CreateLoad(B.getInt64Ty(), RAX);
  Ret64->setAlignment(Align(8));
  return B.CreateTrunc(Ret64, B.getInt32Ty());
}

bool BrightenRepairPass::SynthesizeMissingMain(Module &M) {
  if (M.getFunction("main")) {
    return false;
  }

  auto MainPC = FindMainPCFromLiftedStart(M);
  if (!MainPC.has_value()) {
    return false;
  }

  Function *Target = FindDispatcherByPC(M, *MainPC);
  if (!Target) {
    Target = FindOwnerSubroutineByPC(M, *MainPC);
  }
  Function *InitState = M.getFunction("__mcsema_init_reg_state");
  if (!Target || !InitState || Target->arg_size() < 3) {
    return false;
  }

  auto *I32 = Type::getInt32Ty(M.getContext());
  auto *PtrTy = PointerType::getUnqual(M.getContext());
  auto *MainTy = FunctionType::get(I32, {I32, PtrTy, PtrTy}, false);
  auto *Main = Function::Create(MainTy, GlobalValue::ExternalLinkage, "main", M);
  Main->setDSOLocal(true);
  Main->setCallingConv(CallingConv::X86_64_SysV);
  Main->addFnAttr(Attribute::NoBuiltin);
  Main->addFnAttr(Attribute::NoInline);

  auto ArgIt = Main->arg_begin();
  auto *Argc = &*ArgIt++;
  Argc->setName("argc");
  auto *Argv = &*ArgIt++;
  Argv->setName("argv");
  auto *Envp = &*ArgIt++;
  Envp->setName("envp");

  auto *Entry = BasicBlock::Create(M.getContext(), "entry", Main);
  IRBuilder<> B(Entry);
  Value *State = B.CreateCall(InitState);
  StoreMainArguments(B, M, State, Argc, Argv, Envp);

  SmallVector<Value *, 3> TargetArgs;
  auto TArg = Target->arg_begin();
  TargetArgs.push_back(State);
  ++TArg;
  Type *PCTy = TArg->getType();
  TargetArgs.push_back(ConstantInt::get(cast<IntegerType>(PCTy), *MainPC));
  ++TArg;
  TargetArgs.push_back(Constant::getNullValue(TArg->getType()));
  B.CreateCall(Target, TargetArgs);
  B.CreateRet(LoadReturnCode(B, M, State));
  return true;
}

}  // namespace brighten_repair
