# SPDX-License-Identifier: MPL-2.0
if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()
if(NOT DEFINED ANOSECUREKIT_LIBRARY OR ANOSECUREKIT_LIBRARY STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_LIBRARY is required")
endif()
if(NOT EXISTS "${ANOSECUREKIT_LIBRARY}")
  message(FATAL_ERROR "shared library not found: ${ANOSECUREKIT_LIBRARY}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DANOSECUREKIT_SOURCE_DIR=${ANOSECUREKIT_SOURCE_DIR}
    -P ${ANOSECUREKIT_SOURCE_DIR}/cmake/check_shared_symbol_annotations.cmake
  RESULT_VARIABLE annotation_result)
if(NOT annotation_result EQUAL 0)
  message(FATAL_ERROR "shared symbol annotation check failed")
endif()

if(WIN32)
  get_filename_component(linker_dir "${ANOSECUREKIT_LINKER}" DIRECTORY)
  find_program(_dumpbin NAMES dumpbin HINTS "${linker_dir}")
  if(NOT _dumpbin)
    message(FATAL_ERROR "dumpbin is required for the Windows shared symbol gate")
  endif()
  execute_process(
    COMMAND "${_dumpbin}" /nologo /exports "${ANOSECUREKIT_LIBRARY}"
    RESULT_VARIABLE tool_result
    OUTPUT_VARIABLE symbol_output
    ERROR_VARIABLE symbol_error)
  if(NOT tool_result EQUAL 0)
    message(FATAL_ERROR "dumpbin failed: ${symbol_error}")
  endif()
  string(REPLACE "\r" "" symbol_output "${symbol_output}")
  string(REPLACE "\n" ";" symbol_lines "${symbol_output}")
  set(symbols)
  foreach(line IN LISTS symbol_lines)
    # MSVC dumpbin /exports rows: ordinal, hint (hex), RVA (hex), name.
    if(line MATCHES "^[ \t]*[0-9]+[ \t]+[0-9A-Fa-f]+[ \t]+[0-9A-Fa-f]+[ \t]+([^ \t]+)")
      list(APPEND symbols "${CMAKE_MATCH_1}")
    endif()
  endforeach()
  include("${CMAKE_CURRENT_LIST_DIR}/check_export_inventory.cmake")
  anosecurekit_check_export_inventory("${symbols}"
    "${ANOSECUREKIT_SOURCE_DIR}/cmake/shared_symbol_allowlist_msvc.txt")
  return()
endif()

if(NOT DEFINED ANOSECUREKIT_NM OR ANOSECUREKIT_NM STREQUAL "")
  find_program(ANOSECUREKIT_NM NAMES llvm-nm nm)
endif()
if(NOT ANOSECUREKIT_NM)
  message(FATAL_ERROR "nm or llvm-nm is required for the shared symbol gate")
endif()

if(APPLE)
  set(nm_args -gU -C "${ANOSECUREKIT_LIBRARY}")
else()
  set(nm_args -D --defined-only -C "${ANOSECUREKIT_LIBRARY}")
endif()
execute_process(
  COMMAND "${ANOSECUREKIT_NM}" ${nm_args}
  RESULT_VARIABLE tool_result
  OUTPUT_VARIABLE symbol_output
  ERROR_VARIABLE symbol_error)
if(NOT tool_result EQUAL 0)
  message(FATAL_ERROR "nm failed: ${symbol_error}")
endif()

string(REPLACE "\r\n" "\n" symbol_output "${symbol_output}")
string(REPLACE "\r" "\n" symbol_output "${symbol_output}")
string(REPLACE "\n" ";" symbol_lines "${symbol_output}")
set(symbols)
foreach(line IN LISTS symbol_lines)
  string(REGEX MATCH "^[0-9A-Fa-f]+[ \t]+[A-Za-z][ \t]+(.+)$" matched "${line}")
  if(NOT matched STREQUAL "")
    list(APPEND symbols "${CMAKE_MATCH_1}")
  endif()
endforeach()
list(REMOVE_DUPLICATES symbols)
list(SORT symbols)

include("${CMAKE_CURRENT_LIST_DIR}/check_export_inventory.cmake")
set(allowlist "${ANOSECUREKIT_SOURCE_DIR}/cmake/shared_symbol_allowlist.txt")
if(APPLE)
  find_program(ANOSECUREKIT_LIPO NAMES lipo REQUIRED)
  execute_process(COMMAND "${ANOSECUREKIT_LIPO}" -archs "${ANOSECUREKIT_LIBRARY}"
    RESULT_VARIABLE arch_result OUTPUT_VARIABLE library_arch OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(NOT arch_result EQUAL 0)
    message(FATAL_ERROR "cannot identify Mach-O architecture")
  endif()
  if(library_arch STREQUAL "arm64")
    set(allowlist "${ANOSECUREKIT_SOURCE_DIR}/cmake/shared_symbol_allowlist_apple_arm64.txt")
  endif()
endif()
anosecurekit_check_export_inventory("${symbols}" "${allowlist}")

foreach(forbidden IN ITEMS
    "anosecurekit::detail::"
    "anosecurekit::internal::"
    "anosecurekit::internal_aead::"
    "secure_wipe")
  string(FIND "${symbol_output}" "${forbidden}" found)
  if(NOT found EQUAL -1)
    message(FATAL_ERROR "shared library exposes forbidden internal symbol token: ${forbidden}")
  endif()
endforeach()

