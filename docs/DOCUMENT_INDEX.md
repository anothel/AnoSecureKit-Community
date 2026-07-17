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

## User-Facing Contracts

- `README.md`: project overview, build, API, CLI, package, and release entry points.
- `docs/CLI.md`: checked CLI behavior.
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

## Historical Evidence

Versioned historical evidence may remain under `artifacts/`. Historical evidence
does not become current merely because it is present in the latest repository.
For example, a v0.3.0 post-publication audit does not prove v0.4.0 publication.

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
