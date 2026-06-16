cmake_minimum_required(VERSION 3.14)
project(DeobfuscateSymbolicCFFPass)

find_package(LLVM REQUIRED CONFIG)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

add_definitions(${LLVM_DEFINITIONS})
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions -funwind-tables")

add_library(DeobfuscateSymbolicCFFPass MODULE
  src/main.cpp
)

target_link_libraries(DeobfuscateSymbolicCFFPass
  PRIVATE
  LLVM
  z3
)

set_target_properties(DeobfuscateSymbolicCFFPass PROPERTIES
  PREFIX ""
  BUILD_RPATH "$ORIGIN/../lib:/usr/lib/llvm-21/lib"
)
