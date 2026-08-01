#include "BrightenExternCallBridgePass.h"
#include <limits>
#include <queue>
#include <set>
#include "llvm/IR/CFG.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Analysis/CaptureTracking.h"
#include "llvm/IR/InstIterator.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_extern {

using namespace llvm;

static constexpr uint64_t kOffRAX = 2216;
static constexpr uint64_t kGPArgOffsets[] = {2296, 2280, 2264, 2248, 2344, 2360};
static constexpr uint64_t kXMMArgOffsets[] = {16, 80, 144, 208, 272, 336, 400, 464};
static constexpr uint64_t kOffRSP = 2312;

static cl::opt<bool> TraceMaterializedVAList(
    "brighten-extern-trace-materialized-valist", cl::Hidden,
    cl::desc("Report fail-closed reasons for materialized va_list lowering"),
    cl::init(false));

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

  // A store in an arbitrary predecessor does not necessarily dominate this
  // callsite.  In flattened CFGs the old BFS selected one unrelated branch's
  // register value, corrupting recovered varargs.  Fall back to the State
  // value at the call boundary unless a same-block store proves the value.
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

  if (PointerMayBeCaptured(AI, true)) return nullptr;
  DominatorTree DT(*Before->getFunction());
  StoreInst *Best = nullptr;
  for (Instruction &I : instructions(*Before->getFunction())) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || !DT.dominates(SI, Before)) continue;
    Value *Ptr = SI->getPointerOperand()->stripPointerCasts();
    bool Exact = Ptr == AI && Offset == 0;
    if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
      APInt Off(DL.getPointerSizeInBits(), 0, true);
      Exact = GEP->getPointerOperand()->stripPointerCasts() == AI &&
              GEP->accumulateConstantOffset(DL, Off) && !Off.isNegative() &&
              Off.getZExtValue() == Offset;
    }
    if (!Exact) continue;
    if (!Best || DT.dominates(Best, SI)) Best = SI;
  }
  return Best ? Best->getValueOperand() : nullptr;
}

static Value *FindSameBlockRegisterStore(LoadInst *LI);

static bool IsNativeProvenance(PointerProvenance P);
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
  // Integer-preserved native pointers remain native through ordinary affine
  // byte arithmetic.  Require exactly one native carrier; a guest-address
  // carrier or subtraction of two pointers is not a pointer provenance proof.
  if (auto *BO = dyn_cast<BinaryOperator>(Stripped)) {
    PointerProvenance L =
        ClassifyPointerProvenance(BO->getOperand(0), Depth + 1);
    PointerProvenance R =
        ClassifyPointerProvenance(BO->getOperand(1), Depth + 1);
    // Stack-relative integer arithmetic is owned by the bounds-checked frame
    // translator below.  The generic affine proof is intentionally limited
    // to allocator returns, whose integer spelling is already a host address.
    bool LNative = L == PointerProvenance::NativeHeapObject;
    bool RNative = R == PointerProvenance::NativeHeapObject;
    if (BO->getOpcode() == Instruction::Add && LNative != RNative &&
        (LNative ? R : L) == PointerProvenance::Unknown)
      return LNative ? L : R;
    if (BO->getOpcode() == Instruction::Sub && LNative && !RNative &&
        R == PointerProvenance::Unknown)
      return L;
  }
  if (auto *Phi = dyn_cast<PHINode>(Stripped)) {
    if (Phi->getNumIncomingValues() == 0) return PointerProvenance::Unknown;
    PointerProvenance First =
        ClassifyPointerProvenance(Phi->getIncomingValue(0), Depth + 1);
    if (First == PointerProvenance::Unknown) return First;
    for (unsigned I = 1; I < Phi->getNumIncomingValues(); ++I) {
      PointerProvenance Incoming =
          ClassifyPointerProvenance(Phi->getIncomingValue(I), Depth + 1);
      if (Incoming != First &&
          !(IsNativeProvenance(Incoming) && IsNativeProvenance(First)))
        return PointerProvenance::Unknown;
    }
    return First;
  }
  if (auto *Sel = dyn_cast<SelectInst>(Stripped)) {
    PointerProvenance T = ClassifyPointerProvenance(Sel->getTrueValue(), Depth + 1);
    PointerProvenance F = ClassifyPointerProvenance(Sel->getFalseValue(), Depth + 1);
    if (T == F && T != PointerProvenance::Unknown) return T;
    if (IsNativeProvenance(T) && IsNativeProvenance(F)) return T;
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
  if (!V || Depth > 12) return "";
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
    if (Value *Stored = FindSameBlockRegisterStore(LI))
      return ResolveFormatString(Stored, Depth + 1);
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

  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    // Global-data recovery builds a range-translation chain whose false edge
    // preserves the original native pointer.  When that fallback is a static
    // string, it is the authoritative format for an already-materialized
    // native va_list; true edges may mention unrelated recovered strings and
    // must not make the format look ambiguous.
    if (Sel->getName().starts_with("native.data.pointer.select")) {
      std::string F = ResolveFormatString(Sel->getFalseValue(), Depth + 1);
      if (!F.empty())
        return F;
    }
    std::string T = ResolveFormatString(Sel->getTrueValue(), Depth + 1);
    std::string F = ResolveFormatString(Sel->getFalseValue(), Depth + 1);
    if (T.empty() != F.empty())
      return T.empty() ? F : T;
    if (!T.empty() && T == F)
      return T;
  }

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

// This is deliberately not a general libc attribute inference rule.  A
// direct declaration recognized by the signature database is the external
// identity proof; the format and every destination position must additionally
// be exact before we state the narrow ABI fact that scanf does not retain the
// destination pointer past the call.  The call still writes through it and
// may alias any other pointer, so no memory-effect attributes are added.
static bool IsStrictScanfDestinationSpec(const VarargSpecifier &Spec) {
  StringRef Raw(Spec.Raw);
  if (!Spec.ConsumesArg || Spec.Ty == VarargType::ScanfSuppressed ||
      Raw.contains('$') || Raw.contains('*') || Raw.ends_with("n"))
    return false;
  switch (Spec.Ty) {
  case VarargType::IntI32:
  case VarargType::UintI32:
  case VarargType::IntI64:
  case VarargType::UintI64:
  case VarargType::CharI8:
  case VarargType::Pointer: // %s, %[, and %p destinations
  case VarargType::Double:
    return true;
  default:
    return false;
  }
}

