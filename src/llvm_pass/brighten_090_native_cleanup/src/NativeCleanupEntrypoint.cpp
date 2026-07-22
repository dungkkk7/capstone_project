#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

// Entrypoint-native functions can retain architectural RSP/RBP integers even
// after State-SSA.  If those values are later used as pointers, the public
// wrapper must provide one concrete backing object and seed the entry RSP
// before calling the native body.  Create it only for that proven residual
// stack-pointer case; ordinary modules keep the old no-synthetic-stack path.
GlobalVariable *ensureNativeEntrypointStackStorage(Module &M) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->isDeclaration() || Main->arg_size() == 2)
    return nullptr;
  if (Main->arg_size() < 2 || !Main->getReturnType()->isIntegerTy(32) ||
      !Main->getArg(0)->getType()->isIntegerTy(32) ||
      !Main->getArg(1)->getType()->isPointerTy())
    return nullptr;

  bool CallsNative = false;
  for (BasicBlock &BB : *Main)
    for (Instruction &I : BB)
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *Callee = CB->getCalledFunction();
            Callee && Callee->getName().ends_with(".native")) {
          CallsNative = true;
          break;
        }
  if (!CallsNative)
    return nullptr;

  if (GlobalVariable *Existing = M.getNamedGlobal("frame_storage_backing.main"))
    return Existing;

  bool HasResidualStackPointer = false;
  for (Function &F : M) {
    if (F.isDeclaration() || !F.getName().ends_with(".native"))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        SmallPtrSet<Value *, 32> Seen;
        if (containsNativeStackInteger(ITP->getOperand(0), Seen)) {
          HasResidualStackPointer = true;
          break;
        }
      }
      if (HasResidualStackPointer)
        break;
    }
    if (HasResidualStackPointer)
      break;
  }
  if (!HasResidualStackPointer)
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  auto *StackTy = ArrayType::get(Type::getInt8Ty(Ctx), NativeStackBytes);
  auto *Storage = new GlobalVariable(
      M, StackTy, false, GlobalValue::InternalLinkage,
      ConstantAggregateZero::get(StackTy), "frame_storage_backing.main");
  Storage->setAlignment(Align(16));
  return Storage;
}

