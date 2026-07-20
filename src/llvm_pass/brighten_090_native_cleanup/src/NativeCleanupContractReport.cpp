#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

bool isRemillMetadataName(StringRef Name) {
  return Name.starts_with("remill.") || Name.starts_with("mcsema.") ||
         Name.starts_with("brighten.guest.");
}

bool isGuestStackRegister(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  StringRef Name = V->getName();
  if (Name.contains("state_2312") || Name.contains("state_2328") ||
      Name.contains("state_in_2312") || Name.contains("state_in_2328") ||
      Name.contains("new_rsp") || Name.contains("new_rbp"))
    return true;
  if (auto *BO = dyn_cast<BinaryOperator>(V))
    return isGuestStackRegister(BO->getOperand(0), Seen) ||
           isGuestStackRegister(BO->getOperand(1), Seen);
  if (auto *PN = dyn_cast<PHINode>(V))
    for (Value *Incoming : PN->incoming_values())
      if (isGuestStackRegister(Incoming, Seen))
        return true;
  if (auto *SI = dyn_cast<SelectInst>(V))
    return isGuestStackRegister(SI->getTrueValue(), Seen) ||
           isGuestStackRegister(SI->getFalseValue(), Seen);
  return false;
}

void collectNativeContractViolations(
    Module &M, SmallVectorImpl<std::string> &Findings) {
  for (StructType *ST : M.getIdentifiedStructTypes()) {
    if (isStateType(ST))
      addFinding(Findings, "state type", ST->getName());
    if (ST->hasName() && ST->getName().starts_with("seg_"))
      addFinding(Findings, "raw segment type", ST->getName());
  }

  for (Function &F : M) {
    StringRef Name = F.getName();
    if (Name == "main" &&
        ((F.arg_size() != 2 && F.arg_size() != 3) ||
         !F.getReturnType()->isIntegerTy(32) ||
         !F.getArg(0)->getType()->isIntegerTy(32) ||
         !F.getArg(1)->getType()->isPointerTy() ||
         (F.arg_size() == 3 && !F.getArg(2)->getType()->isPointerTy())))
      addFinding(Findings, "native entrypoint ABI", Name);
    if ((Name == "main" || Name.starts_with("native_entry_impl")) &&
        !F.isDeclaration() && F.size() == 1 &&
        F.getEntryBlock().size() == 1 &&
        isa<UnreachableInst>(F.getEntryBlock().getTerminator()))
      addFinding(Findings, "collapsed unreachable native entrypoint", Name);
    if (isLiftedFunctionName(Name) || isLiftedABI(F))
      addFinding(Findings, "lifted function/ABI", Name);
    if (Name.ends_with(".native") ||
        (F.arg_size() && F.getArg(0)->getType()->isPointerTy() &&
         F.getArg(0)->getName() == "state"))
      addFinding(Findings, "State-pointer native ABI", Name);
    if (auto *ST = dyn_cast<StructType>(F.getReturnType()))
      if (ST->hasName() && ST->getName().ends_with(".state_result"))
        addFinding(Findings, "State-slot aggregate return ABI", Name);
    for (Argument &A : F.args()) {
      if (A.getName() == "native_stack" || A.getName() == "frame_base")
        addFinding(Findings, "guest stack function ABI", Name);
    }
    if (F.hasMetadata("remill.function.type") ||
        F.hasMetadata("remill.function") || F.hasMetadata("mcsema.function"))
      addFinding(Findings, "lifter metadata", Name);

    bool HasDispatcherLikeCFG = false;
    for (BasicBlock &BB : F) {
      auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
      auto *StatePhi = SI ? dyn_cast<PHINode>(SI->getCondition()) : nullptr;
      if (!SI || !StatePhi || SI->getNumCases() < 2 ||
          SI->getDefaultDest() != &BB)
        continue;
      // OLLVM-style flattening uses a loop-carried pseudo-random state and a
      // self-looping default arm.  A source-language switch may legitimately
      // be sparse, so require both that structural signature and a non-dense
      // case set before rejecting it as a dispatcher.
      APInt Min = SI->case_begin()->getCaseValue()->getValue();
      APInt Max = Min;
      for (auto Case : SI->cases()) {
        const APInt &V = Case.getCaseValue()->getValue();
        if (V.slt(Min)) Min = V;
        if (V.sgt(Max)) Max = V;
      }
      APInt Span = Max - Min;
      if (Span.ugt(SI->getNumCases() * 4)) {
        HasDispatcherLikeCFG = true;
        break;
      }
    }
    if (HasDispatcherLikeCFG)
      addFinding(Findings, "guest CFG / flattened dispatcher model", Name);

    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &Op : I.operands()) {
          if (containsUndefined(Op.get())) {
            addFinding(Findings, "undef/poison", F.getName());
            break;
          }
        }
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          if (isa<ConstantInt>(ITP->getOperand(0)))
            addFinding(Findings, "constant guest address", F.getName());
          if (ITP->getName().starts_with("native.ptr") ||
              ITP->getName().starts_with("native.stack"))
            addFinding(Findings, "generated guest address conversion",
                       F.getName());
        }
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (isa<InlineAsm>(CB->getCalledOperand()))
            addFinding(Findings, "inline assembly", F.getName());
        }
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          if (isAddressArtifact(PTI->getPointerOperand()))
            addFinding(Findings, "lifted address conversion", F.getName());
          // The names used by stack lowering also cover a host frame anchor
          // while constructing a native GEP delta.  Reject only a conversion
          // whose source is not already a proven native pointer; otherwise a
          // legitimate `ptrtoint %frame_base` is indistinguishable by name
          // from a lifted numeric guest-stack carrier.
          if (PTI->getName().starts_with("native.stack")) {
            SmallPtrSet<Value *, 16> PointerSeen;
            if (!isNativePointerValue(PTI->getPointerOperand(), PointerSeen))
              addFinding(Findings, "guest stack address integer carrier",
                         F.getName());
          }
        }
        if (auto *AI = dyn_cast<AllocaInst>(&I)) {
          if (auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType()))
            if (AT->getNumElements() >= 1024 * 1024 &&
                AT->getElementType()->isIntegerTy(8) &&
                !AI->getName().starts_with("frame_storage") &&
                !AI->getName().starts_with("native_stack_storage"))
              addFinding(Findings, "fake guest stack allocation", F.getName());
          if (AI->getName().starts_with("native_stack") ||
              AI->getName().starts_with("frame_storage"))
            addFinding(Findings, "guest stack backing allocation", F.getName());
        }
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          SmallPtrSet<Value *, 16> AddressSeen;
          if (isGuestStackRegister(ITP->getOperand(0), AddressSeen))
            addFinding(Findings, "guest stack integer-to-pointer", F.getName());
        }
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (Function *Callee = CB->getCalledFunction()) {
            StringRef ExternalName = Callee->getName();
            StringRef CanonicalName = ExternalName;
            if (CanonicalName.ends_with(".lifted_abi"))
              CanonicalName = CanonicalName.drop_back(StringRef(".lifted_abi").size());
            if (FunctionType *Expected = nativeExternalType(M, CanonicalName)) {
              if (Callee->getName().ends_with(".lifted_abi") ||
                  CB->getFunctionType() != Expected)
                addFinding(Findings, "external ABI mismatch", ExternalName);
            }
            if (Callee->getIntrinsicID() == Intrinsic::sideeffect &&
                CB->getOperandBundle("brighten_return_rax").has_value())
              addFinding(Findings, "transient RAX return marker",
                         F.getName());
            if (Callee->getName() == "__brighten_native_data_pointer")
              addFinding(Findings, "segment pointer mapper", F.getName());
            if (isLiftedFunctionName(Callee->getName()))
              addFinding(Findings, "lifted call", Callee->getName());
          }
        }
      }
    }
  }

  for (GlobalAlias &GA : M.aliases()) {
    StringRef Name = GA.getName();
    if (isLiftedGlobalName(Name) || Name.starts_with("data_"))
      addFinding(Findings, "lifted alias", Name);
  }
  for (GlobalVariable &GV : M.globals()) {
    StringRef Name = GV.getName();
    if (isLiftedGlobalName(Name) || Name.starts_with("seg_") ||
        Name.starts_with("__lifter_guest_stack"))
      addFinding(Findings, "lifted global", Name);
    if (Name.starts_with("frame_storage_backing."))
      addFinding(Findings, "guest stack backing global", Name);
    if (GV.hasInitializer() && containsUndefined(GV.getInitializer()))
      addFinding(Findings, "undef/poison global", Name);
    if (GV.getMetadata("brighten.guest.range"))
      addFinding(Findings, "guest address-range metadata", Name);
  }

  for (NamedMDNode &NMD : M.named_metadata()) {
    if (isRemillMetadataName(NMD.getName()))
      addFinding(Findings, "lifter named metadata", NMD.getName());
  }
}

