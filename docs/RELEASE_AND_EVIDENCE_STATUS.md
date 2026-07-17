<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Release and Evidence Status

Status date: 2026-07-17 (Asia/Seoul)
Current release code/tag baseline: `v0.4.0`

## Evidence Labels

- `PASS`: executed or resolved successfully with retained evidence for the stated
  revision.
- `RECORDED`: a prior record reports success, but the complete evidence was not
  independently reproduced in the current audit.
- `UNVERIFIED`: current evidence was unavailable or not assessed.
- `DEFERRED`: execution was blocked by a stated dependency, platform, tool, or
  service condition.
- `FAIL`: an executed check did not meet its gate.

Qualified labels such as `PASS LOCAL WITH EXECUTION CAVEATS` retain the base status
while naming a material execution limitation that must not be omitted.

## Repository And Release Identity

```text
audited repository baseline: a6b7b634214ea4db55efb7a69cd2e663ea052d61
implementation maintenance baseline: c3872c196452b561b1a545ee73204dca0df83dc7
implementation subject: fix: normalize hex fixtures in fuzz adapter
current main identity: resolve from Git at audit time
post-tag change classes: documentation/evidence and fuzz adapter maintenance
release tag: v0.4.0
annotated tag object: a2dfd3b79335062ffe73ebfb520b4aac7f590e3d
release commit: 694459ebe497d15ba75ef76a52fa7c36ddd7bcce
annotated tag time: 2026-07-13T19:13:50+09:00
release title: AnoSecureKit Community v0.4.0
release published time: 2026-07-13T19:26:47+09:00
release draft: false
release prerelease: false
project version at tag: 0.4.0
```

The tag remains unchanged. The current maintenance line is not the source revision
used to build the v0.4.0 assets. Source-controlled documents record an audited
baseline rather than chasing their own resulting commit SHA.

## COMM-REL-02 Authenticated Publication Result

Authenticated read-only collection recovered the Release object, all assets,
hosted workflow evidence, and exact-commit CodeQL analyses.

Publication result:

```text
Release object: PASS
20-file workflow contract: PASS
API/download size inventory: PASS
SHA256SUMS.txt: PASS, 19/19
SPDX SBOM: PASS, 18/18 package checksums
GitHub asset digests: PASS, 20/20
Windows jobs: PASS, 4/4
macOS jobs: PASS, 2/2
```

### Attestation Evidence

The Linux/WSL collector used GitHub CLI `2.46.0`, which did not provide
`gh attestation verify`; the collector manifest therefore records
`DEFERRED_GH_VERSION` for that row.

A supplementary authenticated verification used GitHub CLI `2.95.0` on Windows.
After one transient verifier-initialization error during the first parallel
attempt, a serial retry verified all 20 assets successfully. The publication
attestation conclusion is therefore `PASS`, provided the supplementary verifier
output is retained with the evidence archive. The original archive alone must
not be described as containing the successful attestation output.

### Release Body

The Release title, publication time, draft state, prerelease state, assets, and
integrity evidence were confirmed. Exact body parity with
`docs/RELEASE_NOTES.md` was not included in the reported result and remains
`UNVERIFIED`.

## Hosted Actions Evidence

Six runs and 24 jobs were associated with the exact release commit.

| Run | Workflow | Event | Conclusion | Relevant result |
| --- | --- | --- | --- | --- |
| `29459387103` | `github_actions in /. - Update #1462577323` | Dependabot | success | Dependabot job succeeded |
| `29334006653` | `Fuzz` | schedule | failure | Fuzz smoke failed with exit 77 |
| `29250834413` | `CodeQL` | schedule | success | C++ analysis job succeeded |
| `29242038502` | `AnoSecureKit CI` | tag `v0.4.0` | success | All 10 jobs, including GitHub Release, succeeded |
| `29241168496` | `AnoSecureKit CI` | main push | success | Nine build jobs succeeded; release job skipped |
| `29241168471` | `CodeQL` | push | success | C++ analysis job succeeded |

The successful tag workflow proves the hosted v0.4.0 build/package/release lanes
completed. It does not erase the later scheduled fuzz failure on the same source
revision.

## CodeQL Exact-Commit Evidence

Two C++ analyses were recovered for the release commit:

```text
analysis IDs: 1471089159, 1471719182
ref: refs/heads/main
CodeQL: 2.26.0
rules_count: 179 each
results_count: 19 each
analysis error: empty
analysis warning: empty
corresponding Actions runs: success
```

The CodeQL execution status is `PASS`.

COMM-CODEQL-01 recovered 19 unique alerts from the two byte-identical SARIF result
sets and completed static Community triage:

```text
unique alerts: 19
state: open 19/19
severity: warning 19/19
security severity: high 16, none 3
confirmed: 0
needs_review: 0
not_actionable: 19
```

Alert `#2` misclassified public SKP1 header metadata as sensitive plaintext.
Alerts `#3` through `#17` involved paths explicitly selected by a local CLI
operator, with no supported external-attacker boundary established. Alerts `#1`,
`#18`, and `#19` were correctness or maintainability results without a demonstrated
security consequence.

This triage conclusion does not change GitHub alert state. All 19 alerts remain
open, and no dismissal or update was performed. See
`docs/CODEQL_TRIAGE_STATUS.md`.

## Scheduled Fuzz Failure

Run `29334006653` failed in `Fuzz smoke` with exit `77`.

```text
target: anosecurekit_fuzz_skt1
exception: anosecurekit::error
message: hex input must contain an even number of characters
path: src/hex.cpp:60
      tests/fuzz/fuzz_utils.hpp:68
      tests/fuzz/skt1_fuzz.cpp:9
```

