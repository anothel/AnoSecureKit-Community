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
current main HEAD: b6dde65db44679fe91428663f98662a429b93cd6
current main subject: docs: record v0.4.0 publication evidence audit
main compared with v0.4.0: ahead by 2, behind by 0
post-tag changes: documentation only
release tag: v0.4.0
release commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
annotated tag object: a2dfd3b79335062ffe73ebfb520b4aac7f590e3d
annotated tag time: 2026-07-13T19:13:50+09:00
release published time: 2026-07-13T19:26:47+09:00
project version at tag: 0.4.0
```

`main` is two documentation-only commits ahead of `v0.4.0`. No post-tag C++
source, public header, CLI source, CMake build logic, test fixture, or v1 format
change was identified.

The released revision remains exactly
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

The audited `v0.3.0..v0.4.0` change and the two post-tag documentation commits did
not modify the public header tree or CLI source tree.

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

## Verification Summary

Evidence labels used here:

- `PASS`: executed or resolved successfully with retained evidence for the stated
  revision.
- `RECORDED`: reported by an earlier record, but the complete evidence was not
  independently reproduced in the current audit.
- `UNVERIFIED`: current evidence was unavailable or not assessed.
- `DEFERRED`: execution was blocked by a stated dependency, platform, tool, or
  service condition.
- `FAIL`: an executed check did not meet its gate.

| Surface | Status | Note |
| --- | --- | --- |
| Current `main` identity | PASS | `b6dde65...`; two documentation-only commits after the tag |
| `v0.4.0` tag/commit/version alignment | PASS | Tag resolves to `694459ebe...`; CMake version is `0.4.0` |
| GitHub Release object | PASS | Public, non-draft, non-prerelease Release recovered |
| Release title and publication time | PASS | `AnoSecureKit Community v0.4.0`; 2026-07-13 19:26:47 KST |
| Release body parity with repository release notes | UNVERIFIED | Body equivalence was not included in the reported analysis |
| Release asset contract | PASS | 20/20 expected assets present; API/download size inventory matched |
| `SHA256SUMS.txt` | PASS | 19/19 listed files verified |
| SPDX release SBOM | PASS | 18/18 package checksums matched downloaded assets |
| GitHub asset digest fields | PASS | 20/20 matched downloaded bytes |
| Artifact attestations | PASS | Supplementary `gh 2.95.0` serial verification passed 20/20 |
| Collector-manifest attestation row | DEFERRED | Collection host used `gh 2.46.0`, which lacked `gh attestation verify` |
| Hosted tag-push CI | PASS | Run `29242038502`; all 10 jobs succeeded |
| Windows lanes | PASS | 4/4 exact-commit jobs succeeded |
| macOS lanes | PASS | 2/2 exact-commit jobs succeeded |
| Exact-commit CodeQL execution | PASS | Two C++ analyses completed without analysis error or warning |
| CodeQL result triage | UNVERIFIED | Each analysis reports `results_count=19`; alert meaning/severity not yet reviewed |
| OpenSSL/external 124-test parity | RECORDED | v0.4.0 preparation records report 124/124 for both assemblies |
| Current local parity rerun | DEFERRED | GoogleTest package/cache was unavailable in the earlier audit environment |
| Scheduled fuzz smoke | FAIL | Run `29334006653`; uncaught `anosecurekit::error`, exit 77 |

The scheduled fuzz failure is not a publication-integrity failure. It is the
current P0 maintenance finding and must be fixed in Community.

See `docs/RELEASE_AND_EVIDENCE_STATUS.md` for detailed hosted evidence and
`docs/NEXT_WORK_QUEUE.md` for the active queue.

## Snapshot Integrity Note

The original uploaded code snapshot reported EOL-only worktree modifications in
`LICENSE`, `docs/FORMAT.md`, and `docs/RELEASE_NOTES.md`. No semantic difference
remained when end-of-line changes were ignored. A release operation must still
start from a clean worktree.

## Repository Boundaries

Community does not own or include Enterprise proprietary code, an AnoCrypto-C
adapter, customer delivery policy, or AnoCrypto-C implementation work. See
`docs/CROSS_REPOSITORY_BOUNDARY.md`.

AnoSecureKit Community makes no KCMVP, FIPS, certification, validation, or
public-sector approval claim.
