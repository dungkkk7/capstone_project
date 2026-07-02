#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include <cctype>
#include <string>
#include <vector>

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

static std::optional<uint64_t> ParsePCFromInlineAsm(const Function &F) {
  for (const BasicBlock &BB : F) {
    for (const Instruction &I : BB) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (CI->isInlineAsm()) {
          auto *IA = cast<InlineAsm>(CI->getCalledOperand());
          StringRef Asm = IA->getAsmString();
          // McSema asm format: "pushq $0;pushq $$0x1080;jmpq *$1;"
          size_t Pos = Asm.find("$$0x");
          if (Pos != StringRef::npos) {
            StringRef Hex = Asm.drop_front(Pos + 4);
            size_t End = 0;
            while (End < Hex.size() && std::isxdigit(static_cast<unsigned char>(Hex[End]))) {
              ++End;
            }
            uint64_t PC = 0;
            if (!Hex.take_front(End).getAsInteger(16, PC)) {
              return PC;
            }
          }
        }
      }
    }
  }
  return std::nullopt;
}

static Function *FindWrapperOrSub(Module &M, uint64_t PC, StringRef Name) {
  std::string WrapperName = (Name + "_wrapper").str();
  if (Function *Wrap = M.getFunction(WrapperName)) {
    if (!Wrap->isDeclaration()) {
      return Wrap;
    }
  }
  std::string SubName = "sub_" + utohexstr(PC);
  for (Function &F : M) {
    if (!F.isDeclaration() && F.getName().starts_with(SubName)) {
      return &F;
    }
  }
  return nullptr;
}

}  // namespace

