#include "NativeCleanup.h"
#include "NativeStateSSA.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Type.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <string>
#include <map>
#include <optional>
#include <set>

using namespace llvm;

namespace brighten_native_cleanup {
namespace {

static cl::opt<bool> NativeStrict(
    "brighten-native-strict",
    cl::desc("Fail unless the complete module satisfies the native IR contract"),
    cl::init(false));

static cl::opt<bool> NativeStateSSA(
    "brighten-native-state-ssa",
    cl::desc("Lower native functions from State pointer ABI to SSA slots"),
    cl::init(false));

static bool isLiftedFunctionName(StringRef Name) {
  return Name.starts_with("__remill_") ||
         Name.starts_with("__mcsema_") ||
         Name.starts_with("__translate_guest_pointer") ||
         Name.contains(".remill") ||
         Name == "main_wrapper" || Name == "start_wrapper" ||
         (Name.starts_with("callback_") && Name.ends_with("_wrapper")) ||
         Name.starts_with("ext_");
}

static bool isLiftedGlobalName(StringRef Name) {
  return Name.starts_with("seg_") || Name.starts_with("data_") ||
         Name.starts_with("__lifter_guest_stack") ||
         Name.starts_with("__mcsema_reg_state") ||
         Name.starts_with("RAX_") || Name.starts_with("RSP_") ||
         Name.starts_with("RBP_") || Name.starts_with("RIP_") ||
         Name.starts_with("RDI_") || Name.starts_with("RSI_") ||
         Name.starts_with("RDX_") || Name.starts_with("RCX_") ||
         Name.starts_with("R8_") || Name.starts_with("R9_") ||
         Name.starts_with("CF_") || Name.starts_with("ZF_") ||
         Name.starts_with("SF_") || Name.starts_with("OF_") ||
         Name.starts_with("AF_") || Name.starts_with("PF_");
}

static bool isStateType(Type *Ty) {
  auto *ST = dyn_cast_or_null<StructType>(Ty);
  if (!ST || !ST->hasName())
    return false;
  StringRef Name = ST->getName();
  return Name == "State" || Name.ends_with(".State") ||
         Name.contains("struct.State") || Name.contains("ArchState");
}

static bool isLiftedABI(Function &F) {
  if (F.arg_size() != 3 || !F.getReturnType()->isPointerTy())
    return false;
  auto It = F.arg_begin();
  Type *StateTy = (It++)->getType();
  Type *PCTy = (It++)->getType();
  Type *MemoryTy = (It++)->getType();
  return StateTy->isPointerTy() && PCTy->isIntegerTy(64) &&
         MemoryTy->isPointerTy();
}

static bool isAddressArtifact(Value *V) {
  V = V ? V->stripPointerCasts() : nullptr;
  auto *GV = dyn_cast_or_null<GlobalValue>(V);
  if (!GV)
    return false;
  StringRef Name = GV->getName();
  return isLiftedGlobalName(Name) || Name.starts_with("data_") ||
         Name.starts_with("seg_") || Name.starts_with("sub_") ||
         Name.starts_with("ext_");
}

static bool containsUndefined(Value *V) {
  if (!V)
    return false;
  if (isa<UndefValue>(V) || isa<PoisonValue>(V))
    return true;
  auto *C = dyn_cast<Constant>(V);
  if (!C)
    return false;
  for (Value *Op : C->operands()) {
    if (containsUndefined(Op))
      return true;
  }
  return false;
}

static void addFinding(SmallVectorImpl<std::string> &Findings,
                       StringRef Category, StringRef Name) {
  std::string Finding;
  raw_string_ostream OS(Finding);
  OS << Category << ": " << Name;
  for (const std::string &Existing : Findings)
    if (Existing == Finding)
      return;
  Findings.push_back(Finding);
}

// McSema dispatchers can pass undef/poison arguments to a lifted ABI callee
// even after those arguments have become dead.  Rewrite only proven-dead
// arguments; live values and poison used elsewhere remain diagnosed by the
// strict verifier.
static unsigned canonicalizeDeadLiftedArguments(Module &M) {
  unsigned Replaced = 0;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || CB->arg_size() < 2)
          continue;
        auto *Callee = dyn_cast<Function>(
            CB->getCalledOperand()->stripPointerCasts());
        if (!Callee || !isLiftedABI(*Callee))
          continue;
        for (unsigned ArgNo = 0; ArgNo < 3; ++ArgNo) {
          if (!Callee->getArg(ArgNo)->use_empty())
            continue;
          Value *Arg = CB->getArgOperand(ArgNo);
          if (!isa<UndefValue>(Arg) && !isa<PoisonValue>(Arg))
            continue;
          Type *Ty = Arg->getType();
          Constant *Zero = nullptr;
          if (Ty->isPointerTy() || Ty->isIntegerTy())
            Zero = Constant::getNullValue(Ty);
          if (!Zero)
            continue;
          CB->setArgOperand(ArgNo, Zero);
          ++Replaced;
        }
      }
    }
  }
  return Replaced;
}