bool normalizeNativeEntrypoint(Module &M, bool &Changed) {
  Function *Main = M.getFunction("main");
  GlobalVariable *Storage = ensureNativeEntrypointStackStorage(M);
  if (!Main || !Storage)
    return false;

  LLVMContext &Ctx = M.getContext();
  auto *StorageTy = dyn_cast<ArrayType>(Storage->getValueType());
  if (!StorageTy || !StorageTy->getElementType()->isIntegerTy(8))
    return false;
  uint64_t NativeStackBytes = StorageTy->getNumElements();
  uint64_t NativeStackTop = NativeStackBytes > 64 * 1024
                                ? NativeStackBytes - 64 * 1024
                                : NativeStackBytes;
  if (MDNode *TopMD = Storage->getMetadata("brighten.stack.top")) {
    if (TopMD->getNumOperands() == 1)
      if (auto *CAM = dyn_cast<ConstantAsMetadata>(TopMD->getOperand(0)))
        if (auto *Top = dyn_cast<ConstantInt>(CAM->getValue()))
          if (Top->getZExtValue() <= NativeStackBytes)
            NativeStackTop = Top->getZExtValue();
  }
  GlobalVariable *CanonicalState = nullptr;
  for (GlobalVariable &GV : M.globals())
    if (GV.getName().contains("__mcsema_reg_state")) {
      CanonicalState = &GV;
      break;
    }
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      Function *Callee = CB ? CB->getCalledFunction() : nullptr;
      if (!CB || !Callee || !Callee->getName().ends_with(".native"))
        continue;
      Value *State = CanonicalState;
      if (!Callee->arg_empty() && Callee->getArg(0)->getName() == "state" &&
          !CB->arg_empty() && CB->getArgOperand(0)->getType()->isPointerTy() &&
          !isa<ConstantPointerNull>(CB->getArgOperand(0)))
        State = CB->getArgOperand(0);
      if (!State)
        continue;
      IRBuilder<> B(CB);
      Value *Base = B.CreateInBoundsGEP(
          StorageTy, Storage, {B.getInt32(0), B.getInt32(0)},
          "native_entry_stack_storage");
      Value *Top = B.CreateConstGEP1_64(B.getInt8Ty(), Base, NativeStackTop,
                                        "native_entry_stack_top");
      Value *TopInt = B.CreatePtrToInt(Top, B.getInt64Ty(),
                                      "native_entry_stack_int");
      for (uint64_t Offset : {uint64_t(2312), uint64_t(2328)}) {
        Value *Slot = B.CreateGEP(B.getInt8Ty(), State, B.getInt64(Offset));
        auto *Seed = B.CreateStore(TopInt, Slot);
        Seed->setVolatile(true);
      }
    }
  }

  FunctionType *ImplTy = Main->getFunctionType();
  // The public entrypoint only has evidence for argc/argv/envp.  Extra
  // implementation parameters cannot be initialized soundly here; preserve
  // the original entrypoint instead of inventing null ABI arguments.
  if (ImplTy->getNumParams() > 3)
    return false;
  std::string ImplName = "native_entry_impl";
  for (unsigned Suffix = 0; M.getFunction(ImplName); ++Suffix)
    ImplName = "native_entry_impl." + std::to_string(Suffix + 1);
  Main->setName(ImplName);
  Main->setLinkage(GlobalValue::InternalLinkage);
  Main->setDSOLocal(true);

  FunctionType *EntryTy = FunctionType::get(
      Type::getInt32Ty(Ctx),
      {Type::getInt32Ty(Ctx), PointerType::getUnqual(Ctx),
       PointerType::getUnqual(Ctx)}, false);
  Function *Entry = Function::Create(EntryTy, GlobalValue::ExternalLinkage,
                                     "main", M);
  Entry->setCallingConv(Main->getCallingConv());
  Entry->setDSOLocal(true);
  Entry->setVisibility(Main->getVisibility());

  IRBuilder<> B(BasicBlock::Create(Ctx, "entry", Entry));
  SmallVector<Value *, 4> Args;
  Args.push_back(Entry->getArg(0));
  Args.push_back(Entry->getArg(1));
  if (ImplTy->getNumParams() > 2)
    Args.push_back(Entry->getArg(2));
  CallInst *Call = B.CreateCall(Main, Args, "native.entry.impl");
  Call->setCallingConv(Main->getCallingConv());
  B.CreateRet(Call);
  Changed = true;
  errs() << "  native entrypoint normalized to main(i32, ptr)\n";
  return true;
}

// The recovered entrypoint owns the concrete State and guest-stack backing
// allocations. Inlining a State-ABI callee through that boundary lets O3
// scalarize partially-defined State slots into `undef` pointer operands. A
// dereference of one of those operands is UB, after which SimplifyCFG may
// legally replace the entire entrypoint with `unreachable`. Keep only this
// ABI boundary opaque; callees remain available for normal optimization.
unsigned preserveNativeEntrypointStateBoundary(Module &M,
                                                       bool &Changed) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->isDeclaration())
    return 0;

  unsigned Preserved = 0;
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      // Proxy cleanup may leave an indirect or bitcast callsite pending later
      // canonicalization.  This boundary only needs direct native callees;
      // walking an unstable ConstantExpr cast chain here can dereference a
      // value invalidated by the preceding cleanup mutations.
      Function *Callee = CB->getCalledFunction();
      if (!Callee || Callee->isDeclaration() ||
          Callee->hasFnAttribute(Attribute::NoInline))
        continue;

      bool HasExplicitStatePointer =
          Callee->getName().ends_with(".native") && Callee->arg_size() &&
          Callee->getArg(0)->getType()->isPointerTy() &&
          Callee->getArg(0)->getName() == "state";
      bool IsStateBoundary = isLiftedABI(*Callee) || HasExplicitStatePointer;
      if (!IsStateBoundary)
        continue;

      Callee->addFnAttr(Attribute::NoInline);
      ++Preserved;
      Changed = true;
    }
  }
  return Preserved;
}

