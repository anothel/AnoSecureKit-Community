<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Current Status

Maintenance resumption (2026-11-15): see [REVIVAL_PLAN.md](REVIVAL_PLAN.md) and
[REVIVAL_PHASE1_RESULTS.md](REVIVAL_PHASE1_RESULTS.md). The closeout record below
is historical; the resumed scope does not authorize a release or define a new SLA.

Status: CURRENT CLOSEOUT
Audit date: 2026-07-25 (Asia/Seoul)
Scope: AnoSecureKit Community only

## Final Closeout State

```text
PROJECT=AnoSecureKit-Community
ENGINEERING_STATUS=CLOSED_AND_FROZEN
REPOSITORY_STATE=PUBLIC_DEVELOPMENT_CLOSED

PUBLIC_RELEASE_BASELINE=
v0.4.0@694459ebe497d15ba75ef76a52fa7c36ddd7bcce

UNPUBLISHED_MAINTENANCE_BASELINE=
df1936777843415022a97f775c6e61eea6d99cb0

MAINTENANCE_SOURCE_VERSION=0.4.1
MAINTENANCE_RELEASE_STATE=UNPUBLISHED_AND_PARKED

PARKED_FEATURE_BASELINE=
develop/v0.5.0@9fe79dc1e0f8b9951e86c2707c70469611ab43e4

FEATURE_BRANCH_STATE=PARKED_NOT_MERGED
ACTIVE_NEXT_WORK=NONE
ACTIVE_RELEASE_ACTION=NONE
FUTURE_WORK=DEFERRED_NOT_SELECTED
REOPEN_REQUIRES_NEW_PRODUCT_DECISION
SECURITY_SUPPORT=EOL_ARCHIVAL_RESPONSE_ONLY
FINAL_CLOSEOUT_COMMIT=RECORDED_IN_EXTERNAL_CLOSEOUT_EVIDENCE
```

## Release Relationships

Published product:

```text
VERSION=0.4.0
COMMIT=694459ebe497d15ba75ef76a52fa7c36ddd7bcce
TAG=v0.4.0
RELEASE=PUBLISHED
```

Unpublished maintenance snapshot:

```text
SOURCE_VERSION=0.4.1
COMMIT=df1936777843415022a97f775c6e61eea6d99cb0
TAG=NONE
RELEASE=NONE
STATE=UNPUBLISHED_AND_PARKED
```

Parked feature candidate:

```text
BRANCH=develop/v0.5.0
COMMIT=9fe79dc1e0f8b9951e86c2707c70469611ab43e4
STATE=PARKED_NOT_MERGED
PUBLIC_SURFACE=NO
```

The C++ file-verification APIs and shared-library ABI allowlist on
`develop/v0.5.0` are not part of published v0.4.0 or the current public surface
on `main`.

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
fallback. `SKT1`, `SKF1`, and `SKP1` v1 meanings and the `SKF1` label
`anosecurekit file sealing v1` remain unchanged.

## Validation And Evidence

```text
MAIN_LOCAL_MSVC_RELEASE=PASS
MAIN_WARNINGS_AS_ERRORS=PASS
MAIN_OPENSSL_TESTS=124/124_PASS
MAIN_EXTERNAL_PROVIDER_TESTS=124/124_PASS
MAIN_ORDERED_TEST_INVENTORY=IDENTICAL
MAIN_FORMAT_CHECK=PASS
MAIN_DOCUMENT_AND_POLICY_CHECKS=PASS
MAIN_SAFE_INSTALL_INSTALLED_CLI_CONSUMER=PASS
PACKAGE_CHECK=NOT_RUN_ARTIFACT_CREATION_NOT_AUTHORIZED
RELEASE_PREFLIGHT=NOT_RUN_ARTIFACT_CREATION_NOT_AUTHORIZED

MAIN_HOSTED_CI=PASS run=29679908885
MAIN_CODEQL=PASS run=29679908924
MAIN_SCHEDULED_FUZZ=PASS run=29832291273

V0_4_1_RELEASE_JOB=NOT_RUN
V0_4_1_RELEASE_ASSETS=NONE
V0_4_1_SBOM_ATTESTATION=NONE
MAINTAINER_GPG_SIGNING=NONE
EXTERNAL_SECURITY_AUDIT=NOT_RUN
```

The published v0.4.0 evidence remains self-contained: 20 assets, checksums,
SPDX SBOM, and GitHub Actions artifact attestations passed retained
verification. The v0.4.0 Release body remains `NOT_EQUAL` to canonical notes
because of two normalized wording differences. GitHub Actions artifact
attestations do not mean the v0.4.0 tag or commit has a maintainer GPG
signature; neither is signed.

The 19 CodeQL alerts remain open. Static triage found 0 confirmed,
0 needs-review, and 19 not-actionable results; no alert state was changed.

## Published v0.4.0 Limitation

Published v0.4.0 generic CLI output can create key or plaintext files with mode
`0644` under a POSIX `umask 022`. The unpublished maintenance snapshot on
`main` fixes generic CLI output with exclusive temporary-file creation and mode
`0600`. That fix is not included in the published v0.4.0 Release. v0.4.1
publication is not approved or scheduled.

## Security Support

`EOL_ARCHIVAL_RESPONSE_ONLY` means:

- no active maintenance or release plan
- no supported version or response SLA
- future fixes, releases, or security response require a new explicit product
  decision
- the repository and published v0.4.0 materials remain historical references

## Enterprise Relation

```text
ENTERPRISE_INTEGRATION_BRANCH_MATCH=YES
ENTERPRISE_DEFAULT_MAIN_MATCH=NO
```

The inspected Enterprise integration branch consumes the exact Community
v0.4.0 tree. Enterprise default `main` does not. Enterprise alignment is outside
this Community closeout and must be handled separately.

## Repository Boundaries

Community does not contain Enterprise proprietary code or an AnoCrypto-C
adapter. AnoSecureKit Community makes no KCMVP, FIPS, certification, validation,
security-audit, or public-sector approval claim.
