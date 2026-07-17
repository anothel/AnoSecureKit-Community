<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Cross-Repository Boundary

Status: CURRENT

## AnoSecureKit Community

Community owns:

- the public C++ API and error contract;
- the `anosecurekit` CLI;
- the CMake package, install, export, CPack, and public release surface;
- `SKT1`, `SKF1`, and `SKP1` v1 formats and fixtures;
- the generic private provider contract;
- the OpenSSL 3.x production provider;
- the build-tree-only external provider seam;
- public tests, security documentation, and release evidence policy.

Community does not own:

- Enterprise proprietary source or product policy;
- an AnoCrypto-C adapter;
- Enterprise licensing, activation, diagnostics, packaging, or customer delivery;
- AnoCrypto-C source, API, ABI, lifecycle, algorithm, validation, or roadmap work.

## AnoSecureKit Enterprise

AnoSecureKit Enterprise is a separate repository and product. Community records
only this boundary. Enterprise implementation details are not a Community
source-of-truth concern.

When Enterprise work discovers a defect in generic Community behavior, the
OpenSSL implementation, the provider seam, the public API, or a v1 format:

```text
fix and verify in Community
→ release a reviewed Community revision
→ consume that exact revision from Enterprise
```

Do not keep a private Enterprise patch to Community-owned behavior as the
long-term source of truth.

## AnoCrypto-C

AnoCrypto-C is a separate external C99 cryptographic module with its own source,
API, ABI, package, evidence, and validation lifecycle. Community does not depend
on it and does not include its source, headers, binaries, adapter, or compliance
status.

The existence of the generic external provider seam does not make AnoCrypto-C a
Community backend.

## Change Routing

| Finding | Owning repository |
| --- | --- |
| Community public API, CLI, package, format, or generic behavior defect | Community |
| Community OpenSSL provider defect | Community |
| Generic provider seam defect | Community |
| Enterprise product, profile, policy, diagnostics, or delivery defect | Enterprise |
| Enterprise proprietary adapter defect | Enterprise |
| AnoCrypto-C API, ABI, algorithm, lifecycle, or evidence defect | AnoCrypto-C |
| Required algorithm differs from an existing v1 format | New format/version design; do not reinterpret v1 |

## Non-Negotiable Rules

- OpenSSL 3.x remains the only shipped Community production provider.
- Community release/install/export/CPack remains OpenSSL-profile only.
- Missing or unsupported provider capability fails closed.
- Silent provider fallback is prohibited.
- Proprietary code is not copied into Community.
- `SKT1`/`SKF1`/`SKP1` v1 meanings are not changed to fit another provider.
- Community makes no KCMVP or FIPS validation claim.
