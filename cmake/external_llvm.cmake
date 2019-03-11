# ******************************************************************************
# Copyright 2017-2019 Intel Corporation
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
# ******************************************************************************

include(ExternalProject)

set(NGRAPH_LLVM_VERSION 8.0.0)

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if (DEFINED NGRAPH_USE_CXX_ABI)
        set(COMPILE_FLAGS "-D_GLIBCXX_USE_CXX11_ABI=${NGRAPH_USE_CXX_ABI}")
    endif()
endif()

ExternalProject_Add(
    ext_clang
    PREFIX clang
    #URL http://releases.llvm.org/${NGRAPH_LLVM_VERSION}/cfe-${NGRAPH_LLVM_VERSION}.src.tar.xz
    #URL_HASH SHA1=427e12762836d808583fb4149c033d02de0a8db2
    URL http://prereleases.llvm.org/8.0.0/rc4/cfe-8.0.0rc4.src.tar.xz
    URL_HASH SHA1=a1660897fecc33e129df116279341b8fe2018f46
    DOWNLOAD_NO_PROGRESS TRUE
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
)

ExternalProject_Get_Property(ext_clang SOURCE_DIR)
set(CLANG_SOURCE_DIR ${SOURCE_DIR})

ExternalProject_Add(
    ext_openmp
    PREFIX openmp
    #URL http://releases.llvm.org/${NGRAPH_LLVM_VERSION}/openmp-${NGRAPH_LLVM_VERSION}.src.tar.xz
    #URL_HASH SHA1=3b931dcafbe6e621c9d99617235fd63f222c2ba2
    URL http://prereleases.llvm.org/8.0.0/rc4/openmp-8.0.0rc4.src.tar.xz
    URL_HASH SHA1=8297ec60b923ece86cb73869fcd1a3a373f41e1f
    DOWNLOAD_NO_PROGRESS TRUE
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
)

ExternalProject_Get_Property(ext_openmp SOURCE_DIR)
set(OPENMP_SOURCE_DIR ${SOURCE_DIR})

if(DEFINED CMAKE_ASM_COMPILER)
    set(LLVM_CMAKE_ASM_COMPILER ${CMAKE_ASM_COMPILER})
else()
    set(LLVM_CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})
endif()

if(WIN32)
    set(LLVM_DEPENDS ext_clang)
else()
    set(LLVM_DEPENDS ext_clang ext_openmp)
    set(PASS_LLVM_OPENMP_DIR -DLLVM_EXTERNAL_OPENMP_SOURCE_DIR=${OPENMP_SOURCE_DIR})
endif()

if(NGRAPH_MANYLINUX_ENABLE)
    set(ALLOW_LLVM_OLD_TOOLCHAIN -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON)
endif()

ExternalProject_Add(
    ext_llvm
    PREFIX llvm
    DEPENDS ${LLVM_DEPENDS}
    #URL http://releases.llvm.org/${NGRAPH_LLVM_VERSION}/llvm-${NGRAPH_LLVM_VERSION}.src.tar.xz
    #URL_HASH SHA1=f97632fcc3186eb0d396492ef8acfc807648580f
    URL http://prereleases.llvm.org/8.0.0/rc4/llvm-8.0.0rc4.src.tar.xz
    URL_HASH SHA1=8486b2a8e136166fe50cbcdccec1ae57a48b7d3c
    DOWNLOAD_NO_PROGRESS TRUE
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    CMAKE_GENERATOR_PLATFORM ${CMAKE_GENERATOR_PLATFORM}
    CMAKE_GENERATOR_TOOLSET ${CMAKE_GENERATOR_TOOLSET}
    CMAKE_ARGS ${NGRAPH_FORWARD_CMAKE_ARGS}
                -DCMAKE_ASM_COMPILER=${LLVM_CMAKE_ASM_COMPILER}
                -DCMAKE_CXX_FLAGS=${COMPILE_FLAGS}
                -DCMAKE_INSTALL_PREFIX=${EXTERNAL_PROJECTS_ROOT}/llvm
                -DLLVM_INCLUDE_DOCS=OFF
                -DLLVM_INCLUDE_TESTS=OFF
                -DLLVM_INCLUDE_GO_TESTS=OFF
                -DLLVM_INCLUDE_EXAMPLES=OFF
                -DLLVM_INCLUDE_BENCHMARKS=OFF
                -DLLVM_BUILD_TOOLS=OFF
                -DLLVM_BUILD_UTILS=OFF
                -DLLVM_BUILD_RUNTIMES=OFF
                -DLLVM_BUILD_RUNTIME=OFF
                -DLLVM_TARGETS_TO_BUILD=X86
                -DLLVM_ENABLE_BINDINGS=OFF
                -DLLVM_ENABLE_TERMINFO=OFF
                -DLLVM_ENABLE_ZLIB=OFF
                ${ALLOW_LLVM_OLD_TOOLCHAIN}
                -DLIBOMP_OMPT_SUPPORT=OFF
                -DCLANG_BUILD_TOOLS=OFF
                -DCLANG_ENABLE_ARCMT=OFF
                -DCLANG_ENABLE_STATIC_ANALYZER=OFF
                -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=${CLANG_SOURCE_DIR}
                ${PASS_LLVM_OPENMP_DIR}
    UPDATE_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
)