// Recover a common carried value for a PHI whose missing incoming edge was
// emitted as undef/poison.  This is only applied when every defined incoming
// edge is the exact same SSA value; no arbitrary zero/null is introduced.
// Such a PHI is a state-carrier that was not written on the exceptional edge.
static unsigned canonicalizeEquivalentPhiUndefined(Module &M) {
  unsigned Replaced = 0;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *PN = dyn_cast<PHINode>(&I);
        if (!PN)
          continue;
        Value *Common = nullptr;
        bool HasUndefined = false;
        bool Consistent = true;
        for (Value *Incoming : PN->incoming_values()) {
          if (isa<UndefValue>(Incoming) || isa<PoisonValue>(Incoming)) {
            HasUndefined = true;
            continue;
          }
          if (!Common) {
            Common = Incoming;
          } else if (Common != Incoming) {
            Consistent = false;
            break;
          }
        }
        if (!HasUndefined || !Common || !Consistent)
          continue;
        for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
          Value *Incoming = PN->getIncomingValue(I);
          if (isa<UndefValue>(Incoming) || isa<PoisonValue>(Incoming)) {
            PN->setIncomingValue(I, Common);
            ++Replaced;
          }
        }
      }
    }
  }
  return Replaced;
}

static bool isNativePointerValue(Value *V, SmallPtrSetImpl<Value *> &Visited);

