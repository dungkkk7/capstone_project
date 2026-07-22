#include "NativeCleanupInternal.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/PatternMatch.h"

using namespace llvm;
using namespace llvm::PatternMatch;

namespace brighten_native_cleanup {

bool isNativeStateSlot(Value *V) {
  auto *GEP = dyn_cast<GEPOperator>(V ? V->stripPointerCasts() : nullptr);
  if (!GEP)
    return false;
  auto *BaseArg = dyn_cast<Argument>(GEP->getPointerOperand());
  if (!BaseArg || BaseArg->getArgNo() != 0 ||
      !BaseArg->getType()->isPointerTy())
    return false;

  const DataLayout &DL = BaseArg->getParent()->getParent()->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base != BaseArg || Offset.isNegative())
    return false;
  uint64_t Bytes = Offset.getZExtValue();
  // State-SSA lays out the CPU register/flag region at this offset range.
  // The bridge has already normalized pointer-valued ABI registers and the
  // entrypoint initializes RSP from a native alloca, so values loaded from
  // this region and used for memory addresses are native pointer integers.
  return Bytes >= 2065 && Bytes < 2500;
}

bool isNativeInteger(Value *V, SmallPtrSetImpl<Value *> &Visited) {
  if (!V)
    return false;
  // A loop-carried state PHI can revisit itself.  The first traversal must
  // establish a non-constant native source; revisiting that SSA cycle does
  // not introduce a new unknown source.
  if (!Visited.insert(V).second)
    return true;
  if (isa<ConstantInt>(V))
    return false;

  if (auto *Arg = dyn_cast<Argument>(V)) {
    StringRef Name = Arg->getName();
    return Name.starts_with("arg_RDI") || Name.starts_with("arg_RSI") ||
           Name.starts_with("arg_RDX") || Name.starts_with("arg_RCX") ||
           Name.starts_with("arg_R8") || Name.starts_with("arg_R9");
  }

  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return isNativePointerValue(PTI->getPointerOperand(), Visited);
  if (auto *LI = dyn_cast<LoadInst>(V))
    return isNativeStateSlot(LI->getPointerOperand()) ||
           IsNativeVarargSaveSlot(LI->getPointerOperand());
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    bool HasDynamic = false;
    for (Value *Op : BO->operands()) {
      if (isa<ConstantInt>(Op))
        continue;
      HasDynamic = true;
      if (!isNativeInteger(Op, Visited))
        return false;
    }
    return HasDynamic;
  }
  if (auto *Cast = dyn_cast<CastInst>(V))
    return isNativeInteger(Cast->getOperand(0), Visited);
  if (auto *PN = dyn_cast<PHINode>(V)) {
    bool HasDynamic = false;
    for (Value *Incoming : PN->incoming_values())
      if (isa<ConstantInt>(Incoming))
        continue;
      else if (!isNativeInteger(Incoming, Visited))
        return false;
      else
        HasDynamic = true;
    return HasDynamic;
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    bool TrueOK = isa<ConstantInt>(Sel->getTrueValue()) ||
                  isNativeInteger(Sel->getTrueValue(), Visited);
    bool FalseOK = isa<ConstantInt>(Sel->getFalseValue()) ||
                   isNativeInteger(Sel->getFalseValue(), Visited);
    return TrueOK && FalseOK;
  }
  return false;
}

bool isNativePointerValue(Value *V,
                                 SmallPtrSetImpl<Value *> &Visited) {
  if (!V || !Visited.insert(V).second)
    return false;
  if (isa<AllocaInst>(V) || isa<Argument>(V))
    return V->getType()->isPointerTy();
  if (auto *GV = dyn_cast<GlobalValue>(V))
    return !isAddressArtifact(GV);
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return isNativePointerValue(GEP->getPointerOperand(), Visited);
  if (auto *PN = dyn_cast<PHINode>(V)) {
    for (Value *Incoming : PN->incoming_values())
      if (!isNativePointerValue(Incoming, Visited))
        return false;
    return true;
  }
  if (auto *Sel = dyn_cast<SelectInst>(V))
    return isNativePointerValue(Sel->getTrueValue(), Visited) &&
           isNativePointerValue(Sel->getFalseValue(), Visited);
  if (auto *CB = dyn_cast<CallBase>(V)) {
    Function *Callee = CB->getCalledFunction();
    return V->getType()->isPointerTy() &&
           (!Callee || !Callee->getName().starts_with(
                           "__translate_guest_pointer"));
  }
  return false;
}

Value *getDirectNativePointerCarrier(Value *V) {
  if (!V)
    return nullptr;
  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return PTI->getPointerOperand();
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt)
      return CE->getOperand(0);
  }
  return nullptr;
}

Value *findNativeVarargAddressCarrier(Value *V,
                                             SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;

  auto ValidateCarrier = [](Value *Candidate) -> Value * {
    if (!Candidate)
      return nullptr;
    // Do not peel a frame anchor out of a larger stack-address expression.
    // For example, inttoptr(ptrtoint(frame_top) - 16) contains a native
    // pointer carrier syntactically, but replacing the whole argument with
    // frame_top drops the -16 destination offset.  Stack expressions must be
    // lowered by lowerNativeStackInteger instead.
    SmallPtrSet<Value *, 16> StackSeen;
    if (isNativeStackPointer(Candidate, StackSeen))
      return nullptr;
    SmallPtrSet<Value *, 16> NativeSeen;
    if (!isNativePointerValue(Candidate, NativeSeen))
      return nullptr;
    return Candidate;
  };

  if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
    if (PTI->getName().starts_with("native.vararg.address"))
      return ValidateCarrier(PTI->getPointerOperand());
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt)
      return ValidateCarrier(CE->getOperand(0));
  }

  // A carrier may be hidden behind representation-only casts.  Do not walk
  // arbitrary arithmetic/GEP/load operands: finding ptrtoint(@global) inside
  //   inttoptr(base + index * stride + field_offset)
  // does not make @global equivalent to the complete address.  The previous
  // recursive search dropped the dynamic and field offsets from such libc
  // arguments (notably ryou[i].dim passed to memcmp).
  if (auto *Cast = dyn_cast<CastInst>(V))
    return findNativeVarargAddressCarrier(Cast->getOperand(0), Seen);
  if (auto *Freeze = dyn_cast<FreezeInst>(V))
    return findNativeVarargAddressCarrier(Freeze->getOperand(0), Seen);
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->isCast())
      return findNativeVarargAddressCarrier(CE->getOperand(0), Seen);
    return nullptr;
  }

  auto FindCommonCarrier = [&](auto Values) -> Value * {
    Value *Common = nullptr;
    for (Value *Arm : Values) {
      Value *Candidate = findNativeVarargAddressCarrier(Arm, Seen);
      if (!Candidate || (Common && Common != Candidate))
        return nullptr;
      Common = Candidate;
    }
    return Common;
  };
  if (auto *PN = dyn_cast<PHINode>(V))
    return FindCommonCarrier(PN->incoming_values());
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    SmallVector<Value *, 2> Arms{Sel->getTrueValue(), Sel->getFalseValue()};
    return FindCommonCarrier(Arms);
  }
  return nullptr;
}

// O3 can fold a translated variadic pointer into the guest-range dispatch
// that materializeRecoveredDataPointer created.  The resulting select no
// longer has a representation-only path from the call argument to
// native.vararg.address, so the deliberately shallow search above cannot
// recover it.  A deep search is safe only for one of our own dispatch trees:
// require the OOB scratch artifact and exactly one marked native carrier.
Value *findNativeVarargCarrierInRecoveredDispatch(Value *V) {
  SmallPtrSet<Value *, 32> Seen;
  Value *UniqueCarrier = nullptr;
  bool HasRecoveredScratch = false;
  bool Ambiguous = false;

  std::function<void(Value *)> Visit = [&](Value *Current) {
    if (!Current || Ambiguous || !Seen.insert(Current).second)
      return;
    if (auto *GV = dyn_cast<GlobalVariable>(Current->stripPointerCasts())) {
      if (GV->getName() == "native.recovered.oob.scratch")
        HasRecoveredScratch = true;
    }
    if (auto *PTI = dyn_cast<PtrToIntInst>(Current)) {
      if (PTI->getName().starts_with("native.vararg.address")) {
        Value *Candidate = PTI->getPointerOperand();
        SmallPtrSet<Value *, 16> StackSeen;
        SmallPtrSet<Value *, 16> NativeSeen;
        if (!isNativeStackPointer(Candidate, StackSeen) &&
            isNativePointerValue(Candidate, NativeSeen)) {
          if (UniqueCarrier && UniqueCarrier != Candidate)
            Ambiguous = true;
          else
            UniqueCarrier = Candidate;
        }
      }
    }
    if (auto *I = dyn_cast<Instruction>(Current)) {
      for (Value *Operand : I->operands())
        Visit(Operand);
    } else if (auto *CE = dyn_cast<ConstantExpr>(Current)) {
      for (Value *Operand : CE->operands())
        Visit(Operand);
    }
  };
  Visit(V);
  return HasRecoveredScratch && !Ambiguous ? UniqueCarrier : nullptr;
}

std::optional<uint64_t> parseGuestAddressPrefix(StringRef Name,
                                                       StringRef Prefix) {
  if (!Name.starts_with(Prefix))
    return std::nullopt;
  StringRef Rest = Name.drop_front(Prefix.size());
  size_t HexDigits = 0;
  while (HexDigits < Rest.size()) {
    char C = Rest[HexDigits];
    bool IsHex = (C >= '0' && C <= '9') || (C >= 'a' && C <= 'f') ||
                 (C >= 'A' && C <= 'F');
    if (!IsHex)
      break;
    ++HexDigits;
  }
  if (!HexDigits)
    return std::nullopt;
  uint64_t Address = 0;
  if (Rest.take_front(HexDigits).getAsInteger(16, Address))
    return std::nullopt;
  return Address;
}

void setGuestBaseMetadata(Module &M, GlobalVariable &GV,
                                 uint64_t GuestBase) {
  LLVMContext &Ctx = M.getContext();
  Constant *Base = ConstantInt::get(Type::getInt64Ty(Ctx), GuestBase);
  GV.setMetadata("brighten.guest.base",
                 MDNode::get(Ctx, {ConstantAsMetadata::get(Base)}));
}

