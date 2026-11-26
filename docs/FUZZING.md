<!-- SPDX-License-Identifier: MPL-2.0 -->

# Fuzzing

AnoSecureKit fuzz targets are optional and require Clang with libFuzzer support.
They do not build in the default release or package path.

```sh
cmake -S . -B build-fuzz \
  -DANOSECUREKIT_BUILD_FUZZ=ON \
  -DANOSECUREKIT_BUILD_TESTS=OFF \
  -DANOSECUREKIT_BUILD_CLI=OFF \
  -DANOSECUREKIT_INSTALL_CLI=OFF \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo

cmake --build build-fuzz --target fuzz-smoke
```

`fuzz-smoke` runs each target once against `tests/fixtures` plus malformed
samples under `tests/fuzz/corpus`. Longer fuzzing remains a manual or scheduled
job:

```sh
build-fuzz/anosecurekit_fuzz_hex tests/fixtures tests/fuzz/corpus
build-fuzz/anosecurekit_fuzz_base64 tests/fixtures tests/fuzz/corpus
build-fuzz/anosecurekit_fuzz_base64url tests/fixtures tests/fuzz/corpus
build-fuzz/anosecurekit_fuzz_skt1 tests/fixtures tests/fuzz/corpus
build-fuzz/anosecurekit_fuzz_file tests/fixtures tests/fuzz/corpus
```

## Opt-in SKP1 valid-scrypt corpus

The regular `anosecurekit_fuzz_file` intentionally skips complete `SKP1`
headers to keep its high-throughput parser campaign bounded. For actual SKP1
KDF and authenticated-record paths, configure a separate Clang build with the
Community OpenSSL backend:

```sh
cmake -S . -B build-fuzz-skp1 -G Ninja \
  -DANOSECUREKIT_BUILD_FUZZ=ON \
  -DANOSECUREKIT_FUZZ_VALID_SKP1=ON \
  -DANOSECUREKIT_BUILD_TESTS=OFF \
  -DANOSECUREKIT_BUILD_CLI=OFF \
  -DANOSECUREKIT_INSTALL_CLI=OFF \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build-fuzz-skp1 --target fuzz-skp1-valid-smoke

mkdir -p build-fuzz-skp1/skp1-corpus
cp tests/fixtures/skp1-known-password-file.hex build-fuzz-skp1/skp1-corpus/
build-fuzz-skp1/anosecurekit_fuzz_skp1_valid \
  -runs=1000 -max_total_time=30 -max_len=4096 -timeout=5 -rss_limit_mb=1024 \
  build-fuzz-skp1/skp1-corpus
```

The standalone smoke executable must authenticate the committed synthetic
SKP1 vector through end of input, open it to the exact expected plaintext in
memory, and report `authentication_failed` for a copy with a modified final
tag. The smoke target also executes the fixed fixture in the mutation harness.
The mutation harness uses the verify-only API and accepts authentication and
structural rejection as ordinary fuzz outcomes.

Both executables use a private static archive built from the complete Community
library source list. Clang instruments the archive and both executables with
ASan and UBSan. The archive also carries libFuzzer coverage instrumentation.
The system OpenSSL library is a separate dependency. The instrumented archive
is used only by the SKP1 test executables and is excluded from packaging.

## GitHub Scheduled Fuzzing

`.github/workflows/fuzz.yml` runs weekly and on manual dispatch. The scheduled
job builds the optional libFuzzer targets, runs `fuzz-smoke` first, then runs
the five default targets with `-max_total_time=60` each. The job has
`timeout-minutes: 30`.

Failure artifacts are uploaded for seven days under `fuzz-artifacts`. They are
limited to target logs, command lines, compiler version, commit SHA, and
libFuzzer crash artifacts emitted through `-artifact_prefix`.

To run the separate SKP1 job, select `skp1` when dispatching the Fuzz workflow,
or add `<!-- run-skp1-fuzz -->` to the body of a pull request targeting `main`.
The job uses the selected commit or pull request head and runs the known-vector
smoke before mutating a private copy of the fixture in hex and binary forms.
The campaign is capped at 1,000 executions or 30 seconds, with 4,096-byte
inputs, a 5-second per-input timeout, and a 1,024 MiB RSS limit. The job has a
10-minute timeout. Failure evidence is retained for seven days.

## Corpus Policy

- Keep checked-in corpus entries small, stable, and format-focused.
- Put byte-format compatibility samples in `tests/fixtures`; put malformed
  smoke-only seeds in `tests/fuzz/corpus`.
- Add a corpus seed only when it exercises a parser path not already covered by
  fixtures or unit tests.
- Minimized crash reproducers may be checked in after the root cause is fixed
  and a regression test names the protected rule.
- Do not check in generated fuzz output, large random corpora, secrets, or
  environment-specific files.

## Scheduled Job Policy

Scheduled fuzzing is owned by the maintainer who owns release readiness for the
target branch. It must run the existing `fuzz-smoke` target first; longer runs
are promoted only after repeated useful local signal from the same targets.

Runtime limit: each scheduled target gets a fixed wall-clock limit, recorded in
the workflow or scheduler config, and the whole job must time out instead of
running indefinitely.

Artifact policy: keep only minimized crash inputs, sanitizer logs, target name,
commit SHA, compiler version, and command line. Do not upload generated corpora,
large random inputs, passwords, keys, plaintext samples, or environment-specific
build trees.

Failure triage path:

1. Reproduce the crash locally with the saved input and exact target.
2. Classify the failure as parser bug, expected rejection, sanitizer-only
   finding, infrastructure failure, or duplicate.
3. Add or update a focused unit test, negative fixture, or corpus seed.
4. Fix the root cause, rerun `fuzz-smoke`, and keep only the minimized
   reproducer when it protects a parser path not already covered.
