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

Before adding provider helpers, update README.md, docs/SECURITY_MODEL.md, this
policy, and release checks with provider-specific test coverage and a rollback
path.
