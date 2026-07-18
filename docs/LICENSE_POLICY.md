<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit License Policy

AnoSecureKit is licensed under the Mozilla Public License 2.0 (`MPL-2.0`).
The full license text is in [`../LICENSE`](../LICENSE).

## Practical Meaning

- Commercial use is allowed.
- Closed-source application use is allowed.
- You do not need to pay a license fee merely because AnoSecureKit is used in a
  commercial product.
- If you distribute modified AnoSecureKit source files, those modified
  AnoSecureKit-covered files should remain available under `MPL-2.0`.
- AnoSecureKit does not intend to force unrelated proprietary application files
  open merely because the application uses AnoSecureKit as a separate library.

## File-Level Boundary

`MPL-2.0` is a file-level copyleft license. Keep project changes clean by
separating direct modifications to AnoSecureKit-covered files from unrelated
application code. If you patch AnoSecureKit itself and distribute the patched
version, publish the patched AnoSecureKit files under `MPL-2.0`.

## Contributions

Contributions to this repository are accepted under `MPL-2.0`. New source,
script, CMake, test, example, benchmark, and public documentation files should
carry a machine-readable SPDX identifier using the comment syntax appropriate for
the file type.

## External Proprietary Modules

AnoSecureKit Enterprise and AnoCrypto-C are separate repositories and products.
Community does not include Enterprise proprietary source, an AnoCrypto-C adapter,
or either product's license logic, package, or validation status. Community
remains licensed under `MPL-2.0`; using separately licensed external products does
not change the license of Community files. No external proprietary source is
included in this repository.

## Not Legal Advice

This document is a project-maintainer explanation of the intended license
posture, not legal advice. Review `MPL-2.0` with counsel for product-specific
compliance decisions.
