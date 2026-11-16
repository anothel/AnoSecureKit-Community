# SPDX-License-Identifier: MPL-2.0
cmake_minimum_required(VERSION 3.20)

project(anosecurekit_consumer LANGUAGES CXX)

find_package(anosecurekit CONFIG REQUIRED)

add_executable(anosecurekit_consumer main.cpp)
target_compile_features(anosecurekit_consumer PRIVATE cxx_std_20)
target_compile_definitions(anosecurekit_consumer PRIVATE
  ANOSECUREKIT_EXPECTED_VERSION="${ANOSECUREKIT_EXPECTED_VERSION}"
  ANOSECUREKIT_EXPECTED_VERSION_MAJOR=${ANOSECUREKIT_EXPECTED_VERSION_MAJOR}
  ANOSECUREKIT_EXPECTED_VERSION_MINOR=${ANOSECUREKIT_EXPECTED_VERSION_MINOR}
  ANOSECUREKIT_EXPECTED_VERSION_PATCH=${ANOSECUREKIT_EXPECTED_VERSION_PATCH})
target_link_libraries(anosecurekit_consumer PRIVATE anosecurekit::anosecurekit)

# Frozen pre-Phase-4 source: verifies old signatures against installed headers.
if(ANOSECUREKIT_TEST_LEGACY_CONSUMER)
  add_executable(anosecurekit_legacy_consumer ../abi/v041_consumer.cpp)
  target_compile_features(anosecurekit_legacy_consumer PRIVATE cxx_std_20)
  get_target_property(consumer_definitions anosecurekit_consumer COMPILE_DEFINITIONS)
  target_compile_definitions(anosecurekit_legacy_consumer PRIVATE ${consumer_definitions})
  target_link_libraries(anosecurekit_legacy_consumer PRIVATE anosecurekit::anosecurekit)
endif()
