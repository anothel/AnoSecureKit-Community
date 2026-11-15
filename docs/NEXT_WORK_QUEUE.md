<!-- SPDX-License-Identifier: MPL-2.0 -->

# AnoSecureKit Community Next Work Queue

Maintenance resumption (2026-11-15): the active phased queue is now
[REVIVAL_PLAN.md](REVIVAL_PLAN.md). The frozen queue below is retained as a
historical record, not the current maintenance instruction.

Status: CLOSED

```text
ENGINEERING_STATUS=CLOSED_AND_FROZEN
ACTIVE_NEXT_WORK=NONE
ACTIVE_RELEASE_ACTION=NONE
FUTURE_WORK=DEFERRED_NOT_SELECTED
REOPEN_REQUIRES_NEW_PRODUCT_DECISION
```

There is no active Community implementation, maintenance, roadmap, hosted
validation, or release-publication task.

## Frozen Baselines

```text
PUBLIC_RELEASE_BASELINE=
v0.4.0@694459ebe497d15ba75ef76a52fa7c36ddd7bcce

UNPUBLISHED_MAINTENANCE_BASELINE=
df1936777843415022a97f775c6e61eea6d99cb0
MAINTENANCE_RELEASE_STATE=UNPUBLISHED_AND_PARKED

PARKED_FEATURE_BASELINE=
develop/v0.5.0@9fe79dc1e0f8b9951e86c2707c70469611ab43e4
FEATURE_BRANCH_STATE=PARKED_NOT_MERGED
```

v0.4.1 has no tag, GitHub Release, release assets, release SBOM, or v0.4.1
attestations. It is not scheduled for publication. `develop/v0.5.0` is not
merged and its C++ verification APIs and shared ABI allowlist are not a public
Community release surface.

## Parked Work

All previously listed maintenance, CodeQL disposition, external security review,
public API, ABI, CLI secret-input, failure-injection, documentation, distribution,
and web ideas are deferred and not selected. They are not commitments or release
actions.

Reopening any item requires a new explicit product decision that names scope,
supported baseline, security policy, runnable validation, and release authority.

## Historical Records

Completed implementation and evidence history remains in Git history,
`docs/RELEASE_NOTES.md`, `docs/RELEASE_AND_EVIDENCE_STATUS.md`,
`docs/CODEQL_TRIAGE_STATUS.md`, `docs/PROVIDER_PARITY_STATUS.md`, and compact
summaries under `artifacts/`. Those records do not create active work.
