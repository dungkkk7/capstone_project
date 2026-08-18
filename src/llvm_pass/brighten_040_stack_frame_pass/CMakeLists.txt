cmake_minimum_required(VERSION 3.16)
project(BrightenStackFramePass LANGUAGES C CXX)

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

# 040 v2 is one affine stack-provenance analysis.  The legacy 71KB recovery
# rule and 53KB post-State compactor are no longer part of the production
# plugin; both phase entrypoints share the same explicit proof domain.
add_llvm_pass_plugin(BrightenStackFramePass
  src/main.cpp
  src/StackFrameV2.cpp
)