bool BrightenExternCallBridgePass::AnnotateDirectScanfDestinationNoCapture(
    ExternCallContext &Ctx) {
  bool Changed = false;
  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      Function *Callee = CI->getCalledFunction();
      if (!Callee || !Callee->isDeclaration())
        continue;
      const LibcSignature *Sig = Ctx.SigDB.lookup(Callee->getName());
      if (!Sig || !Sig->IsVarArg || !isScanfFamilyKind(Sig->Special))
        continue;

      const unsigned FmtIndex = FormatArgIndex(*Sig);
      const unsigned DestStart = FmtIndex + 1;
      if (FmtIndex >= CI->arg_size() || DestStart > CI->arg_size())
        continue;
      std::string Format = ResolveFormatString(CI->getArgOperand(FmtIndex));
      if (Format.empty())
        continue;
      StringRef FmtRef(Format);
      if (!FmtRef.empty() && FmtRef.back() == '\0')
        FmtRef = FmtRef.drop_back();
      SmallVector<VarargSpecifier, 8> Specs;
      if (!parseFormatString(FmtRef, Specs, /*IsScanfFamily=*/true))
        continue;

      SmallVector<unsigned, 8> DestArgs;
      bool Safe = true;
      for (const VarargSpecifier &Spec : Specs) {
        if (!IsStrictScanfDestinationSpec(Spec)) {
          Safe = false;
          break;
        }
        DestArgs.push_back(DestStart + DestArgs.size());
      }
      // No partial annotation: an unaccounted vararg could be a destination
      // whose position was parsed incorrectly, so preserve the whole call.
      if (!Safe || DestArgs.empty() || DestStart + DestArgs.size() != CI->arg_size())
        continue;
      for (unsigned ArgNo : DestArgs)
        if (!CI->getArgOperand(ArgNo)->getType()->isPointerTy()) {
          Safe = false;
          break;
        }
      if (!Safe)
        continue;
      for (unsigned ArgNo : DestArgs) {
        if (!CI->doesNotCapture(ArgNo)) {
          // LLVM 21 represents the source-level nocapture contract as the
          // more precise captures(none) parameter attribute.
          CI->addParamAttr(
              ArgNo, Attribute::getWithCaptureInfo(Ctx.M.getContext(),
                                                    CaptureInfo::none()));
          Changed = true;
        }
      }
    }
  }
  return Changed;
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
      if (CS->SkipReason.empty()) {
        if (!CS->Args.empty() && !CS->Args.back().SkipReason.empty())
          CS->SkipReason = CS->Args.back().SkipReason;
        else
          CS->SkipReason = "unsupported-vararg-format";
      }
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

static AllocaInst *RootAlloca(Value *V) {
  if (!V) return nullptr;
  V = V->stripPointerCasts();
  if (auto *AI = dyn_cast<AllocaInst>(V)) return AI;
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return RootAlloca(GEP->getPointerOperand());
  return nullptr;
}

static std::optional<uint64_t> OffsetFromAlloca(Value *Ptr, AllocaInst *Root,
                                                 const DataLayout &DL) {
  if (!Ptr || !Root) return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base->stripPointerCasts() != Root || Offset.isNegative())
    return std::nullopt;
  return Offset.getZExtValue();
}

static StoreInst *FindLocalStore(CallInst *Before, AllocaInst *Root,
                                 uint64_t WantedOffset,
                                 const DataLayout &DL) {
  for (auto It = BasicBlock::reverse_iterator(Before->getIterator());
       It != Before->getParent()->rend(); ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) continue;
    auto Offset = OffsetFromAlloca(SI->getPointerOperand(), Root, DL);
    if (Offset && *Offset == WantedOffset)
      return SI;
  }
  return nullptr;
}

static Value *FindLocalStoreValue(CallInst *Before, AllocaInst *Root,
                                  uint64_t WantedOffset,
                                  const DataLayout &DL) {
  if (StoreInst *SI = FindLocalStore(Before, Root, WantedOffset, DL))
    return SI->getValueOperand();
  return nullptr;
}

// vsscanf writes through every recovered destination.  Unlike the legacy
// vprintf/vscanf path, do not look through volatile or atomic va_list setup:
// re-materialising such a call would change its observable memory effects.
static StoreInst *FindPlainLocalStore(CallInst *Before, AllocaInst *Root,
                                      uint64_t WantedOffset,
                                      const DataLayout &DL) {
  StoreInst *SI = FindLocalStore(Before, Root, WantedOffset, DL);
  if (!SI || SI->isVolatile() || SI->isAtomic()) return nullptr;
  return SI;
}

// A materialized va_list can still contain literal guest addresses.  Rebase
// only an address covered by exactly one authoritative guest range; overlap,
// one-past-end and unknown addresses deliberately keep the va_list call.
static Value *ResolveUniqueGuestConstant(IRBuilder<> &B, Module &M,
                                         ConstantInt *Address,
                                         uint64_t Width,
                                         StringRef *Failure = nullptr) {
  auto Refuse = [&](StringRef Reason) -> Value * {
    if (Failure) *Failure = Reason;
    return nullptr;
  };
  if (!Address || !Address->getType()->isIntegerTy()) return Refuse("not-integer");
  if (Width == 0) return Refuse("zero-width");
  uint64_t A = Address->getZExtValue(), End = 0;
  if (__builtin_add_overflow(A, Width, &End)) return Refuse("range-overflow");
  GlobalVariable *Match = nullptr;
  uint64_t Offset = 0;
  bool SawRange = false;
  bool SawContainingRange = false;
  for (GlobalVariable &GV : M.globals()) {
    MDNode *Range = GV.getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2) continue;
    SawRange = true;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *FinishMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *Finish = FinishMD ? dyn_cast<ConstantInt>(FinishMD->getValue()) : nullptr;
    if (!Begin || !Finish || A < Begin->getZExtValue() ||
        End > Finish->getZExtValue()) continue;
    SawContainingRange = true;
    uint64_t CandidateOffset = A - Begin->getZExtValue();
    TypeSize Storage = M.getDataLayout().getTypeAllocSize(GV.getValueType());
    if (Storage.isScalable() || CandidateOffset > Storage.getFixedValue() ||
        Width > Storage.getFixedValue() - CandidateOffset)
      continue;
    if (Match) return Refuse("ambiguous-range");
    Match = &GV;
    Offset = CandidateOffset;
  }
  if (!Match)
    return Refuse(SawContainingRange ? "storage-bounds" :
                  (SawRange ? "outside-guest-range" : "no-guest-range"));
  return B.CreateGEP(B.getInt8Ty(), Match, B.getInt64(Offset),
                     "extern.vararg.guest.object");
}

static bool HasScanfLengthModifier(StringRef Raw, StringRef Modifier) {
  if (Raw.size() < 2 || Modifier.empty()) return false;
  size_t Conversion = Raw.size() - 1;
  return Raw.substr(0, Conversion).contains(Modifier);
}

