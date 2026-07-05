#include "BrightenExternCallBridgePass.h"
#include <queue>
#include <set>
#include "llvm/IR/CFG.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_extern {

using namespace llvm;

static constexpr uint64_t kOffRAX = 2216;
static constexpr uint64_t kOffRDI = 2296;
static constexpr uint64_t kOffRSI = 2280;
static constexpr uint64_t kOffRDX = 2264;
static constexpr uint64_t kOffRCX = 2248;
static constexpr uint64_t kOffR8 = 2344;
static constexpr uint64_t kOffR9 = 2360;
static constexpr uint64_t kOffXMM0 = 16;
static constexpr uint64_t kOffXMM1 = 80;
static constexpr uint64_t kOffXMM2 = 144;
static constexpr uint64_t kOffXMM3 = 208;
static constexpr uint64_t kOffXMM4 = 272;
static constexpr uint64_t kOffXMM5 = 336;
static constexpr uint64_t kOffXMM6 = 400;
static constexpr uint64_t kOffXMM7 = 464;

static const uint64_t kGPArgOffsets[] = {kOffRDI, kOffRSI, kOffRDX,
                                          kOffRCX, kOffR8,  kOffR9};
static const uint64_t kXMMArgOffsets[] = {kOffXMM0, kOffXMM1, kOffXMM2,
                                           kOffXMM3, kOffXMM4, kOffXMM5,
                                           kOffXMM6, kOffXMM7};

static Module *FindModule(Value *V) {
  if (!V) return nullptr;
  if (auto *I = dyn_cast<Instruction>(V)) return I->getModule();
  if (auto *GV = dyn_cast<GlobalValue>(V)) return GV->getParent();
  if (auto *Arg = dyn_cast<Argument>(V)) {
    if (Arg->getParent()) return Arg->getParent()->getParent();
  }
  if (auto *GEP = dyn_cast<GEPOperator>(V)) return FindModule(GEP->getPointerOperand());
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands()) {
      if (Module *M = FindModule(Op)) return M;
    }
  }
  return nullptr;
}

