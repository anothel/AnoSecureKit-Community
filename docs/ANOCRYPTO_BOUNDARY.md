<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoCrypto Boundary

AnoCrypto Core is intentionally outside the AnoSecureKit Community source tree.

Community may mention AnoCrypto only as a product-family and backend boundary.
It must not present AnoCrypto as a shipped backend, KCMVP-validated module, or
production-ready native crypto provider before those claims are true.

## Allowed in Community

- Public backend-neutral API and format design.
- OpenSSL backend as the public reference backend.
- Documentation that AnoCrypto is private/commercial and not included.
- Tests and fixtures that can later be reused for backend compatibility.

## Not allowed in Community

- AnoCrypto proprietary source code.
- Enterprise license or activation code.
- Claims of KCMVP validation before validation exists.
- Placeholder code that pretends AnoCrypto is available.

## Integration Gate

Before AnoCrypto can be documented as an available Enterprise backend, the
private codebase should provide at least:

- C99 public headers and ABI policy.
- Package config and versioning.
- Known-answer tests and algorithm vectors.
- Differential tests against the OpenSSL reference backend where applicable.
- Cross-backend AnoSecureKit format compatibility tests.
- Fuzzing or parser coverage for serialized formats.
- Security policy, module-boundary, self-test, and key-lifecycle documents.
- Commercial/private licensing strategy.
