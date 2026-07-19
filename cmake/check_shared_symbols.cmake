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
  find_program(_dumpbin NAMES dumpbin)
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
  foreach(forbidden IN ITEMS
      "@detail@anosecurekit@@"
      "@internal@anosecurekit@@"
      "@internal_aead@anosecurekit@@"
      "secure_wipe")
    string(FIND "${symbol_output}" "${forbidden}" found)
    if(NOT found EQUAL -1)
      message(FATAL_ERROR "Windows DLL exposes forbidden internal symbol token: ${forbidden}")
    endif()
  endforeach()
  foreach(required IN ITEMS
      "verify_file"
      "verify_file_with_password"
      "packet_encryptor"
      "packet_decryptor"
      "random_bytes")
    string(FIND "${symbol_output}" "${required}" found)
    if(found EQUAL -1)
      message(FATAL_ERROR "Windows DLL is missing reviewed public symbol token: ${required}")
    endif()
  endforeach()
  message(STATUS "AnoSecureKit Windows shared symbol gate passed")
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

set(allowlist_file "${ANOSECUREKIT_SOURCE_DIR}/cmake/shared_symbol_allowlist.txt")
file(STRINGS "${allowlist_file}" rules)
set(expected_total 0)
set(matched_symbols)
foreach(rule IN LISTS rules)
  if(rule STREQUAL "" OR rule MATCHES "^#")
    continue()
  endif()
  string(FIND "${rule}" "|" separator)
  if(separator EQUAL -1)
    message(FATAL_ERROR "invalid shared symbol allowlist rule: ${rule}")
  endif()
  string(SUBSTRING "${rule}" 0 ${separator} expected)
  math(EXPR regex_start "${separator} + 1")
  string(SUBSTRING "${rule}" ${regex_start} -1 regex)
  set(count 0)
  foreach(symbol IN LISTS symbols)
    if(symbol MATCHES "${regex}")
      math(EXPR count "${count} + 1")
      list(APPEND matched_symbols "${symbol}")
    endif()
  endforeach()
  if(NOT count EQUAL expected)
    message(FATAL_ERROR "shared symbol rule expected ${expected}, found ${count}: ${regex}")
  endif()
  math(EXPR expected_total "${expected_total} + ${expected}")
endforeach()
list(REMOVE_DUPLICATES matched_symbols)
list(LENGTH symbols actual_total)
list(LENGTH matched_symbols matched_total)
if(NOT actual_total EQUAL expected_total OR NOT matched_total EQUAL expected_total)
  set(unexpected ${symbols})
  foreach(symbol IN LISTS matched_symbols)
    list(REMOVE_ITEM unexpected "${symbol}")
  endforeach()
  list(JOIN unexpected "\n  " unexpected_text)
  message(FATAL_ERROR
    "shared symbol allowlist mismatch: expected ${expected_total}, actual ${actual_total}, matched ${matched_total}\n  ${unexpected_text}")
endif()

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

message(STATUS "AnoSecureKit shared symbol allowlist passed: ${actual_total} unique public symbols")