unsigned lowerProvenNativePointerTranslations(Module &M,
                                                      bool &Changed) {
  Function *Translator = M.getFunction("__translate_guest_pointer");
  if (!Translator || Translator->isDeclaration())
    return 0;

  SmallVector<CallInst *, 128> Calls;
  for (Function &F : M) {
    if (&F == Translator)
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && CI->getCalledFunction() == Translator)
          Calls.push_back(CI);
      }
    }
  }

  unsigned Lowered = 0;
  struct DynamicGuestAddress {
    GlobalVariable *Segment = nullptr;
    uint64_t Offset = 0;
    Value *Dynamic = nullptr;
  };

  auto FindDynamicGuestAddress = [&](Value *V, auto &&Self)
      -> std::optional<DynamicGuestAddress> {
    if (!V)
      return std::nullopt;
    if (auto *Cast = dyn_cast<CastInst>(V))
      return Self(Cast->getOperand(0), Self);
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (!BO || BO->getOpcode() != Instruction::Add ||
        !BO->getType()->isIntegerTy())
      return std::nullopt;

    auto Direct = [&](Value *ConstantSide, Value *DynamicSide)
        -> std::optional<DynamicGuestAddress> {
      if (auto *CI = dyn_cast<ConstantInt>(ConstantSide)) {
        auto Match =
            FindRecoveredGlobalForGuestAddress(M, CI->getZExtValue());
        if (!Match)
          return std::nullopt;
        return DynamicGuestAddress{Match->first, Match->second, DynamicSide};
      }

      Value *PointerBase = nullptr;
      if (auto *CE = dyn_cast<ConstantExpr>(ConstantSide)) {
        if (CE->getOpcode() == Instruction::PtrToInt)
          PointerBase = CE->getOperand(0);
      } else if (auto *PTI = dyn_cast<PtrToIntInst>(ConstantSide)) {
        PointerBase = PTI->getPointerOperand();
      }
      auto *GV = dyn_cast_or_null<GlobalVariable>(
          PointerBase ? PointerBase->stripPointerCasts() : nullptr);
      if (!GV || GV->isDeclaration())
        return std::nullopt;
      return DynamicGuestAddress{GV, 0, DynamicSide};
    };
    if (auto Match = Direct(BO->getOperand(0), BO->getOperand(1)))
      return Match;
    if (auto Match = Direct(BO->getOperand(1), BO->getOperand(0)))
      return Match;

    auto Left = Self(BO->getOperand(0), Self);
    auto Right = Self(BO->getOperand(1), Self);
    if (Left && !Right) {
      IRBuilder<> B(BO);
      Left->Dynamic = B.CreateAdd(Left->Dynamic, BO->getOperand(1),
                                  "native.translated.offset");
      return Left;
    }
    if (Right && !Left) {
      IRBuilder<> B(BO);
      Right->Dynamic = B.CreateAdd(Right->Dynamic, BO->getOperand(0),
                                   "native.translated.offset");
      return Right;
    }
    return std::nullopt;
  };

  for (CallInst *CI : Calls) {
    if (CI->arg_size() != 1)
      continue;
    Value *Address = CI->getArgOperand(0);
    Value *RoundTripPointer = nullptr;
    if (auto *CE = dyn_cast<ConstantExpr>(Address)) {
      if (CE->getOpcode() == Instruction::PtrToInt)
        RoundTripPointer = CE->getOperand(0);
    } else if (auto *PTI = dyn_cast<PtrToIntInst>(Address)) {
      RoundTripPointer = PTI->getPointerOperand();
    }
    if (RoundTripPointer) {
      IRBuilder<> B(CI);
      Value *NativePtr = RoundTripPointer;
      if (NativePtr->getType() != CI->getType())
        NativePtr = B.CreatePointerCast(NativePtr, CI->getType(),
                                        "native.pointer.cast");
      CI->replaceAllUsesWith(NativePtr);
      CI->eraseFromParent();
      ++Lowered;
      Changed = true;
      continue;
    }
    if (auto *ConstantAddress = dyn_cast<ConstantInt>(Address)) {
      uint64_t GuestAddress = ConstantAddress->getZExtValue();
      GlobalVariable *NativeData = nullptr;
      uint64_t Offset = 0;
      for (GlobalVariable &GV : M.globals()) {
        StringRef Name = GV.getName();
        if (!Name.starts_with("native_data_") || GV.isDeclaration())
          continue;
        StringRef BaseText =
            Name.drop_front(StringRef("native_data_").size());
        uint64_t Base = 0;
        if (BaseText.getAsInteger(16, Base) || GuestAddress < Base)
          continue;
        uint64_t CandidateOffset = GuestAddress - Base;
        uint64_t Size = M.getDataLayout()
                            .getTypeAllocSize(GV.getValueType())
                            .getFixedValue();
        if (CandidateOffset >= Size)
          continue;
        NativeData = &GV;
        Offset = CandidateOffset;
        break;
      }
      if (NativeData) {
        IRBuilder<> B(CI);
        Value *NativePtr = B.CreateConstGEP1_64(
            B.getInt8Ty(), NativeData, Offset, "native.data.ptr");
        CI->replaceAllUsesWith(NativePtr);
        CI->eraseFromParent();
        ++Lowered;
        Changed = true;
        continue;
      }
    }
    if (auto Match = FindDynamicGuestAddress(Address, FindDynamicGuestAddress)) {
      IRBuilder<> B(CI);
      // A numeric RSP/RBP expression can accidentally look like guest base
      // zero after the lifted translator is inlined.  Its provenance is
      // stronger than the numeric range match: rebase it on the explicit
      // native stack anchor instead of manufacturing a pointer into an ELF
      // header/data blob.
      Value *NativePtr = lowerNativeStackInteger(B, Address, *CI->getFunction());
      if (!NativePtr) {
        // __translate_guest_pointer takes a full guest address.  The previous
        // lowering rebuilt some dynamic forms as "matched segment + dynamic",
        // which is only valid when Dynamic is a segment-local offset.  Raw
        // fuzzing exposes cases where Dynamic is already a full guest address
        // loaded from recovered state, producing pointers like
        //   @g_arr_0 + 0x40a7a4
        // instead of dispatching 0x40a7a4 to the recovered data object.  Use
        // the central recovered-range mapper for the full address and keep the
        // old segment arithmetic only as a defensive fallback.
        NativePtr = materializeRecoveredDataPointer(M, B, Address);
      }
      if (!NativePtr) {
        Value *Offset = Match->Dynamic;
        if (Match->Offset != 0)
          Offset = B.CreateAdd(Offset, B.getInt64(Match->Offset),
                               "native.translated.segment.offset");
        if (!Offset->getType()->isIntegerTy(64))
          Offset = B.CreateZExtOrTrunc(Offset, B.getInt64Ty(),
                                       "native.translated.offset.ext");
        NativePtr = B.CreateGEP(B.getInt8Ty(), Match->Segment, Offset,
                                "native.translated.segment.ptr");
      }
      CI->replaceAllUsesWith(NativePtr);
      CI->eraseFromParent();
      ++Lowered;
      Changed = true;
      continue;
    }
    // Preserve the original translator fallback for an address whose guest
    // range is not statically recoverable.  This is intentionally a dynamic
    // inttoptr: native integers (heap pointers, stack pointers, callbacks)
    // already use host addresses at this point, while recovered data and
    // explicit guest-base arithmetic took the native GEP paths above.
    IRBuilder<> B(CI);
    Value *NativePtr =
        B.CreateIntToPtr(Address, CI->getType(), "native.dynamic.pointer");
    CI->replaceAllUsesWith(NativePtr);
    CI->eraseFromParent();
    ++Lowered;
    Changed = true;
  }

  if (Translator->use_empty()) {
    Translator->eraseFromParent();
    Changed = true;
  }
  return Lowered;
}

bool IsNativeVarargSaveSlot(Value *Ptr) {
  auto *GEP = dyn_cast<GEPOperator>(Ptr ? Ptr->stripPointerCasts() : nullptr);
  if (!GEP || GEP->getNumIndices() == 0)
    return false;
  auto *AI = dyn_cast<AllocaInst>(GEP->getPointerOperand()->stripPointerCasts());
  if (!AI || !AI->getName().contains("reg_save_area"))
    return false;
  auto It = GEP->idx_end();
  --It;
  auto *Offset = dyn_cast<ConstantInt>(*It);
  if (!Offset)
    return false;
  uint64_t ByteOffset = Offset->getZExtValue();
  return ByteOffset <= 40 && (ByteOffset % 8) == 0;
}

// A lifted stack pointer is carried as an integer state slot until the final
// native ABI lowering.  Preserve that provenance even when arithmetic has
// been folded or split across several SSA instructions.
bool containsNativeStackInteger(
    Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  auto PointsAtFrameStorage = [&](Value *P, auto &&Self) -> bool {
    if (!P)
      return false;
    P = P->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(P))
      return GV->getName().starts_with("frame_storage_backing.");
    if (auto *AI = dyn_cast<AllocaInst>(P)) {
      auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
      StringRef Name = AI->getName();
      return AT && AT->getElementType()->isIntegerTy(8) &&
             (Name.starts_with("frame_storage") ||
              Name.starts_with("native_stack_storage"));
    }
    if (auto *GEP = dyn_cast<GEPOperator>(P))
      return Self(GEP->getPointerOperand(), Self);
    return false;
  };
  if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
    if (PointsAtFrameStorage(PTI->getPointerOperand(), PointsAtFrameStorage))
      return true;
  }
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt &&
        PointsAtFrameStorage(CE->getOperand(0), PointsAtFrameStorage))
      return true;
    for (Value *Op : CE->operands())
      if (Op->getType()->isIntegerTy() &&
          containsNativeStackInteger(Op, Seen))
        return true;
  }
  StringRef Name = V->getName();
  if (Name.contains("state_2312") || Name.contains("state_2328") ||
      Name.contains("state_in_2312") || Name.contains("state_in_2328") ||
      Name.contains("new_rsp") || Name.contains("new_rbp"))
    return true;
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    if (auto *GEP = dyn_cast<GEPOperator>(LI->getPointerOperand())) {
      auto *State = dyn_cast<GlobalVariable>(
          GEP->getPointerOperand()->stripPointerCasts());
      if (State && State->getName().contains("__mcsema_reg_state") &&
          GEP->getNumIndices() != 0) {
        auto It = GEP->idx_end();
        --It;
        if (auto *Offset = dyn_cast<ConstantInt>(*It))
          if (Offset->equalsInt(2312) || Offset->equalsInt(2328))
            return true;
      }
    }
  }
  if (auto *EV = dyn_cast<ExtractValueInst>(V)) {
    ArrayRef<unsigned> Indices = EV->getIndices();
    if (Indices.size() == 1 && (Indices.front() == 4 || Indices.front() == 5)) {
      // State-SSA returns the architectural RSP/RBP pair at tuple slots 4/5
      // for the compact native result used by recovered lifted callees.  Do
      // not infer this from tuple position alone: require the callee's
      // explicit hidden-state argument contract before propagating stack
      // provenance through extractvalue.
      if (auto *CB = dyn_cast<CallBase>(EV->getAggregateOperand())) {
        if (Function *Callee = CB->getCalledFunction()) {
          if (Callee->arg_size() >= 2) {
            auto It = Callee->arg_begin();
            Argument *StateRSP = &*It++;
            Argument *StateRBP = &*It;
            if (StateRSP->getName() == "state_in_2312" &&
                StateRBP->getName() == "state_in_2328")
              return true;
          }
        }
      }
    }
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return false;
  for (Value *Op : I->operands())
    if (Op->getType()->isIntegerTy() &&
        containsNativeStackInteger(Op, Seen))
      return true;
  return false;
}

Argument *findNativeStackArgument(Function &F) {
  for (Argument &Arg : F.args())
    if ((Arg.getName() == "native_stack" || Arg.getName() == "frame_base") &&
        Arg.getType()->isPointerTy())
      return &Arg;
  return nullptr;
}

// Native entry wrappers have no frame_base parameter, but State-SSA preserves
// their real stack backing as an entry-block frame_storage alloca.  It is a
// valid anchor for rebasing the remaining integer RSP/RBP values because it
// dominates every use in that wrapper.
Value *findNativeStackAnchor(Function &F) {
  if (Argument *Arg = findNativeStackArgument(F))
    return Arg;
  if (F.empty())
    return nullptr;
  for (Instruction &I : F.getEntryBlock()) {
    if (!I.getType()->isPointerTy())
      continue;
    StringRef Name = I.getName();
    if (Name.starts_with("frame_top") ||
        Name.starts_with("native_stack_top"))
      return &I;
  }
  for (Instruction &I : F.getEntryBlock()) {
    if (!I.getType()->isPointerTy())
      continue;
    StringRef Name = I.getName();
    if (Name.starts_with("frame_storage") ||
        Name.starts_with("native_stack_storage"))
      return &I;
  }
  // A module-level frame backing is used only for a native entry wrapper that
  // has no stack argument.  Prefer an explicitly named owner before using a
  // unique fallback; multiple entry backings otherwise require provenance.
  std::string BackingName = "frame_storage_backing.";
  BackingName += F.getName().str();
  if (GlobalVariable *NamedBacking =
          F.getParent()->getNamedGlobal(BackingName))
    return NamedBacking;
  GlobalVariable *OnlyBacking = nullptr;
  for (GlobalVariable &GV : F.getParent()->globals()) {
    if (!GV.getName().starts_with("frame_storage_backing."))
      continue;
    if (OnlyBacking)
      return nullptr;
    OnlyBacking = &GV;
  }
  return OnlyBacking;
}

Value *getNativeStackFrameTop(IRBuilder<> &B, Function &F,
                                     Value *NativeStack) {
  if (!NativeStack)
    return nullptr;
  if (isa<Argument>(NativeStack))
    return NativeStack;
  StringRef StackName = NativeStack->getName();
  if (StackName.starts_with("frame_top") ||
      StackName.starts_with("native_stack_top"))
    return NativeStack;
  if (!F.empty()) {
    for (Instruction &I : F.getEntryBlock()) {
      if (!I.getType()->isPointerTy())
        continue;
      StringRef Name = I.getName();
      if (Name.starts_with("frame_top") ||
          Name.starts_with("native_stack_top"))
        return &I;
    }
  }

  // frame_storage_backing.* is the complete recovered stack object, not the
  // logical RSP/RBP anchor.  Relative stack offsets are measured from the
  // entry frame top; materializing them from the global base writes locals
  // before the stack object and makes scanf/output slots disagree.
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  constexpr uint64_t NativeStackTop = NativeStackBytes - 64 * 1024;
  if (isa<GlobalVariable>(NativeStack) ||
      StackName.starts_with("frame_storage") ||
      StackName.starts_with("native_stack_storage"))
    return B.CreateConstGEP1_64(B.getInt8Ty(), NativeStack, NativeStackTop,
                                "native.stack.frame.top");
  return NativeStack;
}

