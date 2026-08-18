cmake_minimum_required(VERSION 3.20)
project(Deobfuscate095 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(LLVM REQUIRED CONFIG)
if(NOT LLVM_PACKAGE_VERSION VERSION_GREATER_EQUAL "21" OR
   LLVM_PACKAGE_VERSION VERSION_GREATER_EQUAL "22")
  message(FATAL_ERROR
          "Deobfuscate095 requires LLVM 21.x (found ${LLVM_PACKAGE_VERSION})")
endif()
find_package(PkgConfig REQUIRED)
pkg_check_modules(Z3 REQUIRED IMPORTED_TARGET z3)

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

# Fresh LLVM implementation of Chernobog's public 108-rule identity catalog.
# Deterministic matching owns the hot path; Z3 is linked for catalog
# certification and an explicitly bounded, default-off fallback only.
add_llvm_pass_plugin(Deobfuscate095
  src/Plugin.cpp
  src/Deobfuscate095.cpp
  src/Z3Fallback.cpp
  src/RuleReport.cpp
  src/RuleCatalog.cpp
  src/RuleCatalogAdd.cpp
  src/RuleCatalogAnd.cpp
  src/RuleCatalogOr.cpp
  src/RuleCatalogSub.cpp
  src/RuleCatalogXor.cpp
  src/RuleCatalogMisc.cpp
  src/RuleMatcher.cpp
  src/RuleMatcherSelfTest.cpp
  src/PredicateRules.cpp
  src/JumpRules.cpp
  src/ControlCleanup.cpp
  src/RuleEngine.cpp
  src/Z3Prover.cpp
)

# LLVM's plugin helper defaults to -fno-exceptions. The deterministic runtime
# matcher does not throw, but Z3's C++ wrapper uses exceptions at the optional
# fallback/catalog-certification boundary. Enable them only for this plugin.
target_compile_options(Deobfuscate095 PRIVATE -fexceptions)
target_link_libraries(Deobfuscate095 PRIVATE PkgConfig::Z3)
set_target_properties(Deobfuscate095 PROPERTIES
  OUTPUT_NAME "095"
  PREFIX "lib"
)