static std::optional<uint64_t> IdentifyStateOffset(Value *Ptr) {
  if (!Ptr)
    return std::nullopt;

  Value *Stripped = Ptr->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalValue>(Stripped)) {
    StringRef Name = GV->getName();
    if (Name == "RAX" || Name == "rax") return 2216;
    if (Name == "RDI" || Name == "rdi") return 2296;
    if (Name == "RSI" || Name == "rsi") return 2280;
    if (Name == "RDX" || Name == "rdx") return 2264;
    if (Name == "RCX" || Name == "rcx") return 2248;
    if (Name == "R8" || Name == "r8") return 2344;
    if (Name == "R9" || Name == "r9") return 2360;
    if (Name == "RSP" || Name == "rsp") return 2312;
    if (Name == "RBP" || Name == "rbp") return 2328;

    // Parse offset from whitelisted register variable names like RDI_2296_xxxx
    bool ValidPrefix = Name.starts_with("RAX_") || Name.starts_with("rax_") ||
                       Name.starts_with("RDI_") || Name.starts_with("rdi_") ||
                       Name.starts_with("RSI_") || Name.starts_with("rsi_") ||
                       Name.starts_with("RDX_") || Name.starts_with("rdx_") ||
                       Name.starts_with("RCX_") || Name.starts_with("rcx_") ||
                       Name.starts_with("R8_")  || Name.starts_with("r8_")  ||
                       Name.starts_with("R9_")  || Name.starts_with("r9_")  ||
                       Name.starts_with("RSP_") || Name.starts_with("rsp_") ||
                       Name.starts_with("RBP_") || Name.starts_with("rbp_") ||
                       Name.starts_with("XMM")  || Name.starts_with("xmm");
    if (ValidPrefix) {
      size_t Underscore1 = Name.find('_');
      if (Underscore1 != StringRef::npos) {
        size_t Underscore2 = Name.find('_', Underscore1 + 1);
        StringRef NumStr = (Underscore2 != StringRef::npos) 
          ? Name.substr(Underscore1 + 1, Underscore2 - Underscore1 - 1)
          : Name.substr(Underscore1 + 1);
        uint64_t Val;
        if (!NumStr.getAsInteger(10, Val)) {
          return Val;
        }
      }
    }
  }

  Module *M = FindModule(Stripped);
  if (!M)
    return std::nullopt;

  const DataLayout &DL = M->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Stripped->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (!Base || Offset.isNegative())
    return std::nullopt;

  Base = Base->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(Base)) {
    if (Constant *Aliasee = Alias->getAliasee())
      Base = Aliasee->stripPointerCasts();
  }
  auto *GV = dyn_cast<GlobalValue>(Base);
  if (!GV)
    return std::nullopt;
  if (GV->getName() == "__mcsema_reg_state")
    return Offset.getZExtValue();

  // Also parse offset if the base variable itself has offset encoded in its name
  StringRef BaseName = GV->getName();
  bool ValidBasePrefix = BaseName.starts_with("RAX_") || BaseName.starts_with("rax_") ||
                         BaseName.starts_with("RDI_") || BaseName.starts_with("rdi_") ||
                         BaseName.starts_with("RSI_") || BaseName.starts_with("rsi_") ||
                         BaseName.starts_with("RDX_") || BaseName.starts_with("rdx_") ||
                         BaseName.starts_with("RCX_") || BaseName.starts_with("rcx_") ||
                         BaseName.starts_with("R8_")  || BaseName.starts_with("r8_")  ||
                         BaseName.starts_with("R9_")  || BaseName.starts_with("r9_")  ||
                         BaseName.starts_with("RSP_") || BaseName.starts_with("rsp_") ||
                         BaseName.starts_with("RBP_") || BaseName.starts_with("rbp_") ||
                         BaseName.starts_with("XMM")  || BaseName.starts_with("xmm");
  if (ValidBasePrefix) {
    size_t Underscore1 = BaseName.find('_');
    if (Underscore1 != StringRef::npos) {
      size_t Underscore2 = BaseName.find('_', Underscore1 + 1);
      StringRef NumStr = (Underscore2 != StringRef::npos) 
        ? BaseName.substr(Underscore1 + 1, Underscore2 - Underscore1 - 1)
        : BaseName.substr(Underscore1 + 1);
      uint64_t Val;
      if (!NumStr.getAsInteger(10, Val)) {
        return Val + Offset.getZExtValue();
      }
    }
  }

  if (auto *Arg = dyn_cast<Argument>(Base)) {
    if (Arg->getArgNo() == 0) {
      return Offset.getZExtValue();
    }
  }

  return std::nullopt;
}

static Value *FindStoreBeforeCall(CallInst *CI, uint64_t RegOffset) {
  BasicBlock *StartBB = CI->getParent();
  for (auto It = BasicBlock::reverse_iterator(CI->getIterator());
       It != StartBB->rend(); ++It) {
    Instruction &I = *It;
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI)
      continue;
    auto Off = IdentifyStateOffset(SI->getPointerOperand());
    if (Off && *Off == RegOffset)
      return SI->getValueOperand();
  }

  std::queue<BasicBlock *> Worklist;
  std::set<BasicBlock *> Visited;
  for (BasicBlock *Pred : predecessors(StartBB)) {
    Worklist.push(Pred);
    Visited.insert(Pred);
  }

  unsigned BlocksVisited = 0;
  while (!Worklist.empty() && BlocksVisited < 32) {
    BasicBlock *BB = Worklist.front();
    Worklist.pop();
    BlocksVisited++;

    for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
      Instruction &I = *It;
      auto *SI = dyn_cast<StoreInst>(&I);
      if (!SI)
        continue;
      auto Off = IdentifyStateOffset(SI->getPointerOperand());
      if (Off && *Off == RegOffset)
        return SI->getValueOperand();
    }

    for (BasicBlock *Pred : predecessors(BB)) {
      if (Visited.insert(Pred).second) {
        Worklist.push(Pred);
      }
    }
  }

  return nullptr;
}