Value *findInitialStateStackInteger(Function &F) {
  if (F.empty())
    return nullptr;
  const DataLayout &DL = F.getParent()->getDataLayout();

  // The entry stack anchor is the value seeded into architectural RSP.  RBP
  // is not an interchangeable baseline: it is commonly zero at the native
  // boundary and is established by the lifted prologue only afterwards.  If
  // an RSP-derived address is rebased against that initial RBP load, the
  // resulting GEP contains the full host pointer as an offset from the local
  // frame (frame + rsp), which is immediately out of bounds.
  //
  // Prefer the explicit RSP seed store.  State-SSA entry lowering deliberately
  // emits this store before the recovered body, while an optimizing pipeline
  // may have no corresponding load left at all.
  for (Instruction &I : F.getEntryBlock()) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || !SI->getValueOperand()->getType()->isIntegerTy(64))
      continue;
    auto *GEP = dyn_cast<GEPOperator>(SI->getPointerOperand());
    if (!GEP)
      continue;
    auto *State = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!State || !State->getName().contains("__mcsema_reg_state"))
      continue;
    APInt Offset(64, 0);
    if (GEP->accumulateConstantOffset(DL, Offset) && Offset == 2312)
      return SI->getValueOperand();
  }

  // Older inputs can expose the pre-seeded RSP only as a load.  Keep that
  // compatibility path restricted to RSP; choosing the first RSP-or-RBP load
  // made the result depend on instruction order and corrupted valid frames.
  for (Instruction &I : F.getEntryBlock()) {
    auto *LI = dyn_cast<LoadInst>(&I);
    if (!LI || !LI->getType()->isIntegerTy(64))
      continue;
    auto *GEP = dyn_cast<GEPOperator>(LI->getPointerOperand());
    if (!GEP)
      continue;
    auto *State = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!State || !State->getName().contains("__mcsema_reg_state"))
      continue;
    APInt Offset(64, 0);
    if (GEP->accumulateConstantOffset(DL, Offset) && Offset == 2312)
      return LI;
  }
  return nullptr;
}

// Entry stack seeds can be algebraic instructions placed after an earlier
// inttoptr that cleanup is currently lowering.  Reusing that later SSA value
// creates invalid dominance.  Materialize only its pure integer expression
// cone at the current insertion point; memory reads, PHIs and side effects
// remain hard barriers.
Value *materializeEntryIntegerAt(
    Value *V, IRBuilder<> &B, Function &F,
    DenseMap<Value *, Value *> &Mapped,
    SmallVectorImpl<Instruction *> &Created, unsigned Depth) {
  if (!V || Depth > 24) return nullptr;
  if (isa<Constant>(V) || isa<Argument>(V)) return V;
  auto It = Mapped.find(V);
  if (It != Mapped.end()) return It->second;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getFunction() != &F || I->getParent() != &F.getEntryBlock())
    return nullptr;
  BasicBlock *InsertBlock = B.GetInsertBlock();
  auto InsertPoint = B.GetInsertPoint();
  if (InsertBlock != I->getParent() || InsertPoint == InsertBlock->end() ||
      I->comesBefore(&*InsertPoint))
    return V;
  if (isa<PHINode>(I) || I->isTerminator() || I->mayReadOrWriteMemory() ||
      I->mayHaveSideEffects() || !I->getType()->isIntegerTy())
    return nullptr;
  Instruction *Clone = I->clone();
  for (unsigned O = 0; O != Clone->getNumOperands(); ++O) {
    Value *Operand = materializeEntryIntegerAt(
        Clone->getOperand(O), B, F, Mapped, Created, Depth + 1);
    if (!Operand) {
      Clone->deleteValue();
      return nullptr;
    }
    Clone->setOperand(O, Operand);
  }
  Clone->setName(I->getName() + ".native.entry");
  Clone->insertBefore(B.GetInsertPoint());
  Created.push_back(Clone);
  Mapped[V] = Clone;
  return Clone;
}

bool isNativeStackPointer(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  StringRef Name = V->getName();
  if (Name == "native_stack" || Name == "frame_base" ||
      Name.starts_with("native_stack_top") ||
      Name.starts_with("frame_top") ||
      Name.starts_with("native_stack_storage") ||
      Name.starts_with("frame_storage"))
    return true;
  if (auto *GV = dyn_cast<GlobalVariable>(V->stripPointerCasts()))
    return GV->getName().starts_with("frame_storage_backing.");
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return isNativeStackPointer(GEP->getPointerOperand(), Seen);
  if (auto *SI = dyn_cast<SelectInst>(V))
    return isNativeStackPointer(SI->getTrueValue(), Seen) ||
           isNativeStackPointer(SI->getFalseValue(), Seen);
  if (auto *ITP = dyn_cast<IntToPtrInst>(V)) {
    SmallPtrSet<Value *, 16> IntegerSeen;
    return containsNativeStackInteger(ITP->getOperand(0), IntegerSeen);
  }
  if (auto *Cast = dyn_cast<CastInst>(V))
    return isNativeStackPointer(Cast->getOperand(0), Seen);
  return false;
}

bool IsDirectControlPredicate(Instruction *I) {
  if (!I)
    return false;
  for (User *U : I->users()) {
    if (isa<ICmpInst>(U) || isa<FCmpInst>(U))
      return true;
  }
  return false;
}

// Relative-stack functions normally carry byte offsets.  A late cleanup can,
// however, encounter an RSP-derived value that was materialized before
// relativization and therefore still contains ptrtoint(frame_top).  Treating
// that absolute carrier as an offset produces frame_top + frame_top + delta.
bool containsNativeStackAnchorInteger(
    Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  Value *Pointer = nullptr;
  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    Pointer = PTI->getPointerOperand();
  else if (auto *CE = dyn_cast<ConstantExpr>(V);
           CE && CE->getOpcode() == Instruction::PtrToInt)
    Pointer = CE->getOperand(0);
  if (Pointer) {
    SmallPtrSet<Value *, 8> PointerSeen;
    if (isNativeStackPointer(Pointer, PointerSeen))
      return true;
  }
  if (auto *I = dyn_cast<Instruction>(V)) {
    for (Value *Op : I->operands())
      if (Op->getType()->isIntegerTy() &&
          containsNativeStackAnchorInteger(Op, Seen))
        return true;
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands())
      if (Op->getType()->isIntegerTy() &&
          containsNativeStackAnchorInteger(Op, Seen))
        return true;
  }
  return false;
}

static Value *lowerNativeStackIntegerImpl(IRBuilder<> &B, Value *Integer,
                                          Function &F,
                                          bool ProvenStackInteger) {
  Value *NativeStack = findNativeStackAnchor(F);
  if (!NativeStack || !Integer || !Integer->getType()->isIntegerTy())
    return nullptr;
  SmallPtrSet<Value *, 32> Seen;
  bool HasStackProvenance =
      ProvenStackInteger || containsNativeStackInteger(Integer, Seen);
  bool RelativeStack = F.hasFnAttribute("brighten.relative-stack");
  if (RelativeStack) {
    SmallPtrSet<Value *, 32> AnchorSeen;
    HasStackProvenance =
        HasStackProvenance ||
        containsNativeStackAnchorInteger(Integer, AnchorSeen);
  }
  if (!HasStackProvenance) {
    auto *CI = dyn_cast<ConstantInt>(Integer);
    if (!RelativeStack || !CI || !CI->getValue().isSignedIntN(19))
      return nullptr;
  }
  Value *Address = Integer;
  if (!Address->getType()->isIntegerTy(64))
    Address = B.CreateZExtOrTrunc(Address, B.getInt64Ty(),
                                  "native.stack.address");
  if (RelativeStack) {
    Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
    if (!FrameTop)
      FrameTop = NativeStack;
    SmallPtrSet<Value *, 32> AnchorSeen;
    if (containsNativeStackAnchorInteger(Address, AnchorSeen)) {
      Value *Anchor = B.CreatePtrToInt(FrameTop, B.getInt64Ty(),
                                       "native.stack.anchor");
      Address = B.CreateSub(Address, Anchor,
                            "native.stack.absolute.delta");
    }
    return B.CreateGEP(B.getInt8Ty(), FrameTop, Address,
                       "native.frame.gep");
  }
  // Late O3 can canonicalize a correct stack pointer into an absolute
  // carrier such as:
  //
  //   inttoptr(ptrtoint(frame_top) + -16)
  //
  // At that point the expression already contains the recovered frame anchor.
  // Rebasing it against a later architectural RSP store found in the entry
  // block can erase the delta and turn scanf destinations into plain
  // frame_top.  When the anchor is syntactically present, subtract that anchor
  // directly and do not consult State-entry seed stores.
  SmallPtrSet<Value *, 32> AbsoluteAnchorSeen;
  if (containsNativeStackAnchorInteger(Address, AbsoluteAnchorSeen)) {
    Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
    if (!FrameTop)
      FrameTop = NativeStack;
    Value *Anchor = B.CreatePtrToInt(FrameTop, B.getInt64Ty(),
                                     "native.stack.anchor");
    Value *Delta = B.CreateSub(Address, Anchor,
                               "native.stack.absolute.delta");
    return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta, "native.stack.gep");
  }
  // Entrypoint-native functions without a frame argument still read their
  // initial RSP/RBP from the canonical State global.  Rebase against that
  // entry value, not against the backing object's host address: algebraic
  // folding of `backing + (rsp - backing)` otherwise recreates inttoptr(rsp)
  // and loses the recovered frame provenance before entrypoint seeding.
  if (!findNativeStackArgument(F)) {
    if (Value *InitialStack = findInitialStateStackInteger(F)) {
      DenseMap<Value *, Value *> Mapped;
      SmallVector<Instruction *, 8> Created;
      Value *AvailableInitial = materializeEntryIntegerAt(
          InitialStack, B, F, Mapped, Created);
      if (!AvailableInitial) {
        for (Instruction *Clone : llvm::reverse(Created))
          if (Clone->use_empty()) Clone->eraseFromParent();
      } else {
      Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
      if (!FrameTop)
        FrameTop = NativeStack;
      Value *Delta = B.CreateSub(Address, AvailableInitial,
                                 "native.stack.entry.delta");
      return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta,
                         "native.stack.gep");
      }
    }
  }
  // A frame_storage_backing global represents the full recovered guest stack,
  // while the active logical RSP boundary is near its high end.  Use the same
  // frame-top convention as entrypoint stack lowering; rebasing on the global
  // base makes scanf destinations alias a different region than later native
  // stack GEPs in rollback-mode State-SSA cases.
  Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
  if (!FrameTop)
    FrameTop = NativeStack;
  Value *Anchor = B.CreatePtrToInt(FrameTop, B.getInt64Ty(),
                                   "native.stack.anchor");
  Value *Delta = B.CreateSub(Address, Anchor, "native.stack.delta");
  return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta, "native.stack.gep");
}

Value *lowerNativeStackInteger(IRBuilder<> &B, Value *Integer, Function &F) {
  return lowerNativeStackIntegerImpl(B, Integer, F, false);
}

