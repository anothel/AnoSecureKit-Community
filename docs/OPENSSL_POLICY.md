<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit OpenSSL Provider Policy

This document records the OpenSSL provider policy.

## Supported Backend

AnoSecureKit supports OpenSSL Crypto 3.0 or newer.

AnoSecureKit uses OpenSSL's default library context and the provider configuration
already active in the process. It does not load providers. It does not create an
`OSSL_LIB_CTX`. It does not set property queries. It does not switch provider
configurations.

No public API change and no format change are made by this policy.

## Provider Responsibility

Applications that require custom provider selection must configure OpenSSL before
calling AnoSecureKit. Community makes no compliance approval claims for the
active OpenSSL configuration.

AnoSecureKit needs these operations from the active OpenSSL configuration:

- AES-256-GCM
- SHA-256
- HMAC-SHA-256
- HKDF-SHA-256
- scrypt
- random bytes

## Failure Behavior

If the active OpenSSL configuration cannot provide required cipher, digest, MAC,
KDF, allocation, initialization, or random operations, AnoSecureKit reports
`anosecurekit::error_code::backend_failure`.

Authentication failures remain generic
`anosecurekit::error_code::authentication_failed`. Malformed or unsupported
serialized structure remains `anosecurekit::error_code::invalid_packet`.

AnoSecureKit does not include OpenSSL error queue details in public exception
messages.

## Release Test Coverage

`release-preflight` runs the release check surface, including unit tests,
package checks, example checks, dogfooding, and release workflow checks. That
coverage verifies AnoSecureKit against the OpenSSL provider configuration active in
the build and test process.

The release checks exercise AES-256-GCM, SHA-256, HMAC-SHA-256, HKDF-SHA-256,
scrypt, and random bytes. They do not prove compliance approval.

## OpenSSL Upgrade and Rollback Policy

Before promoting an OpenSSL update, record the candidate and last known-good
versions in pinned dependency metadata when available, or in the release notes
and build provenance when the platform package manager selects the version. The
candidate must pass the supported CI matrix, `release-preflight`, package and
consumer checks, compatibility fixtures, and the cryptographic tests listed
above.

The rollback path for an OpenSSL update is to restore the last known-good
version when the candidate causes a supported build, provider-availability,
package, consumer, compatibility, or security-test regression. A rollback must
update the same dependency metadata and release notes with the failed version,
reason, and supporting test evidence.

Do not roll back an emergency security update to a version affected by the
vulnerability being fixed. Use another fixed OpenSSL version, apply an
appropriate mitigation, or pause the affected release until a safe version
passes the required evidence. Promotion or rollback requires maintainer approval
through the reviewed dependency change; emergency release decisions must also be
recorded in the release notes.

Before adding provider helpers, update README.md, docs/SECURITY_MODEL.md, this
policy, and release checks with provider-specific test coverage and a rollback
path.
