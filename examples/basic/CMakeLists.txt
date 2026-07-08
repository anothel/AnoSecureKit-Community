# SPDX-License-Identifier: MPL-2.0
cmake_minimum_required(VERSION 3.20)

project(anosecurekit_basic_example LANGUAGES CXX)

find_package(anosecurekit CONFIG REQUIRED)

add_executable(anosecurekit_basic_example main.cpp)
target_compile_features(anosecurekit_basic_example PRIVATE cxx_std_20)
target_link_libraries(anosecurekit_basic_example PRIVATE anosecurekit::anosecurekit)
