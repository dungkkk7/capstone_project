#ifndef BRIGHTEN_STATE_SLOT_LAYOUT_H
#define BRIGHTEN_STATE_SLOT_LAYOUT_H

/// StateSlotLayout.h — x86-64 State struct layout constants and discovery.
///
/// Provides GPR and flag slot tables for the Remill State struct, plus
/// helpers to discover flag offsets dynamically from IR global aliases
/// (e.g. @CF_2065_xxx).  If aliases are absent, falls back to hardcoded
/// Remill AVX512 layout offsets.

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"

#include <cstdint>
#include <optional>

namespace brighten_state_ssa {

// ===================================================================
// Flag slot descriptor
// ===================================================================

struct FlagSlotInfo {
  uint64_t Offset;
  const char *Name;   // "CF", "PF", "AF", "ZF", "SF", "OF"
};

// ===================================================================
// Hardcoded Remill x86-64 AVX512 layout (fallback)
// ===================================================================

static constexpr FlagSlotInfo kDefaultX86_64FlagSlots[] = {
    {2065, "CF"},
    {2067, "PF"},
    {2069, "AF"},
    {2071, "ZF"},
    {2073, "SF"},
    {2077, "OF"},
};

// ===================================================================
// Dynamic flag slot discovery from IR aliases
//
// McSema creates aliases like:
//   @CF_2065_e70f170 = alias i8, gep(%struct.State, ..., i32 2, i32 1)
//   @ZF_2071_e70f170 = alias i8, gep(%struct.State, ..., i32 2, i32 7)
//
// We parse these to extract flag name + offset, then verify they point
// to __mcsema_reg_state.
// ===================================================================

struct DiscoveredFlagLayout {
  llvm::DenseMap<uint64_t, const char *> OffsetToName;
  llvm::DenseSet<uint64_t> Offsets;
  bool Valid = false;
};

/// Try to discover flag offsets from global aliases in the module.
/// Falls back to hardcoded layout if no aliases found.
inline DiscoveredFlagLayout DiscoverFlagSlots(llvm::Module &M) {
  using namespace llvm;

  DiscoveredFlagLayout Result;
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");

  // Map prefix -> canonical name
  struct FlagPrefix {
    StringRef Prefix;
    const char *Name;
  };
  static const FlagPrefix kPrefixes[] = {
      {"CF_", "CF"}, {"PF_", "PF"}, {"AF_", "AF"},
      {"ZF_", "ZF"}, {"SF_", "SF"}, {"OF_", "OF"},
  };

  const DataLayout &DL = M.getDataLayout();
  unsigned Found = 0;

  for (GlobalAlias &GA : M.aliases()) {
    StringRef AName = GA.getName();
    const char *FlagName = nullptr;

    for (const auto &FP : kPrefixes) {
      if (AName.starts_with(FP.Prefix)) {
        FlagName = FP.Name;
        break;
      }
    }
    if (!FlagName) continue;

    // Resolve the alias target to get the offset
    Constant *Aliasee = GA.getAliasee();
    if (!Aliasee) continue;

    // Strip pointer casts, walk through GEP to compute offset
    APInt APOffset(64, 0);
    Value *Base = Aliasee->stripPointerCasts();

    if (auto *GEP = dyn_cast<GEPOperator>(Aliasee)) {
      if (!GEP->accumulateConstantOffset(DL, APOffset)) continue;
      Base = GEP->getPointerOperand()->stripPointerCasts();
    }

    // Verify it points to __mcsema_reg_state
    auto *TargetGV = dyn_cast<GlobalVariable>(Base);
    if (!TargetGV) continue;
    if (StateGV && TargetGV != StateGV &&
        TargetGV->getName() != "__mcsema_reg_state")
      continue;

    uint64_t Offset = APOffset.getZExtValue();
    if (!Result.OffsetToName.count(Offset)) {
      Result.OffsetToName[Offset] = FlagName;
      Result.Offsets.insert(Offset);
      Found++;
    }
  }

  // If we found at least CF+ZF+SF, consider discovery valid
  if (Found >= 3) {
    Result.Valid = true;
    return Result;
  }

  // Fallback to hardcoded layout
  Result.OffsetToName.clear();
  Result.Offsets.clear();
  for (const auto &FS : kDefaultX86_64FlagSlots) {
    Result.OffsetToName[FS.Offset] = FS.Name;
    Result.Offsets.insert(FS.Offset);
  }
  Result.Valid = true;
  return Result;
}

/// Check if an offset is a known flag slot (given discovered layout)
inline bool IsFlagOffset(const DiscoveredFlagLayout &Layout, uint64_t Offset) {
  return Layout.Offsets.count(Offset);
}

} // namespace brighten_state_ssa

#endif // BRIGHTEN_STATE_SLOT_LAYOUT_H
