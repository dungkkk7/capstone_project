#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include <cstring>

namespace brighten_global {

using namespace llvm;

static std::optional<uint64_t> TryExtractGuestAddr(Value *V,
                                                    const GlobalDataContext &Ctx);

static std::optional<uint64_t> ParseGlobalBase(GlobalValue *GV,
                                                const GlobalDataContext &Ctx) {
  for (auto &Seg : Ctx.Segments) {
    if (Seg->GV == GV && Seg->BaseResolved)
      return Seg->GuestBase;
  }
  return std::nullopt;
}

static std::optional<uint64_t> TryExtractGuestAddr(Value *V,
                                                    const GlobalDataContext &Ctx) {
  if (!V)
    return std::nullopt;

  if (auto *CI = dyn_cast<ConstantInt>(V))
    return CI->getZExtValue();

  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::IntToPtr &&
        isa<ConstantInt>(CE->getOperand(0)))
      return cast<ConstantInt>(CE->getOperand(0))->getZExtValue();
    if (CE->getOpcode() == Instruction::PtrToInt)
      return TryExtractGuestAddr(CE->getOperand(0), Ctx);
    if (CE->getOpcode() == Instruction::GetElementPtr) {
      auto *GEP = cast<GEPOperator>(CE);
      Value *Base = GEP->getPointerOperand();
      auto BaseAddr = TryExtractGuestAddr(Base, Ctx);
      if (!BaseAddr)
        return std::nullopt;
      const DataLayout &DL = Ctx.DL;
      APInt Offset(DL.getPointerSizeInBits(), 0);
      if (!GEP->accumulateConstantOffset(DL, Offset))
        return std::nullopt;
      return *BaseAddr + Offset.getZExtValue();
    }
    if (CE->getOpcode() == Instruction::Add) {
      auto LHS = TryExtractGuestAddr(CE->getOperand(0), Ctx);
      auto RHS = TryExtractGuestAddr(CE->getOperand(1), Ctx);
      if (LHS && RHS)
        return *LHS + *RHS;
      return std::nullopt;
    }
    if (CE->getOpcode() == Instruction::Sub) {
      auto LHS = TryExtractGuestAddr(CE->getOperand(0), Ctx);
      auto RHS = TryExtractGuestAddr(CE->getOperand(1), Ctx);
      if (LHS && RHS)
        return *LHS - *RHS;
      return std::nullopt;
    }
  }

  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return TryExtractGuestAddr(PTI->getPointerOperand(), Ctx);

  if (auto *ITP = dyn_cast<IntToPtrInst>(V))
    return TryExtractGuestAddr(ITP->getOperand(0), Ctx);

  if (auto *GEP = dyn_cast<GetElementPtrInst>(V)) {
    auto BaseAddr = TryExtractGuestAddr(GEP->getPointerOperand(), Ctx);
    if (!BaseAddr)
      return std::nullopt;
    APInt Offset(Ctx.DL.getPointerSizeInBits(), 0);
    if (!GEP->accumulateConstantOffset(Ctx.DL, Offset))
      return std::nullopt;
    return *BaseAddr + Offset.getZExtValue();
  }

  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return ParseGlobalBase(GV, Ctx);
  if (auto *GA = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = GA->getAliasee())
      return TryExtractGuestAddr(Aliasee, Ctx);
  }

  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::Add) {
      auto LHS = TryExtractGuestAddr(BO->getOperand(0), Ctx);
      auto RHS = TryExtractGuestAddr(BO->getOperand(1), Ctx);
      if (LHS && RHS)
        return *LHS + *RHS;
    }
    if (BO->getOpcode() == Instruction::Sub) {
      auto LHS = TryExtractGuestAddr(BO->getOperand(0), Ctx);
      auto RHS = TryExtractGuestAddr(BO->getOperand(1), Ctx);
      if (LHS && RHS)
        return *LHS - *RHS;
    }
  }

  return std::nullopt;
}

