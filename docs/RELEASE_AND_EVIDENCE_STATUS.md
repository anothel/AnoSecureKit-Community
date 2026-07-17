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

## Repository And Release Identity

```text
current main HEAD: b6dde65db44679fe91428663f98662a429b93cd6
current main subject: docs: record v0.4.0 publication evidence audit
main compared with v0.4.0: ahead by 2, behind by 0
post-tag change class: documentation only
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

The tag remains unchanged. The current `main` contains two post-tag documentation
commits and is not the source revision used to build the v0.4.0 assets.

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

The CodeQL execution status is `PASS`. The meaning, severity, deduplication, and
current disposition of the 19 reported results were not reviewed in COMM-REL-02.
Do not interpret workflow success as a zero-alert security conclusion.

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

No crash artifact file was retained under `fuzz-artifacts/`. The failure is a
Community fuzz-harness or invalid-input handling defect candidate. It is not a
v0.4.0 asset-integrity or publication blocker.

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
| CodeQL result triage | UNVERIFIED | `results_count=19` per analysis requires separate review |
| Scheduled fuzz smoke | FAIL | Run `29334006653`; uncaught invalid-input exception |
| Historical provider parity | RECORDED | 124/124 reported for OpenSSL and external assemblies |
| Current local provider parity rerun | DEFERRED | Earlier audit lacked GoogleTest package/cache |

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
