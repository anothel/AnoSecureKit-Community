<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Backend Architecture

This document records the approved internal direction for separating
AnoSecureKit's public C++ behavior from its cryptographic provider
implementation. It is an internal architecture policy, not a public provider ABI.

## Product Contract

AnoSecureKit Community is the public `MPL-2.0` distribution and continues to
ship OpenSSL 3.x as its only production cryptographic provider.

```text
AnoSecureKit Community
= existing public API, CLI, formats, packaging, and tests
+ OpenSSL provider
```

The internal code should nevertheless permit an Enterprise build to reuse the
same common behavior with a separately maintained provider.

```text
AnoSecureKit Enterprise OpenSSL profile
= common AnoSecureKit behavior + OpenSSL provider + Enterprise layer

AnoSecureKit Enterprise AnoCrypto-C profile
= common AnoSecureKit behavior + proprietary AnoCrypto-C provider
  + external AnoCryptoC::AnoCryptoC + Enterprise layer
```

Community does not ship, discover, document as available, or provide support for
the proprietary AnoCrypto-C provider.

## Current Implementation

Most cryptographic operations already pass through the private boundary in:

```text
src/crypto_backend.hpp
src/crypto_backend.cpp
```

That boundary currently covers:

- SHA-256;
- HMAC-SHA-256;
- HKDF-SHA-256;
- random bytes and generated keys;
- scrypt;
- AES-256-GCM one-shot chunk operations;
- AES-256-GCM packet streaming state.

OpenSSL-specific coupling remains in:

```text
src/crypto_backend.cpp
src/wipe.hpp
CMakeLists.txt
```

`src/wipe.hpp` is included by otherwise common packet, file, and key-management
logic, so secure wiping must be moved behind a backend-neutral internal helper
before a clean external provider can be injected.

## Target Internal Layout

The first refactor should be incremental. Do not begin by exporting a new public
`anosecurekit_core` package or by changing the installed CMake surface.

Recommended initial layout:

```text
src/backend/crypto_backend.hpp
src/backend/crypto_backend_openssl.cpp
src/internal/secure_wipe.hpp
src/internal/secure_wipe.cpp
```

The final Community product target remains:

```text
anosecurekit::anosecurekit
```

and continues to link OpenSSL. A separate internal core target may be introduced
later only if the provider seam cannot be implemented safely without it.

## Backend Contract Responsibilities

The internal provider contract owns cryptographic operations and provider state:

- hash and MAC;
- KDF and password KDF primitives;
- cryptographically secure random generation;
- AEAD one-shot and streaming state;
- key-wrapping primitives when implemented by the provider;
- initialization and shutdown policy;
- provider/module identity and version;
- operational and self-test state;
- supported-service capability reporting.

Common AnoSecureKit code retains:

- public argument and size validation;
- public error and exception behavior;
- hex, Base64, and Base64URL;
- packet and file header parsing/serialization;
- chunking, file I/O, temporary output, commit, rollback, and cleanup;
- generic authentication-failure policy;
- CLI command shape and user-facing diagnostics;
- `SKT1`, `SKF1`, and `SKP1` compatibility rules.

Provider-specific error details must not leak into public exceptions unless the
public error policy explicitly changes in a versioned release.

## Provider Selection

Provider selection should be compile-time/link-time, not an untrusted runtime
plugin mechanism.

A future internal CMake shape may use concepts such as:

```text
ANOSECUREKIT_CRYPTO_BACKEND=openssl
ANOSECUREKIT_CRYPTO_BACKEND=external
ANOSECUREKIT_EXTERNAL_BACKEND_TARGET=<private provider target>
```

Rules:

- Community defaults to and officially supports only `openssl`.
- `external` is a build-tree integration seam, not an installed public provider
  ABI or a shipped backend.
- The Community repository must not contain a proprietary provider.
- Provider identity must be explicit in diagnostics and build metadata.
- No provider may silently delegate unsupported operations to another provider.

## Capability and Failure Policy

A product profile defines its required capability set. Configuration, build, or
startup must fail closed when a required capability is missing.

For an AnoCrypto-C profile:

```text
locate exact package and target
→ initialize the external module
→ verify self-test and operational state
→ verify required service capabilities
→ enable AnoSecureKit operations
```

An incomplete development profile must be clearly marked non-production. It must
not claim Community feature parity or KCMVP/FIPS validation.

## Format and API Compatibility

The provider refactor must not change:

- public headers, namespace, CLI, package name, or installed target;
- public error behavior without an intentional reviewed change;
- `SKT1`, `SKF1`, or `SKP1` v1 algorithms and parameter semantics;
- the compatibility-sensitive `SKF1` HKDF context label;
- checked fixtures and documented reject rules.

If a provider requires different algorithms or policy semantics, introduce a new
format/version instead of reinterpreting an existing v1 format.

## Ownership Boundary

Community `MPL-2.0` files may contain:

- the internal generic provider contract;
- backend-neutral common implementation;
- the OpenSSL provider;
- public tests, fixtures, and provider compatibility hooks.

Enterprise proprietary files may contain:

- the AnoCrypto-C C++ provider adapter;
- Enterprise policy, diagnostics, packaging, and customer-delivery logic.

AnoCrypto-C remains an external project/package and is not copied into either
AnoSecureKit repository.

## Implementation Sequence

1. Isolate secure wiping from direct OpenSSL headers.
2. Move the existing OpenSSL implementation behind the internal provider layout.
3. Add a build-tree-only external provider hook.
4. Run the existing Community API and format suites through the OpenSSL provider.
5. Verify install/export/package/release behavior remains unchanged.
6. Release the refactored Community baseline before Enterprise consumes the new
   seam.
7. Implement and test the proprietary AnoCrypto-C provider in Enterprise.

## Required Verification

Every provider-seam change must run the full configured release gate:

```sh
cmake --build build --config Release --target release-preflight
```

The change must also demonstrate:

- unchanged OpenSSL Community behavior;
- no public API or format drift;
- no proprietary source in Community;
- deterministic provider selection;
- fail-closed behavior for missing external providers/capabilities;
- no OpenSSL production linkage in an AnoCrypto-C-only profile.
