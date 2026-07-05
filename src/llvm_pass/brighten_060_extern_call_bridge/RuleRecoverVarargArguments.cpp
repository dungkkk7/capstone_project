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
static constexpr uint64_t kGPArgOffsets[] = {2296, 2280, 2264, 2248, 2344, 2360};
static constexpr uint64_t kXMMArgOffsets[] = {16, 80, 144, 208, 272, 336, 400, 464};
static constexpr uint64_t kOffRSP = 2312;

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
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) continue;
    auto Off = IdentifyStateOffset(SI->getPointerOperand());
    if (Off && *Off == RegOffset) return SI->getValueOperand();
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
      auto Off = IdentifyStateOffset(SI->getPointerOperand());
      if (Off && *Off == RegOffset) return SI->getValueOperand();
    }

    for (BasicBlock *Pred : predecessors(BB)) {
      if (Visited.insert(Pred).second) {
        Worklist.push(Pred);
      }
    }
  }

  return nullptr;
}

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
  if (!V || Depth > 8) return PointerProvenance::Unknown;
  Value *Stripped = V->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(Stripped)) {
    if (GV->isConstant() && GV->hasInitializer()) {
      if (auto *CDA = dyn_cast<ConstantDataArray>(GV->getInitializer()))
        if (CDA->isString() || CDA->isCString() ||
            CDA->getElementType()->isIntegerTy(8))
          return PointerProvenance::NativeGlobalString;
    }
    return PointerProvenance::NativeGlobalObject;
  }
  if (auto *GEP = dyn_cast<GEPOperator>(Stripped)) {
    PointerProvenance Base =
        ClassifyPointerProvenance(GEP->getPointerOperand(), Depth + 1);
    if (Base != PointerProvenance::Unknown &&
        Base != PointerProvenance::GuestAddressConstant &&
        Base != PointerProvenance::GuestAddressDynamic)
      return Base;
  }
  if (isa<AllocaInst>(Stripped)) return PointerProvenance::NativeStackObject;
  if (auto *CI = dyn_cast<CallInst>(Stripped)) {
    if (Function *F = CI->getCalledFunction()) {
      StringRef Name = F->getName();
      if (Name == "malloc" || Name == "calloc" || Name == "realloc")
        return PointerProvenance::NativeHeapObject;
    }
  }
  if (auto *ITP = dyn_cast<IntToPtrInst>(Stripped)) {
    if (isa<ConstantInt>(ITP->getOperand(0)))
      return PointerProvenance::GuestAddressConstant;
    return ClassifyPointerProvenance(ITP->getOperand(0), Depth + 1);
  }
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
  if (auto *PTI = dyn_cast<PtrToIntInst>(Stripped))
    return ClassifyPointerProvenance(PTI->getOperand(0), Depth + 1);
  if (auto *Phi = dyn_cast<PHINode>(Stripped)) {
    if (Phi->getNumIncomingValues() == 0) return PointerProvenance::Unknown;
    PointerProvenance First =
        ClassifyPointerProvenance(Phi->getIncomingValue(0), Depth + 1);
    if (First == PointerProvenance::Unknown) return First;
    for (unsigned I = 1; I < Phi->getNumIncomingValues(); ++I)
      if (ClassifyPointerProvenance(Phi->getIncomingValue(I), Depth + 1) != First)
        return PointerProvenance::Unknown;
    return First;
  }
  if (auto *Sel = dyn_cast<SelectInst>(Stripped)) {
    PointerProvenance T = ClassifyPointerProvenance(Sel->getTrueValue(), Depth + 1);
    PointerProvenance F = ClassifyPointerProvenance(Sel->getFalseValue(), Depth + 1);
    if (T == F && T != PointerProvenance::Unknown) return T;
  }
  if (auto *Alias = dyn_cast<GlobalAlias>(Stripped))
    if (Constant *Aliasee = Alias->getAliasee())
      return ClassifyPointerProvenance(Aliasee, Depth + 1);
  return PointerProvenance::Unknown;
}

