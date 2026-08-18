cmake_minimum_required(VERSION 3.16)
project(BrightenNativeCleanupPass LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(LLVM REQUIRED CONFIG)
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

# 090 is a narrow final residual-elimination boundary. State/stack/ABI/object
# reconstruction must be completed by 030/040/050/060/070/080 before this
# point.
add_llvm_pass_plugin(BrightenNativeCleanupPass
  src/main.cpp
  src/NativeCleanupV2.cpp
)
