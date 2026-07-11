# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  get_filename_component(ANOSECUREKIT_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
endif()

set(_anosecurekit_allowlist
  "docs/RELEASE_NOTES.md"
  "cmake/check_legacy_identifiers.cmake"
  "tests/package/check_release_preflight.cmake")

set(_anosecurekit_text_files)
file(GLOB_RECURSE _anosecurekit_globbed_text
  "${ANOSECUREKIT_SOURCE_DIR}/CMakeLists.txt"
  "${ANOSECUREKIT_SOURCE_DIR}/.clang-format"
  "${ANOSECUREKIT_SOURCE_DIR}/.gitignore"
  "${ANOSECUREKIT_SOURCE_DIR}/.github/*.yml"
  "${ANOSECUREKIT_SOURCE_DIR}/.github/workflows/*.yml"
  "${ANOSECUREKIT_SOURCE_DIR}/benchmarks/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/cmake/*.cmake"
  "${ANOSECUREKIT_SOURCE_DIR}/cmake/*.in"
  "${ANOSECUREKIT_SOURCE_DIR}/docs/*.css"
  "${ANOSECUREKIT_SOURCE_DIR}/docs/*.html"
  "${ANOSECUREKIT_SOURCE_DIR}/docs/*.md"
  "${ANOSECUREKIT_SOURCE_DIR}/examples/**/CMakeLists.txt"
  "${ANOSECUREKIT_SOURCE_DIR}/examples/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/examples/**/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/cli/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/cli/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/*.hpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/**/*.cmake"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fuzz/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures/*.md"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures/negative/*.md")
list(APPEND _anosecurekit_text_files ${_anosecurekit_globbed_text})
list(REMOVE_DUPLICATES _anosecurekit_text_files)

set(_anosecurekit_violations)
foreach(_anosecurekit_file IN LISTS _anosecurekit_text_files)
  if(NOT EXISTS "${_anosecurekit_file}" OR IS_DIRECTORY "${_anosecurekit_file}")
    continue()
  endif()
  file(RELATIVE_PATH _anosecurekit_rel "${ANOSECUREKIT_SOURCE_DIR}" "${_anosecurekit_file}")
  if(NOT _anosecurekit_rel STREQUAL "cmake/check_legacy_identifiers.cmake")
    file(READ "${_anosecurekit_file}" _anosecurekit_text)
    string(TOLOWER "${_anosecurekit_text}" _anosecurekit_lower)
    if(_anosecurekit_lower MATCHES "anothel/anosecurekit([^a-z0-9_-]|$)")
      list(APPEND _anosecurekit_violations "${_anosecurekit_rel}: legacy AnoSecureKit repository URL or slug")
    endif()
  endif()
  list(FIND _anosecurekit_allowlist "${_anosecurekit_rel}" _anosecurekit_allowed_at)
  if(NOT _anosecurekit_allowed_at EQUAL -1)
    continue()
  endif()

  file(STRINGS "${_anosecurekit_file}" _anosecurekit_lines ENCODING UTF-8)
  set(_anosecurekit_line_no 0)
  foreach(_anosecurekit_line IN LISTS _anosecurekit_lines)
    math(EXPR _anosecurekit_line_no "${_anosecurekit_line_no} + 1")
    set(_anosecurekit_norm "${_anosecurekit_line}")
    string(REPLACE "AnoSecureKit" "" _anosecurekit_norm "${_anosecurekit_norm}")
    string(REPLACE "anosecurekit::" "" _anosecurekit_norm "${_anosecurekit_norm}")
    string(REPLACE "include/anosecurekit" "" _anosecurekit_norm "${_anosecurekit_norm}")
    string(REPLACE "ANOSECUREKIT_" "" _anosecurekit_norm "${_anosecurekit_norm}")
    string(REPLACE "anosecurekit file sealing v1" "" _anosecurekit_norm "${_anosecurekit_norm}")

    set(_anosecurekit_bad "")
    if(_anosecurekit_norm MATCHES "(^|[^A-Za-z0-9_])SecureKit([^A-Za-z0-9_]|$)")
      set(_anosecurekit_bad "legacy project name SecureKit")
    elseif(_anosecurekit_norm MATCHES "(^|[^A-Za-z0-9_])securekit::")
      set(_anosecurekit_bad "legacy namespace securekit::")
    elseif(_anosecurekit_norm MATCHES "include/securekit")
      set(_anosecurekit_bad "legacy include root include/securekit")
    elseif(_anosecurekit_norm MATCHES "(^|[^A-Z0-9_])SECUREKIT_")
      set(_anosecurekit_bad "legacy macro prefix SECUREKIT_")
    elseif(_anosecurekit_norm MATCHES "Apache-2\\.0")
      set(_anosecurekit_bad "legacy Apache-2.0 license id")
    elseif(_anosecurekit_norm MATCHES "Apache License")
      set(_anosecurekit_bad "legacy Apache License text")
    elseif(_anosecurekit_norm MATCHES "securekit file sealing v1")
      set(_anosecurekit_bad "legacy SKF1 HKDF label")
    endif()

    if(NOT _anosecurekit_bad STREQUAL "")
      list(APPEND _anosecurekit_violations "${_anosecurekit_rel}:${_anosecurekit_line_no}: ${_anosecurekit_bad}")
    endif()
  endforeach()
endforeach()

if(_anosecurekit_violations)
  list(SORT _anosecurekit_violations)
  string(REPLACE ";" "\n  " _anosecurekit_violations_text "${_anosecurekit_violations}")
  message(FATAL_ERROR "Legacy SecureKit-era identifiers found outside the allowlist:\n  ${_anosecurekit_violations_text}")
endif()

message(STATUS "Legacy identifier check passed")
