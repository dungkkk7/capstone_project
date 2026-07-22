cmake_minimum_required(VERSION 3.16)
project(BrightenOLLVMDeobfPass LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(LLVM REQUIRED CONFIG)
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)
find_library(Z3_LIBRARY z3 REQUIRED)

add_llvm_pass_plugin(BrightenOLLVMDeobfPass
  src/main.cpp
  src/OLLVMDeobf.cpp
  src/OLLVMDeobfCommon.cpp
  src/OLLVMDeobfInstSub.cpp
  src/OLLVMDeobfSMTProof.cpp
  src/OLLVMDeobfStateCellPromotion.cpp
  src/OLLVMDeobfEquivalenceProofs.cpp
  src/OLLVMDeobfAffineBV.cpp
  src/OLLVMDeobfACBitVector.cpp
  src/OLLVMDeobfFlagPatternMatchers.cpp
  src/OLLVMDeobfFlagConeRewriting.cpp
  src/OLLVMDeobfStateExprEval.cpp
  src/OLLVMDeobfPointerAffine.cpp
  src/OLLVMDeobfTransitionEval.cpp
  src/OLLVMDeobfBranchDispatcher.cpp
  src/OLLVMDeobfDispatcherPlumbing.cpp
  src/OLLVMDeobfDispatcherCyclicStateFamily.cpp
  src/OLLVMDeobfDispatcherGeneralFunnelPlumbing.cpp
  src/OLLVMDeobfDispatcherFunnel.cpp
  src/OLLVMDeobfDispatcherPartitionedSSA.cpp
  src/OLLVMDeobfDispatcherPartitionedSSAPlumbing.cpp
  src/OLLVMDeobfDispatcherMultiIncomingSSA.cpp
  src/OLLVMDeobfDispatcherSSAPlumbing.cpp
  src/OLLVMDeobfDispatcherSSA.cpp
  src/OLLVMDeobfDispatcherMemoryJoin.cpp
  src/OLLVMDeobfReporting.cpp
)
target_link_libraries(BrightenOLLVMDeobfPass PRIVATE ${Z3_LIBRARY})
target_compile_options(BrightenOLLVMDeobfPass PRIVATE -fexceptions)