// Keep recovered native-to-native calls visible until the final State-SSA
// cleanup.  A recovered helper may use the guest RSP/RBP to address its own
// frame even when those registers are absent from its simplified C-like ABI.
// Inlining such a helper into its caller before State-SSA collapses the two
// guest frame identities onto the same backing object.  Once that happens,
// later stack relativization cannot distinguish a callee local from a caller
// local.  The final cleanup rewrites these calls with explicit frame/RSP/RBP
// carriers, after which normal code generation can optimize their bodies
// without losing the nested-frame boundary.
unsigned preserveNestedNativeFrameBoundaries(Module &M,
                                                     bool &Changed) {
  unsigned Preserved = 0;
  for (Function &Caller : M) {
    if (Caller.isDeclaration() || !Caller.getName().ends_with(".native"))
      continue;

    for (BasicBlock &BB : Caller) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!Callee || Callee == &Caller || Callee->isDeclaration() ||
            !Callee->getName().ends_with(".native") ||
            Callee->hasFnAttribute(Attribute::NoInline))
          continue;
        // The callee owns the nested guest frame.  Marking the caller would
        // only stop the caller from moving upward; it would still allow this
        // callee body (and its frame) to collapse into the caller.
        Callee->addFnAttr(Attribute::NoInline);
        ++Preserved;
        Changed = true;
      }
    }
  }
  return Preserved;
}

bool IsStartupOnlyUse(User *U, Function *Target) {
  if (auto *CB = dyn_cast<CallBase>(U)) {
    Function *Caller = CB->getFunction();
    return Caller && (Caller->getName() == "__remill_function_call" ||
                      Caller->getName() == "__remill_jump");
  }

  auto *PN = dyn_cast<PHINode>(U);
  if (!PN || PN->getFunction()->getName() != "__translate_guest_pointer")
    return false;
  for (Value *Incoming : PN->incoming_values()) {
    if (Incoming->stripPointerCasts() == Target)
      return true;
  }
  return false;
}

bool RemoveTargetFromDispatcher(Function &Dispatcher,
                                       Function *Target) {
  if (Dispatcher.isDeclaration() || !Target)
    return false;

  SmallVector<BasicBlock *, 4> DeadBlocks;
  bool Changed = false;
  for (BasicBlock &BB : Dispatcher) {
    auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
    if (!SI)
      continue;

    for (int I = static_cast<int>(SI->getNumCases()) - 1; I >= 0; --I) {
      auto Case = SI->case_begin() + I;
      BasicBlock *CaseBB = Case->getCaseSuccessor();
      bool CallsTarget = false;
      for (Instruction &Inst : *CaseBB) {
        if (auto *CB = dyn_cast<CallBase>(&Inst)) {
          if (CB->getCalledOperand()->stripPointerCasts() == Target) {
            CallsTarget = true;
            break;
          }
        }
      }
      if (!CallsTarget)
        continue;
      SI->removeCase(Case);
      DeadBlocks.push_back(CaseBB);
      Changed = true;
    }
  }

  for (BasicBlock *BB : DeadBlocks) {
    if (pred_empty(BB))
      BB->eraseFromParent();
  }
  return Changed;
}

bool RemoveTargetFromGuestPointerTranslator(Module &M,
                                                    Function *Target,
                                                    uint64_t GuestPC) {
  Function *Translator = M.getFunction("__translate_guest_pointer");
  if (!Translator || Translator->isDeclaration() || !Target)
    return false;

  bool Changed = false;
  SmallVector<BasicBlock *, 4> DeadBlocks;
  for (BasicBlock &BB : *Translator) {
    auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
    if (!SI)
      continue;

    for (int I = static_cast<int>(SI->getNumCases()) - 1; I >= 0; --I) {
      auto Case = SI->case_begin() + I;
      if (Case->getCaseValue()->getZExtValue() != GuestPC)
        continue;

      BasicBlock *CaseBB = Case->getCaseSuccessor();
      PHINode *Result = nullptr;
      for (BasicBlock &Candidate : *Translator) {
        for (Instruction &Inst : Candidate) {
          auto *PN = dyn_cast<PHINode>(&Inst);
          if (!PN)
            continue;
          for (unsigned Incoming = 0; Incoming < PN->getNumIncomingValues();
               ++Incoming) {
            if (PN->getIncomingBlock(Incoming) == CaseBB &&
                PN->getIncomingValue(Incoming)->stripPointerCasts() ==
                    Target) {
              Result = PN;
              break;
            }
          }
          if (Result)
            break;
        }
        if (Result)
          break;
      }
      if (!Result)
        continue;

      Result->removeIncomingValue(CaseBB, false);
      SI->removeCase(Case);
      DeadBlocks.push_back(CaseBB);
      Changed = true;
    }
  }

  for (BasicBlock *BB : DeadBlocks) {
    if (pred_empty(BB))
      BB->eraseFromParent();
  }
  return Changed;
}

