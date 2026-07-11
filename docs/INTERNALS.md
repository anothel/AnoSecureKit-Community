<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Internal Boundaries

This document records current implementation ownership and the approved provider
refactor direction. It is not a public API or provider ABI contract.

## Current Ownership

- `src/aead.cpp`: one-shot `SKT1` packet encryption/decryption through the
  packet APIs.
- `src/crypto_backend.hpp`: current private cryptographic operation boundary.
- `src/crypto_backend.cpp`: current OpenSSL implementation for hashes, HMAC,
  HKDF, RNG, scrypt, one-shot AES-256-GCM chunk operations, and stateful
  AES-GCM packet streaming.
- `src/internal/secure_wipe.hpp` and `src/internal/secure_wipe.cpp`: backend-neutral
  secure-wipe helper used by common packet, file, key-management, and backend
  cleanup paths. It deliberately has no OpenSSL header or symbol dependency.
- `src/packet_stream.cpp`: move-only `SKT1` packet streaming state machines.
  `packet_decryptor::update()` returns unverified plaintext until `finalize()`
  succeeds.
- `src/aead_internal.hpp`: private `SKT1` packet constants and packet-shape
  validation helpers.
- `src/file.cpp`: public file API orchestration and stream payload flow for
  `SKF1` and `SKP1`.
- `src/file_detail.hpp`: private file-format, crypto, and temp-output boundary
  shared by the file implementation units.
- `src/file_crypto.cpp`: `SKF1`/`SKP1` header parse/serialize, file key
  derivation, password KDF checks, chunk nonce/AAD construction, and chunk
  AEAD orchestration through the private backend boundary.
- `src/file_io.cpp`: file input, exclusive temp-output creation, durable commit,
  cleanup, and stream read/write helpers.
- `src/cli/main.cpp`: CLI executable entry point.
- `src/cli/commands.cpp`: CLI parsing, command dispatch, help text, exit-code
  policy, file command verification, and user-facing diagnostics.
- `tests/fixtures`: stable byte-level compatibility vectors and negative
  fixtures for documented reject rules.

## Approved Provider Refactor

The first refactor should preserve the public and installed surface while moving
provider-specific code into an internal layout such as:

```text
src/backend/crypto_backend.hpp
src/backend/crypto_backend_openssl.cpp
src/internal/secure_wipe.*
```

The Community final target remains OpenSSL-backed. A build-tree-only external
provider hook may be introduced for Enterprise integration, but it is not a
public installed provider ABI and does not make AnoCrypto-C a Community backend.

See `docs/BACKEND_ARCHITECTURE.md` for responsibilities, capability rules,
ownership, and the no-fallback policy.

## Split Gates

Internal splits are allowed only when they reduce active maintenance risk. They
must not change public C++ APIs, CLI command shape, or `SKT1`/`SKF1`/`SKP1`
format behavior. They must also preserve the public package identity.

Provider work must additionally ensure:

- OpenSSL remains the only shipped Community provider;
- common code contains no OpenSSL types after the relevant boundary is moved;
- a missing external provider or capability fails closed;
- proprietary adapters remain outside Community;
- the AnoCrypto-C profile cannot acquire an OpenSSL production dependency by
  fallback or transitive linkage.

Keep file and CLI internals private. Further splits require repeated edit
conflicts, a smaller safety fix, or a test-protected behavior change that is hard
to review in the current files. Introduce a separately exported core target only
if the smaller internal provider seam proves insufficient and the added package
surface has a written compatibility policy.

## Required Checks

Any internal split must run:

```sh
cmake --build build --config Release --target check
cmake --build build --config Release --target release-preflight
```

If the split touches package installation, CLI usage, release assets, or public
headers, run the smallest matching package or CLI check before
`release-preflight`.
