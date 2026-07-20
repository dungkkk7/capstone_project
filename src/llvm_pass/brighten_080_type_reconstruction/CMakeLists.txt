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

add_llvm_pass_plugin(BrightenTypeReconstructionPass
  src/main.cpp
  src/ObjectDiscovery.cpp
  src/PointerOffsetAnalysis.cpp
  src/AccessEvidenceCollector.cpp
  src/TypeConstraintSolver.cpp
  src/ArrayInference.cpp
  src/StructInference.cpp
  src/RewritePlanner.cpp
  src/IRTypeRewriter.cpp
  src/ReconstructionVerifier.cpp
)
