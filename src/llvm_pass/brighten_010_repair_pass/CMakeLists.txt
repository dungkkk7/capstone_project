cmake_minimum_required(VERSION 3.16)
project(BrightenRepairPass LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(LLVM REQUIRED CONFIG)

message(STATUS "Using LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "LLVMConfig.cmake: ${LLVM_DIR}")

include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

# Use LLVM's pass-plugin helper to avoid duplicate static linkage of LLVM
# command-line option registries when loading into `opt`.
add_llvm_pass_plugin(BrightenRepairPass
  src/main.cpp
  src/Helpers.cpp
  src/RuleStripPoisonDrivingFlags.cpp
  src/RuleStripPoisonDrivingAttributes.cpp
  src/RuleForwardMcSemaFlagLoads.cpp
  src/RulePruneDeadMcSemaFlagStores.cpp
  src/RulePruneDeadRipStores.cpp
  src/RuleForwardMcSemaStateLoads.cpp
  src/RuleForwardMcSemaGuestStackSlots.cpp
  src/RulePruneUnusedMcSemaStateStores.cpp
  src/RuleInlineMcSemaExternalWrappers.cpp
  src/RuleDefineRemillControlHelpers.cpp
  src/RuleGrowMcSemaSyntheticStack.cpp
  src/RuleHardenUnsafeScanf.cpp
  src/RuleCanonicalizeObfuscatedCompares.cpp
  src/RuleSanitizeDangerousStrlen.cpp
  src/RuleRepairRemillVarArgFPCalls.cpp
  src/RuleRepairRemillX87LibCalls.cpp
  src/RuleRepairMcSemaX87PseudoDoubleLoads.cpp
  src/RuleNormalizeJumpTableTargets.cpp
  src/RuleRecoverNoReturnFallthroughTargets.cpp
  src/RuleAddRemillEntryDispatchers.cpp
  src/RuleSynthesizeMissingMain.cpp
  src/RuleNormalizeRemillFunctionCalls.cpp
  src/RuleRepairMcSemaRawIndirectCallStack.cpp
  src/RuleGuardRawIndirectCalls.cpp
  src/RulePruneUnusedRemillMcSemaHelpers.cpp
)
