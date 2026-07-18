# SPDX-License-Identifier: MPL-2.0

if(NOT DEFINED ANOSECUREKIT_SOURCE_DIR OR ANOSECUREKIT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ANOSECUREKIT_SOURCE_DIR is required")
endif()

function(_read_relative path out_var)
  set(full_path "${ANOSECUREKIT_SOURCE_DIR}/${path}")
  if(NOT EXISTS "${full_path}")
    message(FATAL_ERROR "document-alignment-check missing required file: ${path}")
  endif()
  file(READ "${full_path}" content)
  set(${out_var} "${content}" PARENT_SCOPE)
endfunction()

function(_require_text path text needle)
  string(FIND "${text}" "${needle}" found_at)
  if(found_at EQUAL -1)
    message(FATAL_ERROR "document-alignment-check: ${path} is missing required text: ${needle}")
  endif()
endfunction()

function(_forbid_text path text needle)
  string(FIND "${text}" "${needle}" found_at)
  if(NOT found_at EQUAL -1)
    message(FATAL_ERROR "document-alignment-check: ${path} contains stale text: ${needle}")
  endif()
endfunction()

_read_relative("README.md" readme)
_read_relative("SECURITY.md" security_policy)
_read_relative("CONTRIBUTING.md" contributing)
_read_relative("docs/LICENSE_POLICY.md" license_policy)
_read_relative("docs/DOGFOODING.md" dogfooding)
_read_relative("docs/ROADMAP.md" roadmap_md)
_read_relative("docs/WEB_ROADMAP.md" web_roadmap)
_read_relative("docs/index.html" index_html)
_read_relative("docs/security.html" security_html)
_read_relative("docs/license.html" license_html)
_read_relative("docs/roadmap.html" roadmap_html)
_read_relative("docs/NEXT_WORK_QUEUE.md" next_queue)

_require_text("README.md" "${readme}" "docs/NEXT_WORK_QUEUE.md")
_require_text("README.md" "${readme}" "compatibility entry point")
_require_text("README.md" "${readme}" "only shipped production provider")
_require_text("SECURITY.md" "${security_policy}" "only shipped production provider")
_require_text("SECURITY.md" "${security_policy}" "AnoCrypto-C adapter")
_require_text("docs/ROADMAP.md" "${roadmap_md}" "Status: COMPATIBILITY ENTRY POINT")
_require_text("docs/ROADMAP.md" "${roadmap_md}" "docs/NEXT_WORK_QUEUE.md")
_require_text("docs/WEB_ROADMAP.md" "${web_roadmap}" "docs/NEXT_WORK_QUEUE.md")
_require_text("docs/index.html" "${index_html}" "only shipped production provider")
_require_text("docs/security.html" "${security_html}" "only shipped production provider")
_require_text("docs/roadmap.html" "${roadmap_html}" "v0.4.1")
_require_text("docs/roadmap.html" "${roadmap_html}" "NEXT_WORK_QUEUE.md")

foreach(pair IN ITEMS
    "README.md|${readme}"
    "SECURITY.md|${security_policy}"
    "CONTRIBUTING.md|${contributing}"
    "docs/LICENSE_POLICY.md|${license_policy}"
    "docs/DOGFOODING.md|${dogfooding}"
    "docs/ROADMAP.md|${roadmap_md}"
    "docs/WEB_ROADMAP.md|${web_roadmap}"
    "docs/index.html|${index_html}"
    "docs/security.html|${security_html}"
    "docs/license.html|${license_html}"
    "docs/roadmap.html|${roadmap_html}")
  string(FIND "${pair}" "|" sep)
  string(SUBSTRING "${pair}" 0 ${sep} path)
  math(EXPR content_start "${sep} + 1")
  string(SUBSTRING "${pair}" ${content_start} -1 content)
  _forbid_text("${path}" "${content}" "current default crypto backend")
  _forbid_text("${path}" "${content}" "OpenSSL-backed today, backend-neutral by design")
  _forbid_text("${path}" "${content}" "preparing and validating the Community v0.4.0 release")
  string(REPLACE "AnoCrypto-C" "" without_current_name "${content}")
  _forbid_text("${path}" "${without_current_name}" "AnoCrypto")
endforeach()

string(REGEX MATCH "COMM-[A-Z]+-[0-9]+[ ]+—" duplicate_task "${roadmap_md}")
if(duplicate_task)
  message(FATAL_ERROR "document-alignment-check: docs/ROADMAP.md contains an independent named work queue")
endif()

message(STATUS "AnoSecureKit documentation alignment check passed")
