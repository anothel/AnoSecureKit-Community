<!-- SPDX-License-Identifier: MPL-2.0 -->
# Repository rules

- Work on a dedicated branch from the reviewed baseline; never edit main directly.
- Preserve the public C++ API, package/target names and SKT1/SKF1/SKP1 v1 bytes,
  fixtures, scrypt parameters and `anosecurekit file sealing v1` HKDF label.
- Community ships OpenSSL Crypto 3.x only. Respect the caller's provider context;
  external providers are build-tree-only, with no silent fallback or Enterprise code.
- Authenticate before committing path output. Use exclusive private temporary files,
  POSIX 0600 (subject to a more restrictive umask), and atomic no-overwrite commit.
  Stream/stdout output cannot be rolled back; never promise otherwise.
- Keep errors generic and secret-free. Do not promise secure erasure, external audit,
  certification, FIPS or KCMVP status without evidence.
- Add regression tests for confirmed defects before fixes; retain working hardening.
  Run CMake `check`, `format-check`, `package-check`, `external-backend-parity-check`
  and relevant document/boundary checks. Record commands, environment, actual results
  and skipped checks. POSIX builds with CLI tests require Python 3.7+ for the security matrix;
  CI/review must run it, not silently treat its absence as a pass.
- Keep changes and PRs independently reviewable. Do not merge, release, move existing
  tags, or dismiss alerts automatically. Historical closeout evidence is not current
  verification. See docs/REVIVAL_PLAN.md for resumed scope.