static std::optional<uint64_t>
ScanfDestinationWidth(const VarargSpecifier &Spec, const DataLayout &DL) {
  switch (Spec.Ty) {
  case VarargType::CharI8:
    // A field width makes %c write an array, and %lc writes wide characters.
    // Keep those forms fail-closed until the parser exposes their exact count.
    if (Spec.Raw != "%c") return std::nullopt;
    return 1;
  case VarargType::IntI32:
  case VarargType::UintI32:
    if (HasScanfLengthModifier(Spec.Raw, "hh")) return 1;
    if (HasScanfLengthModifier(Spec.Raw, "h")) return 2;
    return 4;
  case VarargType::IntI64:
  case VarargType::UintI64:
    return 8;
  case VarargType::Double:
    if (HasScanfLengthModifier(Spec.Raw, "L")) return 16;
    return HasScanfLengthModifier(Spec.Raw, "l") ? 8 : 4;
  case VarargType::Pointer:
    // %s and %[ have an input-dependent write extent.  We cannot prove that
    // extent here, but a direct native call needs the guest address rebased
    // only when its first writable byte is in one unique recovered object.
    // This preserves the original call's possible overrun behavior instead
    // of manufacturing an unmapped inttoptr.  %p is fixed-width and retains
    // its stricter eight-byte proof.
    if (StringRef(Spec.Raw).ends_with("p"))
      return DL.getPointerSize(0);
    if (StringRef(Spec.Raw).ends_with("s") || StringRef(Spec.Raw).contains('['))
      return 1;
    return std::nullopt;
  default:
    // %n and unknown pointer-shaped conversions remain fail-closed.
    return std::nullopt;
  }
}

static std::optional<int64_t> ConstantOffsetFrom(Value *Ptr, Value *Base,
                                                  const DataLayout &DL,
                                                  unsigned Depth = 0) {
  if (!Ptr || !Base || Depth > 8) return std::nullopt;
  Ptr = Ptr->stripPointerCasts();
  Base = Base->stripPointerCasts();
  if (Ptr == Base) return 0;
  auto *GEP = dyn_cast<GEPOperator>(Ptr);
  if (!GEP) return std::nullopt;
  APInt Offset(DL.getIndexTypeSizeInBits(GEP->getType()), 0, true);
  if (!GEP->accumulateConstantOffset(DL, Offset)) return std::nullopt;
  auto Parent = ConstantOffsetFrom(GEP->getPointerOperand(), Base, DL,
                                   Depth + 1);
  if (!Parent) return std::nullopt;
  return *Parent + Offset.getSExtValue();
}

struct AffineValue {
  Value *Base = nullptr;
  int64_t Offset = 0;
};

static std::optional<int64_t> AddSignedOffset(int64_t LHS, int64_t RHS) {
  if ((RHS > 0 && LHS > std::numeric_limits<int64_t>::max() - RHS) ||
      (RHS < 0 && LHS < std::numeric_limits<int64_t>::min() - RHS))
    return std::nullopt;
  return LHS + RHS;
}

static Value *FindSameBlockRegisterStore(LoadInst *LI) {
  auto Wanted = IdentifyStateOffset(LI->getPointerOperand());
  if (!Wanted) return nullptr;
  for (auto It = BasicBlock::reverse_iterator(LI->getIterator());
       It != LI->getParent()->rend(); ++It) {
    if (auto *SI = dyn_cast<StoreInst>(&*It)) {
      auto Offset = IdentifyStateOffset(SI->getPointerOperand());
      if (!Offset) return nullptr;
      if (*Offset == *Wanted) return SI->getValueOperand();
      continue;
    }
    if (auto *CB = dyn_cast<CallBase>(&*It)) {
      if (Function *Callee = CB->getCalledFunction())
        if (Callee->getName().starts_with("llvm.lifetime.")) continue;
      if (CB->mayWriteToMemory()) return nullptr;
    }
  }
  return nullptr;
}

static std::optional<AffineValue> GetAffineValue(Value *V,
                                                  unsigned Depth = 0) {
  if (!V || Depth > 12 || !V->getType()->isIntegerTy()) return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return AffineValue{nullptr, CI->getSExtValue()};
  if (auto *LI = dyn_cast<LoadInst>(V))
    if (Value *Stored = FindSameBlockRegisterStore(LI))
      return GetAffineValue(Stored, Depth + 1);
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::Add) {
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
        auto A = GetAffineValue(BO->getOperand(0), Depth + 1);
        auto Offset = A ? AddSignedOffset(A->Offset, C->getSExtValue())
                        : std::nullopt;
        if (Offset) { A->Offset = *Offset; return A; }
      }
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(0))) {
        auto A = GetAffineValue(BO->getOperand(1), Depth + 1);
        auto Offset = A ? AddSignedOffset(A->Offset, C->getSExtValue())
                        : std::nullopt;
        if (Offset) { A->Offset = *Offset; return A; }
      }
    }
    if (BO->getOpcode() == Instruction::Sub)
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
        auto A = GetAffineValue(BO->getOperand(0), Depth + 1);
        int64_t Delta = C->getSExtValue();
        if (Delta == std::numeric_limits<int64_t>::min())
          return std::nullopt;
        auto Offset = A ? AddSignedOffset(A->Offset, -Delta) : std::nullopt;
        if (Offset) { A->Offset = *Offset; return A; }
      }
  }
  return AffineValue{V, 0};
}

static bool IsPtrToIntOf(Value *V, Value *Ptr) {
  Value *P = nullptr;
  if (auto *I = dyn_cast<PtrToIntInst>(V)) P = I->getPointerOperand();
  else if (auto *CE = dyn_cast<ConstantExpr>(V);
           CE && CE->getOpcode() == Instruction::PtrToInt)
    P = CE->getOperand(0);
  return P && P->stripPointerCasts() == Ptr->stripPointerCasts();
}

// Recognize an integer which explicitly changes from an absolute pointer
// coordinate into Anchor-relative coordinates.  Affine add/sub by constants
// preserves that proof; an architectural RSP/RBP value by itself does not.
static bool IsExplicitFrameRelativeOffset(Value *V, Value *Anchor,
                                          unsigned Depth = 0) {
  if (!V || !Anchor || Depth > 8 || !V->getType()->isIntegerTy())
    return false;
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO)
    return false;
  if (BO->getOpcode() == Instruction::Sub &&
      IsPtrToIntOf(BO->getOperand(1), Anchor))
    return true;
  if ((BO->getOpcode() == Instruction::Add ||
       BO->getOpcode() == Instruction::Sub) &&
      isa<ConstantInt>(BO->getOperand(1)))
    return IsExplicitFrameRelativeOffset(BO->getOperand(0), Anchor,
                                         Depth + 1);
  if (BO->getOpcode() == Instruction::Add &&
      isa<ConstantInt>(BO->getOperand(0)))
    return IsExplicitFrameRelativeOffset(BO->getOperand(1), Anchor,
                                         Depth + 1);
  return false;
}

static bool IsFrameStoragePointer(Value *V, const DataLayout &DL) {
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = V->stripAndAccumulateConstantOffsets(DL, Offset, true);
  auto *GV = dyn_cast_or_null<GlobalVariable>(Base->stripPointerCasts());
  return GV && GV->getName().starts_with("frame_storage_backing.");
}

