#ifndef BRIGHTEN_STATE_SLOT_LAYOUT_H
#define BRIGHTEN_STATE_SLOT_LAYOUT_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

#include <array>
#include <cstdint>
#include <optional>

namespace brighten_state_ssa {

/// Versioned x86-64 Remill/McSema State slots used by the flag passes.
///
/// These offsets are not inferred from a byte's value or from a nearby load.
/// The layout is accepted only when the module is compatible with x86-64 and
/// exposes a State object large enough to contain every slot.  Modules using a
/// different or opaque State layout are left unchanged rather than risking a
/// semantic rewrite of an ordinary byte field.
struct FlagSlot {
  llvm::StringLiteral Name;
  uint64_t Offset;
};

inline constexpr std::array<FlagSlot, 6> X86_64RemillFlagSlots = {{
    {"CF", 2065},
    {"PF", 2067},
    {"AF", 2069},
    {"ZF", 2071},
    {"SF", 2073},
    {"OF", 2077},
}};

struct DiscoveredFlagLayout {
  bool Valid = false;
  llvm::ArrayRef<FlagSlot> Slots;
  uint64_t StateBytes = 0;
  llvm::StringRef Evidence;
};

inline std::optional<uint64_t> SizedStateBytes(llvm::Module &M) {
  const llvm::DataLayout &DL = M.getDataLayout();
  if (llvm::GlobalVariable *GV = M.getGlobalVariable("__mcsema_reg_state")) {
    llvm::Type *Ty = GV->getValueType();
    if (Ty->isSized())
      return DL.getTypeAllocSize(Ty).getFixedValue();
  }

  // Some McSema configurations keep State local and expose only its identified
  // struct type.  Accept that form only when LLVM can compute its exact size.
  for (llvm::StructType *ST : M.getIdentifiedStructTypes()) {
    if (!ST || ST->isOpaque() || !ST->isSized())
      continue;
    llvm::StringRef Name = ST->getName();
    if (!Name.contains("State") && !Name.contains("ArchState"))
      continue;
    return DL.getTypeAllocSize(ST).getFixedValue();
  }
  return std::nullopt;
}

inline bool IsX86_64Module(const llvm::Module &M) {
  llvm::Triple TT(M.getTargetTriple());
  // Empty triples are common in focused pass fixtures.  In production the
  // exact State-size guard below remains mandatory.
  return M.getTargetTriple().empty() || TT.getArch() == llvm::Triple::x86_64;
}

inline DiscoveredFlagLayout DiscoverFlagSlots(llvm::Module &M) {
  DiscoveredFlagLayout Layout;
  if (!IsX86_64Module(M))
    return Layout;

  std::optional<uint64_t> Bytes = SizedStateBytes(M);
  if (!Bytes)
    return Layout;

  constexpr uint64_t RequiredBytes =
      X86_64RemillFlagSlots.back().Offset + 1;
  if (*Bytes < RequiredBytes)
    return Layout;

  Layout.Valid = true;
  Layout.Slots = X86_64RemillFlagSlots;
  Layout.StateBytes = *Bytes;
  Layout.Evidence = "x86_64-remill-state-v1";
  return Layout;
}

inline bool IsFlagOffset(const DiscoveredFlagLayout &Layout, uint64_t Offset) {
  if (!Layout.Valid)
    return false;
  for (const FlagSlot &Slot : Layout.Slots)
    if (Slot.Offset == Offset)
      return true;
  return false;
}

} // namespace brighten_state_ssa

#endif // BRIGHTEN_STATE_SLOT_LAYOUT_H
