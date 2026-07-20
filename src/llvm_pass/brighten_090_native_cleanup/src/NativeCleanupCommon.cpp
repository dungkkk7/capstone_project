#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

bool isLiftedFunctionName(StringRef Name) {
  return Name.starts_with("__remill_") ||
         Name.starts_with("__mcsema_") ||
         Name.starts_with("__translate_guest_pointer") ||
         Name.contains(".remill") ||
         Name == "main_wrapper" || Name == "start_wrapper" ||
         (Name.starts_with("callback_") && Name.ends_with("_wrapper")) ||
         Name.starts_with("ext_");
}

bool isLiftedGlobalName(StringRef Name) {
  return Name.starts_with("seg_") || Name.starts_with("data_") ||
         Name.starts_with("native_data_") ||
         Name.starts_with("addr_carrier_cand_") ||
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

bool isStateType(Type *Ty) {
  auto *ST = dyn_cast_or_null<StructType>(Ty);
  if (!ST || !ST->hasName())
    return false;
  StringRef Name = ST->getName();
  return Name == "State" || Name.ends_with(".State") ||
         Name.contains("struct.State") || Name.contains("ArchState") ||
         Name.ends_with(".state_result");
}

bool isLiftedABI(Function &F) {
  if (F.arg_size() != 3 || !F.getReturnType()->isPointerTy())
    return false;
  auto It = F.arg_begin();
  Type *StateTy = (It++)->getType();
  Type *PCTy = (It++)->getType();
  Type *MemoryTy = (It++)->getType();
  return StateTy->isPointerTy() && PCTy->isIntegerTy(64) &&
         MemoryTy->isPointerTy();
}

bool isAddressArtifact(Value *V) {
  V = V ? V->stripPointerCasts() : nullptr;
  auto *GV = dyn_cast_or_null<GlobalValue>(V);
  if (!GV)
    return false;
  StringRef Name = GV->getName();
  return isLiftedGlobalName(Name) || Name.starts_with("data_") ||
         Name.starts_with("seg_") || Name.starts_with("sub_") ||
         Name.starts_with("ext_");
}

bool containsUndefined(Value *V) {
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

void addFinding(SmallVectorImpl<std::string> &Findings,
                       StringRef Category, StringRef Name) {
  std::string Finding;
  raw_string_ostream OS(Finding);
  OS << Category << ": " << Name;
  for (const std::string &Existing : Findings)
    if (Existing == Finding)
      return;
  Findings.push_back(Finding);
}

} // namespace brighten_native_cleanup