// Once `main` is the only native entrypoint, a synthetic sub_*_start routine
// is dead if its only two kinds of uses are the Remill dispatch tables and the
// guest-pointer translator.  Remove those proven-dead edges before generic
// dead-function cleanup; this also prevents the startup path from keeping
// __remill_function_call alive.
unsigned eraseDeadSyntheticStartupDispatch(Module &M, bool &Changed) {
  if (!M.getFunction("main"))
    return 0;

  SmallVector<Function *, 8> Candidates;
  for (Function &F : M) {
    StringRef Name = F.getName();
    if (F.isDeclaration() || !Name.starts_with("sub_") ||
        !Name.ends_with("_start") || !isLiftedABI(F))
      continue;

    StringRef Rest = Name.drop_front(4);
    size_t Sep = Rest.find('_');
    if (Sep == StringRef::npos)
      continue;
    uint64_t GuestPC = 0;
    if (Rest.substr(0, Sep).getAsInteger(16, GuestPC))
      continue;

    bool OnlyStartupUses = true;
    for (User *U : F.users()) {
      if (!IsStartupOnlyUse(U, &F)) {
        OnlyStartupUses = false;
        break;
      }
    }
    if (OnlyStartupUses)
      Candidates.push_back(&F);
  }

  unsigned Removed = 0;
  for (Function *Target : Candidates) {
    StringRef Name = Target->getName();
    StringRef Rest = Name.drop_front(4);
    uint64_t GuestPC = 0;
    Rest.substr(0, Rest.find('_')).getAsInteger(16, GuestPC);

    bool LocalChanged = false;
    for (StringRef DispatcherName : {StringRef("__remill_function_call"),
                                     StringRef("__remill_jump")}) {
      if (Function *Dispatcher = M.getFunction(DispatcherName))
        LocalChanged |= RemoveTargetFromDispatcher(*Dispatcher, Target);
    }
    LocalChanged |= RemoveTargetFromGuestPointerTranslator(M, Target, GuestPC);
    if (!LocalChanged || !Target->use_empty())
      continue;

    Target->eraseFromParent();
    Changed = true;
    ++Removed;
    errs() << "  synthetic startup dispatch removed: " << Name << "\n";
  }
  return Removed;
}

unsigned eraseUnusedLiftedGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalAlias *, 32> DeadAliases;
  for (GlobalAlias &GA : M.aliases()) {
    GA.removeDeadConstantUsers();
    if (GA.hasLocalLinkage() && GA.use_empty() &&
        isLiftedGlobalName(GA.getName()))
      DeadAliases.push_back(&GA);
  }
  for (GlobalAlias *GA : DeadAliases) {
    GA->eraseFromParent();
    Changed = true;
  }

  SmallVector<GlobalVariable *, 32> DeadGlobals;
  for (GlobalVariable &GV : M.globals()) {
    if (isLiftedGlobalName(GV.getName()))
      GV.removeDeadConstantUsers();
    if (GV.hasLocalLinkage() && GV.use_empty() &&
        isLiftedGlobalName(GV.getName()))
      DeadGlobals.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    Changed = true;
  }
  return DeadAliases.size() + DeadGlobals.size();
}

unsigned eraseDeadStateGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalAlias *, 8> DeadAliases;
  for (GlobalAlias &GA : M.aliases()) {
    GA.removeDeadConstantUsers();
    if (GA.getName().contains("__mcsema_reg_state") && GA.use_empty())
      DeadAliases.push_back(&GA);
  }
  for (GlobalAlias *GA : DeadAliases) {
    GA->eraseFromParent();
    Changed = true;
  }

  SmallVector<GlobalVariable *, 8> DeadGlobals;
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().contains("__mcsema_reg_state"))
      continue;
    GV.removeDeadConstantUsers();
    if (GV.use_empty())
      DeadGlobals.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    Changed = true;
  }
  return DeadAliases.size() + DeadGlobals.size();
}

