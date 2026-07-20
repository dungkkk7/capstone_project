cmake_minimum_required(VERSION 3.16)
project(BrightenGlobalDataRecoveryPass LANGUAGES C CXX)

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

add_llvm_pass_plugin(BrightenGlobalDataRecoveryPass
  src/main.cpp
  src/RuleDiscoverGuestSegments.cpp
  src/RuleFlattenSegmentBytes.cpp
  src/RuleBuildGuestAddressMap.cpp
  src/GenerateObjectCandidates.cpp
  src/ResolveObjectConflicts.cpp
  src/MaterializeRecoveredGlobals.cpp
  src/RuleRewriteGuestDataReferences.cpp
  src/RecoverJumpTableCFG.cpp
  src/RuleCleanupAndVerify.cpp
  src/RuleReport.cpp
)