static bool IsNativeProvenance(PointerProvenance P) {
  return P == PointerProvenance::NativeGlobalString ||
         P == PointerProvenance::NativeGlobalObject ||
         P == PointerProvenance::NativeStackObject ||
         P == PointerProvenance::NativeHeapObject;
}

static Value *CoerceToType(IRBuilder<> &B, Value *V, Type *DstTy) {
  if (!V || !DstTy || V->getType() == DstTy) return V;
  Type *SrcTy = V->getType();
  if (SrcTy->isPointerTy() && DstTy->isPointerTy()) return V;
  if (SrcTy->isPointerTy() && DstTy->isIntegerTy()) return B.CreatePtrToInt(V, DstTy);
  if (SrcTy->isIntegerTy() && DstTy->isPointerTy()) return B.CreateIntToPtr(V, DstTy);
  if (SrcTy->isIntegerTy() && DstTy->isIntegerTy()) {
    unsigned SW = SrcTy->getIntegerBitWidth();
    unsigned DW = DstTy->getIntegerBitWidth();
    if (SW > DW) return B.CreateTrunc(V, DstTy);
    if (SW < DW) return B.CreateZExt(V, DstTy);
    return V;
  }
  if (SrcTy->isIntegerTy() && DstTy->isDoubleTy()) {
    Value *I64 = B.CreateZExtOrTrunc(V, B.getInt64Ty());
    return B.CreateBitCast(I64, DstTy);
  }
  return nullptr;
}

// FIX #5: Broader format string resolution
// Also trace through ptrtoint(@seg+off), interior pointers
static std::string ExtractStringFromConstant(Constant *C, uint64_t Offset, const DataLayout &DL) {
  if (!C) return "";

  // 1. ConstantDataSequential (ConstantDataArray, ConstantDataVector)
  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    if (Offset >= CDS->getNumElements() * CDS->getElementByteSize())
      return "";
    StringRef Raw = CDS->getRawDataValues();
    if (Offset < Raw.size()) {
      size_t NullPos = Raw.find('\0', Offset);
      if (NullPos != StringRef::npos)
        return Raw.substr(Offset, NullPos - Offset).str();
      return Raw.substr(Offset).str();
    }
    return "";
  }

  // 2. ConstantAggregateZero
  if (isa<ConstantAggregateZero>(C)) {
    return "";
  }

  // 3. ConstantStruct
  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    auto *STy = CS->getType();
    const StructLayout *SL = DL.getStructLayout(STy);
    if (Offset >= SL->getSizeInBytes())
      return "";
    unsigned ElemIdx = SL->getElementContainingOffset(Offset);
    uint64_t ElemOffset = SL->getElementOffset(ElemIdx);
    return ExtractStringFromConstant(CS->getOperand(ElemIdx), Offset - ElemOffset, DL);
  }

  // 4. ConstantArray
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    auto *ArrTy = CA->getType();
    uint64_t ElemSize = DL.getTypeAllocSize(ArrTy->getElementType());
    if (ElemSize == 0) return "";
    uint64_t ElemIdx = Offset / ElemSize;
    if (ElemIdx >= ArrTy->getNumElements())
      return "";
    return ExtractStringFromConstant(CA->getOperand(ElemIdx), Offset % ElemSize, DL);
  }

  return "";
}