static bool IsEntryStackPointer(Value *V) {
  auto *LI = dyn_cast<LoadInst>(V);
  if (!LI || LI->getParent() != &LI->getFunction()->getEntryBlock())
    return false;
  auto Offset = IdentifyStateOffset(LI->getPointerOperand());
  return Offset && *Offset == kOffRSP;
}

// Recover the guest/host stack coordinate represented by the two pointer
// translations emitted by earlier passes:
//   frame + (address - ptrtoint(frame))
//   frame_top + (address - entry_rsp)
// The latter is valid only for the recovered frame top and the entry RSP load.
static std::optional<AffineValue>
GetTranslatedStackCoordinate(Value *Ptr, const DataLayout &DL,
                             unsigned Depth = 0) {
  if (!Ptr || Depth > 8) return std::nullopt;
  Ptr = Ptr->stripPointerCasts();
  auto *GEP = dyn_cast<GEPOperator>(Ptr);
  if (!GEP || GEP->getNumIndices() != 1) return std::nullopt;

  Value *Index = *GEP->idx_begin();
  if (auto *C = dyn_cast<ConstantInt>(Index)) {
    auto Parent = GetTranslatedStackCoordinate(GEP->getPointerOperand(), DL,
                                                Depth + 1);
    if (Parent) {
      Parent->Offset += C->getSExtValue();
      return Parent;
    }
    return std::nullopt;
  }

  auto *Sub = dyn_cast<BinaryOperator>(Index);
  if (!Sub || Sub->getOpcode() != Instruction::Sub) return std::nullopt;
  Value *Frame = GEP->getPointerOperand();
  bool RecoveredFrameAddress = IsPtrToIntOf(Sub->getOperand(1), Frame);
  bool EntryRelativeAddress = IsFrameStoragePointer(Frame, DL) &&
                              IsEntryStackPointer(Sub->getOperand(1));
  if (!RecoveredFrameAddress && !EntryRelativeAddress) return std::nullopt;
  return GetAffineValue(Sub->getOperand(0));
}

static Value *FindStoreRelativeTo(CallInst *Before, Value *Base,
                                  uint64_t WantedOffset,
                                  const DataLayout &DL) {
  auto BaseCoordinate = GetTranslatedStackCoordinate(Base, DL);
  for (auto It = BasicBlock::reverse_iterator(Before->getIterator());
       It != Before->getParent()->rend(); ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) continue;
    auto Offset = ConstantOffsetFrom(SI->getPointerOperand(), Base, DL);
    if (Offset && *Offset >= 0 && static_cast<uint64_t>(*Offset) == WantedOffset)
      return SI->getValueOperand();
    if (!BaseCoordinate) continue;
    auto StoreCoordinate =
        GetTranslatedStackCoordinate(SI->getPointerOperand(), DL);
    if (!StoreCoordinate || StoreCoordinate->Base != BaseCoordinate->Base)
      continue;
    int64_t Relative = StoreCoordinate->Offset - BaseCoordinate->Offset;
    if (Relative >= 0 && static_cast<uint64_t>(Relative) == WantedOffset)
      return SI->getValueOperand();
  }
  return nullptr;
}

struct RecoveredFrameAnchor {
  Value *Ptr = nullptr;
  int64_t Offset = 0;
  uint64_t Size = 0;
};

static std::optional<RecoveredFrameAnchor>
GetRecoveredFrameAnchor(Value *V, const DataLayout &DL, unsigned Depth = 0) {
  if (!V || Depth > 8) return std::nullopt;
  V = V->stripPointerCasts();

  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = V->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (auto *GV = dyn_cast_or_null<GlobalVariable>(Base)) {
    if (GV->getName().starts_with("frame_storage_backing.")) {
      uint64_t Size = DL.getTypeAllocSize(GV->getValueType());
      int64_t Signed = Offset.getSExtValue();
      if (Signed >= 0 && static_cast<uint64_t>(Signed) <= Size)
        return RecoveredFrameAnchor{V, Signed, Size};
    }
  }
  if (auto *AI = dyn_cast_or_null<AllocaInst>(Base)) {
    auto *Count = dyn_cast<ConstantInt>(AI->getArraySize());
    if (!Count)
      return std::nullopt;
    uint64_t ElementSize = DL.getTypeAllocSize(AI->getAllocatedType());
    uint64_t CountValue = Count->getLimitedValue();
    if (CountValue != 0 && ElementSize > UINT64_MAX / CountValue)
      return std::nullopt;
    uint64_t Size = ElementSize * CountValue;
    int64_t Signed = Offset.getSExtValue();
    if (Signed >= 0 && static_cast<uint64_t>(Signed) <= Size)
      return RecoveredFrameAnchor{V, Signed, Size};
  }

  // Primary native cleanup may outline the recovered body and pass the frame
  // top as an explicit pointer argument.  Prove that contract from every
  // direct callsite, then keep using the argument inside the outlined body.
  // This lets the late extern sweep translate guest stack offsets without
  // depending on inlining happening before it.
  if (auto *Arg = dyn_cast<Argument>(V)) {
    if (!Arg->getName().starts_with("frame_base"))
      return std::nullopt;
    Function *F = Arg->getParent();
    std::optional<RecoveredFrameAnchor> Proven;
    bool SawDirectCall = false;
    for (User *U : F->users()) {
      auto *CB = dyn_cast<CallBase>(U);
      if (!CB || CB->getCalledOperand()->stripPointerCasts() != F ||
          Arg->getArgNo() >= CB->arg_size())
        continue;
      Value *ActualValue = CB->getArgOperand(Arg->getArgNo());
      if (auto *CallerArg = dyn_cast<Argument>(ActualValue)) {
        if (!CallerArg->getName().starts_with("frame_base"))
          return std::nullopt;
        SawDirectCall = true;
        continue;
      }
      auto Actual = GetRecoveredFrameAnchor(ActualValue, DL, Depth + 1);
      if (!Actual)
        return std::nullopt;
      SawDirectCall = true;
      if (!Proven) {
        Proven = Actual;
      } else {
        uint64_t Before = std::min<uint64_t>(Proven->Offset, Actual->Offset);
        uint64_t ProvenAfter = Proven->Size - Proven->Offset;
        uint64_t ActualAfter = Actual->Size - Actual->Offset;
        uint64_t After = std::min(ProvenAfter, ActualAfter);
        Proven->Offset = static_cast<int64_t>(Before);
        Proven->Size = Before + After;
      }
    }
    if (SawDirectCall && Proven)
      return RecoveredFrameAnchor{Arg, Proven->Offset, Proven->Size};
  }

  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return GetRecoveredFrameAnchor(GEP->getPointerOperand(), DL, Depth + 1);
  return std::nullopt;
}

static Value *PtrToIntPointerOperand(Value *V) {
  if (auto *PTI = dyn_cast_or_null<PtrToIntInst>(V))
    return PTI->getPointerOperand();
  if (auto *CE = dyn_cast_or_null<ConstantExpr>(V);
      CE && CE->getOpcode() == Instruction::PtrToInt)
    return CE->getOperand(0);
  return nullptr;
}

