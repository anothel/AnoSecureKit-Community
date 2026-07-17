<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Backend and Provider Contract

Status: CURRENT
Audience: Community maintainers and parent-build integrators

This is an internal architecture contract. It is not a public provider ABI.

## Shipped Community Profile

```text
AnoSecureKit Community
= public API, CLI, v1 formats, packaging and tests
+ OpenSSL 3.x provider
```

OpenSSL 3.x is the only shipped and supported Community production provider.
The installed target remains `anosecurekit::anosecurekit`.

## Internal Layout

```text
src/backend/crypto_backend.hpp
src/backend/crypto_backend_openssl.cpp
src/internal/secure_wipe.hpp
src/internal/secure_wipe.cpp
```

The provider contract currently covers:

- SHA-256;
- HMAC-SHA-256;
- HKDF-SHA-256;
- random bytes and generated keys;
- scrypt;
- AES-256-GCM one-shot operations;
- AES-256-GCM packet streaming state.

Common code retains public validation and error behavior, encoding helpers,
packet/file serialization, chunking, file safety, CLI behavior, and all v1
compatibility rules.

## Secure Wipe Boundary

Common packet, file, key-management, and cleanup paths call the internal secure
wipe helper without directly including OpenSSL headers. Provider-specific
OpenSSL cleanup stays inside the OpenSSL implementation boundary.

`secure_wipe` is an internal implementation symbol even where shared-library
visibility mechanics require it to be exported. It is not an installed public
header or supported public API.

## External Provider Seam

The supported parent-build seam is:

```text
ANOSECUREKIT_CRYPTO_BACKEND=external
ANOSECUREKIT_EXTERNAL_BACKEND_TARGET=<existing non-imported OBJECT_LIBRARY>
```

Rules:

1. A parent project defines the provider target before adding Community with
   `add_subdirectory()`.
2. The target must exist, must not be imported, and must be an `OBJECT_LIBRARY`.
3. Top-level external configuration is rejected.
4. Missing, unknown, imported, and wrong-type configurations fail at configure
   time.
5. External mode is build-tree only.
6. Community install, export, CPack, package, dogfood, and release surfaces are
   disabled for external mode.
7. No proprietary provider source belongs in Community.
8. The seam is not a runtime plugin mechanism and is not a second supported
   Community backend.

## No Fallback

Provider selection is explicit at configure/link time. A missing operation or
required capability must fail closed. The selected provider must not silently
route an operation to OpenSSL or another provider.

## Compatibility Invariants

Provider work must not change without an intentional public design and versioned
release:

- public headers and namespace;
- CLI commands, output contract, and exit-code policy;
- package name, include root, or CMake target;
- public error behavior;
- `SKT1`, `SKF1`, or `SKP1` v1 meaning;
- the `SKF1` label `anosecurekit file sealing v1`;
- positive and negative fixture compatibility.

When provider requirements conflict with a v1 algorithm or policy, design a new
format/version. Do not reinterpret v1.

## Required Gates

Provider-seam changes must cover, as applicable:

```sh
cmake --build build --config Release --target backend-boundary-check
cmake --build build --config Release --target external-backend-hook-check
cmake --build build --config Release --target external-backend-parity-check
cmake --build build --config Release --target release-preflight
```

`ANOSECUREKIT_TEST_PARALLEL_LEVEL` must be a positive integer and must apply to
both the top-level test run and the nested parity build/test.

A parity claim requires the same discovered test inventory and successful
execution through both the OpenSSL and externally injected assemblies. A
recorded historical result without retained current evidence must be labeled
`RECORDED`, not promoted to a current `PASS`.
