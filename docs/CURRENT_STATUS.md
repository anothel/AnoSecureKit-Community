<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Current Status

Status: CURRENT
Audit date: 2026-07-17 (Asia/Seoul)
Scope: AnoSecureKit Community only

## Repository And Release Baselines

```text
product: AnoSecureKit Community
license: MPL-2.0
language: C++20
current branch: main
current main HEAD: 2fa66fb2fc7d5449d57f615dbc3543c34e5077d9
current main subject: docs: establish Community current-only documentation
release tag: v0.4.0
release commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
annotated tag object: a2dfd3b79335062ffe73ebfb520b4aac7f590e3d
annotated tag time: 2026-07-13T19:13:50+09:00
project version at tag: 0.4.0
```

`main` is one commit ahead of `v0.4.0`. The only post-tag commit is the
Community CURRENT ONLY documentation alignment commit. The comparison contains
no C++ source, public header, CLI source, CMake build logic, test fixture, or v1
format change.

The release revision remains exactly
`694459ebe497d15ba75ef76a52fa7c36ddd7bcce`. Do not describe the current `main`
HEAD as the `v0.4.0` release commit, and do not move or recreate the tag.

## Public Identity

The following public identity is unchanged:

```text
include root: include/anosecurekit
namespace: anosecurekit
CLI: anosecurekit
CMake package: anosecurekit
CMake target: anosecurekit::anosecurekit
```

The audited `v0.3.0..v0.4.0` change did not modify the public header tree or CLI
source tree. The post-tag documentation commit also did not change them.

## Product Backend

OpenSSL 3.x is the only shipped and supported Community production provider.
The external provider option is a build-tree-only integration seam for a parent
build. It is not installed, exported, packaged, released, or advertised as a
second Community production backend.

Missing, imported, wrong-type, top-level, and unknown external provider
configurations fail during configuration. Unsupported operations must not fall
back to OpenSSL or another provider.

## Format Compatibility

The v1 meanings remain fixed:

```text
SKT1: AES-256-GCM packet
SKF1: AES-256-GCM file sealing with HKDF-SHA-256
SKP1: AES-256-GCM password file sealing with scrypt
```

The compatibility-sensitive `SKF1` HKDF label remains:

```text
anosecurekit file sealing v1
```

No audited change altered the v1 fixtures, public format document, or format
semantics. A future algorithm or policy change must use a new format/version
rather than reinterpret an existing v1 magic/version pair.

## Audit Verification Summary

Evidence labels used here:

- `PASS`: executed or resolved successfully with retained evidence for the stated
  revision.
- `RECORDED`: reported by an earlier release-preparation record, but the complete
  machine-readable evidence was not retained in the audited snapshot.
- `UNVERIFIED`: current evidence was not available or could not be confirmed.
- `DEFERRED`: execution was intentionally not completed because a required local
  dependency, platform, service, or authorization was unavailable.

| Surface | Status | Note |
| --- | --- | --- |
| Current `main` identity | PASS | `2fa66fb2...`; one documentation-only commit after the tag |
| `v0.4.0` tag/commit/version alignment | PASS | Tag resolves to `694459ebe...`; CMake version is `0.4.0` |
| Release configure/build | PASS | Linux GCC/OpenSSL audit environment |
| CLI version | PASS | `anosecurekit 0.4.0` |
| Install/export and installed consumer | PASS | OpenSSL profile |
| Library-only consumer | PASS | OpenSSL profile |
| CPack source/binary packaging | PASS | Local package gate |
| Source archive rebuild/install | PASS | Local package gate |
| Backend boundary | PASS | OpenSSL implementation remained isolated |
| External provider hook | PASS | Parent-defined `OBJECT_LIBRARY` seam |
| Invalid external configurations | PASS | Fail-closed configure behavior |
| OpenSSL/external 124-test runs | RECORDED | v0.4.0 preparation record reports 124/124 for each assembly |
| Current audit 124-test rerun | DEFERRED | GoogleTest package/cache unavailable in the audit environment |
| Current external parity rerun | DEFERRED | Same dependency limitation |
| GitHub Release object and publication time | UNVERIFIED | Release-specific API evidence was not recovered |
| Published asset inventory, sizes and digests | UNVERIFIED | Workflow contract exists; publication data not recovered |
| Published `SHA256SUMS.txt` and SPDX SBOM | UNVERIFIED | No downloaded v0.4.0 publication evidence |
| GitHub artifact attestations | UNVERIFIED | No attestation verification result retained |
| Hosted tag-push CI | UNVERIFIED | No authoritative tag-run result recovered |
| Hosted CodeQL for the release commit | UNVERIFIED | CodeQL is main/schedule-triggered; exact-commit run not recovered |
| Windows and macOS tag validation | UNVERIFIED | Workflow lanes exist; tag results were not recovered |

See `docs/RELEASE_AND_EVIDENCE_STATUS.md` for the detailed publication evidence
contract and the expected workflow asset set.

## Snapshot Integrity Note

The original uploaded code snapshot reported EOL-only worktree modifications in
`LICENSE`, `docs/FORMAT.md`, and `docs/RELEASE_NOTES.md`. No semantic difference
remained when end-of-line changes were ignored. A release operation must still
start from a clean worktree and must not treat EOL-only changes as harmless after
asset generation.

## Repository Boundaries

Community does not own or include Enterprise proprietary code, an AnoCrypto-C
adapter, customer delivery policy, or AnoCrypto-C implementation work. See
`docs/CROSS_REPOSITORY_BOUNDARY.md`.

AnoSecureKit Community makes no KCMVP, FIPS, certification, validation, or
public-sector approval claim.
