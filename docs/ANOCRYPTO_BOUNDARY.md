<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoCrypto-C Boundary

AnoCrypto-C is an external cryptographic module managed in its own repository
and package lifecycle. It is not part of the AnoSecureKit Community source tree.

Community may document AnoCrypto-C only as a product-family and architecture
boundary. It must not present AnoCrypto-C as included, available, implemented,
or supported by the Community distribution. OpenSSL 3.x remains the only
Community production provider.

## Allowed in Community

- A generic internal cryptographic-provider contract.
- Backend-neutral public API, format, file, and error behavior.
- The OpenSSL provider used by the Community product.
- Build-tree extension points that do not ship or expose a proprietary provider.
- Tests and fixtures reusable for provider compatibility and feature parity.
- Documentation explaining that Enterprise may supply a separate proprietary
  AnoCrypto-C adapter and consume the external `AnoCryptoC::AnoCryptoC` target.

## Not Allowed in Community

- AnoCrypto-C source, headers, binaries, archives, or copied packages.
- A proprietary AnoCrypto-C C++ adapter.
- A fake, placeholder, or silently partial AnoCrypto-C provider.
- Community package metadata claiming that AnoCrypto-C is a shipped backend.
- Enterprise licensing, activation, entitlement, support, or customer-delivery
  logic.
- Certification, validation, public-sector approval, or compliance claims.

## No Fallback Rule

An Enterprise AnoCrypto-C profile must not silently route missing cryptographic
operations through the Community OpenSSL provider. Missing required capabilities
must fail closed at configuration, build, startup, or through a clear unsupported
operation path in a non-production development profile.

## Public Compatibility

The generic provider seam is internal. It must not change the public Community
identity:

```text
package: anosecurekit
include root: include/anosecurekit
namespace: anosecurekit
CLI: anosecurekit
CMake target: anosecurekit::anosecurekit
```

See `docs/BACKEND_ARCHITECTURE.md` for the approved incremental design.
