# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  get_filename_component(ANOSECUREKIT_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
endif()

set(_anosecurekit_required_files)
file(GLOB_RECURSE _anosecurekit_cpp_headers
  "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/cli/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fuzz/*.hpp")
file(GLOB_RECURSE _anosecurekit_cpp_sources
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/cli/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fuzz/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/examples/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/benchmarks/*.cpp")
file(GLOB_RECURSE _anosecurekit_cmake_files
  "${ANOSECUREKIT_SOURCE_DIR}/cmake/*.cmake"
  "${ANOSECUREKIT_SOURCE_DIR}/cmake/*.in"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/*.cmake"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/package/*.cmake"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/cli/*.cmake"
  "${ANOSECUREKIT_SOURCE_DIR}/examples/**/CMakeLists.txt")
file(GLOB_RECURSE _anosecurekit_docs
  "${ANOSECUREKIT_SOURCE_DIR}/docs/*.md"
  "${ANOSECUREKIT_SOURCE_DIR}/docs/*.html"
  "${ANOSECUREKIT_SOURCE_DIR}/docs/*.css"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures/*.md"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures/negative/*.md")
file(GLOB_RECURSE _anosecurekit_workflows
  "${ANOSECUREKIT_SOURCE_DIR}/.github/*.yml"
  "${ANOSECUREKIT_SOURCE_DIR}/.github/workflows/*.yml")

list(APPEND _anosecurekit_required_files
  "${ANOSECUREKIT_SOURCE_DIR}/CMakeLists.txt"
  "${ANOSECUREKIT_SOURCE_DIR}/README.md"
  "${ANOSECUREKIT_SOURCE_DIR}/CONTRIBUTING.md"
  "${ANOSECUREKIT_SOURCE_DIR}/SECURITY.md"
  "${ANOSECUREKIT_SOURCE_DIR}/.clang-format"
  "${ANOSECUREKIT_SOURCE_DIR}/.gitignore"
  "${ANOSECUREKIT_SOURCE_DIR}/docs/.nojekyll"
  ${_anosecurekit_cpp_headers}
  ${_anosecurekit_cpp_sources}
  ${_anosecurekit_cmake_files}
  ${_anosecurekit_docs}
  ${_anosecurekit_workflows})

list(REMOVE_DUPLICATES _anosecurekit_required_files)
set(_anosecurekit_missing)
foreach(_anosecurekit_file IN LISTS _anosecurekit_required_files)
  if(NOT EXISTS "${_anosecurekit_file}")
    continue()
  endif()
  if(IS_DIRECTORY "${_anosecurekit_file}")
    continue()
  endif()
  file(STRINGS "${_anosecurekit_file}" _anosecurekit_top_lines LIMIT_COUNT 5 ENCODING UTF-8)
  string(REPLACE ";" "\n" _anosecurekit_top_text "${_anosecurekit_top_lines}")
  string(FIND "${_anosecurekit_top_text}" "SPDX-License-Identifier: MPL-2.0" _anosecurekit_spdx_at)
  if(_anosecurekit_spdx_at EQUAL -1)
    file(RELATIVE_PATH _anosecurekit_rel "${ANOSECUREKIT_SOURCE_DIR}" "${_anosecurekit_file}")
    list(APPEND _anosecurekit_missing "${_anosecurekit_rel}")
  endif()
endforeach()

if(_anosecurekit_missing)
  list(SORT _anosecurekit_missing)
  string(REPLACE ";" "\n  " _anosecurekit_missing_text "${_anosecurekit_missing}")
  message(FATAL_ERROR "Files are missing SPDX-License-Identifier: MPL-2.0:\n  ${_anosecurekit_missing_text}")
endif()

message(STATUS "SPDX license header check passed")