static std::pair<DataConsumerKind, EvidenceKind> ClassifyConsumerAndEvidence(
    Instruction *User, Value *AddrVal, unsigned &Confidence) {
  Confidence = 1;
  if (!User)
    return {DataConsumerKind::Unknown, EvidenceKind::NoConflictingOverlap};

  if (auto *LI = dyn_cast<LoadInst>(User)) {
    Confidence = 20;
    return {DataConsumerKind::LoadStorePointer, EvidenceKind::LoadStoreWidth};
  }
  if (auto *SI = dyn_cast<StoreInst>(User)) {
    if (SI->getPointerOperand() == AddrVal) {
      Confidence = 20;
      return {DataConsumerKind::LoadStorePointer, EvidenceKind::LoadStoreWidth};
    }
    return {DataConsumerKind::IntegerAddressConsumer, EvidenceKind::LoadStoreWidth};
  }

  if (auto *CI = dyn_cast<CallInst>(User)) {
    Function *Callee = CI->getCalledFunction();
    if (Callee) {
      StringRef Name = Callee->getName();
      unsigned ArgIdx = 999;
      for (unsigned I = 0; I < CI->arg_size(); ++I) {
        if (CI->getArgOperand(I) == AddrVal) {
          ArgIdx = I;
          break;
        }
      }

      if ((Name == "puts" && ArgIdx == 0) ||
          (Name == "strlen" && ArgIdx == 0) ||
          (Name == "strdup" && ArgIdx == 0) ||
          (Name == "atoi" && ArgIdx == 0) ||
          (Name == "atol" && ArgIdx == 0) ||
          (Name == "strtol" && ArgIdx == 0) ||
          (Name == "strtoul" && ArgIdx == 0) ||
          (Name == "strcmp" && (ArgIdx == 0 || ArgIdx == 1)) ||
          (Name == "strncmp" && (ArgIdx == 0 || ArgIdx == 1)) ||
          (Name == "strcpy" && ArgIdx == 1) ||
          (Name == "strncpy" && ArgIdx == 1) ||
          (Name == "strcat" && ArgIdx == 1) ||
          (Name == "strchr" && ArgIdx == 0) ||
          (Name == "strstr" && (ArgIdx == 0 || ArgIdx == 1))) {
        Confidence = 100;
        return {DataConsumerKind::LibcStringArg, EvidenceKind::LibcStringArg};
      }

      if (((Name == "printf" || Name == "scanf") && ArgIdx == 0) ||
          ((Name == "fprintf" || Name == "sprintf" || Name == "sscanf") && ArgIdx == 1) ||
          ((Name == "snprintf") && ArgIdx == 2)) {
        Confidence = 120;
        return {DataConsumerKind::LibcStringArg, EvidenceKind::FormatStringArg};
      }

      if (((Name == "memcpy" || Name == "memmove") && (ArgIdx == 0 || ArgIdx == 1)) ||
          (Name == "memset" && ArgIdx == 0) ||
          (Name == "write" && ArgIdx == 1) ||
          (Name == "fwrite" && ArgIdx == 0) ||
          (Name == "send" && ArgIdx == 1)) {
        Confidence = 80;
        return {DataConsumerKind::LibcWriteBufferArg, EvidenceKind::NoConflictingOverlap};
      }

      if (Name == "__remill_jump") {
        Confidence = 150;
        return {DataConsumerKind::NativePointerConsumer, EvidenceKind::JumpTableUse};
      }
    }
    Confidence = 10;
    return {DataConsumerKind::NativePointerConsumer, EvidenceKind::PointerTableUse};
  }

  if (auto *ICI = dyn_cast<ICmpInst>(User)) {
    Confidence = 40;
    return {DataConsumerKind::ComparisonOnly, EvidenceKind::AddressIdentityObserved};
  }

  if (isa<BinaryOperator>(User)) {
    Confidence = 30;
    return {DataConsumerKind::ArithmeticOnly, EvidenceKind::AddressIdentityObserved};
  }

  if (isa<IntToPtrInst>(User) || isa<BitCastInst>(User) || isa<PtrToIntInst>(User)) {
    Confidence = 15;
    return {DataConsumerKind::NativePointerConsumer, EvidenceKind::PointerTableUse};
  }

  return {DataConsumerKind::Unknown, EvidenceKind::NoConflictingOverlap};
}