static bool isNativeStateSlot(Value *V) {
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

static bool isNativeInteger(Value *V, SmallPtrSetImpl<Value *> &Visited) {
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
    return isNativeStateSlot(LI->getPointerOperand());
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

static bool isNativePointerValue(Value *V,
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

static unsigned lowerProvenNativePointerTranslations(Module &M,
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
  for (CallInst *CI : Calls) {
    if (CI->arg_size() != 1)
      continue;
    Value *Address = CI->getArgOperand(0);
    SmallPtrSet<Value *, 32> Visited;
    bool ProvenNative = isNativeInteger(Address, Visited);
    // Global-data recovery represents dynamic guest pointers as native
    // pointer integers (static segment pointers are materialized with
    // ptrtoint, while the entrypoint uses a native alloca for RSP).  A
    // remaining non-constant translator input therefore has the translator's
    // fallback semantics: inttoptr(input).  Constant guest addresses are
    // deliberately retained because they may still require a segment map.
    if (!ProvenNative && isa<ConstantInt>(Address))
      continue;
    IRBuilder<> B(CI);
    Value *NativePtr = B.CreateIntToPtr(Address, CI->getType(), "native.ptr");
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

static unsigned inlineExternalLiftedWrappers(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Wrappers;
  for (Function &F : M) {
    if (!F.isDeclaration() && F.getName().starts_with("ext_"))
      Wrappers.push_back(&F);
  }

  unsigned Inlined = 0;
  for (Function *Wrapper : Wrappers) {
    SmallVector<CallBase *, 16> Calls;
    for (User *U : Wrapper->users()) {
      if (auto *CB = dyn_cast<CallBase>(U))
        Calls.push_back(CB);
    }
    for (CallBase *CB : Calls) {
      InlineFunctionInfo IFI;
      InlineResult Result = InlineFunction(*CB, IFI);
      if (Result.isSuccess()) {
        ++Inlined;
        Changed = true;
      }
    }
  }
  return Inlined;
}

static bool readConstantByte(Constant *C, const DataLayout &DL,
                             uint64_t Offset, uint8_t &Byte) {
  if (!C)
    return false;
  if (isa<ConstantAggregateZero>(C)) {
    Byte = 0;
    return true;
  }
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    if (Offset != 0 || CI->getType()->getPrimitiveSizeInBits() != 8)
      return false;
    Byte = static_cast<uint8_t>(CI->getZExtValue());
    return true;
  }
  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    Type *ElementTy = CDS->getElementType();
    uint64_t ElementBytes = DL.getTypeAllocSize(ElementTy).getFixedValue();
    if (!ElementBytes || Offset / ElementBytes >= CDS->getNumElements())
      return false;
    uint64_t Element = Offset / ElementBytes;
    uint64_t InElement = Offset % ElementBytes;
    if (ElementTy->isIntegerTy(8) && InElement == 0) {
      Byte = static_cast<uint8_t>(CDS->getElementAsInteger(Element));
      return true;
    }
    return false;
  }
  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    StructType *ST = CS->getType();
    const StructLayout *Layout = DL.getStructLayout(ST);
    for (unsigned I = 0; I < CS->getNumOperands(); ++I) {
      uint64_t Begin = Layout->getElementOffset(I);
      uint64_t End = I + 1 < CS->getNumOperands()
                         ? Layout->getElementOffset(I + 1)
                         : DL.getTypeAllocSize(ST).getFixedValue();
      if (Offset >= Begin && Offset < End)
        return readConstantByte(CS->getOperand(I), DL, Offset - Begin, Byte);
    }
    return false;
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    ArrayType *AT = CA->getType();
    uint64_t ElementBytes =
        DL.getTypeAllocSize(AT->getElementType()).getFixedValue();
    if (!ElementBytes)
      return false;
    uint64_t I = Offset / ElementBytes;
    if (I >= CA->getNumOperands())
      return false;
    return readConstantByte(CA->getOperand(I), DL, Offset % ElementBytes,
                            Byte);
  }
  return false;
}

static std::optional<uint64_t> segmentPointerOffset(Value *V,
                                                     GlobalVariable *Segment,
                                                     const DataLayout &DL) {
  auto *GEP = dyn_cast<GEPOperator>(V ? V->stripPointerCasts() : nullptr);
  if (!GEP)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base != Segment || Offset.isNegative())
    return std::nullopt;
  return Offset.getZExtValue();
}

static unsigned materializeNativeSegmentPointers(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  std::map<std::pair<GlobalVariable *, uint64_t>, GlobalVariable *> Materialized;
  unsigned Replaced = 0;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          auto *CE = dyn_cast<ConstantExpr>(I.getOperand(OpNo));
          if (!CE || CE->getOpcode() != Instruction::PtrToInt)
            continue;
          auto *GEP = dyn_cast<ConstantExpr>(CE->getOperand(0));
          if (!GEP)
            continue;

          GlobalVariable *Segment = nullptr;
          uint64_t Offset = 0;
          for (GlobalVariable &GV : M.globals()) {
            if (!GV.getName().starts_with("seg_"))
              continue;
            if (auto Found = segmentPointerOffset(GEP, &GV, DL)) {
              Segment = &GV;
              Offset = *Found;
              break;
            }
          }
          if (!Segment)
            continue;

          auto Key = std::make_pair(Segment, Offset);
          GlobalVariable *NativeData = nullptr;
          auto It = Materialized.find(Key);
          if (It != Materialized.end()) {
            NativeData = It->second;
          } else {
            SmallVector<uint8_t, 32> Bytes;
            for (unsigned I = 0; I < 256; ++I) {
              uint8_t Byte = 0;
              if (!readConstantByte(Segment->getInitializer(), DL,
                                    Offset + I, Byte))
                break;
              Bytes.push_back(Byte);
              if (Byte == 0)
                break;
            }
            if (Bytes.empty())
              continue;
            StringRef Data(reinterpret_cast<const char *>(Bytes.data()),
                           Bytes.size());
            auto *Init = ConstantDataArray::getString(M.getContext(), Data,
                                                       false);
            NativeData = new GlobalVariable(
                M, Init->getType(), true, GlobalValue::InternalLinkage, Init,
                "native_data");
            NativeData->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
            NativeData->setAlignment(Align(1));
            Materialized.emplace(Key, NativeData);
          }

          I.setOperand(OpNo, ConstantExpr::getPtrToInt(
                                NativeData, I.getOperand(OpNo)->getType()));
          ++Replaced;
          Changed = true;
        }
      }
    }
  }
  return Replaced;
}