static std::string ResolveFormatString(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 4) return "";
  V = V->stripPointerCasts();

  if (auto *GV = dyn_cast<GlobalVariable>(V)) {
    if (GV->isConstant() && GV->hasInitializer()) {
      Module *M = GV->getParent();
      if (M) {
        const DataLayout &DL = M->getDataLayout();
        return ExtractStringFromConstant(GV->getInitializer(), 0, DL);
      }
    }
  }

  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    Value *Base = GEP->getPointerOperand();
    if (auto *GV = dyn_cast<GlobalVariable>(Base->stripPointerCasts())) {
      if (GV->isConstant() && GV->hasInitializer()) {
        Module *M = GV->getParent();
        if (M) {
          const DataLayout &DL = M->getDataLayout();
          APInt Offset(DL.getPointerSizeInBits(), 0, true);
          if (GEP->accumulateConstantOffset(DL, Offset) &&
              !Offset.isNegative()) {
            return ExtractStringFromConstant(GV->getInitializer(), Offset.getZExtValue(), DL);
          }
        }
      }
    }
    bool AllZero = true;
    for (auto It = GEP->idx_begin(); It != GEP->idx_end(); ++It) {
      if (auto *CI = dyn_cast<ConstantInt>(*It)) {
        if (!CI->isZero()) { AllZero = false; break; }
      } else { AllZero = false; break; }
    }
    if (AllZero)
      return ResolveFormatString(GEP->getPointerOperand(), Depth + 1);
  }

  if (auto *ITP = dyn_cast<IntToPtrInst>(V))
    return ResolveFormatString(ITP->getOperand(0), Depth + 1);
  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return ResolveFormatString(PTI->getOperand(0), Depth + 1);

  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt ||
        CE->getOpcode() == Instruction::IntToPtr) {
      return ResolveFormatString(CE->getOperand(0), Depth + 1);
    }
  }

  // Trace through stack loads
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    Value *Ptr = LI->getPointerOperand()->stripPointerCasts();
    if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
      Value *Base = GEP->getPointerOperand()->stripPointerCasts();
      if (auto *AI = dyn_cast<AllocaInst>(Base)) {
        const DataLayout &DL = LI->getModule()->getDataLayout();
        APInt Offset(DL.getPointerSizeInBits(), 0, true);
        if (GEP->accumulateConstantOffset(DL, Offset) && !Offset.isNegative()) {
          Value *Stored = FindStoreToStackOffset(AI, Offset.getZExtValue(), LI, Depth + 1);
          if (Stored) {
            return ResolveFormatString(Stored, Depth + 1);
          }
        }
      }
    } else if (auto *AI = dyn_cast<AllocaInst>(Ptr)) {
      Value *Stored = FindStoreToStackOffset(AI, 0, LI, Depth + 1);
      if (Stored) {
        return ResolveFormatString(Stored, Depth + 1);
      }
    }
  }

  if (auto *Alias = dyn_cast<GlobalAlias>(V))
    if (Constant *Aliasee = Alias->getAliasee())
      return ResolveFormatString(Aliasee, Depth + 1);

  return "";
}

static unsigned FormatArgIndex(const LibcSignature &Sig) {
  switch (Sig.Special) {
  case LibcSpecialKind::PrintfLike:
  case LibcSpecialKind::ScanfLike: return 0;
  case LibcSpecialKind::FprintfLike:
  case LibcSpecialKind::FscanfLike:
  case LibcSpecialKind::SscanfLike: return 1;
  case LibcSpecialKind::SprintfLike: return 1;
  case LibcSpecialKind::SnprintfLike: return 2;
  default: return 0;
  }
}

static Type *VarargLLVMType(LLVMContext &Ctx, VarargType VT, bool IsScanf) {
  switch (VT) {
  case VarargType::IntI32:
  case VarargType::UintI32:
  case VarargType::CharI8:
    if (IsScanf) return PointerType::getUnqual(Ctx);
    return Type::getInt32Ty(Ctx);
  case VarargType::IntI64:
  case VarargType::UintI64:
    if (IsScanf) return PointerType::getUnqual(Ctx);
    return Type::getInt64Ty(Ctx);
  case VarargType::Pointer:
    return PointerType::getUnqual(Ctx);
  case VarargType::Double:
    if (IsScanf) return PointerType::getUnqual(Ctx);
    return Type::getDoubleTy(Ctx);
  case VarargType::WidthStar:
  case VarargType::PrecisionStar:
    return Type::getInt32Ty(Ctx);
  default:
    return Type::getInt64Ty(Ctx);
  }
}

