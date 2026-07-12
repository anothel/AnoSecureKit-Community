# SPDX-License-Identifier: MPL-2.0
cmake_minimum_required(VERSION 3.20)

project(anosecurekit_external_backend_smoke LANGUAGES CXX)

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()

option(ANOSECUREKIT_EXTERNAL_TEST_DEFINE_PROVIDER
  "Define the external provider target for the smoke test" ON)
option(ANOSECUREKIT_EXTERNAL_TEST_FULL_SUITE
  "Build the full Community API, fixture, and CLI suite through the external provider seam" OFF)
set(ANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE "object" CACHE STRING
  "Provider target type used by negative configuration tests")
set_property(CACHE ANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE PROPERTY STRINGS object interface)

find_package(OpenSSL 3.0 REQUIRED COMPONENTS Crypto)

if(ANOSECUREKIT_EXTERNAL_TEST_DEFINE_PROVIDER)
  if(ANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE STREQUAL "object")
    add_library(anosecurekit_external_test_provider OBJECT
      "${ANOSECUREKIT_SOURCE_DIR}/src/backend/crypto_backend_openssl.cpp")
    target_link_libraries(anosecurekit_external_test_provider PRIVATE OpenSSL::Crypto)
  elseif(ANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE STREQUAL "interface")
    add_library(anosecurekit_external_test_provider INTERFACE)
  else()
    message(FATAL_ERROR
      "Unsupported ANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE='${ANOSECUREKIT_EXTERNAL_TEST_PROVIDER_TYPE}'")
  endif()
endif()

if(ANOSECUREKIT_EXTERNAL_TEST_FULL_SUITE)
  set(BUILD_TESTING ON CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_TESTS ON CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_CLI ON CACHE BOOL "" FORCE)
else()
  set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_CLI OFF CACHE BOOL "" FORCE)
endif()
set(ANOSECUREKIT_INSTALL_CLI OFF CACHE BOOL "" FORCE)
set(ANOSECUREKIT_BUILD_FUZZ OFF CACHE BOOL "" FORCE)
set(ANOSECUREKIT_CRYPTO_BACKEND external CACHE STRING "" FORCE)
set(ANOSECUREKIT_EXTERNAL_BACKEND_TARGET
  anosecurekit_external_test_provider CACHE STRING "" FORCE)

add_subdirectory("${ANOSECUREKIT_SOURCE_DIR}" anosecurekit-community)

add_executable(anosecurekit_external_backend_smoke main.cpp)
target_compile_features(anosecurekit_external_backend_smoke PRIVATE cxx_std_20)
target_link_libraries(anosecurekit_external_backend_smoke PRIVATE
  anosecurekit::anosecurekit)

if(WIN32
    AND DEFINED ANOSECUREKIT_OPENSSL_RUNTIME_DIR
    AND NOT ANOSECUREKIT_OPENSSL_RUNTIME_DIR STREQUAL "")
  add_custom_command(TARGET anosecurekit_external_backend_smoke POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      "${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}"
      "$<TARGET_FILE_DIR:anosecurekit_external_backend_smoke>")
endif()

add_custom_target(external-backend-smoke-check
  COMMAND $<TARGET_FILE:anosecurekit_external_backend_smoke>
  DEPENDS anosecurekit_external_backend_smoke
  USES_TERMINAL)

if(ANOSECUREKIT_EXTERNAL_TEST_FULL_SUITE)
  add_custom_target(external-backend-parity-suite
    DEPENDS
      examples-check
      benchmarks-check
      cli-docs-check
      backend-boundary-check
      spdx-check
      legacy-name-check
      external-backend-smoke-check)
endif()