// FIX #6: Deeper pointer provenance tracing
// Traces through ptrtoint/inttoptr chains, PHI nodes (single-source),
// select, aliases, GEP chains, bitcasts.
static Value *FindStoreToStackOffset(AllocaInst *AI, uint64_t Offset, Instruction *Before, unsigned Depth) {
  if (Depth > 4 || !Before) return nullptr;
  BasicBlock *StartBB = Before->getParent();
  const DataLayout &DL = StartBB->getModule()->getDataLayout();

  for (auto It = BasicBlock::reverse_iterator(Before->getIterator());
       It != StartBB->rend(); ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) continue;

    Value *Ptr = SI->getPointerOperand()->stripPointerCasts();
    if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
      if (GEP->getPointerOperand()->stripPointerCasts() == AI) {
        APInt Off(DL.getPointerSizeInBits(), 0, true);
        if (GEP->accumulateConstantOffset(DL, Off) && !Off.isNegative() &&
            Off.getZExtValue() == Offset) {
          return SI->getValueOperand();
        }
      }
    } else if (Ptr == AI && Offset == 0) {
      return SI->getValueOperand();
    }
  }

  std::queue<BasicBlock *> Worklist;
  std::set<BasicBlock *> Visited;
  for (BasicBlock *Pred : predecessors(StartBB)) {
    Worklist.push(Pred);
    Visited.insert(Pred);
  }

  unsigned BlocksVisited = 0;
  while (!Worklist.empty() && BlocksVisited < 32) {
    BasicBlock *BB = Worklist.front();
    Worklist.pop();
    BlocksVisited++;

    for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
      auto *SI = dyn_cast<StoreInst>(&*It);
      if (!SI) continue;

      Value *Ptr = SI->getPointerOperand()->stripPointerCasts();
      if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
        if (GEP->getPointerOperand()->stripPointerCasts() == AI) {
          APInt Off(DL.getPointerSizeInBits(), 0, true);
          if (GEP->accumulateConstantOffset(DL, Off) && !Off.isNegative() &&
              Off.getZExtValue() == Offset) {
            return SI->getValueOperand();
          }
        }
      } else if (Ptr == AI && Offset == 0) {
        return SI->getValueOperand();
      }
    }

    for (BasicBlock *Pred : predecessors(BB)) {
      if (Visited.insert(Pred).second) {
        Worklist.push(Pred);
      }
    }
  }

  return nullptr;
}