bool constantContainsStateGlobal(Constant *C, GlobalVariable *GV,
                                        SmallPtrSetImpl<Constant *> &Seen) {
  if (!C || !Seen.insert(C).second)
    return false;
  if (C == GV)
    return true;
  for (Value *Op : C->operands())
    if (auto *Nested = dyn_cast<Constant>(Op))
      if (constantContainsStateGlobal(Nested, GV, Seen))
        return true;
  return false;
}

bool collectStateGlobalInstructionUsers(
    Value *V, Function *&Owner, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return true;
  for (User *U : V->users()) {
    if (auto *C = dyn_cast<Constant>(U)) {
      if (!collectStateGlobalInstructionUsers(C, Owner, Seen))
        return false;
      continue;
    }
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      return false;
    if (!Owner)
      Owner = I->getFunction();
    else if (Owner != I->getFunction())
      return false;
    if (isa<CallBase>(I) || isa<PtrToIntInst>(I) || isa<ReturnInst>(I))
      return false;
    if (auto *SI = dyn_cast<StoreInst>(I))
      if (SI->getValueOperand() == V)
        return false;
    if (I->getType()->isPointerTy())
      if (!collectStateGlobalInstructionUsers(I, Owner, Seen))
        return false;
  }
  return true;
}

bool collectStateGlobalInstructionOwners(
    Value *V, SmallPtrSetImpl<Function *> &Owners,
    SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return true;
  for (User *U : V->users()) {
    if (auto *C = dyn_cast<Constant>(U)) {
      if (!collectStateGlobalInstructionOwners(C, Owners, Seen))
        return false;
      continue;
    }
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      return false;
    Owners.insert(I->getFunction());
    // State storage may be followed only through ordinary pointer carriers
    // and accessed as memory.  Passing its address across a call, converting
    // it to an observable integer, returning it, or storing the pointer itself
    // would make per-entry ownership unprovable.
    if (isa<CallBase>(I) || isa<PtrToIntInst>(I) || isa<ReturnInst>(I))
      return false;
    if (auto *SI = dyn_cast<StoreInst>(I))
      if (SI->getValueOperand() == V)
        return false;
    if (I->getType()->isPointerTy())
      if (!collectStateGlobalInstructionOwners(I, Owners, Seen))
        return false;
  }
  return true;
}

static bool isIndependentNativeStateRoot(Function *F) {
  if (!F || F->isDeclaration())
    return false;
  StringRef Name = F->getName();
  return Name == "main" || Name == "native_entry_impl" ||
         Name.ends_with(".native_callback") ||
         Name.ends_with(".qsort_callback");
}