static GlobalVariable *FindReferencedGlobal(Value *V) {
  if (!V)
    return nullptr;
  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return GV;
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (unsigned I = 0; I < CE->getNumOperands(); ++I) {
      if (auto *GV = FindReferencedGlobal(CE->getOperand(I)))
        return GV;
    }
  }
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    return FindReferencedGlobal(GEP->getPointerOperand());
  }
  return nullptr;
}

static void AddAddressRef(Value *V, Instruction *Inst, const GlobalDataContext &Ctx,
                          SmallVectorImpl<std::unique_ptr<GuestAddressRef>> &Refs) {
  auto Addr = TryExtractGuestAddr(V, Ctx);
  if (!Addr)
    return;

  GlobalVariable *GV = FindReferencedGlobal(V);
  GuestSegment *Seg = nullptr;
  if (GV) {
    for (auto &S : Ctx.Segments) {
      if (S->GV == GV) {
        Seg = S.get();
        break;
      }
    }
  }
  if (!Seg) {
    Seg = Ctx.findSegmentForAddr(*Addr);
  }

  auto Ref = std::make_unique<GuestAddressRef>();
  Ref->GuestAddr = *Addr;
  Ref->Segment = Seg;
  Ref->OffsetInSegment = Seg ? (*Addr - Seg->GuestBase) : 0;
  Ref->OriginalValue = V;
  Ref->UserInst = Inst;

  unsigned Confidence = 0;
  auto Classified = ClassifyConsumerAndEvidence(Inst, V, Confidence);
  Ref->ConsumerKind = Classified.first;

  UseEvidence Ev;
  Ev.Kind = Classified.second;
  Ev.Inst = Inst;
  Ev.Confidence = Confidence;
  Ref->EvidenceList.push_back(Ev);

  if (Seg && Seg->ReadOnly) {
    UseEvidence SegEv;
    SegEv.Kind = EvidenceKind::ReadonlySection;
    SegEv.Confidence = 10;
    Ref->EvidenceList.push_back(SegEv);
  }

  if (!Seg) {
    Ref->SkipReason = "address-out-of-segment";
  }

  Refs.push_back(std::move(Ref));
}

static void FindConstantExprRefs(Value *V, Instruction *Inst, const GlobalDataContext &Ctx,
                                 SmallVectorImpl<std::unique_ptr<GuestAddressRef>> &Refs) {
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    AddAddressRef(CE, Inst, Ctx, Refs);
    for (unsigned I = 0; I < CE->getNumOperands(); ++I) {
      FindConstantExprRefs(CE->getOperand(I), Inst, Ctx, Refs);
    }
  } else if (auto *GV = dyn_cast<GlobalValue>(V)) {
    AddAddressRef(GV, Inst, Ctx, Refs);
  }
}

bool BrightenGlobalDataRecoveryPass::BuildGuestAddressMap(
    GlobalDataContext &Ctx) {
  Module &M = Ctx.M;
  unsigned Count = 0;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpIdx = 0; OpIdx < I.getNumOperands(); ++OpIdx) {
          Value *Op = I.getOperand(OpIdx);
          FindConstantExprRefs(Op, &I, Ctx, Ctx.AddressRefs);
        }
      }
    }
  }

  Count = Ctx.AddressRefs.size();
  Ctx.Report.GuestAddressRefsDiscovered = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] discovered " << Count
           << " guest address refs\n";

  return Count > 0;
}

} // namespace brighten_global