ExternalProject_Get_Property(ext_llvm INSTALL_DIR)
set(LLVM_LINK_LIBS
    #[[
    # 5.0.2 does not have
    # clangCrossTU
    # 5.0.2 does not have, only used for building some clang tools
    # clangHandleCXX
    # clangHandleLLVM
    # 5.0.2 does not have
    # clangToolingInclusions
    # 5.0.2 does not have
    # LLVMAggressiveInstCombine
    # LLVMFuzzMutate
    # LLVMMCA
    # LLVMOptRemarks
    # LLVMTextAPI
    # LLVMWindowsManifest
    ]]
    # Do not change order of libraries !!!
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangTooling${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangCodeGen${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangFrontendTool${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangFrontend${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangDriver${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangSerialization${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangParse${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangSema${CMAKE_STATIC_LIBRARY_SUFFIX}
    # Disable static analyzer
    #${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangStaticAnalyzerFrontend${CMAKE_STATIC_LIBRARY_SUFFIX}
    #${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangStaticAnalyzerCheckers${CMAKE_STATIC_LIBRARY_SUFFIX}
    #${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangStaticAnalyzerCore${CMAKE_STATIC_LIBRARY_SUFFIX}
    # 5.0.2 does not have
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangCrossTU${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangAnalysis${CMAKE_STATIC_LIBRARY_SUFFIX}
    # Disabled arc migrate
    #${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangARCMigrate${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangRewriteFrontend${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangEdit${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangAST${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangLex${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}clangBasic${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMLTO${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMPasses${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMObjCARCOpts${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMSymbolize${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMDebugInfoPDB${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMDebugInfoDWARF${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMMIRParser${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMCoverage${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMTableGen${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMDlltoolDriver${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMOrcJIT${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMObjectYAML${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMLibDriver${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMOption${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86Disassembler${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86AsmParser${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86CodeGen${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMGlobalISel${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMSelectionDAG${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMAsmPrinter${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMDebugInfoCodeView${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMDebugInfoMSF${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86Desc${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMMCDisassembler${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86Info${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86AsmPrinter${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMX86Utils${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMMCJIT${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMLineEditor${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMInterpreter${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMExecutionEngine${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMRuntimeDyld${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMCodeGen${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMTarget${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMCoroutines${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMipo${CMAKE_STATIC_LIBRARY_SUFFIX}
    # 5.0.2 does not have
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMAggressiveInstCombine${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMInstrumentation${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMVectorize${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMScalarOpts${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMLinker${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMIRReader${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMAsmParser${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMInstCombine${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMTransformUtils${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMBitWriter${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMAnalysis${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMProfileData${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMObject${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMMCParser${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMMC${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMBitReader${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMCore${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMBinaryFormat${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMSupport${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LLVMDemangle${CMAKE_STATIC_LIBRARY_SUFFIX}
    m
)

ExternalProject_Get_Property(ext_llvm INSTALL_DIR)

if(LINUX OR APPLE)
    set(LLVM_LINK_LIBS ${LLVM_LINK_LIBS} m)
endif()

add_library(libllvm INTERFACE)
add_dependencies(libllvm ext_llvm)
target_include_directories(libllvm SYSTEM INTERFACE ${INSTALL_DIR}/include)
target_link_libraries(libllvm INTERFACE ${LLVM_LINK_LIBS})