static bool haveIndependentNativeStateOwners(
    const SmallPtrSetImpl<Function *> &Owners) {
  if (Owners.empty())
    return false;
  for (Function *Owner : Owners)
    if (!isIndependentNativeStateRoot(Owner))
      return false;

  // These functions are separate host ABI entry activations.  A direct call
  // between two of them would instead establish an ordinary interprocedural
  // State flow, so reject that shape rather than silently splitting it.
  for (Function *Owner : Owners)
    for (BasicBlock &BB : *Owner)
      for (Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (Function *Callee = CB->getCalledFunction())
            if (Owners.contains(Callee))
              return false;
  return true;
}

Value *materializeStateConstantForAlloca(Constant *C,
                                                GlobalVariable *GV,
                                                AllocaInst *Storage,
                                                Instruction *InsertBefore) {
  if (C == GV)
    return Storage;
  auto *CE = dyn_cast<ConstantExpr>(C);
  if (!CE)
    return C;
  Instruction *Materialized = CE->getAsInstruction();
  for (unsigned I = 0; I < CE->getNumOperands(); ++I) {
    auto *Nested = dyn_cast<Constant>(CE->getOperand(I));
    if (!Nested)
      continue;
    SmallPtrSet<Constant *, 16> Seen;
    if (!constantContainsStateGlobal(Nested, GV, Seen))
      continue;
    Value *Replacement = materializeStateConstantForAlloca(
        Nested, GV, Storage, InsertBefore);
    Materialized->setOperand(I, Replacement);
  }
  Materialized->insertBefore(InsertBefore->getIterator());
  return Materialized;
}

// Once startup/dispatcher functions have been removed, a private McSema State
// object often has users in exactly one native entry function.  Keeping it as
// a global prevents SROA and makes the final IR retain a hidden register file.
// Localize only a non-escaping, single-owner object; O3 can then split its
// constant slots and promote them to ordinary SSA values.
unsigned localizePrivateStateGlobals(Module &M, bool &Changed) {
  struct Candidate {
    GlobalVariable *GV = nullptr;
    SmallVector<Function *, 4> Owners;
  };
  SmallVector<Candidate, 8> Candidates;
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().contains("__mcsema_reg_state") || GV.isThreadLocal() ||
        !GV.hasInitializer() || containsUndefined(GV.getInitializer()))
      continue;
    SmallPtrSet<Function *, 4> Owners;
    SmallPtrSet<Value *, 32> Seen;
    if (!collectStateGlobalInstructionOwners(&GV, Owners, Seen) ||
        Owners.empty())
      continue;
    if (Owners.size() > 1 && !haveIndependentNativeStateOwners(Owners))
      continue;
    Candidate C;
    C.GV = &GV;
    C.Owners.append(Owners.begin(), Owners.end());
    Candidates.push_back(std::move(C));
  }

  unsigned Localized = 0;
  for (Candidate &C : Candidates) {
    GlobalVariable *GV = C.GV;
    bool CandidateComplete = true;
    for (Function *Owner : C.Owners) {
      IRBuilder<> EB(&*Owner->getEntryBlock().getFirstInsertionPt());
      AllocaInst *Storage = EB.CreateAlloca(GV->getValueType(), nullptr,
                                            "native_state_storage");
      Storage->setAlignment(GV->getAlign().valueOrOne());
      EB.CreateStore(GV->getInitializer(), Storage);

      SmallVector<Instruction *, 128> Instructions;
      for (BasicBlock &BB : *Owner)
        for (Instruction &I : BB)
          Instructions.push_back(&I);
      for (Instruction *I : Instructions) {
        for (unsigned OpNo = 0; OpNo < I->getNumOperands(); ++OpNo) {
          auto *ConstantOperand = dyn_cast<Constant>(I->getOperand(OpNo));
          if (!ConstantOperand)
            continue;
          SmallPtrSet<Constant *, 16> ConstantSeen;
          if (!constantContainsStateGlobal(ConstantOperand, GV, ConstantSeen))
            continue;
          Instruction *InsertBefore = I;
          if (auto *PN = dyn_cast<PHINode>(I)) {
            unsigned Incoming = PN->getIncomingValueNumForOperand(OpNo);
            InsertBefore = PN->getIncomingBlock(Incoming)->getTerminator();
          }
          I->setOperand(OpNo, materializeStateConstantForAlloca(
                                  ConstantOperand, GV, Storage, InsertBefore));
        }
      }
      if (isAllocaPromotable(Storage)) {
        DominatorTree DT(*Owner);
        SmallVector<AllocaInst *, 1> Allocas{Storage};
        PromoteMemToReg(Allocas, DT);
      }
    }
    GV->removeDeadConstantUsers();
    if (!GV->use_empty()) {
      CandidateComplete = false;
      errs() << "brighten-native-state-ssa: localized State still has "
             << GV->getNumUses() << " use(s)\n";
    }
    if (!CandidateComplete)
      continue;
    GV->eraseFromParent();
    ++Localized;
    Changed = true;
  }
  return Localized;
}

Value *materializeHubValueOnPred(Value *V, BasicBlock *Hub,
                                        BasicBlock *Pred, IRBuilder<> &B,
                                        DenseMap<Value *, Value *> &Cache) {
  if (!V)
    return nullptr;
  if (isa<Constant>(V) || isa<Argument>(V) || isa<GlobalValue>(V))
    return V;
  if (auto It = Cache.find(V); It != Cache.end())
    return It->second;
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (PN->getParent() != Hub)
      return nullptr;
    Value *Incoming = PN->getIncomingValueForBlock(Pred);
    Cache[V] = Incoming;
    return Incoming;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getParent() != Hub || I->mayHaveSideEffects() ||
      I->mayReadFromMemory() || I->isTerminator())
    return nullptr;
  if (!isa<BinaryOperator>(I) && !isa<CastInst>(I) &&
      !isa<GetElementPtrInst>(I))
    return nullptr;

  Instruction *Clone = I->clone();
  for (unsigned OpNo = 0; OpNo < Clone->getNumOperands(); ++OpNo) {
    Value *Mapped = materializeHubValueOnPred(I->getOperand(OpNo), Hub, Pred,
                                              B, Cache);
    if (!Mapped) {
      Clone->deleteValue();
      return nullptr;
    }
    Clone->setOperand(OpNo, Mapped);
  }
  Clone->insertBefore(B.GetInsertPoint());
  Cache[V] = Clone;
  return Clone;
}

