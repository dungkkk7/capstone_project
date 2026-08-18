#include "BrightenExternCallBridgePass.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include <cctype>
#include <cstring>

namespace brighten_extern {

using namespace llvm;

static Value *StripAlias(Value *V) {
  if (!V)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = Alias->getAliasee())
      return Aliasee->stripPointerCasts();
  }
  return V;
}

static std::optional<uint64_t> ParseHexPrefix(StringRef Text) {
  if (Text.empty())
    return std::nullopt;
  size_t End = 0;
  while (End < Text.size() &&
         std::isxdigit(static_cast<unsigned char>(Text[End])))
    ++End;
  if (End == 0)
    return std::nullopt;
  uint64_t Val = 0;
  if (Text.substr(0, End).getAsInteger(16, Val))
    return std::nullopt;
  return Val;
}

static std::optional<uint64_t> ParseAddressName(StringRef Name) {
  if (Name.empty())
    return std::nullopt;
  uint64_t Raw = 0;
  if (!Name.getAsInteger(16, Raw))
    return Raw;
  for (const char *Prefix : {"sub_", "ext_", "auto_sub_", "callback_sub_",
                              "data_", "seg_"}) {
    if (Name.starts_with(Prefix))
      return ParseHexPrefix(Name.drop_front(strlen(Prefix)));
  }
  return std::nullopt;
}

static std::optional<StringRef> ExternalNameFromExtStub(StringRef Name) {
  if (!Name.starts_with("ext_"))
    return std::nullopt;
  StringRef Rest = Name.drop_front(4);
  size_t Sep = Rest.find('_');
  if (Sep == StringRef::npos || Sep + 1 >= Rest.size())
    return std::nullopt;
  return Rest.drop_front(Sep + 1);
}

static std::optional<uint64_t> ExtractConstantPC(Value *V,
                                                  const DataLayout &DL) {
  if (!V)
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return CI->getZExtValue();
  if (auto *PtrToInt = dyn_cast<PtrToIntOperator>(V))
    return ExtractConstantPC(PtrToInt->getPointerOperand(), DL);
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt)
      return ExtractConstantPC(CE->getOperand(0), DL);
  }
  Value *Stripped = StripAlias(V);
  if (Stripped != V)
    return ExtractConstantPC(Stripped, DL);
  if (auto *GV = dyn_cast<GlobalValue>(V))
    return ParseAddressName(GV->getName());
  return std::nullopt;
}

static Function *FindExternalByPC(Module &M, uint64_t PC) {
  for (Function &F : M) {
    auto Parsed = ParseAddressName(F.getName());
    if (!Parsed || *Parsed != PC)
      continue;
    if (auto ExtName = ExternalNameFromExtStub(F.getName())) {
      if (Function *Ext = M.getFunction(*ExtName))
        return Ext;
    }
    if (F.isDeclaration())
      return &F;
  }
  for (GlobalAlias &Alias : M.aliases()) {
    auto Parsed = ParseAddressName(Alias.getName());
    if (!Parsed || *Parsed != PC)
      continue;
    if (auto ExtName = ExternalNameFromExtStub(Alias.getName())) {
      if (Function *Ext = M.getFunction(*ExtName))
        return Ext;
    }
    if (auto *F = dyn_cast<Function>(Alias.getAliasee()->stripPointerCasts())) {
      if (F->isDeclaration())
        return F;
    }
  }
  return nullptr;
}

// Pattern 1: __remill_function_call with ptrtoint(@extern_fn)
// Pattern 2: __remill_function_call with constant PC
static ExternCallTarget ResolveRemillCallTarget(Module &M, CallInst *CI,
                                                 const DataLayout &DL,
                                                 const LibcSignatureDB &SigDB) {
  ExternCallTarget Target;
  if (CI->arg_size() < 3)
    return Target;

  Value *PCVal = CI->getArgOperand(1);

  // Pattern 1: ptrtoint(@printf)
  Value *Ptr = nullptr;
  if (auto *PtrToInt = dyn_cast<PtrToIntOperator>(PCVal))
    Ptr = PtrToInt->getPointerOperand();
  else if (auto *CE = dyn_cast<ConstantExpr>(PCVal);
           CE && CE->getOpcode() == Instruction::PtrToInt)
    Ptr = CE->getOperand(0);

  if (Ptr) {
    Value *Stripped = StripAlias(Ptr);
    if (auto *F = dyn_cast<Function>(Stripped)) {
      // Check for ext_ stub pattern
      if (auto ExtName = ExternalNameFromExtStub(F->getName())) {
        if (Function *Ext = M.getFunction(*ExtName)) {
          Target.ExtFn = Ext;
          Target.SymbolName = ExtName->str();
          Target.Signature = SigDB.lookup(Target.SymbolName);
          Target.Resolved = true;
          return Target;
        }
      }
      if (F->isDeclaration() || SigDB.lookup(F->getName())) {
        Target.ExtFn = F;
        Target.SymbolName = F->getName().str();
        Target.Signature = SigDB.lookup(Target.SymbolName);
        Target.Resolved = true;
        return Target;
      }
    }
  }

  // Pattern 2: constant guest PC
  auto PC = ExtractConstantPC(PCVal, DL);
  if (PC) {
    if (Function *Ext = FindExternalByPC(M, *PC)) {
      StringRef ExtName = Ext->getName();
      if (auto Parsed = ExternalNameFromExtStub(ExtName)) {
        if (Function *RealExt = M.getFunction(*Parsed)) {
          Target.ExtFn = RealExt;
          Target.SymbolName = Parsed->str();
        } else {
          Target.ExtFn = Ext;
          Target.SymbolName = Parsed->str();
        }
      } else {
        Target.ExtFn = Ext;
        Target.SymbolName = Ext->getName().str();
      }
      Target.Signature = SigDB.lookup(Target.SymbolName);
      Target.Resolved = true;
      return Target;
    }
    Target.UnresolvedReason = "unresolved-external-pc";
    return Target;
  }

  Target.UnresolvedReason = "unresolved-external-target";
  return Target;
}

