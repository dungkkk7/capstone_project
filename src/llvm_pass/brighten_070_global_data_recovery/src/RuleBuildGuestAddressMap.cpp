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

// McSema's data aliases carry the original guest virtual address in their
// name (for example, @data_405040).  Do not recompute that address from the
// LLVM aggregate GEP: segment aggregates may contain target-specific
// alignment/padding which is not the ELF virtual-address layout.  Using the
// GEP's DataLayout offset here can silently turn 0x405040 into a different
// guest address and make external-call output pointers point at unrelated
// globals.
static std::optional<uint64_t> TryExtractNamedDataAddr(const GlobalValue *GV) {
  if (!GV)
    return std::nullopt;
  StringRef Name = GV->getName();
  if (!Name.starts_with("data_"))
    return std::nullopt;

  uint64_t Addr = 0;
  StringRef Hex = Name.drop_front(StringRef("data_").size());
  if (Hex.empty() || Hex.getAsInteger(16, Addr))
    return std::nullopt;
  return Addr;
}

static std::optional<uint64_t> ParseGlobalBase(GlobalValue *GV,
                                                const GlobalDataContext &Ctx) {
  for (auto &Seg : Ctx.Segments) {
    if (Seg->GV == GV && Seg->BaseResolved)
      return Seg->GuestBase;
  }
  return std::nullopt;
}

static std::optional<uint64_t> TryGetUInt64(const APInt &Value) {
  if (!Value.isIntN(64))
    return std::nullopt;
  return Value.getLimitedValue();
}

static std::optional<uint64_t> TryGetOffset64(const APInt &Value) {
  if (Value.isIntN(64))
    return Value.getLimitedValue();
  if (!Value.isSignedIntN(64))
    return std::nullopt;
  return Value.trunc(64).getZExtValue();
}

