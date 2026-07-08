# SPDX-License-Identifier: MPL-2.0
if(DEFINED ANOSECUREKIT_PACKAGE_ARTIFACT_DIR AND NOT ANOSECUREKIT_PACKAGE_ARTIFACT_DIR STREQUAL "")
  set(_anosecurekit_artifact_dir "${ANOSECUREKIT_PACKAGE_ARTIFACT_DIR}")
  get_filename_component(_anosecurekit_package_check_root "${_anosecurekit_artifact_dir}" DIRECTORY)
elseif(DEFINED ANOSECUREKIT_PACKAGE_CHECK_ROOT AND NOT ANOSECUREKIT_PACKAGE_CHECK_ROOT STREQUAL "")
  set(_anosecurekit_package_check_root "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}")
  set(_anosecurekit_artifact_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/artifacts")
else()
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT or ANOSECUREKIT_PACKAGE_ARTIFACT_DIR is required")
endif()

if(NOT IS_ABSOLUTE "${_anosecurekit_package_check_root}")
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT must be absolute")
endif()
set(_anosecurekit_package_check_root_name_path "${_anosecurekit_package_check_root}")
cmake_path(NORMAL_PATH _anosecurekit_package_check_root_name_path)
cmake_path(GET _anosecurekit_package_check_root_name_path FILENAME _anosecurekit_package_check_root_name)
if(NOT _anosecurekit_package_check_root_name STREQUAL "package-check")
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT must end in package-check")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_NAME OR ANOSECUREKIT_PROJECT_NAME STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_NAME is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_VERSION OR ANOSECUREKIT_PROJECT_VERSION STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_VERSION is required")
endif()

if(NOT IS_DIRECTORY "${_anosecurekit_artifact_dir}")
  message(FATAL_ERROR "Package artifact directory not found: ${_anosecurekit_artifact_dir}")
endif()

set(_anosecurekit_release_asset_dir "${_anosecurekit_package_check_root}/release-assets")
set(_anosecurekit_artifact_prefix "${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-")
set(_anosecurekit_source_prefix "${_anosecurekit_artifact_prefix}source.")
set(_anosecurekit_source_zip_artifact "${_anosecurekit_artifact_dir}/${_anosecurekit_artifact_prefix}source.zip")
set(_anosecurekit_source_tgz_artifact "${_anosecurekit_artifact_dir}/${_anosecurekit_artifact_prefix}source.tar.gz")

file(GLOB _anosecurekit_artifacts LIST_DIRECTORIES FALSE
  "${_anosecurekit_artifact_dir}/*")
list(SORT _anosecurekit_artifacts)
list(LENGTH _anosecurekit_artifacts _anosecurekit_artifact_count)
if(_anosecurekit_artifact_count EQUAL 0)
  message(FATAL_ERROR "No package artifacts found under ${_anosecurekit_artifact_dir}")
endif()

set(_anosecurekit_source_artifacts)
set(_anosecurekit_binary_artifacts)
set(_anosecurekit_has_binary_zip OFF)
set(_anosecurekit_has_binary_tgz OFF)

foreach(_anosecurekit_artifact IN LISTS _anosecurekit_artifacts)
  get_filename_component(_anosecurekit_artifact_name "${_anosecurekit_artifact}" NAME)

  string(FIND
    "${_anosecurekit_artifact_name}"
    "${_anosecurekit_artifact_prefix}"
    _anosecurekit_artifact_prefix_at)
  if(NOT _anosecurekit_artifact_prefix_at EQUAL 0)
    message(FATAL_ERROR "Package artifact version mismatch: ${_anosecurekit_artifact_name}")
  endif()

  if(NOT _anosecurekit_artifact_name MATCHES "(\\.zip|\\.tar\\.gz)$")
    message(FATAL_ERROR "Package artifact extension mismatch: ${_anosecurekit_artifact_name}")
  endif()

  string(FIND
    "${_anosecurekit_artifact_name}"
    "${_anosecurekit_source_prefix}"
    _anosecurekit_source_prefix_at)
  string(FIND
    "${_anosecurekit_artifact_name}"
    "-source."
    _anosecurekit_source_marker_at)

  if(_anosecurekit_source_prefix_at EQUAL 0)
    list(APPEND _anosecurekit_source_artifacts "${_anosecurekit_artifact}")
  elseif(NOT _anosecurekit_source_marker_at EQUAL -1)
    message(FATAL_ERROR "Package source artifact name mismatch: ${_anosecurekit_artifact_name}")
  else()
    list(APPEND _anosecurekit_binary_artifacts "${_anosecurekit_artifact}")
    if(_anosecurekit_artifact_name MATCHES "\\.zip$")
      set(_anosecurekit_has_binary_zip ON)
    elseif(_anosecurekit_artifact_name MATCHES "\\.tar\\.gz$")
      set(_anosecurekit_has_binary_tgz ON)
    endif()
  endif()
