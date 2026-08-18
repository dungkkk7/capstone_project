#ifndef BRIGHTEN_STATE_SLICE_SEMANTICS_H
#define BRIGHTEN_STATE_SLICE_SEMANTICS_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"

#include <array>
#include <cstdint>
#include <optional>

namespace brighten_state_semantics {

/// Architectural write semantics for one byte slice of the lifted x86 State.
///
/// The old pass inferred this solely from access width.  That is incorrect on
/// x86-64: a write to EAX/ECX/... clears the upper half of the corresponding
/// 64-bit register, while AX/AL/AH preserve the untouched bits.
enum class WriteKind {
  Replace,
  Merge,
  ZeroExtend,
};

struct StateSlice {
  uint64_t BaseOffset = 0;
  unsigned BitOffset = 0;
  unsigned AccessBits = 0;
  unsigned CellBits = 0;
  WriteKind StoreKind = WriteKind::Replace;
  bool Architectural = false;
};

inline constexpr std::array<uint64_t, 16> GPR64Offsets = {
    2216, // RAX
    2232, // RBX
    2248, // RCX
    2264, // RDX
    2280, // RSI
    2296, // RDI
    2312, // RSP
    2328, // RBP
    2344, // R8
    2360, // R9
    2376, // R10
    2392, // R11
    2408, // R12
    2424, // R13
    2440, // R14
    2456, // R15
};

inline constexpr std::array<uint64_t, 8> XMMOffsets = {
    16, 80, 144, 208, 272, 336, 400, 464,
};

inline bool isGPR64Offset(uint64_t Offset) {
  return llvm::is_contained(GPR64Offsets, Offset);
}

inline std::optional<StateSlice> classifyArchitecturalSlice(
    uint64_t Offset, unsigned AccessBits) {
  if (!AccessBits || AccessBits % 8)
    return std::nullopt;

  for (uint64_t Base : GPR64Offsets) {
    if (Offset == Base &&
        (AccessBits == 8 || AccessBits == 16 || AccessBits == 32 ||
         AccessBits == 64)) {
      WriteKind Kind = WriteKind::Merge;
      if (AccessBits == 64)
        Kind = WriteKind::Replace;
      else if (AccessBits == 32)
        Kind = WriteKind::ZeroExtend;
      return StateSlice{Base, 0, AccessBits, 64, Kind, true};
    }

    // AH/BH/CH/DH are represented as an i8 access one byte into the same
    // 64-bit State cell.  Other sub-register aliases remain at offset Base.
    if (Offset == Base + 1 && AccessBits == 8)
      return StateSlice{Base, 8, 8, 64, WriteKind::Merge, true};
  }

  // McSema exposes overlapping aliases for the four 32-bit quarters and two
  // 64-bit halves of an XMM register.  Model all of them as one 128-bit cell.
  for (uint64_t Base : XMMOffsets) {
    if (Offset < Base || Offset >= Base + 16)
      continue;
    uint64_t ByteOffset = Offset - Base;
    unsigned BitOffset = static_cast<unsigned>(ByteOffset * 8);
    if (AccessBits > 128 - BitOffset)
      return std::nullopt;
    WriteKind Kind =
        BitOffset == 0 && AccessBits == 128 ? WriteKind::Replace
                                            : WriteKind::Merge;
    return StateSlice{Base, BitOffset, AccessBits, 128, Kind, true};
  }

  return std::nullopt;
}

inline StateSlice classifyFallbackSlice(uint64_t Offset, unsigned AccessBits,
                                        unsigned CellBits) {
  WriteKind Kind = AccessBits == CellBits ? WriteKind::Replace
                                          : WriteKind::Merge;
  return StateSlice{Offset, 0, AccessBits, CellBits, Kind, false};
}

} // namespace brighten_state_semantics

#endif // BRIGHTEN_STATE_SLICE_SEMANTICS_H
