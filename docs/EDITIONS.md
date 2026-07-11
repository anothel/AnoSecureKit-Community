<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Editions

AnoSecureKit is a product family with a shared C++ compatibility surface and
separate product/backend profiles.

## AnoSecureKit Community

AnoSecureKit Community is the public, open-source edition.

- Repository role: public Community codebase.
- License: MPL-2.0.
- Language: C++20.
- Official production provider: OpenSSL 3.x.
- Package name: `anosecurekit`.
- Include root: `include/anosecurekit`.
- C++ namespace: `anosecurekit`.
- CLI: `anosecurekit`.
- CMake target: `anosecurekit::anosecurekit`.

Community is the compatibility and trust base. It remains useful, documented,
packaged, and fully tested without private assets.

Its internal implementation may be refactored into backend-neutral common code
and an OpenSSL provider, but the official Community distribution continues to
ship and support OpenSSL only.

## AnoSecureKit Enterprise

AnoSecureKit Enterprise is separate proprietary commercial software and is
intended to cover the Community functionality while adding Enterprise policy,
diagnostics, packaging, deployment, and customer-delivery support.

The intended explicit profiles are:

```text
Enterprise OpenSSL profile
= Community-compatible behavior + OpenSSL provider + Enterprise layer

Enterprise AnoCrypto-C profile
= Community-compatible behavior + proprietary AnoCrypto-C provider
  + external AnoCryptoC::AnoCryptoC + Enterprise layer
```

A profile must identify its provider explicitly. The AnoCrypto-C profile must
not silently fall back to OpenSSL when a required service is missing.

Enterprise-only source, including the proprietary AnoCrypto-C adapter, must not
be committed to the Community repository.

## External AnoCrypto-C Boundary

AnoCrypto-C is developed, released, licensed, and validated separately from
AnoSecureKit. Community does not include its source, package, adapter, or
compliance status.

A generic internal provider contract may exist in Community so that Enterprise
can attach its own provider without privately modifying Community-owned files.
See `docs/ANOCRYPTO_BOUNDARY.md` and `docs/BACKEND_ARCHITECTURE.md`.