static std::optional<uint64_t> TryExtractGuestAddr(Value *V,
                                                    const GlobalDataContext &Ctx) {
  if (!V)
    return std::nullopt;

  if (auto *CI = dyn_cast<ConstantInt>(V))
    return TryGetUInt64(CI->getValue());

  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    auto *U = cast<User>(CE);
    if (CE->getOpcode() == Instruction::IntToPtr &&
        isa<ConstantInt>(U->getOperand(0)))
      return TryGetUInt64(
          cast<ConstantInt>(U->getOperand(0))->getValue());
    if (CE->getOpcode() == Instruction::PtrToInt)
      return TryExtractGuestAddr(U->getOperand(0), Ctx);
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
      auto Offset64 = TryGetOffset64(Offset);
      if (!Offset64)
        return std::nullopt;
      return *BaseAddr + *Offset64;
    }
    if (CE->getOpcode() == Instruction::Add) {
      auto LHS = TryExtractGuestAddr(U->getOperand(0), Ctx);
      auto RHS = TryExtractGuestAddr(U->getOperand(1), Ctx);
      if (LHS && RHS)
        return *LHS + *RHS;
      return std::nullopt;
    }
    if (CE->getOpcode() == Instruction::Sub) {
      auto LHS = TryExtractGuestAddr(U->getOperand(0), Ctx);
      auto RHS = TryExtractGuestAddr(U->getOperand(1), Ctx);
      if (LHS && RHS)
        return *LHS - *RHS;
      return std::nullopt;
    }
  }

  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return TryExtractGuestAddr(PTI->getPointerOperand(), Ctx);

  if (auto *ITP = dyn_cast<IntToPtrInst>(V))
    return TryExtractGuestAddr(ITP->getOperand(0), Ctx);

  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    auto BaseAddr = TryExtractGuestAddr(GEP->getPointerOperand(), Ctx);
    if (!BaseAddr)
      return std::nullopt;
    APInt Offset(Ctx.DL.getPointerSizeInBits(), 0);
    if (!GEP->accumulateConstantOffset(Ctx.DL, Offset))
      return std::nullopt;
    auto Offset64 = TryGetOffset64(Offset);
    if (!Offset64)
      return std::nullopt;
    return *BaseAddr + *Offset64;
  }

  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return ParseGlobalBase(GV, Ctx);
  if (auto *GA = dyn_cast<GlobalAlias>(V)) {
    // The alias name is the authoritative guest address.  This must be
    // checked before following the aliasee GEP (see comment above).
    if (auto NamedAddr = TryExtractNamedDataAddr(GA))
      return NamedAddr;
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

static bool IsExternalStringWrapper(StringRef Name, std::string &LibcName) {
  StringRef Func = Name;
  if (Name.starts_with("ext_")) {
    size_t FirstUnderscore = Name.find("_");
    if (FirstUnderscore != StringRef::npos) {
      size_t SecondUnderscore = Name.find("_", FirstUnderscore + 1);
      if (SecondUnderscore != StringRef::npos) {
        Func = Name.substr(SecondUnderscore + 1);
      }
    }
  }
  size_t Dot = Func.find(".");
  if (Dot != StringRef::npos)
    Func = Func.substr(0, Dot);

  std::string Cleaned = Func.str();
  if (Func.starts_with("__isoc99_"))
    Cleaned = Cleaned.substr(9);
  if (Func.ends_with("_chk"))
    Cleaned = Cleaned.substr(0, Cleaned.size() - 4);

  if (Cleaned == "puts" || Cleaned == "strlen" || Cleaned == "strdup" ||
      Cleaned == "atoi" || Cleaned == "atol" || Cleaned == "strtol" ||
      Cleaned == "strtoul" || Cleaned == "strcmp" || Cleaned == "strncmp" ||
      Cleaned == "strcpy" || Cleaned == "strncpy" || Cleaned == "strcat" ||
      Cleaned == "strchr" || Cleaned == "strstr" || Cleaned == "printf" ||
      Cleaned == "scanf" || Cleaned == "vprintf" || Cleaned == "vscanf" ||
      Cleaned == "fprintf" || Cleaned == "sprintf" ||
      Cleaned == "sscanf" || Cleaned == "snprintf" ||
      Cleaned == "memcpy" || Cleaned == "memmove" || Cleaned == "memset") {
    LibcName = Cleaned;
    return true;
  }
  return false;
}

static int64_t GetStateOffset(Value *V) {
  if (!V) return -1;
  V = V->stripPointerCasts();
  if (auto *GA = dyn_cast<GlobalAlias>(V)) {
    V = GA->getAliasee()->stripPointerCasts();
  }
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    if (auto *GV = dyn_cast<GlobalValue>(GEP->getPointerOperand())) {
      if (GV->getName().contains("State") || GV->getName().contains("reg_state")) {
        const DataLayout &DL = GV->getParent()->getDataLayout();
        APInt Offset(DL.getPointerSizeInBits(), 0);
        if (GEP->accumulateConstantOffset(DL, Offset)) {
          return Offset.getSExtValue();
        }
      }
    }
  }
  if (V->hasName()) {
    StringRef Name = V->getName();
    size_t Underscore = Name.find("_");
    if (Underscore != StringRef::npos) {
      StringRef OffsetPart = Name.substr(Underscore + 1);
      size_t NextUnderscore = OffsetPart.find("_");
      if (NextUnderscore != StringRef::npos)
        OffsetPart = OffsetPart.substr(0, NextUnderscore);
      uint64_t OffsetVal = 0;
      if (!OffsetPart.getAsInteger(10, OffsetVal)) {
        return OffsetVal;
      }
    }
    if (Name.starts_with("state")) {
      uint64_t OffsetVal = 0;
      if (!Name.drop_front(5).getAsInteger(10, OffsetVal)) {
        return OffsetVal;
      }
    }
    if (Name.contains("RDI") || Name.contains("rdi")) return 2296;
    if (Name.contains("RSI") || Name.contains("rsi")) return 2280;
    if (Name.contains("RDX") || Name.contains("rdx")) return 2264;
    if (Name.contains("RCX") || Name.contains("rcx")) return 2248;
    if (Name.contains("R8")  || Name.contains("r8"))  return 2344;
    if (Name.contains("R9")  || Name.contains("r9"))  return 2360;
  }
  return -1;
}

