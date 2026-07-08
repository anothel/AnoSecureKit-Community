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

if(NOT ANOSECUREKIT_PROJECT_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
  message(FATAL_ERROR "Project version is not SemVer x.y.z: ${ANOSECUREKIT_PROJECT_VERSION}")
endif()

set(_anosecurekit_expected_tag "v${ANOSECUREKIT_PROJECT_VERSION}")
if(DEFINED ANOSECUREKIT_RELEASE_TAG AND NOT ANOSECUREKIT_RELEASE_TAG STREQUAL "")
  if(NOT ANOSECUREKIT_RELEASE_TAG STREQUAL "${_anosecurekit_expected_tag}")
    message(FATAL_ERROR "Release tag ${ANOSECUREKIT_RELEASE_TAG} does not match project version ${ANOSECUREKIT_PROJECT_VERSION}")
  endif()
endif()

set(_anosecurekit_cmakelists "${ANOSECUREKIT_SOURCE_DIR}/CMakeLists.txt")
set(_anosecurekit_readme "${ANOSECUREKIT_SOURCE_DIR}/README.md")
set(_anosecurekit_security "${ANOSECUREKIT_SOURCE_DIR}/SECURITY.md")
set(_anosecurekit_contributing "${ANOSECUREKIT_SOURCE_DIR}/CONTRIBUTING.md")
set(_anosecurekit_format "${ANOSECUREKIT_SOURCE_DIR}/docs/FORMAT.md")
set(_anosecurekit_license_policy "${ANOSECUREKIT_SOURCE_DIR}/docs/LICENSE_POLICY.md")
set(_anosecurekit_documentation_guide "${ANOSECUREKIT_SOURCE_DIR}/docs/DOCUMENTATION_GUIDE.md")
set(_anosecurekit_license_page "${ANOSECUREKIT_SOURCE_DIR}/docs/license.html")
set(_anosecurekit_security_model "${ANOSECUREKIT_SOURCE_DIR}/docs/SECURITY_MODEL.md")
set(_anosecurekit_external_security_review "${ANOSECUREKIT_SOURCE_DIR}/docs/EXTERNAL_SECURITY_REVIEW.md")
set(_anosecurekit_public_api_policy "${ANOSECUREKIT_SOURCE_DIR}/docs/PUBLIC_API_POLICY.md")
set(_anosecurekit_openssl_policy "${ANOSECUREKIT_SOURCE_DIR}/docs/OPENSSL_POLICY.md")
set(_anosecurekit_kdf_agility "${ANOSECUREKIT_SOURCE_DIR}/docs/KDF_AGILITY.md")
set(_anosecurekit_fuzzing "${ANOSECUREKIT_SOURCE_DIR}/docs/FUZZING.md")
set(_anosecurekit_coverage "${ANOSECUREKIT_SOURCE_DIR}/docs/COVERAGE.md")
set(_anosecurekit_cli_doc "${ANOSECUREKIT_SOURCE_DIR}/docs/CLI.md")
set(_anosecurekit_benchmarks_doc "${ANOSECUREKIT_SOURCE_DIR}/docs/BENCHMARKS.md")
set(_anosecurekit_dependency_policy "${ANOSECUREKIT_SOURCE_DIR}/docs/DEPENDENCY_POLICY.md")
set(_anosecurekit_verify_release "${ANOSECUREKIT_SOURCE_DIR}/docs/VERIFY_RELEASE.md")
set(_anosecurekit_dogfooding "${ANOSECUREKIT_SOURCE_DIR}/docs/DOGFOODING.md")
set(_anosecurekit_release_notes "${ANOSECUREKIT_SOURCE_DIR}/docs/RELEASE_NOTES.md")
set(_anosecurekit_release_checklist "${ANOSECUREKIT_SOURCE_DIR}/docs/RELEASE_CHECKLIST.md")
set(_anosecurekit_roadmap "${ANOSECUREKIT_SOURCE_DIR}/docs/ROADMAP.md")
set(_anosecurekit_internals "${ANOSECUREKIT_SOURCE_DIR}/docs/INTERNALS.md")
set(_anosecurekit_package_recipe_check "${ANOSECUREKIT_SOURCE_DIR}/tests/package/check_package_recipes.cmake")
set(_anosecurekit_fixtures_readme "${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures/README.md")
set(_anosecurekit_negative_fixtures_readme "${ANOSECUREKIT_SOURCE_DIR}/tests/fixtures/negative/README.md")
set(_anosecurekit_dependabot "${ANOSECUREKIT_SOURCE_DIR}/.github/dependabot.yml")
set(_anosecurekit_example_cmakelists "${ANOSECUREKIT_SOURCE_DIR}/examples/basic/CMakeLists.txt")
set(_anosecurekit_example_main "${ANOSECUREKIT_SOURCE_DIR}/examples/basic/main.cpp")
set(_anosecurekit_benchmark_source "${ANOSECUREKIT_SOURCE_DIR}/benchmarks/crypto_file_bench.cpp")
set(_anosecurekit_public_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/anosecurekit.hpp")
set(_anosecurekit_aead_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/aead.hpp")
set(_anosecurekit_base64_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/base64.hpp")
set(_anosecurekit_compare_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/compare.hpp")
set(_anosecurekit_file_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/file.hpp")
set(_anosecurekit_hash_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/hash.hpp")
set(_anosecurekit_hex_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/hex.hpp")
set(_anosecurekit_key_wrap_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/key_wrap.hpp")
set(_anosecurekit_packet_stream_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/packet_stream.hpp")
set(_anosecurekit_random_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/random.hpp")
set(_anosecurekit_version_header "${ANOSECUREKIT_SOURCE_DIR}/include/anosecurekit/version.hpp")
set(_anosecurekit_cli_source "${ANOSECUREKIT_SOURCE_DIR}/src/cli/commands.cpp")
set(_anosecurekit_spdx_check "${ANOSECUREKIT_SOURCE_DIR}/cmake/check_spdx.cmake")
set(_anosecurekit_legacy_check "${ANOSECUREKIT_SOURCE_DIR}/cmake/check_legacy_identifiers.cmake")
set(_anosecurekit_cli_docs_check "${ANOSECUREKIT_SOURCE_DIR}/cmake/check_cli_docs.cmake")

foreach(_anosecurekit_required_file IN ITEMS
    "${_anosecurekit_cmakelists}"
    "${_anosecurekit_readme}"
    "${_anosecurekit_security}"
    "${_anosecurekit_contributing}"
    "${_anosecurekit_format}"
    "${_anosecurekit_license_policy}"
    "${_anosecurekit_documentation_guide}"
    "${_anosecurekit_license_page}"
    "${_anosecurekit_security_model}"
    "${_anosecurekit_external_security_review}"
    "${_anosecurekit_public_api_policy}"
    "${_anosecurekit_openssl_policy}"
    "${_anosecurekit_kdf_agility}"
    "${_anosecurekit_fuzzing}"
    "${_anosecurekit_coverage}"
    "${_anosecurekit_cli_doc}"
    "${_anosecurekit_benchmarks_doc}"
    "${_anosecurekit_dependency_policy}"
    "${_anosecurekit_verify_release}"
    "${_anosecurekit_dogfooding}"
    "${_anosecurekit_release_notes}"
    "${_anosecurekit_release_checklist}"
    "${_anosecurekit_roadmap}"
    "${_anosecurekit_internals}"
    "${_anosecurekit_package_recipe_check}"
    "${_anosecurekit_fixtures_readme}"
    "${_anosecurekit_negative_fixtures_readme}"
    "${_anosecurekit_dependabot}"
    "${_anosecurekit_example_cmakelists}"
    "${_anosecurekit_example_main}"
    "${_anosecurekit_benchmark_source}"
    "${_anosecurekit_public_header}"
    "${_anosecurekit_aead_header}"
    "${_anosecurekit_base64_header}"
    "${_anosecurekit_compare_header}"
    "${_anosecurekit_file_header}"
    "${_anosecurekit_hash_header}"
    "${_anosecurekit_hex_header}"
    "${_anosecurekit_key_wrap_header}"
    "${_anosecurekit_packet_stream_header}"
    "${_anosecurekit_random_header}"
    "${_anosecurekit_version_header}"
    "${_anosecurekit_cli_source}"
    "${_anosecurekit_spdx_check}"
    "${_anosecurekit_legacy_check}"
    "${_anosecurekit_cli_docs_check}")
  if(NOT EXISTS "${_anosecurekit_required_file}")
    message(FATAL_ERROR "Release preflight file not found: ${_anosecurekit_required_file}")
  endif()
endforeach()

file(READ "${_anosecurekit_cmakelists}" _anosecurekit_cmakelists_text)
file(READ "${_anosecurekit_readme}" _anosecurekit_readme_text)
file(READ "${_anosecurekit_security}" _anosecurekit_security_text)
file(READ "${_anosecurekit_contributing}" _anosecurekit_contributing_text)
file(READ "${_anosecurekit_format}" _anosecurekit_format_text)
file(READ "${_anosecurekit_license_policy}" _anosecurekit_license_policy_text)
file(READ "${_anosecurekit_documentation_guide}" _anosecurekit_documentation_guide_text)
file(READ "${_anosecurekit_license_page}" _anosecurekit_license_page_text)
file(READ "${_anosecurekit_security_model}" _anosecurekit_security_model_text)
file(READ "${_anosecurekit_external_security_review}" _anosecurekit_external_security_review_text)
file(READ "${_anosecurekit_public_api_policy}" _anosecurekit_public_api_policy_text)
file(READ "${_anosecurekit_openssl_policy}" _anosecurekit_openssl_policy_text)
file(READ "${_anosecurekit_kdf_agility}" _anosecurekit_kdf_agility_text)
file(READ "${_anosecurekit_fuzzing}" _anosecurekit_fuzzing_text)
file(READ "${_anosecurekit_coverage}" _anosecurekit_coverage_text)
file(READ "${_anosecurekit_cli_doc}" _anosecurekit_cli_doc_text)
file(READ "${_anosecurekit_benchmarks_doc}" _anosecurekit_benchmarks_doc_text)
file(READ "${_anosecurekit_dependency_policy}" _anosecurekit_dependency_policy_text)
file(READ "${_anosecurekit_verify_release}" _anosecurekit_verify_release_text)
file(READ "${_anosecurekit_dogfooding}" _anosecurekit_dogfooding_text)
file(READ "${_anosecurekit_release_notes}" _anosecurekit_release_notes_text)
file(READ "${_anosecurekit_release_checklist}" _anosecurekit_release_checklist_text)
file(READ "${_anosecurekit_roadmap}" _anosecurekit_roadmap_text)
file(READ "${_anosecurekit_internals}" _anosecurekit_internals_text)
file(READ "${_anosecurekit_package_recipe_check}" _anosecurekit_package_recipe_check_text)
file(READ "${_anosecurekit_fixtures_readme}" _anosecurekit_fixtures_readme_text)
file(READ "${_anosecurekit_negative_fixtures_readme}" _anosecurekit_negative_fixtures_readme_text)
file(READ "${_anosecurekit_dependabot}" _anosecurekit_dependabot_text)
file(READ "${_anosecurekit_example_cmakelists}" _anosecurekit_example_cmakelists_text)
file(READ "${_anosecurekit_example_main}" _anosecurekit_example_main_text)
file(READ "${_anosecurekit_benchmark_source}" _anosecurekit_benchmark_source_text)
file(READ "${_anosecurekit_public_header}" _anosecurekit_public_header_text)
file(READ "${_anosecurekit_aead_header}" _anosecurekit_aead_header_text)
file(READ "${_anosecurekit_base64_header}" _anosecurekit_base64_header_text)
file(READ "${_anosecurekit_compare_header}" _anosecurekit_compare_header_text)
file(READ "${_anosecurekit_file_header}" _anosecurekit_file_header_text)
file(READ "${_anosecurekit_hash_header}" _anosecurekit_hash_header_text)
file(READ "${_anosecurekit_hex_header}" _anosecurekit_hex_header_text)
file(READ "${_anosecurekit_key_wrap_header}" _anosecurekit_key_wrap_header_text)
file(READ "${_anosecurekit_packet_stream_header}" _anosecurekit_packet_stream_header_text)
file(READ "${_anosecurekit_random_header}" _anosecurekit_random_header_text)
file(READ "${_anosecurekit_version_header}" _anosecurekit_version_header_text)
file(READ "${_anosecurekit_cli_source}" _anosecurekit_cli_source_text)
file(READ "${_anosecurekit_spdx_check}" _anosecurekit_spdx_check_text)
file(READ "${_anosecurekit_legacy_check}" _anosecurekit_legacy_check_text)
file(READ "${_anosecurekit_cli_docs_check}" _anosecurekit_cli_docs_check_text)

function(_anosecurekit_require_text description haystack needle)
  string(FIND "${haystack}" "${needle}" _anosecurekit_found_at)
  if(_anosecurekit_found_at EQUAL -1)
    message(FATAL_ERROR "Release preflight missing ${description}: ${needle}")
  endif()
endfunction()

function(_anosecurekit_require_regex description haystack pattern)
  string(REGEX MATCH "${pattern}" _anosecurekit_match "${haystack}")
  if(_anosecurekit_match STREQUAL "")
    message(FATAL_ERROR "Release preflight missing ${description}: ${pattern}")
  endif()
endfunction()

function(_anosecurekit_require_terms description haystack)
  foreach(_anosecurekit_term IN LISTS ARGN)
    _anosecurekit_require_text(
      "${description}"
      "${haystack}"
      "${_anosecurekit_term}")
  endforeach()
endfunction()

function(_anosecurekit_forbid_text description haystack needle)
  string(FIND "${haystack}" "${needle}" _anosecurekit_found_at)
  if(NOT _anosecurekit_found_at EQUAL -1)
    message(FATAL_ERROR "Release preflight found out-of-scope ${description}: ${needle}")
  endif()
endfunction()

function(_anosecurekit_forbid_regex description haystack pattern)
  string(REGEX MATCH "${pattern}" _anosecurekit_match "${haystack}")
  if(NOT _anosecurekit_match STREQUAL "")
    message(FATAL_ERROR "Release preflight found out-of-scope ${description}: ${pattern}")
  endif()
endfunction()

function(_anosecurekit_forbid_terms description haystack)
  foreach(_anosecurekit_term IN LISTS ARGN)
    _anosecurekit_forbid_text(
      "${description}"
      "${haystack}"
      "${_anosecurekit_term}")
  endforeach()
endfunction()

_anosecurekit_require_regex(
  "CMake project version"
  "${_anosecurekit_cmakelists_text}"
  "project\\([^\n\r]*[\n\r]+[ \t]*${ANOSECUREKIT_PROJECT_NAME}[\n\r]+[ \t]*VERSION ${ANOSECUREKIT_PROJECT_VERSION}")
_anosecurekit_require_text(
  "README version example"
  "${_anosecurekit_readme_text}"
  "project(... VERSION ${ANOSECUREKIT_PROJECT_VERSION})")
_anosecurekit_require_text(
  "README tag example"
  "${_anosecurekit_readme_text}"
  "${_anosecurekit_expected_tag}")
_anosecurekit_require_text(
  "release checklist tag command"
  "${_anosecurekit_release_checklist_text}"
  "git tag ${_anosecurekit_expected_tag}")
_anosecurekit_require_text(
  "release checklist push command"
  "${_anosecurekit_release_checklist_text}"
  "git push origin ${_anosecurekit_expected_tag}")
_anosecurekit_require_text(
  "roadmap local target release-preflight"
  "${_anosecurekit_roadmap_text}"
  "--target release-preflight")

_anosecurekit_require_terms(
  "release-preflight target dependencies"
  "${_anosecurekit_cmakelists_text}"
  "add_custom_target(release-preflight"
  "DEPENDS"
  "check"
  "benchmarks-check"
  "examples-check"
  "dogfood-check"
  "release-workflow-check"
  "spdx-check"
  "legacy-name-check"
  "cli-docs-check"
  "check_spdx.cmake"
  "check_legacy_identifiers.cmake"
  "check_cli_docs.cmake"
  "check_package_recipes.cmake")

_anosecurekit_forbid_terms(
  "release-preflight nested build"
  "${_anosecurekit_cmakelists_text}"
  "--target check"
  "--target examples-check"
  "--target package-check"
  "--target dogfood-check"
  "--target release-workflow-check")

_anosecurekit_require_terms(
  "roadmap scope guard"
  "${_anosecurekit_roadmap_text}"
  "## Intake Rules"
  "## Current Plan"
  "dogfood-check"
  "no repeated friction"
  "Release-impacting work"
  "Fix Queue"
  "Do not leave accepted fixes deferred"
  "Keep v0.x public API changes minimal"
  "Active roadmap items must name an existing AnoSecureKit surface"
  "External audit or roadmap notes are triage input only"
  "Node.js"
  "backend middleware"
  "Package Publishing"
  "Package-manager recipe publication"
  "rollback")

_anosecurekit_require_terms(
  "roadmap repository-specific candidates"
  "${_anosecurekit_roadmap_text}"
  "Package-manager recipe publication"
  "consumer project builds against each published recipe")
_anosecurekit_forbid_terms(
  "roadmap completed benchmark or fixture queue items"
  "${_anosecurekit_roadmap_text}"
  "Add benchmarks for crypto/file paths"
  "Expand negative compatibility fixtures")
_anosecurekit_forbid_terms(
  "roadmap completed public review queue items"
  "${_anosecurekit_roadmap_text}"
  "Public error/API shape review"
  "Public object-lifecycle review"
  "OpenSSL provider/FIPS policy")

_anosecurekit_forbid_terms(
  "roadmap analysis dump"
  "${_anosecurekit_roadmap_text}"
  "| Audit theme | AnoSecureKit handling | Required check |"
  "| Analysis item | Disposition | Reason / gate |"
  "anosecurekit_analysis_2026-06-28.md"
  "anosecurekit_full_analysis_2026-06-28.md"
  "Already resolved"
  "Already resolved, keep guarded"
  "Accepted as release-confidence work"
  "These are blocked candidates")
_anosecurekit_forbid_regex(
  "roadmap deferred-work section"
  "${_anosecurekit_roadmap_text}"
  "## [Pp]arked|[Pp]arked|## Not[ ]Planned")
_anosecurekit_forbid_regex(
  "roadmap completed-work section"
  "${_anosecurekit_roadmap_text}"
  "## Recently[ ]Finished|Recently[ ]Finished")

_anosecurekit_require_terms(
  "dogfooding record"
  "${_anosecurekit_dogfooding_text}"
  "cmake --build build --config Release --target dogfood-check"
  "keygen"
  "seal-file"
  "verify-file"
  "open-file"
  "seal-file-password"
  "verify-file-password"
  "open-file-password"
  "C++ consumer"
  "no repeated friction recorded"
  "Follow-up work now lives in"
  "Fix Queue")

_anosecurekit_require_terms(
  "contributor one-command local checks"
  "${_anosecurekit_contributing_text}"
  "One-command local check"
  "cmake --build build --config Release --target release-preflight"
  "ANOSECUREKIT_BUILD_TESTS=ON"
  "ANOSECUREKIT_BUILD_CLI=ON"
  "ANOSECUREKIT_INSTALL_CLI=ON"
  "Do not add public API"
  "regression check"
  "rollback plan.")

_anosecurekit_require_terms(
  "README verified feature claims"
  "${_anosecurekit_readme_text}"
  "Hex encode and decode."
  "Base64 encode and decode."
  "Base64URL encode and decode."
  "SHA-256 digest."
  "HMAC-SHA-256 digest."
  "HKDF-SHA-256 key derivation."
  "Constant-time byte comparison for equal-length secret values."
  "Cryptographically secure random bytes."
  "URL-safe random token generation."
  "AES-256-GCM packet encryption and decryption."
  "Move-only packet streaming encryptor and decryptor for `SKT1`."
  "AES-256-GCM key wrapping helpers."
  "Chunked file sealing and opening with path and stream APIs."
  "Password-based chunked file sealing and opening with `SKP1` and scrypt.")

_anosecurekit_require_terms(
  "README release surface contract"
  "${_anosecurekit_readme_text}"
  "Release Surface Contract"
  "Public claims are limited to the C++ APIs listed in Public API"
  "listed in [docs/CLI.md](docs/CLI.md)"
  "`SKT1`, `SKF1`, and `SKP1` formats"
  "and packaged CMake surfaces described here"
  "docs against public headers"
  "CLI command usage"
  "install/export/package"
  "artifacts, release assets"
  "release assets"
  "External audits and roadmap notes are handled through this contract"
  "Items that"
  "do not map to the C++ API, CLI, `SKT1`/`SKF1`/`SKP1`, CMake package"
  "asset, or security-reporting surface"
  "triage input, not implementation scope"
  "`docs/ROADMAP.md` records the active work queue")

_anosecurekit_require_terms(
  "README release notes and internal boundary docs"
  "${_anosecurekit_readme_text}"
  "The release notes source of truth is"
  "GitHub Release notes should be"
  "edited to match it"
  "ANOSECUREKIT_BUILD_FUZZ"
  "[docs/FUZZING.md](docs/FUZZING.md)"
  "[docs/PUBLIC_API_POLICY.md](docs/PUBLIC_API_POLICY.md)"
  "[docs/OPENSSL_POLICY.md](docs/OPENSSL_POLICY.md)"
  "[docs/INTERNALS.md](docs/INTERNALS.md)")

_anosecurekit_require_terms(
  "README CLI entry point"
  "${_anosecurekit_readme_text}"
  "[docs/CLI.md](docs/CLI.md)")

_anosecurekit_require_terms(
  "CLI verify entry point"
  "${_anosecurekit_cli_doc_text}"
  "anosecurekit verify-file"
  "anosecurekit verify-file-password"
  "without creating a plaintext output file"
  "write nothing to stdout on success"
  "exit code: 0 on success, 1 on failure"
  "Usage, parse, file, or decoding failures return exit code 1"
  "authentication verification")

_anosecurekit_require_terms(
  "security model CLI verify output contract"
  "${_anosecurekit_security_model_text}"
  "verify-file"
  "verify-file-password"
  "take no output path"
  "discard"
  "recovered plaintext"
  "exit code 0"
  "exit code 1"
  "writes no stdout for failed commands")

_anosecurekit_require_terms(
  "README contributor entry point"
  "${_anosecurekit_readme_text}"
  "[CONTRIBUTING.md](CONTRIBUTING.md)"
  "one-command local release check")

_anosecurekit_require_terms(
  "README example and package-manager entry points"
  "${_anosecurekit_readme_text}"
  "[examples/basic](examples/basic)"
  "cmake --build build --config Release --target examples-check"
  "consumer"
  "CMake project against the installed package"
  "FetchContent"
  "release source archive"
  "release archive checksum"
  "package-recipes"
  "Homebrew, Conan, and vcpkg recipe")

_anosecurekit_require_terms(
  "positive fixture provenance"
  "${_anosecurekit_fixtures_readme_text}"
  "## Provenance and Regeneration"
  "Three `SKP1` password file fixtures"
  "not external standard vectors"
  "fixed keys, nonces, passwords, plaintext, AAD"
  "skp1-empty-aad.hex"
  "Do not refresh fixture bytes"
  "FixtureInventory.*"
  "release-preflight")

_anosecurekit_require_terms(
  "negative compatibility fixture matrix"
  "${_anosecurekit_negative_fixtures_readme_text}"
  "## Coverage Matrix"
  "| Family | `FORMAT.md` reject rule group | Fixture coverage | Regression check |"
  "`SKT1` structural format rules"
  "malformed magic, unsupported version, missing tag, minimum size"
  "`SKF1` structural format rules"
  "unsupported Cipher/KDF"
  "non-final short chunk"
  "`SKP1` structural format rules"
  "unsupported scrypt parameters"
  "skp1-unsupported-scrypt-n.hex"
  "skp1-unsupported-scrypt-r.hex"
  "skp1-unsupported-scrypt-p.hex"
  "duplicate index is generated in test"
  "Generic authentication failures"
  "Path output safety"
  "Stream rollback limits"
  "Future streaming formats"
  "plaintext-before-auth behavior"
  "output ownership")

_anosecurekit_require_terms(
  "fuzz corpus and scheduled job policy"
  "${_anosecurekit_fuzzing_text}"
  "## Corpus Policy"
  "Keep checked-in corpus entries small, stable, and format-focused."
  "tests/fixtures"
  "tests/fuzz/corpus"
  "Minimized crash reproducers"
  "Do not check in generated fuzz output"
  "## Scheduled Job Policy"
  "release readiness"
  "fixed wall-clock limit"
  "Artifact policy"
  "Failure triage path")

_anosecurekit_require_terms(
  "coverage reporting policy"
  "${_anosecurekit_coverage_text}"
  "Coverage is observational"
  "not a release gate"
  "ANOSECUREKIT_ENABLE_COVERAGE=ON"
  "coverage-report"
  "gcovr"
  "anosecurekit.html"
  "coverage.xml")

_anosecurekit_require_terms(
  "dependency update policy"
  "${_anosecurekit_dependency_policy_text}"
  "GitHub Actions"
  ".github/dependabot.yml"
  "release-workflow-check"
  "GoogleTest"
  "FetchContent"
  "OpenSSL Crypto 3.0 or newer"
  "Do not vendor OpenSSL"
  "release-preflight")

_anosecurekit_require_terms(
  "public API policy"
  "${_anosecurekit_public_api_policy_text}"
  "current exception boundary"
  "`anosecurekit::error`"
  "`anosecurekit::error_code`"
  "No public API change"
  "no format change"
  "affected APIs"
  "result-style API"
  "migration cost"
  "Rollback path"
  "caller"
  "worse with exceptions"
  "No current caller"
  "free-function oriented"
  "`packet_encryptor`"
  "`packet_decryptor`"
  "named current lifecycle state")

_anosecurekit_require_terms(
  "OpenSSL provider policy"
  "${_anosecurekit_openssl_policy_text}"
  "OpenSSL Crypto 3.0 or newer"
  "default library context"
  "provider configuration"
  "does not load providers"
  "does not create an"
  "`OSSL_LIB_CTX`"
  "does not set property queries"
  "FIPS"
  "`anosecurekit::error_code::backend_failure`"
  "`anosecurekit::error_code::authentication_failed`"
  "`anosecurekit::error_code::invalid_packet`"
  "`release-preflight`"
  "AES-256-GCM"
  "SHA-256"
  "HMAC-SHA-256"
  "HKDF-SHA-256"
  "scrypt"
  "random bytes"
  "No public API change"
  "no format change"
  "rollback path")

_anosecurekit_require_terms(
  "Dependabot GitHub Actions updates"
  "${_anosecurekit_dependabot_text}"
  "package-ecosystem: github-actions"
  "interval: weekly"
  "open-pull-requests-limit: 5")

_anosecurekit_require_terms(
  "internal boundary document"
  "${_anosecurekit_internals_text}"
  "Current Ownership"
  "`src/file.cpp`"
  "`src/file_detail.hpp`"
  "`src/file_crypto.cpp`"
  "`src/file_io.cpp`"
  "`src/cli/main.cpp`"
  "`src/cli/commands.cpp`"
  "`SKF1`/`SKP1` header parse/serialize"
  "exclusive temp-output creation"
  "Split Gates"
  "must not change public C++ APIs, CLI command shape, or `SKT1`/`SKF1`/`SKP1`"
  "Further splits require repeated edit"
  "--target release-preflight")

_anosecurekit_require_terms(
  "CMake examples check target"
  "${_anosecurekit_cmakelists_text}"
  "anosecurekit_example_basic"
  "examples-check")

_anosecurekit_require_terms(
  "basic example uses public API"
  "${_anosecurekit_example_main_text}"
  "anosecurekit/anosecurekit.hpp"
  "anosecurekit::encrypt"
  "anosecurekit::decrypt"
  "anosecurekit::sha256")

_anosecurekit_require_terms(
  "basic example CMake recipe"
  "${_anosecurekit_example_cmakelists_text}"
  "find_package(anosecurekit CONFIG"
  "anosecurekit::anosecurekit")

_anosecurekit_require_terms(
  "public aggregate header feature mapping"
  "${_anosecurekit_public_header_text}"
  "anosecurekit/aead.hpp"
  "anosecurekit/base64.hpp"
  "anosecurekit/compare.hpp"
  "anosecurekit/file.hpp"
  "anosecurekit/hash.hpp"
  "anosecurekit/hex.hpp"
  "anosecurekit/key_wrap.hpp"
  "anosecurekit/packet_stream.hpp"
  "anosecurekit/random.hpp"
  "anosecurekit/version.hpp")

_anosecurekit_require_terms(
  "public hex header API mapping"
  "${_anosecurekit_hex_header_text}"
  "hex_encode"
  "hex_decode")
_anosecurekit_require_terms(
  "public base64 header API mapping"
  "${_anosecurekit_base64_header_text}"
  "base64_encode"
  "base64_decode"
  "base64url_encode"
  "base64url_decode")
_anosecurekit_require_terms(
  "public hash header API mapping"
  "${_anosecurekit_hash_header_text}"
  "sha256"
  "hmac_sha256"
  "hkdf_sha256"
  "output_size == 0 returns an empty vector")
_anosecurekit_require_terms(
  "public compare header API mapping"
  "${_anosecurekit_compare_header_text}"
  "constant_time_equal"
  "Input lengths are"
  "must not be secret")
_anosecurekit_require_terms(
  "public random header API mapping"
  "${_anosecurekit_random_header_text}"
  "random_bytes"
  "generate_key"
  "random_token")
_anosecurekit_require_terms(
  "public AEAD header API mapping"
  "${_anosecurekit_aead_header_text}"
  "encrypt"
  "decrypt"
  "Authenticates the whole SKT1 packet before returning plaintext"
  "generic authentication failure")
_anosecurekit_require_terms(
  "public key wrap header API mapping"
  "${_anosecurekit_key_wrap_header_text}"
  "wrap_key"
  "unwrap_key")
_anosecurekit_require_terms(
  "public packet stream header API mapping"
  "${_anosecurekit_packet_stream_header_text}"
  "packet_encryptor"
  "packet_decryptor")
_anosecurekit_require_terms(
  "public file header API mapping"
  "${_anosecurekit_file_header_text}"
  "seal_file"
  "open_file"
  "seal_file_with_password"
  "open_file_with_password"
  "refuses an existing output path"
  "temporary file"
  "Stream overload writes to caller-owned output"
  "Password bytes are used exactly as supplied"
  "no trimming, normalization")
_anosecurekit_require_terms(
  "public version header API mapping"
  "${_anosecurekit_version_header_text}"
  "version()"
  "version_major"
  "version_minor"
  "version_patch")

_anosecurekit_require_terms(
  "CLI release surface mapping"
  "${_anosecurekit_cli_source_text}"
  "anosecurekit token <byte-size>"
  "anosecurekit sha256 --text <text>"
  "anosecurekit hmac-sha256 --key-hex <hex>"
  "anosecurekit hkdf-sha256 --key-hex <hex>"
  "anosecurekit hex-encode --text <text>"
  "anosecurekit base64url-encode --text <text>"
  "anosecurekit wrap-key"
  "anosecurekit unwrap-key"
  "anosecurekit encrypt"
  "anosecurekit decrypt"
  "anosecurekit seal-file"
  "anosecurekit open-file"
  "anosecurekit verify-file"
  "anosecurekit seal-file-password"
  "anosecurekit open-file-password"
  "anosecurekit verify-file-password")

_anosecurekit_forbid_terms(
  "README web middleware scope expansion"
  "${_anosecurekit_readme_text}"
  "Node.js"
  "package.json"
  "TEST_SUMMARY"
  "Express"
  "Koa"
  "Fastify"
  "JWT"
  "CSRF"
  "CORS"
  "NestJS"
  "rate limiting"
  "diagnostic routes")
_anosecurekit_forbid_terms(
  "FORMAT web middleware scope expansion"
  "${_anosecurekit_format_text}"
  "Node.js"
  "package.json"
  "TEST_SUMMARY"
  "Express"
  "Koa"
  "Fastify"
  "JWT"
  "CSRF"
  "CORS"
  "NestJS"
  "rate limiting"
  "diagnostic routes")
_anosecurekit_forbid_terms(
  "SECURITY_MODEL web middleware scope expansion"
  "${_anosecurekit_security_model_text}"
  "Node.js"
  "package.json"
  "TEST_SUMMARY"
  "Express"
  "Koa"
  "Fastify"
  "JWT"
  "CSRF"
  "CORS"
  "NestJS"
  "rate limiting"
  "diagnostic routes")

foreach(_anosecurekit_target_name IN ITEMS check package-check release-workflow-check)
  _anosecurekit_require_text(
    "README local target ${_anosecurekit_target_name}"
    "${_anosecurekit_readme_text}"
    "--target ${_anosecurekit_target_name}")
  _anosecurekit_require_text(
    "release checklist included target ${_anosecurekit_target_name}"
    "${_anosecurekit_release_checklist_text}"
    "${_anosecurekit_target_name}")
endforeach()

_anosecurekit_require_terms(
  "CMake coverage target"
  "${_anosecurekit_cmakelists_text}"
  "ANOSECUREKIT_ENABLE_COVERAGE"
  "coverage-report"
  "GCOVR_EXE"
  "--html-details"
  "--xml"
  "--print-summary")
_anosecurekit_require_terms(
  "README coverage target"
  "${_anosecurekit_readme_text}"
  "ANOSECUREKIT_ENABLE_COVERAGE"
  "coverage-report"
  "docs/COVERAGE.md")
_anosecurekit_require_terms(
  "CMake benchmark target"
  "${_anosecurekit_cmakelists_text}"
  "anosecurekit_benchmarks"
  "benchmarks/crypto_file_bench.cpp"
  "benchmarks-check")
_anosecurekit_require_terms(
  "benchmark source surfaces"
  "${_anosecurekit_benchmark_source_text}"
  "sha256_64k"
  "aead_roundtrip_64k"
  "file_roundtrip_2m"
  "anosecurekit::sha256"
  "anosecurekit::encrypt"
  "anosecurekit::decrypt"
  "anosecurekit::seal_file"
  "anosecurekit::open_file")
_anosecurekit_require_terms(
  "benchmark documentation"
  "${_anosecurekit_benchmarks_doc_text}"
  "cmake --build build --config Release --target benchmarks-check"
  "sha256_64k"
  "aead_roundtrip_64k"
  "file_roundtrip_2m"
  "not a performance guarantee")

_anosecurekit_require_text(
  "README local target release-preflight"
  "${_anosecurekit_readme_text}"
  "--target release-preflight")
_anosecurekit_require_text(
  "release checklist local target release-preflight"
  "${_anosecurekit_release_checklist_text}"
  "--target release-preflight")
_anosecurekit_require_terms(
  "release provenance verification docs"
  "${_anosecurekit_release_checklist_text}"
  "GitHub artifact attestations"
  "anosecurekit-X.Y.Z-release.spdx.json"
  "gh attestation verify SHA256SUMS.txt --repo anothel/anosecurekit"
  "sha256sum -c SHA256SUMS.txt"
  "docs/RELEASE_NOTES.md"
  "Do not introduce a separate `CHANGELOG.md`"
  "Release notes mention the same user-visible changes"
  "run `fuzz-smoke`"
  "extra parser smoke check"
  "Publish Package Recipes"
  "package-recipes"
  "checksum matches `SHA256SUMS.txt`")
_anosecurekit_require_terms(
  "release verification user guide"
  "${_anosecurekit_verify_release_text}"
  "SHA256SUMS.txt"
  "sha256sum -c SHA256SUMS.txt"
  "Get-FileHash"
  "gh attestation verify SHA256SUMS.txt --repo anothel/anosecurekit"
  "anosecurekit-X.Y.Z-release.spdx.json"
  "Source vs Binary Archives"
  "What This Does Not Prove")
_anosecurekit_require_terms(
  "release checklist dependency hygiene"
  "${_anosecurekit_release_checklist_text}"
  "docs/DEPENDENCY_POLICY.md"
  "release-workflow-check"
  "OpenSSL or GoogleTest"
  "release-preflight")
_anosecurekit_require_terms(
  "README release provenance claim"
  "${_anosecurekit_readme_text}"
  "artifact attestations for release assets"
  "release SPDX SBOM"
  "release provenance attestation wiring")

_anosecurekit_require_terms(
  "current release notes"
  "${_anosecurekit_release_notes_text}"
  "## v${ANOSECUREKIT_PROJECT_VERSION}"
  "`anosecurekit verify-file`"
  "`anosecurekit verify-file-password`"
  "checked basic C++ example"
  "negative compatibility coverage"
  "release SPDX SBOM"
  "GitHub provenance attestation checks"
  "Homebrew, Conan, and vcpkg recipe draft generation"
  "`spdx-check`, `legacy-name-check`, and `cli-docs-check`"
  "`anosecurekit file sealing v1`"
  "No intentional `SKT1` or `SKP1` format change."
  "Intentional pre-release `SKF1` compatibility break"
  "Breaking rename from the previous SecureKit surface")

_anosecurekit_require_terms(
  "license policy docs"
  "${_anosecurekit_license_policy_text}"
  "# AnoSecureKit License Policy"
  "Mozilla Public License 2.0"
  "Commercial use is allowed"
  "Closed-source application use is allowed"
  "file-level copyleft"
  "Private Or Commercial Native Crypto Assets")

_anosecurekit_require_terms(
  "documentation guide"
  "${_anosecurekit_documentation_guide_text}"
  "# AnoSecureKit Documentation Guide"
  "docs/CLI.md"
  "docs/FORMAT.md"
  "docs/LICENSE_POLICY.md"
  "cli-docs-check"
  "SPDX-License-Identifier: MPL-2.0")

_anosecurekit_require_terms(
  "license website page"
  "${_anosecurekit_license_page_text}"
  "AnoSecureKit License"
  "MPL-2.0"
  "Modified files"
  "Native crypto boundary")

_anosecurekit_require_terms(
  "release hygiene scripts"
  "${_anosecurekit_spdx_check_text};${_anosecurekit_legacy_check_text};${_anosecurekit_cli_docs_check_text}"
  "SPDX-License-Identifier: MPL-2.0"
  "securekit file sealing v1"
  "docs/CLI.md does not contain the exact current anosecurekit --help output")

_anosecurekit_require_terms(
  "package recipe generator"
  "${_anosecurekit_package_recipe_check_text}"
  "package-recipes"
  "homebrew/anosecurekit.rb"
  "conan/conanfile.py"
  "vcpkg/portfile.cmake"
  "vcpkg/vcpkg.json"
  "SHA256SUMS.txt"
  "file(SHA256"
  "file(SHA512"
  "https://github.com/anothel/anosecurekit/releases/download/v\${ANOSECUREKIT_PROJECT_VERSION}/")

_anosecurekit_require_terms(
  "SECURITY private advisory path"
  "${_anosecurekit_security_text}"
  "https://github.com/anothel/anosecurekit/security/advisories/new"
  "https://github.com/anothel"
  "Do not publish details")
_anosecurekit_require_terms(
  "SECURITY vulnerability report template"
  "${_anosecurekit_security_text}"
  "AnoSecureKit"
  "version"
  "tag"
  "commit"
  "OS"
  "compiler"
  "CMake"
  "OpenSSL"
  "provider configuration"
  "reproducer"
  "expected behavior"
  "actual behavior"
  "affected API"
  "CLI command"
  "serialized format"
  "exploitability")
_anosecurekit_require_terms(
  "SECURITY release note requirements"
  "${_anosecurekit_security_text}"
  "affected surface"
  "fixed version"
  "upgrade instructions"
  "`SKT1`"
  "`SKF1`"
  "`SKP1`"
  "data needs"
  "regenerated")

_anosecurekit_require_terms(
  "FORMAT v1 serialized format docs"
  "${_anosecurekit_format_text}"
  "# AnoSecureKit Format Specification"
  "`SKT1`"
  "`SKF1`"
  "`SKP1`"
  "Caller-provided AAD"
  "nonce = header.nonce_prefix || chunk_index_be32"
  "Scrypt N"
  "## Compatibility Rules"
  "## Security Notes"
  "Future streaming formats"
  "plaintext-before-auth"
  "output ownership"
  "unverified"
  "Stream open APIs")

_anosecurekit_require_terms(
  "SECURITY_MODEL goals and non-goals"
  "${_anosecurekit_security_model_text}"
  "# AnoSecureKit Security Model"
  "## Threat Model"
  "## Non-Goals"
  "## AEAD Authentication Rules"
  "## File Output Safety"
  "## Future Streaming Format Gate"
  "## Password-Based Encryption"
  "## Error Message Policy"
  "## Known Limitations"
  "custom cryptographic primitives"
  "TLS or networking"
  "secure key storage"
  "guaranteed memory erasure"
  "caller-selected nonces"
  "wrong AAD"
  "`packet_decryptor`"
  "unverified plaintext"
  "temporary file"
  "`N = 32768`"
  "`maxmem = 64 MiB`"
  "invalid_input"
  "invalid_encoding"
  "invalid_packet"
  "authentication_failed"
  "backend_failure"
  "docs/PUBLIC_API_POLICY.md"
  "docs/OPENSSL_POLICY.md"
  "OpenSSL Providers and Backend Errors"
  "verified-output-only"
  "explicit early-plaintext"
  "negative fixture"
  "default library context"
  "provider configuration"
  "FIPS providers"
  "Release assets are checksummed and provenance-attested by GitHub Actions"
  "Release assets include a generated SPDX SBOM")

_anosecurekit_require_terms(
  "external security review packet"
  "${_anosecurekit_external_security_review_text}"
  "# AnoSecureKit External Security Review Packet"
  "Review timing"
  "after the matching GitHub Release source assets are uploaded"
  "Package-channel publication can happen separately"
  "Review Scope"
  "`SKT1` packet parser/reject rules"
  "`SKF1`/`SKP1` file parsing"
  "path output safety"
  "stream/stdout output ownership"
  "AAD handling"
  "password-derived key handling"
  "release/security-reporting docs"
  "Out Of Scope"
  "Finding Intake"
  "affected API, CLI command, serialized format, CMake package surface, release asset, or security-reporting surface"
  "Regression Gate"
  "negative fixture"
  "tests/fuzz/corpus"
  "release-preflight"
  "Rollback")

_anosecurekit_require_terms(
  "KDF agility downgrade and fixture gates"
  "${_anosecurekit_kdf_agility_text}"
  "# AnoSecureKit KDF Agility Policy"
  "## Current SKP1 Profile Spec"
  "`SKP1` version `0x01`"
  "`tests/fixtures/skp1-known-password-file.hex`"
  "`tests/fixtures/skp1-empty-aad.hex`"
  "`tests/fixtures/skp1-binary-aad.hex`"
  "Downgrade Policy"
  "fail closed"
  "memory and time upper bounds"
  "Fixture Gate"
  "at least three"
  "compatibility vectors"
  "one old `SKP1` `KDF ID 0x01` vector"
  "one new-profile vector with non-empty plaintext and AAD"
  "one new-profile vector with binary plaintext or binary AAD")

set(_anosecurekit_artifact_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/artifacts")
if(NOT IS_DIRECTORY "${_anosecurekit_artifact_dir}")
  message(FATAL_ERROR "Package artifact directory not found: ${_anosecurekit_artifact_dir}")
endif()

file(GLOB _anosecurekit_release_artifacts LIST_DIRECTORIES FALSE
  "${_anosecurekit_artifact_dir}/*")
list(LENGTH _anosecurekit_release_artifacts _anosecurekit_release_artifact_count)
if(_anosecurekit_release_artifact_count EQUAL 0)
  message(FATAL_ERROR "No package artifacts found under ${_anosecurekit_artifact_dir}")
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
  message(FATAL_ERROR "No binary package artifacts found for ${ANOSECUREKIT_PROJECT_VERSION}")
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

foreach(_anosecurekit_release_artifact IN LISTS _anosecurekit_release_artifacts)
  get_filename_component(_anosecurekit_release_artifact_name "${_anosecurekit_release_artifact}" NAME)
  if(NOT _anosecurekit_release_artifact_name MATCHES "\\.(zip|tar\\.gz)$")
    message(FATAL_ERROR "Package artifact extension mismatch: ${_anosecurekit_release_artifact_name}")
  endif()
  string(FIND
    "${_anosecurekit_release_artifact_name}"
    "${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-"
    _anosecurekit_release_artifact_prefix_at)
  if(NOT _anosecurekit_release_artifact_prefix_at EQUAL 0)
    message(FATAL_ERROR "Package artifact version mismatch: ${_anosecurekit_release_artifact_name}")
  endif()
endforeach()

set(_anosecurekit_release_asset_dir "${ANOSECUREKIT_PACKAGE_CHECK_ROOT}/release-assets")
if(NOT IS_DIRECTORY "${_anosecurekit_release_asset_dir}")
  message(FATAL_ERROR "Release asset staging directory not found: ${_anosecurekit_release_asset_dir}")
endif()

set(_anosecurekit_checksum_file "${_anosecurekit_release_asset_dir}/SHA256SUMS.txt")
if(NOT EXISTS "${_anosecurekit_checksum_file}")
  message(FATAL_ERROR "Release asset checksum file not found: ${_anosecurekit_checksum_file}")
endif()

set(_anosecurekit_sbom_name "${ANOSECUREKIT_PROJECT_NAME}-${ANOSECUREKIT_PROJECT_VERSION}-release.spdx.json")
set(_anosecurekit_sbom_file "${_anosecurekit_release_asset_dir}/${_anosecurekit_sbom_name}")
if(NOT EXISTS "${_anosecurekit_sbom_file}")
  message(FATAL_ERROR "Release SBOM not found: ${_anosecurekit_sbom_file}")
endif()
file(READ "${_anosecurekit_sbom_file}" _anosecurekit_sbom_text)
_anosecurekit_require_terms(
  "release SBOM SPDX content"
  "${_anosecurekit_sbom_text}"
  "\"spdxVersion\": \"SPDX-2.3\""
  "\"SPDXID\": \"SPDXRef-DOCUMENT\""
  "\"name\": \"${ANOSECUREKIT_PROJECT_NAME} ${ANOSECUREKIT_PROJECT_VERSION} release assets\""
  "\"packages\""
  "\"checksums\""
  "\"algorithm\": \"SHA256\"")

file(GLOB _anosecurekit_staged_release_assets LIST_DIRECTORIES FALSE
  "${_anosecurekit_release_asset_dir}/*")
list(FILTER _anosecurekit_staged_release_assets EXCLUDE REGEX "/SHA256SUMS\\.txt$")
list(LENGTH _anosecurekit_staged_release_assets _anosecurekit_staged_release_asset_count)
if(_anosecurekit_staged_release_asset_count EQUAL 0)
  message(FATAL_ERROR "No staged release assets found under ${_anosecurekit_release_asset_dir}")
endif()

file(STRINGS "${_anosecurekit_checksum_file}" _anosecurekit_checksum_lines)
list(LENGTH _anosecurekit_checksum_lines _anosecurekit_checksum_line_count)
if(NOT _anosecurekit_checksum_line_count EQUAL _anosecurekit_staged_release_asset_count)
  message(FATAL_ERROR "Release asset checksum line count does not match staged asset count")
endif()

set(_anosecurekit_checksum_asset_names)
foreach(_anosecurekit_checksum_line IN LISTS _anosecurekit_checksum_lines)
  if(NOT _anosecurekit_checksum_line MATCHES "^([0-9a-f]+)  (.+\\.(zip|tar\\.gz|spdx\\.json))$")
    message(FATAL_ERROR "Release asset checksum line format mismatch: ${_anosecurekit_checksum_line}")
  endif()
  set(_anosecurekit_expected_sha256 "${CMAKE_MATCH_1}")
  set(_anosecurekit_checksum_asset_name "${CMAKE_MATCH_2}")

  string(LENGTH "${CMAKE_MATCH_1}" _anosecurekit_checksum_hash_length)
  if(NOT _anosecurekit_checksum_hash_length EQUAL 64)
    message(FATAL_ERROR "Release asset checksum hash length mismatch: ${_anosecurekit_checksum_line}")
  endif()
  if(_anosecurekit_checksum_line MATCHES "  SHA256SUMS\\.txt$")
    message(FATAL_ERROR "Release asset checksum file must not include itself")
  endif()
  string(FIND "${_anosecurekit_checksum_asset_name}" "/" _anosecurekit_checksum_asset_slash_at)
  string(FIND "${_anosecurekit_checksum_asset_name}" "\\" _anosecurekit_checksum_asset_backslash_at)
  if(NOT _anosecurekit_checksum_asset_slash_at EQUAL -1 OR NOT _anosecurekit_checksum_asset_backslash_at EQUAL -1)
    message(FATAL_ERROR "Release asset checksum name must be a file name: ${_anosecurekit_checksum_asset_name}")
  endif()

  list(FIND _anosecurekit_checksum_asset_names "${_anosecurekit_checksum_asset_name}" _anosecurekit_checksum_duplicate_at)
  if(NOT _anosecurekit_checksum_duplicate_at EQUAL -1)
    message(FATAL_ERROR "Duplicate release asset checksum entry: ${_anosecurekit_checksum_asset_name}")
  endif()
  list(APPEND _anosecurekit_checksum_asset_names "${_anosecurekit_checksum_asset_name}")

  set(_anosecurekit_staged_asset "${_anosecurekit_release_asset_dir}/${_anosecurekit_checksum_asset_name}")
  if(NOT EXISTS "${_anosecurekit_staged_asset}")
    message(FATAL_ERROR "Release asset checksum entry has no staged file: ${_anosecurekit_checksum_asset_name}")
  endif()
  file(SHA256 "${_anosecurekit_staged_asset}" _anosecurekit_actual_sha256)
  if(NOT _anosecurekit_actual_sha256 STREQUAL _anosecurekit_expected_sha256)
    message(FATAL_ERROR "Release asset checksum mismatch: ${_anosecurekit_checksum_asset_name}")
  endif()
endforeach()