endforeach()

list(LENGTH _anosecurekit_binary_artifacts _anosecurekit_binary_artifact_count)
if(_anosecurekit_binary_artifact_count EQUAL 0)
  message(FATAL_ERROR "No binary package artifacts found for ${ANOSECUREKIT_PROJECT_VERSION}")
endif()
if(NOT _anosecurekit_has_binary_zip)
  message(FATAL_ERROR "No binary ZIP package artifact found for ${ANOSECUREKIT_PROJECT_VERSION}")
endif()
if(NOT _anosecurekit_has_binary_tgz)
  message(FATAL_ERROR "No binary TGZ package artifact found for ${ANOSECUREKIT_PROJECT_VERSION}")
endif()

list(LENGTH _anosecurekit_source_artifacts _anosecurekit_source_artifact_count)
if(_anosecurekit_source_artifact_count EQUAL 0)
  message(FATAL_ERROR "No source package artifacts found for ${ANOSECUREKIT_PROJECT_VERSION}")
endif()
if(NOT EXISTS "${_anosecurekit_source_zip_artifact}")
  message(FATAL_ERROR "Source ZIP package artifact not found: ${_anosecurekit_source_zip_artifact}")
endif()
if(NOT EXISTS "${_anosecurekit_source_tgz_artifact}")
  message(FATAL_ERROR "Source TGZ package artifact not found: ${_anosecurekit_source_tgz_artifact}")
endif()

file(REMOVE_RECURSE "${_anosecurekit_release_asset_dir}")
file(MAKE_DIRECTORY "${_anosecurekit_release_asset_dir}")

set(_anosecurekit_staged_names)

foreach(_anosecurekit_source_artifact IN LISTS _anosecurekit_source_artifacts)
  get_filename_component(_anosecurekit_source_name "${_anosecurekit_source_artifact}" NAME)
  list(FIND _anosecurekit_staged_names "${_anosecurekit_source_name}" _anosecurekit_existing_stage_name_at)
  if(NOT _anosecurekit_existing_stage_name_at EQUAL -1)
    message(FATAL_ERROR "Duplicate staged release asset name: ${_anosecurekit_source_name}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${_anosecurekit_source_artifact}"
      "${_anosecurekit_release_asset_dir}/${_anosecurekit_source_name}"
    RESULT_VARIABLE _anosecurekit_stage_source_result)
  if(NOT _anosecurekit_stage_source_result EQUAL 0)
    message(FATAL_ERROR "Failed to stage source release asset: ${_anosecurekit_source_name}")
  endif()
  list(APPEND _anosecurekit_staged_names "${_anosecurekit_source_name}")
endforeach()

foreach(_anosecurekit_binary_artifact IN LISTS _anosecurekit_binary_artifacts)
  get_filename_component(_anosecurekit_binary_name "${_anosecurekit_binary_artifact}" NAME)
  set(_anosecurekit_staged_name "local-package-${_anosecurekit_binary_name}")
  list(FIND _anosecurekit_staged_names "${_anosecurekit_staged_name}" _anosecurekit_existing_stage_name_at)
  if(NOT _anosecurekit_existing_stage_name_at EQUAL -1)
    message(FATAL_ERROR "Duplicate staged release asset name: ${_anosecurekit_staged_name}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${_anosecurekit_binary_artifact}"
      "${_anosecurekit_release_asset_dir}/${_anosecurekit_staged_name}"
    RESULT_VARIABLE _anosecurekit_stage_binary_result)
  if(NOT _anosecurekit_stage_binary_result EQUAL 0)
    message(FATAL_ERROR "Failed to stage binary release asset: ${_anosecurekit_staged_name}")
  endif()
  list(APPEND _anosecurekit_staged_names "${_anosecurekit_staged_name}")
endforeach()

