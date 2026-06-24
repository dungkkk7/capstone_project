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
  src/RuleDefineRemillControlHelpers.cpp
  src/RuleSynthesizeMissingMain.cpp
  src/RuleResolveAliases.cpp
  src/RuleImplementExternCallBridge.cpp
  src/RuleFixCallbackFunctionPointerStores.cpp
  src/RuleRepairObfuscatedStackSubtractions.cpp
)
