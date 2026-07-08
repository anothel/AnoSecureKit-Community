# SPDX-License-Identifier: MPL-2.0
if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR)
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PACKAGE_CHECK_ROOT)
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_NAME OR ANOSECUREKIT_PROJECT_NAME STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_NAME is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_VERSION OR ANOSECUREKIT_PROJECT_VERSION STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_VERSION is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_VERSION_MAJOR OR ANOSECUREKIT_PROJECT_VERSION_MAJOR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_VERSION_MAJOR is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_VERSION_MINOR OR ANOSECUREKIT_PROJECT_VERSION_MINOR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_VERSION_MINOR is required")
endif()

if(NOT DEFINED ANOSECUREKIT_PROJECT_VERSION_PATCH OR ANOSECUREKIT_PROJECT_VERSION_PATCH STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_PROJECT_VERSION_PATCH is required")
endif()

if(NOT DEFINED ANOSECUREKIT_BUILD_CONFIG OR ANOSECUREKIT_BUILD_CONFIG STREQUAL "")
  if(DEFINED ANOSECUREKIT_DEFAULT_BUILD_TYPE AND NOT ANOSECUREKIT_DEFAULT_BUILD_TYPE STREQUAL "")
    set(ANOSECUREKIT_BUILD_CONFIG "${ANOSECUREKIT_DEFAULT_BUILD_TYPE}")
  else()
    set(ANOSECUREKIT_BUILD_CONFIG "Release")
  endif()
endif()

if(WIN32)
  set(_anosecurekit_exe_suffix ".exe")
  set(_anosecurekit_path_separator ";")
else()
  set(_anosecurekit_exe_suffix "")
  set(_anosecurekit_path_separator ":")
endif()

set(_anosecurekit_artifact_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/artifacts")
set(_anosecurekit_dogfood_root "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/dogfood")
set(_anosecurekit_extract_dir "${_anosecurekit_dogfood_root}/extract")
set(_anosecurekit_work_dir "${_anosecurekit_dogfood_root}/work")
set(_anosecurekit_consumer_src_dir "${_anosecurekit_dogfood_root}/consumer-src")
set(_anosecurekit_consumer_build_dir "${_anosecurekit_dogfood_root}/consumer-build")

file(GLOB _anosecurekit_binary_archives
  "${_anosecurekit_artifact_dir}/${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-*.zip"
  "${_anosecurekit_artifact_dir}/${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-*.tar.gz")
list(FILTER _anosecurekit_binary_archives EXCLUDE REGEX "-source\\.")
list(SORT _anosecurekit_binary_archives)

list(LENGTH _anosecurekit_binary_archives _anosecurekit_binary_archive_count)
if(_anosecurekit_binary_archive_count EQUAL 0)
  message(FATAL_ERROR "No binary archive found under ${_anosecurekit_artifact_dir}; run package-check first")
endif()
list(GET _anosecurekit_binary_archives 0 _anosecurekit_binary_archive)

file(REMOVE_RECURSE "${_anosecurekit_dogfood_root}")
file(MAKE_DIRECTORY "${_anosecurekit_extract_dir}")
file(MAKE_DIRECTORY "${_anosecurekit_work_dir}")
file(MAKE_DIRECTORY "${_anosecurekit_consumer_src_dir}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar xf "${_anosecurekit_binary_archive}"
  WORKING_DIRECTORY "${_anosecurekit_extract_dir}"
  RESULT_VARIABLE _anosecurekit_extract_result
  ERROR_VARIABLE _anosecurekit_extract_error)
if(NOT _anosecurekit_extract_result EQUAL 0)
  message(FATAL_ERROR "Dogfood archive extraction failed: ${_anosecurekit_extract_error}")
endif()

file(GLOB_RECURSE _anosecurekit_config_files LIST_DIRECTORIES FALSE
  "${_anosecurekit_extract_dir}/*/lib/cmake/anosecurekit/anosecurekitConfig.cmake"
  "${_anosecurekit_extract_dir}/lib/cmake/anosecurekit/anosecurekitConfig.cmake")
list(LENGTH _anosecurekit_config_files _anosecurekit_config_file_count)
if(NOT _anosecurekit_config_file_count EQUAL 1)
  message(FATAL_ERROR "Expected one extracted anosecurekitConfig.cmake, found ${_anosecurekit_config_file_count}")
endif()
list(GET _anosecurekit_config_files 0 _anosecurekit_config_file)
get_filename_component(_anosecurekit_package_dir "${_anosecurekit_config_file}" DIRECTORY)
get_filename_component(_anosecurekit_package_dir "${_anosecurekit_package_dir}" DIRECTORY)
get_filename_component(_anosecurekit_package_dir "${_anosecurekit_package_dir}" DIRECTORY)
get_filename_component(_anosecurekit_package_prefix "${_anosecurekit_package_dir}" DIRECTORY)

set(_anosecurekit_cli "${_anosecurekit_package_prefix}/bin/anosecurekit${_anosecurekit_exe_suffix}")
if(NOT EXISTS "${_anosecurekit_cli}")
  message(FATAL_ERROR "Extracted package is missing CLI: ${_anosecurekit_cli}")
endif()

set(_anosecurekit_path "${_anosecurekit_package_prefix}/bin")
if(WIN32)
  if(DEFINED ANOSECUREKIT_OPENSSL_RUNTIME_DIR AND NOT ANOSECUREKIT_OPENSSL_RUNTIME_DIR STREQUAL "")
    string(APPEND _anosecurekit_path "${_anosecurekit_path_separator}${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}")
  elseif(DEFINED OPENSSL_ROOT_DIR AND NOT OPENSSL_ROOT_DIR STREQUAL "")
    string(APPEND _anosecurekit_path "${_anosecurekit_path_separator}${OPENSSL_ROOT_DIR}/bin")
  endif()
endif()
string(APPEND _anosecurekit_path "${_anosecurekit_path_separator}$ENV{PATH}")

function(_anosecurekit_dogfood_cli description expected_stdout)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_anosecurekit_path}" "${_anosecurekit_cli}" ${ARGN}
    RESULT_VARIABLE _anosecurekit_result
    OUTPUT_VARIABLE _anosecurekit_stdout
    ERROR_VARIABLE _anosecurekit_stderr)
  if(NOT _anosecurekit_result EQUAL 0)
    message(FATAL_ERROR "${description} failed: ${_anosecurekit_stderr}")
  endif()
  string(REPLACE "\r\n" "\n" _anosecurekit_stdout "${_anosecurekit_stdout}")
  if(NOT _anosecurekit_stdout STREQUAL "${expected_stdout}")
    message(FATAL_ERROR "${description} stdout mismatch: [${_anosecurekit_stdout}]")
  endif()
