# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  get_filename_component(ANOSECUREKIT_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
endif()

set(_anosecurekit_backend_header
  "${ANOSECUREKIT_SOURCE_DIR}/src/backend/crypto_backend.hpp")
set(_anosecurekit_openssl_provider
  "${ANOSECUREKIT_SOURCE_DIR}/src/backend/crypto_backend_openssl.cpp")

foreach(_anosecurekit_required IN ITEMS
    "${_anosecurekit_backend_header}"
    "${_anosecurekit_openssl_provider}")
  if(NOT EXISTS "${_anosecurekit_required}")
    file(RELATIVE_PATH _anosecurekit_missing_rel
      "${ANOSECUREKIT_SOURCE_DIR}" "${_anosecurekit_required}")
    message(FATAL_ERROR "Missing backend boundary file: ${_anosecurekit_missing_rel}")
  endif()
endforeach()

foreach(_anosecurekit_removed IN ITEMS
    "${ANOSECUREKIT_SOURCE_DIR}/src/crypto_backend.hpp"
    "${ANOSECUREKIT_SOURCE_DIR}/src/crypto_backend.cpp")
  if(EXISTS "${_anosecurekit_removed}")
    file(RELATIVE_PATH _anosecurekit_removed_rel
      "${ANOSECUREKIT_SOURCE_DIR}" "${_anosecurekit_removed}")
    message(FATAL_ERROR
      "Legacy backend file remains outside src/backend: ${_anosecurekit_removed_rel}")
  endif()
endforeach()

file(READ "${_anosecurekit_openssl_provider}" _anosecurekit_provider_text)
string(FIND "${_anosecurekit_provider_text}"
  "#include \"crypto_backend.hpp\"" _anosecurekit_contract_include_at)
if(_anosecurekit_contract_include_at EQUAL -1)
  message(FATAL_ERROR
    "OpenSSL provider must include the colocated crypto_backend.hpp contract")
endif()
string(FIND "${_anosecurekit_provider_text}"
  "#include <openssl/evp.h>" _anosecurekit_openssl_include_at)
if(_anosecurekit_openssl_include_at EQUAL -1)
  message(FATAL_ERROR
    "OpenSSL provider does not contain the expected OpenSSL EVP include")
endif()

file(GLOB_RECURSE _anosecurekit_source_files
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.cpp"
  "${ANOSECUREKIT_SOURCE_DIR}/src/*.hpp")

set(_anosecurekit_violations)
foreach(_anosecurekit_file IN LISTS _anosecurekit_source_files)
  if(_anosecurekit_file STREQUAL _anosecurekit_openssl_provider)
    continue()
  endif()

  file(READ "${_anosecurekit_file}" _anosecurekit_text)
  if(_anosecurekit_text MATCHES
      "openssl/|(^|[^A-Za-z0-9_])(OPENSSL_|EVP_|RAND_|OSSL_)[A-Za-z0-9_]*")
    file(RELATIVE_PATH _anosecurekit_rel
      "${ANOSECUREKIT_SOURCE_DIR}" "${_anosecurekit_file}")
    list(APPEND _anosecurekit_violations "${_anosecurekit_rel}")
  endif()
endforeach()

if(_anosecurekit_violations)
  list(SORT _anosecurekit_violations)
  list(REMOVE_DUPLICATES _anosecurekit_violations)
  string(REPLACE ";" "\n  " _anosecurekit_violation_text
    "${_anosecurekit_violations}")
  message(FATAL_ERROR
    "OpenSSL implementation details leaked outside the OpenSSL provider:\n  ${_anosecurekit_violation_text}")
endif()

message(STATUS "Backend boundary check passed")
