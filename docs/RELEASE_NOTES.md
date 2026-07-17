<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Release Notes

## v0.4.0

AnoSecureKit Community v0.4.0 establishes an internal backend provider seam
while preserving OpenSSL 3.x as the only shipped Community production provider.

### Backend Architecture

- Isolated secure wiping from direct OpenSSL headers so common packet, file, and
  key-management code no longer includes `<openssl/crypto.h>`.
- Moved the unchanged OpenSSL implementation behind
  `src/backend/crypto_backend_openssl.cpp` and kept the internal contract in
  `src/backend/crypto_backend.hpp`.
- Added a build-tree-only external provider hook for parent projects that inject
  a non-imported `OBJECT_LIBRARY` provider target.
- Kept Community install, export, CPack, package, and release surfaces on the
  OpenSSL profile; no proprietary provider is included or shipped.
- Made unsupported, missing, imported, wrong-type, and top-level external
  provider configurations fail closed at configure time.

### Verification

- Added `backend-boundary-check`, `external-backend-hook-check`, and
  `external-backend-parity-check` to protect provider isolation and selection.
- Added `ANOSECUREKIT_TEST_PARALLEL_LEVEL` so top-level and nested parity tests
  use one validated, configurable parallelism setting during release preflight.
- The v0.4.0 release-preparation record reports the same 124-test inventory
  through the shipped OpenSSL profile and externally injected provider assembly.
- That record reports 124/124 configured tests through both assembly paths. The
  current retained-evidence state is tracked separately in
  `docs/RELEASE_AND_EVIDENCE_STATUS.md`; do not treat release notes alone as a
  current machine-verifiable PASS.
- Preserved package, install/export, installed-consumer, library-only consumer,
  source-rebuild, release-asset, checksum, SBOM, documentation, SPDX,
  legacy-name, and release-workflow checks.

### Compatibility

- No breaking public C++ API change.
- No CLI, package, namespace, include-root, or CMake target change.
- No cryptographic behavior change.
- No `SKT1`, `SKF1`, or `SKP1` format change.
- Preserved the compatibility-sensitive `SKF1` HKDF label
  `anosecurekit file sealing v1`.
- The external provider hook is not a second supported Community backend; it is
  an internal build-tree integration seam.
- No AnoCrypto-C implementation is included and no KCMVP or FIPS validation
  claim is made.

## v0.3.0

AnoSecureKit Community v0.3.0 is the first published Community release.
Versions before v0.3.0 were pre-Community internal development milestones and
were not published as AnoSecureKit Community releases.

### Product and Repository

- Established AnoSecureKit Community as the public `MPL-2.0` edition of the
  AnoSecureKit product family.
- Aligned repository links, release metadata, verification commands, package
  recipes, and SBOM namespaces with `AnoSecureKit-Community`.
- Preserved the package, public API, CLI, include root, namespace, and CMake
  identity as `anosecurekit` and `anosecurekit::anosecurekit`.

### Backend and Security Policy

- Kept OpenSSL 3.x as the sole Community production backend.
- Documented OpenSSL upgrade evidence requirements and rollback policy.
- Clarified the external proprietary module boundary: no AnoCrypto
  implementation or backend is included in Community.
- Made no KCMVP or FIPS validation claim.

### Licensing and Documentation

- Aligned project-owned files and release checks with `MPL-2.0` SPDX
  identifiers.
- Documented Community, Enterprise, and external AnoCrypto ownership
  boundaries.
- Clarified that separate commercial terms for external proprietary modules do
  not change the `MPL-2.0` license of Community files.

### Verification

- Passed a clean Release `release-preflight` build.
- Passed all 121/121 unit and CLI tests.
- Passed package, install/export, consumer, source rebuild, checksum, SBOM,
  documentation, SPDX, legacy-name, and release-workflow checks.

### Compatibility

- No breaking public C++ API change.
- No CLI, package, namespace, or CMake target change.
- No cryptographic behavior change.
- No `SKT1`, `SKF1`, or `SKP1` format change.
- Preserved the compatibility-sensitive `SKF1` HKDF label
  `anosecurekit file sealing v1`.

## v0.2.2

### Added

- Renamed the project surface to AnoSecureKit: `anosecurekit` package, CLI,
  include root, CMake target, and C++ namespace.
- Added `MPL-2.0` license policy documentation for commercial use, modified-file
  publication expectations, and enterprise review.
- Added release archive consumption docs and checked C++ example coverage.
- Added `spdx-check`, `legacy-name-check`, and `cli-docs-check` release hygiene
  targets.
- Added release SPDX SBOM, GitHub provenance attestation, and package recipe
  draft checks for Homebrew, Conan, and vcpkg.

### Hardened

- Expanded `release-preflight` to cover package artifacts, source archives,
  `SHA256SUMS.txt`, release notes, SBOM, provenance, examples, benchmarks, and
  dogfood checks.
- Expanded negative compatibility coverage for `SKT1`, `SKF1`, and `SKP1`.
- Updated the pre-release `SKF1` HKDF context label to
  `anosecurekit file sealing v1` and refreshed the `SKF1` known-answer fixtures
  before a public AnoSecureKit compatibility promise is made.
- Documented public API, OpenSSL provider, KDF agility, license policy, and
  internal split policies without adding new cryptographic algorithms or wire
  formats.
- Removed obsolete historical implementation plans from public docs; detailed
  completed work now belongs in Git history, release notes, or an internal GPT
  project source pack.

### Compatibility

- No intentional `SKT1` or `SKP1` format change.
- Intentional pre-release `SKF1` compatibility break: the HKDF context label now
  uses the AnoSecureKit name, and `SKF1` fixtures were regenerated accordingly.
- Breaking rename from the previous SecureKit surface: no `securekit` CLI,
  `securekit::` namespace, `include/securekit`, `SECUREKIT_*` options, or
  `securekit::securekit` CMake alias are provided in this release.

## v0.2.0

### Added

- Added `anosecurekit verify-file` and `anosecurekit verify-file-password` to
  authenticate sealed files without writing plaintext output.
- Added the checked basic C++ example and release archive consumption recipe.
- Added release SPDX SBOM generation and GitHub provenance attestation checks
  for release assets.
- Added Homebrew, Conan, and vcpkg recipe draft generation from checked release
  archive checksums.

### Hardened

- Expanded negative compatibility coverage for `SKT1`, `SKF1`, and `SKP1`
  structural reject rules.
- Strengthened `release-preflight` checks for documented CLI, format,
  packaging, release asset, SBOM, and provenance claims.

### Compatibility

- No intentional `SKT1`, `SKF1`, or `SKP1` format change.
- No breaking C++ API change.