endfunction()

set(_anosecurekit_plain "${_anosecurekit_work_dir}/plain.txt")
set(_anosecurekit_key "${_anosecurekit_work_dir}/key.hex")
set(_anosecurekit_sealed "${_anosecurekit_work_dir}/plain.skf")
set(_anosecurekit_opened "${_anosecurekit_work_dir}/opened.txt")
set(_anosecurekit_password "${_anosecurekit_work_dir}/password.txt")
set(_anosecurekit_password_sealed "${_anosecurekit_work_dir}/plain.skp")
set(_anosecurekit_password_opened "${_anosecurekit_work_dir}/password-opened.txt")

file(WRITE "${_anosecurekit_plain}" "dogfood plaintext\n")
file(WRITE "${_anosecurekit_password}" "dogfood password\n")

_anosecurekit_dogfood_cli("keygen" "" keygen --out "${_anosecurekit_key}")
file(READ "${_anosecurekit_key}" _anosecurekit_key_text)
string(STRIP "${_anosecurekit_key_text}" _anosecurekit_key_text)
string(LENGTH "${_anosecurekit_key_text}" _anosecurekit_key_length)
if(NOT _anosecurekit_key_length EQUAL 64 OR NOT _anosecurekit_key_text MATCHES "^[0-9a-f]+$")
  message(FATAL_ERROR "keygen did not write a 64-hex key: [${_anosecurekit_key_text}]")
endif()

_anosecurekit_dogfood_cli("seal-file" "" seal-file --in "${_anosecurekit_plain}" --out "${_anosecurekit_sealed}" --key-file "${_anosecurekit_key}" --aad-text dogfood:v1)
_anosecurekit_dogfood_cli("verify-file" "" verify-file --in "${_anosecurekit_sealed}" --key-file "${_anosecurekit_key}" --aad-text dogfood:v1)
_anosecurekit_dogfood_cli("open-file" "" open-file --in "${_anosecurekit_sealed}" --out "${_anosecurekit_opened}" --key-file "${_anosecurekit_key}" --aad-text dogfood:v1)
file(READ "${_anosecurekit_opened}" _anosecurekit_opened_text)
if(NOT _anosecurekit_opened_text STREQUAL "dogfood plaintext\n")
  message(FATAL_ERROR "open-file did not recover plaintext: [${_anosecurekit_opened_text}]")