static bool HasSameConcreteFrameBacking(Value *LHS, Value *RHS,
                                        const DataLayout &DL) {
  if (!LHS || !RHS) return false;
  APInt LHSOffset(DL.getPointerSizeInBits(0), 0, true);
  APInt RHSOffset(DL.getPointerSizeInBits(0), 0, true);
  Value *LHSBase = LHS->stripAndAccumulateConstantOffsets(
      DL, LHSOffset, true);
  Value *RHSBase = RHS->stripAndAccumulateConstantOffsets(
      DL, RHSOffset, true);
  return LHSBase && RHSBase &&
         LHSBase->stripPointerCasts() == RHSBase->stripPointerCasts() &&
         (isa<AllocaInst>(LHSBase) || isa<GlobalVariable>(LHSBase) ||
          isa<Argument>(LHSBase));
}

static Value *TranslateAffineFrameAddress(IRBuilder<> &B, Value *V,
                                          const RecoveredFrameAnchor &Anchor,
                                          const DataLayout &DL,
                                          uint64_t RequiredWidth) {
  auto Affine = GetAffineValue(V);
  if (!Affine || !Affine->Base) return nullptr;
  Value *BasePointer = PtrToIntPointerOperand(Affine->Base);
  if (!BasePointer ||
      V->getType()->getIntegerBitWidth() != DL.getPointerSizeInBits(0) ||
      !HasSameConcreteFrameBacking(BasePointer, Anchor.Ptr, DL))
    return nullptr;

  auto BaseAnchor = GetRecoveredFrameAnchor(BasePointer, DL);
  if (!BaseAnchor) return nullptr;
  __int128 Target = static_cast<__int128>(BaseAnchor->Offset) +
                    static_cast<__int128>(Affine->Offset);
  if (Target < 0 || Target > static_cast<__int128>(BaseAnchor->Size))
    return nullptr;
  uint64_t TargetOffset = static_cast<uint64_t>(Target);
  if (RequiredWidth > BaseAnchor->Size - TargetOffset)
    return nullptr;

  if (Affine->Offset == 0)
    return BasePointer;

  return B.CreateGEP(B.getInt8Ty(), BasePointer,
                     ConstantInt::getSigned(B.getInt64Ty(), Affine->Offset),
                     "native.frame.affine.ptr");
}

static Value *TranslateProvenFrameOffset(IRBuilder<> &B, Value *V,
                                         const RecoveredFrameAnchor &Anchor,
                                         const DataLayout &DL,
                                         uint64_t RequiredWidth = 1) {
  if (!V || !V->getType()->isIntegerTy()) return nullptr;

  if (Value *AffinePointer =
          TranslateAffineFrameAddress(B, V, Anchor, DL, RequiredWidth))
    return AffinePointer;

  if (IsExplicitFrameRelativeOffset(V, Anchor.Ptr)) {
    Value *Relative = V;
    if (V->getType()->getIntegerBitWidth() < 64)
      Relative = B.CreateSExt(V, B.getInt64Ty(),
                              "native.overflow.frame.sext");
    else if (V->getType()->getIntegerBitWidth() > 64)
      Relative = B.CreateTrunc(V, B.getInt64Ty(),
                               "native.overflow.frame.trunc");
    return B.CreateGEP(B.getInt8Ty(), Anchor.Ptr, Relative,
                       "native.overflow.frame.ptr");
  }

  // Classify the stored coordinate itself.  The kind of the owning anchor is
  // not a coordinate proof: an outlined function can receive `frame_base`
  // while its explicit RSP/RBP State values remain native absolute addresses.
  // Adding frame_base to such a value doubles the address (p00241).
  if (!isa<ConstantInt>(V)) {
    auto Affine = GetAffineValue(V);
    Value *Base = Affine ? Affine->Base : nullptr;
    bool AbsoluteStackCoordinate = false;
    if (auto *LI = dyn_cast_or_null<LoadInst>(Base)) {
      auto Offset = IdentifyStateOffset(LI->getPointerOperand());
      AbsoluteStackCoordinate =
          Offset && (*Offset == kOffRSP || *Offset == 2328);
    } else if (Base && Base->hasName()) {
      StringRef Name = Base->getName();
      AbsoluteStackCoordinate = Name.starts_with("state_2312") ||
                                Name.starts_with("state_2328") ||
                                Name.starts_with("state_in_2312") ||
                                Name.starts_with("state_in_2328");
    }
    if (!AbsoluteStackCoordinate)
      return nullptr;
    return B.CreateIntToPtr(V, B.getPtrTy(),
                            "native.overflow.absolute.ptr");
  }

  Value *Relative = V;
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    int64_t Signed = CI->getSExtValue();
    int64_t Absolute = Anchor.Offset + Signed;
    if (Absolute < 0 || static_cast<uint64_t>(Absolute) >= Anchor.Size)
      return nullptr;
    Relative = ConstantInt::getSigned(B.getInt64Ty(), Signed);
  } else if (V->getType()->getIntegerBitWidth() < 64) {
    Relative = B.CreateSExt(V, B.getInt64Ty(), "native.overflow.frame.sext");
  } else if (V->getType()->getIntegerBitWidth() > 64) {
    Relative = B.CreateTrunc(V, B.getInt64Ty(), "native.overflow.frame.trunc");
  }
  return B.CreateGEP(B.getInt8Ty(), Anchor.Ptr, Relative,
                     "native.overflow.frame.ptr");
}

struct LocalFrameSlice {
  AllocaInst *Root = nullptr;
  uint64_t Offset = 0;
  uint64_t Width = 0;
};

static std::optional<LocalFrameSlice>
GetLocalFrameSlice(Value *Pointer, uint64_t Width, const DataLayout &DL) {
  if (!Pointer || !Pointer->getType()->isPointerTy() || Width == 0)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Pointer->stripAndAccumulateConstantOffsets(DL, Offset, true);
  auto *Root = dyn_cast_or_null<AllocaInst>(
      Base ? Base->stripPointerCasts() : nullptr);
  if (!Root || Offset.isNegative()) return std::nullopt;
  auto *Count = dyn_cast<ConstantInt>(Root->getArraySize());
  if (!Count) return std::nullopt;
  TypeSize ElementSize = DL.getTypeAllocSize(Root->getAllocatedType());
  if (ElementSize.isScalable()) return std::nullopt;
  uint64_t CountValue = Count->getLimitedValue();
  uint64_t StorageSize = 0;
  if (__builtin_mul_overflow(ElementSize.getFixedValue(), CountValue,
                             &StorageSize))
    return std::nullopt;
  uint64_t ByteOffset = Offset.getZExtValue();
  if (ByteOffset > StorageSize || Width > StorageSize - ByteOffset)
    return std::nullopt;
  return LocalFrameSlice{Root, ByteOffset, Width};
}

