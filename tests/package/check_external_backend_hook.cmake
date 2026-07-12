# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()
if(NOT DEFINED ANOSECUREKIT_CHECK_ROOT OR ANOSECUREKIT_CHECK_ROOT STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_CHECK_ROOT is required")
endif()
if(NOT IS_ABSOLUTE "${ANOSECUREKIT_SOURCE_DIR}")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR must be absolute")
endif()
if(NOT IS_ABSOLUTE "${ANOSECUREKIT_CHECK_ROOT}")
  message(FATAL_ERROR "ANOSECUREKIT_CHECK_ROOT must be absolute")
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

function(_anosecurekit_expect_configure_failure description expected_text)
  set(_anosecurekit_command ${ARGN})
  execute_process(
    COMMAND ${_anosecurekit_command}
    RESULT_VARIABLE _anosecurekit_result
    OUTPUT_VARIABLE _anosecurekit_stdout
    ERROR_VARIABLE _anosecurekit_stderr)
  if(_anosecurekit_result EQUAL 0)
    message(FATAL_ERROR "${description} unexpectedly succeeded")
  endif()
  set(_anosecurekit_output "${_anosecurekit_stdout}\n${_anosecurekit_stderr}")
  string(FIND "${_anosecurekit_output}" "${expected_text}" _anosecurekit_expected_at)
  if(_anosecurekit_expected_at EQUAL -1)
    message(FATAL_ERROR
      "${description} failed without expected text '${expected_text}':\n${_anosecurekit_output}")
  endif()
endfunction()

set(_anosecurekit_positive_build "${ANOSECUREKIT_CHECK_ROOT}/positive")
set(_anosecurekit_missing_build "${ANOSECUREKIT_CHECK_ROOT}/missing-provider")
set(_anosecurekit_wrong_type_build "${ANOSECUREKIT_CHECK_ROOT}/wrong-provider-type")
set(_anosecurekit_top_level_build "${ANOSECUREKIT_CHECK_ROOT}/top-level")
file(REMOVE_RECURSE "${ANOSECUREKIT_CHECK_ROOT}")
file(MAKE_DIRECTORY "${ANOSECUREKIT_CHECK_ROOT}")

set(_anosecurekit_positive_configure
  "${CMAKE_COMMAND}"
  -S "${ANOSECUREKIT_SOURCE_DIR}/tests/external_backend"
  -B "${_anosecurekit_positive_build}"
  "-DANOSECUREKIT_SOURCE_DIR=${ANOSECUREKIT_SOURCE_DIR}"
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_generator_args(_anosecurekit_positive_configure)
execute_process(
  COMMAND ${_anosecurekit_positive_configure}
  RESULT_VARIABLE _anosecurekit_positive_configure_result)
if(NOT _anosecurekit_positive_configure_result EQUAL 0)
  message(FATAL_ERROR "External backend smoke project configuration failed")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${_anosecurekit_positive_build}"
    --config "${ANOSECUREKIT_BUILD_CONFIG}"
    --target external-backend-smoke-check
  RESULT_VARIABLE _anosecurekit_positive_build_result)
if(NOT _anosecurekit_positive_build_result EQUAL 0)
  message(FATAL_ERROR "External backend smoke project build or execution failed")
endif()

set(_anosecurekit_missing_configure
  "${CMAKE_COMMAND}"
  -S "${ANOSECUREKIT_SOURCE_DIR}/tests/external_backend"
  -B "${_anosecurekit_missing_build}"
  "-DANOSECUREKIT_SOURCE_DIR=${ANOSECUREKIT_SOURCE_DIR}"
  -DANOSECUREKIT_EXTERNAL_TEST_DEFINE_PROVIDER=OFF
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_generator_args(_anosecurekit_missing_configure)
_anosecurekit_expect_configure_failure(
  "Missing external provider target configuration"
  "does not name an existing target"
  ${_anosecurekit_missing_configure})

set(_anosecurekit_wrong_type_configure
  "${CMAKE_COMMAND}"
  -S "${ANOSECUREKIT_SOURCE_DIR}/tests/external_backend"
  -B "${_anosecurekit_wrong_type_build}"
  "-DANOSECUREKIT_SOURCE_DIR=${ANOSECUREKIT_SOURCE_DIR}"
  -DANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE=interface
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_generator_args(_anosecurekit_wrong_type_configure)
_anosecurekit_expect_configure_failure(
  "Wrong external provider target type configuration"
  "must be an OBJECT_LIBRARY target"
  ${_anosecurekit_wrong_type_configure})

set(_anosecurekit_top_level_configure
  "${CMAKE_COMMAND}"
  -S "${ANOSECUREKIT_SOURCE_DIR}"
  -B "${_anosecurekit_top_level_build}"
  -DANOSECUREKIT_CRYPTO_BACKEND=external
  -DANOSECUREKIT_EXTERNAL_BACKEND_TARGET=unused
  -DANOSECUREKIT_BUILD_TESTS=OFF
  -DANOSECUREKIT_BUILD_CLI=OFF
  -DANOSECUREKIT_INSTALL_CLI=OFF
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_generator_args(_anosecurekit_top_level_configure)
_anosecurekit_expect_configure_failure(
  "Top-level external provider configuration"
  "build-tree-only integration hook"
  ${_anosecurekit_top_level_configure})

message(STATUS "External backend hook check passed")
