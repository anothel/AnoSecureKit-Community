# SPDX-License-Identifier: MPL-2.0
if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR)
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()

if(NOT DEFINED ANOSECUREKIT_BUILD_DIR)
  message(FATAL_ERROR "ANOSECUREKIT_BUILD_DIR is required")
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

if(NOT IS_ABSOLUTE "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}")
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT must be absolute")
endif()
set(_anosecurekit_package_check_root_name_path "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}")
cmake_path(NORMAL_PATH _anosecurekit_package_check_root_name_path)
cmake_path(GET _anosecurekit_package_check_root_name_path FILENAME _anosecurekit_package_check_root_name)
if(NOT _anosecurekit_package_check_root_name STREQUAL "package-check")
  message(FATAL_ERROR "ANOSECUREKIT_PACKAGE_CHECK_ROOT must end in package-check")
endif()

set(_anosecurekit_install_prefix "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/install")
set(_anosecurekit_artifact_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/artifacts")
set(_anosecurekit_consumer_build_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/consumer-build")
set(_anosecurekit_source_extract_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/source-extract")
set(_anosecurekit_source_build_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/source-build")
set(_anosecurekit_source_install_prefix "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/source-install")
set(_anosecurekit_library_only_build_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/library-only-build")
set(_anosecurekit_library_only_install_prefix "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/library-only-install")
set(_anosecurekit_library_only_consumer_build_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/library-only-consumer-build")

file(REMOVE_RECURSE "${_anosecurekit_install_prefix}")
file(REMOVE_RECURSE "${_anosecurekit_artifact_dir}")
file(REMOVE_RECURSE "${_anosecurekit_consumer_build_dir}")
file(REMOVE_RECURSE "${_anosecurekit_source_extract_dir}")
file(REMOVE_RECURSE "${_anosecurekit_source_build_dir}")
file(REMOVE_RECURSE "${_anosecurekit_source_install_prefix}")
file(REMOVE_RECURSE "${_anosecurekit_library_only_build_dir}")
file(REMOVE_RECURSE "${_anosecurekit_library_only_install_prefix}")
file(REMOVE_RECURSE "${_anosecurekit_library_only_consumer_build_dir}")
file(MAKE_DIRECTORY "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}")
file(MAKE_DIRECTORY "${_anosecurekit_artifact_dir}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" --install "${ANOSECUREKIT_BUILD_DIR}" --config "${ANOSECUREKIT_BUILD_CONFIG}" --prefix "${_anosecurekit_install_prefix}"
  RESULT_VARIABLE _anosecurekit_install_result)
if(NOT _anosecurekit_install_result EQUAL 0)
  message(FATAL_ERROR "Package install failed")
endif()

if(WIN32)
  set(_anosecurekit_exe_suffix ".exe")
  set(_anosecurekit_path_separator ";")
else()
  set(_anosecurekit_exe_suffix "")
  set(_anosecurekit_path_separator ":")
endif()

if(NOT DEFINED ANOSECUREKIT_CPACK_COMMAND OR ANOSECUREKIT_CPACK_COMMAND STREQUAL "")
  get_filename_component(_anosecurekit_cmake_dir "${CMAKE_COMMAND}" DIRECTORY)
  set(ANOSECUREKIT_CPACK_COMMAND "${_anosecurekit_cmake_dir}/cpack${_anosecurekit_exe_suffix}")
endif()

function(_anosecurekit_require_archive_member archive_path member_regex)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar tf "${archive_path}"
    RESULT_VARIABLE _anosecurekit_tar_result
    OUTPUT_VARIABLE _anosecurekit_tar_output
    ERROR_VARIABLE _anosecurekit_tar_error)
  if(NOT _anosecurekit_tar_result EQUAL 0)
    message(FATAL_ERROR "Failed to list archive ${archive_path}: ${_anosecurekit_tar_error}")
  endif()
  if(NOT _anosecurekit_tar_output MATCHES "${member_regex}")
    message(FATAL_ERROR "Archive ${archive_path} is missing member matching ${member_regex}")
  endif()
endfunction()

function(_anosecurekit_forbid_archive_member archive_path member_regex)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar tf "${archive_path}"
    RESULT_VARIABLE _anosecurekit_tar_result
    OUTPUT_VARIABLE _anosecurekit_tar_output
    ERROR_VARIABLE _anosecurekit_tar_error)
  if(NOT _anosecurekit_tar_result EQUAL 0)
    message(FATAL_ERROR "Failed to list archive ${archive_path}: ${_anosecurekit_tar_error}")
  endif()
  if(_anosecurekit_tar_output MATCHES "${member_regex}")
    message(FATAL_ERROR "Archive ${archive_path} includes forbidden member matching ${member_regex}")
  endif()
endfunction()

set(_anosecurekit_cli "${_anosecurekit_install_prefix}/bin/anosecurekit${_anosecurekit_exe_suffix}")
string(TOLOWER "${ANOSECUREKIT_BUILD_CONFIG}" _anosecurekit_build_config_lower)
set(_anosecurekit_target_files
  "${_anosecurekit_install_prefix}/lib/cmake/anosecurekit/anosecurekitTargets-${ANOSECUREKIT_BUILD_CONFIG}.cmake"
  "${_anosecurekit_install_prefix}/lib/cmake/anosecurekit/anosecurekitTargets-${_anosecurekit_build_config_lower}.cmake")

set(_anosecurekit_found_target_file FALSE)
foreach(_anosecurekit_target_file IN LISTS _anosecurekit_target_files)
  if(EXISTS "${_anosecurekit_target_file}")
    set(_anosecurekit_found_target_file TRUE)
    break()
  endif()
endforeach()
if(NOT _anosecurekit_found_target_file)
  message(FATAL_ERROR "Missing package target files under ${_anosecurekit_install_prefix}/lib/cmake/anosecurekit")
endif()

foreach(_anosecurekit_package_file
    "${_anosecurekit_cli}"
    "${_anosecurekit_install_prefix}/lib/cmake/anosecurekit/anosecurekitConfig.cmake"
    "${_anosecurekit_install_prefix}/lib/cmake/anosecurekit/anosecurekitConfigVersion.cmake"
    "${_anosecurekit_install_prefix}/lib/cmake/anosecurekit/anosecurekitTargets.cmake")
  if(NOT EXISTS "${_anosecurekit_package_file}")
    message(FATAL_ERROR "Missing package file: ${_anosecurekit_package_file}")
  endif()
endforeach()

file(GLOB _anosecurekit_export_files
  "${_anosecurekit_install_prefix}/lib/cmake/anosecurekit/anosecurekitTargets*.cmake")
foreach(_anosecurekit_export_file IN LISTS _anosecurekit_export_files)
  file(READ "${_anosecurekit_export_file}" _anosecurekit_export_text)
  if(_anosecurekit_export_text MATCHES "(-Werror|/WX)")
    message(FATAL_ERROR "Warnings-as-errors leaked into exported target: ${_anosecurekit_export_file}")
  endif()
endforeach()

set(_anosecurekit_path "$ENV{PATH}")
if(WIN32)
  set(_anosecurekit_runtime_paths "${_anosecurekit_install_prefix}/bin")
  if(DEFINED ANOSECUREKIT_OPENSSL_RUNTIME_DIR AND NOT ANOSECUREKIT_OPENSSL_RUNTIME_DIR STREQUAL "")
    list(APPEND _anosecurekit_runtime_paths "${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}")
  elseif(DEFINED OPENSSL_ROOT_DIR AND NOT OPENSSL_ROOT_DIR STREQUAL "")
    list(APPEND _anosecurekit_runtime_paths "${OPENSSL_ROOT_DIR}/bin")
  endif()
  list(JOIN _anosecurekit_runtime_paths "${_anosecurekit_path_separator}" _anosecurekit_runtime_path)
  set(_anosecurekit_path "${_anosecurekit_runtime_path}${_anosecurekit_path_separator}$ENV{PATH}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_anosecurekit_path}"
    "${CMAKE_COMMAND}"
    "-DANOSECUREKIT_CLI=${_anosecurekit_cli}"
    "-DANOSECUREKIT_CLI_WORK_DIR=${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/installed-cli"
    "-DANOSECUREKIT_TEST_FIXTURE_DIR=${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures"
    -P "${ANOSECUREKIT_SOURCE_DIR}/tests/package/check_installed_cli.cmake"
  RESULT_VARIABLE _anosecurekit_cli_check_result)
if(NOT _anosecurekit_cli_check_result EQUAL 0)
  message(FATAL_ERROR "Installed CLI check failed")
endif()

execute_process(
  COMMAND "${ANOSECUREKIT_CPACK_COMMAND}"
    --config "${ANOSECUREKIT_BUILD_DIR}/CPackConfig.cmake"
    -C "${ANOSECUREKIT_BUILD_CONFIG}"
    -B "${_anosecurekit_artifact_dir}"
  RESULT_VARIABLE _anosecurekit_binary_cpack_result)
if(NOT _anosecurekit_binary_cpack_result EQUAL 0)
  message(FATAL_ERROR "Binary package creation failed")
endif()

execute_process(
  COMMAND "${ANOSECUREKIT_CPACK_COMMAND}"
    --config "${ANOSECUREKIT_BUILD_DIR}/CPackSourceConfig.cmake"
    -B "${_anosecurekit_artifact_dir}"
  RESULT_VARIABLE _anosecurekit_source_cpack_result)
if(NOT _anosecurekit_source_cpack_result EQUAL 0)
  message(FATAL_ERROR "Source package creation failed")
endif()

file(GLOB _anosecurekit_binary_artifacts
  "${_anosecurekit_artifact_dir}/${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-*")
list(FILTER _anosecurekit_binary_artifacts EXCLUDE REGEX "-source\\.")
file(GLOB _anosecurekit_source_artifacts
  "${_anosecurekit_artifact_dir}/${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-source.*")
set(_anosecurekit_source_zip_artifact "${_anosecurekit_artifact_dir}/${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-source.zip")
set(_anosecurekit_source_tgz_artifact "${_anosecurekit_artifact_dir}/${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-source.tar.gz")

list(LENGTH _anosecurekit_binary_artifacts _anosecurekit_binary_artifact_count)
if(_anosecurekit_binary_artifact_count EQUAL 0)
  message(FATAL_ERROR "No binary package artifacts found under ${_anosecurekit_artifact_dir}")
endif()

list(LENGTH _anosecurekit_source_artifacts _anosecurekit_source_artifact_count)
if(_anosecurekit_source_artifact_count EQUAL 0)
  message(FATAL_ERROR "No source package artifacts found under ${_anosecurekit_artifact_dir}")
endif()
if(NOT EXISTS "${_anosecurekit_source_zip_artifact}")
  message(FATAL_ERROR "Source ZIP package artifact not found: ${_anosecurekit_source_zip_artifact}")
endif()
if(NOT EXISTS "${_anosecurekit_source_tgz_artifact}")
  message(FATAL_ERROR "Source TGZ package artifact not found: ${_anosecurekit_source_tgz_artifact}")
endif()

foreach(_anosecurekit_binary_artifact IN LISTS _anosecurekit_binary_artifacts)
  _anosecurekit_require_archive_member(
    "${_anosecurekit_binary_artifact}"
    "/bin/anosecurekit${_anosecurekit_exe_suffix}(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_binary_artifact}"
    "/include/anosecurekit/anosecurekit\\.hpp(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_binary_artifact}"
    "/lib/cmake/anosecurekit/anosecurekitConfig\\.cmake(\r?\n|$)")
endforeach()

foreach(_anosecurekit_source_artifact IN LISTS _anosecurekit_source_artifacts)
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/CMakeLists\\.txt(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/include/anosecurekit/anosecurekit\\.hpp(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/examples/basic/CMakeLists\\.txt(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/examples/basic/main\\.cpp(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/tests/package/check_package\\.cmake(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/tests/package/check_package_recipes\\.cmake(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/RELEASE_CHECKLIST\\.md(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/ROADMAP\\.md(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/FORMAT\\.md(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/SECURITY_MODEL\\.md(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/KDF_AGILITY\\.md(\r?\n|$)")
  _anosecurekit_require_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/FUZZING\\.md(\r?\n|$)")
  _anosecurekit_forbid_archive_member(
    "${_anosecurekit_source_artifact}"
    "/\\.agents/")
  _anosecurekit_forbid_archive_member(
    "${_anosecurekit_source_artifact}"
    "/\\.codex/")
  _anosecurekit_forbid_archive_member(
    "${_anosecurekit_source_artifact}"
    "/docs/superpowers/")
  _anosecurekit_forbid_archive_member(
    "${_anosecurekit_source_artifact}"
    "/anosecurekit-cli-[^/]*(\r?\n|$)")
endforeach()

set(_anosecurekit_consumer_configure_args
  -S "${ANOSECUREKIT_SOURCE_DIR}/tests/consumer"
  -B "${_anosecurekit_consumer_build_dir}"
  "-DCMAKE_PREFIX_PATH=${_anosecurekit_install_prefix}"
  "-DANOSECUREKIT_EXPECTED_VERSION=${ANOSECUREKIT_PROJECT_VERSION}"
  "-DANOSECUREKIT_EXPECTED_VERSION_MAJOR=${ANOSECUREKIT_PROJECT_VERSION_MAJOR}"
  "-DANOSECUREKIT_EXPECTED_VERSION_MINOR=${ANOSECUREKIT_PROJECT_VERSION_MINOR}"
  "-DANOSECUREKIT_EXPECTED_VERSION_PATCH=${ANOSECUREKIT_PROJECT_VERSION_PATCH}"
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")

set(_anosecurekit_source_configure_args
  -B "${_anosecurekit_source_build_dir}"
  -DBUILD_TESTING=OFF
  -DANOSECUREKIT_BUILD_TESTS=OFF
  "-DANOSECUREKIT_WARNINGS_AS_ERRORS=${ANOSECUREKIT_WARNINGS_AS_ERRORS}"
  "-DCMAKE_INSTALL_PREFIX=${_anosecurekit_source_install_prefix}"
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")

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

function(_anosecurekit_run_consumer_command result_variable script_stem)
  if(_anosecurekit_use_msvc_env)
    _anosecurekit_join_cmdline(_anosecurekit_command_line ${ARGN})
    set(_anosecurekit_script "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/${script_stem}.cmd")
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

function(_anosecurekit_append_host_configure_args output_variable)
  set(_anosecurekit_args ${${output_variable}})
  if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR AND NOT ANOSECUREKIT_CMAKE_GENERATOR STREQUAL "")
    list(APPEND _anosecurekit_args -G "${ANOSECUREKIT_CMAKE_GENERATOR}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM AND NOT ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM STREQUAL "")
    list(APPEND _anosecurekit_args -A "${ANOSECUREKIT_CMAKE_GENERATOR_PLATFORM}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET AND NOT ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET STREQUAL "")
    list(APPEND _anosecurekit_args -T "${ANOSECUREKIT_CMAKE_GENERATOR_TOOLSET}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_MAKE_PROGRAM AND NOT ANOSECUREKIT_CMAKE_MAKE_PROGRAM STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_MAKE_PROGRAM=${ANOSECUREKIT_CMAKE_MAKE_PROGRAM}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_CXX_COMPILER AND NOT ANOSECUREKIT_CMAKE_CXX_COMPILER STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_CXX_COMPILER=${ANOSECUREKIT_CMAKE_CXX_COMPILER}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_AR AND NOT ANOSECUREKIT_CMAKE_AR STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_AR=${ANOSECUREKIT_CMAKE_AR}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_LINKER AND NOT ANOSECUREKIT_CMAKE_LINKER STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_LINKER=${ANOSECUREKIT_CMAKE_LINKER}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_MT AND NOT ANOSECUREKIT_CMAKE_MT STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_MT=${ANOSECUREKIT_CMAKE_MT}")
  endif()
  if(DEFINED ANOSECUREKIT_CMAKE_RC_COMPILER AND NOT ANOSECUREKIT_CMAKE_RC_COMPILER STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_RC_COMPILER=${ANOSECUREKIT_CMAKE_RC_COMPILER}")
  endif()
  if(DEFINED CMAKE_TOOLCHAIN_FILE AND NOT CMAKE_TOOLCHAIN_FILE STREQUAL "")
    list(APPEND _anosecurekit_args "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
  endif()
  if(DEFINED VCPKG_TARGET_TRIPLET AND NOT VCPKG_TARGET_TRIPLET STREQUAL "")
    list(APPEND _anosecurekit_args "-DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}")
  endif()
  if(DEFINED OPENSSL_ROOT_DIR AND NOT OPENSSL_ROOT_DIR STREQUAL "")
    list(APPEND _anosecurekit_args "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}")
  endif()
  set(${output_variable} ${_anosecurekit_args} PARENT_SCOPE)
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
    message(STATUS "Using VsDevCmd for MSVC Ninja package checks")
    set(_anosecurekit_use_msvc_env TRUE)
  else()
    message(WARNING "VsDevCmd.bat was not found for MSVC Ninja package checks: ${_anosecurekit_vsdevcmd}")
  endif()
endif()

list(GET _anosecurekit_source_artifacts 0 _anosecurekit_source_artifact)
file(MAKE_DIRECTORY "${_anosecurekit_source_extract_dir}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar xf "${_anosecurekit_source_artifact}"
  WORKING_DIRECTORY "${_anosecurekit_source_extract_dir}"
  RESULT_VARIABLE _anosecurekit_source_extract_result
  ERROR_VARIABLE _anosecurekit_source_extract_error)
if(NOT _anosecurekit_source_extract_result EQUAL 0)
  message(FATAL_ERROR "Source package extraction failed: ${_anosecurekit_source_extract_error}")
endif()

file(GLOB _anosecurekit_source_cmakelists LIST_DIRECTORIES FALSE
  "${_anosecurekit_source_extract_dir}/CMakeLists.txt"
  "${_anosecurekit_source_extract_dir}/*/CMakeLists.txt")
list(LENGTH _anosecurekit_source_cmakelists _anosecurekit_source_cmakelists_count)
if(NOT _anosecurekit_source_cmakelists_count EQUAL 1)
  message(FATAL_ERROR "Expected one extracted source tree, found ${_anosecurekit_source_cmakelists_count}")
endif()
list(GET _anosecurekit_source_cmakelists 0 _anosecurekit_source_cmakelist)
get_filename_component(_anosecurekit_extracted_source_dir "${_anosecurekit_source_cmakelist}" DIRECTORY)

file(GLOB _anosecurekit_forbidden_source_evidence
  "${_anosecurekit_extracted_source_dir}/COMM-REL-*"
  "${_anosecurekit_extracted_source_dir}/collect_v*-publication-evidence*.sh"
  "${_anosecurekit_extracted_source_dir}/artifacts")
if(_anosecurekit_forbidden_source_evidence)
  list(JOIN _anosecurekit_forbidden_source_evidence "\n  " _anosecurekit_forbidden_source_evidence_text)
  message(FATAL_ERROR
    "Source package contains repository-external evidence or artifact paths:\n  "
    "${_anosecurekit_forbidden_source_evidence_text}")
endif()
list(APPEND _anosecurekit_source_configure_args -S "${_anosecurekit_extracted_source_dir}")
_anosecurekit_append_host_configure_args(_anosecurekit_source_configure_args)

_anosecurekit_run_consumer_command(
  _anosecurekit_source_configure_result
  source-configure
  "${CMAKE_COMMAND}"
  ${_anosecurekit_source_configure_args})
if(NOT _anosecurekit_source_configure_result EQUAL 0)
  message(FATAL_ERROR "Source package configure failed")
endif()

_anosecurekit_run_consumer_command(
  _anosecurekit_source_build_result
  source-build
  "${CMAKE_COMMAND}"
  --build "${_anosecurekit_source_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}"
  --target anosecurekit_cli)
if(NOT _anosecurekit_source_build_result EQUAL 0)
  message(FATAL_ERROR "Source package build failed")
endif()

_anosecurekit_run_consumer_command(
  _anosecurekit_source_install_result
  source-install
  "${CMAKE_COMMAND}"
  --install "${_anosecurekit_source_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}"
  --prefix "${_anosecurekit_source_install_prefix}")
if(NOT _anosecurekit_source_install_result EQUAL 0)
  message(FATAL_ERROR "Source package install failed")
endif()

set(_anosecurekit_source_cli "${_anosecurekit_source_install_prefix}/bin/anosecurekit${_anosecurekit_exe_suffix}")
if(NOT EXISTS "${_anosecurekit_source_cli}")
  message(FATAL_ERROR "Source package install is missing CLI: ${_anosecurekit_source_cli}")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_anosecurekit_path}" "${_anosecurekit_source_cli}" --version
  RESULT_VARIABLE _anosecurekit_source_cli_result
  OUTPUT_VARIABLE _anosecurekit_source_cli_output
  ERROR_VARIABLE _anosecurekit_source_cli_error)
if(NOT _anosecurekit_source_cli_result EQUAL 0)
  message(FATAL_ERROR "Source package CLI smoke failed: ${_anosecurekit_source_cli_error}")
endif()
string(REPLACE "\r\n" "\n" _anosecurekit_source_cli_output "${_anosecurekit_source_cli_output}")
if(NOT _anosecurekit_source_cli_output STREQUAL "anosecurekit ${ANOSECUREKIT_PROJECT_VERSION}\n")
  message(FATAL_ERROR "Source package CLI version mismatch: ${_anosecurekit_source_cli_output}")
endif()

set(_anosecurekit_library_only_configure_args
  -S "${_anosecurekit_extracted_source_dir}"
  -B "${_anosecurekit_library_only_build_dir}"
  -DBUILD_TESTING=OFF
  -DANOSECUREKIT_BUILD_TESTS=OFF
  -DANOSECUREKIT_BUILD_CLI=OFF
  -DANOSECUREKIT_INSTALL_CLI=OFF
  "-DANOSECUREKIT_WARNINGS_AS_ERRORS=${ANOSECUREKIT_WARNINGS_AS_ERRORS}"
  "-DCMAKE_INSTALL_PREFIX=${_anosecurekit_library_only_install_prefix}"
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_host_configure_args(_anosecurekit_library_only_configure_args)

_anosecurekit_run_consumer_command(
  _anosecurekit_library_only_configure_result
  library-only-configure
  "${CMAKE_COMMAND}"
  ${_anosecurekit_library_only_configure_args})
if(NOT _anosecurekit_library_only_configure_result EQUAL 0)
  message(FATAL_ERROR "Library-only package configure failed")
endif()

_anosecurekit_run_consumer_command(
  _anosecurekit_library_only_build_result
  library-only-build
  "${CMAKE_COMMAND}"
  --build "${_anosecurekit_library_only_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}"
  --target anosecurekit)
if(NOT _anosecurekit_library_only_build_result EQUAL 0)
  message(FATAL_ERROR "Library-only package build failed")
endif()

_anosecurekit_run_consumer_command(
  _anosecurekit_library_only_install_result
  library-only-install
  "${CMAKE_COMMAND}"
  --install "${_anosecurekit_library_only_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}"
  --prefix "${_anosecurekit_library_only_install_prefix}")
if(NOT _anosecurekit_library_only_install_result EQUAL 0)
  message(FATAL_ERROR "Library-only package install failed")
endif()

set(_anosecurekit_library_only_cli "${_anosecurekit_library_only_install_prefix}/bin/anosecurekit${_anosecurekit_exe_suffix}")
if(EXISTS "${_anosecurekit_library_only_cli}")
  message(FATAL_ERROR "Library-only package unexpectedly installed CLI: ${_anosecurekit_library_only_cli}")
endif()

set(_anosecurekit_library_only_consumer_configure_args
  -S "${ANOSECUREKIT_SOURCE_DIR}/tests/consumer"
  -B "${_anosecurekit_library_only_consumer_build_dir}"
  "-DCMAKE_PREFIX_PATH=${_anosecurekit_library_only_install_prefix}"
  "-DANOSECUREKIT_EXPECTED_VERSION=${ANOSECUREKIT_PROJECT_VERSION}"
  "-DANOSECUREKIT_EXPECTED_VERSION_MAJOR=${ANOSECUREKIT_PROJECT_VERSION_MAJOR}"
  "-DANOSECUREKIT_EXPECTED_VERSION_MINOR=${ANOSECUREKIT_PROJECT_VERSION_MINOR}"
  "-DANOSECUREKIT_EXPECTED_VERSION_PATCH=${ANOSECUREKIT_PROJECT_VERSION_PATCH}"
  "-DCMAKE_BUILD_TYPE=${ANOSECUREKIT_BUILD_CONFIG}")
_anosecurekit_append_host_configure_args(_anosecurekit_library_only_consumer_configure_args)

_anosecurekit_run_consumer_command(
  _anosecurekit_library_only_consumer_configure_result
  library-only-consumer-configure
  "${CMAKE_COMMAND}"
  ${_anosecurekit_library_only_consumer_configure_args})
if(NOT _anosecurekit_library_only_consumer_configure_result EQUAL 0)
  message(FATAL_ERROR "Library-only consumer configure failed")
endif()

_anosecurekit_run_consumer_command(
  _anosecurekit_library_only_consumer_build_result
  library-only-consumer-build
  "${CMAKE_COMMAND}"
  --build "${_anosecurekit_library_only_consumer_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}")
if(NOT _anosecurekit_library_only_consumer_build_result EQUAL 0)
  message(FATAL_ERROR "Library-only consumer build failed")
endif()

set(_anosecurekit_library_only_consumer_candidates
  "${_anosecurekit_library_only_consumer_build_dir}/${ANOSECUREKIT_BUILD_CONFIG}/anosecurekit_consumer${_anosecurekit_exe_suffix}"
  "${_anosecurekit_library_only_consumer_build_dir}/anosecurekit_consumer${_anosecurekit_exe_suffix}")

set(_anosecurekit_library_only_consumer_exe "")
foreach(_anosecurekit_library_only_consumer_candidate IN LISTS _anosecurekit_library_only_consumer_candidates)
  if(EXISTS "${_anosecurekit_library_only_consumer_candidate}")
    set(_anosecurekit_library_only_consumer_exe "${_anosecurekit_library_only_consumer_candidate}")
    break()
  endif()
endforeach()
if(_anosecurekit_library_only_consumer_exe STREQUAL "")
  message(FATAL_ERROR "Library-only consumer executable not found under ${_anosecurekit_library_only_consumer_build_dir}")
endif()

set(_anosecurekit_library_only_path "${_anosecurekit_library_only_install_prefix}/bin${_anosecurekit_path_separator}${_anosecurekit_path}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_anosecurekit_library_only_path}" "${_anosecurekit_library_only_consumer_exe}"
  RESULT_VARIABLE _anosecurekit_library_only_consumer_run_result)
if(NOT _anosecurekit_library_only_consumer_run_result EQUAL 0)
  message(FATAL_ERROR "Library-only consumer run failed")
endif()

_anosecurekit_append_host_configure_args(_anosecurekit_consumer_configure_args)

_anosecurekit_run_consumer_command(
  _anosecurekit_consumer_configure_result
  consumer-configure
  "${CMAKE_COMMAND}"
  ${_anosecurekit_consumer_configure_args})
if(NOT _anosecurekit_consumer_configure_result EQUAL 0)
  message(FATAL_ERROR "Consumer configure failed")
endif()

_anosecurekit_run_consumer_command(
  _anosecurekit_consumer_build_result
  consumer-build
  "${CMAKE_COMMAND}"
  --build "${_anosecurekit_consumer_build_dir}"
  --config "${ANOSECUREKIT_BUILD_CONFIG}")
if(NOT _anosecurekit_consumer_build_result EQUAL 0)
  message(FATAL_ERROR "Consumer build failed")
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
  message(FATAL_ERROR "Consumer executable not found under ${_anosecurekit_consumer_build_dir}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${_anosecurekit_path}" "${_anosecurekit_consumer_exe}"
  RESULT_VARIABLE _anosecurekit_consumer_run_result)
if(NOT _anosecurekit_consumer_run_result EQUAL 0)
  message(FATAL_ERROR "Consumer run failed")
endif()
