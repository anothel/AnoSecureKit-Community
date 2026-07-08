<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Release Notes

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
- Documented public API, OpenSSL provider/FIPS, KDF agility, license policy, and
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
