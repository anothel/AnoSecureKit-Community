<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Backend Architecture

The provider refactor described by the older version of this document is
complete in the `v0.4.0` code/tag baseline.

The current canonical contract is:

- `docs/BACKEND_AND_PROVIDER_CONTRACT.md`
- `docs/CURRENT_STATUS.md`
- `docs/CROSS_REPOSITORY_BOUNDARY.md`

OpenSSL 3.x remains the only shipped Community production provider. The external
provider hook is build-tree only, requires a parent-defined non-imported
`OBJECT_LIBRARY`, is excluded from Community install/export/CPack/release, and
must fail closed without provider fallback.

The public API, CLI, package identity, `SKT1`/`SKF1`/`SKP1` v1 meanings, fixtures,
and the `SKF1` label `anosecurekit file sealing v1` remain unchanged.
