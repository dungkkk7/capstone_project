cmake_minimum_required(VERSION 3.16)
project(BrightenTypeReconstructionPass LANGUAGES C CXX)

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

# 080 v2 keeps type reconstruction as evidence collection -> constraint solve
# -> rewrite -> verifier.  The former 65KB NativePointerProvenance.cpp is not
# production code; exact pointer representation cleanup is isolated below.
add_llvm_pass_plugin(BrightenTypeReconstructionPass
  main.cpp
  ObjectDiscovery.cpp
  PointerOffsetAnalysis.cpp
  AddressProvenanceV2.cpp
  AccessEvidenceCollector.cpp
  TypeConstraintSolver.cpp
  ArrayInference.cpp
  StructInference.cpp
  RewritePlanner.cpp
  IRTypeRewriter.cpp
  ReconstructionVerifier.cpp
)
