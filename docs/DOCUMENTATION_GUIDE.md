<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Documentation Guide

This guide defines which public documents are canonical for AnoSecureKit release
preparation. Historical implementation plans should stay in Git history or
private project notes, not in public user documentation.

## Canonical User Docs

- `README.md`: project identity, requirements, build, release, API overview, and
  CMake consumption.
- `docs/CLI.md`: exact checked CLI help output, examples, recipes, exit codes,
  and stdin/stdout behavior.
- `docs/FORMAT.md`: `SKT1`, `SKF1`, and `SKP1` serialized format contract.
- `docs/SECURITY_MODEL.md`: supported threat model, non-goals, authentication
  rules, output safety, password file sealing, and known limitations.
- `docs/LICENSE_POLICY.md`: project-level `MPL-2.0` explanation and file-level
  boundary.
- `docs/VERIFY_RELEASE.md`: user-side release asset verification.

## Canonical Maintainer Docs

- `CONTRIBUTING.md`: local release gate, contribution license expectations, and
  documentation update rules.
- `docs/RELEASE_CHECKLIST.md`: release operator checklist.
- `docs/RELEASE_NOTES.md`: source of truth for user-visible release notes.
- `docs/ROADMAP.md`: future work only.
- `docs/PUBLIC_API_POLICY.md`, `docs/BACKEND_ARCHITECTURE.md`,
  `docs/EDITIONS.md`, `docs/ANOCRYPTO_BOUNDARY.md`, `docs/OPENSSL_POLICY.md`,
  `docs/DEPENDENCY_POLICY.md`, `docs/KDF_AGILITY.md`, `docs/FUZZING.md`,
  `docs/COVERAGE.md`, `docs/BENCHMARKS.md`, `docs/DOGFOODING.md`, and
  `docs/EXTERNAL_SECURITY_REVIEW.md`: focused maintainer policies and gates.

## Website Docs

The GitHub Pages files under `docs/*.html`, `docs/guides/`, `docs/tools/`, and
`docs/assets/` are a public website surface. Keep them consistent with the
canonical Markdown docs. Do not add web crypto processing claims that exceed the
C++ library, CLI, or documented local browser tooling scope.

## Update Rules

- CLI behavior changes must update `docs/CLI.md` and keep `cli-docs-check`
  passing.
- Serialized byte-format changes must update `docs/FORMAT.md`, fixtures, and
  fixture inventory docs in the same change.
- Rename, license, or package-surface changes must update README, release notes,
  release checklist, and package/release checks.
- Old names may appear only in allowlisted migration or release-note context.
- New public source-controlled text files should include
  `SPDX-License-Identifier: MPL-2.0`.
