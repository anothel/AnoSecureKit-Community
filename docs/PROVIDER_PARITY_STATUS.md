<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Provider Parity Status

Status: CURRENT
Task: `COMM-VER-01`
Repository reference: `a6b7b634214ea4db55efb7a69cd2e663ea052d61`

## Result

```text
OpenSSL assembly: 124/124 PASS
external assembly: 124/124 PASS
ordered CTest inventory: identical
external-backend-parity-check: PASS
backend-boundary-check: PASS
external-backend-hook-check: PASS
```

The evidence retains CTest inventory JSON, JUnit XML, command logs, environment
versions, implementation-input hashes, and built artifact hashes.

## Execution Source Provenance

The shell environment could not clone the current repository. The executed source
was reconstructed from the uploaded `b6dde65...` snapshot plus the exact
implementation delta `c3872c1` and CMake hygiene delta `e8ff924`. The later
`a72aa8e` and `a6b7b63` revisions contain line-ending or documentation-only
changes. Input-file hashes are retained in the evidence archive.

## Harness Boundary

The isolated execution environment had no installed GoogleTest package and could
not reach the declared v1.14.0 FetchContent repository. Community test sources
were not edited. They were compiled with a temporary external compatibility
runner implementing only the GoogleTest macros and discovery arguments present
in the repository.

Accordingly:

- provider behavior and identical test inventory: `PASS LOCAL WITH EXECUTION CAVEATS`;
- exact upstream GoogleTest v1.14.0 reproduction: `DEFERRED_EXTERNAL_DEPENDENCY`;
- hosted current-main confirmation: `DEFERRED_EXTERNAL_BILLING`.

This limitation must remain visible. Do not promote the result to an exact
upstream-framework pass until COMM-VER-02 reproduces it from an exact clean checkout with GoogleTest v1.14.0.

## Compatibility

No Community public API, CLI, CMake identity, provider contract, fixture, or
`SKT1`/`SKF1`/`SKP1` v1 meaning was changed.