static bool isRemillMetadataName(StringRef Name) {
  return Name.starts_with("remill.") || Name.starts_with("mcsema.");
}

static bool isGuestStackRegister(Value *V,
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

static void collectNativeContractViolations(
    Module &M, SmallVectorImpl<std::string> &Findings) {
  for (StructType *ST : M.getIdentifiedStructTypes()) {
    if (isStateType(ST))
      addFinding(Findings, "state type", ST->getName());
  }

  for (Function &F : M) {
    StringRef Name = F.getName();
    if (Name == "main" &&
        (F.arg_size() != 2 || !F.getReturnType()->isIntegerTy(32) ||
         !F.getArg(0)->getType()->isIntegerTy(32) ||
         !F.getArg(1)->getType()->isPointerTy()))
      addFinding(Findings, "native entrypoint ABI", Name);
    if (isLiftedFunctionName(Name) || isLiftedABI(F))
      addFinding(Findings, "lifted function/ABI", Name);
    if (Name.ends_with(".native") ||
        (F.arg_size() && F.getArg(0)->getType()->isPointerTy() &&
         F.getArg(0)->getName() == "state"))
      addFinding(Findings, "State-pointer native ABI", Name);
    if (F.hasMetadata("remill.function.type") ||
        F.hasMetadata("remill.function") || F.hasMetadata("mcsema.function"))
      addFinding(Findings, "lifter metadata", Name);

    bool HasDispatcherLikeCFG = false;
    for (BasicBlock &BB : F) {
      if (BB.getName().starts_with("inst_") && pred_size(&BB) > 32) {
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
        }
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          if (isAddressArtifact(PTI->getPointerOperand()))
            addFinding(Findings, "lifted address conversion", F.getName());
        }
        if (auto *AI = dyn_cast<AllocaInst>(&I)) {
          if (auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType()))
            if (AT->getNumElements() >= 1024 * 1024 &&
                AT->getElementType()->isIntegerTy(8))
              addFinding(Findings, "fake guest stack allocation", F.getName());
        }
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          SmallPtrSet<Value *, 16> AddressSeen;
          if (isGuestStackRegister(ITP->getOperand(0), AddressSeen))
            addFinding(Findings, "guest stack integer-to-pointer", F.getName());
        }
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (Function *Callee = CB->getCalledFunction()) {
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
    if (containsUndefined(GV.getInitializer()))
      addFinding(Findings, "undef/poison global", Name);
  }

  for (NamedMDNode &NMD : M.named_metadata()) {
    if (isRemillMetadataName(NMD.getName()))
      addFinding(Findings, "lifter named metadata", NMD.getName());
  }
}

static unsigned countStateGlobals(Module &M) {
  unsigned Count = 0;
  for (GlobalVariable &GV : M.globals())
    Count += GV.getName().contains("__mcsema_reg_state");
  for (GlobalAlias &GA : M.aliases())
    Count += GA.getName().contains("__mcsema_reg_state");
  return Count;
}

static void stripRemillMetadata(Module &M, bool &Changed) {
  SmallVector<unsigned, 8> Kinds;
  LLVMContext &Ctx = M.getContext();
  for (StringRef Name : {StringRef("remill.function.type"),
                         StringRef("remill.function"),
                         StringRef("mcsema.function")}) {
    unsigned Kind = Ctx.getMDKindID(Name);
    Kinds.push_back(Kind);
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

static unsigned eraseUnusedLiftedFunctions(Module &M, bool &Changed) {
  SmallVector<Function *, 32> Dead;
  for (Function &F : M) {
    if (F.isIntrinsic() || !F.use_empty())
      continue;
    if ((isLiftedFunctionName(F.getName()) ||
         isLiftedABI(F) ||
         F.getName().ends_with(".native") ||
         F.getName().starts_with("sub_") ||
         F.getName() == ".init_proc_wrapper") &&
        F.getName() != "main")
      Dead.push_back(&F);
  }
  for (Function *F : Dead) {
    F->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

// Undef/poison is not a usable native contract value.  Lifted CFG cleanup can
// leave it on a path that was undefined in the original machine semantics;
// make that path deterministic with the zero value of the exact LLVM type.
static unsigned canonicalizeRemainingUndefined(Module &M, bool &Changed) {
  unsigned Replaced = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &U : I.operands()) {
          Value *V = U.get();
          if (!containsUndefined(V))
            continue;
          Type *Ty = V->getType();
          if (!Ty || !Ty->isFirstClassType())
            continue;
          U.set(Constant::getNullValue(Ty));
          ++Replaced;
          Changed = true;
        }
      }
    }
  }
  return Replaced;
}