unsigned countStateGlobals(Module &M) {
  unsigned Count = 0;
  for (GlobalVariable &GV : M.globals())
    Count += GV.getName().contains("__mcsema_reg_state");
  for (GlobalAlias &GA : M.aliases())
    Count += GA.getName().contains("__mcsema_reg_state");
  return Count;
}

void reportNativeContract(Module &M, unsigned RemovedFunctions,
                                 unsigned RemovedGlobals,
                                 bool EnforceStrict) {
  unsigned NativeFunctions = 0;
  unsigned RemillCalls = 0;
  unsigned StateGlobals = countStateGlobals(M);
  unsigned SegmentGlobals = 0;
  unsigned PoisonOperands = 0;
  unsigned UndefOperands = 0;
  unsigned InlineAsmCalls = 0;
  unsigned PtrToIntOps = 0;
  unsigned IntToPtrOps = 0;

  for (Function &F : M) {
    NativeFunctions += F.getName().ends_with(".native");
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        PtrToIntOps += isa<PtrToIntInst>(&I);
        IntToPtrOps += isa<IntToPtrInst>(&I);
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (Function *Callee = CB->getCalledFunction())
            RemillCalls += Callee->getName().starts_with("__remill_") ||
                           Callee->getName().starts_with("__mcsema_");
          InlineAsmCalls += isa<InlineAsm>(CB->getCalledOperand());
        }
        for (Use &Op : I.operands()) {
          PoisonOperands += isa<PoisonValue>(Op.get());
          UndefOperands += isa<UndefValue>(Op.get());
        }
      }
    }
  }
  for (GlobalVariable &GV : M.globals())
    SegmentGlobals += GV.getName().starts_with("seg_");

  SmallVector<std::string, 32> Violations;
  collectNativeContractViolations(M, Violations);
  errs() << "brighten-native-cleanup report:\n"
         << "  native functions: " << NativeFunctions << "\n"
         << "  unused lifted functions removed: " << RemovedFunctions << "\n"
         << "  unused lifted globals removed: " << RemovedGlobals << "\n"
         << "  remaining State globals/aliases: " << StateGlobals << "\n"
         << "  remaining segment globals: " << SegmentGlobals << "\n"
         << "  remaining Remill/McSema calls: " << RemillCalls << "\n"
         << "  poison operands: " << PoisonOperands << "\n"
         << "  undef operands: " << UndefOperands << "\n"
         << "  inline-asm calls: " << InlineAsmCalls << "\n"
         << "  ptrtoint/inttoptr: " << PtrToIntOps << "/" << IntToPtrOps
         << "\n"
         << "  native contract violations: " << Violations.size() << "\n";

  // Keep the final verifier useful even when strict aborts are intentionally
  // disabled for corpus development.  The Python driver persists these
  // findings beside the output, so a successfully emitted module cannot be
  // mistaken for one that satisfies the fully-native contract.
  if (EnforceStrict)
    for (StringRef Finding : Violations)
      errs() << "  native contract finding: " << Finding << "\n";

  if (NativeStrict && EnforceStrict && !Violations.empty()) {
    errs() << "brighten-native-cleanup strict verification failed:\n";
    for (StringRef Finding : Violations)
      errs() << "  - " << Finding << "\n";
    report_fatal_error("module does not satisfy fully-native LLVM IR contract");
  }
}