namespace {

// Normalize the small affine address language emitted by State-SSA.  Pointer
// symbols and their ptrtoint forms intentionally share the same coefficient,
// so expressions such as
//
//   frame_base + ((state_in_2312 - 32) - ptrtoint(frame_base))
//
// reduce to { state_in_2312: 1, constant: -32 }.  This is used only to prove
// that an intervening memory write cannot alias a load; unsupported arithmetic
// fails closed and never supplies stack provenance by itself.
struct NativeAffineAddress {
  DenseMap<Value *, int64_t> Coefficients;
  int64_t MinConstant = 0;
  int64_t MaxConstant = 0;
};

static bool addNativeAffineCoefficient(NativeAffineAddress &Address,
                                       Value *Symbol, int64_t Delta) {
  int64_t Current = Address.Coefficients.lookup(Symbol);
  int64_t Next = 0;
  if (!addSignedOffset(Current, Delta, Next))
    return false;
  if (Next)
    Address.Coefficients[Symbol] = Next;
  else
    Address.Coefficients.erase(Symbol);
  return true;
}

static bool mergeNativeAffineAddress(NativeAffineAddress &Into,
                                     const NativeAffineAddress &From,
                                     int64_t Sign) {
  int64_t NewMin = 0;
  int64_t NewMax = 0;
  if (Sign == 1) {
    if (!addSignedOffset(Into.MinConstant, From.MinConstant, NewMin) ||
        !addSignedOffset(Into.MaxConstant, From.MaxConstant, NewMax))
      return false;
  } else {
    if (From.MaxConstant == std::numeric_limits<int64_t>::min() ||
        From.MinConstant == std::numeric_limits<int64_t>::min() ||
        !addSignedOffset(Into.MinConstant, -From.MaxConstant, NewMin) ||
        !addSignedOffset(Into.MaxConstant, -From.MinConstant, NewMax))
      return false;
  }
  if (NewMin > NewMax)
    return false;
  Into.MinConstant = NewMin;
  Into.MaxConstant = NewMax;
  for (auto [Symbol, Coefficient] : From.Coefficients) {
    if (Sign == -1 && Coefficient == std::numeric_limits<int64_t>::min())
      return false;
    if (!addNativeAffineCoefficient(Into, Symbol, Sign * Coefficient))
      return false;
  }
  return true;
}

static std::optional<NativeAffineAddress>
evaluateNativeAffinePointer(Value *V, const DataLayout &DL, unsigned Depth);

static bool collectDirectAggregateFieldValues(
    Value *Aggregate, unsigned Field, SmallVectorImpl<Value *> &Resolved,
    SmallPtrSetImpl<Value *> &Seen) {
  if (!Aggregate || !Seen.insert(Aggregate).second)
    return false;
  if (auto *PN = dyn_cast<PHINode>(Aggregate)) {
    for (Value *Incoming : PN->incoming_values())
      if (!collectDirectAggregateFieldValues(Incoming, Field, Resolved,
                                             Seen))
        return false;
    return true;
  }
  if (auto *SI = dyn_cast<SelectInst>(Aggregate))
    return collectDirectAggregateFieldValues(SI->getTrueValue(), Field,
                                             Resolved, Seen) &&
           collectDirectAggregateFieldValues(SI->getFalseValue(), Field,
                                             Resolved, Seen);
  auto *CB = dyn_cast<CallBase>(Aggregate);
  Function *Callee = CB ? CB->getCalledFunction() : nullptr;
  if (!CB || !Callee || Callee->isDeclaration())
    return false;
  bool SawReturn = false;
  for (BasicBlock &BB : *Callee) {
    auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
    if (!RI || !RI->getReturnValue())
      continue;
    SawReturn = true;
    Value *Current = RI->getReturnValue();
    Value *FieldValue = nullptr;
    while (auto *IV = dyn_cast<InsertValueInst>(Current)) {
      if (IV->getNumIndices() == 1 && *IV->idx_begin() == Field) {
        FieldValue = IV->getInsertedValueOperand();
        break;
      }
      Current = IV->getAggregateOperand();
    }
    if (!FieldValue)
      if (auto *C = dyn_cast<Constant>(Current))
        FieldValue = C->getAggregateElement(Field);
    if (!FieldValue)
      return false;
    if (auto *Arg = dyn_cast<Argument>(FieldValue)) {
      if (Arg->getParent() != Callee || Arg->getArgNo() >= CB->arg_size())
        return false;
      FieldValue = CB->getArgOperand(Arg->getArgNo());
    } else if (!isa<Constant>(FieldValue)) {
      return false;
    }
    Resolved.push_back(FieldValue);
  }
  return SawReturn;
}

static std::optional<NativeAffineAddress>
evaluateNativeAffineInteger(Value *V, const DataLayout &DL, unsigned Depth) {
  if (!V || Depth > 32 || !V->getType()->isIntegerTy())
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    if (!CI->getValue().isSignedIntN(64))
      return std::nullopt;
    NativeAffineAddress Result;
    Result.MinConstant = CI->getSExtValue();
    Result.MaxConstant = CI->getSExtValue();
    return Result;
  }
  if (auto *PTI = dyn_cast<PtrToIntOperator>(V))
    return evaluateNativeAffinePointer(PTI->getPointerOperand(), DL,
                                       Depth + 1);
  if (auto *Op = dyn_cast<Operator>(V);
      Op && (Op->getOpcode() == Instruction::Add ||
             Op->getOpcode() == Instruction::Sub)) {
    auto Left = evaluateNativeAffineInteger(Op->getOperand(0), DL, Depth + 1);
    auto Right = evaluateNativeAffineInteger(Op->getOperand(1), DL,
                                              Depth + 1);
    if (!Left || !Right ||
        !mergeNativeAffineAddress(*Left, *Right,
                                  Op->getOpcode() == Instruction::Add ? 1
                                                                      : -1))
      return std::nullopt;
    return Left;
  }
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    Value *Operand = Cast->getOperand(0);
    if (!Operand->getType()->isIntegerTy() ||
        Operand->getType()->getIntegerBitWidth() !=
            V->getType()->getIntegerBitWidth())
      return std::nullopt;
    return evaluateNativeAffineInteger(Operand, DL, Depth + 1);
  }
  auto MergeAlternatives = [&](auto Values)
      -> std::optional<NativeAffineAddress> {
    std::optional<NativeAffineAddress> Result;
    for (Value *Incoming : Values) {
      // A shallow dynamic merge often exposes the same affine RSP root on
      // every arm and is useful for forwarding stack spills.  Stop expanding
      // once nesting becomes non-trivial: the owning PHI/select is then a
      // stable symbolic atom, avoiding exponential work on flattened CFGs.
      if (!isa<ConstantInt>(Incoming) && Depth >= 8)
        return std::nullopt;
      auto Arm = evaluateNativeAffineInteger(Incoming, DL, Depth + 1);
      if (!Arm)
        return std::nullopt;
      if (!Result) {
        Result = std::move(Arm);
        continue;
      }
      if (Result->Coefficients.size() != Arm->Coefficients.size())
        return std::nullopt;
      for (auto [Symbol, Coefficient] : Result->Coefficients)
        if (Arm->Coefficients.lookup(Symbol) != Coefficient)
          return std::nullopt;
      Result->MinConstant =
          std::min(Result->MinConstant, Arm->MinConstant);
      Result->MaxConstant =
          std::max(Result->MaxConstant, Arm->MaxConstant);
    }
    return Result;
  };
  if (auto *EV = dyn_cast<ExtractValueInst>(V)) {
    if (EV->getNumIndices() != 1)
      return std::nullopt;
    unsigned Field = *EV->idx_begin();
    SmallVector<Value *, 8> Resolved;
    SmallPtrSet<Value *, 16> Seen;
    if (collectDirectAggregateFieldValues(EV->getAggregateOperand(), Field,
                                          Resolved, Seen))
      if (auto Merged = MergeAlternatives(Resolved))
        return Merged;
    return std::nullopt;
  }
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (auto Merged = MergeAlternatives(PN->incoming_values()))
      return Merged;
    // The alternatives need not share one affine expansion for the PHI itself
    // to be a stable symbolic coordinate.  Keeping the exact SSA value as an
    // atom lets two addresses based on that same dynamic state compare, while
    // addresses based on different symbols still cannot be declared disjoint.
    NativeAffineAddress Symbol;
    Symbol.Coefficients[V] = 1;
    return Symbol;
  }
  if (auto *SI = dyn_cast<SelectInst>(V)) {
    SmallVector<Value *, 2> Arms{SI->getTrueValue(), SI->getFalseValue()};
    if (auto Merged = MergeAlternatives(Arms))
      return Merged;
    NativeAffineAddress Symbol;
    Symbol.Coefficients[V] = 1;
    return Symbol;
  }
  if (isa<Argument>(V)) {
    NativeAffineAddress Result;
    Result.Coefficients[V] = 1;
    return Result;
  }
  return std::nullopt;
}

static std::optional<NativeAffineAddress>
evaluateNativeAffinePointer(Value *V, const DataLayout &DL, unsigned Depth) {
  if (!V || Depth > 32 || !V->getType()->isPointerTy())
    return std::nullopt;
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    auto Base = evaluateNativeAffinePointer(GEP->getPointerOperand(), DL,
                                            Depth + 1);
    if (!Base)
      return std::nullopt;
    APInt ConstantDelta(
        DL.getIndexSizeInBits(GEP->getPointerAddressSpace()), 0, true);
    if (GEP->accumulateConstantOffset(DL, ConstantDelta)) {
      if (!ConstantDelta.isSignedIntN(64) ||
          !addSignedOffset(Base->MinConstant, ConstantDelta.getSExtValue(),
                           Base->MinConstant) ||
          !addSignedOffset(Base->MaxConstant, ConstantDelta.getSExtValue(),
                           Base->MaxConstant))
        return std::nullopt;
      return Base;
    }
    if (!GEP->getSourceElementType()->isIntegerTy(8) ||
        GEP->getNumIndices() != 1)
      return std::nullopt;
    auto Index = evaluateNativeAffineInteger(GEP->idx_begin()->get(), DL,
                                             Depth + 1);
    if (!Index || !mergeNativeAffineAddress(*Base, *Index, 1))
      return std::nullopt;
    return Base;
  }
  if (auto *BC = dyn_cast<BitCastOperator>(V))
    return evaluateNativeAffinePointer(BC->getOperand(0), DL, Depth + 1);
  if (isa<Argument, AllocaInst, GlobalValue>(V)) {
    NativeAffineAddress Result;
    Result.Coefficients[V->stripPointerCasts()] = 1;
    return Result;
  }
  return std::nullopt;
}

static bool haveEqualNativeAffineRoots(const NativeAffineAddress &Left,
                                       const NativeAffineAddress &Right) {
  if (Left.Coefficients.size() != Right.Coefficients.size())
    return false;
  for (auto [Symbol, Coefficient] : Left.Coefficients)
    if (Right.Coefficients.lookup(Symbol) != Coefficient)
      return false;
  return true;
}

static bool areSameExactNativeAffineAddress(const NativeAffineAddress &Left,
                                            const NativeAffineAddress &Right) {
  return Left.MinConstant == Left.MaxConstant &&
         Right.MinConstant == Right.MaxConstant &&
         Left.MinConstant == Right.MinConstant &&
         haveEqualNativeAffineRoots(Left, Right);
}

static bool affineIntervalsMayOverlap(const NativeAffineAddress &Left,
                                      uint64_t LeftSize,
                                      const NativeAffineAddress &Right,
                                      uint64_t RightSize) {
  if (!LeftSize || !RightSize || LeftSize > uint64_t(INT64_MAX) ||
      RightSize > uint64_t(INT64_MAX) ||
      !haveEqualNativeAffineRoots(Left, Right))
    return false;
  int64_t LeftEnd = 0;
  int64_t RightEnd = 0;
  if (!addSignedOffset(Left.MaxConstant, int64_t(LeftSize), LeftEnd) ||
      !addSignedOffset(Right.MaxConstant, int64_t(RightSize), RightEnd))
    return true;
  return !(LeftEnd <= Right.MinConstant || RightEnd <= Left.MinConstant);
}

// Compute bounds for the loop-carried stack-address language produced by
// State-SSA.  The ordinary affine normalizer deliberately treats a PHI as an
// opaque symbol when its alternatives differ.  That is sufficient for exact
// forwarding, but it loses a useful fact for dead lifted call-frame stores:
// a loop may move RSP only downwards, so a dynamic slot is still provably
// below every fixed entry-frame slot.
//
// Model the supported SSA graph as difference constraints
//
//   value = predecessor + constant
//
// with PHI/select nodes taking the union of their incoming alternatives.
// Longest-path relaxation gives a finite upper bound across zero/negative
// cycles; a positive cycle is detected by the final relaxation and leaves the
// upper bound unknown.  The dual calculation handles lower bounds.  Every
// leaf must be a ptrtoint rooted in the same backing object.  Unsupported
// arithmetic and unseeded cycles fail closed.
struct FrameOffsetBounds {
  std::optional<int64_t> Lower;
  std::optional<int64_t> Upper;
};

struct FrameOffsetEquation {
  Value *Node = nullptr;
  std::optional<int64_t> Seed;
  SmallVector<std::pair<Value *, int64_t>, 4> Incoming;
};