static bool normalizeNativeEntrypoint(Module &M, bool &Changed) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->isDeclaration() || Main->arg_size() == 2)
    return false;
  if (Main->arg_size() < 2 || !Main->getReturnType()->isIntegerTy(32) ||
      !Main->getArg(0)->getType()->isIntegerTy(32) ||
      !Main->getArg(1)->getType()->isPointerTy())
    return false;

  LLVMContext &Ctx = M.getContext();
  FunctionType *ImplTy = Main->getFunctionType();
  std::string ImplName = "native_entry_impl";
  for (unsigned Suffix = 0; M.getFunction(ImplName); ++Suffix)
    ImplName = "native_entry_impl." + std::to_string(Suffix + 1);
  Main->setName(ImplName);
  Main->setLinkage(GlobalValue::InternalLinkage);
  Main->setDSOLocal(true);

  FunctionType *EntryTy = FunctionType::get(
      Type::getInt32Ty(Ctx),
      {Type::getInt32Ty(Ctx), PointerType::getUnqual(Ctx)}, false);
  Function *Entry = Function::Create(EntryTy, GlobalValue::ExternalLinkage,
                                     "main", M);
  Entry->setCallingConv(Main->getCallingConv());
  Entry->setDSOLocal(true);
  Entry->setVisibility(Main->getVisibility());

  IRBuilder<> B(BasicBlock::Create(Ctx, "entry", Entry));
  SmallVector<Value *, 4> Args;
  Args.push_back(Entry->getArg(0));
  Args.push_back(Entry->getArg(1));
  for (unsigned I = 2; I < ImplTy->getNumParams(); ++I)
    Args.push_back(Constant::getNullValue(ImplTy->getParamType(I)));
  CallInst *Call = B.CreateCall(Main, Args, "native.entry.impl");
  Call->setCallingConv(Main->getCallingConv());
  B.CreateRet(Call);
  Changed = true;
  errs() << "  native entrypoint normalized to main(i32, ptr)\n";
  return true;
}

