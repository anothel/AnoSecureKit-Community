# SPDX-License-Identifier: MPL-2.0
cmake_minimum_required(VERSION 3.20)

project(
  anosecurekit
  VERSION 0.4.0
  DESCRIPTION "AnoSecureKit Community security utilities"
  LANGUAGES CXX)

include(CTest)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

set(ANOSECUREKIT_CRYPTO_BACKEND "openssl" CACHE STRING
  "Crypto backend for AnoSecureKit. Community ships openssl; external is build-tree only.")
set_property(CACHE ANOSECUREKIT_CRYPTO_BACKEND PROPERTY STRINGS openssl external)
set(ANOSECUREKIT_EXTERNAL_BACKEND_TARGET "" CACHE STRING
  "Existing non-imported OBJECT provider target used with ANOSECUREKIT_CRYPTO_BACKEND=external")

set(_anosecurekit_external_backend FALSE)
if(ANOSECUREKIT_CRYPTO_BACKEND STREQUAL "openssl")
  find_package(OpenSSL 3.0 REQUIRED COMPONENTS Crypto)
elseif(ANOSECUREKIT_CRYPTO_BACKEND STREQUAL "external")
  set(_anosecurekit_external_backend TRUE)

  if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    message(FATAL_ERROR
      "ANOSECUREKIT_CRYPTO_BACKEND=external is a build-tree-only integration hook. "
      "Define the provider target in a parent project, then add AnoSecureKit with add_subdirectory().")
  endif()

  if(ANOSECUREKIT_EXTERNAL_BACKEND_TARGET STREQUAL "")
    message(FATAL_ERROR
      "ANOSECUREKIT_CRYPTO_BACKEND=external requires "
      "ANOSECUREKIT_EXTERNAL_BACKEND_TARGET to name an existing provider target.")
  endif()

  if(NOT TARGET "${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}")
    message(FATAL_ERROR
      "ANOSECUREKIT_EXTERNAL_BACKEND_TARGET='${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}' "
      "does not name an existing target.")
  endif()

  get_target_property(_anosecurekit_external_backend_imported
    "${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}" IMPORTED)
  if(_anosecurekit_external_backend_imported)
    message(FATAL_ERROR
      "ANOSECUREKIT_EXTERNAL_BACKEND_TARGET must name a non-imported provider adapter target, "
      "not the external cryptographic module target itself.")
  endif()

  get_target_property(_anosecurekit_external_backend_type
    "${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}" TYPE)
  if(NOT _anosecurekit_external_backend_type STREQUAL "OBJECT_LIBRARY")
    message(FATAL_ERROR
      "ANOSECUREKIT_EXTERNAL_BACKEND_TARGET must be an OBJECT_LIBRARY target so the provider "
      "implementation is linked into the build-tree product without an installed dependency; "
      "got '${_anosecurekit_external_backend_type}'.")
  endif()

  message(STATUS
    "AnoSecureKit external provider hook enabled with target "
    "'${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}' (build-tree only)")
else()
  message(FATAL_ERROR
    "Unsupported ANOSECUREKIT_CRYPTO_BACKEND='${ANOSECUREKIT_CRYPTO_BACKEND}'. "
    "Expected 'openssl' or 'external'.")
endif()

if(WIN32)
  set(ANOSECUREKIT_OPENSSL_RUNTIME_DIR "" CACHE PATH
    "Directory containing OpenSSL runtime DLLs for AnoSecureKit tests and package checks")
  if(NOT ANOSECUREKIT_OPENSSL_RUNTIME_DIR AND DEFINED OPENSSL_ROOT_DIR)
    set(ANOSECUREKIT_OPENSSL_RUNTIME_DIR "${OPENSSL_ROOT_DIR}/bin")
  endif()
endif()

