# SPDX-License-Identifier: MPL-2.0
# Exercise the validator in separate processes: a FATAL_ERROR is the rejection
# contract. Synthetic exports cannot replace checks of the real DSO.
include("${ANOSECUREKIT_SOURCE_DIR}/cmake/check_export_inventory.cmake")
if(DEFINED CASE)
  set(symbols "anosecurekit::verify_file(path)" "anosecurekit::verify_file(stream)")
  if(CASE STREQUAL "missing")
    list(POP_BACK symbols)
  elseif(CASE STREQUAL "unexpected")
    list(APPEND symbols "foreign_export()")
  elseif(CASE STREQUAL "internal")
    list(APPEND symbols "anosecurekit::detail::open_input(path)")
  endif()
  anosecurekit_check_export_inventory("${symbols}" "${TEST_ROOT}/allowlist.txt")
  return()
endif()
file(MAKE_DIRECTORY "${TEST_ROOT}")
file(WRITE "${TEST_ROOT}/allowlist.txt" "2|^anosecurekit::verify_file[(]\n")
foreach(case IN ITEMS valid missing unexpected internal)
  execute_process(COMMAND "${CMAKE_COMMAND}"
    "-DANOSECUREKIT_SOURCE_DIR=${ANOSECUREKIT_SOURCE_DIR}"
    "-DTEST_ROOT=${TEST_ROOT}" "-DCASE=${case}"
    -P "${CMAKE_CURRENT_LIST_FILE}"
    RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE diagnostic)
  if(case STREQUAL "valid")
    if(NOT result EQUAL 0)
      message(FATAL_ERROR "valid inventory rejected: ${diagnostic}")
    endif()
  elseif(result EQUAL 0 OR NOT diagnostic MATCHES "export inventory")
    message(FATAL_ERROR "bad inventory ${case} was not rejected: ${diagnostic}")
  endif()
endforeach()
message(STATUS "Shared export validator rejects missing, unexpected and internal exports")

# Recorded real native output: guards the Apple arm64 ABI expectation separately
# from native execution. It cannot stand in for a Mach-O/library/consumer run.
file(STRINGS "${ANOSECUREKIT_SOURCE_DIR}/tests/abi/macos_arm64_exports.txt" apple_symbols)
list(FILTER apple_symbols EXCLUDE REGEX "^#")
anosecurekit_check_export_inventory("${apple_symbols}"
  "${ANOSECUREKIT_SOURCE_DIR}/cmake/shared_symbol_allowlist_apple_arm64.txt")
