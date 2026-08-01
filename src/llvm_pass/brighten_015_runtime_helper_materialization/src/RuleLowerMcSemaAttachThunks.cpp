#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include <cctype>
#include <string>
#include <vector>

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalVariable.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

// A lowered McSema entry thunk invokes a lifted guest function directly.  At
// that boundary there is no longer an architectural caller that supplied an
// initial guest RSP, yet the guest prologue still owns real stack accesses.
// Keep this object local to the native entry invocation; it is not a recovered
// program frame and must not escape as a replacement for arbitrary guest
// memory.  The size is deliberately modest: it covers the ABI entry frame and
// ordinary nested call frames while retaining a normal host-stack failure mode
// for pathological unbounded guest recursion rather than silently remapping
// unknown addresses.
static constexpr uint64_t kEntryGuestStackBytes = 64 * 1024;

static std::optional<uint64_t> ParsePCFromInlineAsm(const Function &F) {
  for (const BasicBlock &BB : F) {
    for (const Instruction &I : BB) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (CI->isInlineAsm()) {
          auto *IA = cast<InlineAsm>(CI->getCalledOperand());
          StringRef Asm = IA->getAsmString();
          // McSema asm format: "pushq $0;pushq $$0x1080;jmpq *$1;"
          size_t Pos = Asm.find("$$0x");
          if (Pos != StringRef::npos) {
            StringRef Hex = Asm.drop_front(Pos + 4);
            size_t End = 0;
            while (End < Hex.size() && std::isxdigit(static_cast<unsigned char>(Hex[End]))) {
              ++End;
            }
            uint64_t PC = 0;
            if (!Hex.take_front(End).getAsInteger(16, PC)) {
              return PC;
            }
          }
        }
      }
    }
  }
  return std::nullopt;
}

static Function *FindWrapperOrSub(Module &M, uint64_t PC, StringRef Name) {
  std::string WrapperName = (Name + "_wrapper").str();
  if (Function *Wrap = M.getFunction(WrapperName)) {
    if (!Wrap->isDeclaration()) {
      return Wrap;
    }
  }
  std::string SubName = "sub_" + utohexstr(PC);
  for (Function &F : M) {
    if (!F.isDeclaration() && F.getName().starts_with(SubName)) {
      return &F;
    }
  }
  return nullptr;
}

struct EntryOwnerCandidate {
  Function *EntryThunk;
  Function *Owner;
  CallBase *OwnerCall;
};

static bool InitializerContainsOnlyOwnerPointerProvenance(
    const Constant *C, const Function &Owner, bool &SawOwner) {
  if (C == &Owner) {
    SawOwner = true;
    return true;
  }
  if (isa<GlobalValue>(C))
    return false;
  if (const auto *CE = dyn_cast<ConstantExpr>(C)) {
    const unsigned Opcode = CE->getOpcode();
    if (Opcode != Instruction::BitCast && Opcode != Instruction::AddrSpaceCast)
      return false;
  }
  for (const Use &U : C->operands()) {
    const auto *Operand = dyn_cast<Constant>(U.get());
    if (!Operand || !InitializerContainsOnlyOwnerPointerProvenance(
                        Operand, Owner, SawOwner))
      return false;
  }
  return true;
}

static bool IsInLLVMRetentionList(const Module &M, const GlobalVariable &GV) {
  for (StringRef Name : {"llvm.used", "llvm.compiler.used"}) {
    const GlobalVariable *List = M.getGlobalVariable(Name, true);
    if (!List || !List->hasInitializer())
      continue;
    for (const Use &U : List->getInitializer()->operands()) {
      const auto *Item = dyn_cast<Constant>(U.get());
      if (Item && Item->stripPointerCasts() == &GV)
        return true;
    }
  }
  return false;
}