// FIX #4: Try to recover stack args from Phase 4 stack objects
// In SysV ABI, stack args are at RSP+8, RSP+16, ... (after return address)
// We look for stores to the stack area before the call.
static Value *TryRecoverStackArg(CallInst *CI, unsigned StackIdx,
                                  IRBuilder<> &B) {
  // FIX #5: Outgoing stack argument recovery is unsafe without metadata.
  // We strictly skip stack guessing to prevent semantic drift.
  return nullptr;
}

bool BrightenExternCallBridgePass::RecoverVarargArguments(
    ExternCallContext &Ctx) {
  bool Changed = false;

  // Find __translate_guest_pointer if in compat mode
  if (Ctx.Mode == ExternRecoveryMode::CompatFallback) {
    Ctx.TranslateFn = Ctx.M.getFunction("__translate_guest_pointer");
    if (Ctx.TranslateFn && Ctx.TranslateFn->isDeclaration()) {
      // Keep it if signature matches (accept declaration-only)
    }
  }

  for (auto &CS : Ctx.Callsites) {
    if (!CS->Target.Resolved || !CS->Target.Signature)
      continue;
    const LibcSignature &Sig = *CS->Target.Signature;
    if (!Sig.IsVarArg)
      continue;
    if (!CS->SkipReason.empty())
      continue;

    CallInst *CI = CS->OrigCall;
    IRBuilder<> B(CI);
    LLVMContext &LCtx = Ctx.M.getContext();
    bool IsScanf = isScanfFamilyKind(Sig.Special);

    unsigned GPIdx = 0;
    unsigned XMMIdx = 0;
    bool FixedOk = true;

    for (const LibcParam &Param : Sig.FixedParams) {
      bool NeedFloat = (Param.Kind == LibcParamKind::Double ||
                        Param.Kind == LibcParamKind::Float);
      uint64_t RegOffset;
      if (NeedFloat) {
        if (XMMIdx >= 8) { FixedOk = false; break; }
        RegOffset = kXMMArgOffsets[XMMIdx++];
      } else {
        if (GPIdx >= 6) { FixedOk = false; break; }
        RegOffset = kGPArgOffsets[GPIdx++];
      }

      Value *StoredVal = FindStoreBeforeCall(CI, RegOffset);
      Type *ParamTy = Ctx.SigDB.paramType(LCtx, Param.Kind);
      RecoveredArg Arg;
      Arg.IsWritePointer = Param.IsWritePointer;

      if (StoredVal) {
        if (Param.isPointer()) {
          PointerProvenance Prov = ClassifyPointerProvenance(StoredVal);
          Arg.Provenance = Prov;
          if (Ctx.Mode == ExternRecoveryMode::NativeStrict &&
              !IsNativeProvenance(Prov)) {
            Arg.SkipReason = "arg-provenance-unknown";
            FixedOk = false;
            CS->Args.push_back(Arg);
            break;
          }
          Arg.Val = CoerceToType(B, StoredVal, ParamTy);
        } else {
          Arg.Val = CoerceToType(B, StoredVal, ParamTy);
        }
      } else {
        Type *LoadTy = NeedFloat ? Type::getDoubleTy(LCtx) :
                                    Type::getInt64Ty(LCtx);
        Value *StatePtr = CI->getArgOperand(0);
        Value *Ptr = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, RegOffset,
                                           "ext.fixarg.ptr");
        Value *Raw = B.CreateAlignedLoad(LoadTy, Ptr, Align(8), "ext.fixarg");
        if (Param.isPointer()) {
          Arg.Provenance = PointerProvenance::Unknown;
          if (Ctx.Mode == ExternRecoveryMode::NativeStrict) {
            Arg.SkipReason = "arg-provenance-unknown";
            FixedOk = false;
            CS->Args.push_back(Arg);
            break;
          }
        }
        Arg.Val = CoerceToType(B, Raw, ParamTy);
      }

      if (!Arg.Val) {
        Arg.SkipReason = "arg-type-conflict";
        FixedOk = false;
        CS->Args.push_back(Arg);
        break;
      }
      Arg.Ty = ParamTy;
      Arg.IsValid = true;
      CS->Args.push_back(Arg);
    }

    if (!FixedOk) {
      CS->Action = "preserve";
      if (CS->SkipReason.empty())
        CS->SkipReason = "unsupported-vararg-format";
      continue;
    }

    // Resolve format string
    unsigned FmtIdx = FormatArgIndex(Sig);
    if (FmtIdx >= CS->Args.size()) {
      CS->Action = "preserve";
      CS->SkipReason = "format-not-constant";
      continue;
    }

    // FIX #5: Try multiple sources for format string
    Value *FmtVal = CS->Args[FmtIdx].Val;
    std::string FmtStr = ResolveFormatString(FmtVal);
    if (FmtStr.empty()) {
      uint64_t FmtRegOff = kGPArgOffsets[FmtIdx];
      Value *StoredFmt = FindStoreBeforeCall(CI, FmtRegOff);
      if (StoredFmt)
        FmtStr = ResolveFormatString(StoredFmt);
    }

    if (FmtStr.empty()) {
      CS->Action = "preserve";
      CS->SkipReason = "format-not-constant";
      continue;
    }

    // FIX #3: Pass IsScanfFamily to parser
    SmallVector<VarargSpecifier, 16> Specs;
    StringRef FmtRef(FmtStr);
    if (!FmtRef.empty() && FmtRef.back() == '\0')
      FmtRef = FmtRef.drop_back();

    if (!parseFormatString(FmtRef, Specs, IsScanf)) {
      CS->Action = "preserve";
      CS->SkipReason = "unsupported-vararg-format";
      continue;
    }

    CS->Vararg.FormatResolved = true;
    CS->Vararg.FormatString = FmtStr;
    CS->Vararg.Specifiers = std::move(Specs);
    ++Ctx.Report.FormatStringsRecovered;

    // FIX #3/#4: Recover vararg values with scanf suppression awareness
    // and stack arg fallback
    bool VarargOk = true;
    unsigned StackArgIdx = 0;

    for (const VarargSpecifier &Spec : CS->Vararg.Specifiers) {
      if (Spec.Ty == VarargType::Percent || Spec.Ty == VarargType::ScanfSuppressed)
        continue;
      if (!Spec.ConsumesArg)
        continue;

      Type *VATy = VarargLLVMType(LCtx, Spec.Ty, IsScanf);
      bool UseXMM = Spec.UsesXMMReg && !IsScanf;

      RecoveredArg VArg;
      VArg.Ty = VATy;

      // Determine register source
      bool FromStack = false;
      uint64_t RegOffset;
      if (UseXMM) {
        if (XMMIdx >= 8) {
          // FIX #4: XMM overflow → skip (no stack recovery for floats yet)
          VArg.SkipReason = "xmm-arg-unavailable";
          VarargOk = false;
          CS->Args.push_back(VArg);
          break;
        }
        RegOffset = kXMMArgOffsets[XMMIdx++];
      } else {
        if (GPIdx >= 6) {
          // FIX #4: Try stack arg recovery
          FromStack = true;
        } else {
          RegOffset = kGPArgOffsets[GPIdx++];
        }
      }

      Value *StoredVal = nullptr;
      if (FromStack) {
        StoredVal = TryRecoverStackArg(CI, StackArgIdx, B);
        ++StackArgIdx;
        if (!StoredVal) {
          VArg.SkipReason = "stack-arg-unavailable";
          VarargOk = false;
          CS->Args.push_back(VArg);
          break;
        }
      } else {
        StoredVal = FindStoreBeforeCall(CI, RegOffset);
      }

      Value *StatePtr = CI->getArgOperand(0);

      bool NeedVarargPointer = (VATy->isPointerTy() || IsScanf);
      if (StoredVal) {
        if (NeedVarargPointer) {
          PointerProvenance Prov = ClassifyPointerProvenance(StoredVal);
          VArg.Provenance = Prov;
          if (IsScanf) VArg.IsWritePointer = true;
          if (Ctx.Mode == ExternRecoveryMode::NativeStrict &&
              !IsNativeProvenance(Prov)) {
            VArg.SkipReason = "arg-provenance-unknown";
            VarargOk = false;
            CS->Args.push_back(VArg);
            break;
          }
          if (!IsNativeProvenance(Prov) && Ctx.Mode == ExternRecoveryMode::CompatFallback && Ctx.TranslateFn) {
            Value *IntVal = StoredVal;
            if (IntVal->getType()->isPointerTy())
              IntVal = B.CreatePtrToInt(IntVal, B.getInt64Ty());
            else
              IntVal = CoerceToType(B, IntVal, B.getInt64Ty());
            Value *Translated = (Ctx.TranslateFn->getFunctionType()->getNumParams() == 1) ?
            B.CreateCall(Ctx.TranslateFn, {IntVal}, "translated_ptr") :
            B.CreateCall(Ctx.TranslateFn, {IntVal, B.getInt1(IsScanf)}, "translated_ptr");
            VArg.Val = Translated;
            VArg.IsFallbackTranslated = true;
          } else {
            VArg.Val = CoerceToType(B, StoredVal, VATy);
          }
        } else {
          VArg.Val = CoerceToType(B, StoredVal, VATy);
        }
      } else if (!FromStack) {
        Type *LoadTy = UseXMM ? Type::getDoubleTy(LCtx) :
                                 Type::getInt64Ty(LCtx);
        Value *Ptr = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, RegOffset,
                                           "ext.varg.ptr");
        Value *Raw = B.CreateAlignedLoad(LoadTy, Ptr, Align(8), "ext.varg");
        if (NeedVarargPointer) {
          VArg.Provenance = PointerProvenance::Unknown;
          if (Ctx.Mode == ExternRecoveryMode::NativeStrict) {
            VArg.SkipReason = "arg-provenance-unknown";
            VarargOk = false;
            CS->Args.push_back(VArg);
            break;
          }
          if (Ctx.Mode == ExternRecoveryMode::CompatFallback && Ctx.TranslateFn) {
            Value *IntVal = CoerceToType(B, Raw, B.getInt64Ty());
            Value *Translated = (Ctx.TranslateFn->getFunctionType()->getNumParams() == 1) ?
            B.CreateCall(Ctx.TranslateFn, {IntVal}, "translated_ptr") :
            B.CreateCall(Ctx.TranslateFn, {IntVal, B.getInt1(IsScanf)}, "translated_ptr");
            VArg.Val = Translated;
            VArg.IsFallbackTranslated = true;
          } else {
            VArg.SkipReason = "arg-provenance-unknown";
            VarargOk = false;
            CS->Args.push_back(VArg);
            break;
          }
        } else {
          VArg.Val = CoerceToType(B, Raw, VATy);
        }
      }

      if (!VArg.Val) {
        VArg.SkipReason = "arg-type-conflict";
        VarargOk = false;
        CS->Args.push_back(VArg);
        break;
      }
      VArg.IsValid = true;
      CS->Args.push_back(VArg);
    }

    if (!VarargOk) {
      CS->Action = "preserve";
      if (CS->SkipReason.empty()) {
        for (auto &A : CS->Args)
          if (!A.SkipReason.empty()) { CS->SkipReason = A.SkipReason; break; }
      }
      continue;
    }

    ++Ctx.Report.VarargRecovered;
    Changed = true;
  }

  return Changed;
}

} // namespace brighten_extern