static std::optional<FrameOffsetBounds>
evaluateLoopCarriedFrameIntegerBounds(Value *Root, Value &Backing,
                                      const DataLayout &DL) {
  if (!Root || !Root->getType()->isIntegerTy())
    return std::nullopt;

  constexpr unsigned MaxNodes = 4096;
  DenseMap<Value *, unsigned> NodeIndex;
  SmallVector<FrameOffsetEquation, 64> Equations;
  bool Valid = true;

  std::function<void(Value *)> Build = [&](Value *V) {
    if (!Valid || NodeIndex.contains(V))
      return;
    if (!V || !V->getType()->isIntegerTy() ||
        Equations.size() >= MaxNodes) {
      Valid = false;
      return;
    }
    unsigned Index = Equations.size();
    NodeIndex[V] = Index;
    Equations.push_back({V, std::nullopt, {}});
    FrameOffsetEquation &Equation = Equations[Index];

    if (auto *PTI = dyn_cast<PtrToIntOperator>(V)) {
      SmallPtrSet<Value *, 16> Seen;
      Equation.Seed = evaluateFramePointerOffset(
          PTI->getPointerOperand(), Backing, DL, Seen);
      if (!Equation.Seed)
        Valid = false;
      return;
    }

    auto AddIncoming = [&](Value *Pred, int64_t Delta) {
      Equation.Incoming.push_back({Pred, Delta});
      Build(Pred);
    };
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      Value *Pred = nullptr;
      ConstantInt *Constant = nullptr;
      int64_t Delta = 0;
      if (BO->getOpcode() == Instruction::Add) {
        Constant = dyn_cast<ConstantInt>(BO->getOperand(1));
        Pred = BO->getOperand(0);
        if (!Constant) {
          Constant = dyn_cast<ConstantInt>(BO->getOperand(0));
          Pred = BO->getOperand(1);
        }
      } else if (BO->getOpcode() == Instruction::Sub) {
        Constant = dyn_cast<ConstantInt>(BO->getOperand(1));
        Pred = BO->getOperand(0);
      }
      if (!Constant || !Constant->getValue().isSignedIntN(64)) {
        Valid = false;
        return;
      }
      Delta = Constant->getSExtValue();
      if (BO->getOpcode() == Instruction::Sub) {
        if (Delta == std::numeric_limits<int64_t>::min()) {
          Valid = false;
          return;
        }
        Delta = -Delta;
      }
      AddIncoming(Pred, Delta);
      return;
    }
    if (auto *PN = dyn_cast<PHINode>(V)) {
      if (PN->getNumIncomingValues() == 0) {
        Valid = false;
        return;
      }
      for (Value *Incoming : PN->incoming_values())
        AddIncoming(Incoming, 0);
      return;
    }
    if (auto *SI = dyn_cast<SelectInst>(V)) {
      AddIncoming(SI->getTrueValue(), 0);
      AddIncoming(SI->getFalseValue(), 0);
      return;
    }
    if (auto *FI = dyn_cast<FreezeInst>(V)) {
      AddIncoming(FI->getOperand(0), 0);
      return;
    }
    if (auto *Cast = dyn_cast<CastInst>(V)) {
      Value *Operand = Cast->getOperand(0);
      if (!Operand->getType()->isIntegerTy() ||
          Operand->getType()->getIntegerBitWidth() !=
              V->getType()->getIntegerBitWidth()) {
        Valid = false;
        return;
      }
      AddIncoming(Operand, 0);
      return;
    }
    Valid = false;
  };
  Build(Root);
  if (!Valid || Equations.empty())
    return std::nullopt;

  // An SSA cycle is admissible only if it is ultimately seeded by a concrete
  // pointer into this backing.  This rejects self-contained poison/undef-like
  // recurrences instead of manufacturing a bound for them.
  SmallVector<bool, 64> ReachesSeed(Equations.size(), false);
  for (unsigned I = 0; I < Equations.size(); ++I)
    ReachesSeed[I] = Equations[I].Seed.has_value();
  for (unsigned Round = 0; Round < Equations.size(); ++Round) {
    bool Changed = false;
    for (unsigned I = 0; I < Equations.size(); ++I) {
      if (ReachesSeed[I])
        continue;
      for (auto [Pred, Delta] : Equations[I].Incoming) {
        (void)Delta;
        auto It = NodeIndex.find(Pred);
        if (It != NodeIndex.end() && ReachesSeed[It->second]) {
          ReachesSeed[I] = true;
          Changed = true;
          break;
        }
      }
    }
    if (!Changed)
      break;
  }
  if (llvm::any_of(ReachesSeed, [](bool Reachable) { return !Reachable; }))
    return std::nullopt;

  auto Solve = [&](bool Upper) -> std::optional<int64_t> {
    SmallVector<std::optional<int64_t>, 64> Bounds(Equations.size());
    for (unsigned I = 0; I < Equations.size(); ++I)
      Bounds[I] = Equations[I].Seed;
    bool ChangedOnFinalRound = false;
    for (unsigned Round = 0; Round <= Equations.size(); ++Round) {
      SmallVector<std::optional<int64_t>, 64> Next = Bounds;
      bool Changed = false;
      for (unsigned I = 0; I < Equations.size(); ++I) {
        for (auto [Pred, Delta] : Equations[I].Incoming) {
          auto It = NodeIndex.find(Pred);
          if (It == NodeIndex.end() || !Bounds[It->second])
            continue;
          int64_t Candidate = 0;
          if (!addSignedOffset(*Bounds[It->second], Delta, Candidate))
            return std::nullopt;
          if (!Next[I] || (Upper ? Candidate > *Next[I]
                                 : Candidate < *Next[I])) {
            Next[I] = Candidate;
            Changed = true;
          }
        }
      }
      Bounds.swap(Next);
      if (!Changed)
        break;
      ChangedOnFinalRound = Round == Equations.size();
    }
    if (ChangedOnFinalRound)
      return std::nullopt;
    auto It = NodeIndex.find(Root);
    if (It == NodeIndex.end())
      return std::nullopt;
    return Bounds[It->second];
  };

  FrameOffsetBounds Result;
  Result.Lower = Solve(false);
  Result.Upper = Solve(true);
  if (!Result.Lower && !Result.Upper)
    return std::nullopt;
  return Result;
}

static std::optional<FrameOffsetBounds>
evaluateBoundedFramePointer(Value *Pointer, Value &Backing,
                            const DataLayout &DL) {
  SmallPtrSet<Value *, 16> FixedSeen;
  if (auto Fixed =
          evaluateFramePointerOffset(Pointer, Backing, DL, FixedSeen))
    return FrameOffsetBounds{*Fixed, *Fixed};

  auto *GEP = dyn_cast<GEPOperator>(Pointer);
  if (!GEP || !GEP->getSourceElementType()->isIntegerTy(8) ||
      GEP->getNumIndices() != 1)
    return std::nullopt;
  SmallPtrSet<Value *, 16> BaseSeen;
  auto BaseOffset = evaluateFramePointerOffset(
      GEP->getPointerOperand(), Backing, DL, BaseSeen);
  auto *Delta = dyn_cast<BinaryOperator>(GEP->idx_begin()->get());
  auto *Anchor = Delta && Delta->getOpcode() == Instruction::Sub
                     ? dyn_cast<PtrToIntOperator>(Delta->getOperand(1))
                     : nullptr;
  if (!BaseOffset || !Anchor)
    return std::nullopt;
  SmallPtrSet<Value *, 16> AnchorSeen;
  auto AnchorOffset = evaluateFramePointerOffset(
      Anchor->getPointerOperand(), Backing, DL, AnchorSeen);
  if (!AnchorOffset)
    return std::nullopt;
  auto Logical = evaluateLoopCarriedFrameIntegerBounds(
      Delta->getOperand(0), Backing, DL);
  if (!Logical)
    return std::nullopt;

  int64_t Adjustment = 0;
  if (*AnchorOffset == std::numeric_limits<int64_t>::min() ||
      !addSignedOffset(*BaseOffset, -*AnchorOffset, Adjustment))
    return std::nullopt;
  FrameOffsetBounds Result;
  if (Logical->Lower) {
    int64_t Bound = 0;
    if (addSignedOffset(*Logical->Lower, Adjustment, Bound))
      Result.Lower = Bound;
  }
  if (Logical->Upper) {
    int64_t Bound = 0;
    if (addSignedOffset(*Logical->Upper, Adjustment, Bound))
      Result.Upper = Bound;
  }
  if (!Result.Lower && !Result.Upper)
    return std::nullopt;
  return Result;
}

static bool boundedFrameIntervalsAreDisjoint(const FrameOffsetBounds &Left,
                                             uint64_t LeftSize,
                                             const FrameOffsetBounds &Right,
                                             uint64_t RightSize) {
  if (!LeftSize || !RightSize || LeftSize > uint64_t(INT64_MAX) ||
      RightSize > uint64_t(INT64_MAX))
    return false;
  int64_t End = 0;
  if (Left.Upper && Right.Lower &&
      addSignedOffset(*Left.Upper, int64_t(LeftSize), End) &&
      End <= *Right.Lower)
    return true;
  if (Right.Upper && Left.Lower &&
      addSignedOffset(*Right.Upper, int64_t(RightSize), End) &&
      End <= *Left.Lower)
    return true;
  return false;
}

static bool areDefinitelyDisjointAffineAccesses(LoadInst &Load,
                                                StoreInst &Store) {
  if (Load.isVolatile() || Load.isAtomic() || Store.isVolatile() ||
      Store.isAtomic())
    return false;
  const DataLayout &DL = Load.getModule()->getDataLayout();
  auto LoadAddress =
      evaluateNativeAffinePointer(Load.getPointerOperand(), DL, 0);
  auto StoreAddress =
      evaluateNativeAffinePointer(Store.getPointerOperand(), DL, 0);
  if (!LoadAddress || !StoreAddress)
    return false;
  if (!haveEqualNativeAffineRoots(*LoadAddress, *StoreAddress)) {
    Value *LoadObject = getUnderlyingObject(Load.getPointerOperand());
    Value *StoreObject = getUnderlyingObject(Store.getPointerOperand());
    return LoadObject != StoreObject &&
           isa<AllocaInst, GlobalVariable>(LoadObject) &&
           isa<AllocaInst, GlobalVariable>(StoreObject);
  }
  TypeSize LoadSize = DL.getTypeStoreSize(Load.getType());
  TypeSize StoreSize = DL.getTypeStoreSize(Store.getValueOperand()->getType());
  if (LoadSize.isScalable() || StoreSize.isScalable() ||
      !LoadSize.getFixedValue() || !StoreSize.getFixedValue() ||
      LoadSize.getFixedValue() > uint64_t(INT64_MAX) ||
      StoreSize.getFixedValue() > uint64_t(INT64_MAX))
    return false;
  return !affineIntervalsMayOverlap(*LoadAddress, LoadSize.getFixedValue(),
                                    *StoreAddress,
                                    StoreSize.getFixedValue());
}

static bool knownCallCannotClobberAffineFrameSlot(
    CallBase &CB, const NativeAffineAddress &Target, uint64_t TargetSize,
    Value *TargetObject, const DataLayout &DL) {
  if (!CB.mayWriteToMemory())
    return true;
  Function *Callee = CB.getCalledFunction();
  if (!Callee || (Callee->getName() != "scanf" &&
                  Callee->getName() != "__isoc99_scanf"))
    return false;

  // scanf can modify only its parsed, non-suppressed destination arguments
  // (plus libc-owned state).  A recovered frame slot may therefore be
  // forwarded across the call when every destination has a finite format-
  // derived size and is either a distinct object or affine-disjoint.
  for (unsigned ArgNo = 1; ArgNo < CB.arg_size(); ++ArgNo) {
    auto Size = getScanfDestinationSize(CB, ArgNo, DL);
    Value *Destination = CB.getArgOperand(ArgNo)->stripPointerCasts();
    auto Address = evaluateNativeAffinePointer(Destination, DL, 0);
    if (!Size || !*Size || !Address)
      return false;
    if (haveEqualNativeAffineRoots(Target, *Address)) {
      if (affineIntervalsMayOverlap(Target, TargetSize, *Address, *Size))
        return false;
      continue;
    }
    Value *DestinationObject = getUnderlyingObject(Destination);
    if (DestinationObject == TargetObject ||
        !isa<AllocaInst, GlobalVariable>(DestinationObject))
      return false;
  }
  return true;
}

} // namespace