// Pattern 3: ext_ADDR_name stub call
static ExternCallTarget ResolveExtStubTarget(Module &M, Function *Callee,
                                              const LibcSignatureDB &SigDB) {
  ExternCallTarget Target;
  auto ExtName = ExternalNameFromExtStub(Callee->getName());
  if (!ExtName) {
    Target.UnresolvedReason = "unresolved-external-target";
    return Target;
  }
  Target.SymbolName = ExtName->str();
  Target.Signature = SigDB.lookup(Target.SymbolName);
  if (Function *Ext = M.getFunction(*ExtName)) {
    Target.ExtFn = Ext;
  }
  Target.Resolved = true;
  return Target;
}

static bool IsRemillFunction(Function *F) {
  return F && F->getName() == "__remill_function_call";
}

static bool IsExtStub(Function *F) {
  return F && F->getName().starts_with("ext_");
}

static bool LooksLikeRemillSignature(Function *F) {
  if (!F || F->arg_size() != 3)
    return false;
  if (!F->getReturnType()->isPointerTy())
    return false;
  auto It = F->arg_begin();
  Type *A0 = (It++)->getType();
  Type *A1 = (It++)->getType();
  Type *A2 = (It++)->getType();
  return A0->isPointerTy() && A1->isIntegerTy(64) && A2->isPointerTy();
}

// Pattern 4: sub_xxx.remill wrapper calling external
static ExternCallTarget ResolveRemillWrapperTarget(Module &M, Function *Callee,
                                                    const LibcSignatureDB &SigDB) {
  ExternCallTarget Target;
  StringRef Name = Callee->getName();

  // Check if this is a .remill wrapper
  if (!Name.ends_with(".remill") && !LooksLikeRemillSignature(Callee)) {
    Target.UnresolvedReason = "unresolved-external-target";
    return Target;
  }

  // Look inside the wrapper for external calls
  for (BasicBlock &BB : *Callee) {
    for (Instruction &I : BB) {
      auto *Inner = dyn_cast<CallInst>(&I);
      if (!Inner)
        continue;
      Function *InnerCallee = Inner->getCalledFunction();
      if (!InnerCallee)
        continue;
      if (InnerCallee->isDeclaration()) {
        const LibcSignature *Sig = SigDB.lookup(InnerCallee->getName());
        if (Sig) {
          Target.ExtFn = InnerCallee;
          Target.SymbolName = InnerCallee->getName().str();
          Target.Signature = Sig;
          Target.Resolved = true;
          return Target;
        }
      }
    }
  }

  Target.UnresolvedReason = "unresolved-external-target";
  return Target;
}

bool BrightenExternCallBridgePass::DiscoverExternalSymbols(
    ExternCallContext &Ctx) {
  Module &M = Ctx.M;
  const DataLayout &DL = Ctx.DL;
  Function *RemillCall = M.getFunction("__remill_function_call");

  unsigned Count = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;

        Function *Callee =
            dyn_cast_or_null<Function>(CI->getCalledOperand()->stripPointerCasts());
        if (!Callee)
          continue;

        ExternCallTarget Target;
        bool IsCandidate = false;

        if (IsRemillFunction(Callee)) {
          Target = ResolveRemillCallTarget(M, CI, DL, Ctx.SigDB);
          IsCandidate = true;
        } else if (IsExtStub(Callee) && LooksLikeRemillSignature(Callee)) {
          Target = ResolveExtStubTarget(M, Callee, Ctx.SigDB);
          IsCandidate = true;
        } else if (Callee->getName().ends_with(".remill") &&
                   LooksLikeRemillSignature(Callee)) {
          Target = ResolveRemillWrapperTarget(M, Callee, Ctx.SigDB);
          IsCandidate = true;
        }

        if (!IsCandidate)
          continue;

        if (!Target.Resolved || !Target.Signature) {
          if (Target.Resolved && !Target.Signature) {
            Target.UnresolvedReason = "unsupported-libc-symbol";
            Target.Resolved = false;
          }
        }

        auto CS = std::make_unique<ExternCallsite>();
        CS->OrigCall = CI;
        CS->Caller = &F;
        CS->Target = std::move(Target);
        Ctx.Callsites.push_back(std::move(CS));
        ++Count;
      }
    }
  }

  Ctx.Report.Discovered = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-extern] discovered " << Count
           << " external callsites\n";

  return Count > 0;
}

} // namespace brighten_extern