option(ANOSECUREKIT_WARNINGS_AS_ERRORS "Treat AnoSecureKit build warnings as errors" OFF)
option(ANOSECUREKIT_BUILD_CLI "Build AnoSecureKit CLI" ON)
option(ANOSECUREKIT_INSTALL_CLI "Install AnoSecureKit CLI" ON)
option(ANOSECUREKIT_BUILD_FUZZ "Build AnoSecureKit libFuzzer targets" OFF)
option(ANOSECUREKIT_ENABLE_COVERAGE "Build with GCC/Clang coverage instrumentation" OFF)

if(NOT _anosecurekit_external_backend
    AND ANOSECUREKIT_INSTALL_CLI
    AND NOT ANOSECUREKIT_BUILD_CLI)
  message(FATAL_ERROR "ANOSECUREKIT_INSTALL_CLI=ON requires ANOSECUREKIT_BUILD_CLI=ON")
endif()

if(_anosecurekit_external_backend)
  message(STATUS
    "AnoSecureKit external provider mode is build-tree only; Community install, export, and CPack rules are disabled")
  if(ANOSECUREKIT_INSTALL_CLI)
    message(STATUS
      "ANOSECUREKIT_INSTALL_CLI is ignored for the build-tree-only external provider profile")
  endif()
endif()

set(_anosecurekit_compile_options)
set(_anosecurekit_coverage_options)
if(MSVC)
  list(APPEND _anosecurekit_compile_options /W4 /permissive-)
  if(ANOSECUREKIT_WARNINGS_AS_ERRORS)
    list(APPEND _anosecurekit_compile_options /WX)
  endif()
  if(ANOSECUREKIT_ENABLE_COVERAGE)
    message(FATAL_ERROR "ANOSECUREKIT_ENABLE_COVERAGE=ON requires GCC or Clang")
  endif()
else()
  list(APPEND _anosecurekit_compile_options -Wall -Wextra -Wpedantic)
  if(ANOSECUREKIT_WARNINGS_AS_ERRORS)
    list(APPEND _anosecurekit_compile_options -Werror)
  endif()
  if(ANOSECUREKIT_ENABLE_COVERAGE)
    list(APPEND _anosecurekit_coverage_options --coverage -O0 -g)
  endif()
endif()

find_program(CLANG_FORMAT_EXE
  NAMES clang-format
  HINTS
    "$ENV{ProgramFiles}/Microsoft Visual Studio/18/Community/VC/Tools/Llvm/x64/bin"
    "$ENV{ProgramFiles}/Microsoft Visual Studio/18/Community/VC/Tools/Llvm/bin")