// Forward an exact reaching definition through the recovered affine frame
// language.  LLVM's generic alias analysis often loses the relation between
// two GEPs after RSP was converted to integer SSA, so ordinary GVN leaves
// these spill/reload pairs intact.  This local proof is intentionally
// transactional per load: only the identical slot can define it and only
// complete, affine-disjoint store intervals may be crossed.
unsigned forwardProvenAffineStackSlotLoads(Module &M, bool &Changed) {
  // Reaching values can themselves be loads scheduled for forwarding later
  // in this batch. Raw Value pointers become dangling when an earlier pair
  // RAUWs and erases such a load, which can silently feed a reused,
  // differently typed Value into a later replacement. Tracking handles
  // follow the RAUW chain and keep the transaction type-correct.
  SmallVector<std::pair<WeakTrackingVH, WeakTrackingVH>, 64> Replacements;
  for (Function &F : M) {
    if (F.isDeclaration() || !findNativeStackAnchor(F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI || LI->isVolatile() || LI->isAtomic())
          continue;
        auto LoadAddress = evaluateNativeAffinePointer(
            LI->getPointerOperand(), M.getDataLayout(), 0);
        TypeSize LoadSize = M.getDataLayout().getTypeStoreSize(LI->getType());
        Value *LoadObject = getUnderlyingObject(LI->getPointerOperand());
        for (Instruction *Prev = LI->getPrevNode(); Prev;
             Prev = Prev->getPrevNode()) {
          if (auto *SI = dyn_cast<StoreInst>(Prev)) {
            if (SI->isVolatile() || SI->isAtomic())
              break;
            auto StoreAddress = evaluateNativeAffinePointer(
                SI->getPointerOperand(), M.getDataLayout(), 0);
            bool SameSlot =
                SI->getPointerOperand() == LI->getPointerOperand() ||
                (LoadAddress && StoreAddress &&
                 areSameExactNativeAffineAddress(*LoadAddress,
                                                 *StoreAddress));
            if (SameSlot) {
              if (SI->getValueOperand()->getType() == LI->getType())
                Replacements.push_back({LI, SI->getValueOperand()});
              break;
            }
            if (areDefinitelyDisjointAffineAccesses(*LI, *SI))
              continue;
            break;
          }
          if (auto *CB = dyn_cast<CallBase>(Prev)) {
            if (LoadAddress && !LoadSize.isScalable() &&
                LoadSize.getFixedValue() &&
                knownCallCannotClobberAffineFrameSlot(
                    *CB, *LoadAddress, LoadSize.getFixedValue(), LoadObject,
                    M.getDataLayout()))
              continue;
            break;
          }
          // Volatile/atomic loads are observable operations but they do not
          // clobber another stack slot.  mayWriteToMemory() is intentionally
          // conservative for side-effecting instructions, so classify loads
          // explicitly before consulting it.
          if (isa<LoadInst>(Prev))
            continue;
          if (Prev->mayWriteToMemory())
            break;
        }
      }
    }
  }

  unsigned Forwarded = 0;
  for (auto &Replacement : Replacements) {
    auto *LI = dyn_cast_or_null<LoadInst>(Replacement.first);
    Value *Value = Replacement.second;
    if (!LI || !LI->getParent() || !Value ||
        LI->getType() != Value->getType())
      continue;
    Instruction *PointerExpression =
        dyn_cast<Instruction>(LI->getPointerOperand());
    LI->replaceAllUsesWith(Value);
    LI->eraseFromParent();
    if (PointerExpression && PointerExpression->getParent())
      RecursivelyDeleteTriviallyDeadInstructions(PointerExpression);
    ++Forwarded;
    Changed = true;
  }
  // Passthrough extraction often turns a loop-carried State field into
  //   %state = phi [ %entry.value, %entry ], [ %state, %backedge ]
  // which is exactly the entry value on every defined execution.  Collapse
  // these self-only recurrences to expose constant frame offsets before the
  // dynamic-region and frame-compaction proofs run.
  auto GetSelfRecurrenceBase = [](PHINode &PN) -> Value * {
    Value *Common = nullptr;
    for (Value *Incoming : PN.incoming_values()) {
      if (Incoming == &PN)
        continue;
      if (!Common)
        Common = Incoming;
      else if (Incoming != Common)
        return nullptr;
    }
    return Common && Common->getType() == PN.getType() ? Common : nullptr;
  };
  for (;;) {
    PHINode *Selected = nullptr;
    Value *SelectedBase = nullptr;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F) {
        for (PHINode &PN : BB.phis()) {
          Value *Common = GetSelfRecurrenceBase(PN);
          if (!Common)
            continue;
          // Do not choose an arbitrary representative for a rootless PHI
          // cycle.  Follow only other self-recurrence PHIs; reaching PN (or
          // another cycle) means there is no independently defined base.
          SmallPtrSet<Value *, 16> Chain;
          Chain.insert(&PN);
          Value *Cursor = Common;
          bool Rooted = true;
          while (auto *Other = dyn_cast<PHINode>(Cursor)) {
            if (!Chain.insert(Other).second) {
              Rooted = false;
              break;
            }
            Value *Next = GetSelfRecurrenceBase(*Other);
            if (!Next)
              break;
            Cursor = Next;
          }
          if (!Rooted)
            continue;
          Selected = &PN;
          SelectedBase = Common;
          break;
        }
        if (Selected)
          break;
      }
      if (Selected)
        break;
    }
    if (!Selected)
      break;
    // Mutate one PHI at a time and rescan.  This keeps SelectedBase live even
    // when several collapsible PHIs form a dependency chain.
    Selected->replaceAllUsesWith(SelectedBase);
    Selected->eraseFromParent();
    ++Forwarded;
    Changed = true;
  }
  return Forwarded;
}

unsigned forwardRecoveredAggregatePassthroughs(Module &M, bool &Changed) {
  SmallVector<std::pair<WeakTrackingVH, WeakTrackingVH>, 32> Replacements;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *EV = dyn_cast<ExtractValueInst>(&I);
        if (!EV || EV->getNumIndices() != 1)
          continue;
        SmallVector<Value *, 8> Resolved;
        SmallPtrSet<Value *, 16> Seen;
        if (!collectDirectAggregateFieldValues(
                EV->getAggregateOperand(), *EV->idx_begin(), Resolved, Seen) ||
            Resolved.empty())
          continue;
        Value *Common = Resolved.front();
        if (!Common || Common->getType() != EV->getType() ||
            !llvm::all_of(Resolved,
                          [&](Value *V) { return V == Common; }))
          continue;
        Replacements.push_back({EV, Common});
      }
    }
  }
  // Resolve replacement chains before mutating the IR.  Mutually recursive
  // aggregate plumbing can otherwise produce A -> B and B -> A candidates;
  // applying either edge would erase a value still used as the other's
  // replacement.  A cycle is not a direct passthrough proof, so fail closed.
  DenseMap<Value *, Value *> CandidateTargets;
  for (auto &Replacement : Replacements) {
    Value *Source = Replacement.first;
    Value *Target = Replacement.second;
    if (Source && Target)
      CandidateTargets[Source] = Target;
  }
  for (auto &Replacement : Replacements) {
    Value *Source = Replacement.first;
    Value *Target = Replacement.second;
    SmallPtrSet<Value *, 16> Chain;
    while (Target && CandidateTargets.contains(Target)) {
      if (Target == Source || !Chain.insert(Target).second) {
        Target = nullptr;
        break;
      }
      Target = CandidateTargets.lookup(Target);
    }
    Replacement.second = Target;
  }
  unsigned Forwarded = 0;
  for (auto &Replacement : Replacements) {
    auto *EV = dyn_cast_or_null<ExtractValueInst>(Replacement.first);
    Value *Value = Replacement.second;
    if (!EV || !EV->getParent() || !Value ||
        Value->getType() != EV->getType())
      continue;
    EV->replaceAllUsesWith(Value);
    EV->eraseFromParent();
    ++Forwarded;
    Changed = true;
  }
  return Forwarded;
}

unsigned simplifyRecoveredSignedCompareIdioms(Module &M, bool &Changed) {
  SmallVector<std::pair<Instruction *, Value *>, 32> Replacements;
  auto MatchSignOfXor = [](Value *V, Value *Left,
                           Value *Right) -> bool {
    auto *Shift = dyn_cast<BinaryOperator>(V);
    auto *Amount =
        Shift ? dyn_cast<ConstantInt>(Shift->getOperand(1)) : nullptr;
    auto *Xor = Shift ? dyn_cast<BinaryOperator>(Shift->getOperand(0))
                      : nullptr;
    if (!Shift || Shift->getOpcode() != Instruction::LShr || !Amount ||
        !Xor || Xor->getOpcode() != Instruction::Xor ||
        !Xor->getType()->isIntegerTy() ||
        Amount->getZExtValue() + 1 !=
            Xor->getType()->getIntegerBitWidth())
      return false;
    return (Xor->getOperand(0) == Left && Xor->getOperand(1) == Right) ||
           (Xor->getOperand(0) == Right && Xor->getOperand(1) == Left);
  };

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *XorResult = dyn_cast<BinaryOperator>(&I);
        if (!XorResult || XorResult->getOpcode() != Instruction::Xor ||
            !XorResult->getType()->isIntegerTy(1))
          continue;
        ICmpInst *Negative = nullptr;
        ICmpInst *Overflow = nullptr;
        for (Value *Operand : XorResult->operands()) {
          auto *Cmp = dyn_cast<ICmpInst>(Operand);
          if (!Cmp)
            continue;
          if (Cmp->getPredicate() == ICmpInst::ICMP_SLT &&
              match(Cmp->getOperand(1), m_Zero()))
            Negative = Cmp;
          else if (Cmp->getPredicate() == ICmpInst::ICMP_EQ &&
                   (match(Cmp->getOperand(0), m_SpecificInt(2)) ||
                    match(Cmp->getOperand(1), m_SpecificInt(2))))
            Overflow = Cmp;
        }
        if (!Negative || !Overflow)
          continue;
        auto *Difference =
            dyn_cast<BinaryOperator>(Negative->getOperand(0));
        if (!Difference || Difference->getOpcode() != Instruction::Sub)
          continue;
        Value *Left = Difference->getOperand(0);
        Value *Right = Difference->getOperand(1);
        Value *SumValue = match(Overflow->getOperand(0), m_SpecificInt(2))
                              ? Overflow->getOperand(1)
                              : Overflow->getOperand(0);
        auto *Sum = dyn_cast<BinaryOperator>(SumValue);
        if (!Sum || Sum->getOpcode() != Instruction::Add)
          continue;
        bool MatchesOverflow =
            (MatchSignOfXor(Sum->getOperand(0), Left, Right) &&
             MatchSignOfXor(Sum->getOperand(1), Difference, Left)) ||
            (MatchSignOfXor(Sum->getOperand(1), Left, Right) &&
             MatchSignOfXor(Sum->getOperand(0), Difference, Left));
        if (!MatchesOverflow)
          continue;
        IRBuilder<> B(XorResult);
        Replacements.push_back(
            {XorResult, B.CreateICmpSLT(Left, Right, "native.slt")});
      }
    }
  }

  unsigned Simplified = 0;
  for (auto [Old, New] : Replacements) {
    if (!Old->getParent())
      continue;
    Old->replaceAllUsesWith(New);
    RecursivelyDeleteTriviallyDeadInstructions(Old);
    ++Simplified;
    Changed = true;
  }

  Replacements.clear();
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Or = dyn_cast<BinaryOperator>(&I);
        if (!Or || Or->getOpcode() != Instruction::Or ||
            !Or->getType()->isIntegerTy(1))
          continue;
        auto *First = dyn_cast<ICmpInst>(Or->getOperand(0));
        auto *Second = dyn_cast<ICmpInst>(Or->getOperand(1));
        if (!First || !Second)
          continue;
        ICmpInst *Equal = First->getPredicate() == ICmpInst::ICMP_EQ
                              ? First
                              : Second->getPredicate() == ICmpInst::ICMP_EQ
                                    ? Second
                                    : nullptr;
        ICmpInst *Less = First->getPredicate() == ICmpInst::ICMP_SLT
                             ? First
                             : Second->getPredicate() == ICmpInst::ICMP_SLT
                                   ? Second
                                   : nullptr;
        if (!Equal || !Less)
          continue;
        Value *Left = Less->getOperand(0);
        Value *Right = Less->getOperand(1);
        bool SameOperands =
            (Equal->getOperand(0) == Left && Equal->getOperand(1) == Right) ||
            (Equal->getOperand(0) == Right && Equal->getOperand(1) == Left);
        if (!SameOperands)
          continue;
        IRBuilder<> B(Or);
        Replacements.push_back(
            {Or, B.CreateICmpSLE(Left, Right, "native.sle")});
      }
    }
  }
  for (auto [Old, New] : Replacements) {
    if (!Old->getParent())
      continue;
    Old->replaceAllUsesWith(New);
    RecursivelyDeleteTriviallyDeadInstructions(Old);
    ++Simplified;
    Changed = true;
  }
  return Simplified;
}