static bool IsIgnorableDeadOwnerProvenanceGlobal(const Use &OwnerUse,
                                                 const Function &Owner,
                                                 const Module &M) {
  // A constant aggregate/cast can sit between @owner and its initializer
  // global.  It must be a single-use constant chain; otherwise this is an
  // address-taken use, not dead provenance.
  const User *User = OwnerUse.getUser();
  while (const auto *C = dyn_cast<Constant>(User)) {
    if (const auto *GV = dyn_cast<GlobalVariable>(C)) {
      if (!GV->hasLocalLinkage() || !GV->isConstant() || !GV->use_empty() ||
          GV->hasComdat() || GV->hasSection() ||
          IsInLLVMRetentionList(M, *GV) || !GV->hasInitializer())
        return false;
      for (const GlobalAlias &Alias : M.aliases())
        if (Alias.getAliasee() &&
            Alias.getAliasee()->stripPointerCasts() == GV)
          return false;
      bool SawOwner = false;
      return InitializerContainsOnlyOwnerPointerProvenance(
                 GV->getInitializer(), Owner, SawOwner) &&
             SawOwner;
    }
    if (!C->hasOneUse())
      return false;
    User = *C->user_begin();
  }
  return false;
}

// Schema: !brighten.entry_single_invocation = !{!"v1",
//                                              !"attach_direct_unique"}
// This is deliberately function metadata, not an LLVM function attribute.
// It communicates only the proven executable-entry ownership fact to pass 040;
// it grants no optimizer assumptions about calls, aliasing, or recursion.
static bool MarkProvenEntrySingleInvocation(Module &M,
                                            const EntryOwnerCandidate &C) {
  Function &Entry = *C.EntryThunk;
  Function &Owner = *C.Owner;
  if (Owner.isDeclaration() || !Owner.hasLocalLinkage() ||
      Entry.getMetadata("brighten.entry_single_invocation"))
    return false;

  // Entry may be externally visible through the native ABI, which is not an
  // in-module call-graph fact.  Any in-module use, however, makes this entry
  // callable as a callback/recursive/address-taken value and invalidates the
  // single-invocation capability.
  if (!Entry.use_empty())
    return false;
  for (GlobalAlias &Alias : M.aliases()) {
    if (Alias.getAliasee() &&
        Alias.getAliasee()->stripPointerCasts() == &Entry)
      return false;
  }

  // A local direct owner must have exactly the call just emitted by the
  // executable-entry thunk.  Every other use includes globals, aliases,
  // callback operands, indirect calls, recursive calls, and another in-module
  // caller, all of which make one-invocation ownership unprovable.
  unsigned DirectEntryCalls = 0;
  for (const Use &U : Owner.uses()) {
    auto *CB = dyn_cast<CallBase>(U.getUser());
    if (CB && CB == C.OwnerCall && CB->getFunction() == &Entry &&
        CB->getCalledOperand()->stripPointerCasts() == &Owner) {
      ++DirectEntryCalls;
      continue;
    }
    if (!IsIgnorableDeadOwnerProvenanceGlobal(U, Owner, M))
      return false;
  }
  if (DirectEntryCalls != 1)
    return false;

  for (GlobalAlias &Alias : M.aliases()) {
    if (Alias.getAliasee() &&
        Alias.getAliasee()->stripPointerCasts() == &Owner)
      return false;
  }

  LLVMContext &Ctx = M.getContext();
  Entry.setMetadata(
      "brighten.entry_single_invocation",
      MDNode::get(Ctx, {MDString::get(Ctx, "v1"),
                        MDString::get(Ctx, "attach_direct_unique")}));
  return true;
}

}  // namespace