list(SORT _anosecurekit_staged_names)
set(_anosecurekit_sbom_name "${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-release.spdx.json")
set(_anosecurekit_sbom_file "${_anosecurekit_release_asset_dir}/${_anosecurekit_sbom_name}")
string(TIMESTAMP _anosecurekit_sbom_created "%Y-%m-%dT%H:%M:%SZ" UTC)
file(WRITE "${_anosecurekit_sbom_file}"
  "{\n"
  "  \"spdxVersion\": \"SPDX-2.3\",\n"
  "  \"dataLicense\": \"CC0-1.0\",\n"
  "  \"SPDXID\": \"SPDXRef-DOCUMENT\",\n"
  "  \"name\": \"${ANOSECUREKIT_PROJECT_NAME} ${ANOSECUREKIT_PROJECT_VERSION} release assets\",\n"
  "  \"documentNamespace\": \"https://github.com/anothel/anosecurekit/releases/tag/v${ANOSECUREKIT_PROJECT_VERSION}/sbom\",\n"
  "  \"creationInfo\": {\n"
  "    \"created\": \"${_anosecurekit_sbom_created}\",\n"
  "    \"creators\": [\"Tool: AnoSecureKit release-preflight\"]\n"
  "  },\n"
  "  \"packages\": [\n")
set(_anosecurekit_sbom_separator "")
foreach(_anosecurekit_staged_name IN LISTS _anosecurekit_staged_names)
  file(SHA256
    "${_anosecurekit_release_asset_dir}/${_anosecurekit_staged_name}"
    _anosecurekit_staged_sha256)
  string(REGEX REPLACE "[^A-Za-z0-9.-]" "-" _anosecurekit_spdx_id "${_anosecurekit_staged_name}")
  file(APPEND "${_anosecurekit_sbom_file}"
    "${_anosecurekit_sbom_separator}"
    "    {\n"
    "      \"name\": \"${_anosecurekit_staged_name}\",\n"
    "      \"SPDXID\": \"SPDXRef-Package-${_anosecurekit_spdx_id}\",\n"
    "      \"downloadLocation\": \"NOASSERTION\",\n"
    "      \"filesAnalyzed\": false,\n"
    "      \"checksums\": [{\"algorithm\": \"SHA256\", \"checksumValue\": \"${_anosecurekit_staged_sha256}\"}],\n"
    "      \"licenseConcluded\": \"NOASSERTION\",\n"
    "      \"licenseDeclared\": \"NOASSERTION\",\n"
    "      \"copyrightText\": \"NOASSERTION\"\n"
    "    }")
  set(_anosecurekit_sbom_separator ",\n")
endforeach()
file(APPEND "${_anosecurekit_sbom_file}"
  "\n"
  "  ]\n"
  "}\n")

if(NOT EXISTS "${_anosecurekit_sbom_file}")
  message(FATAL_ERROR "Release SBOM not found: ${_anosecurekit_sbom_file}")
endif()
list(APPEND _anosecurekit_staged_names "${_anosecurekit_sbom_name}")

set(_anosecurekit_checksum_file "${_anosecurekit_release_asset_dir}/SHA256SUMS.txt")
file(WRITE "${_anosecurekit_checksum_file}" "")

foreach(_anosecurekit_staged_name IN LISTS _anosecurekit_staged_names)
  file(SHA256
    "${_anosecurekit_release_asset_dir}/${_anosecurekit_staged_name}"
    _anosecurekit_staged_sha256)
  file(APPEND
    "${_anosecurekit_checksum_file}"
    "${_anosecurekit_staged_sha256}  ${_anosecurekit_staged_name}\n")
endforeach()

file(STRINGS "${_anosecurekit_checksum_file}" _anosecurekit_checksum_lines)
list(LENGTH _anosecurekit_staged_names _anosecurekit_staged_count)
list(LENGTH _anosecurekit_checksum_lines _anosecurekit_checksum_line_count)
if(NOT _anosecurekit_checksum_line_count EQUAL _anosecurekit_staged_count)
  message(FATAL_ERROR "SHA256SUMS.txt line count does not match staged release asset count")
endif()

foreach(_anosecurekit_checksum_line IN LISTS _anosecurekit_checksum_lines)
  if(NOT _anosecurekit_checksum_line MATCHES "^([0-9a-f]+)  (.+\\.(zip|tar\\.gz|spdx\\.json))$")
    message(FATAL_ERROR "SHA256SUMS.txt line format mismatch: ${_anosecurekit_checksum_line}")
  endif()
  string(LENGTH "${CMAKE_MATCH_1}" _anosecurekit_checksum_hash_length)
  if(NOT _anosecurekit_checksum_hash_length EQUAL 64)
    message(FATAL_ERROR "SHA256SUMS.txt hash length mismatch: ${_anosecurekit_checksum_line}")
  endif()
  if(_anosecurekit_checksum_line MATCHES "  SHA256SUMS\\.txt$")
    message(FATAL_ERROR "SHA256SUMS.txt must not include itself")
  endif()
endforeach()