static bool HasFixedScanfWriteExtent(const VarargSpecifier &Spec) {
  if (Spec.Ty == VarargType::Pointer)
    return StringRef(Spec.Raw).ends_with("p");
  return Spec.Ty == VarargType::CharI8 ||
         Spec.Ty == VarargType::IntI32 ||
         Spec.Ty == VarargType::UintI32 ||
         Spec.Ty == VarargType::IntI64 ||
         Spec.Ty == VarargType::UintI64 ||
         Spec.Ty == VarargType::Double;
}

static bool FrameSlicesOverlap(const LocalFrameSlice &LHS,
                               const LocalFrameSlice &RHS) {
  if (LHS.Root != RHS.Root) return false;
  return LHS.Offset < RHS.Offset + RHS.Width &&
         RHS.Offset < LHS.Offset + LHS.Width;
}

static Value *TranslateProvenLocalFrameInteger(IRBuilder<> &B, Value *V,
                                               const DataLayout &DL,
                                               uint64_t RequiredWidth) {
  auto Affine = GetAffineValue(V);
  if (!Affine || !Affine->Base ||
      V->getType()->getIntegerBitWidth() != DL.getPointerSizeInBits(0))
    return nullptr;
  Value *BasePointer = PtrToIntPointerOperand(Affine->Base);
  if (!BasePointer) return nullptr;
  auto Anchor = GetRecoveredFrameAnchor(BasePointer, DL);
  if (!Anchor) return nullptr;
  Value *Object = getUnderlyingObject(BasePointer);
  auto *Root = dyn_cast_or_null<AllocaInst>(Object);
  if (!Root || Root->getFunction() != B.GetInsertBlock()->getParent())
    return nullptr;

  __int128 Target = static_cast<__int128>(Anchor->Offset) +
                    static_cast<__int128>(Affine->Offset);
  if (Target < 0 || Target > static_cast<__int128>(Anchor->Size))
    return nullptr;
  uint64_t TargetOffset = static_cast<uint64_t>(Target);
  if (RequiredWidth > Anchor->Size - TargetOffset)
    return nullptr;
  if (Affine->Offset == 0)
    return BasePointer;
  return B.CreateGEP(B.getInt8Ty(), BasePointer,
                     ConstantInt::getSigned(B.getInt64Ty(), Affine->Offset),
                     "native.scanf.frame.ptr");
}

static bool IsSyntheticLocalFrame(const LocalFrameSlice &Slice) {
  if (!Slice.Root) return false;
  StringRef Name = Slice.Root->getName();
  return Name.starts_with("frame_storage") ||
         Name.starts_with("native_frame");
}

static bool CanonicalizeDirectScanfFrameDestinations(ExternCallContext &Ctx) {
  SmallVector<CallInst *, 16> Calls;
  for (Function &F : Ctx.M)
    if (!F.isDeclaration())
      for (Instruction &I : instructions(F))
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Callee = CI->getCalledFunction())
            if (Callee->getName() == "scanf" ||
                Callee->getName() == "__isoc99_scanf")
              Calls.push_back(CI);

  bool Changed = false;
  for (CallInst *CI : Calls) {
    if (CI->arg_empty()) continue;
    std::string Format = ResolveFormatString(CI->getArgOperand(0));
    if (Format.empty()) continue;
    SmallVector<VarargSpecifier, 16> Specs;
    if (!parseFormatString(Format, Specs, true)) continue;

    struct PendingDirectLocal {
      unsigned ArgumentIndex = 0;
      Value *FramePointer = nullptr;
      LocalFrameSlice Slice;
      AllocaInst *Local = nullptr;
    };
    SmallVector<PendingDirectLocal, 8> Pending;
    unsigned ArgumentIndex = 1;
    IRBuilder<> B(CI);
    for (const VarargSpecifier &Spec : Specs) {
      if (!Spec.ConsumesArg || Spec.Ty == VarargType::Percent ||
          Spec.Ty == VarargType::ScanfSuppressed)
        continue;
      if (ArgumentIndex >= CI->arg_size()) {
        Pending.clear();
        break;
      }
      auto Width = ScanfDestinationWidth(Spec, Ctx.DL);
      if (!Width || !HasFixedScanfWriteExtent(Spec)) {
        ++ArgumentIndex;
        continue;
      }
      Value *Original = CI->getArgOperand(ArgumentIndex);
      Value *FramePointer = Original;
      Value *IntegerAddress = nullptr;
      if (auto *ITP = dyn_cast<IntToPtrInst>(Original))
        IntegerAddress = ITP->getOperand(0);
      else if (auto *CE = dyn_cast<ConstantExpr>(Original);
               CE && CE->getOpcode() == Instruction::IntToPtr)
        IntegerAddress = CE->getOperand(0);
      if (IntegerAddress)
        FramePointer = TranslateProvenLocalFrameInteger(
            B, IntegerAddress, Ctx.DL, *Width);
      if (FramePointer)
        if (auto Slice = GetLocalFrameSlice(FramePointer, *Width, Ctx.DL);
            Slice && IsSyntheticLocalFrame(*Slice))
          Pending.push_back(
              {ArgumentIndex, FramePointer, *Slice, nullptr});
      ++ArgumentIndex;
    }
    if (Pending.empty()) continue;

    bool Disjoint = true;
    for (size_t I = 0; I < Pending.size(); ++I)
      for (size_t J = I + 1; J < Pending.size(); ++J)
        if (FrameSlicesOverlap(Pending[I].Slice, Pending[J].Slice))
          Disjoint = false;
    if (!Disjoint) continue;

    IRBuilder<> EntryBuilder(
        &*CI->getFunction()->getEntryBlock().getFirstInsertionPt());
    for (PendingDirectLocal &Item : Pending) {
      ArrayType *Storage = ArrayType::get(B.getInt8Ty(), Item.Slice.Width);
      Item.Local = EntryBuilder.CreateAlloca(
          Storage, nullptr, "native.scanf.destination");
      uint64_t AlignmentValue = Item.Slice.Width >= 16 ? 16 :
                                Item.Slice.Width >= 8 ? 8 :
                                Item.Slice.Width >= 4 ? 4 :
                                Item.Slice.Width >= 2 ? 2 : 1;
      Align Alignment(AlignmentValue);
      Item.Local->setAlignment(Alignment);
      B.CreateMemCpy(Item.Local, Alignment, Item.FramePointer, Align(1),
                     Item.Slice.Width);
      CI->setArgOperand(Item.ArgumentIndex, Item.Local);
    }
    Instruction *AfterCall = CI->getNextNode();
    if (!AfterCall) continue;
    IRBuilder<> CopyBack(AfterCall);
    for (const PendingDirectLocal &Item : Pending)
      CopyBack.CreateMemCpy(Item.FramePointer, Align(1), Item.Local,
                           Item.Local->getAlign(), Item.Slice.Width);
    Changed = true;
  }
  return Changed;
}

