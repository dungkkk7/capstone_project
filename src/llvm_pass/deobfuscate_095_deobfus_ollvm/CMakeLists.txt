cmake_minimum_required(VERSION 3.20)
project(Deobfuscate095 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(LLVM REQUIRED CONFIG)
if(NOT LLVM_PACKAGE_VERSION VERSION_GREATER_EQUAL "21" OR
   LLVM_PACKAGE_VERSION VERSION_GREATER_EQUAL "22")
  message(FATAL_ERROR "Deobfuscate095 requires LLVM 21.x (found ${LLVM_PACKAGE_VERSION})")
endif()
find_package(PkgConfig REQUIRED)
pkg_check_modules(Z3 REQUIRED IMPORTED_TARGET z3)

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# 095 v2 keeps candidate discovery and equivalence authority centralized in the
# bit-vector Z3 translation validator. CFG unflattening is owned by 020.
add_llvm_pass_plugin(Deobfuscate095
  src/Plugin.cpp
  src/Deobfuscate095.cpp
  src/Z3Prover.cpp
)

target_link_libraries(Deobfuscate095 PRIVATE PkgConfig::Z3)
set_target_properties(Deobfuscate095 PROPERTIES
  OUTPUT_NAME "095"
  PREFIX "lib"
)