if(CLANG_FORMAT_EXE)
  file(GLOB_RECURSE _anosecurekit_format_sources CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/include/anosecurekit/*.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/benchmarks/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.hpp)
  add_custom_target(format-check
    COMMAND ${CLANG_FORMAT_EXE} --dry-run --Werror ${_anosecurekit_format_sources}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    USES_TERMINAL)
else()
  add_custom_target(format-check
    COMMAND ${CMAKE_COMMAND} -E echo "format-check requires clang-format on PATH"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
endif()

set(_anosecurekit_backend_sources)
if(ANOSECUREKIT_CRYPTO_BACKEND STREQUAL "openssl")
  list(APPEND _anosecurekit_backend_sources
    src/backend/crypto_backend_openssl.cpp)
endif()

add_library(anosecurekit
  src/aead.cpp
  src/base64.cpp
  src/compare.cpp
  ${_anosecurekit_backend_sources}
  src/error.cpp
  src/file_crypto.cpp
  src/file.cpp
  src/file_io.cpp
  src/hash.cpp
  src/hex.cpp
  src/internal/secure_wipe.cpp
  src/key_wrap.cpp
  src/packet_stream.cpp
  src/random.cpp
  src/version.cpp)

add_library(anosecurekit::anosecurekit ALIAS anosecurekit)

target_compile_features(anosecurekit PUBLIC cxx_std_20)

target_include_directories(anosecurekit
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>)

if(ANOSECUREKIT_CRYPTO_BACKEND STREQUAL "openssl")
  target_link_libraries(anosecurekit PUBLIC OpenSSL::Crypto)
  target_compile_definitions(anosecurekit PRIVATE ANOSECUREKIT_CRYPTO_BACKEND_OPENSSL=1)
else()
  target_include_directories("${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}"
    PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/include"
      "${CMAKE_CURRENT_SOURCE_DIR}/src")
  target_compile_features("${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}" PRIVATE cxx_std_20)
  target_compile_definitions("${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}" PRIVATE
    ANOSECUREKIT_BUILDING_LIBRARY
    ANOSECUREKIT_EXTERNAL_BACKEND_PROVIDER=1)
  if(BUILD_SHARED_LIBS)
    set_property(TARGET "${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}"
      PROPERTY POSITION_INDEPENDENT_CODE ON)
    target_compile_definitions("${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}" PRIVATE
      ANOSECUREKIT_SHARED)
  endif()

  target_link_libraries(anosecurekit PRIVATE "${ANOSECUREKIT_EXTERNAL_BACKEND_TARGET}")
  target_compile_definitions(anosecurekit PRIVATE ANOSECUREKIT_CRYPTO_BACKEND_EXTERNAL=1)
endif()

target_compile_definitions(anosecurekit PRIVATE
  ANOSECUREKIT_BUILDING_LIBRARY
  ANOSECUREKIT_VERSION="${PROJECT_VERSION}"
  ANOSECUREKIT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
  ANOSECUREKIT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
  ANOSECUREKIT_VERSION_PATCH=${PROJECT_VERSION_PATCH})

if(BUILD_SHARED_LIBS)
  target_compile_definitions(anosecurekit PUBLIC ANOSECUREKIT_SHARED)
endif()

target_compile_options(anosecurekit PRIVATE ${_anosecurekit_compile_options} ${_anosecurekit_coverage_options})
target_link_options(anosecurekit PUBLIC ${_anosecurekit_coverage_options})

if(ANOSECUREKIT_BUILD_CLI)
  add_executable(anosecurekit_cli
    src/cli/commands.cpp
    src/cli/main.cpp)

  set_target_properties(anosecurekit_cli PROPERTIES OUTPUT_NAME anosecurekit)

  target_link_libraries(anosecurekit_cli PRIVATE anosecurekit::anosecurekit)
  target_compile_features(anosecurekit_cli PRIVATE cxx_std_20)

  target_compile_options(anosecurekit_cli PRIVATE ${_anosecurekit_compile_options} ${_anosecurekit_coverage_options})
endif()

add_custom_target(spdx-check
  COMMAND ${CMAKE_COMMAND}
    -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_spdx.cmake
  USES_TERMINAL)

add_custom_target(legacy-name-check
  COMMAND ${CMAKE_COMMAND}
    -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_legacy_identifiers.cmake
  USES_TERMINAL)

add_custom_target(document-alignment-check
  COMMAND ${CMAKE_COMMAND}
    -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_document_alignment.cmake
  USES_TERMINAL)

add_custom_target(backend-boundary-check
  COMMAND ${CMAKE_COMMAND}
    -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_backend_boundary.cmake
  USES_TERMINAL)

add_custom_target(external-backend-hook-check
  COMMAND ${CMAKE_COMMAND}
    -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -DANOSECUREKIT_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/external-backend-hook-check
    -DANOSECUREKIT_BUILD_CONFIG=$<CONFIG>
    -DANOSECUREKIT_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DANOSECUREKIT_CMAKE_GENERATOR=${CMAKE_GENERATOR}
    -DANOSECUREKIT_CMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
    -DANOSECUREKIT_CMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
    -DANOSECUREKIT_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
    -DANOSECUREKIT_CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}
    -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}
    -DANOSECUREKIT_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_external_backend_hook.cmake
  USES_TERMINAL)

if(ANOSECUREKIT_BUILD_CLI)
  add_custom_target(cli-docs-check
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_CLI=$<TARGET_FILE:anosecurekit_cli>
      -DANOSECUREKIT_CLI_DOC=${CMAKE_CURRENT_SOURCE_DIR}/docs/CLI.md
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_cli_docs.cmake
    DEPENDS anosecurekit_cli
    USES_TERMINAL)
else()
  add_custom_target(cli-docs-check
    COMMAND ${CMAKE_COMMAND} -E echo "cli-docs-check requires ANOSECUREKIT_BUILD_CLI=ON"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
endif()

add_executable(anosecurekit_example_basic EXCLUDE_FROM_ALL
  examples/basic/main.cpp)
target_link_libraries(anosecurekit_example_basic PRIVATE anosecurekit::anosecurekit)
target_compile_features(anosecurekit_example_basic PRIVATE cxx_std_20)
target_compile_options(anosecurekit_example_basic PRIVATE ${_anosecurekit_compile_options} ${_anosecurekit_coverage_options})

add_custom_target(examples-check
  COMMAND $<TARGET_FILE:anosecurekit_example_basic>
  DEPENDS anosecurekit_example_basic
  USES_TERMINAL)

add_executable(anosecurekit_benchmarks EXCLUDE_FROM_ALL
  benchmarks/crypto_file_bench.cpp)
target_link_libraries(anosecurekit_benchmarks PRIVATE anosecurekit::anosecurekit)
target_compile_features(anosecurekit_benchmarks PRIVATE cxx_std_20)
target_compile_options(anosecurekit_benchmarks PRIVATE ${_anosecurekit_compile_options} ${_anosecurekit_coverage_options})

add_custom_target(benchmarks-check
  COMMAND $<TARGET_FILE:anosecurekit_benchmarks>
  DEPENDS anosecurekit_benchmarks
  USES_TERMINAL)

if(ANOSECUREKIT_BUILD_FUZZ)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(FATAL_ERROR "ANOSECUREKIT_BUILD_FUZZ=ON requires Clang with libFuzzer support")
  endif()

  function(anosecurekit_add_fuzz target source)
    add_executable(${target} ${source})
    target_link_libraries(${target} PRIVATE anosecurekit::anosecurekit)
    target_compile_features(${target} PRIVATE cxx_std_20)
    target_compile_options(${target} PRIVATE -fsanitize=fuzzer,address ${_anosecurekit_compile_options})
    target_link_options(${target} PRIVATE -fsanitize=fuzzer,address)
  endfunction()

  anosecurekit_add_fuzz(anosecurekit_fuzz_hex tests/fuzz/hex_fuzz.cpp)
  anosecurekit_add_fuzz(anosecurekit_fuzz_base64 tests/fuzz/base64_fuzz.cpp)
  anosecurekit_add_fuzz(anosecurekit_fuzz_base64url tests/fuzz/base64url_fuzz.cpp)
  anosecurekit_add_fuzz(anosecurekit_fuzz_skt1 tests/fuzz/skt1_fuzz.cpp)
  anosecurekit_add_fuzz(anosecurekit_fuzz_file tests/fuzz/file_fuzz.cpp)

  set(_anosecurekit_fuzz_corpus
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/fuzz/corpus)

  add_custom_target(fuzz-smoke
    COMMAND $<TARGET_FILE:anosecurekit_fuzz_hex> -runs=1 ${_anosecurekit_fuzz_corpus}
    COMMAND $<TARGET_FILE:anosecurekit_fuzz_base64> -runs=1 ${_anosecurekit_fuzz_corpus}
    COMMAND $<TARGET_FILE:anosecurekit_fuzz_base64url> -runs=1 ${_anosecurekit_fuzz_corpus}
    COMMAND $<TARGET_FILE:anosecurekit_fuzz_skt1> -runs=1 ${_anosecurekit_fuzz_corpus}
    COMMAND $<TARGET_FILE:anosecurekit_fuzz_file> -runs=1 ${_anosecurekit_fuzz_corpus}
    DEPENDS
      anosecurekit_fuzz_hex
      anosecurekit_fuzz_base64
      anosecurekit_fuzz_base64url
      anosecurekit_fuzz_skt1
      anosecurekit_fuzz_file
    USES_TERMINAL)
endif()

if(NOT _anosecurekit_external_backend
    AND ANOSECUREKIT_BUILD_CLI
    AND ANOSECUREKIT_INSTALL_CLI)
  add_custom_target(package-check
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DANOSECUREKIT_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
      -DANOSECUREKIT_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/package-check
      -DANOSECUREKIT_PROJECT_NAME=${PROJECT_NAME}
      -DANOSECUREKIT_PROJECT_VERSION=${PROJECT_VERSION}
      -DANOSECUREKIT_PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
      -DANOSECUREKIT_PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
      -DANOSECUREKIT_PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
      -DANOSECUREKIT_BUILD_CONFIG=$<CONFIG>
      -DANOSECUREKIT_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DANOSECUREKIT_CMAKE_GENERATOR=${CMAKE_GENERATOR}
      -DANOSECUREKIT_CMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DANOSECUREKIT_CMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
      -DANOSECUREKIT_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
      -DANOSECUREKIT_CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DANOSECUREKIT_CMAKE_AR=${CMAKE_AR}
      -DANOSECUREKIT_CMAKE_LINKER=${CMAKE_LINKER}
      -DANOSECUREKIT_CMAKE_MT=${CMAKE_MT}
      -DANOSECUREKIT_CMAKE_RC_COMPILER=${CMAKE_RC_COMPILER}
      -DANOSECUREKIT_CPACK_COMMAND=${CMAKE_CPACK_COMMAND}
      -DANOSECUREKIT_WARNINGS_AS_ERRORS=${ANOSECUREKIT_WARNINGS_AS_ERRORS}
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
      -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}
      -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}
      -DANOSECUREKIT_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_package.cmake
    DEPENDS anosecurekit anosecurekit_cli
    USES_TERMINAL)
else()
  add_custom_target(package-check
    COMMAND ${CMAKE_COMMAND} -E echo "package-check is available only for the installed Community OpenSSL profile with CLI enabled"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
endif()

if(NOT _anosecurekit_external_backend
    AND ANOSECUREKIT_BUILD_CLI
    AND ANOSECUREKIT_INSTALL_CLI)
  add_custom_target(dogfood-check
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DANOSECUREKIT_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/package-check
      -DANOSECUREKIT_PROJECT_NAME=${PROJECT_NAME}
      -DANOSECUREKIT_PROJECT_VERSION=${PROJECT_VERSION}
      -DANOSECUREKIT_PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
      -DANOSECUREKIT_PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
      -DANOSECUREKIT_PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
      -DANOSECUREKIT_BUILD_CONFIG=$<CONFIG>
      -DANOSECUREKIT_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DANOSECUREKIT_CMAKE_GENERATOR=${CMAKE_GENERATOR}
      -DANOSECUREKIT_CMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DANOSECUREKIT_CMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
      -DANOSECUREKIT_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
      -DANOSECUREKIT_CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DANOSECUREKIT_CMAKE_AR=${CMAKE_AR}
      -DANOSECUREKIT_CMAKE_LINKER=${CMAKE_LINKER}
      -DANOSECUREKIT_CMAKE_MT=${CMAKE_MT}
      -DANOSECUREKIT_CMAKE_RC_COMPILER=${CMAKE_RC_COMPILER}
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
      -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}
      -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}
      -DANOSECUREKIT_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_dogfood.cmake
    DEPENDS package-check
    USES_TERMINAL)
else()
  add_custom_target(dogfood-check
    COMMAND ${CMAKE_COMMAND} -E echo "dogfood-check is available only for the installed Community OpenSSL profile with CLI enabled"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
endif()

add_custom_target(release-workflow-check
  COMMAND ${CMAKE_COMMAND}
    -DANOSECUREKIT_WORKFLOW_FILE=${CMAKE_CURRENT_SOURCE_DIR}/.github/workflows/anosecurekit-ci.yml
    -DANOSECUREKIT_CODEQL_WORKFLOW_FILE=${CMAKE_CURRENT_SOURCE_DIR}/.github/workflows/codeql.yml
    -DANOSECUREKIT_PROJECT_VERSION:STRING=${PROJECT_VERSION}
    -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_release_workflow.cmake
  USES_TERMINAL)

option(ANOSECUREKIT_BUILD_TESTS "Build AnoSecureKit tests" ${BUILD_TESTING})
set(ANOSECUREKIT_TEST_PARALLEL_LEVEL "4" CACHE STRING
  "Parallel test/build jobs used by check and nested provider parity validation")
if(NOT ANOSECUREKIT_TEST_PARALLEL_LEVEL MATCHES "^[1-9][0-9]*$")
  message(FATAL_ERROR
    "ANOSECUREKIT_TEST_PARALLEL_LEVEL must be a positive integer")
endif()

if(ANOSECUREKIT_BUILD_TESTS)
  find_package(GTest CONFIG QUIET)
  if(NOT GTest_FOUND)
    include(FetchContent)
    FetchContent_Declare(
      googletest
      GIT_REPOSITORY https://github.com/google/googletest.git
      GIT_TAG v1.14.0)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    set(_anosecurekit_build_shared_libs "${BUILD_SHARED_LIBS}")
    set(BUILD_SHARED_LIBS OFF)
    FetchContent_MakeAvailable(googletest)
    set(BUILD_SHARED_LIBS "${_anosecurekit_build_shared_libs}")
  endif()

  add_executable(anosecurekit_tests
    tests/aead_test.cpp
    tests/base64_test.cpp
    tests/compare_test.cpp
    tests/file_test.cpp
    tests/fixture_inventory_test.cpp
    tests/hash_test.cpp
    tests/hex_test.cpp
    tests/internal_wipe_test.cpp
    tests/key_wrap_test.cpp
    tests/packet_stream_test.cpp
    tests/public_headers_test.cpp
    tests/random_test.cpp)

  target_link_libraries(anosecurekit_tests PRIVATE anosecurekit::anosecurekit GTest::gtest_main)
  target_compile_features(anosecurekit_tests PRIVATE cxx_std_20)
  target_compile_options(anosecurekit_tests PRIVATE ${_anosecurekit_compile_options} ${_anosecurekit_coverage_options})
  target_compile_definitions(anosecurekit_tests PRIVATE
    ANOSECUREKIT_TEST_FIXTURE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures"
    ANOSECUREKIT_FORMAT_DOC="${CMAKE_CURRENT_SOURCE_DIR}/docs/FORMAT.md"
    ANOSECUREKIT_EXPECTED_VERSION="${PROJECT_VERSION}"
    ANOSECUREKIT_EXPECTED_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
    ANOSECUREKIT_EXPECTED_VERSION_MINOR=${PROJECT_VERSION_MINOR}
    ANOSECUREKIT_EXPECTED_VERSION_PATCH=${PROJECT_VERSION_PATCH})

  set(_anosecurekit_test_properties)
  if(WIN32)
    if(ANOSECUREKIT_OPENSSL_RUNTIME_DIR)
      set(_anosecurekit_test_path "${ANOSECUREKIT_OPENSSL_RUNTIME_DIR};$ENV{PATH}")
      string(REPLACE ";" "\\;" _anosecurekit_test_path "${_anosecurekit_test_path}")
      list(APPEND _anosecurekit_test_properties ENVIRONMENT "PATH=${_anosecurekit_test_path}")
      add_custom_command(TARGET anosecurekit_tests POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}"
          "$<TARGET_FILE_DIR:anosecurekit_tests>")
    endif()
  endif()

  include(GoogleTest)
  gtest_discover_tests(anosecurekit_tests
    DISCOVERY_MODE PRE_TEST
    PROPERTIES ${_anosecurekit_test_properties})

  set(_anosecurekit_check_dependencies anosecurekit_tests)
  if(TARGET anosecurekit_cli)
    add_test(
      NAME Cli.UtilityCommands
      COMMAND ${CMAKE_COMMAND}
        -DANOSECUREKIT_CLI=$<TARGET_FILE:anosecurekit_cli>
        -DANOSECUREKIT_EXPECTED_VERSION=${PROJECT_VERSION}
        -DANOSECUREKIT_TEST_FIXTURE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/cli/check_cli.cmake)
    if(_anosecurekit_test_properties)
      set_tests_properties(Cli.UtilityCommands PROPERTIES ${_anosecurekit_test_properties})
    endif()
    list(APPEND _anosecurekit_check_dependencies anosecurekit_cli)
  endif()

  add_custom_target(check
    COMMAND ${CMAKE_CTEST_COMMAND}
      --test-dir ${CMAKE_CURRENT_BINARY_DIR}
      --build-config $<CONFIG>
      --output-on-failure
      --parallel ${ANOSECUREKIT_TEST_PARALLEL_LEVEL}
    DEPENDS ${_anosecurekit_check_dependencies}
    USES_TERMINAL)

  find_program(GCOVR_EXE NAMES gcovr)
  if(ANOSECUREKIT_ENABLE_COVERAGE AND GCOVR_EXE)
    add_custom_target(coverage-report
      COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/coverage
      COMMAND ${GCOVR_EXE}
        --root ${CMAKE_CURRENT_SOURCE_DIR}
        --object-directory ${CMAKE_CURRENT_BINARY_DIR}
        --filter ${CMAKE_CURRENT_SOURCE_DIR}/include
        --filter ${CMAKE_CURRENT_SOURCE_DIR}/src
        --exclude ${CMAKE_CURRENT_SOURCE_DIR}/tests
        --html-details ${CMAKE_CURRENT_BINARY_DIR}/coverage/anosecurekit.html
        --xml ${CMAKE_CURRENT_BINARY_DIR}/coverage/coverage.xml
        --print-summary
      DEPENDS check
      USES_TERMINAL)
  else()
    add_custom_target(coverage-report
      COMMAND ${CMAKE_COMMAND} -E echo "coverage-report requires -DANOSECUREKIT_ENABLE_COVERAGE=ON, GCC or Clang, and gcovr"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)
  endif()
endif()

if(TARGET check)
  set(_anosecurekit_googletest_source_dir "")
  if(DEFINED googletest_SOURCE_DIR
      AND EXISTS "${googletest_SOURCE_DIR}/CMakeLists.txt")
    set(_anosecurekit_googletest_source_dir "${googletest_SOURCE_DIR}")
  endif()

  add_custom_target(external-backend-parity-check
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DANOSECUREKIT_PARENT_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
      -DANOSECUREKIT_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/external-backend-parity-check
      -DANOSECUREKIT_BUILD_CONFIG=$<CONFIG>
      -DANOSECUREKIT_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DANOSECUREKIT_CMAKE_GENERATOR=${CMAKE_GENERATOR}
      -DANOSECUREKIT_CMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DANOSECUREKIT_CMAKE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
      -DANOSECUREKIT_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
      -DANOSECUREKIT_CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
      -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}
      -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}
      -DANOSECUREKIT_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}
      -DANOSECUREKIT_CTEST_COMMAND=${CMAKE_CTEST_COMMAND}
      -DANOSECUREKIT_TEST_PARALLEL_LEVEL=${ANOSECUREKIT_TEST_PARALLEL_LEVEL}
      -DANOSECUREKIT_GTEST_DIR=${GTest_DIR}
      -DANOSECUREKIT_GOOGLETEST_SOURCE_DIR=${_anosecurekit_googletest_source_dir}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_external_backend_parity.cmake
    DEPENDS anosecurekit_tests
    USES_TERMINAL)
else()
  add_custom_target(external-backend-parity-check
    COMMAND ${CMAKE_COMMAND} -E echo "external-backend-parity-check requires ANOSECUREKIT_BUILD_TESTS=ON"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
endif()

if(_anosecurekit_external_backend)
  add_custom_target(release-preflight
    COMMAND ${CMAKE_COMMAND} -E echo "release-preflight is available only for the shipped Community OpenSSL profile"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
elseif(TARGET check AND ANOSECUREKIT_BUILD_CLI AND ANOSECUREKIT_INSTALL_CLI)
  add_custom_target(release-preflight
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/package-check
      -DANOSECUREKIT_PROJECT_NAME=${PROJECT_NAME}
      -DANOSECUREKIT_PROJECT_VERSION:STRING=${PROJECT_VERSION}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_release_assets.cmake
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/package-check
      -DANOSECUREKIT_PROJECT_NAME=${PROJECT_NAME}
      -DANOSECUREKIT_PROJECT_VERSION:STRING=${PROJECT_VERSION}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_package_recipes.cmake
    COMMAND ${CMAKE_COMMAND}
      -DANOSECUREKIT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DANOSECUREKIT_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/package-check
      -DANOSECUREKIT_PROJECT_NAME=${PROJECT_NAME}
      -DANOSECUREKIT_PROJECT_VERSION:STRING=${PROJECT_VERSION}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_release_preflight.cmake
    DEPENDS
      check
      benchmarks-check
      examples-check
      dogfood-check
      release-workflow-check
      spdx-check
      legacy-name-check
      document-alignment-check
      backend-boundary-check
      external-backend-hook-check
      external-backend-parity-check
      cli-docs-check
    USES_TERMINAL)
elseif(TARGET check)
  add_custom_target(release-preflight
    COMMAND ${CMAKE_COMMAND} -E echo "release-preflight requires ANOSECUREKIT_BUILD_CLI=ON and ANOSECUREKIT_INSTALL_CLI=ON because release validation requires installed CLI"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
else()
  add_custom_target(release-preflight
    COMMAND ${CMAKE_COMMAND} -E echo "release-preflight requires ANOSECUREKIT_BUILD_TESTS=ON"
    COMMAND ${CMAKE_COMMAND} -E false
    USES_TERMINAL)
endif()

if(NOT _anosecurekit_external_backend)
install(
  TARGETS anosecurekit
  EXPORT anosecurekitTargets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

if(ANOSECUREKIT_INSTALL_CLI)
  install(
    TARGETS anosecurekit_cli
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

install(
  DIRECTORY include/anosecurekit
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(
  EXPORT anosecurekitTargets
  NAMESPACE anosecurekit::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/anosecurekit)

configure_package_config_file(
  cmake/anosecurekitConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/anosecurekit)

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion)

install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitConfigVersion.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/anosecurekit)

set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_VENDOR "AnoSecureKit")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_CONTACT "AnoSecureKit maintainers")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_FILE_NAME
  "${PROJECT_NAME}-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_GENERATOR "ZIP;TGZ")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${PROJECT_VERSION}-source")
set(CPACK_SOURCE_GENERATOR "ZIP;TGZ")
set(CPACK_SOURCE_IGNORE_FILES
  "/\\.agents/"
  "/\\.codex/"
  "/\\.git/"
  "/\\.github/"
  "/\\.vscode/"
  "/build[^/]*/"
  "/docs/superpowers/"
  "/artifacts/"
  "/COMM-REL-[^/]*"
  "/collect_v[^/]*-publication-evidence[^/]*\\.sh$"
  "/anosecurekit-cli-[^/]*$"
  "/package-check/"
  "/_CPack_Packages/"
  "CMakeCache\\.txt$"
  "CMakeFiles/"
  "\\.user$")
set(CPACK_VERBATIM_VARIABLES YES)
include(CPack)

endif()
