<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Release and Evidence Status

Status date: 2026-07-17 (Asia/Seoul)
Current code/tag baseline: `v0.4.0`

## Evidence Labels

- `PASS`: executed successfully in the stated environment and retained for the
  stated revision.
- `RECORDED`: a release-preparation record reports success, but the complete
  evidence was not retained or independently re-run in the current audit.
- `UNVERIFIED`: the evidence was not available or could not be confirmed.
- `DEFERRED`: execution was intentionally not completed because a dependency,
  platform, service, or authorization was unavailable.
- `FAIL`: executed and did not meet the gate.

A tag, documentation statement, workflow definition, or generated command is not
by itself proof that a release asset or hosted run exists.

## v0.4.0 Revision Identity

```text
branch: main
commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
tag: v0.4.0
project version: 0.4.0
```

The tag and `main` resolve to the same audited commit.

## Current Evidence Matrix

| Evidence | Status | Current statement |
| --- | --- | --- |
| Tag/version alignment | PASS | `v0.4.0` matches CMake `0.4.0` |
| Local OpenSSL build and CLI version | PASS | Executed during 2026-07-17 audit |
| Install/export and consumer checks | PASS | Executed locally |
| CPack source/binary and source rebuild | PASS | Executed locally |
| Backend boundary and external hook | PASS | Executed locally |
| OpenSSL 124-test inventory/run | RECORDED | Release notes report 124/124 |
| External assembly 124-test inventory/run | RECORDED | Release notes report parity and 124/124 |
| Current audit 124-test/parity rerun | DEFERRED | GoogleTest package/cache unavailable |
| GitHub Release object for v0.4.0 | UNVERIFIED | Not confirmed by retained audit evidence |
| Published release asset names and sizes | UNVERIFIED | Not confirmed |
| Published `SHA256SUMS.txt` | UNVERIFIED | Not confirmed |
| Published SPDX release SBOM | UNVERIFIED | Not confirmed |
| GitHub artifact attestations | UNVERIFIED | Not confirmed |
| Hosted CI for tag commit | UNVERIFIED | No retained run evidence confirmed |
| Hosted CodeQL for tag commit | UNVERIFIED | No retained run evidence confirmed |
| Windows/macOS current tag validation | UNVERIFIED | Not executed in the audit environment |

## Required Publication Evidence

A Community release may be described as published and verified only after the
following are retained for the exact tag commit:

1. GitHub Release identity and publication timestamp;
2. complete asset inventory with names and sizes;
3. `SHA256SUMS.txt` and verified digest results;
4. `anosecurekit-X.Y.Z-release.spdx.json`;
5. GitHub artifact attestation verification results;
6. hosted CI and CodeQL run URLs/conclusions;
7. source and binary consumer verification where claimed;
8. release notes matching `docs/RELEASE_NOTES.md`.

Store a compact machine-readable or Markdown evidence manifest under a versioned
`artifacts/vX.Y.Z-...` directory only after the evidence is collected. Do not
copy credentials, private runner data, or proprietary product information into
Community.

## Local Release Gate

The expected local gate remains:

```sh
cmake --build build --config Release --target release-preflight
```

The configured `ANOSECUREKIT_TEST_PARALLEL_LEVEL` must apply consistently to the
top-level test run and nested external-provider parity validation.

A local pass does not replace hosted publication evidence. Hosted publication
evidence does not replace local compatibility and package validation.

## Claims Boundary

AnoSecureKit Community does not claim KCMVP, FIPS validation, certification, or
public-sector approval. An OpenSSL version or provider being used does not create
such a claim for AnoSecureKit Community.