bool isProvenWriteOnlyAffineFrameSlot(Function &F, Value *Pointer) {
  if (!Pointer || !Pointer->getType()->isPointerTy())
    return false;
  const DataLayout &DL = F.getParent()->getDataLayout();
  auto Target = evaluateNativeAffinePointer(Pointer, DL, 0);
  Value *TargetObject = getUnderlyingObject(Pointer);
  auto TargetBounds = TargetObject
                          ? evaluateBoundedFramePointer(Pointer,
                                                        *TargetObject, DL)
                          : std::nullopt;
  if ((!Target || Target->MinConstant != Target->MaxConstant) &&
      !TargetBounds)
    return false;
  uint64_t TargetSize = 0;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        if (SI->isVolatile() || SI->isAtomic())
          continue;
        auto Store = evaluateNativeAffinePointer(SI->getPointerOperand(), DL,
                                                 0);
        bool SameTarget = SI->getPointerOperand() == Pointer;
        if (!SameTarget && Target && Store)
          SameTarget = areSameExactNativeAffineAddress(*Target, *Store);
        if (!SameTarget)
          continue;
        TypeSize TS = DL.getTypeStoreSize(SI->getValueOperand()->getType());
        if (TS.isScalable() || !TS.getFixedValue())
          return false;
        TargetSize = std::max(TargetSize, TS.getFixedValue());
      }
  if (!TargetSize)
    return false;

  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      Value *ReadPointer = nullptr;
      Type *ReadType = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        ReadPointer = LI->getPointerOperand();
        ReadType = LI->getType();
      } else if (auto *RMW = dyn_cast<AtomicRMWInst>(&I)) {
        ReadPointer = RMW->getPointerOperand();
        ReadType = RMW->getValOperand()->getType();
      } else if (auto *CX = dyn_cast<AtomicCmpXchgInst>(&I)) {
        ReadPointer = CX->getPointerOperand();
        ReadType = CX->getCompareOperand()->getType();
      }
      if (ReadPointer && ReadType) {
        TypeSize TS = DL.getTypeStoreSize(ReadType);
        if (TS.isScalable() || !TS.getFixedValue())
          return false;
        auto Read = evaluateNativeAffinePointer(ReadPointer, DL, 0);
        bool MayOverlap = false;
        if (Target && Read && haveEqualNativeAffineRoots(*Target, *Read)) {
            MayOverlap = affineIntervalsMayOverlap(
                *Target, TargetSize, *Read, TS.getFixedValue());
        } else if (getUnderlyingObject(ReadPointer) == TargetObject) {
          auto ReadBounds = TargetObject
                                ? evaluateBoundedFramePointer(
                                      ReadPointer, *TargetObject, DL)
                                : std::nullopt;
          MayOverlap = !TargetBounds || !ReadBounds ||
                       !boundedFrameIntervalsAreDisjoint(
                           *TargetBounds, TargetSize, *ReadBounds,
                           TS.getFixedValue());
        }
        if (MayOverlap)
          return false;
      }

      if (auto *MT = dyn_cast<MemTransferInst>(&I)) {
        auto *Length = dyn_cast<ConstantInt>(MT->getLength());
        if (!Length || Length->getValue().getActiveBits() > 63)
          return false;
        auto Read = evaluateNativeAffinePointer(MT->getRawSource(), DL, 0);
        bool MayOverlap = false;
        if (Target && Read && haveEqualNativeAffineRoots(*Target, *Read)) {
            MayOverlap = affineIntervalsMayOverlap(
                *Target, TargetSize, *Read, Length->getZExtValue());
        } else if (getUnderlyingObject(MT->getRawSource()) == TargetObject) {
          auto ReadBounds = TargetObject
                                ? evaluateBoundedFramePointer(
                                      MT->getRawSource(), *TargetObject, DL)
                                : std::nullopt;
          MayOverlap = !TargetBounds || !ReadBounds ||
                       !boundedFrameIntervalsAreDisjoint(
                           *TargetBounds, TargetSize, *ReadBounds,
                           Length->getZExtValue());
        }
        if (MayOverlap)
          return false;
      }
    }
  }
  return true;
}

// A final inttoptr rewrite needs must-provenance, not the may-provenance used
// by discovery.  In particular, a PHI/select with one RSP arm and one
// heap/global arm is not a stack address on every execution.  Rebasing that
// complete value on frame_top corrupts the non-stack arm.  Keep this proof
// deliberately narrow: affine stack arithmetic and casts are admitted;
// merges are admitted only when every incoming value is independently proven.
static bool isDefiniteNativeStackInteger(Value *V) {
  auto PointsAtFrameStorage = [&](Value *P, auto &&Self) -> bool {
    if (!P)
      return false;
    P = P->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(P))
      return GV->getName().starts_with("frame_storage_backing.");
    if (auto *AI = dyn_cast<AllocaInst>(P)) {
      auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
      StringRef Name = AI->getName();
      return AT && AT->getElementType()->isIntegerTy(8) &&
             (Name.starts_with("frame_storage") ||
              Name.starts_with("native_stack_storage"));
    }
    if (auto *GEP = dyn_cast<GEPOperator>(P))
      return Self(GEP->getPointerOperand(), Self);
    return false;
  };

  struct StackProofState {
    bool Valid = false;
    bool HasConcreteRoot = false;
  };
  // This proof is invoked independently for each raw inttoptr candidate.
  // Bound total work as well as recursion depth so a highly branching lifted
  // CFG cannot turn a fail-closed query into exponential compile time.
  constexpr unsigned MaxStackProofSteps = 16384;
  unsigned StackProofSteps = 0;
  DenseMap<Value *, StackProofState> Memo;
  SmallPtrSet<Value *, 32> Active;
  SmallVector<std::pair<Function *, unsigned>, 16> ActiveCallFields;
  std::function<StackProofState(Value *, unsigned)> Prove;
  using StackOperandProver =
      std::function<StackProofState(Value *, unsigned)>;
  std::function<StackProofState(Value *, ArrayRef<unsigned>, unsigned,
                                const StackOperandProver &)>
      ProveAggregateElement;

  // State-SSA result tuples are sparse and their field order depends on the
  // recovered live-out set.  Establish the provenance of an extracted field
  // from the callee's actual return construction instead of assuming a fixed
  // RSP/RBP tuple index.  Callee state arguments are substituted with the
  // corresponding call operands, so an ABI-shaped call carrying a non-stack
  // value in its RSP input still fails closed.
  ProveAggregateElement =
      [&](Value *Aggregate, ArrayRef<unsigned> Indices,
          unsigned Depth,
          const StackOperandProver &ProveOperand) -> StackProofState {
    if (!Aggregate || Indices.empty() || Depth > 128 ||
        ++StackProofSteps > MaxStackProofSteps)
      return {};
    if (auto *PN = dyn_cast<PHINode>(Aggregate)) {
      StackProofState Result{true, false};
      for (Value *Incoming : PN->incoming_values()) {
        StackProofState Arm =
            ProveAggregateElement(Incoming, Indices, Depth + 1,
                                  ProveOperand);
        if (!Arm.Valid)
          return {};
        Result.HasConcreteRoot |= Arm.HasConcreteRoot;
      }
      return Result;
    }
    if (auto *SI = dyn_cast<SelectInst>(Aggregate)) {
      StackProofState True =
          ProveAggregateElement(SI->getTrueValue(), Indices, Depth + 1,
                                ProveOperand);
      StackProofState False =
          ProveAggregateElement(SI->getFalseValue(), Indices, Depth + 1,
                                ProveOperand);
      bool Valid = True.Valid && False.Valid;
      return {Valid, Valid && (True.HasConcreteRoot ||
                              False.HasConcreteRoot)};
    }

    auto *CB = dyn_cast<CallBase>(Aggregate);
    Function *Callee = CB ? CB->getCalledFunction() : nullptr;
    if (!CB || !Callee || Callee->isDeclaration() || Indices.size() != 1)
      return {};
    std::pair<Function *, unsigned> CallField{Callee, Indices.front()};
    if (llvm::is_contained(ActiveCallFields, CallField))
      return {true, false};
    ActiveCallFields.push_back(CallField);
    auto FinishCall = [&](StackProofState Result) {
      ActiveCallFields.pop_back();
      return Result;
    };

    DenseMap<Value *, StackProofState> LocalMemo;
    SmallPtrSet<Value *, 32> LocalActive;
    std::function<StackProofState(Value *, unsigned)> ProveReturned =
        [&](Value *Returned, unsigned LocalDepth) -> StackProofState {
      if (!Returned || LocalDepth > 128 ||
          !Returned->getType()->isIntegerTy() ||
          ++StackProofSteps > MaxStackProofSteps)
        return {};
      if (auto It = LocalMemo.find(Returned); It != LocalMemo.end())
        return It->second;
      if (!LocalActive.insert(Returned).second)
        return {true, false};
      auto FinishLocal = [&](StackProofState Result) {
        LocalActive.erase(Returned);
        LocalMemo[Returned] = Result;
        return Result;
      };

      if (auto *Arg = dyn_cast<Argument>(Returned)) {
        StringRef ArgName = Arg->getName();
        bool IsStackState = ArgName == "state_in_2312" ||
                            ArgName == "state_in_2328";
        if (!IsStackState || Arg->getArgNo() >= CB->arg_size())
          return FinishLocal({});
        return FinishLocal(
            ProveOperand(CB->getArgOperand(Arg->getArgNo()),
                         Depth + LocalDepth + 1));
      }
      if (auto *PN = dyn_cast<PHINode>(Returned)) {
        if (!PN->getNumIncomingValues())
          return FinishLocal({});
        StackProofState Result{true, false};
        for (Value *Incoming : PN->incoming_values()) {
          StackProofState Arm = ProveReturned(Incoming, LocalDepth + 1);
          if (!Arm.Valid)
            return FinishLocal({});
          Result.HasConcreteRoot |= Arm.HasConcreteRoot;
        }
        return FinishLocal(Result);
      }
      if (auto *Select = dyn_cast<SelectInst>(Returned)) {
        StackProofState True =
            ProveReturned(Select->getTrueValue(), LocalDepth + 1);
        StackProofState False =
            ProveReturned(Select->getFalseValue(), LocalDepth + 1);
        bool Valid = True.Valid && False.Valid;
        return FinishLocal({Valid, Valid && (True.HasConcreteRoot ||
                                             False.HasConcreteRoot)});
      }
      if (auto *Cast = dyn_cast<CastInst>(Returned)) {
        if (!Cast->getOperand(0)->getType()->isIntegerTy())
          return FinishLocal({});
        return FinishLocal(
            ProveReturned(Cast->getOperand(0), LocalDepth + 1));
      }
      if (auto *EV = dyn_cast<ExtractValueInst>(Returned))
        return FinishLocal(ProveAggregateElement(
            EV->getAggregateOperand(), EV->getIndices(),
            Depth + LocalDepth + 1, ProveReturned));
      if (auto *Op = dyn_cast<Operator>(Returned)) {
        if (Op->getOpcode() != Instruction::Add &&
            Op->getOpcode() != Instruction::Sub)
          return FinishLocal({});
        StackProofState Left =
            ProveReturned(Op->getOperand(0), LocalDepth + 1);
        StackProofState Right =
            ProveReturned(Op->getOperand(1), LocalDepth + 1);
        bool Valid = Op->getOpcode() == Instruction::Sub
                         ? Left.Valid && !Right.Valid
                         : Left.Valid != Right.Valid;
        return FinishLocal(
            {Valid, Valid && (Left.HasConcreteRoot ||
                              Right.HasConcreteRoot)});
      }
      return FinishLocal({});
    };

    bool SawReturn = false;
    StackProofState Result{true, false};
    for (BasicBlock &BB : *Callee) {
      auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
      if (!RI || !RI->getReturnValue())
        continue;
      Value *Field = FindInsertedValue(RI->getReturnValue(), Indices);
      if (!Field || !Field->getType()->isIntegerTy())
        return FinishCall({});
      SawReturn = true;
      StackProofState Arm = ProveReturned(Field, 0);
      if (!Arm.Valid)
        return FinishCall({});
      Result.HasConcreteRoot |= Arm.HasConcreteRoot;
    }
    return FinishCall(SawReturn ? Result : StackProofState{});
  };

  Prove =
      [&](Value *Current, unsigned Depth) -> StackProofState {
    if (!Current || Depth > 128 || !Current->getType()->isIntegerTy() ||
        ++StackProofSteps > MaxStackProofSteps)
      return {};
    if (auto It = Memo.find(Current); It != Memo.end())
      return It->second;
    // A revisit is a provisional affine recurrence, not a root.  The SCC is
    // accepted only if another incoming path eventually contributes a real
    // frame/RSP seed; a rootless self-cycle therefore remains invalid.
    if (!Active.insert(Current).second)
      return {true, false};
    auto Finish = [&](StackProofState Result) {
      Active.erase(Current);
      Memo[Current] = Result;
      return Result;
    };

    if (auto *PTI = dyn_cast<PtrToIntOperator>(Current)) {
      bool IsFrame = PointsAtFrameStorage(PTI->getPointerOperand(),
                                          PointsAtFrameStorage);
      return Finish({IsFrame, IsFrame});
    }
    StringRef Name = Current->getName();
    if (isa<Argument>(Current)) {
      bool IsRoot = Name == "state_in_2312" || Name == "state_in_2328" ||
                    Name == "new_rsp" || Name == "new_rbp";
      return Finish({IsRoot, IsRoot});
    }
    if (auto *LI = dyn_cast<LoadInst>(Current)) {
      if (LI->isVolatile() || LI->isAtomic())
        return Finish({});
      const DataLayout &DL = LI->getModule()->getDataLayout();
      auto LoadAddress =
          evaluateNativeAffinePointer(LI->getPointerOperand(), DL, 0);
      TypeSize LoadSize = DL.getTypeStoreSize(LI->getType());
      if (!LoadAddress || LoadAddress->MinConstant != LoadAddress->MaxConstant ||
          LoadSize.isScalable() || !LoadSize.getFixedValue())
        return Finish({});

      // Follow the first may-aliasing definition backwards through the CFG.
      // A loop backedge is provisional, exactly like a loop-carried SSA PHI:
      // every acyclic entry path must still reach a concrete, stack-proven
      // store.  Unknown writes, partial stores and rootless memory cycles are
      // rejected.  This proves spill/reload provenance without manufacturing
      // a value PHI or assuming that a load from the guest stack contains RSP.
      DenseMap<BasicBlock *, StackProofState> EndMemo;
      SmallPtrSet<BasicBlock *, 32> ActiveBlocks;
      auto ConstantPrintfHasNoWriteConversion =
          [&](CallBase &CB) -> bool {
        if (!CB.arg_size())
          return false;
        StringRef Format;
        if (!getConstantStringInfo(CB.getArgOperand(0), Format))
          return false;
        for (size_t I = 0; I < Format.size();) {
          if (Format[I++] != '%')
            continue;
          if (I >= Format.size())
            return false;
          if (Format[I] == '%') {
            ++I;
            continue;
          }
          // Skip flags, dynamic/constant width, precision and length.  The
          // first recognized conversion terminates this directive.  Unknown
          // or incomplete syntax is not used as a memory proof.
          while (I < Format.size() && StringRef("-+ #0'").contains(Format[I]))
            ++I;
          if (I < Format.size() && Format[I] == '*')
            ++I;
          else
            while (I < Format.size() && Format[I] >= '0' &&
                   Format[I] <= '9')
              ++I;
          if (I < Format.size() && Format[I] == '.') {
            ++I;
            if (I < Format.size() && Format[I] == '*')
              ++I;
            else
              while (I < Format.size() && Format[I] >= '0' &&
                     Format[I] <= '9')
                ++I;
          }
          if (I < Format.size() && StringRef("hljztL").contains(Format[I])) {
            char Length = Format[I++];
            if (I < Format.size() &&
                ((Length == 'h' && Format[I] == 'h') ||
                 (Length == 'l' && Format[I] == 'l')))
              ++I;
          }
          if (I >= Format.size())
            return false;
          char Conversion = Format[I++];
          if (!StringRef("diouxXaAeEfFgGcspn").contains(Conversion) ||
              Conversion == 'n')
            return false;
        }
        return true;
      };
      auto CallCannotClobber = [&](CallBase &CB) -> bool {
        if (!CB.mayWriteToMemory())
          return true;
        Function *Callee = CB.getCalledFunction();
        auto *FrameObject = dyn_cast<AllocaInst>(
            getUnderlyingObject(LI->getPointerOperand()));
        if (!Callee || !FrameObject)
          return false;
        StringRef CalleeName = Callee->getName();
        if (CalleeName == "puts")
          return true;
        if (CalleeName == "printf")
          return ConstantPrintfHasNoWriteConversion(CB);
        if (CalleeName != "scanf" && CalleeName != "__isoc99_scanf")
          return false;

        // scanf writes only its non-suppressed destination arguments.  The
        // existing format parser gives each one an exact byte bound; require
        // every actual destination to have such a bound and to be affine-
        // disjoint from the load.  Unbounded %s/%[ and dynamic formats fail.
        for (unsigned ArgNo = 1; ArgNo < CB.arg_size(); ++ArgNo) {
          auto Size = getScanfDestinationSize(CB, ArgNo, DL);
          Value *Destination = CB.getArgOperand(ArgNo)->stripPointerCasts();
          auto DestinationAddress =
              evaluateNativeAffinePointer(Destination, DL, 0);
          if (!Size || !*Size || !DestinationAddress)
            return false;
          if (!haveEqualNativeAffineRoots(*LoadAddress,
                                          *DestinationAddress)) {
            Value *DestinationObject = getUnderlyingObject(Destination);
            if (DestinationObject == FrameObject ||
                !isa<AllocaInst, GlobalVariable>(DestinationObject))
              return false;
            continue;
          }
          if (affineIntervalsMayOverlap(*LoadAddress,
                                        LoadSize.getFixedValue(),
                                        *DestinationAddress, *Size))
            return false;
        }
        return true;
      };
      std::function<StackProofState(BasicBlock *, Instruction *, unsigned)>
          ProveReachingStores;
      ProveReachingStores =
          [&](BasicBlock *BB, Instruction *Before,
              unsigned MemoryDepth) -> StackProofState {
        if (!BB || MemoryDepth > 256 ||
            ++StackProofSteps > MaxStackProofSteps)
          return {};
        bool AtBlockEnd = Before == nullptr;
        if (AtBlockEnd)
          if (auto It = EndMemo.find(BB); It != EndMemo.end())
            return It->second;
        if (!ActiveBlocks.insert(BB).second)
          return {true, false};
        auto FinishMemory = [&](StackProofState Result) {
          ActiveBlocks.erase(BB);
          if (AtBlockEnd)
            EndMemo[BB] = Result;
          return Result;
        };

        Instruction *Cursor = Before ? Before->getPrevNode()
                                     : BB->getTerminator();
        for (; Cursor; Cursor = Cursor->getPrevNode()) {
          if (++StackProofSteps > MaxStackProofSteps)
            return FinishMemory({});
          if (auto *SI = dyn_cast<StoreInst>(Cursor)) {
            if (SI->isVolatile() || SI->isAtomic())
              return FinishMemory({});
            auto StoreAddress = evaluateNativeAffinePointer(
                SI->getPointerOperand(), DL, 0);
            bool SameSlot =
                SI->getPointerOperand() == LI->getPointerOperand() ||
                (StoreAddress &&
                 areSameExactNativeAffineAddress(*LoadAddress,
                                                 *StoreAddress));
            if (SameSlot) {
              TypeSize StoreSize =
                  DL.getTypeStoreSize(SI->getValueOperand()->getType());
              if (StoreSize.isScalable() ||
                  StoreSize.getFixedValue() != LoadSize.getFixedValue() ||
                  SI->getValueOperand()->getType() != LI->getType())
                return FinishMemory({});
              return FinishMemory(
                  Prove(SI->getValueOperand(), Depth + MemoryDepth + 1));
            }
            if (areDefinitelyDisjointAffineAccesses(*LI, *SI))
              continue;
            return FinishMemory({});
          }
          if (auto *CB = dyn_cast<CallBase>(Cursor)) {
            if (CallCannotClobber(*CB))
              continue;
            return FinishMemory({});
          }
          if (Cursor->mayWriteToMemory())
            return FinishMemory({});
        }

        if (pred_empty(BB))
          return FinishMemory({});
        StackProofState Result{true, false};
        for (BasicBlock *Pred : predecessors(BB)) {
          StackProofState Arm =
              ProveReachingStores(Pred, nullptr, MemoryDepth + 1);
          if (!Arm.Valid)
            return FinishMemory({});
          Result.HasConcreteRoot |= Arm.HasConcreteRoot;
        }
        return FinishMemory(Result);
      };
      return Finish(ProveReachingStores(LI->getParent(), LI, 0));
    }
    if (auto *EV = dyn_cast<ExtractValueInst>(Current))
      return Finish(ProveAggregateElement(EV->getAggregateOperand(),
                                          EV->getIndices(), Depth + 1,
                                          Prove));
    if (auto *PN = dyn_cast<PHINode>(Current)) {
      if (!PN->getNumIncomingValues())
        return Finish({});
      StackProofState Result{true, false};
      for (Value *Incoming : PN->incoming_values()) {
        StackProofState Arm = Prove(Incoming, Depth + 1);
        if (!Arm.Valid)
          return Finish({});
        Result.HasConcreteRoot |= Arm.HasConcreteRoot;
      }
      return Finish(Result);
    }
    if (auto *SI = dyn_cast<SelectInst>(Current)) {
      StackProofState True = Prove(SI->getTrueValue(), Depth + 1);
      StackProofState False = Prove(SI->getFalseValue(), Depth + 1);
      bool Valid = True.Valid && False.Valid;
      return Finish({Valid, Valid && (True.HasConcreteRoot ||
                                     False.HasConcreteRoot)});
    }
    if (auto *Cast = dyn_cast<CastInst>(Current)) {
      if (!Cast->getOperand(0)->getType()->isIntegerTy())
        return Finish({});
      return Finish(Prove(Cast->getOperand(0), Depth + 1));
    }
    if (auto *Op = dyn_cast<Operator>(Current)) {
      if (Op->getOpcode() != Instruction::Add &&
          Op->getOpcode() != Instruction::Sub)
        return Finish({});
      StackProofState Left = Prove(Op->getOperand(0), Depth + 1);
      StackProofState Right = Prove(Op->getOperand(1), Depth + 1);
      bool Valid = Op->getOpcode() == Instruction::Sub
                       ? Left.Valid && !Right.Valid
                       : Left.Valid != Right.Valid;
      bool HasRoot = Valid && (Left.HasConcreteRoot ||
                               Right.HasConcreteRoot);
      return Finish({Valid, HasRoot});
    }
    return Finish({});
  };

  StackProofState Result = Prove(V, 0);
  return Result.Valid && Result.HasConcreteRoot;
}

