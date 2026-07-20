#include "NativeCleanupInternal.h"

using namespace llvm;

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

Value *lowerNativeStackInteger(IRBuilder<> &B, Value *Integer,
                                      Function &F) {
  Value *NativeStack = findNativeStackAnchor(F);
  if (!NativeStack || !Integer || !Integer->getType()->isIntegerTy())
    return nullptr;
  SmallPtrSet<Value *, 32> Seen;
  bool HasStackProvenance = containsNativeStackInteger(Integer, Seen);
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

// O3 can leave an internal RSP/RBP value as a direct inttoptr after the
// translator and external-call rewrites have already run.  Lower only values
// with explicit stack provenance; arbitrary dynamic inttoptr values still
// represent native heap/data/callback pointers and must remain untouched.
bool hasRawNativeStackIntToPtrCandidate(Module &M) {
  for (Function &F : M) {
    if (F.isDeclaration() || !findNativeStackAnchor(F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        SmallPtrSet<Value *, 32> Seen;
        if (containsNativeStackInteger(ITP->getOperand(0), Seen))
          return true;
      }
    }
  }
  return false;
}

unsigned lowerRawNativeStackIntToPtrs(Module &M, bool &Changed) {
  SmallVector<IntToPtrInst *, 32> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration() || !findNativeStackAnchor(F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        SmallPtrSet<Value *, 32> Seen;
        if (containsNativeStackInteger(ITP->getOperand(0), Seen))
          Candidates.push_back(ITP);
      }
    }
  }

  unsigned Lowered = 0;
  for (IntToPtrInst *ITP : Candidates) {
    if (!ITP->getParent())
      continue;
    IRBuilder<> B(ITP);
    Value *NativePtr = lowerNativeStackInteger(
        B, ITP->getOperand(0), *ITP->getFunction());
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
