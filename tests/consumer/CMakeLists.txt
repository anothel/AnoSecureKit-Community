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
