<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Coverage Reporting

Coverage is observational. It is not a release gate until the project has a
stable baseline and a clear owner for threshold changes.

## Local Report

Requirements:

- GCC or Clang
- `gcovr`
- tests enabled

```sh
cmake -S . -B build-coverage -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DANOSECUREKIT_BUILD_TESTS=ON \
  -DANOSECUREKIT_ENABLE_COVERAGE=ON
cmake --build build-coverage --target coverage-report
```

The target runs the test suite through `check` first, then writes:

- `build-coverage/coverage/anosecurekit.html`
- `build-coverage/coverage/coverage.xml`

Use coverage to find untested AnoSecureKit library branches. Do not block changes
on a percentage alone; add focused tests for real behavior, format, CLI, or
release risks.

## Phase 3 Bounded Verification

### B09 Fuzz Campaigns

The 2026-11-23 local campaign used Community source
`bac39195bf9ae95b945c733a9ea548b212a67f93` and the opt-in valid SKP1 harness
from [PR #12](https://github.com/anothel/AnoSecureKit-Community/pull/12) at
`b9d7c52d94ac7624cf2fad118e04d38ca767de30`. Six 60-second libFuzzer campaigns
used copied synthetic seeds, a 4096-byte maximum input, a 5-second per-input
timeout and a memory cap. The valid SKP1 lane used full-source ASan and UBSan.

| Target | Executions |
| --- | ---: |
| hex | 142,546 |
| base64 | 107,184 |
| base64url | 55,040 |
| SKT1 | 38,882 |
| file | 45,005 |
| valid SKP1 | 91,722 |
| **Total** | **480,379** |

All six campaigns exited 0 with zero crash artifacts or observed sanitizer
findings. Counts describe libFuzzer executions, including inputs that can be
rejected before scrypt. The time and seed budgets bound the result. See the
[B09 campaign record](https://github.com/anothel/AnoSecureKit-Community/issues/9#issuecomment-7104544689).

### B10 Full-Suite Coverage

On 2026-11-23, GCC Debug `coverage-report` ran the full CTest suite (134/134
passed) and gcovr 7.2 measured the following on [PR #13](https://github.com/anothel/AnoSecureKit-Community/pull/13)
head `33ef5d3e527aa5a138c516aa42b9006511dff0c4`. That revision adds the coverage
workflow to `bac39195bf9ae95b945c733a9ea548b212a67f93` with identical product source.

- Line coverage: **1842/1983 (92.89%)**
- Branch coverage: **1748/2605 (67.10%)**

See [run 45196322442](https://github.com/anothel/AnoSecureKit-Community/actions/runs/45196322442)
and [job 137767602544](https://github.com/anothel/AnoSecureKit-Community/actions/runs/45196322442/job/137767602544).
[Artifact 14827917714](https://github.com/anothel/AnoSecureKit-Community/actions/runs/45196322442/artifacts/14827917714)
(`anosecurekit-coverage-45196322442-1`) contains `coverage.xml` and
`anosecurekit.html`. The ZIP SHA-256 is
`2f70aafd17179e7cfcbb6964c04be1f1effef26f69e568f0d1b65361030c9dfd`.
The workflow retains artifacts for seven days. The
[B10 evidence record](https://github.com/anothel/AnoSecureKit-Community/issues/9#issuecomment-7104417645)
also records the separate GCC and Clang ASan+UBSan CTest runs (134/134 each)
on PR #12 head in [product CI run 45194616206](https://github.com/anothel/AnoSecureKit-Community/actions/runs/45194616206).

The fuzz and coverage results complete the bounded execution tracked in
[issue #9](https://github.com/anothel/AnoSecureKit-Community/issues/9). Both PRs
were merged by main revision `7401adc2d805ff43f79ff04c89d616fc6f131a6e`.
The measurements apply to the listed test revisions and workloads. Independent
security review, current CodeQL alert review and release acceptance remain open.

## Historical Local Baseline

Baseline source: `build-coverage/coverage/coverage.xml` from a local
`coverage-report` run.

- line coverage: 90.8% (`1619/1783`)
- branch coverage: 63.7% (`1576/2475`)

Lowest branch-coverage files:

| File | Line | Branch |
| --- | ---: | ---: |
| `src/random.cpp` | 88.9% | 46.7% |
| `src/file_io.cpp` | 79.3% | 47.7% |
| `src/aead_internal.hpp` | 88.7% | 50.0% |
| `src/hash.cpp` | 76.1% | 51.2% |
| `src/aead.cpp` | 100.0% | 57.7% |
| `src/file_crypto.cpp` | 91.9% | 59.6% |
| `src/file.cpp` | 91.7% | 62.9% |
| `src/packet_stream.cpp` | 88.2% | 64.4% |

Next focused checks should cover security-critical branches, not chase a
percentage:

- random backend failure and size-boundary behavior.
- OpenSSL hash/HMAC/HKDF failure branches.
- file-open, write, rename, and cleanup failure mapping.
- AEAD setup/finalize failure mapping.
- file record parsing and rollback paths around malformed or reordered input.
- packet stream invalid-order and authentication-failure branches.

These figures and file rankings describe the earlier local report. The hosted
full-suite run and earlier CLI-only measurements used different sources or
workloads, so the figures do not establish a controlled coverage trend.
