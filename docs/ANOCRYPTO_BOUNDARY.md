<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoCrypto Boundary

AnoCrypto is an external proprietary cryptographic module managed outside the
AnoSecureKit Community source tree.

Community may mention AnoCrypto only as a product-family and backend boundary.
It must not present AnoCrypto as included, available, or implemented here.
OpenSSL 3.x is the only public production backend in Community.

## Allowed in Community

- Public backend-neutral API and format design.
- OpenSSL 3.x backend as the public production backend.
- Documentation that AnoCrypto is external, proprietary, and not included.
- Tests and fixtures that can later be reused for backend compatibility.

## Not allowed in Community

- AnoCrypto proprietary source code.
- AnoCrypto scaffold, placeholder, adapter, or fake backend.
- Enterprise license, activation, entitlement, or support logic.
- Certification, validation, public-sector approval, or compliance claims.
- Documentation that implies Community ships or can enable AnoCrypto.
