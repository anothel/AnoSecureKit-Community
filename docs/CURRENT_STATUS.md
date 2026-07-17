<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Current Status

Status: CURRENT
Audit date: 2026-07-17 (Asia/Seoul)
Scope: AnoSecureKit Community only

## Baseline

```text
product: AnoSecureKit Community
license: MPL-2.0
language: C++20
branch: main
HEAD: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
tag: v0.4.0
project version: 0.4.0
```

The `v0.4.0` tag resolves to the current `main` HEAD. No later commit was present
in the audited repository snapshot.

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
source tree.

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

- `PASS`: executed successfully during the 2026-07-17 audit.
- `RECORDED`: reported by an earlier release-preparation record, but the complete
  machine-readable evidence was not retained in the audited snapshot.
- `UNVERIFIED`: current external or hosted evidence was not available.
- `DEFERRED`: the audit could not execute the check because a required local
  dependency or platform was unavailable.

| Surface | Status | Note |
| --- | --- | --- |
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
| GitHub Release and assets | UNVERIFIED | Tag presence alone is not publication evidence |
| SHA-256, release SBOM and attestations | UNVERIFIED | Public release evidence not confirmed |
| Hosted CI and CodeQL for the tag commit | UNVERIFIED | No retained run evidence confirmed |
| Windows and macOS current validation | UNVERIFIED | Not executed in the audit environment |

See `docs/RELEASE_AND_EVIDENCE_STATUS.md` for the evidence contract.

## Snapshot Integrity Note

The uploaded audit snapshot reported EOL-only worktree modifications in
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
