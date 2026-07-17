<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Release and Evidence Status

Status date: 2026-07-17 (Asia/Seoul)
Current release code/tag baseline: `v0.4.0`

## Evidence Labels

- `PASS`: executed or resolved successfully with retained evidence for the stated
  revision.
- `RECORDED`: a release-preparation record reports success, but the complete
  evidence was not retained or independently re-run in the current audit.
- `UNVERIFIED`: the evidence was not available or could not be confirmed.
- `DEFERRED`: execution was intentionally not completed because a dependency,
  platform, service, or authorization was unavailable.
- `FAIL`: executed and did not meet the gate.

A tag, documentation statement, workflow definition, expected filename, or
generated command is not by itself proof that a GitHub Release object, published
asset, digest, SBOM, attestation, or hosted run exists.

## Repository And Release Revision Identity

```text
current main HEAD: 2fa66fb2fc7d5449d57f615dbc3543c34e5077d9
current main subject: docs: establish Community current-only documentation
main compared with v0.4.0: ahead by 1, behind by 0
post-tag change class: documentation only
release tag: v0.4.0
annotated tag object: a2dfd3b79335062ffe73ebfb520b4aac7f590e3d
release commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
annotated tag time: 2026-07-13T19:13:50+09:00
annotated tag subject: AnoSecureKit Community v0.4.0
project version at tag: 0.4.0
```

Tag/version alignment is `PASS`. The current `main` branch no longer resolves to
the release commit because `COMM-DOC-01` added one documentation-only commit.
The release tag remains unchanged and must not be moved or recreated.

## COMM-REL-01 Acquisition Result

The audit confirmed the commit and branch comparison through the connected
GitHub repository data and confirmed the annotated tag from the uploaded Git
object database.

The audit environment did not expose a release-specific GitHub REST action for
listing the `v0.4.0` Release object and assets. The available public HTML snapshot
still displayed the older `v0.3.0` release and an older repository state, so it
was not current enough to prove either presence or absence of `v0.4.0`.

The available commit status interface returned no legacy statuses, and the
available commit-workflow lookup returned no pull-request-triggered runs. Those
results are not sufficient to prove that a tag-push workflow did not run.
Accordingly, publication and hosted results remain `UNVERIFIED`, not `FAIL`.
No tag, Release, asset, workflow, or repository content was created or modified
by this audit.

## Current Evidence Matrix

| Evidence | Status | Current statement |
| --- | --- | --- |
| Current `main` identity | PASS | `2fa66fb2...`; one documentation-only commit after `v0.4.0` |
| Tag/version alignment | PASS | `v0.4.0` resolves to `694459ebe...`; CMake version is `0.4.0` |
| Annotated tag identity | PASS | Tag object, subject and 2026-07-13 19:13:50 KST timestamp recovered |
| Local OpenSSL build and CLI version | PASS | Executed during 2026-07-17 audit |
| Install/export and consumer checks | PASS | Executed locally |
| CPack source/binary and source rebuild | PASS | Executed locally |
| Backend boundary and external hook | PASS | Executed locally |
| OpenSSL 124-test inventory/run | RECORDED | Release notes report 124/124 |
| External assembly 124-test inventory/run | RECORDED | Release notes report parity and 124/124 |
| Current audit 124-test/parity rerun | DEFERRED | GoogleTest package/cache unavailable |
| GitHub Release object for v0.4.0 | UNVERIFIED | Release-specific API result not recovered |
| Release title, body and publication timestamp | UNVERIFIED | Expected title is known; actual object was not recovered |
| Published release asset names and sizes | UNVERIFIED | Expected workflow contract is listed below |
| Published asset digests | UNVERIFIED | No authoritative release asset response or download |
| Published `SHA256SUMS.txt` verification | UNVERIFIED | File not recovered from a v0.4.0 Release |
| Published SPDX release SBOM | UNVERIFIED | File not recovered from a v0.4.0 Release |
| GitHub artifact attestations | UNVERIFIED | No `gh attestation verify` result retained |
| Hosted CI for tag push | UNVERIFIED | Exact tag-run URL and conclusion not recovered |
| Hosted CodeQL for release commit | UNVERIFIED | Exact main-push/scheduled analysis for `694459e...` not recovered |
| Windows tag package/consumer evidence | UNVERIFIED | Workflow lanes exist; run and artifacts not recovered |
| macOS tag package/consumer evidence | UNVERIFIED | Workflow lane exists; run and artifacts not recovered |

## Expected v0.4.0 Workflow Asset Contract

The tag workflow requires the following publication shape before its release job
can upload assets:

```text
2 source archives
16 binary archives: 8 artifact families × ZIP/TGZ
1 SPDX release SBOM
1 SHA256SUMS.txt
= 20 expected uploaded files
```

Exact source and metadata names:

```text
anosecurekit-0.4.0-source.zip
anosecurekit-0.4.0-source.tar.gz
anosecurekit-0.4.0-release.spdx.json
SHA256SUMS.txt
```

Binary asset families, each requiring one `.zip` and one `.tar.gz` file whose
package filename starts with `anosecurekit-0.4.0-`:

```text
anosecurekit-ubuntu-latest-gcc-Release-packages
anosecurekit-ubuntu-latest-clang-Release-packages
anosecurekit-ubuntu-latest-gcc-Debug-packages
anosecurekit-windows-latest-msvc-Release-packages
anosecurekit-ubuntu-gcc-release-install-only-packages
anosecurekit-ubuntu-gcc-release-static-packages
anosecurekit-windows-msvc-release-shared-packages
anosecurekit-macos-clang-release-packages
```

The workflow-derived expected title is:

```text
AnoSecureKit Community v0.4.0
```

The workflow creates generated notes for a new Release and does not itself prove
that the published body matches `docs/RELEASE_NOTES.md`.

The preceding list is an expected contract only. It does not supply actual asset
sizes, final platform suffixes, GitHub-provided `digest` values, or downloaded
SHA-256 results. Do not manufacture those values from local packages or the
older v0.3.0 evidence directory.

## Authoritative Completion Procedure

Use the read-only `collect_v0.4.0-publication-evidence.sh` handoff script in an
authenticated GitHub CLI environment. It collects:

1. tag and current-main resolution;
2. the REST Release object or an authoritative 404;
3. full asset names, sizes, content types and GitHub digest fields;
4. downloaded assets and `SHA256SUMS.txt` verification;
5. SPDX SBOM package/checksum comparison;
6. GitHub artifact-attestation verification;
7. Actions runs, check runs and commit statuses for the release commit;
8. CodeQL analyses associated with the exact release commit where available.

Only that evidence, or equivalent authenticated API output, may change the
publication rows above from `UNVERIFIED` to `PASS`, `FAIL`, `NOT_PUBLISHED`, or a
specific `DEFERRED` external-blocker result.

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