static bool NormalizeScanfOverflowSlots(CallInst *Before, Value *OverflowArea,
                                        const RecoveredFrameAnchor &Anchor,
                                        const DataLayout &DL) {
  bool Changed = false;
  for (auto It = BasicBlock::iterator(Before->getParent()->begin());
       It != Before->getIterator(); ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI || !SI->getValueOperand()->getType()->isIntegerTy()) continue;
    auto Offset = ConstantOffsetFrom(SI->getPointerOperand(), OverflowArea, DL);
    if (!Offset || *Offset < 0 || (*Offset % 8) != 0) continue;
    auto *Raw = dyn_cast<ConstantInt>(SI->getValueOperand());
    if (!Raw) continue;
    IRBuilder<> B(SI);
    Value *HostPtr = TranslateProvenFrameOffset(B, Raw, Anchor, DL);
    if (!HostPtr) continue;
    Value *HostInt = B.CreatePtrToInt(HostPtr, Raw->getType(),
                                      "native.overflow.frame.address");
    SI->setOperand(0, HostInt);
    Changed = true;
  }
  return Changed;
}

bool BrightenExternCallBridgePass::LowerMaterializedVAListCalls(
    ExternCallContext &Ctx) {
  SmallVector<CallInst *, 16> Work;
  for (Function &F : Ctx.M)
    if (!F.isDeclaration())
      for (Instruction &I : instructions(F))
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Callee = CI->getCalledFunction())
            if (((Callee->getName() == "vprintf" ||
                  Callee->getName() == "vscanf") && CI->arg_size() == 2) ||
                (Callee->getName() == "vsscanf" && CI->arg_size() == 3))
              Work.push_back(CI);

  bool Changed = false;
  for (CallInst *CI : Work) {
    Function *OldCallee = CI->getCalledFunction();
    auto Trace = [&](StringRef Reason) {
      if (!TraceMaterializedVAList) return;
      errs() << "[brighten-extern] materialized-va-list preserve: caller="
             << CI->getFunction()->getName() << " callee="
             << OldCallee->getName() << " reason=" << Reason << '\n';
    };
    bool IsSscanf = OldCallee->getName() == "vsscanf";
    bool IsScanf = OldCallee->getName() == "vscanf" || IsSscanf;
    unsigned VAIndex = IsSscanf ? 2 : 1;
    unsigned FormatIndex = IsSscanf ? 1 : 0;
    AllocaInst *VAList = RootAlloca(CI->getArgOperand(VAIndex));
    if (!VAList) { Trace("root-va"); continue; }
    auto LoadVAField = [&](uint64_t Offset) -> Value * {
      if (!IsSscanf)
        return FindLocalStoreValue(CI, VAList, Offset, Ctx.DL);
      if (StoreInst *SI = FindPlainLocalStore(CI, VAList, Offset, Ctx.DL))
        return SI->getValueOperand();
      return nullptr;
    };
    Value *OverflowArea = LoadVAField(8);
    auto FrameAnchor = GetRecoveredFrameAnchor(OverflowArea, Ctx.DL);
    // Keep the existing vscanf normalization path untouched.  A refused
    // vsscanf recovery must leave its materialized va_list byte-for-byte.
    if (IsScanf && !IsSscanf && OverflowArea && FrameAnchor)
      Changed |= NormalizeScanfOverflowSlots(CI, OverflowArea, *FrameAnchor,
                                             Ctx.DL);

    std::string Format = ResolveFormatString(CI->getArgOperand(FormatIndex));
    if (Format.empty()) { Trace("format"); continue; }

    SmallVector<VarargSpecifier, 16> Specs;
    if (!parseFormatString(Format, Specs, IsScanf)) { Trace("format-parse"); continue; }

    Value *RegSaveValue = LoadVAField(16);
    AllocaInst *RegSave = RootAlloca(RegSaveValue);
    if (!RegSave) { Trace("regsave"); continue; }
    uint64_t OverflowOffset = 0;

    uint64_t GPOffset = 8;
    if (Value *StoredGP = LoadVAField(0)) {
      auto *GP = dyn_cast<ConstantInt>(StoredGP);
      if (!GP || GP->getZExtValue() > 40) { Trace("gp"); continue; }
      GPOffset = GP->getZExtValue();
    }

    IRBuilder<> B(CI);
    SmallVector<Value *, 8> Args;
    struct PendingScanfLocal {
      unsigned ArgumentIndex = 0;
      Value *FramePointer = nullptr;
      LocalFrameSlice Slice;
      AllocaInst *Local = nullptr;
    };
    SmallVector<PendingScanfLocal, 8> PendingLocals;
    if (IsSscanf) Args.push_back(CI->getArgOperand(0));
    Args.push_back(CI->getArgOperand(FormatIndex));
    bool Safe = true;
    for (const VarargSpecifier &Spec : Specs) {
      if (!Spec.ConsumesArg || Spec.Ty == VarargType::Percent ||
          Spec.Ty == VarargType::ScanfSuppressed)
        continue;
      if (Spec.UsesXMMReg && !IsScanf) { Safe = false; break; }
      Value *Stored = nullptr;
      bool FromOverflow = GPOffset > 40;
      if (FromOverflow) {
        if (!OverflowArea || !FrameAnchor) { Safe = false; break; }
        Stored = FindStoreRelativeTo(CI, OverflowArea, OverflowOffset, Ctx.DL);
        if (!Stored) {
          Value *Slot = B.CreateGEP(B.getInt8Ty(), OverflowArea,
                                    B.getInt64(OverflowOffset),
                                    "native.overflow.slot");
          Stored = B.CreateLoad(B.getInt64Ty(), Slot,
                                "native.overflow.value");
        }
        OverflowOffset += 8;
      } else {
        if (IsSscanf) {
          StoreInst *SI = FindPlainLocalStore(CI, RegSave, GPOffset, Ctx.DL);
          if (!SI) { Safe = false; break; }
          Stored = SI->getValueOperand();
        } else {
          Stored = FindLocalStoreValue(CI, RegSave, GPOffset, Ctx.DL);
        }
        GPOffset += 8;
      }
      if (!Stored) { Safe = false; break; }
      Type *Ty = VarargLLVMType(Ctx.M.getContext(), Spec.Ty, IsScanf);
      Value *Arg = nullptr;
      std::optional<uint64_t> DestinationWidth;
      if (IsScanf && Ty->isPointerTy()) {
        DestinationWidth = ScanfDestinationWidth(Spec, Ctx.DL);
        if (FrameAnchor && DestinationWidth)
          Arg = TranslateProvenFrameOffset(B, Stored, *FrameAnchor, Ctx.DL,
                                           *DestinationWidth);
      }
      // scanf-family variadic operands are destination pointers.  A literal
      // from the materialized register-save area is still a guest coordinate,
      // not a host pointer: lowering it through CoerceToType would create a
      // raw inttoptr and let libc write through an unmapped address.  Require
      // the same unique guest-object proof for vscanf as for vsscanf.
      if (!Arg && IsScanf && Ty->isPointerTy()) {
        if (auto *Guest = dyn_cast<ConstantInt>(Stored)) {
          if (!DestinationWidth) {
            Trace("guest-width"); Safe = false; break;
          }
          StringRef GuestFailure;
          Arg = ResolveUniqueGuestConstant(B, Ctx.M, Guest, *DestinationWidth,
                                           &GuestFailure);
          // A literal guest coordinate is never a host pointer merely because
          // it has pointer width.  In particular, do not let CoerceToType
          // below turn an ambiguous or out-of-range address into inttoptr.
          if (!Arg) { Trace(GuestFailure); Safe = false; break; }
        }
        else if (!Stored->getType()->isPointerTy() &&
                 !IsNativeProvenance(ClassifyPointerProvenance(Stored))) {
          if (TraceMaterializedVAList) {
            errs() << "[brighten-extern] materialized-va-list slot lacks "
                      "native pointer provenance: ";
            Stored->printAsOperand(errs(), false);
            errs() << '\n';
          }
          Safe = false;
          break;
        }
      }
      if (!Arg)
        Arg = CoerceToType(B, Stored, Ty);
      if (!Arg) { Safe = false; break; }
      if (IsScanf && DestinationWidth &&
          HasFixedScanfWriteExtent(Spec)) {
        if (auto Slice = GetLocalFrameSlice(Arg, *DestinationWidth, Ctx.DL))
          PendingLocals.push_back(
              {static_cast<unsigned>(Args.size()), Arg, *Slice, nullptr});
      }
      Args.push_back(Arg);
    }
    if (!Safe) { Trace("slot-or-provenance"); continue; }

    bool DisjointLocals = true;
    for (size_t I = 0; I < PendingLocals.size(); ++I)
      for (size_t J = I + 1; J < PendingLocals.size(); ++J)
        if (FrameSlicesOverlap(PendingLocals[I].Slice,
                               PendingLocals[J].Slice))
          DisjointLocals = false;
    if (DisjointLocals) {
      IRBuilder<> EntryBuilder(
          &*CI->getFunction()->getEntryBlock().getFirstInsertionPt());
      for (PendingScanfLocal &Pending : PendingLocals) {
        ArrayType *Storage = ArrayType::get(B.getInt8Ty(),
                                            Pending.Slice.Width);
        Pending.Local = EntryBuilder.CreateAlloca(
            Storage, nullptr, "native.scanf.destination");
        uint64_t AlignmentValue = Pending.Slice.Width >= 16 ? 16 :
                                  Pending.Slice.Width >= 8 ? 8 :
                                  Pending.Slice.Width >= 4 ? 4 :
                                  Pending.Slice.Width >= 2 ? 2 : 1;
        Align Alignment(AlignmentValue);
        Pending.Local->setAlignment(Alignment);
        B.CreateMemCpy(Pending.Local, Alignment, Pending.FramePointer,
                       Align(1), Pending.Slice.Width);
        Args[Pending.ArgumentIndex] = Pending.Local;
      }
    } else {
      PendingLocals.clear();
    }

    SmallVector<Type *, 2> FixedArgs{B.getPtrTy()};
    if (IsSscanf) FixedArgs.push_back(B.getPtrTy());
    FunctionType *FT = FunctionType::get(B.getInt32Ty(), FixedArgs, true);
    FunctionCallee Native = Ctx.M.getOrInsertFunction(
        IsSscanf ? "sscanf" : (IsScanf ? "scanf" : "printf"), FT);
    CallInst *NewCall = B.CreateCall(FT, Native.getCallee(), Args,
                                     "native.vararg.direct");
    NewCall->setCallingConv(CI->getCallingConv());
    IRBuilder<> CopyBack(CI);
    for (const PendingScanfLocal &Pending : PendingLocals)
      CopyBack.CreateMemCpy(Pending.FramePointer, Align(1), Pending.Local,
                           Pending.Local->getAlign(), Pending.Slice.Width);
    CI->replaceAllUsesWith(NewCall);
    CI->eraseFromParent();
    ++Ctx.Report.VarargRecovered;
    Changed = true;
  }
  Changed |= CanonicalizeDirectScanfFrameDestinations(Ctx);
  return Changed;
}

