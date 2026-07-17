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
audited implementation baseline: c3872c196452b561b1a545ee73204dca0df83dc7
baseline subject: fix: normalize hex fixtures in fuzz adapter
release tag: v0.4.0
release commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
release published time: 2026-07-13T19:26:47+09:00
project version at tag: 0.4.0
```

The exact current `main` SHA must be read from Git. Source-controlled status
files record the implementation baseline they audited rather than claiming that
their own commit is the current `main` SHA.

The released revision remains exactly
`694459ebe497d15ba75ef76a52fa7c36ddd7bcce`. Do not move or recreate the tag.

## Public Identity And Compatibility

```text
include root: include/anosecurekit
namespace: anosecurekit
CLI: anosecurekit
CMake package: anosecurekit
CMake target: anosecurekit::anosecurekit
```

OpenSSL 3.x remains the only shipped Community production provider. The external
provider remains a build-tree-only parent integration seam with no silent
fallback.

`SKT1`, `SKF1`, and `SKP1` v1 meanings and the `SKF1` label
`anosecurekit file sealing v1` remain unchanged.

## Verification Summary

| Surface | Status | Note |
| --- | --- | --- |
| v0.4.0 publication and integrity | PASS | 20 assets; checksum, SBOM, digests, attestations verified |
| Hosted v0.4.0 tag CI | PASS | Run `29242038502`; 10/10 jobs succeeded |
| Windows/macOS release lanes | PASS | Windows 4/4; macOS 2/2 |
| Exact-commit CodeQL execution | PASS | Two analyses completed; result triage remains open |
| Historical scheduled fuzz run | FAIL | Run `29334006653` exposed an adapter normalization defect |
| Fuzz adapter fix | PASS LOCAL | Commit `c3872c1`; focused seeds and all 5 fuzz targets passed |
| General CTest after fuzz fix | PASS LOCAL | 124/124 |
| Package/install/export after fuzz fix | PASS LOCAL | package-check and consumers passed |
| Hosted fuzz confirmation after fix | DEFERRED_EXTERNAL | GitHub Actions billing prevents runner execution |
| Current provider parity rerun | DEFERRED | Historical 124/124 remains recorded; machine-readable rerun pending |
| Repository EOL policy | PASS | `.gitattributes` defines deterministic LF policy |
| Source evidence exclusion | PASS | CPack and package-check reject repository-external evidence paths |

The billing blocker does not invalidate the completed local fuzz verification,
but the hosted confirmation must not be reported as PASS.

## Repository Boundaries

Community does not contain Enterprise proprietary code or an AnoCrypto-C adapter.
AnoSecureKit Community makes no KCMVP, FIPS, certification, validation, or
public-sector approval claim.
