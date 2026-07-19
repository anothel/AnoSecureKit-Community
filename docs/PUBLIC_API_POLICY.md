<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Public API Policy

This document records the v1 public API shape decision.

## Decision

AnoSecureKit keeps the current exception boundary for v1. Public failures are
reported with `anosecurekit::error` and `anosecurekit::error_code`.
No public API change and no format change are made by this policy.

The affected APIs are the public functions and classes listed in README.md:

- encoders and decoders
- hash, HMAC, HKDF, compare, random, and token helpers
- `encrypt`, `decrypt`, `wrap_key`, and `unwrap_key`
- `seal_file`, `open_file`, `verify_file`, `seal_file_with_password`,
  `open_file_with_password`, and `verify_file_with_password`
- `packet_encryptor` and `packet_decryptor`
- version helpers

## Result-Style API Review

A result-style API would either change return types or duplicate the existing
API with separate non-throwing variants. Changing return types would be a
breaking API migration cost for every caller and example. Duplicating the API
would expand the v1 surface before a current caller proves that exceptions are
worse.

Rollback path: keep the existing throwing functions stable. If a checked caller
is worse with exceptions, add explicitly named result-style variants beside the
current API. Do not change the existing function meanings.

No current caller that is currently worse with exceptions was found in the
checked surfaces. The CLI catches `anosecurekit::error` at the command boundary and
maps it to exit code 1. The basic C++ example and package consumer use
synchronous calls where the current exception boundary is direct.

## Object Lifecycle Review

The base API remains free-function oriented. One-shot byte operations and file
operations have no exposed lifecycle state that a public object would express
more clearly than the current functions.

`packet_encryptor` and `packet_decryptor` remain the only public lifecycle
objects. They model the current `SKT1` incremental lifecycle:

- construct with key and AAD
- `begin`
- `update`
- `finalize`

Add another object only when a named current lifecycle state cannot be expressed
cleanly by free functions and the proposal includes the affected APIs, migration
cost, rollback path, and regression check.

## File Verification API Review

`verify_file` and `verify_file_with_password` are additive throwing free functions with path and stream overloads. They authenticate complete `SKF1` or `SKP1` inputs, discard decrypted chunks inside the library, and expose no plaintext output parameter. `void` preserves the existing error-code distinctions; a boolean result would collapse malformed input and backend failure into an authentication answer. The CLI verification commands delegate to these APIs. See `docs/PUBLIC_FILE_VERIFICATION_API.md`.


## Shared Library ABI Review

Shared builds hide symbols by default and export only declarations marked with
`ANOSECUREKIT_API`. The reviewed ABI includes the public functions and lifecycle
classes above plus `anosecurekit::error` RTTI required for cross-library
exception handling. Internal provider, file-I/O, parsing, and secure-wipe symbols
are not supported ABI. See `docs/SHARED_LIBRARY_ABI.md`.