endif()

_anosecurekit_dogfood_cli("seal-file-password" "" seal-file-password --in "${_anosecurekit_plain}" --out "${_anosecurekit_password_sealed}" --password-file "${_anosecurekit_password}" --aad-text dogfood:v1)
_anosecurekit_dogfood_cli("verify-file-password" "" verify-file-password --in "${_anosecurekit_password_sealed}" --password-file "${_anosecurekit_password}" --aad-text dogfood:v1)
_anosecurekit_dogfood_cli("open-file-password" "" open-file-password --in "${_anosecurekit_password_sealed}" --out "${_anosecurekit_password_opened}" --password-file "${_anosecurekit_password}" --aad-text dogfood:v1)
file(READ "${_anosecurekit_password_opened}" _anosecurekit_password_opened_text)
if(NOT _anosecurekit_password_opened_text STREQUAL "dogfood plaintext\n")
  message(FATAL_ERROR "open-file-password did not recover plaintext: [${_anosecurekit_password_opened_text}]")
endif()

file(COPY
  "${ANOSECUREKIT_SOURCE_DIR}/tests/consumer/CMakeLists.txt"
  "${ANOSECUREKIT_SOURCE_DIR}/tests/consumer/main.cpp"
  DESTINATION "${_anosecurekit_consumer_src_dir}")

set(_anosecurekit_consumer_configure_args
  -S "${_anosecurekit_consumer_src_dir}"
  -B "${_anosecurekit_consumer_build_dir}"
  "-DCMAKE_PREFIX_PATH=${_anosecurekit_package_prefix}"
  "-DANOSECUREKIT_EXPECTED_VERSION=${ANOSECUREKIT_PROJECT_VERSION}"
  "-DANOSECUREKIT_EXPECTED_VERSION_MAJOR=${ANOSECUREKIT_PROJECT_VERSION_MAJOR}"
  "-DANOSECUREKIT_EXPECTED_VERSION_MINOR=${ANOSECUREKIT_PROJECT_VERSION_MINOR}"
  "-DANOSECUREKIT_EXPECTED_VERSION_PATCH=${ANOSECUREKIT_PROJECT_VERSION_PATCH}"
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")

if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR AND NOT ANOSECUREKIT_CMAKE_GENERATOR STREQUAL "")
  list(APPEND _anosecurekit_consumer_configure_args -G "${ANOSECUREKIT_CMAKE_GENERATOR}")
endif()
if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM AND NOT ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM STREQUAL "")
  list(APPEND _anosecurekit_consumer_configure_args -A "${ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM}")
endif()
if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET AND NOT ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET STREQUAL "")
  list(APPEND _anosecurekit_consumer_configure_args -T "${ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET}")
endif()
foreach(_anosecurekit_host_var IN ITEMS
    CMAKE_MAKE_PROGRAM
    CMAKE_CXX_COMPILER
    CMAKE_AR
    CMAKE_LINKER
    CMAKE_MT
    CMAKE_RC_COMPILER
    CMAKE_TOOLCHAIN_FILE
    VCPKG_TARGET_TRIPLET
    OPENSSL_ROOT_DIR)
  if(DEFINED ANOSECUREKIT_${_anosecurekit_host_var} AND NOT ANOSECUREKIT_${_anosecurekit_host_var} STREQUAL "")
    list(APPEND _anosecurekit_consumer_configure_args "-D${_anosecurekit_host_var}=${ANOSECUREKIT_${_anosecurekit_host_var}}")
  elseif(DEFINED ${_anosecurekit_host_var} AND NOT ${_anosecurekit_host_var} STREQUAL "")
    list(APPEND _anosecurekit_consumer_configure_args "-D${_anosecurekit_host_var}=${${_anosecurekit_host_var}}")
  endif()
endforeach()

function(_anosecurekit_join_cmdline output_variable)
  set(_anosecurekit_command_line "")
  foreach(_anosecurekit_argument IN LISTS ARGN)
    if(_anosecurekit_argument MATCHES "\"")
      message(FATAL_ERROR "Cannot quote command argument containing double quote: ${_anosecurekit_argument}")
    endif()
    string(APPEND _anosecurekit_command_line " \"${_anosecurekit_argument}\"")
  endforeach()
  set(${output_variable} "${_anosecurekit_command_line}" PARENT_SCOPE)