static PointerProvenance ClassifyPointerProvenance(Value *V, unsigned Depth = 0);
static PointerProvenance ClassifyPointerProvenance(Value *V, unsigned Depth) {
  if (!V || Depth > 8)
    return PointerProvenance::Unknown;

  Value *Stripped = V->stripPointerCasts();

  // Global string constant
  if (auto *GV = dyn_cast<GlobalVariable>(Stripped)) {
    if (GV->isConstant() && GV->hasInitializer()) {
      Constant *Init = GV->getInitializer();
      if (auto *CDA = dyn_cast<ConstantDataArray>(Init)) {
        // Verify null-terminated string for NativeGlobalString
        if (CDA->isString() || CDA->isCString())
          return PointerProvenance::NativeGlobalString;
        if (CDA->getElementType()->isIntegerTy(8))
          return PointerProvenance::NativeGlobalString;
      }
      if (isa<ConstantDataVector>(Init))
        return PointerProvenance::NativeGlobalObject;
    }
    return PointerProvenance::NativeGlobalObject;
  }

  // GEP into known base
  if (auto *GEP = dyn_cast<GEPOperator>(Stripped)) {
    PointerProvenance Base =
        ClassifyPointerProvenance(GEP->getPointerOperand(), Depth + 1);
    if (Base == PointerProvenance::NativeGlobalString ||
        Base == PointerProvenance::NativeGlobalObject ||
        Base == PointerProvenance::NativeStackObject ||
        Base == PointerProvenance::NativeHeapObject)
      return Base;
  }

  // Alloca = native stack
  if (isa<AllocaInst>(Stripped))
    return PointerProvenance::NativeStackObject;

  // malloc/calloc/realloc return
  if (auto *CI = dyn_cast<CallInst>(Stripped)) {
    Function *Callee = CI->getCalledFunction();
    if (Callee) {
      StringRef Name = Callee->getName();
      if (Name == "malloc" || Name == "calloc" || Name == "realloc")
        return PointerProvenance::NativeHeapObject;
    }
  }

  // inttoptr of constant = guest address constant
  if (auto *ITP = dyn_cast<IntToPtrInst>(Stripped)) {
    if (isa<ConstantInt>(ITP->getOperand(0)))
      return PointerProvenance::GuestAddressConstant;
    // Trace through the integer source
    return ClassifyPointerProvenance(ITP->getOperand(0), Depth + 1);
  }

  // Constant expression inttoptr/ptrtoint
  if (auto *CE = dyn_cast<ConstantExpr>(Stripped)) {
    if (CE->getOpcode() == Instruction::PtrToInt) {
      return ClassifyPointerProvenance(CE->getOperand(0), Depth + 1);
    }
    if (CE->getOpcode() == Instruction::IntToPtr) {
      if (isa<ConstantInt>(CE->getOperand(0)))
        return PointerProvenance::GuestAddressConstant;
      return PointerProvenance::GuestAddressDynamic;
    }
  }

  // Trace through stack loads
  if (auto *LI = dyn_cast<LoadInst>(Stripped)) {
    Value *Ptr = LI->getPointerOperand()->stripPointerCasts();
    if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
      Value *Base = GEP->getPointerOperand()->stripPointerCasts();
      if (auto *AI = dyn_cast<AllocaInst>(Base)) {
        const DataLayout &DL = LI->getModule()->getDataLayout();
        APInt Offset(DL.getPointerSizeInBits(), 0, true);
        if (GEP->accumulateConstantOffset(DL, Offset) && !Offset.isNegative()) {
          Value *Stored = FindStoreToStackOffset(AI, Offset.getZExtValue(), LI, Depth + 1);
          if (Stored) {
            return ClassifyPointerProvenance(Stored, Depth + 1);
          }
        }
      }
    } else if (auto *AI = dyn_cast<AllocaInst>(Ptr)) {
      Value *Stored = FindStoreToStackOffset(AI, 0, LI, Depth + 1);
      if (Stored) {
        return ClassifyPointerProvenance(Stored, Depth + 1);
      }
    }
  }

  // ptrtoint: trace through to the pointer source
  if (auto *PTI = dyn_cast<PtrToIntInst>(Stripped)) {
    return ClassifyPointerProvenance(PTI->getOperand(0), Depth + 1);
  }

  // PHI node: if all incoming values have same provenance, use it
  if (auto *Phi = dyn_cast<PHINode>(Stripped)) {
    if (Phi->getNumIncomingValues() == 0)
      return PointerProvenance::Unknown;
    PointerProvenance First =
        ClassifyPointerProvenance(Phi->getIncomingValue(0), Depth + 1);
    if (First == PointerProvenance::Unknown)
      return PointerProvenance::Unknown;
    for (unsigned I = 1; I < Phi->getNumIncomingValues(); ++I) {
      PointerProvenance P =
          ClassifyPointerProvenance(Phi->getIncomingValue(I), Depth + 1);
      if (P != First)
        return PointerProvenance::Unknown;
    }
    return First;
  }

  // Select: if both arms have same provenance
  if (auto *Sel = dyn_cast<SelectInst>(Stripped)) {
    PointerProvenance T =
        ClassifyPointerProvenance(Sel->getTrueValue(), Depth + 1);
    PointerProvenance F =
        ClassifyPointerProvenance(Sel->getFalseValue(), Depth + 1);
    if (T == F && T != PointerProvenance::Unknown)
      return T;
  }

  // GlobalAlias
  if (auto *Alias = dyn_cast<GlobalAlias>(Stripped)) {
    if (Constant *Aliasee = Alias->getAliasee())
      return ClassifyPointerProvenance(Aliasee, Depth + 1);
  }

  return PointerProvenance::Unknown;
}

static bool IsNativeProvenance(PointerProvenance P) {
  return P == PointerProvenance::NativeGlobalString ||
         P == PointerProvenance::NativeGlobalObject ||
         P == PointerProvenance::NativeStackObject ||
         P == PointerProvenance::NativeHeapObject;
}