bool BrightenRuntimeHelperPass::LowerMcSemaAttachThunks(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();
  GlobalVariable *RegState = M.getGlobalVariable("__mcsema_reg_state");
  if (!RegState) {
    errs() << "[brighten-mcsema-lower] Warning: __mcsema_reg_state not found\n";
  }

  // Offsets trong struct State:
  // RAX: 2216, RDI: 2296, RSI: 2280, RDX: 2264
  Type *I8 = Type::getInt8Ty(Ctx);
  Type *I64 = Type::getInt64Ty(Ctx);

  // 1. Lower main/start/.init_proc attach thunks
  std::vector<Function *> ThunkFunctions;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    StringRef Name = F.getName();
    if (Name == "main" || Name == "start" || Name == ".init_proc" ||
        Name.starts_with("callback_sub_")) {
      // Check if it calls inline asm to attach_call
      if (ParsePCFromInlineAsm(F).has_value()) {
        ThunkFunctions.push_back(&F);
      }
    }
  }

  for (Function *F : ThunkFunctions) {
    auto PC = ParsePCFromInlineAsm(*F);
    if (!PC.has_value()) {
      continue;
    }

    StringRef Name = F->getName();
    Function *Target = FindWrapperOrSub(M, *PC, Name);
    if (!Target) {
      errs() << "[brighten-mcsema-lower] Target not found for thunk " << Name
             << " (PC: 0x" << utohexstr(*PC) << ")\n";
      continue;
    }

    // Remove naked attribute so that LLVM allows using arguments and calls
    F->removeFnAttr(Attribute::Naked);

    // Clear old body
    F->deleteBody();
    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);
    IRBuilder<> B(Entry);

    if (Name == "main") {
      // setup args in State
      if (RegState) {
        // EDI (argc) - arg 0
        if (F->arg_size() > 0) {
          Value *Argc = F->getArg(0);
          Value *EDIPtr = B.CreateConstGEP1_64(I8, RegState, 2296);
          B.CreateAlignedStore(B.CreateZExtOrTrunc(Argc, I64), EDIPtr, Align(8));
        }
        // RSI (argv) - arg 1
        if (F->arg_size() > 1) {
          Value *Argv = F->getArg(1);
          Value *RSIPtr = B.CreateConstGEP1_64(I8, RegState, 2280);
          B.CreateAlignedStore(B.CreatePtrToInt(Argv, I64), RSIPtr, Align(8));
        }
        // RDX (envp) - arg 2
        if (F->arg_size() > 2) {
          Value *Envp = F->getArg(2);
          Value *RDXPtr = B.CreateConstGEP1_64(I8, RegState, 2264);
          B.CreateAlignedStore(B.CreatePtrToInt(Envp, I64), RDXPtr, Align(8));
        }
      }

      // Call target
      // Target có thể có signature (ptr, i64, ptr)->ptr hoặc signature của main
      if (HasMemoryThreadingSignature(*Target)) {
        B.CreateCall(Target->getFunctionType(), Target,
                     {RegState ? B.CreateBitCast(RegState, Target->getFunctionType()->getParamType(0))
                               : ConstantPointerNull::get(PointerType::get(Ctx, 0)),
                      B.getInt64(*PC),
                      ConstantPointerNull::get(PointerType::get(Ctx, 0))});
      } else {
        // Call direct
        B.CreateCall(Target);
      }

      // Read return value (RAX)
      if (RegState && !F->getReturnType()->isVoidTy()) {
        Value *RAXPtr = B.CreateConstGEP1_64(I8, RegState, 2216);
        Value *RAXVal = B.CreateAlignedLoad(I64, RAXPtr, Align(8));
        B.CreateRet(B.CreateZExtOrTrunc(RAXVal, F->getReturnType()));
      } else {
        B.CreateRet(ZeroValue(F->getReturnType()));
      }
    } else {
      // start, .init_proc hoặc callback
      if (HasMemoryThreadingSignature(*Target)) {
        B.CreateCall(Target->getFunctionType(), Target,
                     {RegState ? B.CreateBitCast(RegState, Target->getFunctionType()->getParamType(0))
                               : ConstantPointerNull::get(PointerType::get(Ctx, 0)),
                      B.getInt64(*PC),
                      ConstantPointerNull::get(PointerType::get(Ctx, 0))});
      } else {
        B.CreateCall(Target);
      }

      if (F->getReturnType()->isVoidTy()) {
        B.CreateRetVoid();
      } else {
        B.CreateRet(ZeroValue(F->getReturnType()));
      }
    }

    Changed = true;
    errs() << "[brighten-mcsema-lower] Lowered thunk: " << Name
           << " -> target: " << Target->getName() << "\n";
  }

  // 2. Define noop cho __mcsema_early_init nếu thiếu body
  if (Function *EarlyInit = M.getFunction("__mcsema_early_init")) {
    if (EarlyInit->isDeclaration()) {
      BasicBlock *BB = BasicBlock::Create(Ctx, "entry", EarlyInit);
      IRBuilder<> B(BB);
      B.CreateRetVoid();
      Changed = true;
      errs() << "[brighten-mcsema-lower] Defined noop for __mcsema_early_init\n";
    }
  }

  // 3. Remove callback attach thunk còn sót mà không dùng (use_empty)
  std::vector<Function *> DeadCallbacks;
  for (Function &F : M) {
    if (F.getName().starts_with("callback_sub_") && F.use_empty()) {
      DeadCallbacks.push_back(&F);
    }
  }
  for (Function *F : DeadCallbacks) {
    F->eraseFromParent();
    Changed = true;
    errs() << "[brighten-mcsema-lower] Erased unused callback thunk: " << F->getName() << "\n";
  }

  // 4. Xoá declaration của __mcsema_attach_call
  if (Function *AttachCall = M.getFunction("__mcsema_attach_call")) {
    AttachCall->replaceAllUsesWith(UndefValue::get(AttachCall->getType()));
    AttachCall->eraseFromParent();
    Changed = true;
    errs() << "[brighten-mcsema-lower] Erased __mcsema_attach_call declaration\n";
  }

  // 5. Verify không còn unresolved __mcsema_* trừ global state
  std::vector<Function *> UnresolvedMcSema;
  for (Function &F : M) {
    if (F.isDeclaration() && F.getName().starts_with("__mcsema_")) {
      UnresolvedMcSema.push_back(&F);
    }
  }
  for (Function *F : UnresolvedMcSema) {
    errs() << "[brighten-mcsema-lower] Warning: fallback unresolved mcsema: " << F->getName() << "\n";
    BasicBlock *BB = BasicBlock::Create(Ctx, "entry", F);
    IRBuilder<> B(BB);
    if (F->getReturnType()->isVoidTy()) {
      B.CreateRetVoid();
    } else {
      B.CreateRet(ZeroValue(F->getReturnType()));
    }
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_runtime
