<!-- SPDX-License-Identifier: MPL-2.0 -->
# Phase 4 file verification results — 2026-11-16

Baseline: latest main `0cb8bda7b6d96a11bd83228321707f83d62daa4c`.
Candidate reviewed: `develop/v0.5.0` at `9fe79dc1e0f8b9951e86c2707c70469611ab43e4`.
Branch: `codex/revival-phase4-file-verification`, targeting main.
Phase 3 remains deferred. No merge, release, tag change or alert dismissal.

## Integration decisions

Add four public path/istream verification overloads. Reuse the current stream
open functions with a private discard buffer, rather than copying the candidate's
header parsing and key derivation. Existing chunk plaintext and key cleanup
therefore apply, including late failures. No plaintext output path or output
stream is accepted. Preserve CLI routing/diagnostics, Phase 1 private output and
Phase 2 fault fixes. Unrelated candidate string rewrites, frozen release status
and the separate ABI visibility changes are excluded from this API PR.

All previous signatures, package/target names, SKF1/SKP1/SKT1 fixtures, scrypt
parameters, HKDF label and provider implementation remain unchanged.

## Reproduction

Linux x86_64, GCC 14.2.0, OpenSSL 3.5.7, CMake 3.31.6, Ninja 1.11.1,
Python 3.12.14, GoogleTest 1.14.0. Tools under `/workspace/.anosecurekit-tools`.
The default clang-format was 19.1.7 and failed on four unchanged files.
Installed 22.1.5 under `/tmp/phase4-format` (same version as Phase 2); the full
format check passed without reformatting unrelated files.

```sh
export PATH=/tmp/phase4-format/clang_format/data/bin:/workspace/.anosecurekit-tools/bin:$PATH
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DANOSECUREKIT_BUILD_TESTS=ON -DANOSECUREKIT_WARNINGS_AS_ERRORS=ON \
  -DCLANG_FORMAT_EXE=/tmp/phase4-format/clang_format/data/bin/clang-format
cmake --build build --target check -j 4
ctest --test-dir build --output-on-failure --parallel 4
cmake --build build --target format-check package-check external-backend-parity-check
cmake --build build --target backend-boundary-check document-alignment-check \
  cli-docs-check spdx-check legacy-name-check
```

## Actual local results

- Baseline: 128/128 tests passed before production edits.
- RED: new tests compiled with declarations, then failed linking all four missing
  verification overloads (`/tmp/phase4-api-red.log`).
- GREEN: five `FileVerification.*` tests passed. They cover both input overloads,
  empty/exact 1 MiB/multi-chunk files, final-tag tampering, truncation and trailing
  bytes after authenticated earlier chunks, generic wrong-key/password/AAD
  errors, all six positive and 27 negative file fixtures, binary password bytes,
  missing paths, bad streams and empty-password validation before I/O.
- Path cases assert input bytes remain unchanged and no other directory entry
  appears on success or failure.
- Full `check`: 133/133 passed, including CLI security and deterministic I/O
  fault matrices. Header signature assertions retain the existing APIs and add
  the new overloads; installed consumers call all four.
- Ordered provider parity: 133/133 passed with identical inventories, through
  the build-tree external seam using the OpenSSL forwarding test provider.
  This is not evidence for an Enterprise or other cryptographic implementation.
- Package checks passed: installed consumers and the existing package variants.
- Formatting, backend boundary, document alignment, CLI docs, SPDX and legacy
  identifier checks passed. An initial parity support check found the local
  scratch ledger missing SPDX; corrected that local file and reran successfully.

## Remaining evidence and risks

Remote Linux/MSVC/macOS checks are observed after opening the PR; results will
be recorded separately. Windows/macOS cannot be executed locally. Shared ABI
exports and old binaries are the separate dependent Phase 4 ABI PR, not proved
by static API tests. Stream exceptions follow existing open behavior. No secure
erasure, audit, certification or release-readiness claim is made. Phase 3 fuzz
campaigns and coverage remain deferred; this work does not close those gaps.
