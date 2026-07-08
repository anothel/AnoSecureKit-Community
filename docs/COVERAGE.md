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

## Current Baseline

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