bool isDispatcherStateValue(Value *V, SwitchInst *SW,
                                   SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return SW->findCaseValue(CI) != SW->case_default();
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    SmallPtrSet<Value *, 8> TrueSeen;
    SmallPtrSet<Value *, 8> FalseSeen;
    return isDispatcherStateValue(Sel->getTrueValue(), SW, TrueSeen) &&
           isDispatcherStateValue(Sel->getFalseValue(), SW, FalseSeen);
  }
  return false;
}

bool isDispatcherStateValue(Value *V, SwitchInst *SW) {
  SmallPtrSet<Value *, 8> Seen;
  return isDispatcherStateValue(V, SW, Seen);
}

StoreInst *findDispatcherStateStore(BasicBlock *BB, Value *Ptr,
                                           SwitchInst *SW) {
  StoreInst *Found = nullptr;
  StoreInst *StateValued = nullptr;
  for (Instruction &I : *BB) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || SI->isVolatile() ||
        !SI->getValueOperand()->getType()->isIntegerTy(32))
      continue;
    if (SI->getPointerOperand() == Ptr) {
      if (Found)
        return nullptr;
      Found = SI;
      continue;
    }
    if (isDispatcherStateValue(SI->getValueOperand(), SW))
      StateValued = SI;
  }
  return Found ? Found : StateValued;
}

// Late native cleanup often exposes an OLLVM-style dispatcher whose state is
// still carried through one recovered stack slot:
//
//   header phis
//   %slot = gep frame, rbp - K
//   %state = load i32, %slot
//   switch %state, ...
//   case: store i32 %next, %slot; br latch
//   latch: br header
//
// The memory slot is not source data; it is the flattened control-state
// variable.  Promote just this proven shape into PHIs so the normal LLVM
// threading/simplification pipeline can collapse hot state-machine loops.
unsigned promoteStackDispatcherStateSlots(Module &M, bool &Changed) {
  SmallVector<SwitchInst *, 16> Switches;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        if (auto *SW = dyn_cast<SwitchInst>(BB.getTerminator()))
          Switches.push_back(SW);

  unsigned Promoted = 0;
  for (SwitchInst *SW : Switches) {
    BasicBlock *Hub = SW->getParent();
    auto *LI = dyn_cast<LoadInst>(SW->getCondition());
    if (!LI || LI->isVolatile() || !LI->getType()->isIntegerTy(32) ||
        LI->getParent() != Hub)
      continue;
    Value *SlotPtr = LI->getPointerOperand();
    if (!isa<GetElementPtrInst>(SlotPtr))
      continue;

    SmallVector<BasicBlock *, 4> HubPreds(predecessors(Hub));
    if (HubPreds.size() != 2)
      continue;
    BasicBlock *Latch = nullptr;
    BasicBlock *EntryPred = nullptr;
    for (BasicBlock *Pred : HubPreds) {
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Hub) {
        Latch = nullptr;
        EntryPred = nullptr;
        break;
      }
      if (pred_size(Pred) > 1)
        Latch = Pred;
      else
        EntryPred = Pred;
    }
    if (!Latch || !EntryPred || Latch == Hub || EntryPred == Hub)
      continue;

    SmallVector<BasicBlock *, 64> LatchPreds(predecessors(Latch));
    if (LatchPreds.empty())
      continue;
    DenseMap<BasicBlock *, Value *> NextStateForPred;
    bool Valid = true;
    for (BasicBlock *Pred : LatchPreds) {
      if (Pred == Hub)
        continue;
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch) {
        Valid = false;
        break;
      }
      StoreInst *SI = findDispatcherStateStore(Pred, SlotPtr, SW);
      if (!SI) {
        Valid = false;
        break;
      }
      NextStateForPred[Pred] = SI->getValueOperand();
    }
    if (!Valid)
      continue;

    IRBuilder<> EntryB(EntryPred->getTerminator());
    DenseMap<Value *, Value *> CloneCache;
    Value *EntrySlot = materializeHubValueOnPred(SlotPtr, Hub, EntryPred,
                                                 EntryB, CloneCache);
    if (!EntrySlot)
      continue;
    Value *EntryState = EntryB.CreateLoad(LI->getType(), EntrySlot,
                                          "native.dispatch.entry.state");

    PHINode *StatePhi = PHINode::Create(
        LI->getType(), 2, "native.dispatch.state",
        Hub->getFirstNonPHIIt());
    PHINode *NextPhi = PHINode::Create(
        LI->getType(), pred_size(Latch), "native.dispatch.next",
        Latch->getFirstNonPHIIt());
    StatePhi->addIncoming(EntryState, EntryPred);
    StatePhi->addIncoming(NextPhi, Latch);

    for (BasicBlock *Pred : LatchPreds) {
      Value *Next = Pred == Hub ? StatePhi : NextStateForPred.lookup(Pred);
      if (!Next) {
        Valid = false;
        break;
      }
      NextPhi->addIncoming(Next, Pred);
    }
    if (!Valid) {
      StatePhi->eraseFromParent();
      NextPhi->eraseFromParent();
      continue;
    }

    LI->replaceAllUsesWith(StatePhi);
    SW->setCondition(StatePhi);
    if (LI->use_empty())
      LI->eraseFromParent();
    ++Promoted;
    Changed = true;
  }
  return Promoted;
}

