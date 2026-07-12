# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()
if(NOT DEFINED ANOSECUREKIT_CHECK_ROOT OR ANOSECUREKIT_CHECK_ROOT STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_CHECK_ROOT is required")
endif()
if(NOT DEFINED ANOSECUREKIT_PARENT_BUILD_DIR OR ANOSECUREKIT_PARENT_BUILD_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PARENT_BUILD_DIR is required")
endif()
if(NOT DEFINED ANOSECUREKIT_CTEST_COMMAND OR ANOSECUREKIT_CTEST_COMMAND STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_CTEST_COMMAND is required")
endif()
if(NOT IS_ABSOLUTE "${ANOSECUREKIT_SOURCE_DIR}")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR must be absolute")
endif()
if(NOT IS_ABSOLUTE "${ANOSECUREKIT_CHECK_ROOT}")
  message(FATAL_ERROR "ANOSECUREKIT_CHECK_ROOT must be absolute")
endif()
if(NOT IS_ABSOLUTE "${ANOSECUREKIT_PARENT_BUILD_DIR}")
  message(FATAL_ERROR "ANOSECUREKIT_PARENT_BUILD_DIR must be absolute")
endif()
if(NOT DEFINED ANOSECUREKIT_TEST_PARALLEL_LEVEL
    OR ANOSECUREKIT_TEST_PARALLEL_LEVEL STREQUAL "")
  set(ANOSECUREKIT_TEST_PARALLEL_LEVEL "4")
endif()
if(NOT ANOSECUREKIT_TEST_PARALLEL_LEVEL MATCHES "^[1-9][0-9]*$")
  message(FATAL_ERROR
    "ANOSECUREKIT_TEST_PARALLEL_LEVEL must be a positive integer")
endif()

if(NOT DEFINED ANOSECUREKIT_BUILD_CONFIG OR ANOSECUREKIT_BUILD_CONFIG STREQUAL "")
  if(DEFINED ANOSECUREKIT_DEFAULT_BUILD_TYPE
      AND NOT ANOSECUREKIT_DEFAULT_BUILD_TYPE STREQUAL "")
    set(ANOSECUREKIT_BUILD_CONFIG "${ANOSECUREKIT_DEFAULT_BUILD_TYPE}")
  else()
    set(ANOSECUREKIT_BUILD_CONFIG "Release")
  endif()
endif()

function(_anosecurekit_append_generator_args output_variable)
  set(_anosecurekit_args "${${output_variable}}")
  if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR
      AND NOT ANOSECUREKIT_CMAKE_GENERATOR STREQUAL "")
    list(APPEND _anosecurekit_args -G "${ANOSECUREKIT_CMAKE_GENERATOR}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM
      AND NOT ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM STREQUAL "")
    list(APPEND _anosecurekit_args -A "${ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET
      AND NOT ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET STREQUAL "")
    list(APPEND _anosecurekit_args -T "${ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_MAKE_PROGRAM
      AND NOT ANOSECUREKIT_CMAKE_MAKE_PROGRAM STREQUAL "")
    list(APPEND _anosecurekit_args
      "-DCMAKE_MAKE_PROGRAM=${ANOSECUREKIT_CMAKE_MAKE_PROGRAM}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_CXX_COMPILER
      AND NOT ANOSECUREKIT_CMAKE_CXX_COMPILER STREQUAL "")
    list(APPEND _anosecurekit_args
      "-DCMAKE_CXX_COMPILER=${ANOSECUREKIT_CMAKE_CXX_COMPILER}")
  endif()
  if(DEFINED CMAKE_TOOLCHAIN_FILE AND NOT CMAKE_TOOLCHAIN_FILE STREQUAL "")
    list(APPEND _anosecurekit_args
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
  endif()
  if(DEFINED VCPKG_TARGET_TRIPLET AND NOT VCPKG_TARGET_TRIPLET STREQUAL "")
    list(APPEND _anosecurekit_args
      "-DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}")
  endif()
  if(DEFINED OPENSSL_ROOT_DIR AND NOT OPENSSL_ROOT_DIR STREQUAL "")
    list(APPEND _anosecurekit_args "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}")
  endif()
  if(DEFINED ANOSECUREKIT_OPENSSL_RUNTIME_DIR
      AND NOT ANOSECUREKIT_OPENSSL_RUNTIME_DIR STREQUAL "")
    list(APPEND _anosecurekit_args
      "-DANOSECUREKIT_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}")
  endif()
  set(${output_variable} "${_anosecurekit_args}" PARENT_SCOPE)
endfunction()

function(_anosecurekit_ctest_inventory build_dir output_count output_names)
  set(_anosecurekit_command
    "${ANOSECUREKIT_CTEST_COMMAND}"
    --test-dir "${build_dir}"
    --show-only=json-v1)
  if(DEFINED ANOSECUREKIT_BUILD_CONFIG
      AND NOT ANOSECUREKIT_BUILD_CONFIG STREQUAL "")
    list(APPEND _anosecurekit_command -C "${ANOSECUREKIT_BUILD_CONFIG}")
  endif()
  execute_process(
    COMMAND ${_anosecurekit_command}
    RESULT_VARIABLE _anosecurekit_result
    OUTPUT_VARIABLE _anosecurekit_json
    ERROR_VARIABLE _anosecurekit_stderr)
  if(NOT _anosecurekit_result EQUAL 0)
    message(FATAL_ERROR
      "Could not inspect CTest inventory in '${build_dir}':\n${_anosecurekit_stderr}")
  endif()

  string(JSON _anosecurekit_count LENGTH "${_anosecurekit_json}" tests)
  set(_anosecurekit_names)
  if(_anosecurekit_count GREATER 0)
    math(EXPR _anosecurekit_last "${_anosecurekit_count} - 1")
    foreach(_anosecurekit_index RANGE 0 ${_anosecurekit_last})
      string(JSON _anosecurekit_name GET "${_anosecurekit_json}" tests ${_anosecurekit_index} name)
      list(APPEND _anosecurekit_names "${_anosecurekit_name}")
    endforeach()
  endif()
  list(SORT _anosecurekit_names)
  set(${output_count} "${_anosecurekit_count}" PARENT_SCOPE)
  set(${output_names} "${_anosecurekit_names}" PARENT_SCOPE)
endfunction()

set(_anosecurekit_parity_build "${ANOSECUREKIT_CHECK_ROOT}/full-suite")
# Reconfigure the nested build on every run, but preserve compiled objects for
# practical repeated local release-preflight runs. CI starts from a clean tree.
file(MAKE_DIRECTORY "${ANOSECUREKIT_CHECK_ROOT}")

set(_anosecurekit_configure
  "${CMAKE_COMMAND}"
  -S "${ANOSECUREKIT_SOURCE_DIR}/tests/external_backend"
  -B "${_anosecurekit_parity_build}"
  "-DANOSECUREKIT_SOURCE_DIR=${ANOSECUREKIT_SOURCE_DIR}"
  -DANOSECUREKIT_EXTERNAL_TEST_FULL_SUITE=ON
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_generator_args(_anosecurekit_configure)

if(DEFINED ANOSECUREKIT_GTEST_DIR
    AND NOT ANOSECUREKIT_GTEST_DIR STREQUAL ""
    AND NOT ANOSECUREKIT_GTEST_DIR MATCHES "-NOTFOUND$")
  list(APPEND _anosecurekit_configure "-DGTest_DIR=${ANOSECUREKIT_GTEST_DIR}")
endif()

if(DEFINED ANOSECUREKIT_GOOGLETEST_SOURCE_DIR
    AND NOT ANOSECUREKIT_GOOGLETEST_SOURCE_DIR STREQUAL ""
    AND EXISTS "${ANOSECUREKIT_GOOGLETEST_SOURCE_DIR}/CMakeLists.txt")
  list(APPEND _anosecurekit_configure
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=${ANOSECUREKIT_GOOGLETEST_SOURCE_DIR}")
elseif(EXISTS "${ANOSECUREKIT_PARENT_BUILD_DIR}/_deps/googletest-src/CMakeLists.txt")
  list(APPEND _anosecurekit_configure
    "-DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=${ANOSECUREKIT_PARENT_BUILD_DIR}/_deps/googletest-src")
endif()

execute_process(
  COMMAND ${_anosecurekit_configure}
  RESULT_VARIABLE _anosecurekit_configure_result)
if(NOT _anosecurekit_configure_result EQUAL 0)
  message(FATAL_ERROR "External backend full-suite project configuration failed")
endif()

# PRE_TEST discovery requires the nested test executable to exist before the
# CTest inventory can be compared with the shipped OpenSSL profile.
execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${_anosecurekit_parity_build}"
    --config "${ANOSECUREKIT_BUILD_CONFIG}"
    --parallel "${ANOSECUREKIT_TEST_PARALLEL_LEVEL}"
    --target anosecurekit_tests anosecurekit_cli
  RESULT_VARIABLE _anosecurekit_test_build_result)
if(NOT _anosecurekit_test_build_result EQUAL 0)
  message(FATAL_ERROR "External backend test and CLI build failed")
endif()

_anosecurekit_ctest_inventory(
  "${ANOSECUREKIT_PARENT_BUILD_DIR}"
  _anosecurekit_parent_count
  _anosecurekit_parent_names)
_anosecurekit_ctest_inventory(
  "${_anosecurekit_parity_build}/anosecurekit-community"
  _anosecurekit_external_count
  _anosecurekit_external_names)

if(NOT "${_anosecurekit_parent_count}" EQUAL "${_anosecurekit_external_count}")
  message(FATAL_ERROR
    "External provider test inventory count differs from the OpenSSL profile: "
    "OpenSSL=${_anosecurekit_parent_count}, external=${_anosecurekit_external_count}")
endif()
if(NOT "${_anosecurekit_parent_names}" STREQUAL "${_anosecurekit_external_names}")
  message(FATAL_ERROR
    "External provider test inventory differs from the OpenSSL profile.\n"
    "OpenSSL: ${_anosecurekit_parent_names}\n"
    "External: ${_anosecurekit_external_names}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${_anosecurekit_parity_build}"
    --config "${ANOSECUREKIT_BUILD_CONFIG}"
    --parallel "${ANOSECUREKIT_TEST_PARALLEL_LEVEL}"
    --target external-backend-parity-suite
  RESULT_VARIABLE _anosecurekit_build_result)
if(NOT _anosecurekit_build_result EQUAL 0)
  message(FATAL_ERROR "External backend parity support checks failed")
endif()

set(_anosecurekit_ctest_command
  "${ANOSECUREKIT_CTEST_COMMAND}"
  --test-dir "${_anosecurekit_parity_build}/anosecurekit-community"
  --output-on-failure
  --parallel "${ANOSECUREKIT_TEST_PARALLEL_LEVEL}")
if(DEFINED ANOSECUREKIT_BUILD_CONFIG
    AND NOT ANOSECUREKIT_BUILD_CONFIG STREQUAL "")
  list(APPEND _anosecurekit_ctest_command -C "${ANOSECUREKIT_BUILD_CONFIG}")
endif()
execute_process(
  COMMAND ${_anosecurekit_ctest_command}
  RESULT_VARIABLE _anosecurekit_test_result)
if(NOT _anosecurekit_test_result EQUAL 0)
  message(FATAL_ERROR "External backend full API/fixture/CLI test suite failed")
endif()

message(STATUS
  "External backend parity check passed with ${_anosecurekit_external_count} tests and identical test inventory")