void stripRemillMetadata(Module &M, bool &Changed,
                                bool StripGuestRanges) {
  SmallVector<unsigned, 8> Kinds;
  LLVMContext &Ctx = M.getContext();
  for (StringRef Name : {StringRef("remill.function.type"),
                         StringRef("remill.function"),
                         StringRef("mcsema.function")}) {
    unsigned Kind = Ctx.getMDKindID(Name);
    Kinds.push_back(Kind);
  }
  if (StripGuestRanges)
  {
    Kinds.push_back(Ctx.getMDKindID("brighten.guest.range"));
    Kinds.push_back(Ctx.getMDKindID("brighten.guest.base"));
  }

  for (Function &F : M) {
    for (unsigned Kind : Kinds) {
      if (F.getMetadata(Kind)) {
        F.setMetadata(Kind, nullptr);
        Changed = true;
      }
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned Kind : Kinds) {
          if (I.getMetadata(Kind)) {
            I.setMetadata(Kind, nullptr);
            Changed = true;
          }
        }
      }
    }
  }

  for (GlobalVariable &GV : M.globals()) {
    for (unsigned Kind : Kinds) {
      if (GV.getMetadata(Kind)) {
        GV.setMetadata(Kind, nullptr);
        Changed = true;
      }
    }
  }

  SmallVector<NamedMDNode *, 8> DeadNamedMetadata;
  for (NamedMDNode &NMD : M.named_metadata()) {
    if (isRemillMetadataName(NMD.getName()))
      DeadNamedMetadata.push_back(&NMD);
  }
  for (NamedMDNode *NMD : DeadNamedMetadata) {
    NMD->eraseFromParent();
    Changed = true;
  }
}