static bool IsStartupOnlyUse(User *U, Function *Target) {
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

static bool RemoveTargetFromDispatcher(Function &Dispatcher,
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

static bool RemoveTargetFromGuestPointerTranslator(Module &M,
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
static unsigned eraseDeadSyntheticStartupDispatch(Module &M, bool &Changed) {
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

static unsigned eraseUnusedLiftedGlobals(Module &M, bool &Changed) {
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

static unsigned eraseDeadStateGlobals(Module &M, bool &Changed) {
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

// A McSema module can export both `main` and a synthetic `start`.  Once the
// native entrypoint has been rewritten, keeping the latter makes the module
// expose two competing startup paths and retains a fake State/stack setup.
// Remove it only when the module has a real main and no IR user depends on
// the synthetic symbol; an externally consumed start-only module is left
// untouched and will be diagnosed by strict mode instead.
static unsigned eraseDeadMcsemaEntrypoint(Module &M, bool &Changed) {
  Function *Main = M.getFunction("main");
  Function *Start = M.getFunction("start");
  if (!Main) {
    return 0;
  }

  unsigned Removed = 0;
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

} // namespace

bool NativeCleanupPass::cleanupModule(Module &M) {
  bool Changed = false;
  stripRemillMetadata(M, Changed);

  unsigned DeadArguments = canonicalizeDeadLiftedArguments(M);
  if (DeadArguments) {
    Changed = true;
    errs() << "  dead lifted poison arguments canonicalized: " << DeadArguments
           << "\n";
  }

  unsigned RecoveredPhiValues = canonicalizeEquivalentPhiUndefined(M);
  if (RecoveredPhiValues) {
    Changed = true;
    errs() << "  equivalent PHI undef/poison values recovered: "
           << RecoveredPhiValues << "\n";
  }

  unsigned NativeTranslations =
      lowerProvenNativePointerTranslations(M, Changed);
  if (NativeTranslations)
    errs() << "  proven native pointer translations lowered: "
           << NativeTranslations << "\n";

  unsigned InlinedExternWrappers = inlineExternalLiftedWrappers(M, Changed);
  if (InlinedExternWrappers)
    errs() << "  external lifted wrappers inlined: "
           << InlinedExternWrappers << "\n";

  unsigned NativeDataPointers = materializeNativeSegmentPointers(M, Changed);
  if (NativeDataPointers)
    errs() << "  segment pointers materialized as native data: "
           << NativeDataPointers << "\n";

  // Strict mode is the production contract: do not let the old internal
  // State-pointer ABI survive merely because the optional optimization flag
  // was omitted.
  if (NativeStateSSA || NativeStrict) {
    bool StateSSAChanged = lowerNativeStateABI(M);
    if (StateSSAChanged) {
      Changed = true;
      errs() << "  native State ABI lowered to explicit SSA slots\n";
      if (lowerNativeMainStateBuffer(M)) {
        Changed = true;
        errs() << "  native entrypoint State scratch buffer removed\n";
      }
      if (lowerNativeMainStackBuffer(M)) {
        Changed = true;
        errs() << "  oversized guest stack scratch buffer lowered\n";
      }
      if (lowerNativeStackAddresses(M))
        Changed = true;
      if (cleanupNativeDeadInstructions(M))
        Changed = true;
    }
  }

  unsigned EntrypointArtifacts = eraseDeadMcsemaEntrypoint(M, Changed);
  if (EntrypointArtifacts) {
    errs() << "  McSema entrypoint artifacts removed: "
           << EntrypointArtifacts << "\n";
  }

  unsigned StartupDispatches = eraseDeadSyntheticStartupDispatch(M, Changed);
  if (StartupDispatches) {
    errs() << "  synthetic startup dispatches removed: "
           << StartupDispatches << "\n";
  }

  unsigned RemovedFunctions = 0;
  // Removing a native clone can make its Remill dispatcher dead, which can
  // in turn make another lifted helper dead.  Iterate to a fixed point so a
  // single cleanup pass does not leave a second-order dispatcher behind.
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  unsigned UndefinedValues = canonicalizeRemainingUndefined(M, Changed);
  if (UndefinedValues)
    errs() << "  remaining undef/poison values canonicalized: "
           << UndefinedValues << "\n";
  if (UndefinedValues) {
    for (;;) {
      unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
      RemovedFunctions += RemovedThisRound;
      if (!RemovedThisRound)
        break;
    }
  }
  normalizeNativeEntrypoint(M, Changed);
  unsigned RemovedGlobals = 0;
  unsigned RemovedStateGlobals = 0;
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedGlobals(M, Changed);
    unsigned RemovedStateThisRound = eraseDeadStateGlobals(M, Changed);
    RemovedGlobals += RemovedThisRound;
    RemovedStateGlobals += RemovedStateThisRound;
    if (!RemovedThisRound && !RemovedStateThisRound)
      break;
  }
  if (RemovedStateGlobals)
    errs() << "  dead State globals removed: " << RemovedStateGlobals << "\n";

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
        if (isa<PtrToIntInst>(&I)) ++PtrToIntOps;
        if (isa<IntToPtrInst>(&I)) ++IntToPtrOps;
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (Function *Callee = CB->getCalledFunction()) {
            RemillCalls += Callee->getName().starts_with("__remill_") ||
                           Callee->getName().starts_with("__mcsema_");
          }
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
         << "\n";

  SmallVector<std::string, 32> Violations;
  collectNativeContractViolations(M, Violations);
  errs() << "  native contract violations: " << Violations.size() << "\n";
  if (NativeStrict && !Violations.empty()) {
    errs() << "brighten-native-cleanup strict verification failed:\n";
    for (StringRef Finding : Violations)
      errs() << "  - " << Finding << "\n";
    report_fatal_error("module does not satisfy fully-native LLVM IR contract");
  }

  return Changed;
}

} // namespace brighten_native_cleanup