static bool StateRegisterMatchesLibcArg(int64_t Offset, StringRef LibcName) {
  if (Offset == -1)
    return false;

  if (LibcName == "puts" || LibcName == "strlen" || LibcName == "strdup" ||
      LibcName == "atoi" || LibcName == "atol" || LibcName == "strtol" || LibcName == "strtoul") {
    return Offset == 2296;
  }
  if (LibcName == "strcmp" || LibcName == "strncmp" || LibcName == "strchr" || LibcName == "strstr") {
    return Offset == 2296 || Offset == 2280;
  }
  if (LibcName == "strcpy" || LibcName == "strncpy" || LibcName == "strcat") {
    return Offset == 2280;
  }
  if (LibcName == "printf" || LibcName == "scanf" ||
      LibcName == "vprintf" || LibcName == "vscanf") {
    return Offset == 2296;
  }
  if (LibcName == "fprintf" || LibcName == "sprintf" || LibcName == "sscanf") {
    return Offset == 2280;
  }
  if (LibcName == "snprintf") {
    return Offset == 2264;
  }
  if (LibcName == "memcpy" || LibcName == "memmove") {
    return Offset == 2296 || Offset == 2280;
  }
  if (LibcName == "memset") {
    return Offset == 2296;
  }
  return false;
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
    
    Value *Dest = SI->getPointerOperand();
    int64_t Offset = GetStateOffset(Dest);
    if (Offset != -1) {
      BasicBlock *BB = SI->getParent();
      Instruction *Next = SI->getNextNode();
      while (Next) {
        if (auto *CI = dyn_cast<CallInst>(Next)) {
          Function *Callee = CI->getCalledFunction();
          if (Callee) {
            StringRef CalleeName = Callee->getName();
            if (CalleeName.starts_with("__translate_") || CalleeName.starts_with("llvm.")) {
              Next = Next->getNextNode();
              continue;
            }
            std::string LibcName;
            if (IsExternalStringWrapper(CalleeName, LibcName)) {
              if (StateRegisterMatchesLibcArg(Offset, LibcName)) {
                if (LibcName == "printf" || LibcName == "scanf" ||
                    LibcName == "vprintf" || LibcName == "vscanf" ||
                    LibcName == "fprintf" || LibcName == "sprintf" ||
                    LibcName == "sscanf" || LibcName == "snprintf") {
                  Confidence = 120;
                  return {DataConsumerKind::LibcStringArg, EvidenceKind::FormatStringArg};
                } else {
                  Confidence = 100;
                  return {DataConsumerKind::LibcStringArg, EvidenceKind::LibcStringArg};
                }
              }
            }
          }
          break;
        }
        Next = Next->getNextNode();
      }
    }
    return {DataConsumerKind::IntegerAddressConsumer, EvidenceKind::LoadStoreWidth};
  }

  if (auto *CI = dyn_cast<CallInst>(User)) {
    Function *Callee = CI->getCalledFunction();
    if (Callee) {
      std::string NameStr = Callee->getName().str();
      if (Callee->getName().starts_with("__isoc99_"))
        NameStr = NameStr.substr(9);
      if (Callee->getName().ends_with("_chk"))
        NameStr = NameStr.substr(0, NameStr.size() - 4);
      StringRef Name = NameStr;

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

      if (((Name == "printf" || Name == "scanf" ||
            Name == "vprintf" || Name == "vscanf") && ArgIdx == 0) ||
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
  V = V->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return GV;
  if (auto *GA = dyn_cast<GlobalAlias>(V)) {
    return FindReferencedGlobal(GA->getAliasee());
  }
  if (auto *U = dyn_cast<User>(V)) {
    for (unsigned I = 0; I < U->getNumOperands(); ++I) {
      if (auto *GV = FindReferencedGlobal(U->getOperand(I)))
        return GV;
    }
  }
  return nullptr;
}

static bool IsNamedDataAddress(const Module &M, uint64_t Addr) {
  for (const GlobalAlias &GA : M.aliases()) {
    StringRef Name = GA.getName();
    if (!Name.starts_with("data_"))
      continue;
    uint64_t AliasAddr = 0;
    StringRef Hex = Name.drop_front(StringRef("data_").size());
    if (!Hex.empty() && !Hex.getAsInteger(16, AliasAddr) &&
        AliasAddr == Addr)
      return true;
  }
  return false;
}

// Earlier repair/devirt passes can fold ptrtoint(@data_x) into the original
// guest address before this pass runs. Recover that provenance only for a
// dynamic arithmetic expression which is subsequently consumed as a pointer;
// a bare integer in a call/store remains an ordinary scalar or intrinsic
// immediate and must not be rewritten.
static bool EventuallyFeedsPointerConsumer(Value *V,
                                           SmallPtrSetImpl<Value *> &Seen,
                                           unsigned Depth = 0) {
  if (!V || Depth > 12 || !Seen.insert(V).second)
    return false;
  for (User *U : V->users()) {
    if (isa<IntToPtrInst>(U))
      return true;
    if (auto *CI = dyn_cast<CallInst>(U)) {
      if (Function *Callee = CI->getCalledFunction()) {
        // The translator is the lifted ABI's pointer boundary.  Its result
        // is consumed as a native pointer by a later cleanup pass, so an
        // address expression reaching this call has guest-pointer
        // provenance even though the final inttoptr is not present yet.
        if (Callee->getName() == "__translate_guest_pointer")
          return true;
      }
    }
    if (auto *CE = dyn_cast<ConstantExpr>(U)) {
      if (CE->getOpcode() == Instruction::IntToPtr)
        return true;
      continue;
    }
    if (isa<CastInst>(U) || isa<BinaryOperator>(U) || isa<PHINode>(U) ||
        isa<SelectInst>(U)) {
      if (EventuallyFeedsPointerConsumer(cast<Value>(U), Seen, Depth + 1))
        return true;
    }
  }
  return false;
}

static bool IsFoldedDynamicGuestAddress(Value *V, Instruction *Inst,
                                        const GlobalDataContext &Ctx) {
  auto *CI = dyn_cast<ConstantInt>(V);
  auto *BO = dyn_cast_or_null<BinaryOperator>(Inst);
  if (!CI || !BO || (BO->getOpcode() != Instruction::Add &&
                     BO->getOpcode() != Instruction::Sub))
    return false;

  auto Addr = TryGetUInt64(CI->getValue());
  if (!Addr)
    return false;
  GuestSegment *Seg = Ctx.findSegmentForAddr(*Addr);
  if (!Seg || Seg->Executable)
    return false;

  bool IsOperand = false;
  for (Value *Op : BO->operands())
    IsOperand |= Op == V;
  if (!IsOperand)
    return false;

  // Once a named alias has been folded into its ELF address, the only
  // remaining provenance can be `guest_base + dynamic_index`.  A writable
  // guest-segment address in that exact form is a pointer carrier even when
  // it first travels through a recovered native call rather than directly to
  // inttoptr/translate.  Record it so global-data recovery can replace the
  // constant base with a native object address before ABI lowering.
  Value *Other = BO->getOperand(0) == V ? BO->getOperand(1)
                                        : BO->getOperand(0);
  if (Seg->Writable && Other->getType()->isIntegerTy() &&
      !isa<Constant>(Other))
    return true;

  SmallPtrSet<Value *, 32> Seen;
  return EventuallyFeedsPointerConsumer(Inst, Seen);
}

static bool EventuallyFeedsStringConsumer(Value *V,
                                           SmallPtrSetImpl<Value *> &Seen,
                                           unsigned Depth = 0) {
  if (!V || Depth > 24 || !Seen.insert(V).second)
    return false;
  for (User *U : V->users()) {
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (SI->getValueOperand() == V) {
        unsigned Confidence = 0;
        if (ClassifyConsumerAndEvidence(SI, V, Confidence).first ==
            DataConsumerKind::LibcStringArg)
          return true;
      }
    }
    if (auto *CI = dyn_cast<CallInst>(U)) {
      unsigned Confidence = 0;
      if (ClassifyConsumerAndEvidence(CI, V, Confidence).first ==
          DataConsumerKind::LibcStringArg)
        return true;
      if (Function *Callee = CI->getCalledFunction())
        if (Callee->getName() == "__translate_guest_pointer" &&
            EventuallyFeedsStringConsumer(CI, Seen, Depth + 1))
          return true;
    }
    if (isa<CastInst>(U) || isa<BinaryOperator>(U) || isa<PHINode>(U) ||
        isa<SelectInst>(U) || isa<GetElementPtrInst>(U))
      if (EventuallyFeedsStringConsumer(cast<Value>(U), Seen, Depth + 1))
        return true;
  }
  return false;
}

static bool IsFoldedConstantGuestString(Value *V, Instruction *Inst,
                                        const GlobalDataContext &Ctx) {
  auto *CI = dyn_cast<ConstantInt>(V);
  if (!CI || !Inst)
    return false;

  auto AddrValue = TryGetUInt64(CI->getValue());
  if (!AddrValue)
    return false;
  uint64_t Addr = *AddrValue;
  GuestSegment *Seg = Ctx.findSegmentForAddr(Addr);
  if (!Seg || Seg->Executable || !Seg->ReadOnly)
    return false;

  uint64_t Off = Addr - Seg->GuestBase;
  if (Off >= Seg->FlatBytes.size())
    return false;
  uint64_t End = Off;
  constexpr uint64_t MaxStringProbe = 4096;
  while (End < Seg->FlatBytes.size() &&
         End - Off < MaxStringProbe && Seg->FlatBytes[End] != 0) {
    uint8_t C = Seg->FlatBytes[End];
    if (!((C >= 0x20 && C <= 0x7e) || C == '\n' || C == '\r' ||
          C == '\t'))
      return false;
    ++End;
  }
  if (End == Off || End >= Seg->FlatBytes.size() ||
      Seg->FlatBytes[End] != 0)
    return false;

  unsigned Confidence = 0;
  if (ClassifyConsumerAndEvidence(Inst, V, Confidence).first ==
      DataConsumerKind::LibcStringArg)
    return true;

  // Alias DCE may leave only the integer address in a select/phi before the
  // native pointer boundary.  The read-only, printable, NUL-terminated range
  // above proves storage; require the value flow to prove a string consumer.
  SmallPtrSet<Value *, 32> Seen;
  return EventuallyFeedsStringConsumer(Inst, Seen);
}

static void AddAddressRef(Value *V, Instruction *Inst, const GlobalDataContext &Ctx,
                          SmallVectorImpl<std::unique_ptr<GuestAddressRef>> &Refs) {
  for (auto &Existing : Refs) {
    if (Existing->OriginalValue == V && Existing->UserInst == Inst)
      return;
  }
  auto Addr = TryExtractGuestAddr(V, Ctx);
  if (!Addr)
    return;

  // A raw integer operand is not, by itself, guest-pointer provenance.  The
  // lifted IR contains ordinary constants in stores/calls (zero fill bytes,
  // sizes, flags, and intrinsic immargs); treating all of them as addresses
  // can rewrite an i1/i8/i64 constant into ptrtoint and produce invalid IR.
  // Keep folded-address recovery narrow: either the value still matches a
  // named ELF data alias, or it is the base of a dynamic arithmetic tree that
  // demonstrably reaches a pointer consumer.
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    auto ConstantAddr = TryGetUInt64(CI->getValue());
    if ((!ConstantAddr || !IsNamedDataAddress(Ctx.M, *ConstantAddr)) &&
        !IsFoldedDynamicGuestAddress(V, Inst, Ctx) &&
        !IsFoldedConstantGuestString(V, Inst, Ctx))
      return;
  }

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

  bool FoldedString = IsFoldedConstantGuestString(V, Inst, Ctx);
  unsigned Confidence = 0;
  auto Classified = ClassifyConsumerAndEvidence(Inst, V, Confidence);
  Ref->ConsumerKind = Classified.first;
  if (FoldedString) {
    Classified = {DataConsumerKind::LibcStringArg,
                  EvidenceKind::LibcStringArg};
    Ref->ConsumerKind = Classified.first;
    Confidence = 100;
  }

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
  if (!V)
    return;
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    // Optimisation can fold ptrtoint(@data_x) into an integer before this
    // analysis runs.  Recover only the narrow form that is still visibly an
    // address carrier: a select choosing between named ELF data addresses.
    // Reinterpreting arbitrary integer literals as pointers would be unsafe.
    auto ConstantAddr = TryGetUInt64(CI->getValue());
    if ((isa<SelectInst>(Inst) && ConstantAddr &&
         IsNamedDataAddress(Ctx.M, *ConstantAddr)) ||
        IsFoldedDynamicGuestAddress(CI, Inst, Ctx) ||
        IsFoldedConstantGuestString(CI, Inst, Ctx))
      AddAddressRef(V, Inst, Ctx, Refs);
    return;
  }
  auto Addr = TryExtractGuestAddr(V, Ctx);
  if (Addr) {
    AddAddressRef(V, Inst, Ctx, Refs);
    return;
  }
  if (auto *C = dyn_cast<Constant>(V)) {
    if (!isa<GlobalValue>(C)) {
      if (auto *U = dyn_cast<User>(C)) {
        for (unsigned I = 0; I < U->getNumOperands(); ++I) {
          FindConstantExprRefs(U->getOperand(I), Inst, Ctx, Refs);
        }
      }
    }
  }
}