endfunction()

function(_anosecurekit_run_host_command result_variable script_stem)
  if(_anosecurekit_use_msvc_env)
    _anosecurekit_join_cmdline(_anosecurekit_command_line ${ARGN})
    set(_anosecurekit_script "${_anosecurekit_dogfood_root}/${script_stem}.cmd")
    file(WRITE "${_anosecurekit_script}"
      "@echo off\r\n"
      "call \"${_anosecurekit_vsdevcmd}\" -arch=x64 -host_arch=x64 >nul\r\n"
      "${_anosecurekit_command_line}\r\n"
      "exit /b %ERRORLEVEL%\r\n")
    execute_process(
      COMMAND cmd /S /C "${_anosecurekit_script}"
      RESULT_VARIABLE _anosecurekit_result)
  else()
    execute_process(
      COMMAND ${ARGN}
      RESULT_VARIABLE _anosecurekit_result)
  endif()
  set(${result_variable} "${_anosecurekit_result}" PARENT_SCOPE)
endfunction()

set(_anosecurekit_use_msvc_env FALSE)
if(WIN32
    AND DEFINED ANOSECUREKIT_CMAKE_GENERATOR
    AND ANOSECUREKIT_CMAKE_GENERATOR MATCHES "Ninja"
    AND DEFINED ANOSECUREKIT_CMAKE_CXX_COMPILER
    AND ANOSECUREKIT_CMAKE_CXX_COMPILER MATCHES "[/\\\\]cl\\.exe$"
    AND "$ENV{LIB}" STREQUAL "")
  string(REGEX REPLACE "/VC/Tools/MSVC/[^/]+/bin/[^/]+/[^/]+/cl\\.exe$" ""
    _anosecurekit_vs_root "${ANOSECUREKIT_CMAKE_CXX_COMPILER}")
  set(_anosecurekit_vsdevcmd "${_anosecurekit_vs_root}/Common7/Tools/VsDevCmd.bat")
  if(EXISTS "${_anosecurekit_vsdevcmd}")
    set(_anosecurekit_use_msvc_env TRUE)
  endif()
endif()

_anosecurekit_run_host_command(
  _anosecurekit_consumer_configure_result
  dogfood-consumer-configure
  "${CMAKE_COMMAND}"
  ${_anosecurekit_consumer_configure_args})
if(NOT _anosecurekit_consumer_configure_result EQUAL 0)
  message(FATAL_ERROR "Dogfood consumer configure failed")
endif()

_anosecurekit_run_host_command(
  _anosecurekit_consumer_build_result
  dogfood-consumer-build
  "${CMAKE_COMMAND}"
  --build "${_anosecurekit_consumer_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}")
if(NOT _anosecurekit_consumer_build_result EQUAL 0)
  message(FATAL_ERROR "Dogfood consumer build failed")
endif()

set(_anosecurekit_consumer_candidates
  "${_anosecurekit_consumer_build_dir}/${ANOSECUREKIT_BUILD_CONFIG}/anosecurekit_consumer${_anosecurekit_exe_suffix}"
  "${_anosecurekit_consumer_build_dir}/anosecurekit_consumer${_anosecurekit_exe_suffix}")
set(_anosecurekit_consumer_exe "")
foreach(_anosecurekit_consumer_candidate IN LISTS _anosecurekit_consumer_candidates)
  if(EXISTS "${_anosecurekit_consumer_candidate}")
    set(_anosecurekit_consumer_exe "${_anosecurekit_consumer_candidate}")
    break()
  endif()
endforeach()
if(_anosecurekit_consumer_exe STREQUAL "")
  message(FATAL_ERROR "Dogfood consumer executable not found under ${_anosecurekit_consumer_build_dir}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_anosecurekit_path}" "${_anosecurekit_consumer_exe}"
  RESULT_VARIABLE _anosecurekit_consumer_run_result)
if(NOT _anosecurekit_consumer_run_result EQUAL 0)
  message(FATAL_ERROR "Dogfood consumer run failed")
endif()

file(WRITE "${_anosecurekit_dogfood_root}/DOGFOOD_RESULT.txt"
  "AnoSecureKit ${ANOSECUREKIT_PROJECT_VERSION} dogfood check passed.\n"
  "Archive: ${_anosecurekit_binary_archive}\n"
  "CLI flows: keygen, seal-file/open-file/verify-file, password file flow.\n"
  "C++ API: copied external consumer configured, built, and ran from extracted package.\n")