bool BrightenExternCallBridgePass::LowerLiftedExternalABICalls(
    ExternCallContext &Ctx) {
  SmallVector<CallInst *, 32> Work;
  for (Function &F : Ctx.M)
    if (!F.isDeclaration())
      for (Instruction &I : instructions(F))
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *Callee = CI->getCalledFunction())
            if (Callee->getName().ends_with(".lifted_abi"))
              Work.push_back(CI);

  bool Changed = false;
  for (CallInst *OldCall : Work) {
    Function *OldCallee = OldCall->getCalledFunction();
    StringRef Name = OldCallee->getName();
    Name = Name.drop_back(StringRef(".lifted_abi").size());
    const LibcSignature *Sig = Ctx.SigDB.lookup(Name);
    if (!Sig || Sig->IsVarArg || OldCall->arg_size() != Sig->FixedParams.size())
      continue;

    FunctionType *Expected = Ctx.SigDB.buildFunctionType(
        Ctx.M.getContext(), *Sig);
    Function *Native = Ctx.M.getFunction(Name);
    if (!Native || Native->getFunctionType() != Expected)
      continue;

    IRBuilder<> B(OldCall);
    SmallVector<Value *, 8> Args;
    bool Valid = true;
    for (unsigned I = 0; I < Expected->getNumParams(); ++I) {
      Value *OldArg = OldCall->getArgOperand(I);
      Type *DstTy = Expected->getParamType(I);
      Value *Arg = nullptr;
      if (DstTy->isPointerTy() && OldArg->getType()->isIntegerTy()) {
        if (auto *PTI = dyn_cast<PtrToIntInst>(OldArg))
          Arg = PTI->getPointerOperand();
        else if (auto *CE = dyn_cast<ConstantExpr>(OldArg);
                 CE && CE->getOpcode() == Instruction::PtrToInt)
          Arg = CE->getOperand(0);
      }
      if (!Arg)
        Arg = CoerceToType(B, OldArg, DstTy);
      if (!Arg) {
        Valid = false;
        break;
      }
      Args.push_back(Arg);
    }
    if (!Valid)
      continue;

    CallInst *NewCall = B.CreateCall(Native, Args, "native.lifted_abi.ret");
    NewCall->setCallingConv(Native->getCallingConv());
    Value *Replacement = CoerceToType(B, NewCall, OldCall->getType());
    if (!Replacement) {
      NewCall->eraseFromParent();
      continue;
    }
    OldCall->replaceAllUsesWith(Replacement);
    OldCall->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_extern
