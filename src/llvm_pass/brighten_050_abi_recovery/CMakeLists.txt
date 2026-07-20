cmake_minimum_required(VERSION 3.16)
project(BrightenABIRecoveryPass LANGUAGES C CXX)

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

add_llvm_pass_plugin(BrightenABIRecoveryPass
  src/main.cpp
  src/ABIModel.cpp
  src/RegisterAccess.cpp
  src/ABIAnalysis.cpp
  src/RuleNormalizeRegisterAccesses.cpp
  src/RuleAnalyzeFunctionLiveIns.cpp
  src/RuleAnalyzeFunctionLiveOuts.cpp
  src/RuleAnalyzeCallsiteABI.cpp
  src/RuleInferFunctionABISignatures.cpp
  src/RuleCloneNativeFunctions.cpp
  src/RuleRewriteNativeFunctionBodies.cpp
  src/RuleRewriteKnownCallsites.cpp
  src/RuleCreateRemillWrappers.cpp
  src/RuleRewriteMainWrapper.cpp
  src/RuleCleanupDeadRemillABI.cpp
)