// O3 can leave an internal RSP/RBP value as a direct inttoptr after the
// translator and external-call rewrites have already run. Lower only values
// with definite stack provenance; arbitrary or mixed dynamic inttoptr values
// still represent native heap/data/callback pointers and remain untouched.
bool hasRawNativeStackIntToPtrCandidate(Module &M) {
  for (Function &F : M) {
    if (F.isDeclaration() || !findNativeStackAnchor(F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        if (isDefiniteNativeStackInteger(ITP->getOperand(0)))
          return true;
      }
    }
  }
  return false;
}

unsigned lowerRawNativeStackIntToPtrs(Module &M, bool &Changed) {
  // Materializing one recovered stack pointer can fold or recursively delete
  // another candidate.  Tracking handles prevent a later batch entry from
  // dereferencing an instruction that no longer exists.
  SmallVector<WeakTrackingVH, 32> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration() || !findNativeStackAnchor(F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        if (isDefiniteNativeStackInteger(ITP->getOperand(0)))
          Candidates.push_back(ITP);
      }
    }
  }

  unsigned Lowered = 0;
  for (WeakTrackingVH &Candidate : Candidates) {
    auto *ITP = dyn_cast_or_null<IntToPtrInst>(Candidate);
    if (!ITP)
      continue;
    if (!ITP->getParent())
      continue;
    IRBuilder<> B(ITP);
    // Candidate collection already established must-stack provenance with
    // isDefiniteNativeStackInteger.  Preserve that proof when materializing
    // the pointer: the older may-provenance walker deliberately cannot see an
    // exact stack value that was spilled and reloaded from a private slot.
    Value *NativePtr = lowerNativeStackIntegerImpl(
        B, ITP->getOperand(0), *ITP->getFunction(), true);
    if (!NativePtr)
      continue;
    if (NativePtr->getType() != ITP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                      "native.stack.pointer");
    ITP->replaceAllUsesWith(NativePtr);
    ITP->eraseFromParent();
    ++Lowered;
    Changed = true;
  }
  return Lowered;
}

// The first translator cleanup runs before State-SSA introduces the explicit
// native_stack argument.  Repair the remaining translated GEPs afterwards,
// using the guest range metadata to reconstruct the original integer address.
unsigned rewriteNativeDataStackGEPs(Module &M, bool &Changed) {
  SmallVector<GetElementPtrInst *, 64> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *GEP = dyn_cast<GetElementPtrInst>(&I);
        if (!GEP || GEP->getNumIndices() != 1)
          continue;
        auto *GV = dyn_cast<GlobalVariable>(
            GEP->getPointerOperand()->stripPointerCasts());
        if (!GV || !GV->getName().starts_with("native_data_"))
          continue;
        if (!isa<IntegerType>(GEP->getSourceElementType()) ||
            !GEP->getSourceElementType()->isIntegerTy(8))
          continue;
        if (isa<ConstantInt>(GEP->getOperand(1)))
          continue;
        Candidates.push_back(GEP);
      }
    }
  }

  unsigned Rewritten = 0;
  for (GetElementPtrInst *GEP : Candidates) {
    auto *GV = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!GV || !GEP->getParent())
      continue;
    MDNode *Range = GV->getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    if (!Begin)
      continue;

    IRBuilder<> B(GEP);
    Value *GuestAddress = GEP->getOperand(1);
    if (Begin->getZExtValue() != 0)
      GuestAddress = B.CreateAdd(
          GuestAddress, B.getInt64(Begin->getZExtValue()),
          "native.translated.guest.address");
    Value *NativePtr = lowerNativeStackInteger(
        B, GuestAddress, *GEP->getFunction());
    if (!NativePtr)
      continue;
    GEP->replaceAllUsesWith(NativePtr);
    GEP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

} // namespace brighten_native_cleanup