static bool IsStackPointer(Value *V) {
  if (!V) return false;
  V = V->stripPointerCasts();
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    Value *Ptr = LI->getPointerOperand()->stripPointerCasts();
    if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
      if (auto *GV = dyn_cast<GlobalValue>(GEP->getPointerOperand())) {
        if (GV->getName().contains("State") || GV->getName().contains("reg_state")) {
          const DataLayout &DL = GV->getParent()->getDataLayout();
          APInt Offset(DL.getPointerSizeInBits(), 0);
          if (GEP->accumulateConstantOffset(DL, Offset)) {
            int64_t Off = Offset.getSExtValue();
            if (Off == 2312 || Off == 2328) {
              return true;
            }
          }
        }
      }
    }
    if (auto *GV = dyn_cast<GlobalValue>(Ptr)) {
      if (GV->getName().contains("RSP") || GV->getName().contains("RBP") ||
          GV->getName().contains("rsp") || GV->getName().contains("rbp")) {
        return true;
      }
    }
  }
  if (V->hasName()) {
    StringRef Name = V->getName();
    if (Name.contains("RSP") || Name.contains("RBP") ||
        Name.contains("rsp") || Name.contains("rbp") ||
        Name.contains("state_2312") || Name.contains("state_2328")) {
      return true;
    }
  }
  return false;
}

