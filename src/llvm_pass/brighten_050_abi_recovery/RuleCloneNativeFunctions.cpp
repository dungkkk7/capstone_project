#include "BrightenABIRecoveryPass.h"

#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static constexpr StringLiteral GuestBoundaryAttr =
    "brighten.preserve.guest.boundary";
static constexpr StringLiteral GuestBoundaryVersion = "v1";
static cl::opt<bool> EnableGuestBoundaryPreservation(
    "brighten-050-preserve-guest-boundary", cl::init(false),
    cl::desc("Experimental: preserve proven guest function inline boundaries"));

static bool hasGuestBoundaryMarker(const Function &F) {
  Attribute A = F.getFnAttribute(GuestBoundaryAttr);
  return A.isStringAttribute() && A.getValueAsString() == GuestBoundaryVersion;
}

static void preserveProvenGuestBoundary(const Function &Old, Function &New) {
  if (!EnableGuestBoundaryPreservation)
    return;
  // A function cannot be both a deliberate inline boundary and alwaysinline.
  // Refuse the preservation rather than resolving that contradictory source
  // contract by changing either attribute.
  if (Old.hasFnAttribute(Attribute::AlwaysInline) ||
      (!Old.hasFnAttribute(Attribute::NoInline) && !hasGuestBoundaryMarker(Old)))
    return;
  New.addFnAttr(Attribute::NoInline);
  New.addFnAttr(GuestBoundaryAttr, GuestBoundaryVersion);
}

static Function *CreateNativeShell(Module &M, FunctionABISummary &S) {
  SmallVector<Type *, 12> Params;
  Function &Old = *S.RemillFn;
  if (S.HiddenState) {
    Params.push_back(Old.getArg(0)->getType());
  }
  if (S.HiddenPC) {
    Params.push_back(Old.getArg(1)->getType());
  }
  if (S.HiddenMemory) {
    Params.push_back(Old.getArg(2)->getType());
  }
  for (const ABIArgInfo &Arg : S.Args) {
    Params.push_back(Arg.Ty);
  }

  FunctionType *FT = FunctionType::get(S.RetTy, Params, false);
  Function *Native =
      Function::Create(FT, GlobalValue::InternalLinkage,
                       (S.OriginalName + ".native"), M);
  Native->setCallingConv(Old.getCallingConv());
  Native->setDSOLocal(true);
  preserveProvenGuestBoundary(Old, *Native);
  return Native;
}

static void NameNativeArgs(FunctionABISummary &S) {
  unsigned I = 0;
  if (S.HiddenState) {
    S.NativeFn->getArg(I++)->setName("state");
  }
  if (S.HiddenPC) {
    S.NativeFn->getArg(I++)->setName("pc");
  }
  if (S.HiddenMemory) {
    S.NativeFn->getArg(I++)->setName("memory");
  }
  for (const ABIArgInfo &Arg : S.Args) {
    S.NativeFn->getArg(I++)->setName(("arg_" + GetRegisterName(Arg.Reg)).str());
  }
}

static void CloneBody(FunctionABISummary &S) {
  ValueToValueMapTy VMap;
  unsigned I = 0;
  if (S.HiddenState) {
    VMap[S.RemillFn->getArg(0)] = S.NativeFn->getArg(I++);
  }
  if (S.HiddenPC) {
    VMap[S.RemillFn->getArg(1)] = S.NativeFn->getArg(I++);
  }
  if (S.HiddenMemory) {
    VMap[S.RemillFn->getArg(2)] = S.NativeFn->getArg(I++);
  }

  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionBodyInto(*S.NativeFn, *S.RemillFn, VMap, RF_None, Returns);
}

bool BrightenABIRecoveryPass::CloneNativeFunctions(ABIRecoveryContext &Ctx) {
  bool Changed = false;
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (S->SkipNative || !S->Eligible) {
      continue;
    }

    Function *Old = S->RemillFn;
    S->OriginalName = Old->getName().str();
    S->OriginalLinkage = Old->getLinkage();
    Old->setName(S->OriginalName + ".remill");

    S->NativeFn = CreateNativeShell(Ctx.M, *S);
    NameNativeArgs(*S);
    CloneBody(*S);
    S->Cloned = true;
    Changed = true;

    errs() << "[brighten-abi] cloned: " << S->OriginalName << " -> "
           << S->NativeFn->getName() << "\n";
  }
  return Changed;
}

} // namespace brighten_abi
