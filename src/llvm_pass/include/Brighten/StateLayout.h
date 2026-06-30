#pragma once

#include <array>
#include <cstdint>

namespace brighten {
namespace StateLayout {

inline constexpr uint64_t kRAX = 2216;
inline constexpr uint64_t kRBX = 2232;
inline constexpr uint64_t kRCX = 2248;
inline constexpr uint64_t kRDX = 2264;
inline constexpr uint64_t kRSI = 2280;
inline constexpr uint64_t kRDI = 2296;
inline constexpr uint64_t kRSP = 2312;
inline constexpr uint64_t kRBP = 2328;
inline constexpr uint64_t kR8 = 2344;
inline constexpr uint64_t kR9 = 2360;
inline constexpr uint64_t kR10 = 2376;
inline constexpr uint64_t kR11 = 2392;
inline constexpr uint64_t kR12 = 2408;
inline constexpr uint64_t kR13 = 2424;
inline constexpr uint64_t kR14 = 2440;
inline constexpr uint64_t kR15 = 2456;
inline constexpr uint64_t kRIP = 2472;

inline constexpr std::array<uint64_t, 6> kSysVParamOffsets = {
    kRDI, kRSI, kRDX, kRCX, kR8, kR9};

inline constexpr std::array<uint64_t, 6> kSysVCalleeSavedOffsets = {
    kRBX, kRBP, kR12, kR13, kR14, kR15};

inline constexpr std::array<uint64_t, 17> kSetjmpGPROffsets = {
    kRAX, kRCX, kRDX, kRBX, kRSP, kRBP, kRDI, kRSI, kR8,
    kR9,  kR10, kR11, kR12, kR13, kR14, kR15, kRIP};

}  // namespace StateLayout
}  // namespace brighten
