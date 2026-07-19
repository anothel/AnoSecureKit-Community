<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Document Index

Status: CURRENT

## Current Status and Scope

- `docs/CURRENT_STATUS.md`: exact code/tag baseline, public identity, audit status,
  and current uncertainty.
- `docs/CROSS_REPOSITORY_BOUNDARY.md`: Community, Enterprise, and AnoCrypto-C
  ownership and change routing.
- `docs/BACKEND_AND_PROVIDER_CONTRACT.md`: canonical provider-seam and no-fallback
  contract.
- `docs/RELEASE_AND_EVIDENCE_STATUS.md`: release evidence taxonomy and current
  v0.4.0 evidence state.
- `docs/NEXT_WORK_QUEUE.md`: active post-v0.4.0 Community work.
- `docs/CODEQL_TRIAGE_STATUS.md`: exact-commit CodeQL alert normalization, static verdicts, and alert-state boundary.
- `docs/PROVIDER_PARITY_STATUS.md`: current OpenSSL/external inventory and execution evidence, including the local harness caveat.

- `docs/ROADMAP.md`: compatibility entry point to `docs/NEXT_WORK_QUEUE.md`; not an independent queue.

## User-Facing Contracts

- `README.md`: project overview, build, API, CLI, package, and release entry points.
- `docs/CLI.md`: checked CLI behavior.
- `docs/PUBLIC_FILE_VERIFICATION_API.md`: reviewed v0.5.0 additive API decision for output-free `SKF1`/`SKP1` verification.
- `docs/SHARED_LIBRARY_ABI.md`: shared-library export allowlist, visibility policy, and package gates.
- `docs/FORMAT.md`: `SKT1`, `SKF1`, and `SKP1` v1 compatibility contract.
- `docs/SECURITY_MODEL.md`: threat model, non-goals, and output-safety rules.
- `docs/LICENSE_POLICY.md`: MPL-2.0 project boundary.
- `docs/VERIFY_RELEASE.md`: user-side release verification procedure.
- `SECURITY.md`: private vulnerability reporting and supported-version policy.

## Maintainer Policies

- `CONTRIBUTING.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/RELEASE_NOTES.md`
- `docs/PUBLIC_API_POLICY.md`
- `docs/OPENSSL_POLICY.md`
- `docs/DEPENDENCY_POLICY.md`
- `docs/KDF_AGILITY.md`
- `docs/FUZZING.md`
- `docs/COVERAGE.md`
- `docs/BENCHMARKS.md`
- `docs/DOGFOODING.md`
- `docs/EXTERNAL_SECURITY_REVIEW.md`
- `docs/WEB_ROADMAP.md`
- `docs/REPOSITORY_HYGIENE.md`

## Compatibility Entry Points

The following paths remain because repository checks or existing links use them.
They are not independent sources of truth:

- `docs/BACKEND_ARCHITECTURE.md` → `docs/BACKEND_AND_PROVIDER_CONTRACT.md`
- `docs/ROADMAP.md` → `docs/NEXT_WORK_QUEUE.md`
- `docs/DOCUMENTATION_GUIDE.md` → this index
- `docs/INTERNALS.md` → implementation ownership details plus the provider contract
- `docs/EDITIONS.md` → `docs/CROSS_REPOSITORY_BOUNDARY.md`
- `docs/ANOCRYPTO_BOUNDARY.md` → `docs/CROSS_REPOSITORY_BOUNDARY.md`
- `COMMUNITY_SPLIT_NOTES.md` → historical extraction note only

## Historical And Release Evidence

Only compact versioned summaries remain under `artifacts/`. Full release binaries,
expanded archives, authenticated response dumps, and local evidence ZIPs remain
outside the source tree.

- `artifacts/v0.3.0-post-publication-audit/README.md`: historical v0.3.0 pointer.
- `artifacts/v0.4.0-post-publication-audit/README.md`: compact COMM-REL-02
  publication summary and external archive identity.
- `artifacts/v0.4.0-codeql-triage/README.md`: compact CodeQL triage identity and external evidence archive SHA-256.
- `artifacts/v0.4.0-provider-parity/README.md`: compact COMM-VER-01 parity evidence identity and limitation.

A historical directory does not prove a later release, and a publication audit
does not replace current fuzz, provider-parity, or security-review work.

## Update Rule

When two documents conflict, use this priority:

```text
actual code/tag/release evidence
→ CURRENT status and evidence documents
→ user-facing contract documents
→ focused maintainer policies
→ compatibility entry points
→ historical records
```

New source-controlled documentation must include
`SPDX-License-Identifier: MPL-2.0`.
