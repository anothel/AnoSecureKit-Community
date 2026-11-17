<!-- SPDX-License-Identifier: MPL-2.0 -->
# AnoSecureKit Community Next Work Queue

Status: CURRENT

The canonical phased queue and execution record is [REVIVAL_PLAN.md](REVIVAL_PLAN.md).
The 2026-11-15 maintenance instruction supersedes the historical frozen queue.

- Phases 1–2: merged in PRs #1–#2; output security and deterministic I/O faults.
- Phase 3: **DEFERRED** fuzz campaigns and measured coverage, including bounded SKP1.
- Phase 4: merged in PRs #3–#4; additive verification APIs and shared ABI gates.
- Phase 5: merged in PR #5; CLI password file/descriptor/prompt handling.
- Phase 6: release engineering assessment in [REVIVAL_PHASE6_RESULTS.md](REVIVAL_PHASE6_RESULTS.md).
- Maintainer decisions remain: next version, release authorization, support policy,
  acceptance or resolution of evidence gaps and current security-alert review.

OpenSSL remains the only shipped production provider. Preserve public identities
and v1 formats. No publication, tag movement, or alert dismissal is authorized.
Historical publication evidence remains in RELEASE_AND_EVIDENCE_STATUS.md;
prepared source notes remain in docs/RELEASE_NOTES.md. Neither selects a release.