bool BrightenRuntimeHelperPass::LowerMcSemaAttachThunks(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();
  GlobalVariable *RegState = M.getGlobalVariable("__mcsema_reg_state");
  if (!RegState) {
    errs() << "[brighten-mcsema-lower] Warning: __mcsema_reg_state not found\n";
  }

  // Offsets trong struct State:
  // RAX: 2216, RDI: 2296, RSI: 2280, RDX: 2264
  Type *I8 = Type::getInt8Ty(Ctx);
  Type *I64 = Type::getInt64Ty(Ctx);

  // 1. Lower main/start/.init_proc attach thunks
  std::vector<Function *> ThunkFunctions;
  SmallVector<EntryOwnerCandidate, 1> EntryOwnerCandidates;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    StringRef Name = F.getName();
    if (Name == "main" || Name == "start" || Name == ".init_proc" ||
        Name == "compar" || Name.starts_with("callback_sub_")) {
      // Check if it calls inline asm to attach_call
      if (ParsePCFromInlineAsm(F).has_value()) {
        ThunkFunctions.push_back(&F);
      }
    }
  }

  for (Function *F : ThunkFunctions) {
    auto PC = ParsePCFromInlineAsm(*F);
    if (!PC.has_value()) {
      continue;
    }

    StringRef Name = F->getName();
    Function *Target = FindWrapperOrSub(M, *PC, Name);
    if (!Target) {
      errs() << "[brighten-mcsema-lower] Target not found for thunk " << Name
             << " (PC: 0x" << utohexstr(*PC) << ")\n";
      continue;
    }

    // qsort's comparator is a McSema naked thunk with no C arguments, but
    // libc calls it as (const void *, const void *).  Preserve that boundary
    // before generic thunk lowering erases the only wrapper-to-body link.
    // The comparator body communicates its result through the canonical RAX
    // State slot, just like the original lifted call bridge.
    if (Name == "compar" && RegState &&
        HasMemoryThreadingSignature(*Target)) {
      Type *PtrTy = PointerType::getUnqual(Ctx);
      FunctionType *AdapterTy =
          FunctionType::get(Type::getInt32Ty(Ctx), {PtrTy, PtrTy}, false);
      Function *Adapter = Function::Create(
          AdapterTy, GlobalValue::InternalLinkage, "compar.native_callback", &M);
      Adapter->setCallingConv(F->getCallingConv());
      Adapter->setDSOLocal(true);
      Adapter->getArg(0)->setName("lhs");
      Adapter->getArg(1)->setName("rhs");
      BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Adapter);
      IRBuilder<> AB(Entry);
      AB.CreateAlignedStore(AB.CreatePtrToInt(Adapter->getArg(0), I64),
                            AB.CreateConstGEP1_64(I8, RegState, 2296), Align(8));
      AB.CreateAlignedStore(AB.CreatePtrToInt(Adapter->getArg(1), I64),
                            AB.CreateConstGEP1_64(I8, RegState, 2280), Align(8));
      SmallVector<Value *, 3> Args;
      FunctionType *TargetTy = Target->getFunctionType();
      if (TargetTy->getNumParams() != 3) {
        Adapter->eraseFromParent();
        continue;
      }
      Args.push_back(AB.CreateBitCast(RegState, TargetTy->getParamType(0)));
      Args.push_back(ConstantInt::get(TargetTy->getParamType(1), *PC));
      Args.push_back(ConstantPointerNull::get(
          cast<PointerType>(TargetTy->getParamType(2))));
      AB.CreateCall(TargetTy, Target, Args);
      Value *RAX = AB.CreateAlignedLoad(
          Type::getInt32Ty(Ctx), AB.CreateConstGEP1_64(I8, RegState, 2216),
          Align(8));
      AB.CreateRet(RAX);
      F->replaceAllUsesWith(Adapter);
      if (F->use_empty())
        F->eraseFromParent();
      Changed = true;
      errs() << "[brighten-mcsema-lower] Lowered qsort comparator thunk: "
             << Name << " -> " << Target->getName() << "\n";
      continue;
    }

    // Remove naked attribute so that LLVM allows using arguments and calls
    F->removeFnAttr(Attribute::Naked);

    // Clear old body
    F->deleteBody();
    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);
    IRBuilder<> B(Entry);

    if (RegState) {
      // Do not synthesize a fixed-size guest stack here.  Stack-frame pass 040
      // owns RSP/RBP recovery and creates native allocas from proven frame
      // regions.  A fabricated 8 MiB backing both hides that provenance and
      // can still be too small for a valid lifted access.

      // Setup fs_base.  This is a real host TLS value used by lifted stack
      // protector sequences until they are canonicalized.
      FunctionType *FsAsmFTy = FunctionType::get(I64, {}, false);
      InlineAsm *GetFsAsm = InlineAsm::get(FsAsmFTy, "movq %fs:0, $0", "=r", false);
      Value *FsVal = B.CreateCall(GetFsAsm, {});
      Value *FsPtr = B.CreateConstGEP1_64(I8, RegState, 2168);
      B.CreateAlignedStore(FsVal, FsPtr, Align(8));
    }

    if (Name == "main") {
      // setup args in State
      if (RegState) {
        // The original attach thunk enters with a live architectural stack.
        // Once we replace it with a host-ABI main, RSP would otherwise stay
        // zero and the first valid guest stack store dereferences -8.  Model
        // only that entry-stack boundary with a function-local object.  The
        // sentinel is the initial guest return address; it is distinct from
        // any recovered local frame and cannot provide provenance for other
        // guest addresses.
        ArrayType *EntryStackTy = ArrayType::get(I8, kEntryGuestStackBytes);
        AllocaInst *EntryStack = B.CreateAlloca(EntryStackTy, nullptr,
                                                 "entry_guest_stack");
        EntryStack->setAlignment(Align(16));
        // This is a transitional entry-boundary repair, never recovered
        // program storage.  Later native cleanup must either compact it into
        // a proven native entry frame or leave this marker for the final
        // native-contract reporter to reject.
        EntryStack->setMetadata(
            "brighten.entry_guest_stack.transitional",
            MDNode::get(Ctx, {MDString::get(
                                 Ctx, "seeded-guest-rsp-entry-boundary")}));
        Value *StackTop = B.CreateConstGEP2_64(
            EntryStackTy, EntryStack, 0, kEntryGuestStackBytes,
            "entry_guest_stack_top");
        Value *ReturnSlot = B.CreateInBoundsGEP(
            I8, StackTop, B.getInt64(-8), "entry_guest_return_slot");
        B.CreateAlignedStore(ConstantInt::get(I64, 0), ReturnSlot, Align(8));
        Value *RSPPtr = B.CreateConstGEP1_64(I8, RegState, 2312);
        B.CreateAlignedStore(B.CreatePtrToInt(ReturnSlot, I64), RSPPtr,
                             Align(8));

        // EDI (argc) - arg 0
        if (F->arg_size() > 0) {
          Value *Argc = F->getArg(0);
          Value *EDIPtr = B.CreateConstGEP1_64(I8, RegState, 2296);
          B.CreateAlignedStore(B.CreateZExtOrTrunc(Argc, I64), EDIPtr, Align(8));
        }
        // RSI (argv) - arg 1
        if (F->arg_size() > 1) {
          Value *Argv = F->getArg(1);
          Value *RSIPtr = B.CreateConstGEP1_64(I8, RegState, 2280);
          B.CreateAlignedStore(B.CreatePtrToInt(Argv, I64), RSIPtr, Align(8));
        }
        // RDX (envp) - arg 2
        if (F->arg_size() > 2) {
          Value *Envp = F->getArg(2);
          Value *RDXPtr = B.CreateConstGEP1_64(I8, RegState, 2264);
          B.CreateAlignedStore(B.CreatePtrToInt(Envp, I64), RDXPtr, Align(8));
        }
      }

      // Call target
      // Target có thể có signature (ptr, i64, ptr)->ptr hoặc signature của main
      CallInst *OwnerCall = nullptr;
      if (HasMemoryThreadingSignature(*Target)) {
        OwnerCall = B.CreateCall(
            Target->getFunctionType(), Target,
            {RegState ? B.CreateBitCast(RegState, Target->getFunctionType()->getParamType(0))
                      : ConstantPointerNull::get(PointerType::get(Ctx, 0)),
             B.getInt64(*PC),
             ConstantPointerNull::get(PointerType::get(Ctx, 0))});
      } else {
        // Call direct
        OwnerCall = B.CreateCall(Target);
      }
      EntryOwnerCandidates.push_back({F, Target, OwnerCall});

      // Read return value (RAX)
      if (RegState && !F->getReturnType()->isVoidTy()) {
        Value *RAXPtr = B.CreateConstGEP1_64(I8, RegState, 2216);
        Value *RAXVal = B.CreateAlignedLoad(I64, RAXPtr, Align(8));
        B.CreateRet(B.CreateZExtOrTrunc(RAXVal, F->getReturnType()));
      } else {
        B.CreateRet(ZeroValue(F->getReturnType()));
      }
    } else {
      // start, .init_proc hoặc callback
      if (HasMemoryThreadingSignature(*Target)) {
        B.CreateCall(Target->getFunctionType(), Target,
                     {RegState ? B.CreateBitCast(RegState, Target->getFunctionType()->getParamType(0))
                               : ConstantPointerNull::get(PointerType::get(Ctx, 0)),
                      B.getInt64(*PC),
                      ConstantPointerNull::get(PointerType::get(Ctx, 0))});
      } else {
        B.CreateCall(Target);
      }

      if (F->getReturnType()->isVoidTy()) {
        B.CreateRetVoid();
      } else {
        B.CreateRet(ZeroValue(F->getReturnType()));
      }
    }

    Changed = true;
    errs() << "[brighten-mcsema-lower] Lowered thunk: " << Name
           << " -> target: " << Target->getName() << "\n";
  }

  for (const EntryOwnerCandidate &Candidate : EntryOwnerCandidates) {
    if (MarkProvenEntrySingleInvocation(M, Candidate)) {
      Changed = true;
      errs() << "[brighten-mcsema-lower] Marked executable entry "
             << Candidate.EntryThunk->getName()
             << " with single-invocation capability\n";
    }
  }

  // 2. Define noop cho __mcsema_early_init nếu thiếu body
  if (Function *EarlyInit = M.getFunction("__mcsema_early_init")) {
    if (EarlyInit->isDeclaration()) {
      BasicBlock *BB = BasicBlock::Create(Ctx, "entry", EarlyInit);
      IRBuilder<> B(BB);
      B.CreateRetVoid();
      Changed = true;
      errs() << "[brighten-mcsema-lower] Defined noop for __mcsema_early_init\n";
    }
  }

  // 3. Remove callback attach thunk còn sót mà không dùng (use_empty)
  std::vector<Function *> DeadCallbacks;
  for (Function &F : M) {
    if (F.getName().starts_with("callback_sub_") && F.use_empty()) {
      DeadCallbacks.push_back(&F);
    }
  }
  for (Function *F : DeadCallbacks) {
    errs() << "[brighten-mcsema-lower] Erased unused callback thunk: " << F->getName() << "\n";
    F->eraseFromParent();
    Changed = true;
  }

  // 4. Xoá declaration của __mcsema_attach_call
  if (Function *AttachCall = M.getFunction("__mcsema_attach_call")) {
    if (AttachCall->use_empty()) {
      AttachCall->eraseFromParent();
      Changed = true;
      errs() << "[brighten-mcsema-lower] Erased unused __mcsema_attach_call declaration\n";
    } else {
      errs() << "[brighten-mcsema-lower] unresolved live __mcsema_attach_call preserved\n";
    }
  }

  // 5. Verify không còn unresolved __mcsema_* trừ global state
  std::vector<Function *> UnresolvedMcSema;
  for (Function &F : M) {
    if (F.isDeclaration() && F.getName().starts_with("__mcsema_")) {
      UnresolvedMcSema.push_back(&F);
    }
  }
  for (Function *F : UnresolvedMcSema)
    errs() << "[brighten-mcsema-lower] unresolved mcsema declaration preserved: "
           << F->getName() << "\n";

  return Changed;
}

}  // namespace brighten_runtime
