# SPDX-License-Identifier: MPL-2.0
if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()

function(_read path out)
  set(full "${ANOSECUREKIT_SOURCE_DIR}/${path}")
  if(NOT EXISTS "${full}")
    message(FATAL_ERROR "shared symbol annotation check missing ${path}")
  endif()
  file(READ "${full}" text)
  set(${out} "${text}" PARENT_SCOPE)
endfunction()

_read("CMakeLists.txt" cmakelists)
_read("include/anosecurekit/export.hpp" export_header)
_read("include/anosecurekit/error.hpp" error_header)
_read("cmake/shared_symbol_allowlist.txt" allowlist)

foreach(required IN ITEMS
    "CXX_VISIBILITY_PRESET hidden"
    "VISIBILITY_INLINES_HIDDEN YES"
    "shared-symbol-check"
    "shared-package-check")
  string(FIND "${cmakelists}" "${required}" found)
  if(found EQUAL -1)
    message(FATAL_ERROR "shared symbol annotation check missing CMake policy: ${required}")
  endif()
endforeach()

foreach(required IN ITEMS
    "__declspec(dllexport)"
    "__declspec(dllimport)"
    "__attribute__((visibility(\"default\")))")
  string(FIND "${export_header}" "${required}" found)
  if(found EQUAL -1)
    message(FATAL_ERROR "shared symbol annotation check missing export policy: ${required}")
  endif()
endforeach()

string(FIND "${error_header}" "class ANOSECUREKIT_API error" error_export)
if(error_export EQUAL -1)
  message(FATAL_ERROR "anosecurekit::error must be class-exported for cross-DSO exception RTTI")
endif()

file(GLOB_RECURSE internal_headers
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.hpp")
foreach(header IN LISTS internal_headers)
  file(READ "${header}" text)
  string(FIND "${text}" "ANOSECUREKIT_API" found)
  if(NOT found EQUAL -1)
    file(RELATIVE_PATH rel "${ANOSECUREKIT_SOURCE_DIR}" "${header}")
    message(FATAL_ERROR "internal header exposes ANOSECUREKIT_API: ${rel}")
  endif()
endforeach()

foreach(required IN ITEMS
    "verify_file"
    "verify_file_with_password"
    "packet_encryptor"
    "packet_decryptor"
    "typeinfo for anosecurekit::error")
  string(FIND "${allowlist}" "${required}" found)
  if(found EQUAL -1)
    message(FATAL_ERROR "shared symbol allowlist missing reviewed public surface: ${required}")
  endif()
endforeach()

message(STATUS "AnoSecureKit shared symbol annotation check passed")