static bool IsLikelyGuestAddress(Value *V, Instruction *Inst, unsigned OpIdx) {
  if (!Inst)
    return true;

  if (auto *GEP = dyn_cast<GetElementPtrInst>(Inst)) {
    if (OpIdx > 0)
      return false;
  }

  if (auto *BO = dyn_cast<BinaryOperator>(Inst)) {
    if (BO->getOpcode() == Instruction::Shl ||
        BO->getOpcode() == Instruction::LShr ||
        BO->getOpcode() == Instruction::AShr) {
      if (OpIdx == 1)
        return false;
    }
    if (BO->getOpcode() == Instruction::Add ||
        BO->getOpcode() == Instruction::Sub) {
      Value *OtherOp = BO->getOperand(1 - OpIdx);
      if (IsStackPointer(OtherOp))
        return false;
    }
  }

  if (auto *SI = dyn_cast<SwitchInst>(Inst)) {
    if (OpIdx > 0)
      return false;
  }

  return true;
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
          if (IsLikelyGuestAddress(Op, &I, OpIdx)) {
            if (isa<LoadInst>(I) || isa<StoreInst>(I) || isa<CallInst>(I)) {
              if (TryExtractGuestAddr(Op, Ctx)) {
                AddAddressRef(Op, &I, Ctx, Ctx.AddressRefs);
              }
            }
            FindConstantExprRefs(Op, &I, Ctx, Ctx.AddressRefs);
          }
        }
      }
    }
  }

  Count = Ctx.AddressRefs.size();
  Ctx.Report.GuestAddressRefsDiscovered = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] discovered " << Count
           << " guest address refs\n";

  return false; // Analysis only, does not modify IR
}

} // namespace brighten_global
