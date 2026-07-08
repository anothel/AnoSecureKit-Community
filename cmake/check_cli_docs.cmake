# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_CLI OR ANOSECUREKIT_CLI STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_CLI is required")
endif()
if(NOT DEFINED ANOSECUREKIT_CLI_DOC OR ANOSECUREKIT_CLI_DOC STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_CLI_DOC is required")
endif()
if(NOT EXISTS "${ANOSECUREKIT_CLI}")
  message(FATAL_ERROR "CLI executable not found: ${ANOSECUREKIT_CLI}")
endif()
if(NOT EXISTS "${ANOSECUREKIT_CLI_DOC}")
  message(FATAL_ERROR "CLI documentation not found: ${ANOSECUREKIT_CLI_DOC}")
endif()

execute_process(
  COMMAND "${ANOSECUREKIT_CLI}" --help
  RESULT_VARIABLE _anosecurekit_help_result
  OUTPUT_VARIABLE _anosecurekit_help_stdout
  ERROR_VARIABLE _anosecurekit_help_stderr)

if(NOT _anosecurekit_help_result EQUAL 0)
  message(FATAL_ERROR "anosecurekit --help failed with ${_anosecurekit_help_result}: ${_anosecurekit_help_stderr}")
endif()
if(NOT _anosecurekit_help_stderr STREQUAL "")
  message(FATAL_ERROR "anosecurekit --help wrote to stderr: ${_anosecurekit_help_stderr}")
endif()

file(READ "${ANOSECUREKIT_CLI_DOC}" _anosecurekit_cli_doc_text)
string(FIND "${_anosecurekit_cli_doc_text}" "${_anosecurekit_help_stdout}" _anosecurekit_help_at)
if(_anosecurekit_help_at EQUAL -1)
  message(FATAL_ERROR "docs/CLI.md does not contain the exact current anosecurekit --help output")
endif()

message(STATUS "CLI help documentation check passed")