No crash artifact file was retained under `fuzz-artifacts/`. The adapter defect was
fixed by commit `c3872c196452b561b1a545ee73204dca0df83dc7`. The exact fixture,
existing odd-length seed, all five fuzz targets, general CTest 124/124, and package
checks passed locally. Hosted confirmation is `DEFERRED_EXTERNAL` because GitHub
Actions billing prevents runner execution. The production strict hex parser was
not weakened.


## COMM-VER-01 Local Provider Parity Result

The existing `external-backend-parity-check` completed successfully for an
implementation-equivalent reconstruction of repository reference
`a6b7b634214ea4db55efb7a69cd2e663ea052d61`. The reconstruction used the uploaded
`b6dde65...` baseline plus exact implementation and CMake deltas; hashes and source
provenance are retained.

```text
OpenSSL test inventory: 124
OpenSSL execution: 124/124 PASS
external test inventory: 124
external execution: 124/124 PASS
ordered inventory comparison: identical
backend boundary: PASS
external provider hook: PASS
```

Machine-readable CTest inventory JSON and JUnit XML were retained for both
assemblies. The execution environment also could not obtain the declared GoogleTest v1.14.0
dependency, so unchanged Community test sources used a temporary external
compatibility runner limited to the exact GoogleTest assertion and discovery
surface they require. The evidence therefore proves local provider behavior and
inventory parity with execution caveats. It does not claim that the upstream
GoogleTest v1.14.0 implementation was executed.

```text
evidence archive: COMM-VER-01-evidence.zip
evidence SHA-256: 5dc4e449ee0a57ba7a53ab256d2196c4e10ba076ff125e5cdff90fe7af63091b
hosted confirmation: DEFERRED_EXTERNAL_BILLING
upstream GoogleTest rerun: DEFERRED_EXTERNAL_DEPENDENCY
```

## Current Evidence Matrix

| Evidence | Status | Current statement |
| --- | --- | --- |
| Tag/version alignment | PASS | `v0.4.0` resolves to `694459ebe...`; CMake version is `0.4.0` |
| GitHub Release object | PASS | Public, non-draft, non-prerelease Release recovered |
| Release title and published time | PASS | Exact title and 2026-07-13 19:26:47 KST confirmed |
| Release body parity | UNVERIFIED | Exact body comparison was not reported |
| Asset inventory and sizes | PASS | 20-file contract and API/download inventory matched |
| `SHA256SUMS.txt` | PASS | 19/19 verified |
| SPDX release SBOM | PASS | 18/18 package/checksum entries matched |
| GitHub asset digests | PASS | 20/20 matched |
| Artifact attestations | PASS | Supplementary `gh 2.95.0` serial verification passed 20/20 |
| Collector-manifest attestation | DEFERRED | `gh 2.46.0` lacked attestation verification |
| Hosted v0.4.0 CI | PASS | Tag run `29242038502`; 10/10 jobs succeeded |
| Windows package/consumer lanes | PASS | 4/4 exact-commit jobs succeeded |
| macOS package/consumer lanes | PASS | 2/2 exact-commit jobs succeeded |
| Exact-commit CodeQL execution | PASS | Two analyses completed without analysis errors or warnings |
| CodeQL result triage | PASS | 19 unique alerts; 0 confirmed, 0 needs review, 19 not actionable |
| GitHub CodeQL alert disposition | NOT_RUN | All 19 alerts remain open; no state mutation was authorized |
| Historical scheduled fuzz smoke | FAIL | Run `29334006653`; uncaught invalid-input exception |
| Fuzz adapter fix | PASS LOCAL | `c3872c1`; focused and full local fuzz smoke passed |
| Hosted fuzz confirmation after fix | DEFERRED_EXTERNAL | GitHub Actions billing prevents runner execution |
| Provider parity behavior and inventory | PASS LOCAL WITH EXECUTION CAVEATS | OpenSSL 124/124; external 124/124; ordered inventory identical; JUnit retained |
| Declared GoogleTest v1.14.0 parity rerun | DEFERRED_EXTERNAL_DEPENDENCY | Isolated environment could not obtain upstream package/source |

## Evidence Archive Identity

```text
evidence archive: COMM-REL-02-v0_4_0-evidence.zip
evidence archive SHA-256: 76782f2d8840a183fc91cae0b6268e33d8f77e38f05c2b5dd9e426bb176ca356
collector SHA-256: f5629c8a52d1ad354b702cc6389798b95937e129cfda3af89f48b47d5649d2c2
repository mutation during collection: none
```

The successful supplementary attestation output should be retained next to the
archive or included in a new evidence bundle before treating the archive itself
as self-contained.

## Source Repository Evidence Retention

Full release binaries, expanded archives, authenticated API dumps, and local
evidence ZIPs are not retained in the current source tree. Compact summaries live
under `artifacts/`; exact archive SHA-256 values point to externally retained
evidence. CPack source archives exclude repository-external evidence paths, and
package-check fails if those paths reappear. Git history is not rewritten.

## Local Release Gate

The expected local gate remains:

```sh
cmake --build build --config Release --target release-preflight
```

A local pass does not replace hosted publication evidence. Hosted publication
evidence does not replace local compatibility, fuzz, and provider-parity
validation.

## Claims Boundary

AnoSecureKit Community does not claim KCMVP, FIPS validation, certification, or
public-sector approval. OpenSSL or CodeQL usage does not create such a claim.
