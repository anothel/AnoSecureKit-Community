# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_RELEASE_NOTES_FILE
    OR ANOSECUREKIT_RELEASE_NOTES_FILE STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_RELEASE_NOTES_FILE is required")
endif()

if(NOT DEFINED ANOSECUREKIT_RELEASE_VERSION
    OR ANOSECUREKIT_RELEASE_VERSION STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_RELEASE_VERSION is required")
endif()

if(NOT ANOSECUREKIT_RELEASE_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  message(FATAL_ERROR
    "ANOSECUREKIT_RELEASE_VERSION must be SemVer x.y.z: ${ANOSECUREKIT_RELEASE_VERSION}")
endif()

if(NOT EXISTS "${ANOSECUREKIT_RELEASE_NOTES_FILE}")
  message(FATAL_ERROR
    "Release notes file not found: ${ANOSECUREKIT_RELEASE_NOTES_FILE}")
endif()

file(READ "${ANOSECUREKIT_RELEASE_NOTES_FILE}" _anosecurekit_release_notes)
string(REPLACE "\r\n" "\n" _anosecurekit_release_notes
  "${_anosecurekit_release_notes}")
string(REPLACE "\r" "\n" _anosecurekit_release_notes
  "${_anosecurekit_release_notes}")

set(_anosecurekit_heading "## v${ANOSECUREKIT_RELEASE_VERSION}\n")
string(FIND "${_anosecurekit_release_notes}" "${_anosecurekit_heading}"
  _anosecurekit_section_start)
if(_anosecurekit_section_start EQUAL -1)
  message(FATAL_ERROR
    "Release notes are missing ${_anosecurekit_heading}")
endif()

string(SUBSTRING "${_anosecurekit_release_notes}"
  ${_anosecurekit_section_start} -1 _anosecurekit_section_tail)
string(LENGTH "${_anosecurekit_heading}" _anosecurekit_heading_length)
string(SUBSTRING "${_anosecurekit_section_tail}"
  ${_anosecurekit_heading_length} -1 _anosecurekit_after_heading)

string(FIND "${_anosecurekit_after_heading}" "${_anosecurekit_heading}"
  _anosecurekit_duplicate_heading)
if(NOT _anosecurekit_duplicate_heading EQUAL -1)
  message(FATAL_ERROR
    "Release notes contain duplicate v${ANOSECUREKIT_RELEASE_VERSION} sections")
endif()

string(FIND "${_anosecurekit_after_heading}" "\n## "
  _anosecurekit_next_section)
if(_anosecurekit_next_section EQUAL -1)
  set(_anosecurekit_section "${_anosecurekit_section_tail}")
else()
  math(EXPR _anosecurekit_section_length
    "${_anosecurekit_heading_length} + ${_anosecurekit_next_section}")
  string(SUBSTRING "${_anosecurekit_section_tail}" 0
    ${_anosecurekit_section_length} _anosecurekit_section)
endif()

string(STRIP "${_anosecurekit_section}" _anosecurekit_section)
if(_anosecurekit_section STREQUAL "## v${ANOSECUREKIT_RELEASE_VERSION}")
  message(FATAL_ERROR
    "Release notes section v${ANOSECUREKIT_RELEASE_VERSION} is empty")
endif()

if(DEFINED ANOSECUREKIT_RELEASE_NOTES_OUTPUT
    AND NOT ANOSECUREKIT_RELEASE_NOTES_OUTPUT STREQUAL "")
  get_filename_component(_anosecurekit_output_dir
    "${ANOSECUREKIT_RELEASE_NOTES_OUTPUT}" DIRECTORY)
  file(MAKE_DIRECTORY "${_anosecurekit_output_dir}")
  file(WRITE "${ANOSECUREKIT_RELEASE_NOTES_OUTPUT}"
    "${_anosecurekit_section}\n")
  message(STATUS
    "Wrote canonical v${ANOSECUREKIT_RELEASE_VERSION} release notes: ${ANOSECUREKIT_RELEASE_NOTES_OUTPUT}")
else()
  message(STATUS
    "Validated canonical v${ANOSECUREKIT_RELEASE_VERSION} release notes")
endif()
