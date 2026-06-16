# Copyright (c) 2020 Trail of Bits, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.2)

if(NOT TARGET remill)
  if(WIN32)
    set(REMILL_LIBRARY_LOCATION "/opt/trailofbits/remill/remill/lib/remill.lib")
    set(REMILL_INCLUDE_LOCATION "/opt/trailofbits/remill/remill/include")
  else()
    set(REMILL_LIBRARY_LOCATION "/opt/trailofbits/remill/lib/libremill.a")
    set(REMILL_INCLUDE_LOCATION "/opt/trailofbits/remill/include")
  endif()
  
  # For Linux builds, group LLVM libraries into a single group
  # that avoids frustrating library ordering issues.
  if(UNIX AND NOT APPLE)
    set(LINKER_START_GROUP "-Wl,--start-group")
    set(LINKER_END_GROUP "-Wl,--end-group")
  else()
    set(LINKER_START_GROUP "")
    set(LINKER_END_GROUP "")
  endif()

  if(NOT "x/opt/trailofbits/librariesx" STREQUAL "xx")
    if (EXISTS "/opt/trailofbits/libraries")
      set(CXX_COMMON_REPOSITORY_ROOT "/opt/trailofbits/libraries"
        CACHE PATH "Location of cxx-common libraries"
      )
    endif()
  endif()
  
  if(NOT DEFINED CXX_COMMON_REPOSITORY_ROOT OR NOT EXISTS "${CXX_COMMON_REPOSITORY_ROOT}")
    if(DEFINED ENV{TRAILOFBITS_LIBRARIES})
      set(CXX_COMMON_REPOSITORY_ROOT $ENV{TRAILOFBITS_LIBRARIES}
        CACHE PATH "Location of cxx-common libraries."
      )
    endif()
  endif()

  set(LLVM_MAJOR_VERSION 10)
  set(LLVM_MINOR_VERSION 0)
  set(REMILL_LLVM_VERSION "10.0")
  
  add_library(remill_bc STATIC IMPORTED)
  set_property(TARGET remill_bc PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_bc.a")
  
  add_library(remill_os STATIC IMPORTED)
  set_property(TARGET remill_os PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_os.a")
  
  add_library(remill_arch STATIC IMPORTED)
  set_property(TARGET remill_arch PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_arch.a")
  
  add_library(remill_arch_x86 STATIC IMPORTED)
  set_property(TARGET remill_arch_x86 PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_arch_x86.a")
  
  add_library(remill_arch_aarch64 STATIC IMPORTED)
  set_property(TARGET remill_arch_aarch64 PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_arch_aarch64.a")
  
  add_library(remill_arch_sparc32 STATIC IMPORTED)
  set_property(TARGET remill_arch_sparc32 PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_arch_sparc32.a")
  
  add_library(remill_arch_sparc64 STATIC IMPORTED)
  set_property(TARGET remill_arch_sparc64 PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_arch_sparc64.a")
  
  add_library(remill_version STATIC IMPORTED)
  set_property(TARGET remill_version PROPERTY IMPORTED_LOCATION "/opt/trailofbits/remill/lib/libremill_version.a")
  
  add_library(remill INTERFACE)
  target_link_libraries(remill INTERFACE
    ${LINKER_START_GROUP}
    remill_bc
    remill_os
    remill_arch
    remill_arch_x86
    remill_arch_aarch64
    remill_arch_sparc32
    remill_arch_sparc64
    remill_version
    /opt/trailofbits/libraries/llvm/lib/libLLVMDemangle.a;/opt/trailofbits/libraries/llvm/lib/libLLVMTableGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMFuzzMutate.a;/opt/trailofbits/libraries/llvm/lib/libLLVMIRReader.a;/opt/trailofbits/libraries/llvm/lib/libLLVMCodeGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSelectionDAG.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAsmPrinter.a;/opt/trailofbits/libraries/llvm/lib/libLLVMMIRParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMGlobalISel.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDWARFLinker.a;/opt/trailofbits/libraries/llvm/lib/libLLVMFrontendOpenMP.a;/opt/trailofbits/libraries/llvm/lib/libLLVMInstrumentation.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAggressiveInstCombine.a;/opt/trailofbits/libraries/llvm/lib/libLLVMInstCombine.a;/opt/trailofbits/libraries/llvm/lib/libLLVMipo.a;/opt/trailofbits/libraries/llvm/lib/libLLVMObjCARCOpts.a;/opt/trailofbits/libraries/llvm/lib/libLLVMCoroutines.a;/opt/trailofbits/libraries/llvm/lib/libLLVMCFGuard.a;/opt/trailofbits/libraries/llvm/lib/libLLVMLTO.a;/opt/trailofbits/libraries/llvm/lib/libLLVMMCDisassembler.a;/opt/trailofbits/libraries/llvm/lib/libLLVMMCA.a;/opt/trailofbits/libraries/llvm/lib/libLLVMObjectYAML.a;/opt/trailofbits/libraries/llvm/lib/libLLVMOption.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDebugInfoGSYM.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDebugInfoPDB.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSymbolize.a;/opt/trailofbits/libraries/llvm/lib/libLLVMExecutionEngine.a;/opt/trailofbits/libraries/llvm/lib/libLLVMInterpreter.a;/opt/trailofbits/libraries/llvm/lib/libLLVMJITLink.a;/opt/trailofbits/libraries/llvm/lib/libLLVMMCJIT.a;/opt/trailofbits/libraries/llvm/lib/libLLVMOrcError.a;/opt/trailofbits/libraries/llvm/lib/libLLVMOrcJIT.a;/opt/trailofbits/libraries/llvm/lib/libLLVMX86CodeGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMX86AsmParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMX86Disassembler.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAArch64CodeGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAArch64AsmParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAArch64Disassembler.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSparcCodeGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSparcAsmParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSparcDisassembler.a;/opt/trailofbits/libraries/llvm/lib/libLLVMNVPTXCodeGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMARMCodeGen.a;/opt/trailofbits/libraries/llvm/lib/libLLVMARMAsmParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMARMDisassembler.a;/opt/trailofbits/libraries/llvm/lib/libLLVMLineEditor.a;/opt/trailofbits/libraries/llvm/lib/libLLVMCoverage.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDlltoolDriver.a;/opt/trailofbits/libraries/llvm/lib/libLLVMLibDriver.a;/opt/trailofbits/libraries/llvm/lib/libLLVMXRay.a;/opt/trailofbits/libraries/llvm/lib/libLLVMWindowsManifest.a;/opt/trailofbits/libraries/xed/lib/libxed.a;/opt/trailofbits/libraries/xed/lib/libxed-ild.a;/opt/trailofbits/libraries/glog/lib/libglog.a;/opt/trailofbits/libraries/gflags/lib/libgflags.a;/opt/trailofbits/libraries/z3/lib/libz3.a;/opt/trailofbits/libraries/llvm/lib/libLLVMBitReader.a;/opt/trailofbits/libraries/llvm/lib/libLLVMBitWriter.a;/opt/trailofbits/libraries/llvm/lib/libLLVMScalarOpts.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDebugInfoMSF.a;/opt/trailofbits/libraries/llvm/lib/libLLVMMCParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAsmParser.a;/opt/trailofbits/libraries/llvm/lib/libLLVMBinaryFormat.a;/opt/trailofbits/libraries/llvm/lib/libLLVMBitstreamReader.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDebugInfoDWARF.a;/opt/trailofbits/libraries/llvm/lib/libLLVMTransformUtils.a;/opt/trailofbits/libraries/llvm/lib/libLLVMLinker.a;/opt/trailofbits/libraries/llvm/lib/libLLVMVectorize.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAnalysis.a;/opt/trailofbits/libraries/llvm/lib/libLLVMObject.a;/opt/trailofbits/libraries/llvm/lib/libLLVMRemarks.a;/opt/trailofbits/libraries/llvm/lib/libLLVMTextAPI.a;/opt/trailofbits/libraries/llvm/lib/libLLVMDebugInfoCodeView.a;/opt/trailofbits/libraries/llvm/lib/libLLVMPasses.a;/opt/trailofbits/libraries/llvm/lib/libLLVMRuntimeDyld.a;/opt/trailofbits/libraries/llvm/lib/libLLVMTarget.a;/opt/trailofbits/libraries/llvm/lib/libLLVMProfileData.a;/opt/trailofbits/libraries/llvm/lib/libLLVMX86Desc.a;/opt/trailofbits/libraries/llvm/lib/libLLVMX86Info.a;/opt/trailofbits/libraries/llvm/lib/libLLVMX86Utils.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAArch64Desc.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAArch64Info.a;/opt/trailofbits/libraries/llvm/lib/libLLVMAArch64Utils.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSparcDesc.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSparcInfo.a;/opt/trailofbits/libraries/llvm/lib/libLLVMNVPTXDesc.a;/opt/trailofbits/libraries/llvm/lib/libLLVMNVPTXInfo.a;/opt/trailofbits/libraries/llvm/lib/libLLVMARMDesc.a;/opt/trailofbits/libraries/llvm/lib/libLLVMARMInfo.a;/opt/trailofbits/libraries/llvm/lib/libLLVMARMUtils.a;/opt/trailofbits/libraries/llvm/lib/libLLVMMC.a;/opt/trailofbits/libraries/llvm/lib/libLLVMCore.a;/opt/trailofbits/libraries/llvm/lib/libLLVMSupport.a;-lpthread;z;rt;dl;tinfo;m
    ${LINKER_END_GROUP}
  )
  
  target_include_directories(remill INTERFACE /opt/trailofbits/libraries/z3/include;/opt/trailofbits/libraries/llvm/include;/opt/trailofbits/libraries/xed/include;/opt/trailofbits/libraries/glog/include;/opt/trailofbits/libraries/gflags/include)
  target_include_directories(remill INTERFACE /opt/trailofbits/remill/include)
  target_compile_options(remill INTERFACE -Wall;-Wextra;-Wno-unused-parameter;-Wno-c++98-compat;-Wno-unreachable-code-return;-Wno-nested-anon-types;-Wno-extended-offsetof;-Wno-variadic-macros;-Wno-return-type-c-linkage;-Wno-c99-extensions;-Wno-ignored-attributes;-Wno-unused-local-typedef;-Wno-unknown-pragmas;-Wno-unknown-warning-option;-fPIC;-fno-omit-frame-pointer;-fvisibility-inlines-hidden;-fno-asynchronous-unwind-tables;-Wgnu-alignof-expression;-Wno-gnu-anonymous-struct;-Wno-gnu-designator;-Wno-gnu-zero-variadic-macro-arguments;-Wno-gnu-statement-expression;-fno-aligned-allocation;-gdwarf-2;-g3;-O2)
  target_compile_definitions(remill INTERFACE NDEBUG;REMILL_INSTALL_SEMANTICS_DIR="/opt/trailofbits/remill/share/remill/10.0/semantics/";REMILL_BUILD_SEMANTICS_DIR_X86="/remill/build/lib/Arch/X86/Runtime";REMILL_BUILD_SEMANTICS_DIR_AARCH64="/remill/build/lib/Arch/AArch64/Runtime";REMILL_BUILD_SEMANTICS_DIR_SPARC32="/remill/build/lib/Arch/SPARC32/Runtime";REMILL_BUILD_SEMANTICS_DIR_SPARC64="/remill/build/lib/Arch/SPARC64/Runtime")

  # Add a dummy 'semantics' target to satisfy the protobuf generator
  add_custom_target(semantics)
endif()