static Value *CoerceToType(IRBuilder<> &B, Value *V, Type *DstTy) {
  if (!V || !DstTy || V->getType() == DstTy)
    return V;
  Type *SrcTy = V->getType();

  if (SrcTy->isPointerTy() && DstTy->isPointerTy())
    return V;
  if (SrcTy->isPointerTy() && DstTy->isIntegerTy())
    return B.CreatePtrToInt(V, DstTy);
  if (SrcTy->isIntegerTy() && DstTy->isPointerTy())
    return B.CreateIntToPtr(V, DstTy);
  if (SrcTy->isIntegerTy() && DstTy->isIntegerTy()) {
    unsigned SW = SrcTy->getIntegerBitWidth();
    unsigned DW = DstTy->getIntegerBitWidth();
    if (SW > DW) return B.CreateTrunc(V, DstTy);
    if (SW < DW) return B.CreateZExt(V, DstTy);
    return V;
  }
  if (SrcTy->isIntegerTy() && DstTy->isDoubleTy()) {
    Value *Trunc = V;
    if (SrcTy->getIntegerBitWidth() != 64)
      Trunc = B.CreateZExtOrTrunc(V, B.getInt64Ty());
    return B.CreateBitCast(Trunc, DstTy);
  }
  if (SrcTy->isIntegerTy() && DstTy->isFloatTy()) {
    Value *Trunc = B.CreateTrunc(V, B.getInt32Ty());
    return B.CreateBitCast(Trunc, DstTy);
  }
  return nullptr;
}

static RecoveredArg RecoverFixedArg(ExternCallContext &Ctx, CallInst *CI,
                                     const LibcParam &Param,
                                     unsigned GPIdx, unsigned XMMIdx,
                                     IRBuilder<> &B) {
  RecoveredArg Arg;
  Arg.IsWritePointer = Param.IsWritePointer;

  Value *StatePtr = CI->getArgOperand(0);
  bool NeedPointer = Param.isPointer();
  bool NeedFloat = (Param.Kind == LibcParamKind::Double ||
                    Param.Kind == LibcParamKind::Float);

  uint64_t RegOffset;
  if (NeedFloat) {
    if (XMMIdx >= 8) {
      Arg.SkipReason = "xmm-arg-unavailable";
      return Arg;
    }
    RegOffset = kXMMArgOffsets[XMMIdx];
  } else {
    if (GPIdx >= 6) {
      Arg.SkipReason = "stack-arg-unavailable";
      return Arg;
    }
    RegOffset = kGPArgOffsets[GPIdx];
  }

  Value *StoredVal = FindStoreBeforeCall(CI, RegOffset);
  Type *TargetTy = Ctx.SigDB.paramType(Ctx.M.getContext(), Param.Kind);

  if (StoredVal) {
    if (NeedPointer) {
      PointerProvenance Prov = ClassifyPointerProvenance(StoredVal);
      Arg.Provenance = Prov;

      if (Ctx.Mode == ExternRecoveryMode::NativeStrict &&
          !IsNativeProvenance(Prov)) {
        Arg.SkipReason = "arg-provenance-unknown";
        return Arg;
      }

      if (!IsNativeProvenance(Prov) &&
          Ctx.Mode == ExternRecoveryMode::CompatFallback && Ctx.TranslateFn) {
        Value *IntVal = StoredVal;
        if (IntVal->getType()->isPointerTy())
          IntVal = B.CreatePtrToInt(IntVal, B.getInt64Ty());
        else
          IntVal = CoerceToType(B, IntVal, B.getInt64Ty());
        if (!IntVal) {
          Arg.SkipReason = "arg-type-conflict";
          return Arg;
        }
        Value *Translated =
            B.CreateCall(Ctx.TranslateFn,
                         {IntVal, B.getInt1(Param.IsWritePointer)},
                         "translated_ptr");
        Arg.Val = Translated;
        Arg.Ty = TargetTy;
        Arg.IsFallbackTranslated = true;
        Arg.IsValid = true;
        return Arg;
      }

      Arg.Val = CoerceToType(B, StoredVal, TargetTy);
      if (!Arg.Val) {
        Arg.SkipReason = "arg-type-conflict";
        return Arg;
      }
    } else {
      Arg.Val = CoerceToType(B, StoredVal, TargetTy);
      if (!Arg.Val) {
        Arg.SkipReason = "arg-type-conflict";
        return Arg;
      }
    }
  } else {
    Type *LoadTy = NeedFloat ? Type::getDoubleTy(Ctx.M.getContext())
                              : Type::getInt64Ty(Ctx.M.getContext());
    Value *Raw = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, RegOffset,
                                       "ext.arg.ptr");
    Raw = B.CreateAlignedLoad(LoadTy, Raw, Align(8), "ext.arg");

    if (NeedPointer) {
      Arg.Provenance = PointerProvenance::Unknown;
      if (Ctx.Mode == ExternRecoveryMode::NativeStrict) {
        Arg.SkipReason = "arg-provenance-unknown";
        return Arg;
      }
      if (Ctx.Mode == ExternRecoveryMode::CompatFallback && Ctx.TranslateFn) {
        Value *IntVal = CoerceToType(B, Raw, B.getInt64Ty());
        if (!IntVal) {
          Arg.SkipReason = "arg-type-conflict";
          return Arg;
        }
        Value *Translated =
            B.CreateCall(Ctx.TranslateFn,
                         {IntVal, B.getInt1(Param.IsWritePointer)},
                         "translated_ptr");
        Arg.Val = Translated;
        Arg.Ty = TargetTy;
        Arg.IsFallbackTranslated = true;
        Arg.IsValid = true;
        return Arg;
      }
      Arg.SkipReason = "arg-provenance-unknown";
      return Arg;
    }

    Arg.Val = CoerceToType(B, Raw, TargetTy);
    if (!Arg.Val) {
      Arg.SkipReason = "arg-type-conflict";
      return Arg;
    }
  }

  Arg.Ty = TargetTy;
  Arg.IsValid = true;
  return Arg;
}