void foldExactPointerRoundTrips(Module &M, bool &Changed) {
  SmallVector<IntToPtrInst *, 16> RoundTrips;
  SmallVector<PtrToIntInst *, 16> IntegerRoundTrips;
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          Value *Integer = ITP->getOperand(0);
          bool Exact = false;
          if (auto *PTI = dyn_cast<PtrToIntInst>(Integer))
            Exact = PTI->getPointerOperand()->getType()->getPointerAddressSpace() ==
                    ITP->getType()->getPointerAddressSpace();
          else if (auto *CE = dyn_cast<ConstantExpr>(Integer))
            Exact = CE->getOpcode() == Instruction::PtrToInt &&
                    CE->getOperand(0)->getType()->getPointerAddressSpace() ==
                        ITP->getType()->getPointerAddressSpace();
          if (Exact)
            RoundTrips.push_back(ITP);
        }
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          auto *ITP = dyn_cast<IntToPtrInst>(PTI->getPointerOperand());
          if (ITP && ITP->getOperand(0)->getType() == PTI->getType()) {
            Value *Inner = ITP->getOperand(0);
            bool FoldedByPointerRoundTrip = isa<PtrToIntInst>(Inner);
            if (auto *CE = dyn_cast<ConstantExpr>(Inner))
              FoldedByPointerRoundTrip |=
                  CE->getOpcode() == Instruction::PtrToInt;
            if (!FoldedByPointerRoundTrip)
              IntegerRoundTrips.push_back(PTI);
          }
        }
      }

  for (IntToPtrInst *ITP : RoundTrips) {
    Value *Integer = ITP->getOperand(0);
    Value *Pointer = isa<PtrToIntInst>(Integer)
                         ? cast<PtrToIntInst>(Integer)->getPointerOperand()
                         : cast<ConstantExpr>(Integer)->getOperand(0);
    ITP->replaceAllUsesWith(Pointer);
    ITP->eraseFromParent();
    Changed = true;
  }
  for (PtrToIntInst *PTI : IntegerRoundTrips) {
    auto *ITP = cast<IntToPtrInst>(PTI->getPointerOperand());
    PTI->replaceAllUsesWith(ITP->getOperand(0));
    PTI->eraseFromParent();
    if (ITP->use_empty())
      ITP->eraseFromParent();
    Changed = true;
  }
}

} // namespace brighten_native_cleanup
