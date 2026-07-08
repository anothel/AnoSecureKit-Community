<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Editions

AnoSecureKit is now treated as a product family rather than a single repository.

## AnoSecureKit Community

AnoSecureKit Community is the public, open-source edition.

- Repository role: public community codebase.
- License: MPL-2.0.
- Language: C++20.
- Public backend: OpenSSL 3.x.
- Package name: `anosecurekit`.
- Include root: `include/anosecurekit`.
- C++ namespace: `anosecurekit`.
- CLI: `anosecurekit`.
- CMake target: `anosecurekit::anosecurekit`.

Community is the compatibility and trust base. It should remain buildable,
well-tested, documented, and useful without private assets.

## AnoSecureKit Enterprise

AnoSecureKit Enterprise is separate commercial software. It should use Community
as a dependency, then add enterprise-only policy, packaging, support, deployment,
and AnoCrypto integration code outside this repository.

Enterprise-only source must not be committed to the Community repository.

## External AnoCrypto Boundary

AnoCrypto is an external proprietary cryptographic module managed outside this
repository. It is not included in Community, and Community does not provide an
AnoCrypto backend, scaffold, Enterprise license logic, or compliance approval
claim.