// FIX #2: Accept __translate_guest_pointer even if only a declaration,
// as long as the function type matches (i64, i1) -> ptr.
static Function *FindTranslateGuestPointer(Module &M) {
  Function *F = M.getFunction("__translate_guest_pointer");
  if (!F)
    return nullptr;
  FunctionType *FTy = F->getFunctionType();
  LLVMContext &Ctx = M.getContext();
  // Expected: ptr (i64, i1)
  if (FTy->getNumParams() != 2)
    return nullptr;
  if (!FTy->getReturnType()->isPointerTy())
    return nullptr;
  if (!FTy->getParamType(0)->isIntegerTy(64))
    return nullptr;
  if (!FTy->getParamType(1)->isIntegerTy(1))
    return nullptr;
  return F;
}

bool BrightenExternCallBridgePass::AnalyzeExternalCallsites(
    ExternCallContext &Ctx) {
  for (auto &CS : Ctx.Callsites) {
    if (!CS->Target.Resolved) {
      CS->SkipReason = CS->Target.UnresolvedReason;
      CS->Action = "preserve";
    }
  }
  return false;
}

bool BrightenExternCallBridgePass::RecoverLibcArguments(
    ExternCallContext &Ctx) {
  bool Changed = false;

  // FIX #2: Accept declaration-only __translate_guest_pointer if type matches
  if (Ctx.Mode == ExternRecoveryMode::CompatFallback) {
    Ctx.TranslateFn = FindTranslateGuestPointer(Ctx.M);
  }

  for (auto &CS : Ctx.Callsites) {
    if (!CS->Target.Resolved || !CS->Target.Signature)
      continue;
    if (CS->Target.Signature->IsVarArg)
      continue;

    const LibcSignature &Sig = *CS->Target.Signature;
    CallInst *CI = CS->OrigCall;
    IRBuilder<> B(CI);

    unsigned GPIdx = 0;
    unsigned XMMIdx = 0;
    bool AllValid = true;

    for (const LibcParam &Param : Sig.FixedParams) {
      bool NeedFloat = (Param.Kind == LibcParamKind::Double ||
                        Param.Kind == LibcParamKind::Float);
      RecoveredArg Arg = RecoverFixedArg(Ctx, CI, Param, GPIdx, XMMIdx, B);
      CS->Args.push_back(Arg);
      if (!Arg.IsValid) {
        AllValid = false;
        if (CS->SkipReason.empty())
          CS->SkipReason = Arg.SkipReason;
      }
      if (NeedFloat)
        ++XMMIdx;
      else
        ++GPIdx;
    }

    if (!AllValid) {
      CS->Action = "preserve";
    }
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_extern