// A McSema module can export both `main` and a synthetic `start`.  Once the
// native entrypoint has been rewritten, keeping the latter makes the module
// expose two competing startup paths and retains a fake State/stack setup.
// Remove it only when the module has a real main and no IR user depends on
// the synthetic symbol; an externally consumed start-only module is left
// untouched and will be diagnosed by strict mode instead.
unsigned eraseDeadMcsemaEntrypoint(Module &M, bool &Changed) {
  Function *Main = M.getFunction("main");
  Function *Start = M.getFunction("start");
  if (!Main) {
    return 0;
  }

  unsigned Removed = 0;
  auto DropSyntheticConstantUsers = [&](Function *F) {
    if (!F)
      return;
    SmallVector<Use *, 16> ConstantUses;
    for (Use &U : F->uses())
      if (isa<Constant>(U.getUser()) &&
          !isa<GlobalValue>(U.getUser()))
        ConstantUses.push_back(&U);
    for (Use *U : ConstantUses) {
      U->set(Constant::getNullValue(U->get()->getType()));
      Changed = true;
    }
  };

  // The ELF image global embeds addresses of the synthetic startup symbols.
  // Once `main` is the sole entrypoint those constant references are dead
  // data, but they still count as LLVM users and would pin the functions.
  DropSyntheticConstantUsers(Start);
  DropSyntheticConstantUsers(M.getFunction(".init_proc"));
  if (Start && Start->use_empty() && !Start->isDeclaration()) {
    Start->eraseFromParent();
    Changed = true;
    ++Removed;
  }

  for (StringRef Name : {StringRef("start_wrapper"), StringRef(".init_proc")}) {
    if (Function *F = M.getFunction(Name)) {
      if (F->use_empty() && !F->isDeclaration()) {
        F->eraseFromParent();
        Changed = true;
        ++Removed;
      }
    }
  }

  // __mcsema_early_init is a McSema TLS guard with no application-visible
  // result.  Remove calls from surviving native callbacks, then let the
  // normal dead-function cleanup erase the definition if it becomes unused.
  if (Function *Init = M.getFunction("__mcsema_early_init")) {
    SmallVector<CallBase *, 16> Calls;
    for (User *U : Init->users()) {
      if (auto *CB = dyn_cast<CallBase>(U))
        Calls.push_back(CB);
    }
    for (CallBase *CB : Calls) {
      if (!CB->getType()->isVoidTy())
        continue;
      CB->eraseFromParent();
      Changed = true;
      ++Removed;
    }
    if (Init->use_empty() && !Init->isDeclaration()) {
      Init->eraseFromParent();
      Changed = true;
      ++Removed;
    }
  }
  return Removed;
}

} // namespace brighten_native_cleanup
