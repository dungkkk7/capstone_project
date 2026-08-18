cmake_minimum_required(VERSION 3.20)
project(OwnObfuscator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(LLVM REQUIRED CONFIG)
if(NOT LLVM_PACKAGE_VERSION VERSION_GREATER_EQUAL "21" OR
   LLVM_PACKAGE_VERSION VERSION_GREATER_EQUAL "22")
  message(FATAL_ERROR "OwnObfuscator requires LLVM 21.x (found ${LLVM_PACKAGE_VERSION})")
endif()

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

add_llvm_pass_plugin(OwnObfuscator OwnObfuscator.cpp)
set_target_properties(OwnObfuscator PROPERTIES
  OUTPUT_NAME "OwnObfuscator"
  PREFIX "lib"
)
